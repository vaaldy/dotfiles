#!/bin/bash

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"

cur_win="$(yabai -m query --windows --window 2>/dev/null)"
if [[ -n "$cur_win" ]]; then
  cur_id="$(jq -r '.id // empty' <<<"$cur_win")"
  cur_space="$(jq -r '.space // empty' <<<"$cur_win")"
  [[ -n "$cur_id" && -n "$cur_space" ]] && echo "$cur_id" > "/tmp/yabai_last_focus_space_${cur_space}"
fi

windows="$(yabai -m query --windows 2>/dev/null)"
[[ -z "$windows" ]] && exit 0

active_map='{}'
for f in /tmp/yabai_last_focus_space_*; do
  [[ -f "$f" ]] || continue
  sp="${f##*_}"
  wid="$(<"$f")"
  [[ -n "$wid" ]] && active_map="$(jq -c --arg sp "$sp" --arg wid "$wid" '. + {($sp): ($wid|tonumber)}' <<<"$active_map")"
done

args=(--animate tanh 18)
while IFS=$'\t' read -r display id is_active; do
  [[ -n "$id" ]] || continue
  name="app.$display.$id"
  if [[ "$is_active" == "true" ]]; then
    color=$PURPLE text=$BG_DARK
  else
    color=0x00000000 text=$MUTED
  fi
  args+=(--set "$name"
         background.color="$color" label.color="$text")
done < <(jq -nr \
  --argjson windows "$windows" \
  --argjson active_map "$active_map" \
  '
  ($windows | [.[] | select(."is-minimized" == false and ."is-hidden" == false and (.layer == "normal" or (.app | test("paraview"; "i"))) and (."subrole" == "AXStandardWindow" or (."role" == "AXWindow" and ."can-move" == true) or (.app | test("paraview"; "i"))) and .app != "" and .title != "")]) as $std_wins |
  $std_wins | group_by(.space) | map(
    . as $space_wins |
    ($space_wins[0].space | tostring) as $sp |
    ( ([$space_wins[] | select(."has-focus" == true)][0].id) //
      ($active_map[$sp]) //
      $space_wins[0].id
    ) as $active_id |
    $space_wins[] | [ .display, .id, (.id == $active_id) ]
  )[] | @tsv
')

((${#args[@]} > 3)) && sketchybar "${args[@]}" >/dev/null 2>&1
