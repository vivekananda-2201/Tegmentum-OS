#!/usr/bin/env bash
# Central wallpaper hook, called by hyprquickpaper with the chosen image or video path.

target="$1"
[[ -f "$target" ]] || { echo "commands.sh: not a file: $target" >&2; exit 1; }

mkdir -p "$HOME/.cache"
echo "$target" > "$HOME/.cache/current_wallpaper"

ext="${target##*.}"
ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

CACHE_DIR="$HOME/.cache/quickshell/thumbs"
mkdir -p "$CACHE_DIR"
filename="$(basename "$target")"
thumb_file="$CACHE_DIR/$filename"

case "$ext_lower" in
    mp4|webm|mkv|mov)
        # Ensure preview thumbnail exists for palette extraction
        if [ ! -f "$thumb_file" ] || [ ! -s "$thumb_file" ]; then
            ffmpeg -y -i "$target" -vframes 1 -vf "scale=-1:500" -q:v 2 -f image2 -update 1 "$thumb_file" -loglevel error 2>/dev/null
        fi

        # Stop any existing mpvpaper instance
        pkill -x mpvpaper 2>/dev/null || true
        sleep 0.1

        # Launch video wallpaper across all outputs with auto-pause when windows cover it
        setsid -f mpvpaper -p -o "no-audio loop hwdec=auto" ALL "$target" >/dev/null 2>&1

        # Extract theme palette from video thumbnail
        mkdir -p "$HOME/.cache/tegmentum"
        setsid -f python3 "$HOME/.config/tegmentum/bin/theme.py" wallpaper "$thumb_file" \
            >>"$HOME/.cache/tegmentum/theme.log" 2>&1
        ;;
    *)
        # Stop video wallpaper if switching back to image or GIF
        pkill -x mpvpaper 2>/dev/null || true

        # Display static image or animated GIF via awww
        awww img "$target" -t random --transition-duration 1

        mkdir -p "$HOME/.cache/tegmentum"
        setsid -f python3 "$HOME/.config/tegmentum/bin/theme.py" wallpaper "$target" \
            >>"$HOME/.cache/tegmentum/theme.log" 2>&1
        ;;
esac
