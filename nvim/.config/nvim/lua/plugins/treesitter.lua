-- ───────────────────────────────────────────────────────────────────────────
-- Markdown injections: work around a broken nvim-treesitter directive.
--
-- Symptom, on every cursor move in a markdown buffer containing ``` blocks:
--   Decoration provider "start" (ns=nvim.treesitter.highlighter):
--   .../vim/treesitter.lua:197: attempt to call method 'range' (a nil value)
--
-- Cause: nvim-treesitter ships its own queries/markdown/injections.scm which
-- resolves the fence language via a custom directive, implemented at
-- nvim-treesitter/lua/nvim-treesitter/query_predicates.lua:135 —
--
--     local node = match[capture_id]
--     if not node then return end
--     local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
--
-- On Neovim 0.12 `match[capture_id]` is a TSNode[] LIST, not a single TSNode.
-- A table is truthy, so the nil-guard passes, and get_node_text() goes on to
-- call vim.treesitter.get_range() -> `node:range(true)` on a plain table.
-- It throws from the async parse coroutine driven by the highlighter, hence
-- the decoration-provider framing.
--
-- Upstream declined it on both sides: neovim/neovim#39032 and
-- nvim-treesitter#8618 are closed "not planned" (see also #8636 for the
-- underlying match[id] API change). nvim-treesitter's master branch is in
-- maintenance — `main` is the rewrite — so no fix is coming.
--
-- Below is Neovim 0.12's own $VIMRUNTIME/queries/markdown/injections.scm,
-- which needs no custom directive: it captures @injection.language directly.
--
-- Why query.set() rather than a file in ~/.config/nvim/queries/: query.set
-- writes to the `explicit_queries` table, which vim/treesitter/query.lua:293
-- consults BEFORE any runtimepath lookup, and M.set() clears the memoized
-- M.get cache. So it does not depend on stow having linked a queries/
-- directory, on runtimepath ordering, or on load timing. There is no
-- ';; extends' modeline, so this fully REPLACES the plugin's query rather
-- than appending to it (query.lua:312-323).
--
-- TO REVERT: delete this block. If nvim-treesitter ever fixes the directive,
-- that is the only change needed.
-- ───────────────────────────────────────────────────────────────────────────
vim.treesitter.query.set(
  "markdown",
  "injections",
  [==[
(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
]==]
)

-- The "good text highlighter": treesitter builds a real syntax tree per buffer,
-- so highlighting, indentation and text objects understand code structure
-- instead of pattern-matching it.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- stable API; `main` is the in-progress rewrite
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash", "c", "css", "diff", "dockerfile", "go", "html", "javascript",
        "json", "jsonc", "lua", "luadoc", "make", "markdown", "markdown_inline",
        "python", "query", "regex", "rust", "toml", "tsx", "typescript",
        "vim", "vimdoc", "yaml",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        -- NOT <C-space>: tmux owns that as its prefix, so it never reaches nvim.
        keymaps = {
          init_selection = "<leader>v",
          node_incremental = "v",
          node_decremental = "V",
          scope_incremental = false,
        },
      },
    },
  },

  -- structural text objects: vaf = around function, cif = change inside function
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer", ["if"] = "@function.inner",
              ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",["ia"] = "@parameter.inner",
              ["ai"] = "@conditional.outer", ["ii"] = "@conditional.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          },
        },
      })
    end,
  },

  -- sticky header showing the enclosing function/class
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 3,
      multiline_threshold = 1,

      -- Neovim 0.12 regression, still unfixed: markdown's bundled query sets
      -- `conceal_lines` on fenced-code-block delimiters, and 0.12 calls
      -- .range() on a nil node handling it. This plugin's parent-langtree
      -- walk (how it computes the sticky header) goes straight through that
      -- path, so any markdown buffer containing a ``` block throws on every
      -- cursor move. Both upstreams closed it "not planned":
      --   neovim/neovim#39032
      --   nvim-treesitter/nvim-treesitter#8618
      --
      -- So the buffer simply never gets attached. `on_attach` is the plugin's
      -- own per-buffer hook — return false to skip a buffer. It replaces an
      -- earlier TSContextDisable-on-FileType workaround that had two holes:
      -- TSContextDisable is GLOBAL with no re-enable (one markdown file killed
      -- sticky context everywhere for the rest of the session), and the guard
      -- read `vim.bo.filetype` — the *current* buffer — rather than the buffer
      -- the event fired for, so it no-op'd whenever a markdown buffer loaded
      -- while something else was focused. Here the plugin hands us the right
      -- buffer and there is no global state to leak.
      on_attach = function(buf)
        local ft = vim.bo[buf].filetype
        return ft ~= "markdown" and ft ~= "markdown_inline" and ft ~= "mdx"
      end,
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)
    end,
  },
}
