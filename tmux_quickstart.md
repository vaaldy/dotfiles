# tmux quickstart

Prefix is **`Ctrl-Space`** (referred to below as `prefix`).

## CLI Commands

| Command | Action |
|---|---|
| `tmux` | Start a new unnamed session |
| `tmux new -s <name>` | Start a new session named `<name>` |
| `tmux attach` | Reattach to the last session |
| `tmux attach -t <name>` | Reattach to session `<name>` |
| `tmux ls` | List all running sessions |

## Sessions

| Key | Action |
|---|---|
| `prefix s` | Open **sesh** picker (fuzzy-switch or **create new session** from zoxide/dir) |
| `prefix e` | Open **ccmux** popup (all agent sessions across repos, live state + jump) |
| `prefix R` | **Rename** current session |
| `prefix d` | Detach from current session (leaves it running) |
| `prefix Q` | Kill current session (with confirmation prompt) |
| `prefix Space` | Jump to **last** session (Alt-Tab between projects) |
| `prefix Tab` | Cycle to **next** session |
| `prefix S-Tab` | Cycle to **previous** session |
| `prefix !` | Jump to session **1** (`Shift+1`) |
| `prefix @` | Jump to session **2** (`Shift+2`) |
| `prefix #` | Jump to session **3** (`Shift+3`) |
| `prefix $` | Jump to session **4** (`Shift+4`) |

### Inside `prefix s` (sesh popup)

| Key | Action |
|---|---|
| `Enter` | Connect to selected session, or **create a new session** for the selected directory |
| `Ctrl-a` | Show all (`sesh list`) |
| `Ctrl-t` | Filter to active tmux sessions only |
| `Ctrl-g` | Filter to config bookmarks |
| `Ctrl-x` | Filter to **zoxide** directories (pick any dir to create a new session there) |
| `Ctrl-f` | Find any directory under `~` (`fd`) to create a new session there |
| `Ctrl-d` | Kill highlighted tmux session |

## Windows (Tabs)

| Key | Action |
|---|---|
| `prefix c` | Create new window (inherits current directory) |
| `prefix ,` | Rename current window |
| `prefix <` | Open window context menu (Swap, Kill, Respawn, Mark, Rename, New) |
| `prefix n` | Next window |
| `prefix p` | Previous window |
| `prefix w` | Interactive window/session tree picker |
| `prefix 1..9` | Jump to window 1..9 |
| `prefix &` | Kill current window |

## Panes (Splits)

| Key | Action |
|---|---|
| `prefix \|` | Split vertically (side-by-side, inherits cwd) |
| `prefix -` | Split horizontally (top/bottom, inherits cwd) |
| `Ctrl-h / j / k / l` | Move between tmux panes **and** Neovim splits seamlessly (no prefix) |
| `prefix H / J / K / L` | Resize current pane left / down / up / right (repeatable) |
| `prefix z` | Toggle current pane fullscreen zoom |
| `prefix X` | Kill current pane |

## Git & Agent Tools

| Key | Action |
|---|---|
| `prefix g` | Open `lazygit` popup in current pane's directory |
| `prefix C-g` | Open `git diff HEAD --stat --patch` review popup (`q` to close) |
| `prefix e` | Open `ccmux` agent session manager popup |
| `prefix f` | Toggle Pi subagent fleet view (`Ctrl-Alt-f`) |

## Copy Mode (Vi Keys + Wayland `wl-copy`)

| Key | Action |
|---|---|
| `prefix Enter` | Enter copy mode |
| `v` | Start visual selection |
| `Ctrl-v` | Toggle rectangle / block selection |
| `y` | Copy selection to Wayland clipboard (`wl-copy`) and exit copy mode |
| `MouseDrag` | Select and auto-copy to `wl-copy` on release |
| `q` or `Esc` | Exit copy mode |

## Config & Utility

| Key | Action |
|---|---|
| `prefix r` | Reload `~/.config/tmux/tmux.conf` live |
| `prefix ?` | List all active keybindings |
| `prefix :` | Open tmux command prompt |
