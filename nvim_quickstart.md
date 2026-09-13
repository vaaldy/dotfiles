# Neovim quickstart

Your config, not Neovim in general. For the editor itself, run `:Tutor` once — 25
minutes, and it teaches the motions this document assumes.

---

## Day zero

```fish
sudo pacman -S --needed npm base-devel     # mason's node servers; treesitter's C compiler
cd ~/dotfiles && stow -R nvim
nvim
```

First launch does two things and both take a minute:

1. **lazy.nvim clones 29 plugins.** A dashboard shows progress. Let it finish.
2. **Treesitter compiles parsers** for ~26 languages, and again for any new language
   later. It's a C compile, hence `base-devel`.

Quit, reopen, then:

```
:checkhealth
```

Warnings about optional providers (perl, ruby) are fine. What you want clean: `lazy`,
`treesitter`, `lsp`, `fzf-lua`. Clipboard should report **wl-copy/wl-paste** — this is a
Wayland session, and `clipboard=unnamedplus` routes through wl-clipboard.

One more, once — the formatters `<leader>cf` calls aren't bundled:

```
:MasonInstall stylua shfmt prettierd ruff
```

---

## The one trick that replaces reading this document

**Press `<Space>` and wait.**

which-key pops up a menu of every leader binding, grouped and labelled. Press the next
key and it narrows. You don't have to memorise anything — you can browse to any command
in the config.

`<leader>?` does the same for *buffer-local* keys, which is how you see what the LSP
attached for this specific filetype.

Throughout this doc, `<leader>` is the **Spacebar**.

---

## Survival kit

| | |
|---|---|
| `i` | insert mode (type text) |
| `jk` or `Esc` | back to normal mode |
| `:w` or `<leader>w` | save |
| `:q` or `<leader>q` | close window |
| `:qa!` | quit everything, discard changes |
| `u` / `Ctrl-r` | undo / redo |
| `<Esc>` | also clears search highlight here |

If you're ever lost: `Esc` twice, then `:q`.

---

## The twelve keys that cover most days

| Key | Does |
|---|---|
| `<leader>ff` | find file by name |
| `<leader>fg` | grep the whole project |
| `<leader>/` | search inside this file |
| `<leader>e` | open Yazi at the current file |
| `<leader>fb` | switch buffer |
| `S-h` / `S-l` | previous / next buffer |
| `gd` | jump to definition |
| `gr` | find all references |
| `K` | hover docs for symbol under cursor |
| `<leader>ca` | code action (fix imports, auto-fix, etc.) |
| `<leader>cr` | rename symbol across the project |
| `<leader>cf` | format the file |

`Ctrl-o` jumps back where you came from, `Ctrl-i` forward. After a `gd`, that's how you
return.

**`Ctrl-h/j/k/l` move between splits** — and past the edge of nvim into the neighbouring
tmux pane, without you changing keys. That's `vim-tmux-navigator` plus the matching
bindings in `tmux.conf`; the two halves only work together.

Because Ctrl-hjkl is spoken for, **splits are on leader**: `<leader>sv` vertical,
`<leader>ss` horizontal, `<leader>sx` close, `<leader>s=` equalize.

---

## Four workflows, end to end

### Open a project and start working

```fish
cd ~/Projects/thing && nvim .
```

Then `<leader>ff` to find a file, or `<leader>e` to browse from the current file in
Yazi. `<leader>fg` searches when you know a string but not a filename.

### Edit with the language server

Land on a symbol you don't recognise → `K` for docs, `gd` to jump to it, `Ctrl-o` back.
Red squiggle → `<leader>xd` reads the diagnostic, `<leader>ca` usually offers the fix.
`]d` / `[d` walk between problems.

Completion appears as you type: `Tab` / `S-Tab` to move, `Ctrl-y` accept, `Ctrl-e`
dismiss.

> `Ctrl-e` does double duty in insert mode: it dismisses the completion menu when one is
> open, and otherwise triggers autopairs' fast-wrap (wrap the next word in the bracket
> you just typed). They coexist because completion only claims the key while its menu is
> visible.

Servers installed on first run: `lua_ls`, `ts_ls`, `pyright`, `jsonls`, `bashls`. Add
more with `:Mason` → `i`, or by editing `ensure_installed` in `lua/plugins/lsp.lua`.

### Review changes before committing

```
<leader>r         reload files changed outside nvim
<leader>gd        diffview: side-by-side review of everything uncommitted
]h / [h           jump between individual hunks
<leader>hp        preview a hunk inline
<leader>hs        stage this hunk
<leader>hr        reject this hunk
<leader>gq        close diffview
```

`dih` deletes a hunk as a text object — the fastest way to drop one edit inside a file
you otherwise want. `<leader>gm` reviews the whole branch against its merge-base with
main.

### Commit

```
<leader>gs        fugitive status — `s` stages, `u` unstages, `=` shows the diff
<leader>gc        write the commit message, then :wq
<leader>gp        push
```

Or `prefix g` from tmux for lazygit, which is better for anything involving history.

---

## The part that isn't like VSCode

Treesitter gives you **structural text objects**. They operate on code shapes, not lines:

| | |
|---|---|
| `cif` | change **i**nside **f**unction — wipes the body, leaves the signature |
| `daf` | delete **a**round **f**unction — the whole thing, gone |
| `vac` | select **a**round **c**lass |
| `cia` | change this argument |
| `]f` / `[f` | jump to next / previous function |

`<leader>v` starts an incremental selection: press `v` repeatedly to expand outward by
syntax node (expression → statement → block → function), `V` to shrink. Fastest way to
select something awkwardly nested.

> It's `<leader>v` and not the more common `Ctrl-Space` for a specific reason: tmux
> claims Ctrl-Space as its prefix, so it never reaches nvim at all.

Also worth knowing:

- `ci"` change inside quotes, `ci(` inside parens, `cit` inside an HTML tag
- `cs"'` change surrounding quotes from `"` to `'` (nvim-surround)
- `ysiw)` wrap the current word in parens
- `ds(` delete the surrounding parens

---

## Making it yours

Everything lives in `~/.config/nvim`, which is a stow symlink into
`~/dotfiles/nvim/.config/nvim/`. Edit either path — they're the same files, and edits
land in the repo automatically.

```
init.lua                   entry point, sets leader
lua/config/options.lua     editor settings
lua/config/keymaps.lua     global keymaps
lua/config/lazy.lua        plugin manager bootstrap
lua/plugins/editor.lua     Yazi, fzf-lua, autopairs, surround, tmux nav
lua/plugins/treesitter.lua highlighting + text objects
lua/plugins/lsp.lua        language servers, completion, formatting
lua/plugins/git.lua        gitsigns, diffview, fugitive, conflicts
lua/plugins/ui.lua         theme, statusline, which-key
```

**Add a plugin** — drop it in any file under `lua/plugins/`, restart:

```lua
{ "folke/todo-comments.nvim", event = "VeryLazy", opts = {} },
```

**Change a keymap** — edit `lua/config/keymaps.lua`, or the `keys = {}` block of the
relevant plugin. `:so %` reloads the current file without restarting.

**Adding files needs a re-stow.** New file directly under `~/.config/nvim`? Fine. New
file created in the repo? `cd ~/dotfiles && stow -R nvim`. Check with
`ls -ld ~/.config/nvim` that it's still a symlink and not a real directory shadowing it.

**On the colorscheme.** rose-pine's `base`/`surface`/`overlay` are pinned in
`lua/plugins/ui.lua` to the exact values Alacritty and tmux use, so nvim's background,
the tmux status bar and the pane borders are the same colors rather than merely similar
ones. Changing one means changing all three — the table in `README.md` says which is
which.

---

## When something breaks

| Command | For |
|---|---|
| `:checkhealth` | the first thing to run, always |
| `:Lazy` | plugin status; `U` updates, `x` cleans, `L` shows load times |
| `:Mason` | install/remove language servers and formatters |
| `:LspInfo` | is a server actually attached to this buffer? |
| `:messages` | the error that flashed past too fast |
| `:Lazy profile` | why startup got slow |

Startup should be well under 100ms. If it isn't, `:Lazy profile` names the culprit.

**Colors look flat or wrong inside tmux?** That's a terminal-capability problem, not a
theme one. Check `:lua print(vim.o.termguicolors)` prints `true`, and that
`echo $TERM` is `tmux-256color` inside tmux and `xterm-256color` outside.

---

## A realistic learning path

**Week 1 — don't touch the config.** Learn `hjkl`, `w`/`b`, `ciw`, `dd`, `/search`, and
the twelve keys above. Resist adding plugins; the gap you feel is usually a motion you
haven't learned yet.

**Week 2 — text objects.** `ci"`, `ci(`, `cif`, `daf`. This is where editing starts being
faster than a mouse, and it's the thing people quit before reaching.

**Week 3 — make it yours.** Now you know what you actually want. Change keymaps, add the
one plugin you keep wishing for.

Two habits worth forming early: `.` repeats your last change, and `<leader>fr` resumes
your last search instead of retyping it.

If a key feels wrong, change it. It's ~350 lines and you own all of them.
