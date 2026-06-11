#!/usr/bin/env sh

set -eu

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

monitors_json="$(hyprctl monitors -j)"
monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/monitor-order"

if [ "$monitor_count" -lt 2 ]; then
    exit 0
fi

left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[0].name')"
right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[1].name')"

left_scale="$(printf '%s' "$monitors_json" | jq -r --arg name "$left_monitor" '.[] | select(.name == $name) | .scale')"
right_scale="$(printf '%s' "$monitors_json" | jq -r --arg name "$right_monitor" '.[] | select(.name == $name) | .scale')"
new_left_width="$(printf '%s' "$monitors_json" | jq -r --arg name "$right_monitor" '.[] | select(.name == $name) | ((.width / .scale) | floor)')"

if ! printf '%s\n' "$new_left_width" | grep -Eq '^[0-9]+$'; then
    new_left_width=1920
fi

hyprctl --batch "keyword monitor $right_monitor,preferred,0x0,$right_scale; keyword monitor $left_monitor,preferred,${new_left_width}x0,$left_scale" >/dev/null

mkdir -p "$state_dir"
printf '%s\n%s\n' "$right_monitor" "$left_monitor" > "$state_file"

for workspace in 1 2 3 4 5 6 7 8 9; do
    hyprctl keyword workspace "$workspace,monitor:$left_monitor" >/dev/null
done

for workspace in 10 11 12 13 14 15 16 17 18 19 20; do
    hyprctl keyword workspace "$workspace,monitor:$right_monitor" >/dev/null
done
