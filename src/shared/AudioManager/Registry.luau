local create = require(script.Parent.Util.create)

local SoundGroups = {
	["SFX"] = true,
	["Music"] = true,
	["Ambient"] = true,
	["Enemies"] = true,
}

local SoundRegistry = {
	["UI"] = {
		["Click"] = create(9111),
		["Hover"] = create(1111).volume(0.5),
	},
	["Zombies"] = {
		["Died"] = create().fromId(2222).looped(true),
		["Walk"] = create().fromId(3333),
	},
	["Players"] = {
		["Jump"] = create().fromId(4444),
		["Land"] = create().fromId(5555),
	},
}

local CategoryToGroup: { [SoundCategory]: SoundGroups } = {
	["UI"] = "SFX",
	["Zombies"] = "Enemies",
	["Players"] = "SFX",
}

export type SoundGroups = keyof<typeof(SoundGroups)>
export type SoundCategory = keyof<typeof(SoundRegistry)>
export type SoundNames =
	| keyof<typeof(SoundRegistry.UI)>
	| keyof<typeof(SoundRegistry.Zombies)>
	| keyof<typeof(SoundRegistry.Players)>

return {
	Registry = SoundRegistry,
	CategoryToGroup = CategoryToGroup,
	SoundGroups = SoundGroups,
}
