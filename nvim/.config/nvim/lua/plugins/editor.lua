return {
  -- ── file tree ─────────────────────────────────────────────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle reveal left<CR>", desc = "Explorer toggle" },
      { "<leader>E", "<cmd>Neotree reveal left<CR>", desc = "Explorer reveal file" },
      { "<leader>ge", "<cmd>Neotree float git_status<CR>", desc = "Explorer git status" },
      { "<leader>be", "<cmd>Neotree toggle show buffers right<CR>", desc = "Explorer buffers" },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true, -- picks up files an agent creates in another pane
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { ".git", "node_modules", ".DS_Store" },
        },
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "none", -- leader stays leader
          ["l"] = "open",
          ["h"] = "close_node",
          ["P"] = { "toggle_preview", config = { use_float = true } },
        },
      },
      default_component_configs = {
        indent = { with_expanders = true },
        git_status = { symbols = { added = "+", modified = "~", deleted = "-", renamed = "→" } },
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
      { "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<CR>", desc = "Workspace symbols" },
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
