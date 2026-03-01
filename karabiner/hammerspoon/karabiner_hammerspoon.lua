local previousState = _G.__karabiner_hammerspoon or _G.__karabiner_mode_indicator
if previousState and previousState.teardown then
	previousState.teardown()
end

local scriptSource = debug.getinfo(1, "S").source
local scriptDir = scriptSource:sub(1, 1) == "@" and scriptSource:match("^@(.+)/[^/]+$") or nil
if not scriptDir then
	error("failed to resolve script directory")
end

local modeIndicatorModule = dofile(scriptDir .. "/karabiner/mode_indicator.lua")

local function loadModeIcon(fileName)
	return hs.image.imageFromPath(scriptDir .. "/" .. fileName)
end

local iconImage = loadModeIcon("mode.png") or loadModeIcon("hacker-owl.png")

local modeIndicator = modeIndicatorModule.new({
	iconImage = iconImage,
})

hs.urlevent.bind("karabiner-mode", function(_, params)
	modeIndicator.setMode(params and params.mode)
end)

local function teardown()
	if modeIndicator and modeIndicator.teardown then
		modeIndicator.teardown()
	end
end

_G.__karabiner_hammerspoon = {
	teardown = teardown,
	setMode = modeIndicator.setMode,
}

_G.__karabiner_mode_indicator = _G.__karabiner_hammerspoon
