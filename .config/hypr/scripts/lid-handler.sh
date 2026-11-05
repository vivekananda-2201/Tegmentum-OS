#!/usr/bin/env bash
# ~/.config/hypr/scripts/lid-handler.sh
# Handles laptop lid open/close and dynamic multi-monitor management in Hyprland
#
# Rules:
# 1. Lid closed + external monitor connected -> Clamshell mode:
#    Internal display is disabled, external monitor becomes absolute primary at 0x0.
# 2. Lid open (at boot, hotplug mid-usage, or opened mid-usage) -> Dual/Laptop mode:
#    Internal laptop screen ALWAYS becomes primary at 0x0.
#    External display(s) extended to the right (at logical internal width x 0).
#    Focus and Workspace 1 anchor to the laptop screen.
# 3. Lid closed + no external displays -> Lock session (hyprlock) and turn off backlight.
# 4. Zero flicker: Idempotent state evaluation skips redundant modesets.

ACTION="${1:-check}"
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 999)
HW_LID_STATE=$(grep -oE 'open|closed' /proc/acpi/button/lid/*/state 2>/dev/null | head -n 1)
HW_LID_STATE="${HW_LID_STATE:-open}"

# Startup grace period: ignore open-lid checks during early boot to prevent DRM modeset collision
if [ "$UPTIME_SEC" -lt 15 ] && [ "$HW_LID_STATE" = "open" ] && [ "$ACTION" != "close" ]; then
    exit 0
fi

python3 - << EOF
import json, subprocess, glob, sys, os, time

action = "$ACTION"
hw_lid = "$HW_LID_STATE"

# Honor explicit action if not contradicted by hardware lid
if action == "close" and hw_lid != "open":
    lid = "closed"
elif action == "open" and hw_lid != "closed":
    lid = "open"
else:
    lid = hw_lid

try:
    raw = subprocess.check_output(["hyprctl", "monitors", "all", "-j"], stderr=subprocess.DEVNULL)
    monitors = json.loads(raw)
except Exception:
    monitors = []

internal = next((m for m in monitors if m.get("name", "").startswith("eDP-")), None)
internal_name = internal.get("name", "eDP-1") if internal else "eDP-1"
internal_disabled = internal.get("disabled", False) if internal else False
internal_scale = internal.get("scale", 1.2) if internal else 1.2
if not internal_scale or internal_scale <= 0:
    internal_scale = 1.2
internal_width = internal.get("width", 1920) if internal else 1920
internal_log_w = int(round(internal_width / internal_scale))

externals = [m for m in monitors if m.get("name") != internal_name]

# Check idempotence to prevent modeset flickering
needs_reconfig = False
needs_shell_restart = False
lua_cmds = []

if lid == "closed":
    if externals:
        # Clamshell mode: internal must be disabled, first external at 0x0
        ext0 = externals[0]
        ext0_scale = ext0.get("scale", 1.2) or 1.2
        if ext0_scale <= 0:
            ext0_scale = 1.2

        if (not internal_disabled or 
            ext0.get("disabled", False) or 
            ext0.get("x") != 0 or 
            ext0.get("y") != 0 or
            not ext0.get("focused", False)):
            needs_reconfig = True

        if internal_disabled is False:
            needs_shell_restart = True

        if needs_reconfig:
            lua_cmds.append(f"hl.monitor({{ output = '{internal_name}', disabled = true }})")
            curr_x = 0
            for i, ext in enumerate(externals):
                e_name = ext.get("name")
                e_scale = ext.get("scale", 1.2) or 1.2
                if e_scale <= 0:
                    e_scale = 1.2
                e_w = ext.get("width", 1920) or 1920
                e_log_w = int(round(e_w / e_scale))
                lua_cmds.append(f"hl.monitor({{ output = '{e_name}', mode = 'preferred', position = '{curr_x}x0', scale = {e_scale}, disabled = false }})")
                curr_x += e_log_w

            lua_cmds.append(f"hl.dispatch(hl.dsp.focus({{ monitor = '{ext0.get('name')}' }}))")
            lua_cmds.append(f"hl.dispatch(hl.dsp.focus({{ workspace = 1 }}))")
    else:
        # Standalone laptop lid closed: hyprlock and display off
        if subprocess.call(["pgrep", "-x", "hyprlock"], stdout=subprocess.DEVNULL) != 0:
            subprocess.Popen(["hyprlock"])
        lua_cmds.append(f"hl.dispatch(hl.dsp.dpms({{ state = false, monitor = '{internal_name}' }}))")
        needs_reconfig = True

else:
    # Lid open: Laptop internal display ALWAYS primary at 0x0
    if (internal_disabled or 
        internal.get("x") != 0 or 
        internal.get("y") != 0 or
        not internal.get("focused", False)):
        needs_reconfig = True

    if internal_disabled is True:
        needs_shell_restart = True

    # Check external monitor positions
    curr_x = internal_log_w
    for ext in externals:
        e_scale = ext.get("scale", 1.2) or 1.2
        if e_scale <= 0:
            e_scale = 1.2
        e_w = ext.get("width", 1920) or 1920
        e_log_w = int(round(e_w / e_scale))
        if ext.get("disabled", False) or ext.get("x") != curr_x or ext.get("y") != 0:
            needs_reconfig = True
        curr_x += e_log_w

    if needs_reconfig:
        lua_cmds.append(f"hl.monitor({{ output = '{internal_name}', mode = 'preferred', position = '0x0', scale = {internal_scale}, disabled = false }})")
        lua_cmds.append(f"hl.dispatch(hl.dsp.dpms({{ state = true, monitor = '{internal_name}' }}))")
        curr_x = internal_log_w
        for ext in externals:
            e_name = ext.get("name")
            e_scale = ext.get("scale", 1.2) or 1.2
            if e_scale <= 0:
                e_scale = 1.2
            e_w = ext.get("width", 1920) or 1920
            e_log_w = int(round(e_w / e_scale))
            lua_cmds.append(f"hl.monitor({{ output = '{e_name}', mode = 'preferred', position = '{curr_x}x0', scale = {e_scale}, disabled = false }})")
            curr_x += e_log_w

        lua_cmds.append(f"hl.dispatch(hl.dsp.focus({{ monitor = '{internal_name}' }}))")
        lua_cmds.append(f"hl.dispatch(hl.dsp.workspace.move({{ workspace = 1, monitor = '{internal_name}' }}))")
        lua_cmds.append(f"hl.dispatch(hl.dsp.focus({{ workspace = 1 }}))")

if needs_reconfig and lua_cmds:
    combined_lua = "; ".join(lua_cmds)
    try:
        subprocess.check_output(["hyprctl", "eval", combined_lua], stderr=subprocess.DEVNULL)
    except Exception:
        pass

# Manage Quickshell adaptation
launch_script = os.path.expanduser("~/.config/hypr/scripts/launch-quickshell.sh")
if needs_shell_restart:
    time.sleep(0.15)
    subprocess.call([launch_script, "--restart"])
elif subprocess.call(["pgrep", "-x", "qs"], stdout=subprocess.DEVNULL) != 0:
    subprocess.call([launch_script])
EOF
