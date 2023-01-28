local g = vim.g

g.mapleader = "," --Change leader to a comma
g.maplocalleader = "\\" --Change local leader to backslash

local o = vim.o

o.number = true -- Show line numbers
-- o.relativenumber = true  -- Make relative number default
o.wrap = false -- Don't wrap lines
o.visualbell = true -- No sounds
o.autochdir = true -- Always o.pwd to path of current file
o.ignorecase = true -- Ignore case when searching
o.smartcase = true -- Override 'ignorecase' if search has uppercase
o.undofile = true
o.synmaxcol = 300 -- stop syntax highlight after x lines for performance

o.expandtab = true -- use space instead of tab by default
o.showmode = false -- Don't show the mode (we use lualine instead)
o.scrolloff = 8 -- Start scrolling 8 lines from top/bottom margin
o.sidescrolloff = 15 -- Start scrolling 15 lines from left/right margin
o.sidescroll = 1 -- Scroll horizontally by 1 character at time

o.clipboard = "unnamed" -- Allow vim to access OS clipboard
o.foldmethod = "syntax" -- Fold by syntax
-- set guicursor=a:blinkon0 -- Disable cursor blink

o.mouse = "a" -- Allow mouse to drag/adjust window splits

-- o.cursorline = true      -- show cursor line
-- o.cursorcolumn = true    -- show cursor column
-- o.joinspaces = false     -- No double spaces with join after a dot

o.list = true -- show space and tabs chars
o.listchars = "eol:⏎,tab:▸·,trail:×,nbsp:⎵"

-- guifont only applies to GUI/non-terminal neovim
-- o.guifont = "Hack Nerd Font Mono"


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


-- TODO - check if we need these when using plugins
-- " Auto complete stuff
-- set wildmode=list:longest,full     "first list:longest then full
-- set wildmenu                       "enable ctrl-n and ctrl-p to scroll thru matches
-- set wildignore=*.o,*.obj,*~        "stuff to ignore when tab completing
-- set wildignore+=*vim/backups*
-- set wildignore+=*sass-cache*
-- set wildignore+=*DS_Store*
-- set wildignore+=vendor/rails/**
-- set wildignore+=vendor/cache/**
-- set wildignore+=*.gem
-- set wildignore+=log/**
-- set wildignore+=tmp/**
-- set wildignore+=*.png,*.jpg,*.gif

-- TODO: check out folding with treesitter
-- o.foldmethod = "expr"
-- o.foldexpr = "nvim_treesitter#foldexpr()"
-- o.foldenable = false

-- o.grepprg = "rg --color=never"
-- Prefer ripgrep if it exists
-- if fn.executable("rg") > 0 then
--   vim.o.grepprg = "rg --hidden --glob '!.git' --no-heading --smart-case --vimgrep --follow $*"
--   vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }
-- end

--
-- o.guicursor = "a:blinkon0,i:ver25-iCursor"
-- o.termguicolors = true
-- o.guicursor:append { "i-c-ci:ver25", "o-v-ve:hor20", "cr-sm-n-r:block" }
