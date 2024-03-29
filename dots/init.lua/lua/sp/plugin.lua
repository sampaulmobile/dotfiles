local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


local plugins = {
    -- LSP
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            {
                'williamboman/mason.nvim',
                build = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    },
    'jose-elias-alvarez/null-ls.nvim',

    -- File and folder management
    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-fzy-native.nvim",
    'nvim-telescope/telescope-ui-select.nvim',
    -- "ThePrimeagen/harpoon",

    {
        "mbbill/undotree",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },

    -- nvim-tree (File explorer)
    {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- optional, for file icons
        },
    },

    "thosakwe/vim-flutter",

    -- Snippets
    "RobertBrunhage/flutter-riverpod-snippets",
    "Neevash/awesome-flutter-snippets",

    -- Language support
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
    },
    -- {
    --   dir = "~/personal/projects/nvim-treesitter",
    --   build = ":TSUpdate",
    -- },
    "nvim-treesitter/nvim-treesitter-context",
    -- { dir = "~/personal/projects/nvim-treesitter-context" },

    -- Nice to haves
    "numToStr/Comment.nvim",
    -- "github/copilot.vim",
    -- "j-hui/fidget.nvim",

    -- Git
    {
        'tpope/vim-fugitive',
        dependencies = {
            'tpope/vim-rhubarb',
        }
    },
    -- "lewis6991/gitsigns.nvim",

    -- UI
    -- Visually display indent levels in code
    -- use {
    --   "lukas-reineke/indent-blankline.nvim",
    --   config = require("config.indent-blankline")
    -- }

    -- Python folding
    -- use 'tmhedberg/SimpylFold'

    -- "f-person/auto-dark-mode.nvim",
    -- {
    --   'rose-pine/neovim',
    --   name = 'rose-pine',
    -- }
    'folke/tokyonight.nvim',
    "EdenEast/nightfox.nvim"
}

require("lazy").setup(plugins, {})
