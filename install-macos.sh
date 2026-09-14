#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
stamp="$(date +%Y%m%d%H%M%S)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    [[ "$(readlink "$dst")" == "$src" ]] && return
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$dst.bak.$stamp"
  fi
  ln -s "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
}

# macOS host configuration
link "$here/macos/.zshenv" "$HOME/.zshenv"
link "$here/macos/.config/bash/env" "$HOME/.config/bash/env"
link "$here/macos/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
link "$here/macos/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$here/nvim/.config/nvim" "$HOME/.config/nvim"
link "$here/macos/.gitconfig" "$HOME/.gitconfig"
link "$here/macos/.config/git/ignore" "$HOME/.config/git/ignore"
link "$here/macos/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
link "$here/macos/.config/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
link "$here/macos/.config/spicetify" "$HOME/.config/spicetify"
link "$here/macos/.config/yabai/yabairc" "$HOME/.config/yabai/yabairc"
link "$here/macos/.config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
link "$here/macos/.config/borders/bordersrc" "$HOME/.config/borders/bordersrc"
link "$here/macos/.config/sketchybar" "$HOME/.config/sketchybar"
link "$here/macos/.config/paneru/paneru.toml" "$HOME/.config/paneru/paneru.toml"

for script in "$here"/macos/.local/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Shared configuration owned by main
link "$here/mcp/.config/mcp/mcp.json" "$HOME/.config/mcp/mcp.json"
link "$here/yazi/.config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

pi="$here/pi/.pi/agent"
link "$pi/settings.json" "$HOME/.pi/agent/settings.json"
link "$pi/APPEND_SYSTEM.md" "$HOME/.pi/agent/APPEND_SYSTEM.md"
link "$pi/models.json" "$HOME/.pi/agent/models.json"
link "$pi/compact-transcript.json" "$HOME/.pi/agent/compact-transcript.json"
for extension in "$pi"/extensions/*.ts; do
  link "$extension" "$HOME/.pi/agent/extensions/$(basename "$extension")"
done
link "$pi/skills/jira" "$HOME/.pi/agent/skills/jira"
link "$pi/themes/tokyo-night.json" "$HOME/.pi/agent/themes/tokyo-night.json"

# Keep the portable shared Term-chan loader working with the existing checkout.
term_chan="$HOME/Documents/term-chan"
if [[ -d "$term_chan" ]]; then
  link "$term_chan" "$HOME/.local/share/term-chan"
fi
