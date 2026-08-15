-- ~/.config/nvim/init.lua
-- Terminal-only setup, ported from macOS. Leader is <Space>; nothing here binds
-- Alt, and niri binds everything on Mod (Super), so the two never collide.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.keymaps")
