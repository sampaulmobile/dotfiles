return function()
  local k = vim.keymap

  k.set({ 'n', 'v' }, '<leader>a=', '<cmd>Tabularize /=<cr>')
  k.set({ 'n', 'v' }, '<leader>a:', '<cmd>Tabularize /:\zs<cr>')
end
