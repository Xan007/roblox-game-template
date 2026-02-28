local function create(id: number?)
	local data = {}
	local builder = {}
	function builder.fromId(id: number)
		data.SoundId = `rbxassetid://{id}`
		return builder
	end
	function builder.url(url: string)
		data.SoundId = url
		return builder
	end
	function builder.volume(volume: number)
		data.Volume = volume
		return builder
	end
	function builder.looped(looped: boolean)
		data.Looped = looped
		return builder
	end
	function builder.build()
		return data
	end
	if id then
		builder.fromId(id)
	end
	return builder
end

return create
