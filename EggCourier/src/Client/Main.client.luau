local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Input = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Market = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local Shared = RS:WaitForChild("EggShared")
local Config, Levels = require(Shared.Config),require(Shared.Levels)
local Egg = require(Shared.EggModel)
local Audio = require(script.Parent.Audio)
local remote = Shared:WaitForChild("CourierEvent")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CourierBroadcast"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local rgb = Color3.fromHex
local navy, dark, white = rgb("242751"), rgb("343968"), rgb("fff8e6")
local yellow, mint, pink, orange = rgb("ffda54"),rgb("74edcc"),rgb("ff739e"),rgb("ff9356")
local state = {stage="Lobby", selected=1, level=1, deadline=0}
local race = {hp=3, place=1, total=1, progress=0, check=0, checks=0, cooldown=0, recover=0}
local profile = {skins={Classic=true},skin="Classic",trails={},records={},title=1}
local tab, preview = nil,"Classic"
local at = function() return workspace:GetServerTimeNow() end

local function round(parent, radius)
	local corner = Instance.new("UICorner",parent)
	corner.CornerRadius = UDim.new(0,radius or 13)
end
local function border(parent,color,transparency)
	local line=Instance.new("UIStroke",parent)
	line.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	line.Color=color
	line.Transparency=transparency or 0
	line.Thickness=1.5
	return line
end
local function frame(parent, color, size, position, radius)
	local f = Instance.new("Frame")
	f.BackgroundColor3=color
	f.BorderSizePixel=0
	f.Size=size
	f.Position=position or UDim2.new()
	f.Parent=parent
	round(f,radius)
	return f
end
local function label(parent,text,size,position,fontSize,color,bold)
	local f=Instance.new("TextLabel")
	f.BackgroundTransparency=1
	f.Size=size
	f.Position=position or UDim2.new()
	f.Font=bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	f.TextSize=fontSize or 15
	f.TextColor3=color or white
	f.Text=text
	f.Parent=parent
	return f
end
local function button(parent,text,color,callback)
	local b=Instance.new("TextButton")
	b.AutoButtonColor=true
	b.BackgroundColor3=color
	b.TextColor3=color == dark and white or navy
	b.Text=text
	b.TextSize=15
	b.Font=Enum.Font.GothamBold
	b.Size=UDim2.new(1,0,0,40)
	b.Parent=parent
	round(b,10)
	b.Activated:Connect(function()
		Audio.play("Click")
		callback()
	end)
	return b
end
local function fire(action,value)
	remote:FireServer(action,value)
end

local tint=Instance.new("Frame",gui)
tint.BackgroundColor3=pink
tint.BackgroundTransparency=1
tint.Size=UDim2.fromScale(1,1)
local top=frame(gui,navy,UDim2.new(1,-24,0,82),UDim2.new(0.5,0,0,8))
top.AnchorPoint=Vector2.new(0.5,0)
border(top,dark)
local topLimit=Instance.new("UISizeConstraint",top)
topLimit.MaxSize=Vector2.new(500,82)
local line1=label(top,"",UDim2.new(1,-70,0,27),UDim2.fromOffset(12,4),16,white,true)
line1.TextXAlignment=Enum.TextXAlignment.Left
line1.TextTruncate=Enum.TextTruncate.AtEnd
local timer=label(top,"",UDim2.fromOffset(62,27),UDim2.new(1,-69,0,4),18,yellow,true)
local details=label(top,"",UDim2.new(1,-24,0,24),UDim2.fromOffset(12,31),13,mint)
details.TextXAlignment=Enum.TextXAlignment.Left
local track=frame(top,dark,UDim2.new(1,-24,0,6),UDim2.fromOffset(12,66),4)
local fill=frame(track,mint,UDim2.fromScale(0,1),nil,4)

local callout=label(gui,"",UDim2.new(1,0,0,86),UDim2.new(0,0,0.32,0),46,yellow,true)
callout.TextStrokeColor3=navy
callout.TextStrokeTransparency=0.25
callout.Visible=false
local toast=frame(gui,navy,UDim2.new(1,-34,0,38),UDim2.new(0.5,0,0,100))
toast.AnchorPoint=Vector2.new(0.5,0)
toast.Visible=false
local toastLimit=Instance.new("UISizeConstraint",toast)
toastLimit.MaxSize=Vector2.new(350,38)
local toastText=label(toast,"",UDim2.fromScale(1,1),nil,14,yellow,true)
local toastVersion=0
local function notice(message)
	toastVersion+=1
	local current=toastVersion
	toastText.Text=message
	toast.Visible=true
	task.delay(2,function() if current==toastVersion then toast.Visible=false end end)
end

local nav=frame(gui,navy,UDim2.new(0,94,0,224),UDim2.new(0,10,0.5,0))
nav.AnchorPoint=Vector2.new(0,0.5)
local navLayout=Instance.new("UIListLayout",nav)
navLayout.Padding=UDim.new(0,5)
navLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment=Enum.VerticalAlignment.Center
local menu, menuTitle, list, layout
local setTab
local play=button(nav,"Play",yellow,function()
	fire((state.queued or state.practiceQueued) and "lobby" or "queue")
end)
local menuButtons={play}
for _, name in {"Courses","Egg Shop","Stats","Settings"} do
	table.insert(menuButtons,button(nav,name,dark,function()
		setTab(if name=="Egg Shop" then "Shop" else name)
	end))
end
for _, b in menuButtons do b.Size=UDim2.fromOffset(82,36) end

local shove=button(gui,"SHOVE",orange,function() fire("shove") end)
shove.AnchorPoint=Vector2.new(1,0.5)
shove.Position=UDim2.new(1,-12,0.62,0)
shove.Size=UDim2.fromOffset(100,48)
shove.Visible=false
Input:BindAction("CourierShove",function(_,status)
	if not shove.Visible then return Enum.ContextActionResult.Pass end
	if status==Enum.UserInputState.Begin then fire("shove") end
	return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
local zoneLabel=label(gui,"CRACK ZONE  •  E / X TO SHOVE",UDim2.new(1,0,0,28),UDim2.fromOffset(0,91),14,orange,true)
zoneLabel.TextStrokeTransparency=0.3
zoneLabel.Visible=false

menu=frame(gui,navy,UDim2.new(0.92,0,1,-108),UDim2.new(0.5,0,0,98),18)
menu.AnchorPoint=Vector2.new(0.5,0)
menu.Visible=false
menu.Active=true
border(menu,rgb("7777a6"))
local menuLimit=Instance.new("UISizeConstraint",menu)
menuLimit.MaxSize=Vector2.new(465,500)
menuTitle=label(menu,"",UDim2.new(1,-75,0,52),UDim2.fromOffset(16,0),24,yellow,true)
menuTitle.TextXAlignment=Enum.TextXAlignment.Left
local close=button(menu,"Close",dark,function() setTab(nil) end)
close.Size=UDim2.fromOffset(60,30)
close.Position=UDim2.new(1,-70,0,10)
list=Instance.new("ScrollingFrame",menu)
list.BackgroundTransparency=1
list.BorderSizePixel=0
list.Position=UDim2.fromOffset(13,54)
list.Size=UDim2.new(1,-26,1,-65)
list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new()
list.ScrollBarThickness=4
list.ScrollBarImageColor3=mint
layout=Instance.new("UIListLayout",list)
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Padding=UDim.new(0,7)

local function row(text,color)
	local l=label(list,text,UDim2.new(1,-8,0,30),nil,14,color)
	l.TextWrapped=true
	return l
end

local function previewEgg()
	local view=Instance.new("ViewportFrame",list)
	view.Size=UDim2.new(1,-7,0,106)
	view.BackgroundColor3=dark
	view.Ambient=rgb("cdd2fa")
	view.LightColor=white
	view.LightDirection=Vector3.new(-1,-1,-1)
	round(view,10)
	local camera=Instance.new("Camera",view)
	camera.CFrame=CFrame.lookAt(Vector3.new(2,1.1,4.5),Vector3.zero)
	camera.FieldOfView=32
	view.CurrentCamera=camera
	local mesh=Egg.build(preview,1.45,true)
	mesh.Parent=view
end

local draw
draw=function()
	for _, child in list:GetChildren() do
		if child ~= layout then child:Destroy() end
	end
	menu.Visible=tab~=nil
	nav.Visible=tab==nil and not state.racing
	if not tab then return end
	menuTitle.Text=({Shop="Egg shop",Courses="Green Meadows",Stats="Courier stats",Settings="Settings",Results="Race results"})[tab]
	if tab=="Courses" then
		if state.stage=="Voting" and state.queued then row("Vote among courses unlocked by the whole group",mint) end
		for i, item in Levels do
			if typeof(i)~="number" then continue end
			local unlocked=i<=(player:GetAttribute("Unlocked") or 1)
			local text=("%02d   %s%s"):format(i,item.name,unlocked and (state.selected==i and "  ✓" or "") or "   •   Locked")
			if unlocked then button(list,text,state.selected==i and yellow or dark,function() fire("choose",tostring(i)) end)
			else row(text) end
		end
		button(list,"Practice selected course",mint,function() fire("practice"); setTab(nil) end)
	elseif tab=="Shop" then
		previewEgg()
		local skin=Config.bySkin[preview]
		local cost=skin[3]
		local owns=profile.skins[preview]
		local enabled=Config.passes[preview] and Config.passes[preview]>0
		row(skin[2],yellow)
		if owns or typeof(cost)=="number" or enabled then
			button(list,owns and (profile.skin==preview and "Equipped" or "Equip egg") or (enabled and "View Roblox price" or ("Buy & equip  •  %d coins"):format(cost)),mint,function()
				fire("skin",preview)
			end)
		else
			row(preview=="Cosmic" and "Future World 4 completion reward" or "Premium cosmetic unavailable")
		end
		for _, item in Config.skins do
			button(list,item[2] .. (profile.skins[item[1]] and "   ✓" or ""),item[1]==preview and yellow or dark,function()
				preview=item[1]
				draw()
				list.CanvasPosition=Vector2.zero
				if GuiService.SelectedObject then GuiService.SelectedObject=list:FindFirstChildWhichIsA("TextButton") or close end
			end)
		end
		row("COURIER TRAILS",mint)
		button(list,"Remove trail",dark,function() fire("trail","") end)
		for _, id in {"Lightning","Rainbow","VIP"} do
			local price=Config.trails[id]
			if price or profile.trails[id] then
				local description=profile.trail==id and "Equipped" or (profile.trails[id] and "Equip" or ("%d coins"):format(price))
				button(list,id .. "  •  " .. description,dark,function() fire("trail",id) end)
			end
		end
	elseif tab=="Stats" then
		row(("%d coins    /    %d wins    /    %d XP"):format(player:GetAttribute("Coins") or 0,player:GetAttribute("Wins") or 0,player:GetAttribute("XP") or 0),mint)
		for i, title in Config.titles do
			if i<5 and (player:GetAttribute("XP") or 0)>=Config.titleXP[i] then
				button(list,title .. (profile.title==i and "  ✓" or ""),dark,function() fire("title",tostring(i)) end)
			else row(title .. (i==5 and "  •  World 4 reward" or ("  •  %d XP"):format(Config.titleXP[i]))) end
		end
		for i=1,#Levels do
			local record=profile.records[tostring(i)]
			if record then row(("%s   %.2fs"):format(Levels[i].name,record),yellow) end
		end
	elseif tab=="Settings" then
		for _, key in {"music","effects"} do
			local heading=key=="music" and "Music" or "Sound effects"
			button(list,("%s  •  %d%%"):format(heading,math.round(Audio[key]*100)),dark,function()
				Audio[key]=if Audio[key]>=0.99 then 0 elseif Audio[key]==0 then 0.25 else math.min(1,Audio[key]+0.25)
				Audio.setLobby(not state.racing)
				draw()
			end)
		end
	elseif tab=="Results" then
		local result=state.result
		if result and not result.dnf then
			row(result.practice and "Practice complete" or ("Finished #%d"):format(result.place),mint)
			row(("%.2fs    /    %d of 3 shell    /    +%d coins"):format(result.time,result.hp,result.coins),yellow)
			if result.record then row("NEW PERSONAL RECORD",mint) end
		elseif result then row(("Time expired  •  %d%% complete  •  %d of 3 shell"):format(math.floor(result.progress*100),result.hp),orange) end
		for _, entry in state.scoreboard or {} do row(("%d   %s   /   %.2fs"):format(entry.place,entry.name,entry.time)) end
		button(list,"Next race",yellow,function() fire("next"); setTab(nil) end)
		button(list,"Return to lobby",dark,function() fire("lobby"); setTab(nil) end)
	end
end

setTab=function(name)
	if name and tab==name and name~="Results" then name=nil end
	tab=name
	draw()
	list.CanvasPosition=Vector2.zero
	if GuiService.SelectedObject then
		GuiService.SelectedObject=if name then close elseif nav.Visible then play else nil
	end
end

local function confetti()
	for i=1,26 do
		local bit=frame(gui,({yellow,mint,pink,orange})[i%4+1],UDim2.fromOffset(7,12),UDim2.fromScale(0.5,0.47),2)
		bit.Rotation=i*33
		Tween:Create(bit,TweenInfo.new(0.9+i%5*0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
			Position=UDim2.fromScale(0.5+math.cos(i)*0.48,0.48+math.sin(i)*0.43),
			Rotation=i*68,BackgroundTransparency=1,
		}):Play()
		Debris:AddItem(bit,1.45)
	end
end

local lastCount, showGo = nil,0
local fade=Instance.new("Frame",gui)
fade.Size=UDim2.fromScale(1,1)
fade.BackgroundColor3=navy
fade.BackgroundTransparency=1
fade.ZIndex=20
local function cameraTransition()
	fade.BackgroundTransparency=0.15
	Tween:Create(fade,TweenInfo.new(0.45,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play()
end
remote.OnClientEvent:Connect(function(kind,value,extra)
	if kind=="State" then
		local before=state.stage
		state=value
		if state.racing and state.stage~=before and (state.stage=="Preparation" or state.stage=="Returning") then
			cameraTransition()
		end
		if state.stage=="Countdown" and before~="Countdown" then
			race={hp=3,place=1,total=state.total,progress=0,check=0,checks=0,cooldown=0,recover=0}
			lastCount=nil
		elseif state.stage=="Race" and before=="Countdown" and state.racing then
			showGo=at()+0.75
			Audio.play("Start")
		end
		Audio.setLobby(not state.racing)
		if state.stage=="Returning" or (not state.racing and tab=="Results") then setTab(nil)
		elseif state.result and state.racing and tab~="Results" then setTab("Results")
		elseif state.racing and not state.result and tab then setTab(nil)
		elseif state.stage=="Voting" and state.queued and before~="Voting" then setTab("Courses")
		elseif tab=="Courses" or (tab=="Results" and state.stage=="Results") then draw()
		else nav.Visible=tab==nil and not state.racing end
	elseif kind=="Race" then
		if value.zone and not race.zone and not state.practice and not state.solo then notice("CRACK ZONE  •  Shoves are live") end
		race=value
	elseif kind=="Profile" then
		profile=value
		if tab=="Stats" or tab=="Shop" then
			local position=list.CanvasPosition
			local selected=GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(list)
			draw()
			list.CanvasPosition=position
			if selected then GuiService.SelectedObject=close end
		end
	elseif kind=="Open" then setTab(value)
	elseif kind=="Notice" then notice(value)
	elseif kind=="Pass" then
		local ok=pcall(Market.PromptGamePassPurchase,Market,player,value)
		if not ok then notice("Roblox purchase prompt unavailable") end
	elseif kind=="FX" then
		Audio.play(value)
		if value=="Crack" or value=="Break" then
			tint.BackgroundTransparency=0.65
			Tween:Create(tint,TweenInfo.new(0.38),{BackgroundTransparency=1}):Play()
			notice(value=="Break" and "EGG BROKE  •  Returning to checkpoint" or (extra==1 and "ONE SHELL LEFT" or "SHELL CRACKED"))
		elseif value=="Checkpoint" then notice(extra==0 and "Fresh egg" or ("CHECKPOINT %d"):format(extra))
		elseif value=="Finish" then
			confetti()
			if extra.coins>0 then Audio.play("Coins") end
			if extra.place==1 then Audio.play("Victory") end
		end
	end
end)

local function clock(n)
	n=math.max(0,math.ceil(n))
	return ("%d:%02d"):format(n//60,n%60)
end
local display=0
Run.RenderStepped:Connect(function(dt)
	display+=dt
	local current=at()
	for _, courier in Players:GetPlayers() do
		local char=courier.Character
		local root=char and char:FindFirstChild("HumanoidRootPart")
		local egg=char and char:FindFirstChild("CourierEgg")
		local shell=egg and egg.PrimaryPart
		local motor=shell and shell:FindFirstChild("EggMotor")
		if root and motor then
			local velocity=root.AssemblyLinearVelocity
			local amplitude=math.clamp(velocity.Magnitude/16,0.2,1)
			motor.Transform=CFrame.new(0,math.sin(current*11)*0.084*amplitude,0)*CFrame.Angles(math.sin(current*6)*0.12*amplitude,0,math.cos(current*9)*0.14*amplitude)
			if egg:GetAttribute("Skin")=="Rainbow" then
				local rainbow=Color3.fromHSV((current%4)/4,0.66,1)
				shell.Color=rainbow
				local crown=egg:FindFirstChild("Crown")
				if crown then crown.Color=rainbow end
			end
		end
	end
	if display<0.08 then return end
	display=0
	local coins=player:GetAttribute("Coins") or 0
	local racing=state.racing and (state.stage=="Race" or state.stage=="Countdown" or state.stage=="Preparation")
	local left=state.deadline-current
	timer.Text=state.stage=="Lobby" and "" or clock(left)
	if racing then
		line1.Text=("%02d  /  %s"):format(state.level,Levels[state.level].name)
		local shells=string.rep("●",race.hp)..string.rep("○",3-race.hp)
		details.Text=("%s   %d/%d   CP %d/%d   %d%%   ◈ %d"):format(shells,race.place,race.total,race.check,race.checks,math.floor(race.progress*100),coins)
		details.TextColor3=race.hp<=1 and orange or mint
		fill.Size=UDim2.fromScale(race.progress,1)
	else
		line1.Text="DON’T CRACK THE EGG!"
		local status=({Lobby="Courier lobby",Intermission="Race opens soon",Voting="Map voting",Preparation="Course loading",Countdown="Race starting",Race="Race in progress",Results="Race results",Returning="Returning to lobby"})[state.stage]
		details.Text=status.."    /    ◈ "..coins.." coins"
		details.TextColor3=mint
		fill.Size=UDim2.fromScale(0,1)
	end
	play.Text=(state.queued or state.practiceQueued) and "Cancel" or "Play"
	local showShove=racing and state.stage=="Race" and race.zone and not state.practice and not state.solo and not state.result and race.recover<=current
	shove.Visible=showShove==true
	zoneLabel.Visible=shove.Visible
	local cd=math.max(0,math.ceil(race.cooldown-current))
	shove.Text=cd>0 and ("%ds"):format(cd) or "SHOVE"
	shove.BackgroundColor3=cd>0 and dark or orange
	shove.TextColor3=cd>0 and white or navy
	if racing and state.stage=="Countdown" then
		local count=math.max(1,math.ceil(left))
		callout.Visible=true
		callout.Text=tostring(count)
		if lastCount~=count then lastCount=count; Audio.play("Countdown") end
	elseif racing and current<showGo then
		callout.Visible=true
		callout.Text="GO!"
	elseif racing and race.recover>current then
		callout.Visible=true
		callout.Text=("Fresh egg in %ds"):format(math.ceil(race.recover-current))
		callout.TextSize=30
	else
		callout.Visible=false
		callout.TextSize=46
	end
end)

Input:BindAction("CourierCloseMenu",function(_,status)
	if not tab then return Enum.ContextActionResult.Pass end
	if status==Enum.UserInputState.Begin then setTab(nil) end
	return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.ButtonB)

Audio.setLobby(true)
fire("hello")
