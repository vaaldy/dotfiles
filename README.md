# dotfiles

Shared configuration lives on `main`; each machine has its own branch.

```mermaid
graph TD
    main --> pc
    main --> laptop
    main --> macos
```

## Configuration

- **Terminal:** [Alacritty](https://alacritty.org/)
- **Shell:** [Fish](https://fishshell.com/)
- **Terminal multiplexer:** [tmux](https://github.com/tmux/tmux)
- **Text editor:** [Neovim](https://neovim.io/)
  - Language support: nvim-treesitter, nvim-lspconfig, blink.cmp, and conform.nvim
  - Navigation: fzf-lua, yazi.nvim, and vim-tmux-navigator
  - Git: gitsigns.nvim, diffview.nvim, vim-fugitive, and git-conflict.nvim
  - UI: rose-pine, lualine.nvim, and which-key.nvim
- **File explorer:** [Yazi](https://yazi-rs.github.io/)
- **Linux desktop:** [niri](https://github.com/YaLTeR/niri) + [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
- **macOS desktop:** yabai + skhd + SketchyBar
- **Coding agent:** [Pi](https://github.com/earendil-works/pi)

## Setup

Check out the branch for the current machine.

### Linux (`pc` / `laptop`)

Configurations are [GNU Stow](https://www.gnu.org/software/stow/) packages:

```sh
stow alacritty niri nvim tmux fish noctalia mcp yazi
mkdir -p ~/.pi/agent
stow --no-folding pi
```

Rerun `stow -R <package>` to relink a package.

### macOS

```sh
git switch macos
./install-macos.sh
```

Rerun `install-macos.sh` to relink the configuration. Existing files are moved to timestamped backups before linking.

## Host (`pc`)

AMD desktop, CachyOS. Single AMD GPU — none of the iGPU/dGPU render-node
handling on `main` applies here. Exact CPU/GPU/monitor not yet recorded; run
`lspci -nn | grep -Ei 'vga|3d'` and `niri msg outputs` and fill them in.

Two things left tuned for the laptop that you may want to change once the
monitor is known:

- `alacritty.toml` `font.size = 10` — sized for a 1.75-scale HiDPI panel, likely
  too small at scale 1.
- `niri/cfg/display.kdl` — every output block is commented out, so niri
  autodetects. Uncomment and set the real mode/scale if it guesses wrong.
