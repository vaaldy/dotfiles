#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
stamp="$(date +%Y%m%d%H%M%S)"

command -v git >/dev/null
command -v npm >/dev/null
node -e 'const [major, minor] = process.versions.node.split(".").map(Number); if (major < 26 || (major === 26 && minor < 7)) throw new Error("Pi session tools require Node >=26.7");'

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
link "$here/macos/.config/paneru/paneru.toml" "$HOME/.config/paneru/paneru.toml"

for script in "$here"/macos/.local/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Shared configuration owned by main
link "$here/mcp/.config/mcp/mcp.json" "$HOME/.config/mcp/mcp.json"
for config in "$here"/yazi/.config/yazi/*; do
  link "$config" "$HOME/.config/yazi/$(basename "$config")"
done

pi="$here/pi/.pi/agent"
if [[ ! -f "$HOME/.pi/agent/settings.json" || -L "$HOME/.pi/agent/settings.json" ]]; then
  link "$pi/settings.json" "$HOME/.pi/agent/settings.json"
fi
link "$pi/APPEND_SYSTEM.md" "$HOME/.pi/agent/APPEND_SYSTEM.md"
if [[ ! -f "$HOME/.pi/agent/models.json" || -L "$HOME/.pi/agent/models.json" ]]; then
  link "$pi/models.json" "$HOME/.pi/agent/models.json"
fi
link "$pi/compact-transcript.json" "$HOME/.pi/agent/compact-transcript.json"
link "$pi/prompts/simulation-improvement-loop.md" "$HOME/.pi/agent/prompts/simulation-improvement-loop.md"
link "$pi/skills/simulation-improvement-loop" "$HOME/.pi/agent/skills/simulation-improvement-loop"
for extension in "$pi"/extensions/*.ts; do
  link "$extension" "$HOME/.pi/agent/extensions/$(basename "$extension")"
done
link "$pi/extensions/subagent/config.json" "$HOME/.pi/agent/extensions/subagent/config.json"
for script in "$pi"/scripts/*; do
  link "$script" "$HOME/.pi/agent/scripts/$(basename "$script")"
done
link "$pi/skills/jira" "$HOME/.pi/agent/skills/jira"
link "$pi/themes/tokyo-night.json" "$HOME/.pi/agent/themes/tokyo-night.json"

# Apply the shared session policy without replacing private Pi configuration.
if [[ ! -L "$HOME/.pi/agent/settings.json" ]]; then
  node --input-type=module - "$pi/settings.json" "$HOME/.pi/agent/settings.json" "$HOME/.pi/agent/models.json" <<'JS'
import { constants, copyFileSync, readFileSync, writeFileSync } from 'node:fs';
const [sharedPath, localPath, modelsPath] = process.argv.slice(2);
const shared = JSON.parse(readFileSync(sharedPath, 'utf8'));
const original = readFileSync(localPath, 'utf8');
const local = JSON.parse(original);
const before = JSON.stringify(local);
local.nunc = { ...local.nunc, ...shared.nunc };
local.compaction ??= {};
local.compaction.modelOverrides ??= {};
const models = JSON.parse(readFileSync(modelsPath, 'utf8'));
for (const model of Object.keys(shared.compaction.modelOverrides)) {
  const separator = model.indexOf('/');
  const window = models.providers?.[model.slice(0, separator)]?.modelOverrides?.[model.slice(separator + 1)]?.contextWindow;
  const existing = local.compaction.modelOverrides[model] ?? {};
  const keep = existing.keepRecentTokens ?? local.compaction.keepRecentTokens ?? 20000;
  if (!Number.isSafeInteger(window) || window <= 250000 || keep >= 250000) {
    console.warn(`Keeping existing compaction settings for ${model}: a compatible explicit context window and retention are required.`);
    continue;
  }
  local.compaction.modelOverrides[model] = { ...existing, reserveTokens: window - 250000 };
}
const source = entry => typeof entry === 'string' ? entry : entry.source;
const nunc = '~/.pi/agent/local-packages/pi-nunc';
local.packages = (local.packages ?? []).filter(entry => !/^npm:pi-smart-compact(?:@|$)/.test(source(entry)));
if (!local.packages.some(entry => source(entry) === nunc)) local.packages.push(nunc);
if (JSON.stringify(local) !== before) {
  copyFileSync(localPath, `${localPath}.bak.${Date.now()}.${process.pid}`, constants.COPYFILE_EXCL);
  writeFileSync(localPath, JSON.stringify(local, null, 2) + '\n');
}
JS
fi

nunc="$HOME/.pi/agent/local-packages/pi-nunc"
nunc_revision="53310dcfec14df2d4600c6dd7edc9a2e29dc0cd0"
if [[ ! -e "$nunc" ]]; then
  mkdir -p "$(dirname "$nunc")"
  git clone https://github.com/tefx/pi-nunc.git "$nunc"
  git -C "$nunc" checkout "$nunc_revision"
fi
if [[ "$(git -C "$nunc" rev-parse HEAD)" != "$nunc_revision" || -n "$(git -C "$nunc" status --porcelain)" ]]; then
  printf 'Nunc checkout must be clean and at %s; leaving it unchanged: %s\n' "$nunc_revision" "$nunc" >&2
  exit 1
fi
(cd "$nunc" && npm ci --ignore-scripts --no-audit --no-fund && npm run build)
(cd "$pi/scripts/durable-loop" && npm ci --ignore-scripts --no-audit --no-fund)
printf 'Pi session tools installed. Run /reload, then /nunc details in Pi.\n'

# Keep the portable shared Term-chan loader working with the existing checkout.
term_chan="$HOME/Documents/term-chan"
if [[ -d "$term_chan" ]]; then
  link "$term_chan" "$HOME/.local/share/term-chan"
fi
