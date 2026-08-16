# tmux quickstart

Every binding below is verified against `tmux/.config/tmux/tmux.conf` in this repo —
nothing generic, and nothing carried over from the macOS original that doesn't work here.

## Before anything works

```fish
sudo pacman -S --needed tmux lazygit
cd ~/dotfiles && stow tmux
```

`stow tmux` is what creates `~/.config/tmux` → this repo. Without it tmux starts with
stock defaults and none of the below applies.

## Why you're using this at all

niri already tiles windows on screen, so tmux isn't for layout. It's for two things a
compositor can't do:

1. **Persistence.** Close Alacritty, log out, come back — `tmux attach` and everything,
   including a long-running build or agent, is exactly where you left it.
2. **Grouping.** One session per project, several windows inside it, all reachable
   without hunting for the right Alacritty window in the niri scroll.

## The one concept that unlocks everything: prefix

tmux bindings are two keystrokes: a **prefix**, then a letter. Your prefix is
**Ctrl-Space** (not the default Ctrl-b). So "prefix `s`" means: press Ctrl-Space,
release, then press `s`.

**Linux gotcha:** Ctrl-Space is the default toggle for fcitx5 and ibus input methods. If
tmux seems to ignore your prefix entirely, that's almost certainly it:

```fish
pgrep -x fcitx5; pgrep -x ibus-daemon    # either printing a PID = suspect
```

Unbind it there, or switch tmux's prefix to Ctrl-a — two lines at the top of
`tmux.conf`. niri itself is clean: every one of its binds is on `Mod` (Super), so
nothing in the compositor competes for Ctrl-Space.

## Starting out

```fish
tmux              # start a new session
tmux attach       # reattach after closing the terminal
tmux ls           # list all sessions
```

Detaching — leaving tmux running in the background rather than killing it — is
**prefix `d`**. That's a tmux default, not remapped here.

## Sessions, windows, panes — the hierarchy

- **Session** = one project. Typically one per thing you're working on.
- **Window** = a tab within a session.
- **Pane** = a split within a window.

## Panes: splitting and moving

```
prefix |     split vertically    (mnemonic: | is a vertical line)
prefix -     split horizontally  (mnemonic: - is a horizontal line)
```

Both inherit your current directory — no `cd`-ing after every split.

Moving between panes is **plain Ctrl-hjkl, no prefix** — and it's seamless with nvim
splits. If the focused pane is running nvim, Ctrl-h/j/k/l moves between nvim's own
splits; if it's a shell, it moves between tmux panes. One motion for both.

```
prefix H / J / K / L    resize current pane (repeatable — hold prefix, tap the letter)
prefix z                zoom current pane fullscreen (tap again to unzoom)
prefix X                kill current pane
```

## Windows

```
prefix c    new window (inherits cwd)
prefix n    next window
prefix p    previous window
```

## Sessions — the part most people skip

This is the one that matters once you have three or four projects open:

```
prefix s        session picker (fuzzy tree view)
prefix w        window picker (same view, window-scoped)
prefix Space    jump to your LAST session — the alt-tab of projects
prefix Tab      cycle to the next session
prefix S-Tab    cycle to the previous session
prefix !@#$     (Shift+1..4) jump straight to session 1/2/3/4
```

Shift+1..4 sits on the punctuation row rather than the plain numbers because niri owns
`Mod+1..9` for workspaces — no collision, they're different modifiers, but keeping the
plain number row free inside tmux avoids the ambiguity entirely.

## Git

```
prefix g      lazygit, as a popup
prefix C-g    what changed — diff --stat plus the full patch, paged
```

`prefix C-g` uses git's own pager, so `q` closes it. (The macOS version used a bash
`read -n1` to hold the popup open; that breaks under fish, which is what tmux spawns
here, so it was replaced.)

## Copy mode (selecting/copying text)

```
prefix Enter    enter copy mode
v               start a selection — vi-style, since mode-keys is vi
C-v             toggle rectangular/block selection
y               copy, exit copy mode, land it on the system clipboard
```

`y` pipes through **wl-copy**, not macOS's `pbcopy` — Wayland session. Mouse
drag-selection copies automatically too, via the same binding.

## Everyday utility

```
prefix r    reload tmux.conf without restarting your session
prefix Q    kill the whole session (asks first)
```

## Reading the status bar

Top of the screen, left to right:

- **Session name** in bright purple — the project you're in.
- **Window tabs** — the current one in pale violet, activity in yellow, a bell in red.
- **Other session names**, dimmed, on the right — everything running in the background.
  One turns **yellow** the moment something finishes or wants input in it. That's
  `monitor-activity`/`monitor-bell`, and it's the signal to `prefix Space` or
  `prefix Tab` over and look, rather than babysitting four terminals.
- **Clock**, far right.
- **`PREFIX`** appears in yellow while the prefix is held — useful when you're not sure
  whether tmux caught it.

The palette is the noctalia purple from `alacritty/themes/noctalia.toml`, deliberately —
the status bar background, the pane borders and nvim's own background are the same three
values. See the table in `README.md` before changing any of them.

## A typical session, start to finish

1. `cd ~/Projects/thing && tmux new -s thing`
2. `prefix |` to split, nvim on the left, shell on the right. Ctrl-hjkl between them.
3. `prefix c` for a third window when you need a long-running process somewhere it
   won't be in the way.
4. `prefix d` to detach and walk away. `tmux attach -t thing` to come back.
5. Several projects going: `prefix s` to pick, `prefix Space` to bounce between the
   last two, and watch the status bar for a session going yellow.

## What's parked

The macOS config had a layer on top of this: `prefix f` (fzf project switcher),
`prefix a`/`A` (agent window/pane), `prefix t`/`T` (term-chan), `prefix G` (git worktree
switcher), and `prefix 1..4` to jump to named `edit`/`agent`/`git`/`run` windows.

Those bindings are **commented out at the foot of `tmux.conf`**, not deleted. They call
helper scripts (`tsess`, `agentproj`, `agentwt`) that aren't installed on this machine
yet. Installing those scripts and uncommenting the block is the whole job.
