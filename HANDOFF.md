# Handoff: CachyOS + niri workstation

**Supersedes `HANDOFF-tmux-nvim.md`**, which described the tmux/nvim port *before* it
was done. That file is now historical — safe to delete once you've read this.

**Written:** 2026-08-16. Everything below was verified on the machine or in the repo,
not assumed. Where something is unverified, it says so.

---

## 0. READ THIS FIRST

### 0.1 There is no Cmd key on Linux

The nvim/tmux configs here were ported from a macOS setup. That setup was deliberately
built Cmd-free and Alt-free (it coexisted with yabai), which is why the port was clean.
**Keep it that way.** Any binding of the form `Cmd+<key>` or `<D-...>` has no Linux
equivalent — terminals cannot transmit Cmd, so `<D-s>` simply never fires.

### 0.2 Do not touch input remapping

`/etc/keyd/`, niri's modifier bindings, and any system-wide key remapping are
**off-limits**. Two separate attempts at macOS-style modifiers were built and fully
reverted (see §4). The user chose stock modifiers deliberately.

Editing `niri/cfg/layout.kdl` or adding window rules is fine — that ground is not
scarred. It is specifically the *modifier* experiments that failed.

### 0.3 You probably cannot run commands on this machine

Cowork sessions running **in the cloud** get file transfer only
(`device_list_dir` / `device_stage_files` / `device_commit_files`) — no shell. You
cannot run `git`, `stow`, `pacman`, or `systemctl`. Hand the user exact commands
instead, batched, and remember the shell is **fish**.

A session running **on the user's computer** does get a shell. If you need one, that's
the difference.

---

## 1. Environment (verified 2026-08-16)

| Component | Value |
|---|---|
| OS | CachyOS (Arch-based), `x86-64-v3` repos |
| Kernel | `7.1.8-1-cachyos`; `6.18.42-1-cachyos-lts` also installed |
| Compositor | niri 26.04 (Wayland, scrollable-tiling). `Mod` = Super |
| Shell | fish 4.8.1 — **login shell**. Not bash, not zsh |
| Terminal | Alacritty 0.17.0 |
| Editor | Neovim 0.12.4 |
| Multiplexer | tmux 3.7 |
| Display manager | SDDM |
| Shell UI | noctalia |
| AUR helper | `paru` |
| Display | desktop monitor — name/mode/scale **TBD, run `niri msg outputs`** |
| Filesystem | btrfs + snapper + snap-pac + limine-snapper-sync |

### GPU — single AMD, no hybrid graphics

This machine is AMD. Unlike the laptop on `main` there is no second GPU, so none of the
iGPU/dGPU render-node juggling applies: `/dev/dri/renderD128` is *the* GPU, `amdgpu`
drives it, and nothing needs to be told which card to pick.

Fill in the specifics before relying on them:

```fish
lspci -nn | grep -Ei 'vga|3d|display'
ls -l /dev/dri/by-path/
```

| PCI | Device | card | render node |
|---|---|---|---|
| TBD | AMD (`amdgpu`) | TBD | TBD |

### Thermals

Desktop cooling, so the laptop's "0 RPM is correct" caveat does not carry over — on this
box fans reading zero under load *is* worth investigating. Baseline idle temps not yet
recorded; take them with `sensors` before calling anything abnormal.

### fish is not POSIX

- `export FOO=bar` → `set -gx FOO bar`
- `$(...)` → `(...)`
- `/etc/profile.d/*.sh` is **not sourced** — anything that installs PATH there is
  invisible to fish. Use `fish_add_path`.

---

## 2. Dotfiles workflow — FOLLOW THIS

`~/dotfiles` is a git repo managed with **GNU stow**. Packages:

```
alacritty/  niri/  nvim/  tmux/  fish/  noctalia/
```

Each mirrors its path relative to `$HOME`, e.g. `nvim/.config/nvim/` → `~/.config/nvim/`.

**Editing existing files:** just edit `~/.config/...` — it's a symlink into the repo.

**Adding a NEW file or directory:** create it in the repo, then **re-stow**:

```fish
cd ~/dotfiles && stow -R nvim
```

> ⚠️ This bit us. A `queries/` directory was added under `nvim/.config/nvim/` and never
> appeared in `~/.config/nvim/` because stow had not been re-run. The fix looked like it
> had failed when it had simply never been linked. **If a new file seems to have no
> effect, check `ls -ld ~/.config/<pkg>` and re-stow before debugging anything else.**

**Commit in small, separate pieces.** The user has reverted work repeatedly; discrete
commits are what made that painless.

---

## 3. System changes NOT captured by this repo

Stow and git only see `~/dotfiles`. These were made outside it and would be lost on a
rebuild:

| Change | Command | Why |
|---|---|---|
| snapd socket | `sudo systemctl enable --now snapd.socket` | Arch ships snapd disabled |
| snapd apparmor | `sudo systemctl enable --now snapd.apparmor.service` | confined snaps |
| `/snap` symlink | `sudo ln -s /var/lib/snapd/snap /snap` | classic confinement |
| snap PATH for fish | `fish_add_path /var/lib/snapd/snap/bin` | fish ignores `/etc/profile.d` |
| snap app | `sudo snap install kaffelogic-studio` | coffee roaster software |
| snap interfaces | `sudo snap connect kaffelogic-studio:raw-usb` (+ `removable-media`) | USB/serial to the roaster |

`serial-port` will likely refuse to connect — on classic (non-Ubuntu-Core) systems
there's usually no matching slot. That's expected; `raw-usb` covers it.

### `/etc/sddm.conf.d/99-wayland.conf` — check before assuming

This file may or may not exist. **It broke the boot once** (§4.3). If present and the
desktop is failing to start, delete it and reboot.

---

## 4. Scar tissue — read before proposing anything ambitious

Four configurations have been built and reverted. Three share a root cause: a change
spanning layers that couldn't be evaluated one piece at a time.

### 4.1 niri macOS-style keybinds — reverted
All bindings rewritten to Cmd-style chords before the physical modifier swap landed.
Semantics moved, thumb position didn't.

### 4.2 keyd `leftalt = leftcontrol` — reverted
Made Cmd+C/V work in GUI apps, but keyd rewrites the key *before any application sees
it*, so Cmd and Ctrl became literally the same keystroke. Cmd+C sent SIGINT in the
terminal. Binding Cmd+Q in Alacritty also bound Ctrl+Q.

### 4.3 SDDM Wayland greeter — reverted, BROKE THE BOOT
Written to `/etc/sddm.conf.d/99-wayland.conf`:

```ini
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell   # ← the bug

[Wayland]
CompositorCommand=weston --shell=kiosk
```

`GreeterEnvironment=...layer-shell` is **kwin-specific**. Weston does not implement
`wlr-layer-shell`, so the Qt greeter could not create a surface and exited immediately
on every boot, both kernels. Journal signature:

```
Greeter session started successfully
[PAM] Closing session          ← immediately after
Greeter stopped.
```

The docs list the kwin and weston configs as *alternatives*; a line was taken from each
and merged. The corrected form is `DisplayServer=wayland` alone — the `[Wayland]`
section is optional. **Unverified.** Recovery: `Ctrl-Alt-F3`, log in, delete the file,
reboot. Or edit the limine entry with `e` and append `systemd.unit=multi-user.target`.

**Motivation, for context:** on the laptop this was chased to stop SDDM's leftover X
server from holding the discrete GPU awake. That motivation does not exist here — single
AMD GPU, nothing to power down — so there is no reason to retry it at all. The scar
tissue is kept only so nobody rediscovers the idea and breaks the boot.

### 4.4 Verify before asserting
An earlier session claimed screenshot and brightness keys were broken and needed
`grim`/`slurp`/`brightnessctl`. Wrong — niri screenshots natively (`Ctrl+Shift+1/2/3`)
and noctalia handles brightness/media via `noctalia msg`. **Check, don't assume.**

---

## 5. Live workarounds — do not "clean these up"

### 5.1 nvim: markdown treesitter crash
`lua/plugins/treesitter.lua` calls `vim.treesitter.query.set("markdown", "injections", ...)`
at file scope. This replaces nvim-treesitter's markdown injections query, whose custom
`#set-lang-from-info-string!` directive does `match[capture_id]` — a `TSNode[]` list on
Neovim 0.12, not a single node — then calls `:range()` on it. Every cursor move in a
markdown buffer with ``` blocks threw.

Upstream closed it **"not planned"** on both sides (neovim#39032, nvim-treesitter#8618;
see also #8636). nvim-treesitter's `master` is in maintenance — `main` is the rewrite —
so no fix is coming. The full reasoning is in the file's comment block.

Also in that file: `on_attach` skips `nvim-treesitter-context` for markdown filetypes.
That was aimed at an earlier symptom and **is probably now unnecessary** — the query
override fixed the actual cause. Removing it should restore sticky headers in markdown.
Untested.

### 5.2 tmux: fork-free pane navigation
`tmux.conf` uses a tmux-native format match, not the upstream `ps | grep`:

```
is_vim="#{m/ri:^(\\S+/)?g?(view|l?n?vim?x?|fzf)(diff)?$,#{pane_current_command}}"
bind-key -n 'C-h' if-shell -F "$is_vim" 'send-keys C-h' 'select-pane -L'
```

The upstream version forks `ps` **and** `grep` on every C-hjkl press, which is
perceptibly laggy. Verified: pane running nvim → `1`, anything else → `0`.

### 5.3 tmux: truecolor keyed on the right TERM
Alacritty sets `TERM=xterm-256color`, so `terminal-features ",alacritty:RGB"` never
matched — it was silently broken on the Mac too. Both are now listed.

### 5.4 Colors are shared, not merely similar
rose-pine's `base`/`surface`/`overlay` are pinned in `lua/plugins/ui.lua` to the exact
Alacritty and tmux values:

| value | source | consumer |
|---|---|---|
| `#201A28` | alacritty noctalia theme bg | nvim `Normal` |
| `#2A2136` | tmux `status-style` bg | nvim `NormalFloat`, `StatusLine` |
| `#382E47` | tmux `pane-border-style` | nvim `CursorLine` |

Change one, change all three.

---

## 6. Not done / open

- **Agentic scripts not ported.** `tsess` (fzf project switcher), `agentproj` (4-window
  session layout), `agentwt` (worktree-per-branch) exist in the original macOS zip but
  were not installed. The matching tmux bindings (`prefix f/a/A/t/T/G`, `prefix 1-4`)
  are **commented out at the foot of `tmux.conf`**, not deleted. Despite the names,
  `tsess`/`agentproj` are not agent-specific — they're a project switcher and a session
  layout. Only `prefix a/A/t/T` touch an agent CLI.
- **fish glue not written.** Needed if the scripts land: `PATH`, `EDITOR`, `AGENT_CMD`,
  `TSESS_ROOTS` (must point at `~/Projects`, not the macOS `~/dev`), `WT_ROOT`.
- **gitconfig not ported.** The macOS one has delta, ~35 aliases, worktree settings.
  Would replace the global `~/.gitconfig`; `osxkeychain` → `libsecret`.
- **`lazy-lock.json` not committed** — plugins float to latest. `.gitignore` is already
  set up to track it.
- **tmux sessions don't survive reboot.** tmux-resurrect + tmux-continuum were discussed
  and not installed. Note `swapfile = false` in nvim options, so unsaved buffers are
  lost with no recovery file — always `:wa` before rebooting.
- **Formatters** need `:MasonInstall stylua shfmt prettierd ruff`.

---

## 7. Gotchas worth knowing

**Kernel updates break modprobe until reboot.** `paru`/`pacman -Syu` replaces
`/usr/lib/modules/<version>`; the running kernel can then load no new module. This
presented as snapd failing with "cannot mount squashfs / failed to set up loop device".
First check on any weird module failure:

```fish
uname -r; ls /usr/lib/modules/
```

No matching directory → reboot.

**Alacritty binds Ctrl+L twice** (`ClearLogNotice` and `chars = "\f"`). Unresolved
whether the first swallows the key. If tmux `C-l` (pane-right) misbehaves while
`C-h/j/k` are fine, that's the suspect.
