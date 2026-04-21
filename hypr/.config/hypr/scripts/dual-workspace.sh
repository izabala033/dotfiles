#!/usr/bin/env sh

set -eu

mode="switch"

case "${1:-}" in
    switch|move)
        mode="$1"
        shift
        ;;
esac

left_workspace="${1:-}"
right_workspace="${2:-}"

if [ -z "$left_workspace" ]; then
    echo "usage: $0 [switch|move] <left-workspace-number> [right-workspace-number]" >&2
    exit 1
fi

if ! printf '%s\n' "$left_workspace" | grep -Eq '^[0-9]+$'; then
    echo "left workspace must be a number" >&2
    exit 1
fi

if [ -n "$right_workspace" ] && ! printf '%s\n' "$right_workspace" | grep -Eq '^[0-9]+$'; then
    echo "right workspace must be a number" >&2
    exit 1
fi

monitors_json="$(hyprctl monitors -j)"
monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"

if [ -z "$right_workspace" ]; then
    right_workspace=$((left_workspace + 10))
fi

if [ "$monitor_count" -lt 2 ]; then
    if [ "$mode" = "move" ]; then
        hyprctl dispatch movetoworkspace "$left_workspace"
    else
        hyprctl dispatch workspace "$left_workspace"
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
    batch_cmd="dispatch movetoworkspace $left_workspace;"
    final_monitor="${focused_monitor:-$left_monitor}"
else
    final_monitor="$left_monitor"
fi

batch_cmd="${batch_cmd}dispatch focusmonitor $left_monitor;\
dispatch workspace $left_workspace;\
dispatch focusmonitor $right_monitor;\
dispatch workspace $right_workspace;\
dispatch focusmonitor $final_monitor"

hyprctl --batch "$batch_cmd"
