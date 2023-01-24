-- pcall(require, "impatient")

require("options")
require("mappings")

local g = vim.g
local o = vim.o
local k = vim.keymap

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
    config = function()
      require('nvim-treesitter.configs').setup({
        highlight = {
          enable = true,
          disable = {},
        },
        indent = {
          enable = true,
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
    end
  }

  -- A collection of language packs for Vim
  use 'sheerun/vim-polyglot'

  use "neovim/nvim-lspconfig"

  use {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  }

  use {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",
          "dockerls",
          "html",
          "jsonls",
          "sumneko_lua",
          "jedi_language_server", -- python
          "sqlls",
          "terraformls",
          "yamlls"
        }
      })
    end
  }

  use {
    "jose-elias-alvarez/null-ls.nvim",
    requires = "nvim-lua/plenary.nvim",
  }

  use {
    "jay-babu/mason-null-ls.nvim",
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {
          "jq",
          "selene",
          "black",
          "flake8",
          "isort",
          "mypy",
          "pylint",
          "sqlfluff",
          "yamllint"
        },
        automatic_installation = true,
        automatic_setup = false,
      })
    end
  }

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    requires = 'nvim-lua/plenary.nvim'
  }

  use 'hrsh7th/nvim-cmp' -- Autocomplete engine
  use 'hrsh7th/cmp-nvim-lsp' -- Completion source
  use 'hrsh7th/cmp-buffer' -- Completion source
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-path'

  use 'L3MON4D3/LuaSnip' -- Snippet engine
  use 'saadparwaiz1/cmp_luasnip' -- Completion source

  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
    config = function()
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
    end
  }

  -- Visually display indent levels in code
  use {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup {
        show_current_context = true,
        show_current_context_start = true,
        use_treesitter = true,
        max_indent_increase = 1,
      }
    end
  }

  -- Hotkey for adding comments to blocks of code
  use 'terrortylor/nvim-comment'

  -- Python folding
  use 'tmhedberg/SimpylFold'

  -- use {
  --   'nmac427/guess-indent.nvim',
  --   config = function()
  --     require('guess-indent').setup()
  --   end
  -- }

  -- Insert or delete brackets, parens, quotes in pair
  use {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end
  }

  -- Text filtering and alignment
  use 'godlygeek/tabular'

  -- Git(hub) wrapper - :gblame, :gbrowse, etc.
  use {
    'tpope/vim-fugitive',
    requires = {
      'tpope/vim-rhubarb',
    }
  }

  -- Visualize vim undo tree
  use 'mbbill/undotree'

  use {
    'nvim-lualine/lualine.nvim',
    -- *NOTE* - brew install --cask homebrew/cask-fonts/font-hack-nerd-font
    -- and select Hack Nerd Font Mono in iterm2 settings
    requires = {
      'kyazdani42/nvim-web-devicons', opt = true
    },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'nightfox',
        }
      })
    end
  }

  -- these are optional themes but I hear good things about gloombuddy ;)
  -- colorbuddy allows us to run the gloombuddy theme
  -- use 'tjdevries/colorbuddy.nvim'
  -- use 'bkegley/gloombuddy'
  -- use {'prettier/vim-prettier', run = 'yarn install'}

  use 'folke/tokyonight.nvim'
  use "EdenEast/nightfox.nvim"
  -- use {'lewis6991/impatient.nvim'}

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

-- Run PackerCompile after saving plugins.lua
vim.cmd([[
	augroup packer_user_config
	autocmd!
	autocmd BufWritePost init.lua source <afile> | PackerCompile
	augroup end
]])

-- o.foldenable = false
-- vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile', 'BufWinEnter' }, {
-- group = vim.api.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
-- callback = function()
-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr   = 'nvim_treesitter#foldexpr()'
-- end
-- })


local lspconfig = require("lspconfig")

local on_attach = function(client, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  k.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  k.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  k.set('n', 'K', vim.lsp.buf.hover, bufopts)
  k.set('n', 'lr', vim.lsp.buf.rename, bufopts)
  k.set('n', '<space>lf', function() vim.lsp.buf.format { async = true } end, bufopts)

  vim.keymap.set('n', '<c-]>', "<Cmd>lua vim.lsp.buf.definition()<CR>", bufopts)
  vim.keymap.set('n', 'K', "<Cmd>lua vim.lsp.buf.hover()<CR>", bufopts)
  vim.keymap.set('n', 'gh', "<Cmd>lua vim.lsp.buf.signature_help()<CR>", bufopts)
  vim.keymap.set('n', 'ga', "<Cmd>lua vim.lsp.buf.code_action()<CR>", bufopts)
  vim.keymap.set('n', 'gm', "<Cmd>lua vim.lsp.buf.implementation()<CR>", bufopts)
  vim.keymap.set('n', 'gl', "<Cmd>lua vim.lsp.buf.incoming_calls()<CR>", bufopts)
  vim.keymap.set('n', 'gd', "<Cmd>lua vim.lsp.buf.type_definition()<CR>", bufopts)
  vim.keymap.set('n', 'gr', "<Cmd>lua vim.lsp.buf.references()<CR>", bufopts)
  vim.keymap.set('n', 'gn', "<Cmd>lua vim.lsp.buf.rename()<CR>", bufopts)

  -- vim.keymap.set('n', 'gs', "<Cmd>lua vim.lsp.buf.document_symbol()<CR>", bufopts)
  vim.keymap.set('n', 'gs', "<Cmd>SymbolsOutline<CR>", bufopts)

  vim.keymap.set('n', 'gw', "<Cmd>lua vim.lsp.buf.workspace_symbol()<CR>", bufopts)
  vim.keymap.set('n', '[x', "<Cmd>lua vim.diagnostic.goto_prev()<CR>", bufopts)
  vim.keymap.set('n', ']x', "<Cmd>lua vim.diagnostic.goto_next()<CR>", bufopts)
  vim.keymap.set('n', ']r', "<Cmd>lua vim.diagnostic.open_float()<CR>", bufopts)
  vim.keymap.set('n', ']s', "<Cmd>lua vim.diagnostic.show()<CR>", bufopts)

  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      group = vim.api.nvim_create_augroup("SharedLspFormatting", { clear = true }),
      pattern = "*",
      command = "lua vim.lsp.buf.format()",
    })
  end
end

-- local servers = require 'lspinstall'.installed_servers()

require("mason-lspconfig").setup_handlers({
  function(server_name)
    -- local opts = vim.tbl_deep_extend("force", options, servers[server_name] or {})
    lspconfig[server_name].setup {
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' }
          }
        }
      }
    }
  end,
})


require('luasnip.loaders.from_vscode').lazy_load()

vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

local cmp = require('cmp')
local luasnip = require('luasnip')
local select_opts = { behavior = cmp.SelectBehavior.Select }

-- See :help cmp-config
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end
  },
  sources = {
    { name = 'path' },
    { name = 'nvim_lsp', keyword_length = 3 },
    { name = 'buffer', keyword_length = 3 },
    { name = 'luasnip', keyword_length = 2 },
  },
  window = {
    documentation = cmp.config.window.bordered()
  },
  formatting = {
    fields = { 'menu', 'abbr', 'kind' },
    format = function(entry, item)
      local menu_icon = {
        nvim_lsp = 'λ',
        luasnip = '⋗',
        buffer = 'Ω',
        path = '🖫',
      }

      item.menu = menu_icon[entry.source.name]
      return item
    end,
  },
  -- See :help cmp-mapping
  mapping = {
    ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
    ['<Down>'] = cmp.mapping.select_next_item(select_opts),

    ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
    ['<C-n>'] = cmp.mapping.select_next_item(select_opts),

    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),

    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),

    ['<C-d>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<C-b>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<Tab>'] = cmp.mapping(function(fallback)
      local col = vim.fn.col('.') - 1

      if cmp.visible() then
        cmp.select_next_item(select_opts)
      elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        fallback()
      else
        cmp.complete()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item(select_opts)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
})

local builtin = require('telescope.builtin')
-- k.set('n', '<leader>t', builtin.find_files, {})
k.set('n', '<leader>t', builtin.git_files, {})
k.set('n', '<leader>f', builtin.live_grep, {})
k.set('n', '<leader>b', builtin.buffers, {})

-- nvim-tree (File explorer)
k.set('', 'T', '<cmd>NvimTreeToggle<cr>')

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

-- Set some shortcuts for Tabularize
k.set({ 'n', 'v' }, '<leader>a=', '<cmd>Tabularize /=<cr>')
k.set({ 'n', 'v' }, '<leader>a:', '<cmd>Tabularize /:\zs<cr>')

-- Mappings for fugitive
k.set('', '<leader>gb', '<cmd>Git blame<cr>')
k.set('', '<leader>gh', '<cmd>GBrowse<cr>')

-- undotree mappings
k.set('', '<leader>u', '<cmd>UndotreeToggle<cr>')

require('nvim_comment').setup()
k.set('n', '<leader>/', '<cmd>CommentToggle<cr>')
-- k.set('v', '<leader>/', 'gc<cr>')

o.termguicolors = true
vim.cmd('colorscheme tokyonight')
-- night, day, dawn, dusk, nord, tera, carbon fox
-- vim.cmd('colorscheme nightfox')
