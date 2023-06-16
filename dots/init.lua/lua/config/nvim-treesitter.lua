return function()
  require('nvim-treesitter.configs').setup({
    highlight = {
      enable = true,
      disable = {},
    },
    indent = {
      enable = false,
      disable = {},
    },
    ensure_installed = {
      "c",
      "help",
      "vim",
      "lua",
      "json",
      "yaml",
      "html",
      "python",
    },
    endwise = {
      enable = true
    }
  })

  -- o.foldenable = false
  -- vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile', 'BufWinEnter' }, {
  -- group = vim.api.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
  -- callback = function()
  -- vim.opt.foldmethod = 'expr'
  -- vim.opt.foldexpr   = 'nvim_treesitter#foldexpr()'
  -- end
  -- })
end
