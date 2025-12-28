local ReplicatedStorage = game:GetService("ReplicatedStorage")
local conch = require(ReplicatedStorage.Packages.conch)
local conch_ui = require(ReplicatedStorage.Packages.conch_ui)

conch.initiate_default_lifecycle()
conch_ui.bind_to(Enum.KeyCode.F4)