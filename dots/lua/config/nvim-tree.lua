return function()
  require("nvim-tree").setup({
    open_on_setup = true,
    sort_by = "case_sensitive",
    view = {
      width = 20
    },
    renderer = {
      group_empty = true,
    },
    on_attach = function(bufnr)
      local bufmap = function(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- :help nvim-tree.api
      local api = require('nvim-tree.api')

      bufmap('I', api.tree.toggle_hidden_filter, 'Toggle hidden files')
      bufmap('gh', api.tree.toggle_hidden_filter, 'Toggle hidden files')
    end
  })

  vim.keymap.set('', 'T', '<cmd>NvimTreeToggle<cr>')

  -- close neovim if nvim-tree is last window open
  -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close
  vim.api.nvim_create_autocmd("BufEnter", {
    nested = true,
    callback = function()
      if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
        vim.cmd "quit"
      end
    end
  })
end
