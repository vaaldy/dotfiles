#!/bin/bash
CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"

BATT_INFO="$(pmset -g batt)"
PERCENTAGE="$(echo "$BATT_INFO" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
CHARGING="$(echo "$BATT_INFO" | grep 'AC Power')"

[ -z "$PERCENTAGE" ] && exit 0

if [ -n "$CHARGING" ]; then
  COLOR=$GREEN
  case "$PERCENTAGE" in
    9[0-9]|100) ICON="󰂅" ;;
    8[0-9])      ICON="󰂋" ;;
    7[0-9])      ICON="󰂊" ;;
    6[0-9])      ICON="󰢞" ;;
    5[0-9])      ICON="󰂉" ;;
    4[0-9])      ICON="󰢝" ;;
    3[0-9])      ICON="󰂈" ;;
    2[0-9])      ICON="󰂇" ;;
    1[0-9])      ICON="󰂆" ;;
    *)           ICON="󰢜" ;;
  esac
else
  COLOR=$FG
  [ "$PERCENTAGE" -le 20 ] && COLOR=$RED
  case "$PERCENTAGE" in
    9[0-9]|100) ICON="󰁹" ;;
    [6-8][0-9])  ICON="󰂀" ;;
    [3-5][0-9])  ICON="󰁾" ;;
    [1-2][0-9])  ICON="󰁻" ;;
    *)           ICON="󰁺" ;;
  esac
fi

sketchybar --animate tanh 15 \
  --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
