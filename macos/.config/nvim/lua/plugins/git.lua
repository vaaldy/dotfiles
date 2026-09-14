return {
  -- ── inline git state in the gutter ────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" }, change = { text = "▎" },
        delete = { text = "" }, topdelete = { text = "" }, changedelete = { text = "▎" },
      },
      current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function m(mode, l, r, d)
          vim.keymap.set(mode, l, r, { buffer = buf, desc = "Git: " .. d })
        end
        m("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        m("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        m("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        m("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        m("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
        m("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
        m("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle inline blame")
        m("n", "<leader>hd", gs.diffthis, "Diff this file")
        -- ih = "in hunk": `dih` discards a hunk, `vih` selects one
        m({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  -- ── review what the agent changed ─────────────────────────────────────────
  -- This is the single most useful git plugin in an agentic loop: an agent
  -- touches nine files, and `<leader>gd` gives you a real side-by-side review
  -- with per-hunk staging, instead of scrolling a wall of terminal diff.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Review working changes" },
      { "<leader>gD", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "Review last commit" },
      { "<leader>gm", function()
          local base = vim.fn.systemlist("git merge-base HEAD main 2>/dev/null")[1]
          if not base or base == "" then
            base = vim.fn.systemlist("git merge-base HEAD master 2>/dev/null")[1]
          end
          if not base or base == "" then
            vim.notify("no merge-base against main/master", vim.log.levels.WARN)
            return
          end
          vim.cmd("DiffviewOpen " .. base)
        end, desc = "Review branch vs main" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "History of this file" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "History of this branch" },
      { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Close diffview" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
      file_panel = { listing_style = "tree", win_config = { width = 32 } },
      keymaps = {
        view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close" } } },
        file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close" } } },
      },
    },
  },

  -- ── conflict resolution without memorising >>>>>>> arithmetic ─────────────
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPre" },
    opts = {
      default_mappings = false,
      disable_diagnostics = true,
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)
      local map = vim.keymap.set
      map("n", "<leader>co", "<Plug>(git-conflict-ours)", { desc = "Conflict: take ours" })
      map("n", "<leader>ct", "<Plug>(git-conflict-theirs)", { desc = "Conflict: take theirs" })
      map("n", "<leader>cb", "<Plug>(git-conflict-both)", { desc = "Conflict: take both" })
      map("n", "<leader>c0", "<Plug>(git-conflict-none)", { desc = "Conflict: take none" })
      map("n", "]x", "<Plug>(git-conflict-next-conflict)", { desc = "Next conflict" })
      map("n", "[x", "<Plug>(git-conflict-prev-conflict)", { desc = "Prev conflict" })
    end,
  },
}
