local builtin = require('telescope.builtin')

-- vim.keymap.set('n', '<leader>p', builtin.find_files, {})
vim.keymap.set('n', '<leader>t', builtin.git_files, {})
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>f', builtin.live_grep, {})
vim.keymap.set('n', '<C-p>', builtin.find_files, {})

-- vim.keymap.set('n', '<leader>ps', function()
-- 	builtin.grep_string({ search = vim.fn.input("Grep > ") })
-- end)
-- vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})

require("telescope").setup({
  defaults = require("telescope.themes").get_dropdown({
    file_sorter = require("telescope.sorters").get_fzy_sorter,
    file_previewer = require("telescope.previewers").vim_buffer_cat.new,
    grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
    qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
    mappings = {
      i = {
        ["<C-x>"] = false,
      },
    },
  }),
  extensions = {
    fzy_native = {
      override_generic_sorter = false,
      override_file_sorter = true,
    },
    ["ui-select"] = {
      specific_opts = {
        codeactions = false,
      }
    },
  },
})

-- local find_files_in_root = function(opts)
--   opts = opts or {}
--   opts.cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
--   if vim.v.shell_error ~= 0 then
--     -- if not git then active lsp client root
--     -- will get the configured root directory of the first attached lsp. You will have problems if you are using multiple lsps
--     opts.cwd = vim.lsp.get_active_clients()[1].config.root_dir
--   end
--   require 'telescope.builtin'.find_files(opts)
-- end

require("telescope").load_extension("fzy_native")
require("telescope").load_extension("ui-select")
