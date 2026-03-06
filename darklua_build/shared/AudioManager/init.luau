local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Registry = require(script.Registry)

local AudioManager = {}
AudioManager.Groups = {}

function AudioManager.GetSound(soundName: Registry.SoundNames, category: Registry.SoundCategory?)
	local soundInstance 	
if category then
		local targetGroup = Registry.CategoryToGroup[category]
		if not targetGroup then
			warn(`No sound group found for category {category}, defaulting to SFX`)
			targetGroup = "SFX"
		end

		soundInstance = AudioManager.Groups[targetGroup]:FindFirstChild(soundName, true)
	else
		soundInstance = SoundService:FindFirstChild(soundName, true)
	end

	return soundInstance
end

function AudioManager.Play(soundName: Registry.SoundNames, category: Registry.SoundCategory?)
	local soundInstance = AudioManager.GetSound(soundName, category)

	if soundInstance then
		soundInstance:Play()
	end
end

function AudioManager.Stop(soundName: Registry.SoundNames, category: Registry.SoundCategory?)
	local soundInstance = AudioManager.GetSound(soundName, category)

	if soundInstance then
		soundInstance:Stop()
	end
end

if RunService:IsServer() then
	for group in Registry.SoundGroups do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = group
		soundGroup.Parent = SoundService

		AudioManager.Groups[group] = soundGroup
	end

	for category, categorySounds in Registry.Registry do
		for soundName, soundConfig in categorySounds do
			local data = soundConfig.build()

			local soundInstance = Instance.new("Sound")
			soundInstance.Name = soundName

			for key, value in data do
				soundInstance[key] = value
			end

			local targetGroup = Registry.CategoryToGroup[category]
			if not targetGroup then
				warn(`No sound group found for category {category}, defaulting to SFX`)
				targetGroup = "SFX"
			end

			soundInstance.Parent = AudioManager.Groups[targetGroup]
		end
	end
else
	for group in Registry.SoundGroups do
		local soundGroup = SoundService:WaitForChild(group)
		AudioManager.Groups[group] = soundGroup
	end
end

return AudioManager
