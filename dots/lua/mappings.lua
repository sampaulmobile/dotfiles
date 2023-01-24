local k = vim.keymap

-- jj to exit insert mode
k.set({ 'i' }, 'jj', '<esc>')

-- Misc <leader> mappings
k.set('n', '<Leader>vs', '<cmd>vsplit<cr>', { silent = true })
k.set('n', '<Leader>s', '<cmd>split<cr>', { silent = true })
k.set('n', '<Leader>c', '<cmd>close<cr>', { silent = true })
k.set('n', '<Leader>w', '<cmd>w<cr>', { silent = true })
k.set('n', '<Leader>wq', '<cmd>wq<cr>', { silent = true })
k.set('n', '<Leader>q', '<cmd>q<cr>', { silent = true })
k.set('n', '<Leader>r', '<cmd>so $MYVIMRC<cr>')

-- Move between split windows with Ctrl + hlkj keys
k.set('n', '<C-h>', '<C-w>h', { silent = true })
k.set('n', '<C-l>', '<C-w>l', { silent = true })
k.set('n', '<C-k>', '<C-w>k', { silent = true })
k.set('n', '<C-j>', '<C-w>j', { silent = true })

-- Buffer navigation
k.set("n", "<leader>]", "<cmd>bnext<cr>")
k.set("n", "<leader>[", "<cmd>bprev<cr>")
k.set("n", "L", "<cmd>bnext<cr>")
k.set("n", "H", "<cmd>bprev<cr>")

-- Make search results appear in middle of screen
k.set('n', 'n', 'nzz', { silent = true })
k.set('n', 'N', 'Nzz', { silent = true })
k.set('n', '*', '*zz', { silent = true })
k.set('n', '#', '#zz', { silent = true })
k.set('n', 'g*', 'g*zz', { silent = true })
k.set('n', 'g#', 'g#zz', { silent = true })

-- Clear searches with ESC
k.set('n', '<esc>', '<cmd>noh<cr><esc>', { silent = true })
k.set('n', '<esc>^[', '<esc>^[', { silent = true })

-- Remove unnecessary whitespace (trailing, between {}/quotes)
-- TODO - get this to work
k.set('n', '<Leader>ww', [[:let _s=@/
  \<Bar>:%s/\s\+$//e
  \<Bar>:%s/{ '/{'/e
  \<Bar>:%s/' }/'}/e
  \<Bar>:%s/{ "/{"/e  
  \<Bar>:%s/" }/"}/e
  \<Bar>:let @/=_s<Bar><CR>]], { silent = true })

-- format json
k.set('n', 'fj', '<cmd>%!python -m json.tool<cr>')
