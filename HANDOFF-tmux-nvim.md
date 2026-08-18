# Handoff: tmux + Neovim setup on CachyOS/niri

**Goal:** set up tmux and Neovim to match the user's existing macOS setup.
**Written:** 2026-08-15. All environment facts below were verified on the machine, not assumed.

---

## 0. READ THIS FIRST — two things that will derail you

### 0.1 The macOS configs are NOT in this repo

Nothing here describes what the user's macOS tmux/nvim setup actually *is*. You cannot
match it without seeing it. **Ask for these before writing a single config file:**

- `~/.tmux.conf` or `~/.config/tmux/tmux.conf` from the Mac
- `~/.config/nvim/` from the Mac — at minimum `init.lua`, the plugin spec files, and
  `lazy-lock.json` if they use lazy.nvim
- Which distribution it is, if any: LazyVim / kickstart.nvim / NvChad / AstroNvim / hand-rolled.
  This single answer determines most of the work.
- Whether they want a byte-for-byte port or "same feel, adapted to Linux"

If the user can't produce the files, get the plugin list and the leader/prefix keys at
minimum. Do not guess a "typical macOS setup" and build that — it will be wrong and
this user has already had two configurations reverted (see §6).

### 0.2 There is no Cmd key on Linux — this is a hard limit

macOS terminal setups lean on Cmd. Linux has no Cmd, and **terminal emulators cannot
transmit one**: a TUI receives bytes, and there is no escape sequence for Cmd. So any
macOS binding of the form `Cmd+<key>` has NO direct port. This affects:

- Alacritty-level bindings (`Cmd+K` clear, `Cmd+T` new window, `Cmd+Enter` fullscreen)
- Any tmux binding the user triggers with Cmd
- Any nvim mapping written as `<D-...>` — **`<D-s>`, `<D-v>` etc. simply never fire on Linux**

Grep their macOS config for `<D-` early and surface every hit to the user with a
proposed replacement. Do not silently drop them.

Historical note: a previous session tried to synthesise a Cmd key by remapping Alt to
Ctrl at the keyd level. It was **fully reverted** — see §6. Do not re-attempt it.

---

## 1. Environment (verified 2026-08-15)

| Component | Version / value |
|---|---|
| OS | CachyOS (Arch-based), kernel 7.1.6-1-cachyos, `x86-64-v3` repos |
| Compositor | niri 26.04 (Wayland, scrollable-tiling). `Mod` = Super |
| Shell | fish 4.8.1 — **login shell**. Not bash, not zsh |
| Terminal | Alacritty 0.17.0 |
| Neovim | v0.12.4 (LuaJIT 2.1) |
| tmux | **NOT INSTALLED**. Available as `cachyos-extra-v3/tmux 3.7_b-1.1` |
| AUR helper | `paru` 2.1.0 (installed and working) |
| Hardware | Ryzen 5 5500 + AMD Navi 22 (`amdgpu`), single GPU, no iGPU |
| Display | DP-3, AOC Q27G3XMN 2560x1440 @170Hz, **scale 1** (~109 DPI — not HiDPI) |

### fish is not POSIX
The login shell is fish. Anything you write that assumes bash/zsh syntax will break:

- `export FOO=bar` -> `set -gx FOO bar`
- `foo && bar` works in fish 4.x, but `$(...)`/backtick idioms and `[[ ]]` do not
- tmux's `default-shell` should point at `/bin/fish`
- Plugin managers that shell out (`lazy.nvim` build steps, `mason.nvim`) generally
  invoke `sh`, so those are fine — but *your* config snippets are not

---

## 2. Dotfiles workflow — YOU MUST FOLLOW THIS

`~/dotfiles` is a git repo managed with **GNU stow**. Everything under `~/.config` for
the managed packages is a **symlink into the repo**.

```
~/dotfiles/
  alacritty/.config/alacritty/     -> ~/.config/alacritty/
  niri/.config/niri/               -> ~/.config/niri/
  nvim/.config/nvim/               -> ~/.config/nvim/
  fish/.config/fish/               -> ~/.config/fish/
  noctalia/.config/noctalia/       -> ~/.config/noctalia/
```

**Editing existing files:** just edit `~/.config/nvim/init.lua` normally. It is a
symlink, so the edit lands in the repo automatically. This is the easy case.

**Adding NEW files or a NEW package (e.g. tmux):** create it in the repo, then stow.

```fish
mkdir -p ~/dotfiles/tmux/.config/tmux
# write ~/dotfiles/tmux/.config/tmux/tmux.conf
cd ~/dotfiles && stow tmux           # creates the ~/.config/tmux symlink
cd ~/dotfiles && stow -R nvim        # re-link after adding files to an existing package
```

If you write a new file directly to `~/.config/nvim/lua/...` it lands in the *symlinked
directory*, which works, but confirm with `ls -l` that you haven't created a real
directory that shadows the stow link. `stow -n -v <pkg>` is a safe dry run.

**Commit as you go.** The user has reverted work twice; discrete commits are what made
that painless. Do not bundle unrelated changes.

### Deliberately untracked
- `fish_variables` — host-specific, mode 0600. Never commit it.
- Plugin checkouts (`~/.local/share/nvim/lazy/`) live outside the repo. `lazy-lock.json`
  SHOULD be tracked once it exists again.

---

## 3. Current state of the targets

### Neovim — intentionally bare
`~/.config/nvim/init.lua` is **16 lines**: options only. Zero plugins, zero keymaps,
no lazy.nvim bootstrap. `lazy-lock.json` was deleted, plugin dir wiped.

This was deliberate — the user said "i was only fooling around" and asked for a clean
slate. **This is a greenfield build, not a migration.** Do not try to preserve anything.

Currently set: `mapleader=" "`, `maplocalleader="\\"`, `number`, `relativenumber`,
`tabstop/shiftwidth=4`, `expandtab`, `clipboard=unnamedplus`.

The previous throwaway config is at commit `7889b50` if you ever need to look, but it
was neo-tree + autopairs + mini.pairs and has no bearing on the macOS setup.

### tmux — not installed
```fish
sudo pacman -S --needed tmux        # user must run this, see §5
```
No tmux config exists anywhere. TPM (tmux plugin manager) is not present either.

---

## 4. Terminal facts that matter for tmux + nvim

Verified present: `alacritty`, `tmux-256color`, and `xterm-256color` terminfo entries.
`COLORTERM=truecolor` is exported.

Alacritty currently sets `TERM = "xterm-256color"` (`alacritty.toml:7`).

**Standard correct setup, which you should apply:**
- Inside tmux: `set -g default-terminal "tmux-256color"`
- Plus a truecolor passthrough override, e.g.
  `set -ga terminal-overrides ",*256col*:Tc"` (or the `RGB` capability form)
- Verify with `:checkhealth` in nvim inside tmux, and by confirming
  `nvim +'lua print(vim.o.termguicolors)'` reports true

**Undercurl/underline styles** (used by LSP diagnostics) need extra
`terminal-overrides` entries for `Smulx`/`Setulc` if the user's macOS setup shows them.

### Clipboard — a real macOS/Linux divergence
macOS nvim configs often hardcode `pbcopy`/`pbpaste`. On this machine:
- Session is **Wayland**; `wl-clipboard` IS installed (`wl-copy`/`wl-paste`)
- `clipboard=unnamedplus` is already set and works
- Grep their config for `pbcopy`, `pbpaste`, `macos`, `Darwin` and replace
- For tmux, `copy-pipe-and-cancel "wl-copy"` replaces `pbcopy`

### Font
Alacritty uses `JetBrainsMono Nerd Font` at size 10 on a 1.75-scaled display. Nerd Font
glyphs are available (JetBrainsMono and Meslo both installed), so devicons/statusline
glyphs will render.

Minor latent inconsistency, not currently breaking: `alacritty.toml:27` spells the
`bold_italic` family `"JetBrains Mono Nerd Font"` (with a space) while the other three
styles use `"JetBrainsMono Nerd Font"` (no space). fontconfig resolves both to the same
family today, so it renders correctly — but it is worth normalising while you're there.

---

## 5. Constraints on you as the agent

**Sudo requires a password and there is NO passwordless sudo.** You cannot install
packages yourself. The `!` bash prefix in this harness has no TTY, so `sudo` fails there
too with "a terminal is required to read the password".

=> Hand the user exact commands to paste into a real terminal. Batch them: ask once for
everything you need installed, rather than interrupting repeatedly.

Likely install list for this work (confirm against their actual macOS config first):
```fish
sudo pacman -S --needed tmux
# only if their nvim setup needs them:
sudo pacman -S --needed lazygit zoxide luarocks go rust tree-sitter-cli
```
Already present, do not reinstall: `git ripgrep fd fzf bat eza wl-clipboard nodejs
python unzip curl`. Absent: `go rust luarocks tmux zoxide lazygit starship`.

`paru` is available for AUR packages and works without sudo prompts for the build step.

---

## 6. Scar tissue — read before proposing anything ambitious

This user has had **two configurations built and then fully reverted** in the preceding
session. Both failures were the same root cause: a change that spanned layers and could
not be evaluated one piece at a time.

1. **niri macOS keybinds** — all bindings rewritten to Cmd-style chords before the
   physical modifier swap was applied. Semantics moved, thumb position didn't, nothing
   matched. Reverted.
2. **keyd `leftalt = leftcontrol`** — made Cmd+C/V/A work in GUI apps, but because keyd
   rewrites the key *before any application sees it*, Cmd and Ctrl became literally the
   same keystroke. Cmd+C sent SIGINT in the terminal; Cmd+A meant select-all in Firefox
   but jump-to-line-start in the shell; binding Cmd+Q in Alacritty also bound Ctrl+Q.
   Reverted.

**What this means for you:**
- Prefer changes contained to one config file. tmux and nvim are both well-behaved this
  way — nothing you do in `tmux.conf` or `init.lua` can leak into the compositor.
- **Do not touch `/etc/keyd/`, niri's keybinds, or any system-wide input remapping.**
  That ground has been covered and the user explicitly chose to stay on stock modifiers.
- Land changes incrementally and let the user try each one. Do not deliver a 2000-line
  nvim config in a single commit.
- Verify claims before making them. In the prior session an agent asserted that
  screenshot and brightness keys were broken and needed `grim`/`slurp`/`brightnessctl`.
  That was wrong — niri screenshots natively and noctalia handles brightness/media
  internally via `noctalia msg`. Check, don't assume.

---

## 7. Suggested opening move

1. Ask for the macOS `tmux.conf` and `nvim/` directory (§0.1). Blocked without them.
2. While waiting, confirm the Cmd-key constraint with the user and agree on a
   replacement modifier for any `Cmd`/`<D-...>` bindings found. On this machine the
   sensible substitutes are `Ctrl`, `Alt`, or a tmux prefix chord — Super is taken by
   niri for window management.
3. Get tmux installed (§5) since it is a hard prerequisite and needs the user anyway.
4. Then port in order: tmux.conf -> nvim options/keymaps -> plugin manager -> plugins
   -> LSP/tooling. Commit at each boundary.

## 8. Open questions to put to the user

- Byte-for-byte port, or "same feel, adapted to Linux idioms"?
- tmux prefix key on the Mac? (`C-a` and `C-b` are both common)
- Which nvim distro/base, if any?
- Do they want `lazy-lock.json` from the Mac carried over to pin exact plugin versions?
  (Recommended — reproducibility, and it is already gitignore-cleared to be tracked.)
- Any macOS-only plugins in the list that need Linux substitutes?
- Should tmux autostart in Alacritty, or be launched manually?
