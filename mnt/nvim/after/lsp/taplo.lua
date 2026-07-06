return {
  on_attach = function(client, bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name:match("/yazi/keymap%.toml$") then
      client.server_capabilities.documentFormattingProvider = false
    end
  end,
}
