vim.g.mapleader = "," --Change leader to a comma
vim.g.maplocalleader = "\\" --Change local leader to backslash

vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true  -- Make relative number default
vim.opt.wrap = false -- Don't wrap lines
vim.opt.visualbell = true -- No sounds
vim.opt.autochdir = true -- Always o.pwd to path of current file
vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.smartcase = true -- Override 'ignorecase' if search has uppercase
vim.opt.undofile = true
vim.opt.synmaxcol = 300 -- stop syntax highlight after x lines for performance

vim.opt.expandtab = true -- use space instead of tab by default
vim.opt.showmode = false -- Don't show the mode (we use lualine instead)
vim.opt.scrolloff = 8 -- Start scrolling 8 lines from top/bottom margin
vim.opt.sidescrolloff = 15 -- Start scrolling 15 lines from left/right margin
vim.opt.sidescroll = 1 -- Scroll horizontally by 1 character at time
vim.opt.splitright = true -- will put the new window right of the current one.

vim.opt.clipboard = "unnamed" -- Allow vim to access OS clipboard
vim.opt.foldmethod = "syntax" -- Fold by syntax
-- set guicursor=a:blinkon0 -- Disable cursor blink

vim.opt.mouse = "a" -- Allow mouse to drag/adjust window splits

-- vim.opt.cursorline = true      -- show cursor line
-- vim.opt.cursorcolumn = true    -- show cursor column
-- vim.opt.joinspaces = false     -- No double spaces with join after a dot

vim.opt.list = true -- show space and tabs chars
vim.opt.listchars = "eol:⏎,tab:▸·,trail:×,nbsp:⎵"

-- guifont only applies to GUI/non-terminal neovim
-- vim.opt.guifont = "Hack Nerd Font Mono"
-- vim.opt.colorcolumn = "80"

-- I don't think this works for WSL on Windows or Windows in general
vim.opt.updatetime = 50


--[[
vim.opt.fillchars = {
  vert = "│",
  fold = "⠀",
  eob = " ", -- suppress ~ at EndOfBuffer
  --diff = "⣿", -- alternatives = ⣿ ░ ─ ╱
  msgsep = "‾",
  foldopen = "▾",
  foldsep = "│",
  foldclose = "▸",
}
]] --


-- Disable scrollbars
vim.cmd [[set guioptions-=r]]
vim.cmd [[set guioptions-=R]]
vim.cmd [[set guioptions-=l]]
vim.cmd [[set guioptions-=L]]
-- o.guioptions = o.guioptions - "r"
-- o.guioptions = o.guioptions - "R"
-- o.guioptions = o.guioptions - "l"
-- o.guioptions = o.guioptions - "L"

