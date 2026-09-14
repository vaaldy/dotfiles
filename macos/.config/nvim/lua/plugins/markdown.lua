return {
  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    main = "markdown",
    opts = {
      -- Keep nvim-surround's global ds/cs/ys workflow intact in Markdown.
      mappings = {
        inline_surround_toggle = false,
        inline_surround_toggle_line = false,
        inline_surround_delete = false,
        inline_surround_change = false,
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", desc = "Markdown preview toggle" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
      }
    end,
    keys = {
      { "<leader>mb", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown browser preview" },
    },
  },
}
