return {
  -- ── completion (fast, Rust-backed) ────────────────────────────────────────
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "default",        -- <C-y> accept, <C-n>/<C-p> cycle, <C-e> hide
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = false },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true },
    },
  },

  -- ── LSP servers ───────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      { "mason-org/mason-lspconfig.nvim", opts = {
          ensure_installed = { "lua_ls", "ts_ls", "pyright", "jsonls", "bashls" },
        },
      },
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN]  = "W",
            [vim.diagnostic.severity.INFO]  = "I",
            [vim.diagnostic.severity.HINT]  = "H",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(ev)
          local function m(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          m("gd", "<cmd>FzfLua lsp_definitions<CR>", "Definitions")
          m("gr", "<cmd>FzfLua lsp_references<CR>", "References")
          m("gI", "<cmd>FzfLua lsp_implementations<CR>", "Implementations")
          m("gy", "<cmd>FzfLua lsp_typedefs<CR>", "Type definitions")
          m("K", vim.lsp.buf.hover, "Hover")
          m("<leader>cr", vim.lsp.buf.rename, "Rename")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          vim.keymap.set("v", "<leader>ca", vim.lsp.buf.code_action,
            { buffer = ev.buf, desc = "LSP: Code action" })
        end,
      })

      -- Neovim 0.11+ style: per-server tweaks, then let mason-lspconfig enable them.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })
    end,
  },

  -- ── python venv detection (poetry, conda, plain venv, pipenv...) ─────────
  -- Supersedes the old manual "shell out to `poetry env info --path`" hack —
  -- this handles every env manager, not just poetry, and wires the result
  -- into pyright for you. picker="fzf-lua" reuses your existing fuzzy-finder
  -- instead of pulling in telescope just for this one plugin.
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    ft = "python",
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<CR>", desc = "Select python venv" },
    },
    opts = {
      options = { picker = "fzf-lua" },
    },
  },

  -- ── formatting ────────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        sh = { "shfmt" },
      },
      -- Off by default: an agent writing the same file mid-save is a bad time.
      -- Flip to a table to enable format-on-write.
      format_on_save = nil,
    },
  },
}
