#!/usr/bin/env python3
"""
tray-control.py — Universal System Tray Application Controller for Tegmentum-OS
Handles state-aware activation (focusing open windows without closing/toggling,
or unhiding/launching minimized apps) and complete process termination across
all Linux desktop applications (Qt, GTK, Electron, Steam, ROGCC, Indicators, etc.).
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

def get_hyprland_clients():
    """Returns list of active Hyprland clients."""
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        return json.loads(out)
    except Exception:
        return []

def get_dbus_prop(service, path, interface, prop):
    """Queries a single DBus property via busctl."""
    try:
        res = subprocess.check_output(
            ["busctl", "--user", "get-property", service, path, interface, prop],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        if '"' in res:
            return res.split('"')[1]
        return res
    except Exception:
        return ""

def get_menu_items(service, menu_path):
    """Retrieves all menu items (id, label, type) from com.canonical.dbusmenu."""
    if not menu_path:
        return []
    try:
        out = subprocess.check_output(
            ["busctl", "--user", "call", service, menu_path,
             "com.canonical.dbusmenu", "GetLayout", "iias", "0", "--", "-1", "0"],
            stderr=subprocess.DEVNULL
        ).decode()
        items = []
        raw_items = re.findall(r'\(ia\{sv\}av\)\s+(\d+)\s+\d+(.*?)(?=\(ia\{sv\}av\)|\Z)', out, re.DOTALL)
        for mid, body in raw_items:
            m_label = re.search(r'"label"\s+s\s+"([^"]*)"', body)
            label = m_label.group(1) if m_label else ""
            m_type = re.search(r'"type"\s+s\s+"([^"]*)"', body)
            itype = m_type.group(1) if m_type else ""
            items.append({"id": int(mid), "label": label, "type": itype})
        return items
    except Exception:
        return []

def normalize(s):
    """Strips non-alphanumeric characters and converts to lowercase."""
    return re.sub(r'[^a-z0-9]', '', (s or "").lower())

def get_descendant_pids(pid):
    """Finds all descendant child processes of a PID."""
    descendants = set()
    queue = [pid]
    while queue:
        curr = queue.pop()
        try:
            out = subprocess.check_output(["pgrep", "-P", str(curr)], stderr=subprocess.DEVNULL).decode()
            children = [int(p) for p in out.split()]
            for ch in children:
                if ch not in descendants:
                    descendants.add(ch)
                    queue.append(ch)
        except Exception:
            pass
    return descendants

def get_sni_info(target_id, target_title="", target_tooltip=""):
    """
    Finds best matching SNI item across registered items on the bus using
    robust scoring. Returns (service, path, pid, comm, exe, item_id, item_title, menu_path, category).
    """
    items = get_registered_snis()
    t_id_norm = normalize(target_id)
    t_title_norm = normalize(target_title)
    t_tip_norm = normalize(target_tooltip)
    stop_words = {"statusnotifieritem", "org", "freedesktop", "kde", "ayatana", "notificationitem"}

    candidates = []

    for item in items:
        parts = item.split("/", 1)
        service = parts[0]
        path = "/" + parts[1] if len(parts) > 1 else "/StatusNotifierItem"

        pid = None
        try:
            pid_out = subprocess.check_output(
                ["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
                 "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", service],
                stderr=subprocess.DEVNULL
            ).decode()
            pid = int(pid_out.split()[-1])
        except Exception:
            pass

        comm = ""
        exe = ""
        if pid:
            try:
                exe = os.path.realpath(f"/proc/{pid}/exe")
            except Exception:
                pass
            try:
                with open(f"/proc/{pid}/comm", "r") as f:
                    comm = f.read().strip()
            except Exception:
                pass

        item_id = get_dbus_prop(service, path, "org.kde.StatusNotifierItem", "Id")
        item_title = get_dbus_prop(service, path, "org.kde.StatusNotifierItem", "Title")
        menu_path = get_dbus_prop(service, path, "org.kde.StatusNotifierItem", "Menu")
        category = get_dbus_prop(service, path, "org.kde.StatusNotifierItem", "Category")

        id_norm = normalize(item_id)
        svc_norm = normalize(service)
        comm_norm = normalize(comm)
        title_norm = normalize(item_title)

        score = 0
        if t_id_norm and t_id_norm == id_norm:
            score += 100
        elif t_id_norm and t_id_norm == svc_norm:
            score += 90
        elif t_id_norm and (t_id_norm == comm_norm or comm_norm in t_id_norm):
            score += 85
        elif t_id_norm and len(t_id_norm) > 3 and t_id_norm not in stop_words:
            if t_id_norm in id_norm or id_norm in t_id_norm:
                score += 75

        if t_title_norm and t_title_norm == title_norm:
            score += 50
        elif t_title_norm and len(t_title_norm) > 4 and (t_title_norm in title_norm or title_norm in t_title_norm):
            score += 30

        if t_tip_norm and len(t_tip_norm) > 3 and (t_tip_norm in id_norm or t_tip_norm in title_norm or t_tip_norm in comm_norm):
            score += 40

        candidates.append((score, service, path, pid, comm, exe, item_id, item_title, menu_path, category))

    candidates.sort(key=lambda x: x[0], reverse=True)
    if candidates and candidates[0][0] > 0:
        return candidates[0][1:]
    return None, None, None, None, None, None, None, None, None

def get_window_for_sni(pid, comm, exe, item_id, target_id, target_title=""):
    """
    Finds matching visible window in Hyprland for this application.
    Checks exact PID, descendant PIDs, shared executable binary,
    and normalized window class names.
    """
    clients = get_hyprland_clients()
    t_id_norm = normalize(target_id)
    t_comm_norm = normalize(comm)
    t_item_id_norm = normalize(item_id)
    t_title_norm = normalize(target_title)

    # 1. Exact PID match
    if pid:
        for c in clients:
            if (c.get("mapped") is not False) and not c.get("hidden"):
                if c.get("pid") == pid:
                    return c

    # 2. Descendant PIDs (child processes of this app)
    if pid:
        descendants = get_descendant_pids(pid)
        for c in clients:
            if (c.get("mapped") is not False) and not c.get("hidden"):
                if c.get("pid") in descendants:
                    return c

    # 3. Executable path match (/proc/<c_pid>/exe == exe)
    if exe and os.path.exists(exe):
        for c in clients:
            if (c.get("mapped") is not False) and not c.get("hidden"):
                c_pid = c.get("pid")
                if c_pid:
                    try:
                        c_exe = os.path.realpath(f"/proc/{c_pid}/exe")
                        if c_exe == exe:
                            return c
                    except Exception:
                        pass

    # 4. Class and InitialClass match
    keys = [k for k in [t_id_norm, t_comm_norm, t_item_id_norm] if len(k) > 2 and k not in {"statusnotifieritem", "org", "freedesktop"}]
    for c in clients:
        if (c.get("mapped") is not False) and not c.get("hidden"):
            c_class = normalize(c.get("class"))
            c_init_class = normalize(c.get("initialClass"))

            for k in keys:
                if k and (k in c_class or c_class in k or k in c_init_class or c_init_class in k):
                    return c

    # 5. Title match
    if t_title_norm and len(t_title_norm) > 4:
        for c in clients:
            if (c.get("mapped") is not False) and not c.get("hidden"):
                c_title = normalize(c.get("title"))
                if t_title_norm in c_title or c_title in t_title_norm:
                    return c

    return None

def focus_hyprland_window(win):
    """Switches workspace and focuses window in Hyprland using 0.56+ Lua dispatch syntax."""
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

def activate_app(target_id, target_title="", target_tooltip=""):
    """
    Universal State-Aware Activation:
    1. If the window is ALREADY OPEN on any workspace, switch to it and focus it.
       (Crucially avoids calling Activate/DBusMenu which would close/toggle the app).
    2. If the window is NOT open (minimized/backgrounded), restore it via:
       a. DBusMenu "Open / Show / Restore / Settings" action
       b. StatusNotifierItem.Activate(0, 0)
       c. StatusNotifierItem.SecondaryActivate(0, 0)
       d. Indicator-specific launch (e.g. nm-connection-editor)
       e. Binary executable re-invocation
    """
    service, path, pid, comm, exe, item_id, item_title, menu_path, category = get_sni_info(target_id, target_title, target_tooltip)

    # 1. App window is ALREADY OPEN: focus and return immediately!
    win = get_window_for_sni(pid, comm, exe, item_id, target_id, target_title)
    if win:
        focus_hyprland_window(win)
        return

    # 2. App window is NOT open. Determine best single activation path.
    triggered_action = False

    # 2A. DBusMenu Open / Show action
    if service and menu_path:
        menu_items = get_menu_items(service, menu_path)
        open_item_id = None
        for mi in menu_items:
            l = re.sub(r'[_&]', '', mi['label']).lower().strip()
            if any(k in l for k in ['open', 'show', 'restore', 'display', 'launch', 'main', 'preferences', 'settings', 'edit connection', 'gui']):
                open_item_id = mi['id']
                break

        if open_item_id is not None:
            subprocess.run(
                ["busctl", "--user", "call", service, menu_path,
                 "com.canonical.dbusmenu", "Event", "isvu", str(open_item_id), "clicked", "s", "", "0"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            triggered_action = True

    # 2B. If no DBusMenu action triggered, call StatusNotifierItem.Activate
    if not triggered_action and service:
        subprocess.run(
            ["busctl", "--user", "call", service, path,
             "org.kde.StatusNotifierItem", "Activate", "ii", "0", "0"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        triggered_action = True

    # Poll up to 1.2s for window to appear
    for _ in range(24):
        time.sleep(0.05)
        new_win = get_window_for_sni(pid, comm, exe, item_id, target_id, target_title)
        if new_win:
            focus_hyprland_window(new_win)
            return

    # 2C. Fallback: SecondaryActivate if still no window
    if service:
        subprocess.run(
            ["busctl", "--user", "call", service, path,
             "org.kde.StatusNotifierItem", "SecondaryActivate", "ii", "0", "0"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        for _ in range(10):
            time.sleep(0.05)
            new_win = get_window_for_sni(pid, comm, exe, item_id, target_id, target_title)
            if new_win:
                focus_hyprland_window(new_win)
                return

    # 2D. Indicator-specific fallbacks
    norm_id = normalize(target_id)
    if "network" in norm_id or "nmapplet" in norm_id or comm == "nm-applet":
        subprocess.Popen(["nm-connection-editor"], start_new_session=True)
        for _ in range(15):
            time.sleep(0.05)
            new_win = get_window_for_sni(pid, "nm-connection-editor", None, "nm-connection-editor", "nm-connection-editor")
            if new_win:
                focus_hyprland_window(new_win)
                return

    if "bluetooth" in norm_id or "blueman" in norm_id or comm == "blueman-applet":
        subprocess.Popen(["blueman-manager"], start_new_session=True)
        return

    # 2E. Executable re-invocation fallback
    if exe and os.path.exists(exe):
        try:
            subprocess.Popen([exe], start_new_session=True)
            for _ in range(15):
                time.sleep(0.05)
                new_win = get_window_for_sni(pid, comm, exe, item_id, target_id, target_title)
                if new_win:
                    focus_hyprland_window(new_win)
                    return
        except Exception:
            pass

def quit_app(target_id, target_title="", target_tooltip=""):
    """
    Universal Process Termination:
    1. Triggers DBusMenu "Quit / Exit" action if available (graceful cleanup).
    2. Sends SIGTERM to PID and all descendant processes.
    3. Escalates to SIGKILL if processes remain alive.
    4. Fallback pkill by process name.
    """
    service, path, pid, comm, exe, item_id, item_title, menu_path, category = get_sni_info(target_id, target_title, target_tooltip)

    # 1. DBusMenu Quit action
    if service and menu_path:
        menu_items = get_menu_items(service, menu_path)
        quit_item_id = None
        for mi in menu_items:
            l = re.sub(r'[_&]', '', mi['label']).lower().strip()
            if any(k in l for k in ['quit', 'exit', 'close', 'terminate']):
                quit_item_id = mi['id']
                break

        if quit_item_id is not None:
            subprocess.run(
                ["busctl", "--user", "call", service, menu_path,
                 "com.canonical.dbusmenu", "Event", "isvu", str(quit_item_id), "clicked", "s", "", "0"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            time.sleep(0.2)
            if pid:
                try:
                    os.kill(pid, 0)
                except (ProcessLookupError, OSError):
                    return

    # 2. Terminate PID & Descendant Processes
    if not pid:
        win = get_window_for_sni(None, comm, exe, item_id, target_id, target_title)
        if win and win.get("pid"):
            pid = win.get("pid")

    if pid:
        descendants = get_descendant_pids(pid)
        all_pids = [pid] + list(descendants)
        for p in all_pids:
            try:
                os.kill(p, signal.SIGTERM)
            except Exception:
                pass

        time.sleep(0.2)
        for p in all_pids:
            try:
                os.kill(p, 0)
                os.kill(p, signal.SIGKILL)
            except (ProcessLookupError, OSError):
                pass
        return

    # 3. Fallback: pkill by comm / item name
    clean_target = normalize(comm or item_id or target_id)
    if clean_target and len(clean_target) > 2 and clean_target not in {"statusnotifieritem"}:
        subprocess.run(["pkill", "-f", "-i", clean_target], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    action = sys.argv[1]
    tid = sys.argv[2] if len(sys.argv) > 2 else ""
    ttitle = sys.argv[3] if len(sys.argv) > 3 else ""
    ttip = sys.argv[4] if len(sys.argv) > 4 else ""

    if action == "activate":
        activate_app(tid, ttitle, ttip)
    elif action == "quit":
        quit_app(tid, ttitle, ttip)
