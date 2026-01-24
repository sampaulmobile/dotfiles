-- Options are automatically loaded before lazy.nvim startup
-- Add any additional options here

local opt = vim.opt

-- Custom options (preserved from original config)
opt.wrap = false              -- Don't wrap lines
opt.visualbell = true         -- No sounds
opt.autochdir = true          -- Always set pwd to path of current file
opt.synmaxcol = 300           -- Stop syntax highlight after x lines for performance

-- Tabs/indentation (4 spaces instead of LazyVim default 2)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- Scrolling
opt.scrolloff = 8             -- Start scrolling 8 lines from top/bottom margin
opt.sidescrolloff = 15        -- Start scrolling 15 lines from left/right margin
opt.sidescroll = 1            -- Scroll horizontally by 1 character at time

-- Splits
opt.splitright = false        -- Put new window left of current one

-- Clipboard
opt.clipboard = "unnamed"     -- Use OS clipboard

-- Folding
opt.foldmethod = "syntax"

-- Whitespace display
opt.list = true
opt.listchars = "eol:⏎,tab:▸·,trail:×,nbsp:⎵"

-- Performance
opt.updatetime = 50
