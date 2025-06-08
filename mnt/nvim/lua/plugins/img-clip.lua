return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      dir_path = function()
        -- WARN: CWDと同一の場合はうまく動かないが、mkdocsプロジェクトの場合はdocs配下になるので平気なはず
        return vim.fn.expand("%:h") .. "/attachments"
      end,
      insert_mode_after_paste = false,
      -- INFO: AVIFにコンバート. quality 35 は劣化が肉眼で判別困難なギリギリのレベル.
      extension = "avif",
      process_cmd = "convert - -quality 35 avif:-",
    },
    filetypes = {
      markdown = {
        -- https://minerva.mamansoft.net/vim-0004
        template = "![$FILE_NAME_NO_EXT](./$FILE_PATH)",
      },
    },
  },
  keys = {
    { "<space>p", "<cmd>PasteImage<cr>" },
  },
}
