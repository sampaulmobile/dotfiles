return function()
  require("trouble").setup {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }

  local k = vim.keymap
  k.set('n', '<leader>xx', "<cmd>TroubleToggle<cr>")
end
