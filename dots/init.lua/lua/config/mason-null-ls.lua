return function()
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
