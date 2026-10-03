#!/usr/bin/env bash

# ~/.config/hypr/scripts/brightness.sh
# Adjust screen brightness using brightnessctl and notify Quickshell Brightness OSD
# Rules:
# - 0% to 10%: precise 1% adjustments (allows 0% for privacy)
# - Above 10%: standard 5% jumps

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

CURRENT=$(brightnessctl -m | cut -d',' -f4 | tr -d '%')
CURRENT=${CURRENT:-20}

case "$1" in
    --inc|up)
        if (( CURRENT < 10 )); then
            OUT=$(brightnessctl set 1%+ -m)
        else
            OUT=$(brightnessctl set 5%+ -m)
        fi
        ;;
    --dec|down)
        if (( CURRENT <= 10 )); then
            OUT=$(brightnessctl set 1%- -m)
        elif (( CURRENT - 5 < 10 )); then
            OUT=$(brightnessctl set 10% -m)
        else
            OUT=$(brightnessctl set 5%- -m)
        fi
        ;;
    --set)
        OUT=$(brightnessctl set "$2" -m)
        ;;
    *)
        OUT=$(brightnessctl -m)
        ;;
esac

PCT=$(echo "$OUT" | cut -d',' -f4 | tr -d '%')
if [[ -n "$PCT" ]]; then
    qs ipc call brightness notify "$PCT" >/dev/null 2>&1 || true
fi
