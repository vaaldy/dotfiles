-- ============================================================================
-- 1. BASIC OPTIONS & MAPLEADER
-- ============================================================================
vim.g.mapleader = " " -- Set Space as the Leader key

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard

-- Fast scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- ============================================================================
-- 2. BOOTSTRAP LAZY.NVIM (Plugin Manager)
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- 3. PLUGINS SPECIFICATION
-- ============================================================================
require("lazy").setup({
  -- Icons dependency
  { "nvim-tree/nvim-web-devicons" },
  -- UI dependencies for Neo-tree
  { "MunifTanjim/nui.nvim" },
  { "nvim-lua/plenary.nvim" },

  -- Neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true, -- Close Neovim if Neo-tree is the last window open
        filesystem = {
          filtered_items = {
            visible = true, -- Show hidden files (dotfiles) by default
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = true, -- Auto-expand tree to current open file
          },
        },
      })
    end,
  },

  -- Automatic Bracket & Quote Pairing
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true, -- Integrates with Treesitter to avoid pairing inside strings/comments
      })
    end,
  },

  {
    "echasnovski/mini.pairs",
    version = "*",
    config = function()
      require("mini.pairs").setup()
    end,
  },
}

)
-- ============================================================================
-- 4. KEYBINDINGS
-- ============================================================================
-- Press Space + e to toggle the file sidebar open/closed
vim.keymap.set("n", "<leader>e", ":Neotree toggle left<CR>", { desc = "Toggle Neo-tree sidebar" })
-- Press Space + o to focus the cursor on Neo-tree
vim.keymap.set("n", "<leader>o", ":Neotree focus<CR>", { desc = "Focus Neo-tree sidebar" })
