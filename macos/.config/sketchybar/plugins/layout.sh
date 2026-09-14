#!/bin/bash

# Show state that is otherwise easy to miss in a BSP/stacked layout.
windows="$(yabai -m query --windows --space 2>/dev/null || true)"
[[ -n "$windows" ]] || exit 0

stacked="$(jq '[.[] | select(."is-visible" == true and ."is-floating" == false and .layer == "normal" and ."stack-index" > 0)] | length' <<<"$windows")"
stacked=$((stacked + 1))

zoomed="$(jq '[.[] | select(."has-focus" == true and ."has-fullscreen-zoom" == true)] | length' <<<"$windows")"

label=""
[[ "$stacked" -gt 1 ]] && label="S:$stacked"
[[ "$zoomed" -gt 0 ]] && label="${label:+$label }Z"

sketchybar --set layout label="$label" drawing=on
