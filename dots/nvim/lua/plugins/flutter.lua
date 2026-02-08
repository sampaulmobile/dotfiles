-- Flutter/Dart development support
return {
  -- Flutter tools
  { "thosakwe/vim-flutter" },

  -- Flutter snippets
  { "RobertBrunhage/flutter-riverpod-snippets" },
  { "Neevash/awesome-flutter-snippets" },

  -- Dart LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dartls = {
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
            },
          },
        },
      },
    },
  },
}
