#!/usr/bin/env python3
"""
tray-control.py — System Tray Application Controller for Tegmentum-OS
Handles state-aware activation (focusing open windows without closing/toggling,
or unhiding minimized apps) and complete process termination.
"""

import sys
import os
import re
import time
import signal
import subprocess
import json

def get_registered_snis():
    """Returns list of registered SNI service/path pairs."""
    try:
        out = subprocess.check_output(
            ["busctl", "--user", "get-property",
             "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
             "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"],
            stderr=subprocess.DEVNULL
        ).decode()
        return re.findall(r'"([^"]+)"', out)
    except Exception:
        return []

def get_sni_info(target_id, target_title):
    """Finds matching SNI service, path, PID, item ID, and title."""
    items = get_registered_snis()
    target_id_l = (target_id or "").strip().lower()
    target_title_l = (target_title or "").strip().lower()

    # Clean target string (e.g. "org.qbittorrent.qBittorrent" -> "qbittorrent")
    clean_target = target_id_l.replace("_status_icon", "").split("/")[-1].split(".")[-1].strip()

    best_match = None

    for item in items:
        parts = item.split("/", 1)
        service = parts[0]
        path = "/" + parts[1] if len(parts) > 1 else "/StatusNotifierItem"

        # Resolve Unix PID of DBus service owner
        pid = None
        try:
            pid_out = subprocess.check_output(
                ["busctl", "--user", "call",
                 "org.freedesktop.DBus", "/org/freedesktop/DBus",
                 "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", service],
                stderr=subprocess.DEVNULL
            ).decode()
            pid = int(pid_out.split()[-1])
        except Exception:
            pass

        # Retrieve item Id
        item_id = ""
        try:
            id_out = subprocess.check_output(
                ["busctl", "--user", "get-property", service, path,
                 "org.kde.StatusNotifierItem", "Id"],
                stderr=subprocess.DEVNULL
            ).decode()
            if '"' in id_out:
                item_id = id_out.split('"')[1]
        except Exception:
            pass

        # Retrieve item Title
        item_title = ""
        try:
            t_out = subprocess.check_output(
                ["busctl", "--user", "get-property", service, path,
                 "org.kde.StatusNotifierItem", "Title"],
                stderr=subprocess.DEVNULL
            ).decode()
            if '"' in t_out:
                item_title = t_out.split('"')[1]
        except Exception:
            pass

        item_id_l = item_id.lower()
        item_title_l = item_title.lower()
        service_l = service.lower()

        # Exact match
        if target_id_l and (target_id_l == item_id_l or target_id_l == service_l):
            return service, path, pid, item_id, item_title

        if target_title_l and target_title_l == item_title_l:
            return service, path, pid, item_id, item_title

        # Substring / clean match
        if clean_target and len(clean_target) > 2:
            if clean_target in item_id_l or clean_target in service_l:
                best_match = (service, path, pid, item_id, item_title)

    if best_match:
        return best_match

    return None, None, None, None, None

def get_hyprland_clients():
    """Returns list of active Hyprland clients."""
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        return json.loads(out)
    except Exception:
        return []

def get_window_for_sni(pid, target_id, target_title):
    """Finds matching visible window in Hyprland for this application."""
    clients = get_hyprland_clients()
    clean_id = (target_id or "").lower().replace("_status_icon", "").split("/")[-1].split(".")[-1].strip()
    clean_title = (target_title or "").lower().strip()

    # 1. Match by exact PID first (100% reliable)
    if pid:
        for c in clients:
            if (c.get("mapped") is not False) and not c.get("hidden"):
                if c.get("pid") == pid:
                    return c

    # 2. Match by class or title if PID differs (e.g. multi-process child window)
    for c in clients:
        if (c.get("mapped") is not False) and not c.get("hidden"):
            c_class = str(c.get("class") or "").lower()
            c_init_class = str(c.get("initialClass") or "").lower()
            c_title = str(c.get("title") or "").lower()

            if clean_id and len(clean_id) > 2:
                if clean_id in c_class or clean_id in c_init_class:
                    return c

            if clean_title and len(clean_title) > 2:
                if clean_title in c_title or clean_title in c_class:
                    return c

    return None

def focus_hyprland_window(win):
    """Switches workspace and focuses window in Hyprland."""
    if not win:
        return
    ws = win.get("workspace", {}).get("name")
    addr = win.get("address")

    if ws is not None:
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.focus({{workspace="{ws}"}})'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    if addr:
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.focus({{window="address:{addr}"}})'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )

def activate_app(target_id, target_title):
    """State-aware activation: Focuses if open; unhides if minimized."""
    service, path, pid, item_id, item_title = get_sni_info(target_id, target_title)
    win = get_window_for_sni(pid, target_id, target_title)

    if win:
        # App is ALREADY OPEN! Do not call Activate because DBus SNI toggles/closes it!
        focus_hyprland_window(win)
        return

    # App is closed / minimized to tray: send DBus Activate
    if service:
        subprocess.run(
            ["busctl", "--user", "call", service, path,
             "org.kde.StatusNotifierItem", "Activate", "ii", "0", "0"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )

        # Poll up to 500ms for window to appear, then focus it
        for _ in range(10):
            time.sleep(0.05)
            new_win = get_window_for_sni(pid, target_id, target_title)
            if new_win:
                focus_hyprland_window(new_win)
                return

def quit_app(target_id, target_title):
    """Completely terminates application process."""
    service, path, pid, item_id, item_title = get_sni_info(target_id, target_title)

    if not pid:
        # Fallback to checking Hyprland clients
        win = get_window_for_sni(None, target_id, target_title)
        if win and win.get("pid"):
            pid = win.get("pid")

    if pid:
        try:
            os.kill(pid, signal.SIGTERM)
            time.sleep(0.15)
            # Verify if process is still running
            os.kill(pid, 0)
            # If still alive, send SIGKILL
            os.kill(pid, signal.SIGKILL)
        except (ProcessLookupError, OSError):
            pass
        return

    # Final fallback: pkill by clean name
    clean_target = (target_id or target_title or "").replace("_status_icon", "").split("/")[-1].split(".")[-1].strip()
    if clean_target and len(clean_target) > 2:
        subprocess.run(["pkill", "-x", "-i", clean_target], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-f", "-i", clean_target], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    action = sys.argv[1]
    tid = sys.argv[2] if len(sys.argv) > 2 else ""
    ttitle = sys.argv[3] if len(sys.argv) > 3 else ""

    if action == "activate":
        activate_app(tid, ttitle)
    elif action == "quit":
        quit_app(tid, ttitle)
