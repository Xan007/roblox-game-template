local Charm = require("../../../roblox_packages/Charm")
local PlayerStore = require("../Services/DataService/PlayerStore")

export type PlayerProfile = typeof(PlayerStore:StartSessionAsync())

local profiles = Charm.reactive({
    
} :: {[Player]: PlayerProfile})

local function wrapProfile(player: Player, profile: PlayerProfile)
    profiles[player] = profile

    return profiles[player]
end

local function getPlayerData(player: Player)  
    local profile = profiles[player]
    if profile then
        return profile.Data
    end
    return nil
end

local function getProfiles()
    return profiles
end

return {
    profiles = profiles,
    wrapProfile = wrapProfile,
    getPlayerData = getPlayerData,

    getProfiles = getProfiles,
}