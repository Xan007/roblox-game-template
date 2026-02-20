local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lib = require("@self/lib")
local gt = require(ReplicatedStorage.Packages.GreenTea)

return  {
	assert = lib.assert,

    patch = lib.event(),
}

