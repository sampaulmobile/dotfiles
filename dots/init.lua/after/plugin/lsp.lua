local lsp_zero = require('lsp-zero');
local lsp_config = require("lspconfig");
local null_ls = require('null-ls')

lsp_zero.preset('minimal')

lsp_zero.ensure_installed({
    'tsserver',
    'eslint',
    'lua_ls',
})

-- Fix Undefined global 'vim'
lsp_zero.configure('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})

local on_attach = function(_, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>e", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "<leader>a", function() vim.lsp.buf.code_action() end, opts)
    -- vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>gr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("n", "<leader>dl", function() vim.diagnostic.setqflist() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end

lsp_zero.on_attach(on_attach)

vim.diagnostic.config({
    virtual_text = true,
    signs = false,
})

lsp_config["dartls"].setup({
    on_attach = on_attach,
    root_dir = lsp_config.util.root_pattern('.git'),
    settings = {
        dart = {
            analysisExcludedFolders = {
                vim.fn.expand("$HOME/AppData/Local/Pub/Cache"),
                vim.fn.expand("$HOME/.pub-cache"),
                vim.fn.expand("/opt/homebrew/"),
                vim.fn.expand("$HOME/tools/flutter/"),
            },
            updateImportsOnRename = true,
            completeFunctionCalls = true,
            showTodos = true,
        }
    },
})

local flake_ignores = {
    "E203", -- whitespace before :
    "W503", -- line break before binary operator
    "E501", -- line too long
    "C901"  -- mccabe complexity
}

lsp_config["pylsp"].setup({
    on_attach = on_attach,
    settings = {
        pylsp = {
            configurationSources = "black",
            plugins = {
                pycodestyle = { enabled = false },
                mccabe = { enabled = false },
                pyflakes = { enabled = false },
                flake8 = { enabled = false },
                -- flake8 = {
                --     enabled = true,
                --     ignore = table.concat(flake_ignores, ",")
                -- },
                pyls_black = { enabled = true },
                isort = { enabled = true, profile = "black" },
                -- ruff = {
                --     enabled = true,
                --     extendSelect = { "I" },
                -- },
            },
        },
    },
})


lsp_zero.format_on_save({
    format_opts = {
        async = false,
        timeout_ms = 10000,
    },
    servers = {
        ['lua_ls'] = { 'lua' },
        ['rust_analyzer'] = { 'rust' },
        -- ['pylsp'] = { 'python' },
        -- if you have a working setup with null-ls
        -- you can specify filetypes it can format.
        -- ['null-ls'] = {'javascript', 'typescript'},
    }
})

lsp_zero.setup()

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

local cmp_mappings = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-y>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),

});

-- disable completion with tab
-- this helps with copilot setup
-- cmp_mappings['<Tab>'] = vim.NIL
-- cmp_mappings['<S-Tab>'] = vim.NIL

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'luasnip' },
        { name = 'buffer',  keyword_length = 5 },
    },
    mapping = cmp_mappings,
})

null_ls.setup({
    on_attach = on_attach,
    sources = {
        null_ls.builtins.formatting.prettier,
        -- null_ls.builtins.diagnostics.eslint,
    }
})

-- require("fidget").setup({})
