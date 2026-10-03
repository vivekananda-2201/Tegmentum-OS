#!/usr/bin/env bash
# ~/.config/hypr/scripts/lid-handler.sh
# Handles laptop lid open/close events cleanly in Hyprland without system sleep

ACTION="$1"

# Identify internal monitor dynamically (fallback to eDP-1)
INTERNAL_MONITOR=$(hyprctl monitors 2>/dev/null | grep -E '^Monitor ' | grep -oE 'eDP-[0-9]+' | head -n 1)
INTERNAL_MONITOR="${INTERNAL_MONITOR:-eDP-1}"

# Count external monitors (excluding internal display)
EXTERNAL_COUNT=$(hyprctl monitors 2>/dev/null | grep -E '^Monitor ' | grep -v "$INTERNAL_MONITOR" | wc -l)

case "$ACTION" in
    close)
        if [ "$EXTERNAL_COUNT" -gt 0 ]; then
            # External display is connected: keep it intact, turn off only the laptop screen
            hyprctl dispatch "hl.dsp.dpms(\"off\", \"$INTERNAL_MONITOR\")"
        else
            # Standalone laptop: lock session first, then turn off display
            if ! pgrep -x hyprlock >/dev/null; then
                hyprlock &
            fi
            sleep 0.2
            hyprctl dispatch "hl.dsp.dpms(\"off\", \"$INTERNAL_MONITOR\")"
        fi
        ;;
    open)
        # If standalone laptop and hyprlock is not running, ensure screen is locked
        if [ "$EXTERNAL_COUNT" -eq 0 ] && ! pgrep -x hyprlock >/dev/null; then
            hyprlock &
        fi
        # Turn laptop screen back on immediately
        hyprctl dispatch "hl.dsp.dpms(\"on\", \"$INTERNAL_MONITOR\")"
        ;;
    *)
        echo "Usage: $0 {close|open}"
        exit 1
        ;;
esac
