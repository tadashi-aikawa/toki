local vue_language_server_path = os.getenv("HOME")
  .. "/.local/share/mise/installs/npm-vue-language-server/latest/lib/node_modules/@vue/language-server"
local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

return {
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local root_markers = { "package.json", "tsconfig.json", "jsconfig.json" }
    local project_root = vim.fs.root(bufnr, root_markers)
    on_dir(project_root)
  end,
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    },
  },
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
}
