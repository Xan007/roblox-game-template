--[[
DataService is responsible for handling player data profiles using the PlayerStore module.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Charm = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('Charm'))
local Migration = require(script.Migration)
local Migrations = require(ServerScriptService.Data.Migrations)
local ProfileData = require(ServerScriptService.Data.ProfileData)
local Signal = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('Signal'))
local gt = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('GreenTea'))

local PlayerProfileStore = require(ServerScriptService.Stores.PlayerProfileStore)
local PlayerStore = require(script.PlayerStore)

local Profiles = PlayerProfileStore.profiles

local DataService = {}
DataService.Order = 0

type PlayerProfile = PlayerStore.PlayerProfile

DataService.ProfileLoaded = Signal.new() :: Signal.Signal<Player, PlayerProfile>

local CallbacksBeforeProfileRelease = {} :: { (player: Player, profile: PlayerProfile) -> () }

function DataService.Start()
	DataService.ProfileLoaded:Connect(function(player: Player, profile)
		local leadertstats = Instance.new("Folder")
		leadertstats.Name = "leaderstats"
		leadertstats.Parent = player

		for _, stat in ProfileData.leaderstats do
			local object = Instance.new(stat.object)
			object.Parent = leadertstats
			object.Name = stat.display

			Charm.listen(
				Charm.computed(function()
					return profile.Data[stat.key]
				end),
				function(value, oldValue)
					if stat.format then
						object.Value = stat.format(value)
					else
						object.Value = value
					end
				end
			)
		end
	end)
end

local function noYield<Args..., Results...>(fn: (Args...) -> Results...): (Args...) -> Results...	
local function resultHandler(thread: thread, ok: boolean, ...)
		if not ok then
			error(debug.traceback(thread, tostring((...))))
		elseif coroutine.status(thread) ~= "dead" then
			error(debug.traceback(thread, "Yielding is not allowed on profile"))
		end
		return ...
	end
	return function(...)
		local thread = coroutine.create(fn)
		return resultHandler(thread, coroutine.resume(thread, ...))
	end
end

local function typeCheck(data, player: Player?)
	local profileTypechecker = gt.typecast(ProfileData.schema)
	local isValid, msg = profileTypechecker:matches(data)
	if not isValid then
		if player then
			warn(`Profile data for player {player.Name} failed typecheck: {msg}`)
		end
	end

	return isValid
end

function DataService.GetKey(userId: number)
	return `Player_{userId}`
end

function DataService.GetStore()
	return PlayerStore
end

function DataService.GetProfile(target: Player | number, waitForProfile: boolean?): PlayerProfile?
	local player: Player? 	
local profile: PlayerProfile? 	
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

--[[
Allows to safely use a profile for a player.
If the profile doesn't exist yet, it will yield until it does.
Returns true if the profile was successfully loaded.
]]
function DataService.UseProfile(
	target: Player | number,
	callback: (profile: PlayerProfile) -> (),
	waitForProfile: boolean?
): boolean
	local profile = DataService.GetProfile(target, waitForProfile or false)
	if profile then
		noYield(callback)(profile)
		return true
	end

	return false
end

function DataService.OnPlayerAdded(player: Player)
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

	-- Apply migrations if needed
	local migrateOk, migratedData, lastCompatibleVersion = Migration.migrate(Migrations, profile.Data, player.Name)
	if not migrateOk then
		player:Kick(`Profile migration failed: {migratedData}`)
		profile:EndSession()
		return
	end

	for key, value in migratedData do
		profile.Data[key] = value
	end
	profile.Data.migrationVersion = #Migrations
	profile.Data.lastCompatibleVersion = lastCompatibleVersion

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick(`Profile session end - Please rejoin`)
	end)

	if player.Parent ~= Players then
		-- The player has left before the profile session started
		profile:EndSession()
		return
	end

	typeCheck(profile.Data, player)

	profile = PlayerProfileStore.wrapProfile(player, profile)
	DataService.ProfileLoaded:Fire(player, profile)
end

function DataService.OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		for _, callback in CallbacksBeforeProfileRelease do
			local success, error = pcall(function()
				noYield(callback)(player, profile)
			end)
			if not success then
				warn(`Error in callback before profile release for player {player.Name}: {error}`)
			end
		end

		typeCheck(profile.Data, player)

		profile:EndSession()
		Profiles[player] = nil
	end
end

function DataService.RegisterBeforeProfileRelease(callback: (player: Player, profile: PlayerProfile) -> ())
	table.insert(CallbacksBeforeProfileRelease, callback)
end

return DataService
