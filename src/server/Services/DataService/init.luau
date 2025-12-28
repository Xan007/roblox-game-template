local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)

local ProfileStore = require(ServerScriptService.Modules.ProfileStore)
local ProfileTemplate = require(script.ProfileTemplate)
local SessionTemplate = require(script.SessionTemplate)

local PlayerStore = ProfileStore.New("PlayerStore", ProfileTemplate)

export type PlayerProfile = typeof(PlayerStore:StartSessionAsync())

local Profiles: {[Player]: PlayerProfile} = {}
local Sessions: {[Player]: typeof(SessionTemplate)} = {}

local DataService = {}
DataService.ProfileLoaded = Signal.new() :: Signal.Signal<Player, PlayerProfile>

function DataService.GetKey(userId: number)
	return `Player_{userId}`
end

function DataService.Init()
	local function handleProfile(player: Player, profile: PlayerProfile)
		local leaderstats = script.leaderstats:Clone()
		leaderstats.Parent = player
		if leaderstats then
			leaderstats.Coins.Value = profile.Data.Coins
		end
	end
	
	for player, profile in Profiles do
		handleProfile(player, profile)
	end
	DataService.ProfileLoaded:Connect(handleProfile)
end

function DataService.Start()
	
end

function DataService.GetStore()
	return PlayerStore
end

function DataService.GetProfile(target: Player | number, waitForProfile: boolean?): PlayerProfile?
	local player: Player? = nil
	local profile: PlayerProfile? = nil
	if typeof(target) == "number" then
		player = Players:GetPlayerByUserId(target)
		if player == nil then
			profile = PlayerStore:GetAsync(DataService.GetKey(target))
		end
	elseif typeof(target) == "Instance" and target:IsA("Player") then
		player = target
	else
		return nil
	end
	
	if player then
		profile = Profiles[player]
		if waitForProfile then
			while profile == nil and player.Parent == Players do
				profile = Profiles[player]
				if profile ~= nil then
					break
				end
				task.wait()
			end
		end
	end
	
	return profile
end

function DataService.GetSession(player: Player): typeof(SessionTemplate)
	return Sessions[player]
end

--[[
Allows to safely use a profile for a player.
If the profile doesn't exist yet, it will yield until it does.
Returns true if the profile was successfully loaded.
]]
function DataService.UseProfile(target: Player | number, callback: (profile: PlayerProfile) -> (), waitForProfile: boolean?): boolean
	local profile = DataService.GetProfile(target, waitForProfile or false)
	if profile then
		callback(profile)
		return true
	end
	
	return false
end

function DataService.UseSession(player: Player, callback: (session: typeof(SessionTemplate)) -> ()): boolean
	local Session = Sessions[player]
	if Session then
		callback(Session)
		return true
	end
	return false
end

function DataService.OnPlayerAdded(player: Player)
	Sessions[player] = table.clone(SessionTemplate)
	
	-- Start a profile session for this player's data:
	local profile = PlayerStore:StartSessionAsync(DataService.GetKey(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:
	if profile == nil then
		player:Kick(`Profile load fail - Please rejoin`)
		return
	end

	profile:AddUserId(player.UserId) -- GDPR compliance
	profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick(`Profile session end - Please rejoin`)
	end)

	if player.Parent ~= Players then
		-- The player has left before the profile session started
		profile:EndSession()
		return
	end

	Profiles[player] = profile
	
	DataService.ProfileLoaded:Fire(player, profile)
end

function DataService.OnPlayerRemoving(player: Player)
	Sessions[player] = nil
	
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
		Profiles[player] = nil
	end
end

return DataService