return {
  -- ── file manager (fast Rust-backed floating file manager) ─────────────────
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>e", "<cmd>Yazi<CR>", desc = "Yazi (current file)" },
      { "<leader>E", "<cmd>Yazi cwd<CR>", desc = "Yazi (working dir)" },
      { "<c-up>", "<cmd>Yazi toggle<CR>", desc = "Yazi toggle" },
    },
    opts = {
      open_for_directories = true,
      keymaps = {
        show_help = "<f1>",
      },
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
      { "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<CR>", desc = "Workspace symbols (repo-wide)" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<CR>", desc = "Diagnostics" },
      { "<leader>fc", "<cmd>FzfLua git_status<CR>", desc = "Changed files" },
      { "<leader>/",  "<cmd>FzfLua blines<CR>", desc = "Search in buffer" },
    },
    opts = { "telescope", winopts = { height = 0.85, width = 0.85, preview = { layout = "flex" } } },
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
