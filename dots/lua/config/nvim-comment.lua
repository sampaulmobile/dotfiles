return function()
  local k = vim.keymap

  require('nvim_comment').setup({
    line_mapping = "<leader>/",
    operator_mapping = "<leader>/",
  })

  k.set('n', '<leader>/', '<cmd>CommentToggle<cr>')
end
