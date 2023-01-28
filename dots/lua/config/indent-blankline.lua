return function()
  require("indent_blankline").setup {
    show_current_context = true,
    show_current_context_start = true,
    use_treesitter = true,
    max_indent_increase = 1,
  }
end
