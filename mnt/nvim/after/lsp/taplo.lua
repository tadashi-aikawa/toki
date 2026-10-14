return {
  -- ルートが見つからないと単独ファイル扱いになり、taploが文書を対象外と判定して
  -- #:schema の補完・検証を返さない。見つからなければファイルのフォルダをルートにする
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(vim.fs.root(fname, { ".taplo.toml", "taplo.toml", ".git" }) or vim.fs.dirname(fname))
  end,
  on_attach = function(client, bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name:match("/yazi/keymap%.toml$") then
      client.server_capabilities.documentFormattingProvider = false
    end
  end,
}
