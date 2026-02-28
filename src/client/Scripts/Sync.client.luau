local Players = game:GetService("Players")

local PlayerDataStore = require("../Stores/PlayerDataStore")
local CharmSync = require("../../../roblox_packages/CharmSync")
local Remotes = require("../../shared/Remotes")

local function deepAssign(target, source)
	for key, value in source do
		if typeof(value) == "table" and typeof(target[key]) == "table" then
			deepAssign(target[key], value)
		else
			target[key] = value
		end
	end
end

local client = CharmSync.client

client.addSignals({
	[`data-{Players.LocalPlayer.UserId}`] = function(data)
		if typeof(data) == "function" then
			data = data()
		else
			return
		end

		deepAssign(PlayerDataStore.playerData, data)
	end
} :: any)

Remotes.patch.OnClientEvent:Connect(function(patches)
	client.patch(patches)
end)