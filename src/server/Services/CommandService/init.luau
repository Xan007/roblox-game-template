local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local admins = require(script.admins)
local conch = require(ReplicatedStorage.Packages.conch)

local CommandService = {}

function CommandService.Init()
    conch.initiate_default_lifecycle()

    for _, commandModule in pairs(ServerScriptService.Modules.Commands:GetChildren()) do
        if commandModule:IsA("ModuleScript") then
            require(commandModule)
        end
    end
end

function CommandService.OnPlayerAdded(player)
    if table.find(admins, player.UserId) then
        conch.give_roles(conch.get_user(player), "super-user")
    end
end

return CommandService