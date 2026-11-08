-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Smooth horizontal scrolling with mouse wheel / trackpad gestures
vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelRight>", "5zl", { silent = true, desc = "Scroll view right" })
vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelLeft>", "5zh", { silent = true, desc = "Scroll view left" })
vim.keymap.set({ "n", "v", "i" }, "<S-ScrollWheelDown>", "5zl", { silent = true, desc = "Scroll view right" })
vim.keymap.set({ "n", "v", "i" }, "<S-ScrollWheelUp>", "5zh", { silent = true, desc = "Scroll view left" })

-- Horizontal scrolling with keyboard (Alt + Left / Alt + Right)
vim.keymap.set({ "n", "v" }, "<A-Left>", "5zh", { silent = true, desc = "Scroll view left" })
vim.keymap.set({ "n", "v" }, "<A-Right>", "5zl", { silent = true, desc = "Scroll view right" })
vim.keymap.set("i", "<A-Left>", "<C-o>5zh", { silent = true, desc = "Scroll view left" })
vim.keymap.set("i", "<A-Right>", "<C-o>5zl", { silent = true, desc = "Scroll view right" })
