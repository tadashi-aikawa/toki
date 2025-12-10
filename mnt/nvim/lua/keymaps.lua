-- ╭─────────────────────────────────────────────────────────╮
-- │                      キーバインド                       │
-- ╰─────────────────────────────────────────────────────────╯
-- プラグインのキーバインドはプラグインの方で行う

vim.g.maplocalleader = ","

-- Mac対応
vim.keymap.set({ "n", "v", "i", "c", "t", "o" }, "<D-left>", "<Home>", { silent = true })
vim.keymap.set({ "n", "v", "i", "c", "t", "o" }, "<D-right>", "<End>", { silent = true })

-- ウィンドウのクローズ
vim.keymap.set("n", "<Space>m", ":q<CR>", { silent = true })
vim.keymap.set("n", "<Space>n", ":q!<CR>", { silent = true })
vim.keymap.set("n", "<Space><Space>m", ":qa<CR>", { silent = true })
vim.keymap.set("n", "<Space><Space>n", ":qa!<CR>", { silent = true })
-- タブのクローズ
vim.keymap.set("n", "<Space><Space>q", ":tabclose<CR>", { silent = true })

-- Hippie completion
vim.keymap.set("i", "<F18>", "<C-x><C-p>") -- Ubuntu(WSL)ではS-F6がF18となるため

-- cnext / cprevious
vim.keymap.set("n", "<Space>J", ":cnext<CR>", { silent = true })
vim.keymap.set("n", "<Space>K", ":cprevious<CR>", { silent = true })
-- diff next / diff previous
vim.keymap.set("n", "<D-j>", "]c", { silent = true })
vim.keymap.set("n", "<D-k>", "[c", { silent = true })
-- quickfix list open
vim.keymap.set("n", "<Space>L", ":botright cw<CR>", { silent = true })
-- URLをブラウザで開く
vim.keymap.set("n", "go", ":ObsidianFollowLink<CR>", { silent = true })

-- バッファ切り替え
vim.keymap.set("n", "<Space>r", ":b#<CR>", { silent = true })
vim.keymap.set("n", "<Space>e", ":BufferPick<CR>", { silent = true })
vim.keymap.set("n", "<Space>l", ":BufferNext<CR>", { silent = true })
vim.keymap.set("n", "<Space>h", ":BufferPrevious<CR>", { silent = true })
vim.keymap.set("n", "<Space>w", ":BufferCloseAllButVisible<CR>", { silent = true })

-- tab split
vim.keymap.set("n", "<C-w>t", ":tab split<CR>", { silent = true })
-- 行補完
vim.keymap.set("i", "<C-l>", "<C-x><C-l>", { silent = true })

-- lazy.nvim
vim.keymap.set("n", "glp", ":Lazy profile<CR>", { silent = true })
vim.keymap.set("n", "gls", ":Lazy sync<CR>", { silent = true })

-- markdown装飾
vim.keymap.set("n", "<Space>b", function()
  vim.cmd("normal ysiW*.")
end, { silent = true })
vim.keymap.set("n", "<Space>@", function()
  vim.cmd("normal ysiW`")
end, { silent = true })

-- Marpの強調タスクを取り消しに変更
vim.keymap.set("n", "<Space>-", ":s/*/\\~/g<CR>", { silent = true })
-- ghostwriter.nvimのタスク状態を初期化
vim.keymap.set("n", "<Space>_", ":s/\\v- \\[.\\] (.+) `.+`/- [ ] \\1/<CR><Cmd>nohlsearch<CR>", { silent = true })

-- カレントウィンドウのファイル相対パスをコピー
vim.keymap.set("n", "<Space>cy", function()
  local relative_path = vim.fn.expand("%:~:.")
  vim.fn.setreg("+", relative_path)
  vim.notify("Copy: " .. relative_path)
end, { silent = true })
-- カレントウィンドウのファイル名をコピー
vim.keymap.set("n", "<Space>cf", function()
  local filename = vim.fn.expand("%:t")
  vim.fn.setreg("+", filename)
  vim.notify("Copy: " .. filename)
end, { silent = true })

-- カレントバッファのNFD形式をNFC形式に強制変換する
vim.keymap.set("n", "<Space>!", function()
  vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    vim.fn.systemlist("iconv -f UTF-8-MAC -t UTF-8", vim.api.nvim_buf_get_lines(0, 0, -1, false))
  )
end, { silent = true })

-- クリップボードの内容と比較
vim.keymap.set("n", "<C-w>d", function()
  vim.cmd([[
    let ft=&ft
    leftabove vnew [Clipboard]
    setlocal bufhidden=wipe buftype=nofile noswapfile
    put +
    0d_
    " remove CR for Windows
    silent %s/\r$//e
    execute "set ft=" . ft
    diffthis
    wincmd p
    diffthis
  ]])
end, { desc = "Compare to clipboard" })

-- Markdownファイルだけに発生するプラグイン間連携の特殊処理
vim.api.nvim_create_autocmd("FileType", {
  desc = "markdown-toggle.nvim keymaps",
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args)
    local opts = { silent = true, noremap = true, buffer = args.buf }
    local toggle = require("markdown-toggle")

    vim.keymap.set({ "n", "v" }, "<C-CR>", function()
      toggle.checkbox()
      local cline = vim.api.nvim_get_current_line()
      if string.find(cline, "- %[x%] .+ ``") then
        vim.cmd("SilhouettePushTimer")
      end
    end, opts)
    vim.keymap.set({ "i" }, "<C-CR>", function()
      vim.api.nvim_command("stopinsert")
      vim.schedule(function()
        toggle.checkbox()
      end)
      vim.schedule(function()
        vim.api.nvim_command("startinsert")
      end)
    end, opts)
  end,
})

-- ╭─────────────────────────────────────────────────────────╮
-- │                         VSCode                          │
-- ╰─────────────────────────────────────────────────────────╯
if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "<Space>,", function()
    vscode.action("workbench.action.terminal.toggleTerminal")
  end)

  vim.keymap.set("n", "gru", function()
    vscode.action("workbench.action.findInFiles")
  end)

  vim.keymap.set({ "n", "i" }, "<S-D-r>", function()
    vscode.action("editor.action.rename")
  end)

  vim.keymap.set("n", "<space>j", function()
    vscode.action("workbench.action.editor.nextChange")
  end)
  vim.keymap.set("n", "<space>k", function()
    vscode.action("workbench.action.editor.previousChange")
  end)

  vim.keymap.set("n", "<space>g", function()
    vscode.action("lazygit-vscode.toggle")
  end)

  vim.keymap.set("n", "<space>y", function()
    vscode.action("yazi-vscode.toggle")
  end)

  vim.keymap.set("n", "<space>u", function()
    vscode.action("git.revertSelectedRanges")
  end)
  vim.keymap.set("n", "<space>+", function()
    vscode.action("git.stageSelectedRanges")
  end)

  -- VSCodeのsettings.jsonにも設定が必要 (Neovim以外のタブの切り替え)
  vim.keymap.set("n", "<Space>l", function()
    vscode.action("workbench.action.nextEditorInGroup")
  end)
  vim.keymap.set("n", "<Space>h", function()
    vscode.action("workbench.action.previousEditorInGroup")
  end)
  vim.keymap.set("n", "<Space>q", function()
    vscode.action("workbench.action.closeActiveEditor")
  end)
  vim.keymap.set("n", "<space>w", function()
    vscode.action("workbench.action.closeOtherEditors")
  end)
  vim.keymap.set("n", "<space>t", function()
    vscode.action("workbench.action.reopenClosedEditor")
  end)
  vim.keymap.set("n", "<space>r", function()
    vscode.action("workbench.action.navigateLast")
  end)
  vim.keymap.set("n", "<space>e", function()
    vscode.action("workbench.action.showAllEditors")
  end)

  -- split系はVSCodeで動かないため別途設定が必要
  vim.keymap.set("n", "<C-S-]>", function()
    vscode.call("workbench.action.splitEditorRight")
    vscode.action("editor.action.revealDefinition")
  end)
  vim.keymap.set("n", "g<C-]>", function()
    vscode.call("workbench.action.splitEditorDown")
    vscode.action("editor.action.revealDefinition")
  end)

  -- folding
  vim.keymap.set("n", "zc", function()
    vscode.action("editor.fold")
  end)
  vim.keymap.set("n", "zo", function()
    vscode.action("editor.unfold")
  end)

  -- Oil.code
  vim.keymap.set("n", "<space>o", function()
    vscode.action("oil-code.open")
  end)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function(event)
      local opts = { buffer = event.buf, noremap = true, silent = true }
      vim.keymap.set("n", "<CR>", function()
        vscode.action("oil-code.select")
      end, opts)
      vim.keymap.set("n", "<C-CR>", function()
        vscode.action("oil-code.selectVertical")
      end, opts)
      -- 水平方向に展開するコマンドはないので複数コマンドを同期で連続させる
      vim.keymap.set("n", "<C-s>", function()
        vscode.call("workbench.action.splitEditorDown")
        vscode.call("oil-code.selectTab")
        vscode.call("workbench.action.previousEditorInGroup")
        vscode.call("workbench.action.closeActiveEditor")
      end, opts)

      vim.keymap.set("n", "-", function()
        vscode.action("oil-code.openParent")
      end, opts)
      vim.keymap.set("n", "_", function()
        vscode.action("oil-code.openCwd")
      end, opts)
      vim.keymap.set("n", "<C-l>", function()
        vscode.action("oil-code.refresh")
      end, opts)
    end,
  })
end
