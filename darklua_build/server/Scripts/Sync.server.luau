local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local DataService = require(ServerScriptService.Services.DataService)
local Observers = require(ReplicatedStorage.Shared.Modules.Observers)
local ProfileData = require(ServerScriptService.Data.ProfileData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local server = CharmSync.server

local function onPlayerAdded(player: Player)
	server.addSignalsToClient(player, {
		[`data-{player.UserId}`] = Charm.computed(function()
			local profile = DataService.GetProfile(player)
			if not profile then
				return {}
			end

			local dataToReplicate = profile.Data

			for key, shouldReplicate in (ProfileData.replicateSchema or {}) do
				if not shouldReplicate then
					dataToReplicate[key] = nil
				end
			end

			return dataToReplicate
		end),
	})
end

local function onPlayerRemoving(player: Player)
	server.removeClient(player)
end

server.connect(function(player, patches)
	Remotes.patch:FireClient(player, patches)
end)

Observers.observePlayers(function(player: Player): (() -> ())?
	onPlayerAdded(player)

	return function()
		onPlayerRemoving(player)
	end
end)
