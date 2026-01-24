-- Keymaps are automatically loaded on the VeryLazy event
-- Add any additional keymaps here

local k = vim.keymap

-- jj to exit insert mode
k.set("i", "jj", "<esc>", { desc = "Exit insert mode" })

-- Misc <leader> mappings
k.set("n", "<leader>vs", "<cmd>vsplit<cr>", { silent = true, desc = "Vertical split" })
k.set("n", "<leader>s", "<cmd>split<cr>", { silent = true, desc = "Horizontal split" })
k.set("n", "<leader>c", "<cmd>close<cr>", { silent = true, desc = "Close window" })
k.set("n", "<leader>w", "<cmd>w<cr>", { silent = true, desc = "Save file" })
k.set("n", "<leader>wq", "<cmd>wq<cr>", { silent = true, desc = "Save and quit" })
k.set("n", "<leader>q", "<cmd>q<cr>", { silent = true, desc = "Quit" })
k.set("n", "<leader>r", "<cmd>so $MYVIMRC<cr>", { desc = "Reload config" })

-- Move between split windows with Ctrl + hjkl
k.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "Go to left window" })
k.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "Go to right window" })
k.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "Go to upper window" })
k.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "Go to lower window" })

-- Buffer navigation
k.set("n", "<leader>]", "<cmd>bnext<cr>", { desc = "Next buffer" })
k.set("n", "<leader>[", "<cmd>bprev<cr>", { desc = "Previous buffer" })
k.set("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })
k.set("n", "H", "<cmd>bprev<cr>", { desc = "Previous buffer" })

-- Make search results appear in middle of screen
k.set("n", "n", "nzz", { silent = true, desc = "Next search result (centered)" })
k.set("n", "N", "Nzz", { silent = true, desc = "Prev search result (centered)" })
k.set("n", "*", "*zz", { silent = true, desc = "Search word (centered)" })
k.set("n", "#", "#zz", { silent = true, desc = "Search word backward (centered)" })
k.set("n", "g*", "g*zz", { silent = true, desc = "Search partial word (centered)" })
k.set("n", "g#", "g#zz", { silent = true, desc = "Search partial word backward (centered)" })

-- Clear searches with ESC
k.set("n", "<esc>", "<cmd>noh<cr><esc>", { silent = true, desc = "Clear search highlight" })

-- Format JSON
k.set("n", "fj", "<cmd>%!python -m json.tool<cr>", { desc = "Format JSON" })
