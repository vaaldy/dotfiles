#!/bin/bash
CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"

if [ "$SELECTED" = "true" ]; then
  sketchybar --animate tanh 18 \
    --set "$NAME" \
      background.color="$BLUE" \
      icon.color="$BG_DARK" \
      icon.padding_left=24 \
      icon.padding_right=24 \
      background.padding_left=3 \
      background.padding_right=3
else
  sketchybar --animate tanh 18 \
    --set "$NAME" \
      background.color=0x00000000 \
      icon.color="$MUTED" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      background.padding_left=3 \
      background.padding_right=3
fi
