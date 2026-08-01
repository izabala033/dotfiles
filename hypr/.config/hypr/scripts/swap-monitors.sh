#!/usr/bin/env sh

set -eu

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/monitor-order"

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

monitors_json="$(hyprctl monitors -j)"
monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"

if [ "$monitor_count" -lt 2 ]; then
    exit 0
fi

monitor_exists() {
    printf '%s' "$monitors_json" | jq -e --arg name "$1" '.[] | select(.name == $name)' >/dev/null
}

left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[0].name')"
right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[1].name')"

if [ -r "$state_file" ]; then
    saved_left="$(sed -n '1p' "$state_file")"
    saved_right="$(sed -n '2p' "$state_file")"

    if [ -n "$saved_left" ] && [ -n "$saved_right" ] && [ "$saved_left" != "$saved_right" ] &&
       monitor_exists "$saved_left" && monitor_exists "$saved_right"; then
        left_monitor="$saved_left"
        right_monitor="$saved_right"
    fi
fi

mkdir -p "$state_dir"
printf '%s\n%s\n' "$right_monitor" "$left_monitor" > "$state_file"

hyprctl reload config-only >/dev/null
