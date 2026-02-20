-- Creates PlayerStore to be able to export the type of the player profile
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileData = require(ServerScriptService.Data.ProfileData)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

local PlayerStore = ProfileStore.New("PlayerStore", ProfileData.template)

export type PlayerProfile = typeof(PlayerStore:StartSessionAsync())

return PlayerStore