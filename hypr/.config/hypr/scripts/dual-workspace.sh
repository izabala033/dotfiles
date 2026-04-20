#!/usr/bin/env sh

set -eu

mode="${1:-switch}"
base_workspace="${2:-}"

if [ "$mode" != "switch" ] && [ "$mode" != "move" ]; then
    base_workspace="$mode"
    mode="switch"
fi

if [ -z "$base_workspace" ]; then
    echo "usage: $0 [switch|move] <workspace-number>" >&2
    exit 1
fi

if ! printf '%s\n' "$base_workspace" | grep -Eq '^[0-9]+$'; then
    echo "workspace must be a number" >&2
    exit 1
fi

monitors_json="$(hyprctl monitors -j)"
monitor_count="$(printf '%s' "$monitors_json" | jq 'length')"

if [ "$monitor_count" -lt 2 ]; then
    if [ "$mode" = "move" ]; then
        hyprctl dispatch movetoworkspace "$base_workspace"
    else
        hyprctl dispatch workspace "$base_workspace"
    fi
    exit 0
fi

left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.id) | .[0].name')"
right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.id) | .[1].name')"
focused_monitor="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.focused == true) | .name')"
paired_workspace=$((base_workspace + 10))

batch_cmd=""

if [ "$mode" = "move" ]; then
    batch_cmd="dispatch movetoworkspace $base_workspace;"
fi

batch_cmd="${batch_cmd}dispatch focusmonitor $left_monitor;\
dispatch workspace $base_workspace;\
dispatch focusmonitor $right_monitor;\
dispatch workspace $paired_workspace;\
dispatch focusmonitor $focused_monitor"

hyprctl --batch "$batch_cmd"
