local RunService = game:GetService("RunService")
local Framework = require("../../../roblox_packages/Framework")

local OnPlayerRemoving = Framework.Hook("OnPlayerRemoving")

return {
	Name = "OnPlayerRemoving",
	IsClient = RunService:IsClient(),
	IsServer = RunService:IsServer(),
	Hook = OnPlayerRemoving,
	Init = function()
		local Players = game:GetService("Players")
		Players.PlayerRemoving:Connect(function(player)
			OnPlayerRemoving:Fire(player)
		end)
	end
}
