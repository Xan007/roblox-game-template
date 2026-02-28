local admins = require("@self/admins")
local conch = require("../../../roblox_packages/conch")

local CommandService = {}

function CommandService.Init()
    conch.initiate_default_lifecycle()

    for _, commandModule in script.Commands:GetChildren() do
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