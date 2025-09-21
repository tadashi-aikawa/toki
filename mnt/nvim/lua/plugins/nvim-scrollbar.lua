return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy", -- nvim-hlslensの初期化にあわせる
  opts = {
    handle = {
      color = "gray",
      blend = 50,
    },
    handlers = {
      search = true,
    },
  },
}
