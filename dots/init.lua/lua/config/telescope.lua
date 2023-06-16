return function()
  local k = vim.keymap

  local builtin = require('telescope.builtin')

  local find_files_in_root = function(opts)
    opts = opts or {}
    opts.cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
      -- if not git then active lsp client root
      -- will get the configured root directory of the first attached lsp. You will have problems if you are using multiple lsps
      opts.cwd = vim.lsp.get_active_clients()[1].config.root_dir
    end
    require 'telescope.builtin'.find_files(opts)
  end

  k.set('n', '<leader>t', find_files_in_root, {})
  k.set('n', '<leader>f', builtin.live_grep, {})
  k.set('n', '<leader>b', builtin.buffers, {})
end
