#!/usr/bin/env bash
# ~/.config/hypr/scripts/restore-wallpaper.sh
# Restores active wallpaper (image, animated GIF, or MP4 video) on session startup

WP="$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)"

awww-daemon &

if [[ -f "$WP" ]]; then
    ext="${WP##*.}"
    ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    case "$ext_lower" in
        mp4|webm|mkv|mov)
            sleep 0.5
            setsid -f mpvpaper -p -o "no-audio loop hwdec=auto" ALL "$WP" >/dev/null 2>&1
            exit 0
            ;;
    esac
fi

awww restore &
