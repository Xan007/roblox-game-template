local Charm = require("../../../roblox_packages/Charm")

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