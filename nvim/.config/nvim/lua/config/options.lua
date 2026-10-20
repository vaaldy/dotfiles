local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.splitbelow = true
opt.splitright = true

opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.updatetime = 200
opt.timeoutlen = 400

opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- Wayland system clipboard, via wl-clipboard
opt.confirm = true
opt.splitkeep = "screen"
opt.laststatus = 3            -- one global statusline, plays nicer inside tmux
opt.fillchars = { eob = " " }

-- Treesitter syntax-aware folding (JSON objects/arrays, functions, classes, etc.)
-- Starts unfolded (level 99); use za / zc / zo / zM / zR to collapse & expand.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Agent-friendly: files edited by a CLI agent in another pane show up here.
-- Needs `set -g focus-events on` in tmux.conf (it's there).
opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("agent_autoread", { clear = true }),
  command = "checktime",
})

-- Yank flash, so you can see what the register got.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
