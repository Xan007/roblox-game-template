local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Packages.Framework)

local OnPlayerAdded = Framework.Hook("OnPlayerAdded")

return {
	Name = "OnPlayerAdded",
	IsClient = RunService:IsClient(),
	IsServer = RunService:IsServer(),
	Hook = OnPlayerAdded,
	Init = function()
		local Players = game:GetService("Players")
		Players.PlayerAdded:Connect(function(player)
			OnPlayerAdded:Fire(player)
		end)
		if RunService:IsServer() then
			task.defer(function()
				for _, player in Players:GetPlayers() do
					OnPlayerAdded:Fire(player)
				end
			end)
		end
	end
}
