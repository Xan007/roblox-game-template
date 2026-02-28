local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gt = require(ReplicatedStorage.Packages.GreenTea)
local lib = require("@self/lib")

return {
	assert = lib.assert,

	patch = lib.event(),
}
