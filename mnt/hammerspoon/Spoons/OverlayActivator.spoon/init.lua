local M = {}
M.__index = M

M.name = "OverlayActivator"
M.description = "OverlayActivator is a spoon that allows you to activate applications using a key combination."
M.version = "0.1.0"

local toKeyMap = function(modifiers, key)
	if #modifiers == 0 then
		return key
	end
	table.sort(modifiers)
	return table.concat(modifiers, "+") .. "+" .. key
end

M.eventTap = nil
M.previousBundleId = nil

function M:start(keysByBundleId)
	if self.eventTap then
		self.eventTap:stop()
	end

	local bundleIdByKey = {}
	for bundleID, keys in pairs(keysByBundleId) do
		for _, key in ipairs(keys) do
			bundleIdByKey[toKeyMap(key[1], key[2])] = bundleID
		end
	end

	self.eventTap = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown }, function(event)
			-- INFO: Escapeでoverlayを閉じた時は元のアプリケーションにフォーカスを戻す必要があるため
			local currentBundleId = hs.application.frontmostApplication():bundleID()

			local activeModifiers = {}
			for mod, isPressed in pairs(event:getFlags()) do
				if isPressed then
					table.insert(activeModifiers, mod)
				end
			end

			local mapKey = toKeyMap(activeModifiers, hs.keycodes.map[event:getKeyCode()])
			local bundleID = bundleIdByKey[mapKey]
			if currentBundleId ~= M.previousBundleId and keysByBundleId[currentBundleId] and mapKey == "escape" then
				hs.application.launchOrFocusByBundleID(M.previousBundleId)
				return false
			end
			if not bundleID then
				return false
			end

			local app = hs.application.get(bundleID)
			M.previousBundleId = currentBundleId
			if app then
				app:activate()
			else
				hs.application.launchOrFocusByBundleID(bundleID)
			end

			return false
		end)
		:start()

	return self
end

function M:stop()
	if self.eventTap then
		self.eventTap:stop()
		self.eventTap = nil
	end
	return self
end

return M
