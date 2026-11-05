#!/usr/bin/env bash
# ~/.config/hypr/scripts/toggle-power-profile.sh
# Cycles through system power profiles: Balanced -> Performance -> Power Saver
# and sends an instant visual notification

CURRENT=$(powerprofilesctl get 2>/dev/null || echo "balanced")

case "$CURRENT" in
    balanced)
        NEXT="performance"
        TITLE="Performance Mode"
        DESC="Maximum CPU boost and GPU throughput"
        ICON="speedometer"
        ;;
    performance)
        NEXT="power-saver"
        TITLE="Power Saver Mode"
        DESC="Conservative clock frequencies for maximum battery life"
        ICON="battery-low"
        ;;
    power-saver|*)
        NEXT="balanced"
        TITLE="Balanced Mode"
        DESC="Dynamic scaling: full boost on demand, cool and quiet at idle"
        ICON="battery-good"
        ;;
esac

powerprofilesctl set "$NEXT" 2>/dev/null || true

if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2000 -a "Power Profile" -i "$ICON" "$TITLE" "$DESC"
fi
