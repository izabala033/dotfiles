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

monitors_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"
dual_scale="1"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/monitor-order"

monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"

if [ "$monitor_count" -ge 2 ]; then
    left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[0].name')"
    right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[1].name')"

    if [ -r "$state_file" ]; then
        state_left="$(sed -n '1p' "$state_file")"
        state_right="$(sed -n '2p' "$state_file")"

        if [ "$state_left" != "$state_right" ] &&
           printf '%s' "$monitors_json" | jq -e --arg name "$state_left" '.[] | select(.name == $name)' >/dev/null 2>&1 &&
           printf '%s' "$monitors_json" | jq -e --arg name "$state_right" '.[] | select(.name == $name)' >/dev/null 2>&1; then
            left_monitor="$state_left"
            right_monitor="$state_right"
        fi
    fi

    left_width="$(printf '%s' "$monitors_json" | jq -r --arg name "$left_monitor" --argjson scale "$dual_scale" '.[] | select(.name == $name) | ((.width / $scale) | floor)')"

    if ! printf '%s\n' "$left_width" | grep -Eq '^[0-9]+$'; then
        left_width=1920
    fi

    set_monitor "$left_monitor" "$dual_scale" "0x0"
    set_monitor "$right_monitor" "$dual_scale" "${left_width}x0"

    mkdir -p "$state_dir"
    printf '%s\n%s\n' "$left_monitor" "$right_monitor" > "$state_file"

    for workspace in 1 2 3 4 5 6 7 8 9; do
        set_workspace_monitor "$workspace" "$right_monitor"
    done

    for workspace in 10 11 12 13 14 15 16 17 18 19 20; do
        set_workspace_monitor "$workspace" "$left_monitor"
    done
fi
