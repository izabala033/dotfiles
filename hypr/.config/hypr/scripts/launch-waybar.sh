#!/usr/bin/env sh

set -eu

pkill -x waybar >/dev/null 2>&1 || true

exec waybar
