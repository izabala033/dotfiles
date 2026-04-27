#!/usr/bin/env sh

set -eu

mode="switch"

case "${1:-}" in
    switch|move)
        mode="$1"
        shift
        ;;
esac

right_workspace="${1:-}"
left_workspace="${2:-}"

if [ -z "$right_workspace" ]; then
    echo "usage: $0 [switch|move] <right-workspace-number> [left-workspace-number]" >&2
    exit 1
fi

if ! printf '%s\n' "$right_workspace" | grep -Eq '^[0-9]+$'; then
    echo "right workspace must be a number" >&2
    exit 1
fi

if [ -n "$left_workspace" ] && ! printf '%s\n' "$left_workspace" | grep -Eq '^[0-9]+$'; then
    echo "left workspace must be a number" >&2
    exit 1
fi

monitors_json="$(hyprctl monitors -j)"
monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"

if [ -z "$left_workspace" ]; then
    if [ "$right_workspace" -lt 10 ]; then
        left_workspace=$((right_workspace + 9))
    else
        left_workspace="$right_workspace"
        right_workspace=""
    fi
fi

if [ "$monitor_count" -lt 2 ]; then
    if [ "$mode" = "move" ]; then
        hyprctl dispatch movetoworkspace "${right_workspace:-$left_workspace}"
    else
        hyprctl dispatch workspace "${right_workspace:-$left_workspace}"
    fi
    exit 0
fi

if printf '%s' "$monitors_json" | jq -e '.[] | select(.name == "HDMI-A-2")' >/dev/null 2>&1 &&
   printf '%s' "$monitors_json" | jq -e '.[] | select(.name == "DP-1")' >/dev/null 2>&1; then
    left_monitor="HDMI-A-2"
    right_monitor="DP-1"
else
    left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[0].name')"
    right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[1].name')"
fi
focused_monitor="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.focused == true) | .name')"

batch_cmd=""

if [ "$mode" = "move" ]; then
    if [ -z "$right_workspace" ] || [ "$focused_monitor" = "$left_monitor" ]; then
        move_workspace="$left_workspace"
    else
        move_workspace="$right_workspace"
    fi

    batch_cmd="dispatch movetoworkspace $move_workspace;"
    final_monitor="${focused_monitor:-$left_monitor}"
else
    if [ -z "$right_workspace" ]; then
        final_monitor="$left_monitor"
    else
        final_monitor="$right_monitor"
    fi
fi

batch_cmd="${batch_cmd}dispatch focusmonitor $left_monitor;\
dispatch workspace $left_workspace;"

if [ -n "$right_workspace" ]; then
    batch_cmd="${batch_cmd}dispatch focusmonitor $right_monitor;\
dispatch workspace $right_workspace;"
fi

batch_cmd="${batch_cmd}dispatch focusmonitor $final_monitor"

hyprctl --batch "$batch_cmd"
