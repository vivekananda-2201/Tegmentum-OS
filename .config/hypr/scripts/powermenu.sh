#!/usr/bin/env bash
# Power menu launcher using Rofi

# Toggle behavior: if rofi is open, close it
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

# Options with Nerd Font icons
lock="󰌾  Lock"
suspend="󰤄  Suspend"
hibernate="󰒲  Hibernate"
logout="󰍃  Logout"
reboot="󰑓  Reboot"
shutdown="⏻  Shutdown"

options="${lock}\n${suspend}\n${hibernate}\n${logout}\n${reboot}\n${shutdown}"

chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power" -theme "$HOME/.config/rofi/powermenu.rasi")"

case "$chosen" in
    *Lock*)
        hyprlock
        ;;
    *Suspend*)
        systemctl suspend
        ;;
    *Hibernate*)
        systemctl hibernate
        ;;
    *Logout*)
        hyprctl dispatch exit
        ;;
    *Reboot*)
        systemctl reboot
        ;;
    *Shutdown*)
        systemctl poweroff
        ;;
esac
