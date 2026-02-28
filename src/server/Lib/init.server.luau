local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
	Reparent the server's files to a non-replicated instance to prevent clients 
	from accessing server-only scripts.
]]

local server = require(ReplicatedStorage.roblox_packages[".pesde"]["littensy_charm-sync@0.4.0-rc.5"]["charm-sync"].server)
local framework = require("../../roblox_packages/Framework")

local Services = script.Parent.Services
local Modules = script.Parent.Modules

require("../shared/Hooks")
require("../shared/AudioManager")

framework.Add({
	Services,
	Modules,
})

framework.Start()

local destination = Instance.new("Camera")
local source: Instance = script:FindFirstAncestor("server")

destination.Name = source.Name
destination.Parent = source.Parent

for _, child in source:GetChildren() do
	child.Parent = destination
end

local serverPackages = ReplicatedStorage.roblox_server_packages

local destination_2 = Instance.new("Camera")
destination_2.Name = serverPackages.Name
destination_2.Parent = serverPackages.Parent


for _, child in serverPackages:GetChildren() do
	child.Parent = destination_2
end

source.Parent = nil
serverPackages.Parent = nil

--[[for _, module in Components:GetDescendants() do
	if module:IsA("ModuleScript") then
		pcall(function()
			require(module)
		end)
	end
end]]