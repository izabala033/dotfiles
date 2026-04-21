#!/usr/bin/env sh

set -eu

config_file="${HOME}/.config/hypr/wallpaper.conf"

WALLPAPER_DIR="${HOME}/dotfiles/Wallpapers"
WALLPAPER_IMAGE=""
AWWW_TRANSITION="fade"
AWWW_TRANSITION_DURATION="1"
AWWW_RESIZE="crop"
AWWW_CYCLE_SECONDS="300"

if [ -f "$config_file" ]; then
    # shellcheck disable=SC1090
    . "$config_file"
fi

if ! command -v awww >/dev/null 2>&1 || ! command -v awww-daemon >/dev/null 2>&1; then
    exit 0
fi

lock_dir="${XDG_RUNTIME_DIR:-/tmp}/awww-wallpaper-rotator.lock"

count_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.avif' -o -iname '*.gif' -o -iname '*.jpeg' -o -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) \
        | wc -l | tr -d ' '
}

pick_random_wallpaper() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.avif' -o -iname '*.gif' -o -iname '*.jpeg' -o -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) \
        | shuf -n 1 2>/dev/null || true
}

pick_wallpaper() {
    previous_wallpaper="${1:-}"
    wallpaper_count="$(count_wallpapers)"

    if [ "${wallpaper_count:-0}" -eq 0 ]; then
        return 1
    fi

    attempts=0
    while :; do
        wallpaper="$(pick_random_wallpaper)"

        if [ -z "$wallpaper" ]; then
            return 1
        fi

        if [ "$wallpaper_count" -eq 1 ] || [ "$wallpaper" != "$previous_wallpaper" ]; then
            printf '%s\n' "$wallpaper"
            return 0
        fi

        attempts=$((attempts + 1))
        if [ "$attempts" -ge 5 ]; then
            printf '%s\n' "$wallpaper"
            return 0
        fi
    done
}

ensure_daemon_ready() {
    if ! awww query >/dev/null 2>&1; then
        awww-daemon >/dev/null 2>&1 &
    fi

    ready=0
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if awww query >/dev/null 2>&1; then
            ready=1
            break
        fi

        sleep 0.2
    done

    [ "$ready" -eq 1 ]
}

set_wallpaper() {
    wallpaper="$1"

    ensure_daemon_ready || return 1

    awww img \
        --resize "$AWWW_RESIZE" \
        --transition-type "$AWWW_TRANSITION" \
        --transition-duration "$AWWW_TRANSITION_DURATION" \
        "$wallpaper"
}

cycle_seconds="${AWWW_CYCLE_SECONDS:-300}"
case "$cycle_seconds" in
    ''|*[!0-9]*)
        cycle_seconds="300"
        ;;
esac

if [ -n "$WALLPAPER_IMAGE" ] && [ -f "$WALLPAPER_IMAGE" ]; then
    set_wallpaper "$WALLPAPER_IMAGE"
    exit 0
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    exit 0
fi

if ! mkdir "$lock_dir" 2>/dev/null; then
    exit 0
fi

cleanup() {
    rmdir "$lock_dir" 2>/dev/null || true
}

trap cleanup EXIT HUP INT TERM

current_wallpaper="$(pick_wallpaper '')"

if [ -z "$current_wallpaper" ]; then
    exit 0
fi

set_wallpaper "$current_wallpaper"

if [ "$cycle_seconds" -eq 0 ]; then
    exit 0
fi

while :; do
    sleep "$cycle_seconds"

    next_wallpaper="$(pick_wallpaper "$current_wallpaper")" || continue
    if set_wallpaper "$next_wallpaper"; then
        current_wallpaper="$next_wallpaper"
    fi
done
