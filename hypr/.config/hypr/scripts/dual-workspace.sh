#!/usr/bin/env sh

set -eu

mode="switch"

dispatch_lua() {
    hyprctl dispatch "$1"
}

dispatch_batch() {
    hyprctl --batch "$1" >/dev/null
}

focus_monitor() {
    dispatch_lua "hl.dsp.focus({ monitor = \"$1\" })"
}

focus_workspace() {
    dispatch_lua "hl.dsp.focus({ workspace = \"$1\" })"
}

move_to_workspace() {
    dispatch_lua "hl.dsp.window.move({ workspace = \"$1\" })"
}

get_monitors_json() {
    attempt=0

    while [ "$attempt" -lt 3 ]; do
        if monitors_json="$(hyprctl monitors -j 2>/dev/null)" &&
           printf '%s' "$monitors_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
            printf '%s' "$monitors_json"
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 0.05
    done

    echo "unable to read Hyprland monitors" >&2
    return 1
}

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

monitors_json="$(get_monitors_json)"
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
        move_to_workspace "${right_workspace:-$left_workspace}"
    else
        focus_workspace "${right_workspace:-$left_workspace}"
    fi
    exit 0
fi

left_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[0].name')"
right_monitor="$(printf '%s' "$monitors_json" | jq -r 'sort_by(.x, .id) | .[1].name')"
focused_monitor="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.focused == true) | .name')"

if [ "$mode" = "move" ]; then
    if [ -z "$right_workspace" ] || [ "$focused_monitor" = "$left_monitor" ]; then
        move_workspace="$left_workspace"
    else
        move_workspace="$right_workspace"
    fi

    move_to_workspace "$move_workspace"
    final_monitor="${focused_monitor:-$left_monitor}"
else
    if [ -z "$right_workspace" ]; then
        final_monitor="$left_monitor"
    else
        final_monitor="$right_monitor"
    fi
fi

batch="dispatch hl.dsp.focus({ monitor = \"$left_monitor\" }); dispatch hl.dsp.focus({ workspace = \"$left_workspace\" })"

if [ -n "$right_workspace" ]; then
    batch="$batch; dispatch hl.dsp.focus({ monitor = \"$right_monitor\" }); dispatch hl.dsp.focus({ workspace = \"$right_workspace\" })"
fi

batch="$batch; dispatch hl.dsp.focus({ monitor = \"$final_monitor\" })"
dispatch_batch "$batch"
