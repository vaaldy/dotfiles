-- ~/.config/nvim/init.lua
-- Terminal-only agentic setup. Leader is <Space>; nothing here binds Alt/Option,
-- so yabai keeps Opt+A / Opt+D / Opt+R (+Shift) to itself.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.keymaps")
