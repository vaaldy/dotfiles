# Handoff: move shared terminal behavior into `main`

**Written:** 2026-09-13 from the laptop checkout.

## Repository state at handoff

- `origin/main` and `origin/laptop`: `cb81ab3` (`feat: import shared Pi setup from macOS`)
- `origin/pc`: `73ae4d8` (`[chore] raffi mpv and whatevs`)
- Local laptop branch has two unpushed commits:
  - `3caa432` — laptop display profile (`eDP-1`, 2880x1800@120, scale 1.75)
  - `b66196d` — a temporary laptop-local Yazi integration which should become
    redundant after the shared change lands in `main`
- `laptop-before-rebase` preserves the older laptop history.

The intended model is:

```text
main      shared Linux terminal/editor configuration
pc        PC hardware, display, input, and generated appearance state only
laptop    laptop hardware, display, input, and generated appearance state only
```

## Important: do not cherry-pick `73ae4d8` wholesale

That commit mixes shared Neovim/tmux work with PC-only Noctalia colors, Raffi,
MPV, hardware documentation, and Niri settings. Extract the relevant changes
into small commits on `main`, then rebase `pc` onto the resulting `main`.

## 1. Move the Yazi Neovim workflow to `main`

`origin/main` still uses Neo-tree. `origin/pc` replaces it with `yazi.nvim` and
binds `<Space>e`; this is shared workflow, not PC configuration.

Use a cleaned shared spec in `nvim/.config/nvim/lua/plugins/editor.lua`:

```lua
{
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>e",
      mode = { "n", "v" },
      "<cmd>Yazi<CR>",
      desc = "Open Yazi at current file",
    },
    {
      "<leader>E",
      "<cmd>Yazi cwd<CR>",
      desc = "Open Yazi in working directory",
    },
  },
  opts = {
    open_for_directories = true,
    keymaps = { show_help = "<f1>" },
  },
}
```

Also:

- Remove the Neo-tree spec.
- Add and track `nvim/.config/nvim/lazy-lock.json`. README already claims it
  is tracked, but the file is absent from `main` and exists only on `pc`.
- Regenerate the lockfile from the final shared plugin specification instead
  of copying a stale lock blindly.
- Update `nvim_quickstart.md` from Neo-tree/file-tree language to Yazi.
- Keep Niri `Mod+E` launching Nautilus. Yazi belongs inside Neovim/tmux through
  `<Space>e`, not as a compositor-level launcher.

The laptop has Yazi 26.9.1 installed and its stow package linked. The local
`yazi.nvim` checkout was verified to register both `:Yazi` and `<Space>e`.

## 2. Review the other Neovim changes currently hidden in `pc`

All of these came from `73ae4d8`:

- `mason.nvim` gains `cmd = "Mason"`. This is not device-specific. Keep it only
  if lazy loading and LSP startup still work, and put it in `main` if retained.
- `vim.notify("LSP attached: ...")` runs for every LSP attachment. Treat this as
  debugging residue and drop it unless the notification is deliberately wanted
  on every machine.
- Rose Pine changes to `transparency = true`. This is a shared visual preference,
  not hardware configuration. Either promote it to `main` or revert it from
  `pc`; do not leave it classified as PC-specific by accident.

## 3. Review the tmux `sesh` binding

`origin/pc` adds `prefix f` using `sesh`, `zoxide`, and `fzf-tmux`. This is a
shared workflow concept, but it is not portable yet:

- Laptop currently has `fzf-tmux`.
- Laptop currently does not have `sesh` or `zoxide`.
- The repository has no executable dependency/bootstrap setup for the binding.

Move the binding to `main` only together with installation/bootstrap guidance
and a graceful missing-command path. Otherwise leave it out of `main`; it is
not hardware-specific, but a broken shared binding is worse than no binding.

## 4. Fix Alacritty ownership instead of promoting the PC palette

Do not move the `origin/pc` changes to
`alacritty/.config/alacritty/themes/noctalia.toml` into `main` as-is. They look
like generated wallpaper/Noctalia palette state.

The current configuration has conflicting color owners:

- `alacritty.toml` imports `themes/noctalia.toml`.
- `alacritty.toml` then defines its own primary, normal, and bright colors.
- Neovim and tmux pin static `#201A28` / `#2A2136` / `#382E47` values.
- The generated PC Noctalia palette uses different values.

Choose one color source in `main`: either a static shared terminal palette that
Neovim/tmux match, or generated Noctalia colors with all consumers updated from
the same source. Keep generated wallpaper palettes in host branches or out of
Git.

There are two more Alacritty issues:

- `font.size = 10` in `main` is laptop-specific. The PC handoff itself says the
  PC needs roughly 12–13. Prefer no size in `main`, then explicit size overrides
  in `laptop` and `pc`.
- `Ctrl+L` is bound both to `ClearLogNotice` and to sending `\f`. Resolve this in
  `main` and verify tmux `C-l` pane navigation still works.

## 5. Expected branch result

Commit shared changes to `main` in focused pieces. Suggested grouping:

1. `nvim: replace neo-tree with yazi`
2. `nvim: track plugin lockfile`
3. `tmux: add portable sesh project picker` (only if dependencies are handled)
4. `terminal: clarify shared colors and host font sizing`

Then rebase `pc` onto updated `main`, retaining only PC-specific differences.
Do not modify or force-push `laptop`; the laptop checkout will fetch the finished
`main`, rebase its local commits, remove the now-duplicate Yazi commit, resolve
conflicts without dropping laptop display work, and update `origin/laptop`.

## Validation

- Run `niri validate -c niri/.config/niri/config.kdl` if Niri files change.
- Start Neovim headless and verify `:Yazi` plus the `<Space>e` mapping.
- Open `nvim .`, confirm Yazi opens, select a file, and confirm it returns to
  Neovim.
- Reload tmux with `prefix r`; verify `C-h/j/k/l`, `prefix g`, and any promoted
  `prefix f` binding.
- Run `git diff --check` and leave the worktree clean.
