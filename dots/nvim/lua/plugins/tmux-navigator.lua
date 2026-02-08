-- Seamless navigation between tmux panes and vim splits with Ctrl+hjkl
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- Delete LazyVim's default Ctrl+hjkl mappings so vim-tmux-navigator can own them
      vim.keymap.del("n", "<C-h>")
      vim.keymap.del("n", "<C-j>")
      vim.keymap.del("n", "<C-k>")
      vim.keymap.del("n", "<C-l>")
    end,
  },
}
