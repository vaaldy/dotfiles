return {
  -- ── colorscheme ───────────────────────────────────────────────────────────
  -- The macOS config ran Tokyo Night Storm. This machine's Alacritty uses the
  -- noctalia purple theme (~/.config/alacritty/themes/noctalia.toml), and a
  -- blue-grey editor on a purple terminal reads as a mistake — so: rose-pine,
  -- whose default palette is already purple-leaning, with base/surface/overlay
  -- pinned to the exact Alacritty and tmux values. nvim's background, tmux's
  -- statusline and the terminal background then agree to the byte.
  --
  -- To go back to the Mac's theme, swap this block for folke/tokyonight.nvim
  -- with opts = { style = "storm" } and set lualine's theme to "tokyonight".
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    opts = {
      variant = "main",
      dark_variant = "main",
      styles = { italic = true, transparency = false },
      palette = {
        main = {
          base = "#201A28",    -- == alacritty colors.primary.background
          surface = "#2A2136", -- == tmux status-style bg
          overlay = "#382E47", -- == tmux pane-border-style fg
        },
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme("rose-pine")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        -- "auto" derives from whatever colorscheme is active, so this keeps
        -- working if you swap themes later.
        theme = "auto",
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
