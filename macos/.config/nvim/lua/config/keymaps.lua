local map = vim.keymap.set

-- ── yabai rule ──────────────────────────────────────────────────────────────
-- No mapping in this config uses <M-...> / Alt / Option. Opt+A, Opt+D, Opt+R
-- and their Shift variants never reach nvim, and nothing here wants them.
-- ────────────────────────────────────────────────────────────────────────────

-- basics
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("i", "jk", "<Esc>", { desc = "Escape" })

-- keep the cursor put
-- Ctrl-d/Ctrl-u used to be remapped here to auto-center (zz) after jumping.
-- neoscroll.nvim (lua/plugins/ui.lua) now owns those two keys instead, for
-- the smooth-scroll animation — centering-after-jump traded away on purpose
-- for that. n/N below are unrelated and still center as before.
map("n", "J", "mzJ`z", { desc = "Join, keep cursor" })
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- move selected lines (visual mode only; no Alt involved)
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<", "<gv")
map("v", ">", ">gv")

-- paste/delete without clobbering the yank register
map("x", "<leader>p", [["_dP]], { desc = "Paste over, keep register" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- splits (C-hjkl is taken by vim-tmux-navigator, so splits use leader)
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ss", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })
map("n", "<leader>s=", "<C-w>=", { desc = "Equalize splits" })

-- diagnostics
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })

-- terminal escape hatch
map("t", "<C-\\><C-n>", "<C-\\><C-n>", { desc = "Terminal normal mode" })

-- reload files the agent touched, on demand
map("n", "<leader>r", "<cmd>checktime<CR>", { desc = "Reload changed files" })
