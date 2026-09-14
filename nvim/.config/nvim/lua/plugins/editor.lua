return {
  -- ── file manager ──────────────────────────────────────────────────────────
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
  },

  -- ── auto brackets / pairs ─────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,             -- treesitter-aware: no pairs inside strings/comments
      fast_wrap = {
        map = "<C-e>",             -- wrap the next word in the pair you just typed
        chars = { "{", "[", "(", '"', "'" },
      },
    },
  },
  {
    -- surround/change existing pairs: cs"' , ysiw( , ds(
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
  {
    -- auto-close HTML/JSX tags, treesitter driven
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },

  -- ── markdown ──────────────────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown rendering" },
    },
    opts = {},
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    keys = {
      { "<leader>mb", "<cmd>MarkdownPreviewToggle<CR>", desc = "Toggle Markdown browser preview" },
    },
    build = function() vim.fn["mkdp#util#install"]() end,
  },

  -- ── fuzzy finding ─────────────────────────────────────────────────────────
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Grep project" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua helptags<CR>", desc = "Help" },
      { "<leader>fr", "<cmd>FzfLua resume<CR>", desc = "Resume last search" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", desc = "Document symbols" },
      { "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<CR>", desc = "Workspace symbols" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<CR>", desc = "Diagnostics" },
      { "<leader>fc", "<cmd>FzfLua git_status<CR>", desc = "Changed files" },
      { "<leader>/",  "<cmd>FzfLua blines<CR>", desc = "Search in buffer" },
    },
    opts = {
      "telescope",
      files = { hidden = true, no_ignore = true },
      winopts = { height = 0.85, width = 0.85, preview = { layout = "flex" } },
    },
  },

  -- ── tmux <-> nvim pane navigation with C-hjkl ─────────────────────────────
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>",  desc = "Pane left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>",  desc = "Pane down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>",    desc = "Pane up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Pane right" },
    },
  },

  -- git lives in lua/plugins/git.lua
}
