#!/bin/bash

CONFIG_DIR="$HOME/.config/sketchybar"
PLUGIN_DIR="$CONFIG_DIR/plugins"
source "$CONFIG_DIR/colors.sh"

# Space switches only update styling via space.sh. Rebuild inventory solely when it changed.
focused="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')"
desired="$(yabai -m query --displays 2>/dev/null | jq -r '
  sort_by(.index)[] | .index as $display | .spaces | sort[]
  | "space.\($display).\(.)"')"
current="$(sketchybar --query bar 2>/dev/null | jq -r '
  [.items[] | select(startswith("space."))] | sort | .[]')"
[[ "$(sort <<<"$desired")" == "$current" ]] && exit 0

args=(--remove '/space\..*/')
while IFS=. read -r _ display space; do
  [[ -n "$space" ]] || continue
  name="space.$display.$space"
  if [[ "$space" == "$focused" ]]; then
    color=$BLUE icon_color=$BG_DARK icon_pad=24
  else
    color=0x00000000 icon_color=$MUTED icon_pad=8
  fi
  args+=(--add space "$name" left
         --set "$name" space="$space" display="$display" icon="$space"
           script="$PLUGIN_DIR/space.sh"
           background.color="$color" icon.color="$icon_color"
           background.corner_radius=9
           background.height=24 background.drawing=on label.drawing=off
           icon.align=center
           icon.padding_left="$icon_pad" icon.padding_right="$icon_pad"
           background.padding_left=3 background.padding_right=3
           click_script="yabai -m space --focus $space 2>/dev/null"
         --subscribe "$name" space_change
         --move "$name" before spaces_end)
done <<<"$desired"

sketchybar "${args[@]}" >/dev/null
