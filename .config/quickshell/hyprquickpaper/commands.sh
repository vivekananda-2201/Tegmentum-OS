#!/usr/bin/env bash
# Central wallpaper hook, called by hyprquickpaper with the chosen image path.

img="$1"
[[ -f "$img" ]] || { echo "commands.sh: not a file: $img" >&2; exit 1; }

mkdir -p "$HOME/.cache"
echo "$img" > "$HOME/.cache/current_wallpaper"

awww img "$img" -t random --transition-duration 1

mkdir -p "$HOME/.cache/43pr"
setsid -f python3 "$HOME/.config/43pr/bin/theme.py" wallpaper "$img" \
    >>"$HOME/.cache/43pr/theme.log" 2>&1
