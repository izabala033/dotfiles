#!/usr/bin/env sh

set -eu

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

monitors_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"

has_monitor() {
    printf '%s' "$monitors_json" | jq -e --arg name "$1" '.[] | select(.name == $name)' >/dev/null 2>&1
}

if has_monitor "HDMI-A-2" && has_monitor "DP-1"; then
    left_width="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "HDMI-A-2") | ((.width / .scale) | floor)')"

    if ! printf '%s\n' "$left_width" | grep -Eq '^[0-9]+$'; then
        left_width=1920
    fi

    hyprctl --batch "keyword monitor HDMI-A-2,preferred,0x0,1; keyword monitor DP-1,preferred,${left_width}x0,1" >/dev/null
fi
