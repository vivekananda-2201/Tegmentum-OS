#!/usr/bin/env bash

CONFIG="$1/config.json"

expand_home() {
    local path="$1"

    if [[ "$path" == '$HOME' ]]; then
        printf '%s\n' "$HOME"
    elif [[ "$path" == '$HOME/'* ]]; then
        printf '%s/%s\n' "$HOME" "${path#'$HOME/'}"
    else
        printf '%s\n' "$path"
    fi
}

get_json() {
    local key="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$key" "$CONFIG"
    else
        python3 -c "import json; d=json.load(open('$CONFIG')); print(d.get('$key', ''))"
    fi
}

wallpaper_path=$(expand_home "$(get_json 'wallpaper_path')")
cache_path=$(expand_home "$(get_json 'cache_path')")
cache_batch_size=$(get_json 'cache_batch_size')
[[ -z "$cache_batch_size" || "$cache_batch_size" == "null" ]] && cache_batch_size=20

mkdir -p "$cache_path"

echo "Wallpaper path: $wallpaper_path"
echo "Cache path: $cache_path"

CONV_CMD="magick"
command -v magick >/dev/null 2>&1 || CONV_CMD="convert"

while read -r img; do
    [[ -n "$img" ]] || continue
    filename=$(basename "$img")
    out="$cache_path/$filename"

    if [[ -f "$out" && -s "$out" ]]; then
        continue
    fi

    echo "Generating thumbnail for $filename"
    ext="${filename##*.}"
    ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    case "$ext_lower" in
        mp4|webm|mkv|mov)
            ffmpeg -y -i "$img" -vframes 1 -vf "scale=-1:500" -q:v 2 -f image2 -update 1 "$out" -loglevel error 2>/dev/null &
            ;;
        gif)
            "$CONV_CMD" "${img}[0]" -thumbnail x500 -strip -quality 85 "$out" &
            ;;
        *)
            "$CONV_CMD" "$img" -thumbnail x500 -strip -quality 85 "$out" &
            ;;
    esac

    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n 2>/dev/null || sleep 0.1
        done
    fi
done < <(find "$wallpaper_path" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" -o \
    -iname "*.gif" -o \
    -iname "*.mp4" -o \
    -iname "*.webm" -o \
    -iname "*.mkv" -o \
    -iname "*.mov" \
\))

wait
echo "Thumbnail generation complete."
