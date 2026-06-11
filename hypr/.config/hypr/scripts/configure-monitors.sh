#!/usr/bin/env sh

set -eu

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

monitors_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"
dual_scale="1"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/monitor-order"

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

    hyprctl --batch "keyword monitor $left_monitor,preferred,0x0,$dual_scale; keyword monitor $right_monitor,preferred,${left_width}x0,$dual_scale" >/dev/null

    for workspace in 1 2 3 4 5 6 7 8 9; do
        hyprctl keyword workspace "$workspace,monitor:$right_monitor" >/dev/null
    done

    for workspace in 10 11 12 13 14 15 16 17 18 19 20; do
        hyprctl keyword workspace "$workspace,monitor:$left_monitor" >/dev/null
    done
fi
