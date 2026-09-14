# dotfiles

CachyOS + niri + noctalia. Managed with [GNU stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a *stow package* whose contents mirror the path
relative to `$HOME`:

```
alacritty/.config/alacritty/   ->  ~/.config/alacritty/
niri/.config/niri/             ->  ~/.config/niri/
nvim/.config/nvim/             ->  ~/.config/nvim/
tmux/.config/tmux/             ->  ~/.config/tmux/
fish/.config/fish/             ->  ~/.config/fish/
noctalia/.config/noctalia/     ->  ~/.config/noctalia/
mcp/.config/mcp/               ->  ~/.config/mcp/
pi/.pi/agent/                  ->  ~/.pi/agent/
yazi/.config/yazi/             ->  ~/.config/yazi/
```

## Usage

```fish
cd ~/dotfiles

stow alacritty niri nvim tmux fish noctalia mcp yazi
mkdir -p ~/.pi/agent && stow --no-folding pi # keep Pi runtime state outside the repo
stow -R niri                                  # re-link after adding files
stow -D niri                                  # unlink
stow -n -v alacritty                          # dry run
```

## Terminal stack

`tmux` + `nvim` are a port of a macOS setup, adapted rather than copied — see
`HANDOFF-tmux-nvim.md` for the constraints that shaped it. The short version:

- **tmux prefix is `C-Space`.** niri binds everything on `Mod` (Super), so the
  two never collide. If tmux stops responding to the prefix, check for an input
  method stealing it: `pgrep -x fcitx5; pgrep -x ibus-daemon`.
- **`C-h/j/k/l` move between panes**, transparently across the tmux/nvim
  boundary (`vim-tmux-navigator` plus the `is_vim` check in `tmux.conf`).
- **`C-j` reaches interactive agents**, including Pi and Codex, instead of
  moving to the tmux pane below.
- **Colors are shared, not merely similar.** rose-pine's `base`/`surface`/
  `overlay` are pinned to the Alacritty background, the tmux status bar and the
  pane border respectively, so all three layers agree to the byte:

  | value     | where it comes from                    | used by                          |
  |-----------|----------------------------------------|----------------------------------|
  | `#201A28` | `alacritty/alacritty.toml` background | nvim `Normal`                    |
  | `#2A2136` | tmux `status-style` bg                 | nvim `NormalFloat`, `StatusLine` |
  | `#382E47` | tmux `pane-border-style`               | nvim `CursorLine`                |

  Change one and change all three, or they drift apart.
- The macOS config's **agentic bindings** (`prefix f/a/A/t/T/G`, which call the
  `tsess` / `agentproj` / `agentwt` helper scripts) are present but commented
  out at the foot of `tmux.conf` — the scripts aren't installed on this machine
  yet.

## Pi

The `/btw` extension uses tmux and zoxide. The `/term-chan` extension expects
[term-chan](https://github.com/vaaldy/term-chan) under
`~/.local/share/term-chan` (override with `TERM_CHAN_PI_INTEGRATION`):

```fish
git clone https://github.com/vaaldy/term-chan ~/.local/share/term-chan
```

## Not tracked

- `fish_variables` — fish universal variables, host-specific and mode 0600.
- Plugin checkouts, which lazy.nvim keeps in `~/.local/share/nvim/lazy/` and so
  are outside this repo anyway. `lazy-lock.json` *is* tracked so versions pin.

## Branches

`main` is the shared Linux starting point. `pc` and `laptop` contain only
device-specific changes on top of it. The separate macOS repository is the
reference for portable terminal and Pi updates.
