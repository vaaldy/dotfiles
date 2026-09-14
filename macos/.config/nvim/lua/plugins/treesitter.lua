-- The "good text highlighter": treesitter builds a real syntax tree per buffer,
-- so highlighting, indentation and text objects understand code structure
-- instead of pattern-matching it.

-- ── Neovim 0.12 compatibility shim for nvim-treesitter ──────────────────────
-- In Neovim 0.12, query predicates and directives receive `match` where each
-- capture ID maps to a `TSNode[]` list, not a single `TSNode`. Legacy
-- nvim-treesitter directives (#downcase!, #set-lang-from-info-string!,
-- #set-lang-from-mimetype!) and predicates (#nth?, #is?, #kind-eq?) expect
-- single TSNodes and call node methods (or pass them to get_node_text which
-- calls node:range()), causing "attempt to call method 'range' (a nil value)"
-- whenever files have heredocs (sh/bash), fences (markdown), embedded scripts, etc.
if not vim.g._ts_012_compat_applied then
  vim.g._ts_012_compat_applied = true

  local orig_get_node_text = vim.treesitter.get_node_text
  vim.treesitter.get_node_text = function(node, source, opts)
    if type(node) == "table" and node[1] then
      node = node[1]
    end
    return orig_get_node_text(node, source, opts)
  end

  local function unwrap_match(match)
    local unwrapped = {}
    for k, v in pairs(match) do
      if type(v) == "table" and v[1] and type(v[1]) == "userdata" then
        unwrapped[k] = v[1]
      else
        unwrapped[k] = v
      end
    end
    return unwrapped
  end

  local orig_add_directive = vim.treesitter.query.add_directive
  vim.treesitter.query.add_directive = function(name, handler, opts)
    local wrapped = function(match, pattern, bufnr, pred, metadata)
      return handler(unwrap_match(match), pattern, bufnr, pred, metadata)
    end
    return orig_add_directive(name, wrapped, opts)
  end

  local orig_add_predicate = vim.treesitter.query.add_predicate
  vim.treesitter.query.add_predicate = function(name, handler, opts)
    local wrapped = function(match, pattern, bufnr, pred)
      return handler(unwrap_match(match), pattern, bufnr, pred)
    end
    return orig_add_predicate(name, wrapped, opts)
  end
end

-- Fallback: Neovim's own bundled markdown injections query
pcall(function()
  local path = vim.fs.joinpath(vim.env.VIMRUNTIME, "queries", "markdown", "injections.scm")
  local lines = vim.fn.readfile(path)
  if type(lines) == "table" and #lines > 0 then
    vim.treesitter.query.set("markdown", "injections", table.concat(lines, "\n"))
  end
end)

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
    main = "treesitter-context",
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      -- Belt-and-braces with the injection-query fix above: skip markdown
      -- entirely. This replaces an earlier workaround that called
      -- `:TSContextDisable` — a command this plugin no longer registers (it
      -- exposes `:TSContext <subcommand>` now), so it threw E492 into a pcall
      -- that swallowed it and the guard never actually ran. That version was
      -- doubly wrong anyway: TSContextDisable is global with no re-enable, so
      -- one markdown file would have killed sticky context everywhere for the
      -- rest of the session, and it read `vim.bo.filetype` (the CURRENT
      -- buffer) rather than the buffer the FileType event fired for, so it
      -- no-op'd whenever a markdown buffer loaded unfocused.
      -- on_attach returning false disables context per-buffer. No commands,
      -- no autocmds, no global state.
      on_attach = function(buf)
        local ft = vim.bo[buf].filetype
        return ft ~= "markdown" and ft ~= "markdown_inline" and ft ~= "mdx"
      end,
    },
  },
}
