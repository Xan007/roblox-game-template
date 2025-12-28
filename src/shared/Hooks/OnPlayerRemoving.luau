local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Packages.Framework)

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
