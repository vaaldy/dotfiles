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
    opts = { max_lines = 3, multiline_threshold = 1 },
    config = function(_, opts)
      require("treesitter-context").setup(opts)
      -- Neovim 0.12.x regression: markdown's bundled treesitter query calls
      -- .range() on a nil node for fenced-code-block delimiters, and this
      -- plugin's parent-langtree walk (used to compute the sticky header)
      -- crosses right into that path. Upstream: neovim/neovim#39032, closed
      -- "not planned" — so scope the workaround to markdown specifically
      -- rather than losing sticky context everywhere.
      local function disable_if_markdown()
        if vim.bo.filetype == "markdown" then
          pcall(vim.cmd, "TSContextDisable")
        end
      end
      -- Covers future markdown buffers...
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = disable_if_markdown,
      })
      -- ...and the buffer that's open RIGHT NOW, since this plugin lazy-loads
      -- on BufReadPost/BufNewFile — the same moment a file's FileType event
      -- fires. That's a race: this config() function can run after that
      -- buffer's FileType has already fired, so the autocmd above alone
      -- would miss exactly the file that triggered the plugin to load.
      disable_if_markdown()
    end,
  },
}
