if _G.__karabiner_mode_indicator and _G.__karabiner_mode_indicator.teardown then
	_G.__karabiner_mode_indicator.teardown()
end

local currentMode = "DEFAULT"
local canvases = {}

local WIDGET = {
	size = 240,
	marginRight = 40,
	marginBottom = 36,
	iconSize = 240,
	wideThreshold = 2560,
}

local scriptSource = debug.getinfo(1, "S").source
local scriptDir = scriptSource:sub(1, 1) == "@" and scriptSource:match("^@(.+)/[^/]+$") or nil

local function loadModeIcon(fileName)
	return scriptDir and hs.image.imageFromPath(scriptDir .. "/" .. fileName) or nil
end

local iconImage = loadModeIcon("mode.png") or loadModeIcon("hacker-owl.png")
local modeColors = {
	NORMAL = { red = 0.40, green = 0.68, blue = 0.98, alpha = 0.78 },
	RANGE = { red = 0.42, green = 0.85, blue = 0.56, alpha = 0.78 },
	SPECIAL = { red = 0.99, green = 0.49, blue = 0.49, alpha = 0.78 },
}

local function normalizeMode(mode)
	local m = string.upper(tostring(mode or "DEFAULT"))
	if m ~= "NORMAL" and m ~= "RANGE" and m ~= "SPECIAL" then
		return "DEFAULT"
	end
	return m
end

local function frameFor(screen)
	local f = screen:fullFrame()
	return {
		x = f.x + f.w - WIDGET.size - WIDGET.marginRight,
		y = f.y + f.h - WIDGET.size - WIDGET.marginBottom,
		w = WIDGET.size,
		h = WIDGET.size,
	}
end

local function wideAuxFrameFor(screen)
	local f = screen:fullFrame()
	return {
		x = f.x + WIDGET.marginRight,
		y = f.y + f.h - WIDGET.size - WIDGET.marginBottom,
		w = WIDGET.size,
		h = WIDGET.size,
	}
end

local function newCanvas(frame)
	local canvas = hs.canvas
		.new(frame)
		:level(hs.canvas.windowLevels.overlay)
		:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })
	local iconFrame = {
		x = (WIDGET.size - WIDGET.iconSize) / 2,
		y = (WIDGET.size - WIDGET.iconSize) / 2,
		w = WIDGET.iconSize,
		h = WIDGET.iconSize,
	}

	canvas[1] = {
		type = iconImage and "image" or "rectangle",
		action = iconImage and nil or "fill",
		image = iconImage,
		imageScaling = iconImage and "scaleToFit" or nil,
		fillColor = iconImage and nil or { red = 0, green = 0, blue = 0, alpha = 0 },
		frame = iconImage and iconFrame or { x = 0, y = 0, w = 0, h = 0 },
	}

	canvas[2] = {
		type = "rectangle",
		action = "fill",
		fillColor = modeColors.NORMAL,
		compositeRule = iconImage and "sourceIn" or "sourceOver",
		frame = iconImage and iconFrame or { x = 0, y = 0, w = 0, h = 0 },
	}

	return canvas
end

local function applyMode(canvas)
	if currentMode == "DEFAULT" then
		canvas:hide()
		return
	end

	local color = modeColors[currentMode] or modeColors.NORMAL
	if iconImage then
		canvas[1].type = "image"
		canvas[1].action = nil
		canvas[1].image = iconImage
		canvas[1].imageScaling = "scaleToFit"
		canvas[1].frame = {
			x = (WIDGET.size - WIDGET.iconSize) / 2,
			y = (WIDGET.size - WIDGET.iconSize) / 2,
			w = WIDGET.iconSize,
			h = WIDGET.iconSize,
		}
		canvas[2].type = "rectangle"
		canvas[2].action = "fill"
		canvas[2].fillColor = color
		canvas[2].compositeRule = "sourceIn"
		canvas[2].frame = {
			x = (WIDGET.size - WIDGET.iconSize) / 2,
			y = (WIDGET.size - WIDGET.iconSize) / 2,
			w = WIDGET.iconSize,
			h = WIDGET.iconSize,
		}
	else
		canvas[1].type = "rectangle"
		canvas[1].action = "fill"
		canvas[1].fillColor = { red = 0, green = 0, blue = 0, alpha = 0 }
		canvas[1].frame = { x = 0, y = 0, w = 0, h = 0 }
		canvas[2].type = "rectangle"
		canvas[2].action = "fill"
		canvas[2].fillColor = { red = 0, green = 0, blue = 0, alpha = 0 }
		canvas[2].compositeRule = "sourceOver"
		canvas[2].frame = { x = 0, y = 0, w = 0, h = 0 }
	end
	canvas:show()
end

local function applyModeAll(targetCanvases)
	for _, canvas in ipairs(targetCanvases) do
		applyMode(canvas)
	end
end

local function resetCanvases()
	for _, canvasList in pairs(canvases) do
		for _, canvas in ipairs(canvasList) do
			canvas:delete()
		end
	end

	canvases = {}
	for _, screen in ipairs(hs.screen.allScreens()) do
		local key = tostring(screen:getUUID() or screen:id() or screen:name())
		local canvasList = {}
		local screenFrame = screen:fullFrame()

		table.insert(canvasList, newCanvas(frameFor(screen)))
		if screenFrame.w >= WIDGET.wideThreshold then
			table.insert(canvasList, newCanvas(wideAuxFrameFor(screen)))
		end

		canvases[key] = canvasList
		applyModeAll(canvasList)
	end
end

local function setMode(mode)
	currentMode = normalizeMode(mode)
	for _, canvasList in pairs(canvases) do
		applyModeAll(canvasList)
	end
end

local function teardown()
	if _G.__karabiner_mode_indicator and _G.__karabiner_mode_indicator.screenWatcher then
		_G.__karabiner_mode_indicator.screenWatcher:stop()
	end

	for _, canvasList in pairs(canvases) do
		for _, canvas in ipairs(canvasList) do
			canvas:delete()
		end
	end

	canvases = {}
end

local screenWatcher = hs.screen.watcher.new(function()
	resetCanvases()
end)
screenWatcher:start()

hs.urlevent.bind("karabiner-mode", function(_, params)
	setMode(params and params.mode)
end)

resetCanvases()
setMode(currentMode)

_G.__karabiner_mode_indicator = {
	teardown = teardown,
	setMode = setMode,
	screenWatcher = screenWatcher,
}
