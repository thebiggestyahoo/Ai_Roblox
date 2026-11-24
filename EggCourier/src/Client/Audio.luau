local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("EggShared").Config)
local A = {music=0.35, effects=0.65}

function A.play(key)
	local id = Config.audio[key]
	if not id or id <= 0 then return end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = key == "Music" and A.music or A.effects
	sound.Looped = key == "Music"
	sound.Parent = SoundService
	sound:Play()
	if sound.Looped then A.track = sound else Debris:AddItem(sound,20) end
end

function A.setLobby(enabled)
	if enabled and not A.track then A.play("Music") end
	if A.track then
		A.track.Volume = A.music
		if enabled then A.track:Resume() else A.track:Pause() end
	end
end
return A
