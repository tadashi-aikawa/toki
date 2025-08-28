require("git"):setup()
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

-- `plugins/bunny-private.yazi/main.lua` に設定する
--
-- ```lua
-- local function setup()
-- 	require("bunny"):setup({
-- 		hops = {
-- 			{ key = "/", path = "/" },
-- 			{ key = "d", path = "~/Downloads", desc = "Downloads" },
-- 		},
-- 	})
-- end
--
-- return { setup = setup }
-- ```
--
require("bunny-private"):setup()
