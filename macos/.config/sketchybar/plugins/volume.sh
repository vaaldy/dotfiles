#!/bin/bash

TARGET="${NAME:-volume}"

# When user drags/clicks the slider, SketchyBar sends mouse.clicked with $PERCENTAGE
if [ "$SENDER" = "mouse.clicked" ]; then
  if [ -n "$PERCENTAGE" ]; then
    osascript -e "set volume output volume $PERCENTAGE" >/dev/null 2>&1
    sketchybar --set "$TARGET" slider.percentage="$PERCENTAGE"
  fi
  exit 0
fi

# When macOS volume changes, SketchyBar sends volume_change with $INFO (0-100)
if [ "$SENDER" = "volume_change" ] && [ -n "$INFO" ]; then
  sketchybar --set "$TARGET" slider.percentage="$INFO"
  exit 0
fi

# Fallback for startup, wake from sleep, or periodic polling (routine)
VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo 0)"
sketchybar --set "$TARGET" slider.percentage="$VOLUME"
