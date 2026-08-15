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
```

## Usage

```fish
cd ~/dotfiles

stow alacritty niri nvim tmux fish noctalia   # link everything
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
- **Colors are shared, not merely similar.** rose-pine's `base`/`surface`/
  `overlay` are pinned to the Alacritty background, the tmux status bar and the
  pane border respectively, so all three layers agree to the byte:

  | value     | where it comes from                    | used by                          |
  |-----------|----------------------------------------|----------------------------------|
  | `#201A28` | `alacritty/themes/noctalia.toml` bg    | nvim `Normal`                    |
  | `#2A2136` | tmux `status-style` bg                 | nvim `NormalFloat`, `StatusLine` |
  | `#382E47` | tmux `pane-border-style`               | nvim `CursorLine`                |

  Change one and change all three, or they drift apart.
- The macOS config's **agentic bindings** (`prefix f/a/A/t/T/G`, which call the
  `tsess` / `agentproj` / `agentwt` helper scripts) are present but commented
  out at the foot of `tmux.conf` — the scripts aren't installed on this machine
  yet.

## Not tracked

- `fish_variables` — fish universal variables, host-specific and mode 0600.
- Plugin checkouts, which lazy.nvim keeps in `~/.local/share/nvim/lazy/` and so
  are outside this repo anyway. `lazy-lock.json` *is* tracked so versions pin.

## Host

Framework-class laptop: Intel Core Ultra 7 255H (Arrow Lake-H), Arc 140T iGPU +
RTX 5060 Mobile, 2880x1800@120 eDP-1 at 1.75 scale. Root on btrfs with snapper
+ snap-pac + limine-snapper-sync.
