-- Reload Config
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)
hs.alert.show("Config loaded")

-- Overlay Activator
hs.loadSpoon("OverlayActivator")
spoon.OverlayActivator:start({
	-- Raycastの起動キーを列挙する
	["com.raycast.macos"] = {
		{ { "alt", "fn" }, "f13" },
		{ { "cmd", "fn" }, "f14" },
		{ { "cmd", "fn" }, "f15" },
	},
})
