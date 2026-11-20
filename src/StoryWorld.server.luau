local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
Players.CharacterAutoLoads=false
local shared=ReplicatedStorage:WaitForChild("RobloxCinematic")
local config=require(shared.Config)
local World=require(script.Parent.WorldBuilder)
local Actor=require(script.Parent.ActorController)
local root=World.build()
local runtime=Instance.new("Folder")
runtime.Name,runtime.Parent="SecondChancesRuntime",ReplicatedStorage
script.Parent.ActorController:Clone().Parent=runtime
local origins=Instance.new("Folder")
origins.Name,origins.Parent="Origins",runtime
for name,origin in World.origins do
	local value=Instance.new("Vector3Value")
	value.Name,value.Value,value.Parent=name,origin,origins
end
local assets=Instance.new("Folder")
assets.Name,assets.Parent="Cast",runtime
local pending=0
for role,names in config.Cast do
	pending+=1
	task.spawn(function()
		local ok,result=pcall(Actor.spawn,role,names,assets)
		if not ok then warn("[Second Chances] "..role..": "..tostring(result)) end
		pending-=1
	end)
end
while pending>0 do task.wait() end
local extra=assets:FindFirstChild("Student")
if extra then
	local clone=extra:Clone()
	clone.Name,clone.Parent="Extra",assets
end
runtime:SetAttribute("Ready",true)
print("[Second Chances] Sets ready: "..#root:GetChildren().."; avatar roles loaded: "..#assets:GetChildren())
