local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local EggModel = require(Shared.EggModel)
local Levels = require(Shared.Levels)
local Obstacles = require(script.Parent.Obstacles)

local World = {}
local color = Color3.fromHex
local tar = color("28343b")
local dark = color("151f25")
local slate = color("3f5258")
local bone = color("f4ebd4")
local yolk = color("ffbb39")
local teal = color("4ed1b2")
local coral = color("f47758")
local silver = color("718990")

local function part(parent, name, size, cf, tint, material, solid, shape)
	local item = Obstacles.part(parent, name, size, cf, tint, solid == true, shape)
	item.Material = material or Enum.Material.SmoothPlastic
	if not solid then item.CanQuery = false end
	return item
end

local function box(parent, name, position, size, tint, material, solid)
	return part(parent,name,size,CFrame.new(position),tint,material,solid)
end

local function beam(parent, name, from, to, thickness, tint, material)
	return part(parent,name,Vector3.new(thickness,thickness,(to-from).Magnitude),
		CFrame.lookAt((from+to)/2,to),tint,material)
end

local function sign(parent, name, position, size, caption, fill, ink, font, face)
	local plate = box(parent,name,position,Vector3.new(size.X,size.Y,0.35),fill,Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Printed face"
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.PixelsPerStud = 36
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Name = "Lettering"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.055,0.10)
	label.Size = UDim2.fromScale(0.89,0.8)
	label.Font = font or Enum.Font.FredokaOne
	label.Text = caption
	label.TextColor3 = ink
	label.TextScaled = true
	label.Parent = gui
	return label
end

local function prompt(parent, position, caption, object, key, action)
	local marker = box(parent,object.." prompt",position,Vector3.new(1,1,1),tar)
	marker.Transparency = 1
	local input = Instance.new("ProximityPrompt")
	input.ActionText = caption
	input.ObjectText = object
	input.MaxActivationDistance = 10
	input.RequiresLineOfSight = false
	input.Parent = marker
	input.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position-position).Magnitude <= 12 then action(player,key) end
	end)
end

local function platform(parent, name, x, z, width, depth, surface, trim)
	box(parent,name.." base",Vector3.new(x,0.21,z),Vector3.new(width,0.42,depth),trim,Enum.Material.Metal,true)
	box(parent,name.." deck",Vector3.new(x,0.48,z),Vector3.new(width-0.58,0.18,depth-0.58),surface,Enum.Material.Concrete,true)
end

local function runway(parent)
	box(parent,"Launch lane",Vector3.new(0,0.024,-7),Vector3.new(22,0.048,59),dark,Enum.Material.Asphalt)
	for _, side in {-1,1} do
		box(parent,"Lane edge",Vector3.new(side*10.8,0.052,-7),Vector3.new(0.26,0.025,59),yolk)
		for z=-30,19,7 do
			box(parent,"Lane lamp",Vector3.new(side*11.7,0.13,z),Vector3.new(0.75,0.26,0.7),yolk,Enum.Material.Neon)
		end
	end
	for z=-26,15,8 do
		for _, side in {-1,1} do
			part(parent,"Runway chevron",Vector3.new(0.28,0.026,4.2),
				CFrame.new(side*1.45,0.061,z)*CFrame.Angles(0,side*math.rad(45),0),bone)
		end
	end
end

local function crate(parent, x, z, width, tint)
	box(parent,"Freight crate",Vector3.new(x,width/2,z),Vector3.new(width,width,width),tint,Enum.Material.WoodPlanks)
	for _, side in {-1,1} do
		box(parent,"Crate band",Vector3.new(x+side*width*0.27,width/2,z),
			Vector3.new(0.27,width+0.12,width+0.12),dark,Enum.Material.Metal)
	end
end

local function railing(parent, x, fromZ, toZ)
	beam(parent,"Safety rail",Vector3.new(x,2.65,fromZ),Vector3.new(x,2.65,toZ),0.18,yolk,Enum.Material.Metal)
	beam(parent,"Safety rail",Vector3.new(x,1.35,fromZ),Vector3.new(x,1.35,toZ),0.12,silver,Enum.Material.Metal)
	for z=fromZ,toZ,6 do
		box(parent,"Rail post",Vector3.new(x,1.45,z),Vector3.new(0.27,2.9,0.27),slate,Enum.Material.Metal)
	end
	-- A single invisible wall keeps the deck edge safe without joining rail pieces into colliders.
	local barrier = box(parent,"Deck barrier",Vector3.new(x,3,(fromZ+toZ)/2),
		Vector3.new(0.25,6,toZ-fromZ),slate,nil,true)
	barrier.Transparency = 1
end

local function landscaping(parent)
	local grass = color("4d745d")
	local rock = color("60605b")
	for _, side in {-1,1} do
		box(parent,"Raised planted verge",Vector3.new(side*58,0.65,0),Vector3.new(9,1.3,92),grass,Enum.Material.Grass,true)
		for z=-38,38,12 do
			local x = side*(58 + (z%5-2)*0.45)
			local height = 3.5 + (z%4)*0.5
			box(parent,"Windbreak trunk",Vector3.new(x,1.3+height/2,z),Vector3.new(0.6,height,0.6),color("77604c"),Enum.Material.Wood)
			for i=1,3 do
				local tint = ({color("35615c"),color("577d62"),color("6f8e6c")})[i]
				part(parent,"Sculpted tree canopy",Vector3.new(4.4-i*0.44,2.2,3.6-i*0.36),
					CFrame.new(x+side*(i-2)*0.63,height+i*0.7,z)*CFrame.Angles(0,i,math.rad(-side*20)),tint)
			end
		end
		railing(parent,side*52.6,-48,48)
	end
	box(parent,"Terminal foundation",Vector3.new(0,-4.2,1),Vector3.new(131,6.4,103),rock,Enum.Material.Slate)
	box(parent,"Terminal foundation band",Vector3.new(0,-1.8,1),Vector3.new(132,1.0,104),color("9f967e"),Enum.Material.Concrete)
	local random = Random.new(861)
	for i=1,15 do
		local x = (i-8)*7.6
		local depth = random:NextNumber(13,27)
		local height = random:NextNumber(6,13)
		part(parent,"Cliff shelf",Vector3.new(11,height,depth),
			CFrame.new(x,-8-height*0.4,random:NextNumber(-24,25))*CFrame.Angles(0,random:NextNumber(-0.5,0.5),random:NextNumber(-0.15,0.15)),
			if i%2 == 0 then rock else color("776e5e"),Enum.Material.Rock)
	end
end

local function beacon(parent, x, z)
	box(parent,"Mast foot",Vector3.new(x,1.1,z),Vector3.new(2.8,2.2,2.8),tar,Enum.Material.Metal,true)
	box(parent,"Apron light mast",Vector3.new(x,7.3,z),Vector3.new(0.62,12.6,0.62),slate,Enum.Material.Metal)
	local lightBar = box(parent,"Light bar",Vector3.new(x,13.7,z),Vector3.new(4,0.55,0.72),dark,Enum.Material.Metal)
	for offset=-1.4,1.4,1.4 do
		box(parent,"Apron lamp",Vector3.new(x+offset,13.65,z-0.35),Vector3.new(0.7,0.27,0.18),bone,Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = bone
	light.Brightness = 0.65
	light.Range = 16
	light.Parent = lightBar
end

local function hangar(parent, action)
	local hall = Instance.new("Folder")
	hall.Name = "Race Gate"
	hall.Parent = parent
	platform(hall,"Race launch",0,29,28,26,tar,yolk)
	for _, side in {-1,1} do
		box(hall,"Hangar wall",Vector3.new(side*13.65,5.8,29),Vector3.new(0.7,11.6,26),slate,Enum.Material.Metal,true)
		for _, z in {16,24,32,40} do
			box(hall,"Hangar ribs",Vector3.new(side*13.1,5.75,z),Vector3.new(0.35,11.5,0.55),dark,Enum.Material.Metal)
		end
		for y=2,9,3.5 do
			box(hall,"Gate light",Vector3.new(side*12.98,y,15.9),Vector3.new(0.48,2.1,0.35),yolk,Enum.Material.Neon)
		end
		part(hall,"Hangar roof",Vector3.new(15,0.62,28),
			CFrame.new(side*7,12.25,29)*CFrame.Angles(0,0,side*math.rad(-11)),dark,Enum.Material.Metal,true)
		box(hall,"Runway guide",Vector3.new(side*10.7,0.59,28),Vector3.new(0.16,0.04,22),yolk)
		crate(hall,side*10.5,37,2.6,yolk)
	end
	box(hall,"Gate backing",Vector3.new(0,5.8,41.72),Vector3.new(27,11.6,0.6),tar,Enum.Material.Metal,true)
	for x=-9,9,3 do
		box(hall,"Gate interior panel",Vector3.new(x,5.1,41.36),Vector3.new(2.8,9.2,0.28),slate,Enum.Material.Metal)
	end
	box(hall,"Gate sign girder",Vector3.new(0,9.3,15.8),Vector3.new(27,0.52,0.68),dark,Enum.Material.Metal)
	sign(hall,"Gate identifier",Vector3.new(0,9.3,15.3),Vector2.new(17,2.6),"RACE GATE",yolk,dark)
	sign(hall,"Terminal title",Vector3.new(0,15.6,15.15),Vector2.new(32,3.3),"DON’T CRACK THE EGG!",dark,bone)
	for _, side in {-1,1} do
		beam(hall,"Marquee mount",Vector3.new(side*12,11.66,16.0),Vector3.new(side*12,16.7,15.6),0.55,slate,Enum.Material.Metal)
		box(hall,"Title trim",Vector3.new(side*16.6,15.6,15.15),Vector3.new(0.45,3.3,0.35),coral,Enum.Material.Metal)
	end

	box(hall,"Roof cradle",Vector3.new(0,13.7,26),Vector3.new(11,1.3,8),slate,Enum.Material.Metal)
	box(hall,"Roof cradle trim",Vector3.new(0,14.4,26),Vector3.new(10,0.35,7.5),yolk,Enum.Material.Metal)
	local trophy = EggModel.build("Golden",8,true)
	trophy.Name = "Terminal trophy"
	trophy:PivotTo(CFrame.new(0,20,24)*CFrame.Angles(0,0,math.rad(-14)))
	trophy.Parent = hall
	for _, side in {-1,1} do
		beam(hall,"Cradle bracket",Vector3.new(side*5.2,14.3,23),Vector3.new(side*4.2,18,23),0.44,dark,Enum.Material.Metal)
	end
	prompt(hall,Vector3.new(0,3,19),"Enter race","Race Gate","queue",action)
end

local function shop(parent, action)
	local kiosk = Instance.new("Folder")
	kiosk.Name = "Egg Locker"
	kiosk.Parent = parent
	local x,z = -37,-13
	platform(kiosk,"Market stall",x,z,22,16,slate,teal)
	box(kiosk,"Back wall",Vector3.new(x,4.2,z+7.4),Vector3.new(21,8.4,0.55),color("246c66"),Enum.Material.Metal,true)
	for _, side in {-1,1} do
		box(kiosk,"Market post",Vector3.new(x+side*10.2,4.4,z-3.5),Vector3.new(0.5,8.8,0.55),dark,Enum.Material.Metal)
		box(kiosk,"Market showcase",Vector3.new(x+side*7.1,1.62,z+2.4),Vector3.new(5.4,2.12,3.1),dark,Enum.Material.Metal,true)
		box(kiosk,"Showcase lighting",Vector3.new(x+side*7.1,2.75,z+2.4),Vector3.new(5.1,0.16,2.9),teal,Enum.Material.Neon)
	end
	for i=1,11 do
		part(kiosk,"Market awning",Vector3.new(1.95,0.24,8.2),
			CFrame.new(x+(i-6)*1.95,8.8,z)*CFrame.Angles(math.rad(-12),0,0),
			if i%2 == 0 then teal else bone,Enum.Material.Fabric)
	end
	box(kiosk,"Awning valance",Vector3.new(x,8.8,z-4.75),Vector3.new(21,0.5,0.62),dark,Enum.Material.Metal)
	sign(kiosk,"Shop sign",Vector3.new(x,8.8,z-5.2),Vector2.new(15,2.3),"EGG LOCKER",teal,dark)
	for i, skin in {"Watermelon","Ninja","Frozen","Lava"} do
		local address = ({-8.2,-6.0,6.0,8.2})[i]
		local prop = EggModel.build(skin,1.6,true)
		prop:PivotTo(CFrame.new(x+address,3.85,z+2.4)*CFrame.Angles(0,i*0.7,0))
		prop.Parent = kiosk
	end
	prompt(kiosk,Vector3.new(x,2.5,z-3.7),"Eggs and reward boxes","Egg Locker","Shop",action)
end

local function warmup(parent, action)
	local zone = Instance.new("Folder")
	zone.Name = "Warmup Bay"
	zone.Parent = parent
	local x,z = 37,-13
	platform(zone,"Warmup mat",x,z,23,19,tar,coral)
	for _, side in {-1,1} do
		box(zone,"Warmup uprights",Vector3.new(x+side*10.6,3.8,z+1),Vector3.new(0.7,7.6,0.7),slate,Enum.Material.Metal)
		box(zone,"Warmup side mat",Vector3.new(x+side*8.1,0.86,z+2),Vector3.new(2.6,0.58,7.2),coral,Enum.Material.Rubber,true)
	end
	for i=1,5 do
		local height = 0.22 + i*0.14
		box(zone,"Footwork block",Vector3.new(x+5.5,0.57+height/2,z+11.5-i*1.9),Vector3.new(1,height,1.45),
			if i%2 == 0 then yolk else coral,Enum.Material.Rubber,true)
	end
	box(zone,"Warmup sign girder",Vector3.new(x,7.0,z+1),Vector3.new(22,0.45,0.74),slate,Enum.Material.Metal)
	sign(zone,"Warmup banner",Vector3.new(x,7.0,z+0.45),Vector2.new(18,2.3),"WARMUP BAY",coral,dark)
	for i=1,19 do
		local offset = (i-10)*1.12
		part(zone,"Hazard print",Vector3.new(0.58,0.04,0.85),
			CFrame.new(x+offset,0.59,z-8.5)*CFrame.Angles(0,math.rad(25),0),yolk)
	end
	local demo = {model = zone, obstacles = {}}
	Obstacles.add(demo,"sweep",Vector3.new(x-1.8,0.58,z+3.0),1,{damage=false,size=Vector3.new(10,0.75,0.9),speed=1.9})
	prompt(zone,Vector3.new(x,2.5,z-5.1),"Start practice","Warmup Bay","practice",action)
	return demo
end

local function islandDesk(parent, action)
	local display = Instance.new("Folder")
	display.Name = "Island Atlas"
	display.Parent = parent
	local tint = color("96afe4")
	local x,z = 36,25
	platform(display,"Atlas platform",x,z,25,17,tar,tint)
	box(display,"Atlas backboard",Vector3.new(x,4.4,z+7.6),Vector3.new(24,8.8,0.5),slate,Enum.Material.Metal,true)
	sign(display,"Atlas sign",Vector3.new(x,7.4,z+7.15),Vector2.new(20,2.8),"ISLAND ATLAS",tint,dark)
	box(display,"Model table",Vector3.new(x,1.95,z+2.4),Vector3.new(22,2.8,5.4),dark,Enum.Material.Metal,true)
	local islandColors = {color("729b4a"),coral,color("8bebf1"),color("b585ec"),color("c6a47a")}
	local islands = {}
	local seen = {}
	for _, level in ipairs(Levels) do
		local island = level.island
		if island and not seen[island] then
			table.insert(islands,island)
			seen[island] = true
		end
	end
	for i, island in islands do
		local pos = x+(i-(#islands+1)/2)*4.32
		local islandColor = islandColors[i] or tint
		local center = Vector3.new(pos,3.5,z+2.6)
		box(display,"Model island base",center,Vector3.new(4.08,0.32,3.8),islandColor,Enum.Material.Slate)
		if i == 1 then
			box(display,"Mini course",center+Vector3.new(0,0.72,0),Vector3.new(2.8,0.94,1.65),yolk,Enum.Material.Fabric)
			box(display,"Mini finish arch",center+Vector3.new(1.4,1.48,0),Vector3.new(0.26,2.1,1.68),coral)
		elseif i == 2 then
			part(display,"Foundry volcano",Vector3.new(2.1,2.6,1.85),
				CFrame.new(center+Vector3.new(0,1.12,0))*CFrame.Angles(0,0,-0.24),slate,Enum.Material.Basalt)
			box(display,"Foundry lava",center+Vector3.new(0,2.47,0),Vector3.new(1.45,0.12,1.28),coral,Enum.Material.Neon)
		elseif i == 3 then
			for j=-1,1 do
				part(display,"Glacier shard",Vector3.new(0.85,2.0-math.abs(j)*0.45,1.1),
					CFrame.new(center+Vector3.new(j*0.8,0.97,0))*CFrame.Angles(0,0,math.rad(j*24)),islandColor,Enum.Material.Ice)
			end
		elseif i == 4 then
			part(display,"Orbital relay",Vector3.new(1.8,1.8,1.8),
				CFrame.new(center+Vector3.new(0,1.42,0)),islandColor,Enum.Material.Neon,false,Enum.PartType.Ball)
			beam(display,"Relay antenna",center+Vector3.new(0,0.18,0),center+Vector3.new(0,1.25,0),0.27,bone)
		else
			for _, side in {-1,1} do
				box(display,"Ruins altar column",center+Vector3.new(side*1.05,0.85,0),Vector3.new(0.42,1.55,0.53),
					islandColor,Enum.Material.Sandstone)
			end
			box(display,"Ruins altar lintel",center+Vector3.new(0,1.61,0),Vector3.new(2.73,0.37,0.84),islandColor,Enum.Material.Sandstone)
			local relic = EggModel.build("Golden",0.63,true)
			relic.Name = "Model relic"
			relic:PivotTo(CFrame.new(center+Vector3.new(0,0.65,-0.62)))
			relic.Parent = display
		end
		sign(display,island.." nameplate",Vector3.new(pos,1.92,z-0.58),Vector2.new(4.1,1.25),island,dark,islandColor,Enum.Font.GothamBold)
	end
	prompt(display,Vector3.new(x,2.5,z-3.6),"View courses","Island Atlas","Courses",action)
end

local function scoreboard(parent)
	local room = Instance.new("Folder")
	room.Name = "Winners' Circle"
	room.Parent = parent
	local x,z = -36,26
	platform(room,"Podium floor",x,z,25,18,slate,yolk)
	box(room,"Scoreboard stand",Vector3.new(x,4.3,z+7.8),Vector3.new(24,8.6,0.9),dark,Enum.Material.Metal,true)
	for _, side in {-1,1} do
		box(room,"Board rails",Vector3.new(x+side*11.95,4.3,z+7.2),Vector3.new(0.5,8.6,0.34),yolk,Enum.Material.Metal)
	end
	local board = sign(room,"Scoreboard",Vector3.new(x,5.3,z+7.0),Vector2.new(22,6.0),
		"SERVER LEADERS",dark,bone,Enum.Font.RobotoMono)
	local ranks = {}
	for place, config in {{0,3.0,yolk},{-7,2.15,teal},{7,1.45,coral}} do
		local stepX = x+config[1]
		local height = config[2]
		box(room,"Podium step",Vector3.new(stepX,height/2+0.56,z+0.8),Vector3.new(6.5,height,5.8),
			config[3],Enum.Material.Metal,true)
		box(room,"Podium tread",Vector3.new(stepX,height+0.6,z+0.8),Vector3.new(6.3,0.14,5.6),dark,Enum.Material.Rubber)
		local plate = sign(room,"Podium place",Vector3.new(stepX,0.53+height*0.56,z-2.25),Vector2.new(6.25,math.min(0.98,height-0.2)),
			tostring(place),dark,bone,Enum.Font.GothamBold)
		ranks[place] = plate
	end
	return board,ranks
end

function World.lobby(action)
	Lighting.ClockTime = 15.3
	Lighting.Brightness = 2.1
	Lighting.Ambient = color("7a8286")
	Lighting.OutdoorAmbient = color("bbc6cc")
	local air = Instance.new("Atmosphere")
	air.Name = "Terminal sky"
	air.Density = 0.23
	air.Haze = 0.72
	air.Color = color("d3e9f7")
	air.Decay = color("90aebb")
	air.Parent = Lighting

	local authored = workspace:FindFirstChild("CourierLobby")
	if not authored then
		authored = Instance.new("Folder")
		authored.Name = "CourierLobby"
		authored.Parent = workspace
	end
	if not authored:FindFirstChild("Stage floor") then
		box(authored,"Stage floor",Vector3.new(0,-1,0),Vector3.new(130,2,100),tar,Enum.Material.Asphalt,true)
	end
	local spawn = authored:FindFirstChild("CourierSpawn")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "CourierSpawn"
		spawn.Size = Vector3.new(12,0.22,7)
		spawn.Position = Vector3.new(0,0.11,-36)
		spawn.Transparency = 1
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Anchored = true
		spawn.Parent = authored
	end

	local terminal = Instance.new("Model")
	terminal.Name = "Shell Yard Terminal"
	terminal.Parent = authored
	runway(terminal)
	landscaping(terminal)
	for _, side in {-1,1} do
		beacon(terminal,side*16.5,-30)
		crate(terminal,side*47,-35,3.0,if side == 1 then coral else teal)
		crate(terminal,side*43,-37,2.2,yolk)
		box(terminal,"Apron stripe",Vector3.new(side*31,0.055,-27),Vector3.new(30,0.045,0.18),bone)
		box(terminal,"Apron stripe",Vector3.new(side*31,0.055,6),Vector3.new(30,0.045,0.18),bone)
	end
	hangar(terminal,action)
	shop(terminal,action)
	local demo = warmup(terminal,action)
	islandDesk(terminal,action)
	local board, podium = scoreboard(terminal)
	return spawn.Position+Vector3.new(0,3.56,0),demo,board,podium
end

return World
