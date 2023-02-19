return function()
  require("mason-lspconfig").setup({
    ensure_installed = {
      "bashls",
      "dockerls",
      "html",
      "jsonls",
      "sumneko_lua",
      "jedi_language_server", -- python
      "pyright", -- python
      "sqlls",
      "terraformls",
      "yamlls"
    }
  })

  local k = vim.keymap
  local lspconfig = require("lspconfig")

  local on_attach = function(client, bufnr)
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    k.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    k.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    k.set('n', 'K', vim.lsp.buf.hover, bufopts)
    -- k.set('n', 'lr', vim.lsp.buf.rename, bufopts)
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
end
