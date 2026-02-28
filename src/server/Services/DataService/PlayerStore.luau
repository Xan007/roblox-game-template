-- Creates PlayerStore to be able to export the type of the player profile
local ProfileData = require("../../Data/ProfileData")
local ProfileStore = require("../../../../roblox_server_packages/ProfileStore")

local PlayerStore = ProfileStore.New("PlayerStore", ProfileData.template)

export type PlayerProfile = typeof(PlayerStore:StartSessionAsync())

return PlayerStore