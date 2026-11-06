-- Servers are installed + enabled by mason-lspconfig (automatic_enable); only overrides live here.
vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } },
})

-- Vue 3 hybrid mode: vue_ls handles template/style, vtsls (+ Vue TS plugin) handles script
vim.lsp.config("vtsls", {
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  },
})

local schemastore = require("schemastore")
vim.lsp.config("jsonls", {
  settings = { json = { schemas = schemastore.json.schemas(), validate = { enable = true } } },
})
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- use SchemaStore.nvim instead
      schemas = schemastore.yaml.schemas(),
    },
  },
})

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded" },
})
