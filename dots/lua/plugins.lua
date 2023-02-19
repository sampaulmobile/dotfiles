local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    print('Installing packer...')
    fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      'https://github.com/wbthomason/packer.nvim',
      install_path
    })
    print('Done.')

    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use "nvim-lua/plenary.nvim"

  use {
    'nvim-treesitter/nvim-treesitter',
    requires = "RRethy/nvim-treesitter-endwise",
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
    config = require("config.nvim-treesitter")
  }

  -- A collection of language packs for Vim
  use 'sheerun/vim-polyglot'

  use "neovim/nvim-lspconfig"

  use {
    "williamboman/mason.nvim",
    config = require("config.mason")
  }

  use {
    "williamboman/mason-lspconfig.nvim",
    config = require("config.mason-lspconfig")
  }

  use {
    "jose-elias-alvarez/null-ls.nvim",
    requires = "nvim-lua/plenary.nvim",
  }

  use {
    "jay-babu/mason-null-ls.nvim",
    config = require("config.mason-null-ls")
  }

  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.1',
    requires = 'nvim-lua/plenary.nvim',
    config = require("config.telescope")
  }

  -- snippets
  use {
    'L3MON4D3/LuaSnip',
    config = require("config.luasnip"),
  }

  -- Completion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
      { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
    },
    config = require("config.nvim-cmp"),
    event = 'InsertEnter',
    wants = 'LuaSnip',
  }

  -- nvim-tree (File explorer)
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
    config = require("config.nvim-tree")
  }

  -- Visually display indent levels in code
  use {
    "lukas-reineke/indent-blankline.nvim",
    config = require("config.indent-blankline")
  }

  -- Hotkey for adding comments to blocks of code
  use {
    'terrortylor/nvim-comment',
    config = require("config.nvim-comment")
  }

  -- Python folding
  use 'tmhedberg/SimpylFold'

  -- use 'tpope/vim-sleuth'

  -- use {
  --   'nmac427/guess-indent.nvim',
  --   config = function()
  --     require('guess-indent').setup()
  --   end
  -- }

  -- Insert or delete brackets, parens, quotes in pair
  use {
    "windwp/nvim-autopairs",
    config = require("config.nvim-autopairs")
  }

  -- Text filtering and alignment
  use {
    'godlygeek/tabular',
    config = require("config.tabular")
  }

  -- Git(hub) wrapper - :gblame, :gbrowse, etc.
  use {
    'tpope/vim-fugitive',
    requires = {
      'tpope/vim-rhubarb',
    },
    config = require("config.fugitive")
  }

  -- Visualize vim undo tree
  use {
    'mbbill/undotree',
    config = require("config.undotree")
  }

  use {
    'nvim-lualine/lualine.nvim',
    -- *NOTE* - brew install --cask homebrew/cask-fonts/font-hack-nerd-font
    -- and select Hack Nerd Font Mono in iterm2 settings
    requires = {
      'kyazdani42/nvim-web-devicons', opt = true
    },
    config = require("config.lualine")
  }

  -- toggleterm - persist and toggle multiple terminals during an editing session
  use {
    "akinsho/toggleterm.nvim",
    tag = '*',
    config = require("config.toggleterm"),
  }

  use {
    "folke/trouble.nvim",
    requires = "nvim-tree/nvim-web-devicons",
    config = require("config.trouble"),
  }

  -- use {'lewis6991/impatient.nvim'}
  use 'folke/tokyonight.nvim'
  use "EdenEast/nightfox.nvim"
  -- use 'tjdevries/colorbuddy.nvim'
  -- use 'bkegley/gloombuddy'

  if packer_bootstrap then
    require('packer').sync()
  end
end)

if packer_bootstrap then
  print '=================================='
  print '    Plugins will be installed.'
  print '      After you press Enter'
  print '    Wait until Packer completes,'
  print '       then restart nvim'
  print '=================================='
  return
end

-- PackerCompile after saving any packer-related lua files
local packerSyncGrp = vim.api.nvim_create_augroup("PackerSyncGrp", {})
vim.api.nvim_clear_autocmds({ group = packerSyncGrp })
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = packerSyncGrp,
  pattern = { "**/lua/plugins.lua", "**/lua/config/*.lua" },
  command = "source <afile> | PackerCompile",
})
