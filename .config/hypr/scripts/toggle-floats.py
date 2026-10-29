#!/usr/bin/env python3
"""
toggle-floats.py — Hide and restore floating windows on the active workspace in Hyprland.
When toggled, active floating windows are stashed away to a special workspace (special:minimized).
Toggling again restores them to the active workspace.
"""

import json
import os
import subprocess
import sys


def get_hypr_json(args):
    try:
        raw = subprocess.check_output(args, stderr=subprocess.DEVNULL)
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return None


def main():
    active_ws = get_hypr_json(["hyprctl", "activeworkspace", "-j"])
    if not active_ws:
        sys.exit(0)

    ws_id = active_ws.get("id")
    ws_name = str(active_ws.get("name", ws_id))
    if ws_id is None:
        sys.exit(0)

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    state_file = os.path.join(runtime_dir, f"hypr_hidden_floats_ws_{ws_id}.json")

    # If state file exists, restore windows back to this workspace
    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                addresses = json.load(f)
        except Exception:
            addresses = []

        restored_count = 0
        all_clients = get_hypr_json(["hyprctl", "clients", "-j"]) or []
        existing_addrs = {c.get("address") for c in all_clients}

        for addr in addresses:
            if addr in existing_addrs:
                subprocess.call(
                    ["hyprctl", "dispatch", "movetoworkspacesilent", f"{ws_id},address:{addr}"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                restored_count += 1

        try:
            os.remove(state_file)
        except OSError:
            pass

        if restored_count > 0:
            subprocess.call(
                ["hyprctl", "notify", "1", "1500", "rgb(137,208,237)", f"Restored {restored_count} floating window(s)"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        return

    # Otherwise, find active floating windows on this workspace and stash them
    clients = get_hypr_json(["hyprctl", "clients", "-j"])
    if not clients:
        return

    floating_addrs = [
        c.get("address")
        for c in clients
        if c.get("workspace", {}).get("id") == ws_id and c.get("floating") is True and c.get("address")
    ]

    if not floating_addrs:
        return

    try:
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump(floating_addrs, f)
    except Exception as e:
        sys.stderr.write(f"Error saving state: {e}\n")
        return

    for addr in floating_addrs:
        subprocess.call(
            ["hyprctl", "dispatch", "movetoworkspacesilent", f"special:minimized,address:{addr}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    subprocess.call(
        ["hyprctl", "notify", "1", "1500", "rgb(179,202,213)", f"Hid {len(floating_addrs)} floating window(s)"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


if __name__ == "__main__":
    main()
