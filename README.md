# dotfiles

CachyOS + niri + noctalia. Managed with [GNU stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a *stow package* whose contents mirror the path
relative to `$HOME`:

```
alacritty/.config/alacritty/   ->  ~/.config/alacritty/
niri/.config/niri/             ->  ~/.config/niri/
nvim/.config/nvim/             ->  ~/.config/nvim/
fish/.config/fish/             ->  ~/.config/fish/
noctalia/.config/noctalia/     ->  ~/.config/noctalia/
```

## Usage

```fish
cd ~/dotfiles

stow alacritty niri nvim fish noctalia   # link everything
stow -R niri                             # re-link after adding files
stow -D niri                             # unlink
stow -n -v alacritty                     # dry run
```

## Not tracked

- `fish_variables` — fish universal variables, host-specific and mode 0600.
- Plugin checkouts, which lazy.nvim keeps in `~/.local/share/nvim/lazy/` and so
  are outside this repo anyway. `lazy-lock.json` *is* tracked so versions pin.

## Host

Framework-class laptop: Intel Core Ultra 7 255H (Arrow Lake-H), Arc 140T iGPU +
RTX 5060 Mobile, 2880x1800@120 eDP-1 at 1.75 scale. Root on btrfs with snapper
+ snap-pac + limine-snapper-sync.
