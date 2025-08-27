require("git"):setup()
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})
require("bunny"):setup({
	hops = {
		{ key = "/", path = "/" },
		{ key = "t", path = "/tmp" },
		{ key = "d", path = "~/Downloads", desc = "Downloads" },
		{ key = "D", path = "~/Documents", desc = "Documents" },
		{ key = "c", path = "~/.config", desc = "Config files" },
		{ key = "i", path = "~/Library/Mobile Documents/com~apple~CloudDocs/image", desc = "iCloud/image" },
	},
})
