return function()
  require('lualine').setup({
    options = {
      theme = 'nightfox',
    },
    sections = {
      lualine_a = { '' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { 'filename' },
      lualine_x = { '', '', 'filetype' },
      lualine_y = { '' },
      lualine_z = { 'location' }
    },
  })
end
