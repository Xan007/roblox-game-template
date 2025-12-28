local RunService = game:GetService("RunService")
local HooksFolder = script

for _, module in HooksFolder:GetChildren() do
    if module:IsA("ModuleScript") and module.Name ~= "init" then
        local hookInfo = require(module)
        if (hookInfo.IsClient and RunService:IsServer()) or (hookInfo.IsServer and RunService:IsClient()) then
            continue
        end
        if hookInfo.Init then
            hookInfo.Init()
        end
    end
end

return true
