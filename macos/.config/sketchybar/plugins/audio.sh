#!/bin/bash

device="$(system_profiler SPAudioDataType -json 2>/dev/null \
  | jq -r '[.. | objects | select(.coreaudio_default_audio_output_device? == "spaudio_yes") | ._name] | first // ""')"

if [[ "$device" == *"MacBook Pro Speakers"* ]]; then
  icon="󰕾"
else
  icon="󰋋"
fi

sketchybar --set volume_icon icon="$icon"
