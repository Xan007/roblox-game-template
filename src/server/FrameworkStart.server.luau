local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local framework = require(ReplicatedStorage.Packages.Framework)

local Services = ServerScriptService.Services
local Modules = ServerScriptService.Modules

require(ReplicatedStorage.Shared.Hooks)

framework.Add({
	Services,
	Modules,
})

framework.Start()

--[[for _, module in Components:GetDescendants() do
	if module:IsA("ModuleScript") then
		pcall(function()
			require(module)
		end)
	end
end]]