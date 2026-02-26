local previousState = _G.__karabiner_hammerspoon or _G.__karabiner_mode_indicator
if previousState and previousState.teardown then
	previousState.teardown()
end

if _G.__karabiner_mode_indicator_hints_patch then
	hs.hints.displayHintsForDict = _G.__karabiner_mode_indicator_hints_patch.originalDisplayHintsForDict
	_G.__karabiner_mode_indicator_hints_patch = nil
end

local scriptSource = debug.getinfo(1, "S").source
local scriptDir = scriptSource:sub(1, 1) == "@" and scriptSource:match("^@(.+)/[^/]+$") or nil
if not scriptDir then
	error("failed to resolve script directory")
end

local modeIndicatorModule = dofile(scriptDir .. "/karabiner/mode_indicator.lua")
local windowHintsModule = dofile(scriptDir .. "/karabiner/window_hints.lua")

local function loadModeIcon(fileName)
	return hs.image.imageFromPath(scriptDir .. "/" .. fileName)
end

local iconImage = loadModeIcon("mode.png") or loadModeIcon("hacker-owl.png")
local windowHintChars = {
	"A",
	"S",
	"D",
	"F",
	"G",
	"H",
	"J",
	"K",
	"L",
	"Q",
	"W",
	"E",
	"R",
	"T",
	"Y",
	"U",
	"I",
	"O",
	"P",
	"Z",
	"X",
	"C",
	"V",
	"B",
	"N",
	"M",
}

local modeIndicator = modeIndicatorModule.new({
	iconImage = iconImage,
})

local windowHints = windowHintsModule.new({
	hintChars = windowHintChars,
	hotkeyModifiers = { "alt" },
	hotkeyKey = "f20",
	iconSize = 72,
	titleMaxSize = 72,
	onSelect = function(win)
		if not win then
			return
		end
		local frame = win:frame()
		hs.mouse.absolutePosition({ x = frame.x + frame.w / 2, y = frame.y + frame.h / 2 })
	end,
	onError = function(err)
		local message = "Window Hints error: " .. tostring(err)
		hs.printf("[karabiner_hammerspoon] %s", message)
		hs.alert.show(message, 3)
	end,
})

local function showWindowHints()
	windowHints.show()
end

hs.urlevent.bind("karabiner-mode", function(_, params)
	modeIndicator.setMode(params and params.mode)
end)

local function teardown()
	if windowHints and windowHints.teardown then
		windowHints.teardown()
	end
	if modeIndicator and modeIndicator.teardown then
		modeIndicator.teardown()
	end
end

_G.__karabiner_hammerspoon = {
	teardown = teardown,
	setMode = modeIndicator.setMode,
	showWindowHints = showWindowHints,
}

_G.__karabiner_mode_indicator = _G.__karabiner_hammerspoon
