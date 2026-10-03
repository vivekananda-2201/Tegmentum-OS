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
    "$CONV_CMD" "$img" -thumbnail x500 -strip -quality 85 "$out" &

    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n 2>/dev/null || sleep 0.1
        done
    fi
done < <(find "$wallpaper_path" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
\))

wait
echo "Thumbnail generation complete."
