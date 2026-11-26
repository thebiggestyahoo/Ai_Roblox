local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("EggShared").Config)
local A = {music=0.35, effects=0.65}
local trackId
local activeWorld

local function soundFor(id, volume, looped)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = volume
	sound.Looped = looped
	sound.Parent = SoundService
	return sound
end

function A.play(key)
	local id = Config.audio[key]
	if not id or id <= 0 then return end
	local sound = soundFor(id,A.effects,false)
	sound:Play()
	Debris:AddItem(sound,20)
end

function A.refreshVolume()
	if A.track then A.track.Volume = A.music end
end

function A.setScene(worldKey, racing)
	activeWorld = racing and worldKey or nil
	local id = if racing then Config.worldMusic and Config.worldMusic[worldKey] or 0 else Config.audio.Music
	if id == trackId then
		A.refreshVolume()
		return
	end
	if A.track then A.track:Destroy() end
	A.track = nil
	trackId = id
	if id and id > 0 then
		A.track = soundFor(id,A.music,true)
		A.track:Play()
	end
end

function A.setLobby(enabled)
	A.setScene(activeWorld,not enabled)
end

return A
