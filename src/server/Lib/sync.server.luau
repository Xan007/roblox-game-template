local ProfileData = require("../Data/ProfileData")
local DataService = require("../Services/DataService")
local Charm = require("../../../roblox_packages/Charm")
local CharmSync = require("../../../roblox_packages/CharmSync")
local Observers = require("../../shared/Modules/Observers")
local Remotes = require("../../shared/Remotes")

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
		end)
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