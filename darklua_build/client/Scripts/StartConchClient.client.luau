local conch = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('conch'))
local conch_ui = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('conch_ui'))

conch.initiate_default_lifecycle()
conch_ui.bind_to(Enum.KeyCode.F4)
