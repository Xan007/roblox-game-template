local function v1(old)
	old.coins = old.coins or 0
	return old
end

local function v2(old)
	old.xp = math.max(old.xp or 0, 0)
	return old
end

local MIGRATIONS = {
	{
		migrate = v1,
		backwardsCompatible = true,
	},
	{
		migrate = v2,
		backwardsCompatible = true,
	},
}

return MIGRATIONS
