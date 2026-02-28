local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gt = require(ReplicatedStorage.Packages.GreenTea)

local schema = gt.table({
	xp = gt.number(),
	coins = gt.number(),

	-- DO NOT DELETE OR RENAME THESE FIELDS
	migrationVersion = gt.optional(gt.number()),
	lastCompatibleVersion = gt.optional(gt.number()),
})

local template: Schema = {
	xp = 0,
	coins = 0,

	migrationVersion = 0,
	lastCompatibleVersion = 0,
}

local replicateSchema: { [keys]: boolean } = {
	xp = true,
	coins = true,
}

type valid_values = "BoolValue" | "IntValue" | "NumberValue" | "StringValue"

type stat = {
	key: keys,
	display: string,
	object: valid_values,
	format: ((value: any) -> any)?,
}

local leaderstats: { stat } = {
	{
		key = "xp",
		display = "XP",
		object = "NumberValue",
		format = function(value: any)
			return math.floor(value)
		end,
	},
	{
		key = "coins",
		display = "Coins",
		object = "StringValue",
		format = function(value: any)
			if value >= 1000 then
				return string.format("%.1fK", value / 1000)
			else
				return tostring(value)
			end
		end,
	},
}

export type Schema = typeof(schema)
type keys = keyof<typeof(schema)>

return {
	template = template,
	schema = schema,
	replicateSchema = replicateSchema,
	leaderstats = leaderstats,
}
