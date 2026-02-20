local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local PlayerData = Charm.reactive({
    xp = 0,
    coins = 0,
} :: {xp: number, coins: number})

local function getPlayerData()
    return PlayerData
end

return {
    playerData = PlayerData,

    getCoins = Charm.computed(function()
        return PlayerData and PlayerData.coins or nil
    end),
    getPlayerData = getPlayerData,
}