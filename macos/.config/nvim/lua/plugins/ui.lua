return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
     opts = { style = "storm", transparent = true, styles = { comments = { italic = true } } },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
        section_separators = "",
        component_separators = "│",
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics", "filetype" },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>s", group = "split" },
        { "<leader>c", group = "code / conflict" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunk" },
        { "<leader>b", group = "buffer" },
        { "<leader>x", group = "diagnostics" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },

  -- smooth animated scrolling — purely cosmetic, no effect on how far/fast
  -- you actually navigate, just how it looks getting there
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      -- Ctrl-d/Ctrl-u included on request — the old auto-center-after-jump
      -- remap for them (keymaps.lua) was removed to make room, since
      -- neoscroll's own handling of these two doesn't carry that over.
      mappings = { "<C-b>", "<C-f>", "<C-y>", "<C-e>", "<C-d>", "<C-u>", "zt", "zz", "zb" },
    },
  },

  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      bigfile = { enabled = true },   -- don't choke on generated files
      indent = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
    },
  },
}
