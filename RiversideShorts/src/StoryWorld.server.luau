local Players=game:GetService("Players")
local shared=game:GetService("ReplicatedStorage")
local Config=require(shared.RobloxCinematic.Config)
Players.CharacterAutoLoads=Config.ExploreTown
require(script.Parent.WorldBuilder).build()
if Config.ExploreTown then
	for _,player in Players:GetPlayers() do
		if not player.Character then task.spawn(function() player:LoadCharacterAsync() end) end
	end
	return
end
local Actor=require(script.Parent.ActorController)
local runtime=Instance.new("Folder")
runtime.Name="RiversideRuntime"
script.Parent.ActorController:Clone().Parent=runtime
local cast=Instance.new("Folder")
cast.Name,cast.Parent="Cast",runtime
runtime.Parent=shared
local count=0
for role,names in Config.Cast do
	count+=1
	task.spawn(function()
		local ok,result=pcall(Actor.spawn,role,names,cast,Config.Outfits[role])
		if not ok or not result then warn("[Riverside Shorts] Avatar load failed for "..role) end
		count-=1
	end)
end
while count>0 do task.wait() end
runtime:SetAttribute("Ready",true)
