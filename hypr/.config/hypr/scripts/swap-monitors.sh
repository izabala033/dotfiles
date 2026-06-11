#!/usr/bin/env sh

set -eu

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

lua_string() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

set_monitor() {
    output="$(lua_string "$1")"
    position="$(lua_string "$3")"
    hyprctl eval "hl.monitor({ output = \"$output\", mode = \"preferred\", position = \"$position\", scale = $2 })" >/dev/null
}

set_workspace_monitor() {
    monitor="$(lua_string "$2")"
    hyprctl eval "hl.workspace_rule({ workspace = \"$1\", monitor = \"$monitor\" })" >/dev/null
}

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

set_monitor "$right_monitor" "$right_scale" "0x0"
set_monitor "$left_monitor" "$left_scale" "${new_left_width}x0"

mkdir -p "$state_dir"
printf '%s\n%s\n' "$right_monitor" "$left_monitor" > "$state_file"

for workspace in 1 2 3 4 5 6 7 8 9; do
    set_workspace_monitor "$workspace" "$left_monitor"
done

for workspace in 10 11 12 13 14 15 16 17 18 19 20; do
    set_workspace_monitor "$workspace" "$right_monitor"
done
