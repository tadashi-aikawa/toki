local util = require("lspconfig.util")

return {
  root_dir = function(bufnr, on_dir)
    if vim.fs.root(bufnr, { ".oxlintrc.json", "oxlint.config.ts" }) then
      return
    end

    local root_markers = {
      "package-lock.json",
      "yarn.lock",
      "pnpm-lock.yaml",
      "bun.lockb",
      "bun.lock",
      "deno.lock",
    }
    root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
      or vim.list_extend(root_markers, { ".git" })

    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

    local filename = vim.api.nvim_buf_get_name(bufnr)
    local biome_config_files = { "biome.json", "biome.jsonc" }
    biome_config_files = util.insert_package_json(biome_config_files, "biomejs", filename)
    local is_buffer_using_biome = vim.fs.find(biome_config_files, {
      path = filename,
      type = "file",
      limit = 1,
      upward = true,
      stop = vim.fs.dirname(project_root),
    })[1]
    if not is_buffer_using_biome then
      return
    end

    on_dir(project_root)
  end,
}
