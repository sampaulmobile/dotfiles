-- Options are automatically loaded before lazy.nvim startup
-- Add any additional options here

vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Custom options
opt.wrap = false
opt.visualbell = true         -- No sounds
opt.synmaxcol = 300           -- Stop syntax highlight after x lines for performance

-- Tabs/indentation (4 spaces instead of LazyVim default 2)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 15
opt.sidescroll = 1

-- Splits
opt.splitright = false

-- Clipboard
opt.clipboard = "unnamed"     -- Use OS clipboard

-- Folding
opt.foldmethod = "syntax"

-- Whitespace display
opt.list = true
opt.listchars = "eol:⏎,tab:▸·,trail:×,nbsp:⎵"

-- Performance
opt.updatetime = 50
