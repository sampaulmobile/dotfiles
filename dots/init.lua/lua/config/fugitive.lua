return function()
  local k = vim.keymap

  k.set('', '<leader>gb', '<cmd>Git blame<cr>')
  k.set('', '<leader>gh', '<cmd>GBrowse<cr>')
end
