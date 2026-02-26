local M = {}

local DEFAULT_HINT_CHARS = {
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

local DEFAULT_CONFIG = {
	hotkeyModifiers = { "alt" },
	hotkeyKey = "f20",
	iconSize = 72,
	keyBoxSize = 72,
	keyBoxMinWidth = 72,
	keyBoxHorizontalPadding = 10,
	keyGap = 0,
	padding = 12,
	fontName = nil,
	fontSize = 48,
	titleFontSize = 16,
	rowGap = 8,
	titleMaxSize = 72,
	showTitles = true,
	bgColor = { red = 0, green = 0, blue = 0, alpha = 0.72 },
	dimmedBgAlpha = 0.22,
	textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
	dimmedTextColor = { red = 1, green = 1, blue = 1, alpha = 0.35 },
	titleTextColor = { red = 0.84, green = 0.84, blue = 0.86, alpha = 1 },
	dimmedTitleTextColor = { red = 0.84, green = 0.84, blue = 0.86, alpha = 0.35 },
	keyHighlightColor = { red = 0.84, green = 0.84, blue = 0.86, alpha = 0.35 },
	iconAlpha = 0.95,
	dimmedIconAlpha = 0.48,
	bumpThreshold = 120,
	bumpMove = 90,
	onSelect = nil,
}

local function mergeTable(defaults, overrides)
	local merged = {}
	for k, v in pairs(defaults) do
		merged[k] = v
	end
	if overrides then
		for k, v in pairs(overrides) do
			merged[k] = v
		end
	end
	return merged
end

local function cloneColor(color)
	return {
		red = color.red,
		green = color.green,
		blue = color.blue,
		alpha = color.alpha,
	}
end

local function startsWith(s, prefix)
	return string.sub(s, 1, #prefix) == prefix
end

local function utf8Truncate(text, maxSize)
	if maxSize == nil or maxSize < 6 then
		return text
	end
	local len = utf8.len(text)
	if not len or len <= maxSize then
		return text
	end
	local endIdx = utf8.offset(text, math.max(1, maxSize - 3))
	if not endIdx then
		return text
	end
	return string.sub(text, 1, endIdx - 1) .. "..."
end

local function keySuffixFor(index, hintChars)
	local base = #hintChars
	local n = index
	local code = ""
	repeat
		local rem = n % base
		code = hintChars[rem + 1] .. code
		n = math.floor(n / base) - 1
	until n < 0
	return code
end

local function appPrefixChar(appTitle, fallback, allowedPrefixes)
	local c = string.upper(string.sub(appTitle or "", 1, 1))
	if c == "" or not allowedPrefixes[c] then
		return fallback
	end
	return c
end

local function clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

local function estimatedTextWidth(text, fontSize, minimum)
	local len = utf8.len(text) or string.len(text)
	return math.max(minimum or 40, math.floor((len + 1) * fontSize * 0.55))
end

local function estimatedKeyTextWidth(text, fontSize)
	local width = 0
	for i = 1, #text do
		local ch = string.sub(text, i, i)
		if ch == " " then
			width = width + (fontSize * 0.30)
		else
			width = width + (fontSize * 0.62)
		end
	end
	return math.floor(width)
end

local function rawPrefixLenToDisplayLen(prefixLen)
	if prefixLen <= 0 then
		return 0
	end
	return prefixLen * 2 - 1
end

local function keyToDisplayText(key)
	if #key <= 1 then
		return key
	end
	local parts = {}
	for i = 1, #key do
		table.insert(parts, string.sub(key, i, i))
	end
	return table.concat(parts, " ")
end

function M.new(options)
	options = options or {}
	local config = mergeTable(DEFAULT_CONFIG, options)
	local hintChars = options.hintChars or DEFAULT_HINT_CHARS

	local hotkey = nil
	local modal = nil
	local openHints = {}
	local hintByKey = {}
	local currentInput = ""
	local isShowing = false
	local allowedPrefixes = {}
	for _, char in ipairs(hintChars) do
		allowedPrefixes[char] = true
	end

	local function clearHints()
		for _, hint in ipairs(openHints) do
			if hint.canvas then
				hint.canvas:delete()
			end
		end
		openHints = {}
		hintByKey = {}
		currentInput = ""
	end

	local function setHintActive(hint, active)
		local bg = cloneColor(config.bgColor)
		if not active then
			bg.alpha = config.dimmedBgAlpha
		end
		local prefixLen = 0
		if active and currentInput ~= "" and startsWith(hint.key, currentInput) then
			prefixLen = math.min(#currentInput, #hint.keyText)
		end
		local displayPrefixLen = rawPrefixLenToDisplayLen(prefixLen)
		local prefixText = displayPrefixLen > 0 and string.sub(hint.displayKeyText, 1, displayPrefixLen) or ""
		local restText = string.sub(hint.displayKeyText, displayPrefixLen + 1)
		local totalTextWidth = estimatedKeyTextWidth(hint.displayKeyText, config.fontSize) + 8
		local prefixTextWidth = estimatedKeyTextWidth(prefixText, config.fontSize) + 2
		prefixTextWidth = math.max(0, math.min(totalTextWidth, prefixTextWidth))
		local textLeft = hint.keyBoxFrame.x + (hint.keyBoxFrame.w - totalTextWidth) / 2
		local textTop = hint.keyBoxFrame.y + (hint.keyBoxFrame.h - hint.keyTextHeight) / 2

		hint.canvas[1].fillColor = bg
		hint.canvas[2].imageAlpha = active and config.iconAlpha or config.dimmedIconAlpha
		hint.canvas[3].text = prefixText
		hint.canvas[3].frame = {
			x = textLeft,
			y = textTop,
			w = prefixTextWidth,
			h = hint.keyTextHeight,
		}
		hint.canvas[4].text = restText
		hint.canvas[4].frame = {
			x = textLeft + prefixTextWidth,
			y = textTop,
			w = math.max(0, totalTextWidth - prefixTextWidth),
			h = hint.keyTextHeight,
		}
		hint.canvas[3].textColor = active and config.keyHighlightColor or config.dimmedTextColor
		hint.canvas[4].textColor = active and config.textColor or config.dimmedTextColor
		hint.canvas[5].textColor = active and config.titleTextColor or config.dimmedTitleTextColor
	end

	local function keyBoxWidthForText(displayKeyText)
		local textWidth = estimatedKeyTextWidth(displayKeyText, config.fontSize)
		local minWidth = config.keyBoxMinWidth or config.keyBoxSize
		return math.max(minWidth, textWidth + (config.keyBoxHorizontalPadding * 2))
	end

	local function hasPrefixMatch(prefix)
		for key, _ in pairs(hintByKey) do
			if startsWith(key, prefix) then
				return true
			end
		end
		return false
	end

	local function refreshHighlights()
		for _, hint in ipairs(openHints) do
			local active = currentInput == "" or startsWith(hint.key, currentInput)
			setHintActive(hint, active)
		end
	end

	local function closeHints(exitModal)
		if isShowing and exitModal and modal then
			modal:exit()
		end
		isShowing = false
		clearHints()
	end

	local function selectWindow(win)
		if not win then
			return
		end
		win:focus()
		if config.onSelect then
			config.onSelect(win)
		end
		closeHints(true)
	end

	local function handleChar(char)
		if not isShowing then
			return
		end

		currentInput = currentInput .. char
		local exact = hintByKey[currentInput]
		if exact then
			selectWindow(exact.win)
			return
		end

		if hasPrefixMatch(currentInput) then
			refreshHighlights()
			return
		end

		currentInput = char
		if hasPrefixMatch(currentInput) then
			refreshHighlights()
			return
		end

		currentInput = ""
		refreshHighlights()
	end

	local function handleBackspace()
		if not isShowing then
			return
		end
		if #currentInput == 0 then
			return
		end
		currentInput = string.sub(currentInput, 1, #currentInput - 1)
		refreshHighlights()
	end

	local function ensureModal()
		if modal then
			return
		end
		modal = hs.hotkey.modal.new(nil, nil)
		modal:bind({}, "escape", function()
			closeHints(true)
		end)
		modal:bind({}, "delete", function()
			handleBackspace()
		end)
		modal:bind({}, "forwarddelete", function()
			handleBackspace()
		end)
		for _, char in ipairs(hintChars) do
			local lower = string.lower(char)
			modal:bind({}, lower, function()
				handleChar(char)
			end)
			modal:bind({ "shift" }, lower, function()
				handleChar(char)
			end)
		end
	end

	local function collectEntries()
		local entries = {}
		for _, win in ipairs(hs.window.visibleWindows()) do
			local app = win:application()
			local screen = win:screen()
			if app and app:bundleID() and screen and win:isStandard() then
				local appTitle = app:title() or ""
				table.insert(entries, {
					win = win,
					app = app,
					appTitle = appTitle,
					title = win:title() or "",
					prefix = appPrefixChar(appTitle, hintChars[1], allowedPrefixes),
				})
			end
		end

		table.sort(entries, function(a, b)
			if a.prefix ~= b.prefix then
				return a.prefix < b.prefix
			end
			if a.appTitle ~= b.appTitle then
				return a.appTitle < b.appTitle
			end
			if a.title ~= b.title then
				return a.title < b.title
			end
			local af = a.win:frame()
			local bf = b.win:frame()
			if af.x ~= bf.x then
				return af.x < bf.x
			end
			return af.y < bf.y
		end)

		return entries
	end

	local function buildHintEntries(entries)
		local grouped = {}
		for _, entry in ipairs(entries) do
			grouped[entry.prefix] = grouped[entry.prefix] or {}
			table.insert(grouped[entry.prefix], entry)
		end

		local hints = {}
		for _, char in ipairs(hintChars) do
			local group = grouped[char]
			if group then
				for i, entry in ipairs(group) do
					local key = #group == 1 and char or (char .. keySuffixFor(i - 1, hintChars))
					local title = entry.title ~= "" and entry.title or entry.appTitle
					title = config.showTitles and utf8Truncate(title, config.titleMaxSize) or ""
					table.insert(hints, {
						key = key,
						keyText = key,
						displayKeyText = keyToDisplayText(key),
						titleText = title,
						win = entry.win,
						app = entry.app,
					})
				end
			end
		end

		return hints
	end

	local function nextCenter(baseCenter, screenFrame, width, height, takenCenters)
		local x = baseCenter.x
		local y = baseCenter.y

		for _ = 1, 80 do
			local conflicted = false
			for _, pos in ipairs(takenCenters) do
				local dx = pos.x - x
				local dy = pos.y - y
				if (dx * dx + dy * dy) < (config.bumpThreshold * config.bumpThreshold) then
					conflicted = true
					break
				end
			end

			if not conflicted then
				break
			end

			y = y + config.bumpMove
			local maxY = screenFrame.y + screenFrame.h - (height / 2)
			if y > maxY then
				y = baseCenter.y
				x = x + config.bumpMove
			end
		end

		local minX = screenFrame.x + (width / 2)
		local maxX = screenFrame.x + screenFrame.w - (width / 2)
		local minY = screenFrame.y + (height / 2)
		local maxY = screenFrame.y + screenFrame.h - (height / 2)

		return {
			x = clamp(x, minX, maxX),
			y = clamp(y, minY, maxY),
		}
	end

	local function newHintCanvas(frame, icon, keyText, titleText, keyBoxWidth)
		local canvas = hs.canvas
			.new(frame)
			:level(hs.canvas.windowLevels.overlay)
			:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })

		local topRowHeight = math.max(config.iconSize, config.keyBoxSize)
		local topRowWidth = config.iconSize + config.keyGap + keyBoxWidth
		local topRowLeft = (frame.w - topRowWidth) / 2
		local keyTextHeight = config.fontSize + 8
		local titleTextHeight = config.titleFontSize + 8
		local iconFrame = {
			x = topRowLeft,
			y = config.padding + (topRowHeight - config.iconSize) / 2,
			w = config.iconSize,
			h = config.iconSize,
		}
		local keyBoxFrame = {
			x = topRowLeft + config.iconSize + config.keyGap,
			y = config.padding + (topRowHeight - config.keyBoxSize) / 2,
			w = keyBoxWidth,
			h = config.keyBoxSize,
		}
		local keyPrefixFrame = {
			x = keyBoxFrame.x,
			y = keyBoxFrame.y + (keyBoxFrame.h - keyTextHeight) / 2,
			w = 0,
			h = keyTextHeight,
		}
		local keyRestFrame = {
			x = keyBoxFrame.x,
			y = keyBoxFrame.y + (keyBoxFrame.h - keyTextHeight) / 2,
			w = keyBoxFrame.w,
			h = keyTextHeight,
		}
		local titleTextFrame = {
			x = config.padding,
			y = config.padding + topRowHeight + config.rowGap,
			w = frame.w - (config.padding * 2),
			h = titleTextHeight,
		}

		canvas[1] = {
			type = "rectangle",
			action = "fill",
			fillColor = cloneColor(config.bgColor),
			roundedRectRadii = { xRadius = 12, yRadius = 12 },
			frame = { x = 0, y = 0, w = frame.w, h = frame.h },
		}
		canvas[2] = {
			type = "image",
			image = icon,
			imageScaling = "scaleToFit",
			imageAlpha = config.iconAlpha,
			frame = iconFrame,
		}
		canvas[3] = {
			type = "text",
			text = "",
			textFont = config.fontName,
			textSize = config.fontSize,
			textColor = config.keyHighlightColor,
			textAlignment = "left",
			textLineBreak = "clip",
			frame = keyPrefixFrame,
		}
		canvas[4] = {
			type = "text",
			text = keyToDisplayText(keyText),
			textFont = config.fontName,
			textSize = config.fontSize,
			textColor = config.textColor,
			textAlignment = "left",
			textLineBreak = "clip",
			frame = keyRestFrame,
		}
		canvas[5] = {
			type = "text",
			text = titleText or "",
			textFont = config.fontName,
			textSize = config.titleFontSize,
			textColor = config.titleTextColor,
			textAlignment = "left",
			textLineBreak = "truncateTail",
			frame = titleTextFrame,
		}

		canvas:show()
		return canvas, keyBoxFrame, keyTextHeight
	end

	local function showHints()
		local entries = collectEntries()
		local hintEntries = buildHintEntries(entries)
		if #hintEntries == 0 then
			return
		end

		closeHints(false)
		ensureModal()

		local takenCenters = {}
		for _, hint in ipairs(hintEntries) do
			local screen = hint.win:screen()
			local windowFrame = hint.win:frame()
			if screen then
				local bundleID = hint.app and hint.app:bundleID() or nil
				local icon = bundleID and hs.image.imageFromAppBundle(bundleID) or nil
				local titleWidth = estimatedTextWidth(hint.titleText, config.titleFontSize, 120)
				local keyBoxWidth = keyBoxWidthForText(hint.displayKeyText)
				local topRowWidth = config.iconSize + config.keyGap + keyBoxWidth
				local contentWidth = math.max(topRowWidth, titleWidth)
				local width = config.padding * 2 + contentWidth
				local topRowHeight = math.max(config.iconSize, config.keyBoxSize)
				local titleRowHeight = config.titleFontSize + 8
				local height = config.padding * 2 + topRowHeight + config.rowGap + titleRowHeight
				local center = nextCenter(
					{ x = windowFrame.x + (windowFrame.w / 2), y = windowFrame.y + (windowFrame.h / 2) },
					screen:frame(),
					width,
					height,
					takenCenters
				)
				local canvasFrame = {
					x = center.x - (width / 2),
					y = center.y - (height / 2),
					w = width,
					h = height,
				}
				local canvas, keyBoxFrame, keyTextHeight =
					newHintCanvas(canvasFrame, icon, hint.keyText, hint.titleText, keyBoxWidth)
				hint.canvas = canvas
				hint.keyBoxFrame = keyBoxFrame
				hint.keyTextHeight = keyTextHeight
				table.insert(openHints, hint)
				hintByKey[hint.key] = hint
				table.insert(takenCenters, center)
			end
		end

		if #openHints == 0 then
			clearHints()
			return
		end

		isShowing = true
		currentInput = ""
		refreshHighlights()
		modal:enter()
	end

	local function invokeShowHints()
		local ok, err = pcall(showHints)
		if ok then
			return true
		end
		if config.onError then
			config.onError(err)
		end
		return false
	end

	local function teardown()
		if hotkey then
			hotkey:delete()
			hotkey = nil
		end
		closeHints(true)
		if modal then
			modal:delete()
			modal = nil
		end
	end

	hotkey = hs.hotkey.bind(config.hotkeyModifiers, config.hotkeyKey, function()
		invokeShowHints()
	end)

	return {
		show = invokeShowHints,
		teardown = teardown,
	}
end

return M
