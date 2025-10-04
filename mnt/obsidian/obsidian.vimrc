" ╭──────────────────────────────────────────────────────────╮
" │                         基本設定                         │
" ╰──────────────────────────────────────────────────────────╯

" クリップボードとヤンクを共有
set clipboard=unnamed

" スペースは2key bindingで利用するため単体無効化
unmap <Space>

" <C->コマンドの修飾キーを置換 (ObsidianはKarabinerで入れ替えしていないので)
noremap <M-o> <C-o>
noremap <M-i> <C-i>
noremap <M-v> <C-v>
noremap <M-a> <C-a>
noremap <M-x> <C-x>

" ╭──────────────────────────────────────────────────────────╮
" │                      ワークスペース                      │
" ╰──────────────────────────────────────────────────────────╯

" 次のワークスペースへ移動
noremap gt :obcommand<Space>carnelian:carnelian_move-to-next-workspace<CR>

" ╭──────────────────────────────────────────────────────────╮
" │                           タブ                           │
" ╰──────────────────────────────────────────────────────────╯

" 移動
noremap <Space>h :obcommand<Space>workspace:previous-tab<CR>
noremap <Space>l :obcommand<Space>workspace:next-tab<CR>

" 復元
noremap <Space>t :obcommand<Space>workspace:undo-close-pane<CR>

" 閉じる
noremap <Space>q :obcommand<Space>workspace:close<CR>
noremap <Space>w :obcommand<Space>workspace:close-others-tab-group<CR>

" ╭──────────────────────────────────────────────────────────╮
" │                       タブグループ                       │
" ╰──────────────────────────────────────────────────────────╯

" 移動
noremap <M-w>h :obcommand<Space>editor:focus-left<CR>
noremap <M-w>j :obcommand<Space>editor:focus-bottom<CR>
noremap <M-w>k :obcommand<Space>editor:focus-top<CR>
noremap <M-w>l :obcommand<Space>editor:focus-right<CR>

" 分割
noremap <M-w>v :obcommand<Space>workspace:split-vertical<CR>
noremap <M-w>s :obcommand<Space>workspace:split-horizontal<CR>

" 閉じる
exmap q obcommand workspace:close-tab-group

" ╭──────────────────────────────────────────────────────────╮
" │                      プロパティ操作                      │
" ╰──────────────────────────────────────────────────────────╯

" change log更新
noremap <Space>u :obcommand<Space>carnelian:carnelian_update-change-log<CR>
" 最適プロパティ挿入
noremap <Space>k :obcommand<Space>carnelian:carnelian_add-property-suitably<CR>

" ╭──────────────────────────────────────────────────────────╮
" │                       エディタ操作                       │
" ╰──────────────────────────────────────────────────────────╯

" 先頭と末尾に移動
noremap <C-a> ^
noremap <C-e> $

" 折りたたみ/展開
noremap zc :obcommand<Space>editor:fold-more<CR>
noremap zo :obcommand<Space>editor:fold-less<CR>

" ╭──────────────────────────────────────────────────────────╮
" │                       エディタ編集                       │
" ╰──────────────────────────────────────────────────────────╯

" Undo/Redo
exmap undo jscommand { editor.undo(); editor.setCursor(editor.getCursor()) }
noremap u :undo<CR>
exmap redo jscommand { editor.redo(); editor.setCursor(editor.getCursor()) }
noremap <M-r> :redo<CR>

" 修正・変換
noremap <Space>f :obcommand<Space>carnelian:carnelian_fix-link<CR>
noremap <Space>m :obcommand<Space>carnelian:carnelian_update-moc-suitably<CR>
noremap <Space>o :obcommand<Space>carnelian:carnelian_transform-to-v2-ogp-card<CR>

" surround
noremap <Space>] :surround<Space>[[<Space>]]<CR>
noremap <Space>" :surround<Space>"<Space>"<CR>
noremap <Space>' :surround<Space>'<Space>'<CR>
" 装飾
noremap <Space>b :obcommand<Space>editor:toggle-bold<CR>
noremap <Space>@ :obcommand<Space>editor:toggle-code<CR>


" コピペ系
noremap gy :obcommand<Space>carnelian:carnelian_copy-active-file-full-path<CR>
noremap gp :obcommand<Space>carnelian:carnelian_paste-url-to-site-link<CR>
noremap gP :obcommand<Space>carnelian:carnelian_paste-site-card<CR>
noremap <Space>p :obcommand<Space>carnelian:carnelian_paste-clipboard-as-avif<CR>

" ╭──────────────────────────────────────────────────────────╮
" │                         外部連携                         │
" ╰──────────────────────────────────────────────────────────╯

noremap <Space>y :obcommand<Space>carnelian:carnelian_open-active-file-in-yazi<CR>
noremap <Space>, :obcommand<Space>carnelian:carnelian_open-vault-in-terminal<CR>
noremap <Space>g :obcommand<Space>carnelian:carnelian_open-vault-in-lazygit<CR>

