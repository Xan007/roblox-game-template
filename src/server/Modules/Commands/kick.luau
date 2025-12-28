local ReplicatedStorage = game:GetService("ReplicatedStorage")
local conch = require(ReplicatedStorage.Packages.conch)

conch.register("kick", {
	description = "Kicks the given player from the server",
	permissions = { "kick-player" },
	arguments = function()
		return
			conch.args.player("player", "The player that should be kicked from the server"),
			conch.args.string("reason", "The reason why the player has been kicked from the user.")
	end,

	callback = function(player, reason)
		player:Kick(reason)
	end
})

return true