-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.autoread = true

-- Disable line wrapping globally so lines do not collapse vertically on window resize or font zoom
vim.opt.wrap = false
vim.opt.sidescroll = 1 -- Smooth horizontal scrolling by 1 column
vim.opt.sidescrolloff = 8 -- Keep 8 columns of context visible horizontally
vim.opt.listchars:append({ precedes = "«", extends = "»" }) -- Show boundary indicator when text overflows horizontally
