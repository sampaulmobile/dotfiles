-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd.packadd('packer.nvim')

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Git(hub) wrapper - :gblame, :gbrowse, etc.
  use {
          'tpope/vim-fugitive',
          requires = {
                  'tpope/vim-rhubarb',
          }
  }

  -- Hotkey for adding comments to blocks of code
  use {'terrortylor/nvim-comment'}

  use {
          'nvim-telescope/telescope.nvim',
          tag = '0.1.0',
          requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- use({
  --     "folke/trouble.nvim",
  --     config = function()
  --         require("trouble").setup {
  --             icons = false,
  --             -- your configuration comes here
  --             -- or leave it empty to use the default settings
  --             -- refer to the configuration section below
  --         }
  --     end
  -- })

  -- Visualize vim undo tree
  use("mbbill/undotree")

  use {
          'nvim-treesitter/nvim-treesitter',
          run = function()
                  local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
                  ts_update()
          end,
  }

  -- use("theprimeagen/harpoon")
  -- use("theprimeagen/refactoring.nvim")
  use("nvim-treesitter/nvim-treesitter-context");

  use {
          'VonHeikemen/lsp-zero.nvim',
          branch = 'v2.x',
          requires = {
                  -- LSP Support
                  {'neovim/nvim-lspconfig'},             -- Required
                  {                                      -- Optional
                  'williamboman/mason.nvim',
                  run = function()
                          pcall(vim.cmd, 'MasonUpdate')
                  end,
          },
          {'williamboman/mason-lspconfig.nvim'}, -- Optional

          -- Autocompletion
          {'hrsh7th/nvim-cmp'},     -- Required
          {'hrsh7th/cmp-nvim-lsp'}, -- Required
          {'L3MON4D3/LuaSnip'},     -- Required
  }
  }

  -- nvim-tree (File explorer)
  -- use {
  --   'nvim-tree/nvim-tree.lua',
  --   requires = {
  --     'nvim-tree/nvim-web-devicons', -- optional, for file icons
  --   },
  --   config = require("config.nvim-tree")
  -- }

  -- Visually display indent levels in code
  -- use {
  --   "lukas-reineke/indent-blankline.nvim",
  --   config = require("config.indent-blankline")
  -- }

  -- Python folding
  -- use 'tmhedberg/SimpylFold'

  -- use {
  --   'nvim-lualine/lualine.nvim',
  --   -- *NOTE* - brew install --cask homebrew/cask-fonts/font-hack-nerd-font
  --   -- and select Hack Nerd Font Mono in iterm2 settings
  --   requires = {
  --     'kyazdani42/nvim-web-devicons', opt = true
  --   },
  --   config = require("config.lualine")
  -- }

  -- toggleterm - persist and toggle multiple terminals during an editing session
  -- use {
  --   "akinsho/toggleterm.nvim",
  --   tag = '*',
  --   config = require("config.toggleterm"),
  -- }

  -- Plug 'thosakwe/vim-flutter'
  -- use {'dart-lang/dart-vim-plugin'}
  use {'natebosch/vim-lsc'}
  use {'natebosch/vim-lsc-dart'}


  -- Flutter
  -- use {
  --   "akinsho/flutter-tools.nvim",
  --   requires = { "nvim-lua/plenary.nvim" },
  --   config = function()
  --     require("config.flutter").setup()
  --   end,
  -- }

  use 'folke/tokyonight.nvim'
  use "EdenEast/nightfox.nvim"
  -- use 'tjdevries/colorbuddy.nvim'
  -- use 'bkegley/gloombuddy'
  -- use {'lewis6991/impatient.nvim'}

end)

-- PackerCompile after saving any packer-related lua files
-- local packerSyncGrp = vim.api.nvim_create_augroup("PackerSyncGrp", {})
-- vim.api.nvim_clear_autocmds({ group = packerSyncGrp })
-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--   group = packerSyncGrp,
--   pattern = { "**/lua/plugins.lua", "**/lua/config/*.lua" },
--   command = "source <afile> | PackerCompile",
-- })
