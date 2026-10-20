# Neovim quickstart

Leader key is **`Space`** (`<leader>`). Press `Space` and wait for `which-key` to preview any binding.

## Survival & Files

| Key | Action |
|---|---|
| `i` | Enter insert mode |
| `jk` or `Esc` | Return to normal mode |
| `Esc` (normal) | Clear search highlight |
| `<leader>w` or `:w` | Save file |
| `<leader>q` or `:q` | Quit current window |
| `:qa!` | Quit all without saving |
| `<leader>r` | Reload files changed on disk (`:checktime`) |
| `u` / `Ctrl-r` | Undo / Redo |

## Search & Navigation (`fzf-lua` + `yazi`)

| Key | Action |
|---|---|
| `<leader>ff` | Find file by name |
| `<leader>fg` | Live grep across project |
| `<leader>fr` | Resume last fzf search |
| `<leader>/` | Fuzzy search lines in current buffer |
| `<leader>fb` | Switch open buffer |
| `<leader>fh` | Search help tags |
| `<leader>e` | Open **Yazi** at current file |
| `<leader>E` | Open **Yazi** in current working directory |
| `<leader>?` | Show buffer-local keymaps (`which-key`) |

## Buffers & Splits

| Key | Action |
|---|---|
| `S-h` / `S-l` | Previous / Next buffer |
| `<leader>bd` | Delete (close) current buffer |
| `Ctrl-h / j / k / l` | Move between Neovim splits **and** tmux panes seamlessly |
| `<leader>sv` | Split window vertically |
| `<leader>ss` | Split window horizontally |
| `<leader>sx` | Close current split |
| `<leader>s=` | Equalize split sizes |

## LSP & Diagnostics

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Show hover documentation |
| `<leader>ca` | Code action (quickfix, imports, refactor) |
| `<leader>cr` | Rename symbol across project |
| `<leader>cf` | Format buffer (`conform.nvim`) |
| `<leader>xd` | Show line diagnostics float |
| `]d` / `[d` | Next / Previous diagnostic |
| `Ctrl-o` / `Ctrl-i` | Jump back / Jump forward in jumplist |

## Completion & Editing

| Key | Action |
|---|---|
| `Tab` / `S-Tab` | Next / Previous completion item |
| `Ctrl-y` | Accept completion |
| `Ctrl-e` (insert) | Dismiss completion menu, or fast-wrap next word in pair (`nvim-autopairs`) |
| `J` / `K` (visual) | Move selected lines down / up |
| `<` / `>` (visual) | Outdent / Indent and keep visual selection |
| `J` (normal) | Join line below without moving cursor |
| `<leader>p` (visual) | Paste over selection without overwriting yank register |
| `<leader>d` | Delete into black hole register (keep yank register) |

## Treesitter & Surround

| Key | Action |
|---|---|
| `<leader>v` | Start incremental syntax selection (`v` expand, `V` shrink) |
| `cif` / `daf` | Change inside / Delete around function |
| `cac` / `vac` | Change / Select around class |
| `cia` / `daa` | Change inside / Delete around parameter/argument |
| `]f` / `[f` | Jump to next / previous function |
| `cs"'` | Change surrounding `"` to `'` (`nvim-surround`) |
| `ds(` | Delete surrounding `(` `)` |
| `ysiw)` | Wrap current word in `(` `)` |

## Folding (JSON, Functions, Blocks — Treesitter)

| Key | Action |
|---|---|
| `za` | Toggle fold (expand / collapse) under cursor |
| `zc` / `zo` | Collapse (close) / Expand (open) fold under cursor |
| `zC` / `zO` | Recursively collapse / expand all nested folds under cursor |
| `zM` | Collapse **all** folds in file |
| `zR` | Expand **all** folds in file |
| `zm` / `zr` | Fold one level deeper / Unfold one level across file |

## Git (`gitsigns`, `diffview`, `fugitive`, `git-conflict`)

| Key | Action |
|---|---|
| `]h` / `[h` | Next / Previous git hunk |
| `<leader>hp` | Preview git hunk inline |
| `<leader>hs` | Stage current hunk |
| `<leader>hr` | Reset (reject) current hunk |
| `dih` | Delete hunk (text object) |
| `<leader>hb` | Blame current line |
| `<leader>gd` | Open `DiffviewOpen` (side-by-side uncommitted diff) |
| `<leader>gm` | Open `DiffviewOpen` against `main` merge-base |
| `<leader>gh` | File commit history (`DiffviewFileHistory %`) |
| `<leader>gq` | Close Diffview |
| `<leader>gs` | Git status (`vim-fugitive`: `s` stage, `u` unstage, `=` diff) |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `co` / `ct` / `cb` / `c0` | Conflict resolution: choose ours / theirs / both / none |
| `]x` / `[x` | Next / Previous merge conflict |

## Markdown

| Key | Action |
|---|---|
| `<leader>mp` | Toggle in-buffer Markdown rendering (`render-markdown.nvim`) |
| `<leader>mb` | Toggle live browser Markdown preview (`markdown-preview.nvim`) |

## Plugin & Tooling Commands

| Command | Action |
|---|---|
| `:checkhealth` | Verify Neovim, LSP, Treesitter, and clipboard setup |
| `:Lazy` | Manage plugins (`U` update, `x` clean, `L` profile) |
| `:Mason` | Install/manage LSP servers and formatters (`i` to install) |
| `:LspInfo` | Inspect active LSP clients attached to current buffer |
