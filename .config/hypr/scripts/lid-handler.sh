#!/usr/bin/env bash
# ~/.config/hypr/scripts/lid-handler.sh
# Handles laptop lid open/close and clamshell mode in Hyprland without system sleep

ACTION="${1:-check}"

# Startup grace period: ignore disruptive lid switch events during early boot
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 999)

# Read hardware ACPI lid state if available ('open' or 'closed')
HW_LID_STATE=$(grep -oE 'open|closed' /proc/acpi/button/lid/*/state 2>/dev/null | head -n 1)

# Query internal monitor name, disabled state, and active external monitor count via Hyprland JSON
query_monitors() {
    python3 -c "
import json, subprocess
try:
    raw = subprocess.check_output(['hyprctl', 'monitors', 'all', '-j'], stderr=subprocess.DEVNULL)
    monitors = json.loads(raw)
except Exception:
    monitors = []
internal = next((m for m in monitors if m.get('name', '').startswith('eDP-')), None)
internal_name = internal.get('name', 'eDP-1') if internal else 'eDP-1'
internal_disabled = '1' if (internal and internal.get('disabled', False)) else '0'
external_active = [m.get('name', '') for m in monitors if m.get('name') != internal_name and not m.get('disabled', False)]
print(f'{internal_name}|{internal_disabled}|{len(external_active)}')
" 2>/dev/null
}

IFS='|' read -r INTERNAL_MONITOR INTERNAL_DISABLED EXTERNAL_COUNT <<< "$(query_monitors)"
INTERNAL_MONITOR="${INTERNAL_MONITOR:-eDP-1}"
INTERNAL_DISABLED="${INTERNAL_DISABLED:-0}"
EXTERNAL_COUNT="${EXTERNAL_COUNT:-0}"

apply_close() {
    if [ "$EXTERNAL_COUNT" -gt 0 ]; then
        # Clamshell mode with external display connected:
        # Fully disable the internal display so Hyprland migrates all workspaces
        # and windows to the active external monitor(s) seamlessly.
        if [ "$INTERNAL_DISABLED" -ne 1 ]; then
            hyprctl eval "hl.monitor({ output = '$INTERNAL_MONITOR', disabled = true })" >/dev/null 2>&1
        fi
    else
        # Standalone laptop: lock session first, then turn off display backlight
        if ! pgrep -x hyprlock >/dev/null; then
            hyprlock &
        fi
        sleep 0.2
        hyprctl eval "hl.dispatch(hl.dsp.dpms({ state = false, monitor = '$INTERNAL_MONITOR' }))" >/dev/null 2>&1
    fi

    # Ensure Quickshell remains running across display transitions
    ensure_quickshell
}

apply_open() {
    # Turn internal monitor backlight on
    hyprctl eval "hl.dispatch(hl.dsp.dpms({ state = true, monitor = '$INTERNAL_MONITOR' }))" >/dev/null 2>&1

    # Re-enable the internal monitor if it was disabled
    if [ "$INTERNAL_DISABLED" -eq 1 ]; then
        hyprctl eval "hl.monitor({ output = '$INTERNAL_MONITOR', disabled = false })" >/dev/null 2>&1

        # Re-apply user's display layout from monitors.lua if present
        MON_LUA="$HOME/.config/hypr/monitors.lua"
        if [ -f "$MON_LUA" ]; then
            hyprctl eval "pcall(dofile, '$MON_LUA')" >/dev/null 2>&1
        else
            hyprctl eval "hl.monitor({ output = '$INTERNAL_MONITOR', mode = 'preferred', position = 'auto', scale = 1.2 })" >/dev/null 2>&1
        fi
    fi

    # Ensure Quickshell remains running across display transitions
    ensure_quickshell
}

ensure_quickshell() {
    LAUNCH_SCRIPT="$HOME/.config/hypr/scripts/launch-quickshell.sh"
    if [ -x "$LAUNCH_SCRIPT" ]; then
        "$LAUNCH_SCRIPT"
    elif ! pgrep -x qs >/dev/null 2>&1; then
        systemctl --user reset-failed quickshell >/dev/null 2>&1 || true
        systemd-run --user --unit=quickshell qs >/dev/null 2>&1 || (nohup qs >/dev/null 2>&1 &)
    fi
}

case "$ACTION" in
    close)
        # Prevent synthetic switch events from blanking the screen on startup or when the lid is actually open
        if [ "$UPTIME_SEC" -lt 15 ] || [ "$HW_LID_STATE" = "open" ]; then
            exit 0
        fi
        apply_close
        ;;
    open)
        if [ "$HW_LID_STATE" = "closed" ]; then
            exit 0
        fi
        apply_open
        ;;
    check|init)
        if [ "$HW_LID_STATE" = "closed" ]; then
            apply_close
        else
            apply_open
        fi
        ;;
    *)
        echo "Usage: $0 {close|open|check}"
        exit 1
        ;;
esac
