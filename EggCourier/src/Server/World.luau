local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Levels = require(Shared.Levels)
local EggModel = require(Shared.EggModel)
local Obstacles = require(script.Parent.Obstacles)
local W = {}
local rgb = Color3.fromHex
local ink, cream, yellow = rgb("242855"), rgb("fff8da"), rgb("ffdc53")
local green, aqua, pink = rgb("8ce65a"), rgb("36d6ec"), rgb("fb5791")
local lane = {rgb("38c988"), rgb("4dc7ed"), rgb("ffa445"), rgb("a67aff"), rgb("ff7299"), rgb("55cfac")}
local P = Obstacles.part

local function box(parent, name, x, y, z, w, h, d, color, solid)
	return P(parent, name, Vector3.new(w,h,d), CFrame.new(x,y,z), color, solid == true)
end

local function billboard(parent, text, width, height, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(width,height)
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = 175
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel", gui)
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundColor3 = ink
	label.BackgroundTransparency = 0.12
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color or cream
	local corner = Instance.new("UICorner", label)
	corner.CornerRadius = UDim.new(0.2,0)
	return label
end

local function arch(model, x, z, width, title, color)
	for _, dir in {-1, 1} do
		box(model, "Portal pillar", x + dir * width / 2, 4, z, 2.1, 8, 2.1, color)
		box(model, "Pillar stripe", x + dir * width / 2, 1.3, z, 2.2, 0.8, 2.2, cream)
	end
	local bar = box(model, "Portal marquee", x, 8, z, width+2.2, 2, 2, ink)
	billboard(bar, title, width, 3, Vector3.new(0,1,0), color)
	return bar
end

local function checker(parent, x, z, width)
	for i = 1, 12 do
		for row = 1, 2 do
			box(parent,"Checker",x-width/2+(i-0.5)*width/12,0.035,z+row-1.5,width/12,0.065,1,(i+row)%2 == 0 and cream or ink)
		end
	end
end

local function scenery(model, x, z, seed)
	local random = Random.new(seed)
	for i = 1, 10 do
		local tx = x + random:NextNumber(-17,17)
		local tz = z + random:NextNumber(-25,25)
		local h = random:NextNumber(4,10)
		box(model,"Tree trunk",tx,-4+h/2,tz,1,h,1,rgb("ae7951"))
		P(model,"Meadow canopy",Vector3.new(h,h*0.85,h),CFrame.new(tx,-4+h,tz),i%2 == 0 and green or rgb("4cc97c"),false,Enum.PartType.Ball)
	end
end

function W.lobby(action)
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.Ambient = rgb("a4a0c5")
	Lighting.OutdoorAmbient = rgb("adbcdb")
	local air = Instance.new("Atmosphere", Lighting)
	air.Density = 0.23
	air.Haze = 0.65
	air.Color = rgb("d0e7ff")
	local m = workspace:FindFirstChild("CourierLobby")
	if not m then
		m = Instance.new("Folder")
		m.Name = "CourierLobby"
		m.Parent = workspace
	end
	box(m,"Grass island",0,-3,0,125,5,112,green,true)
	if not m:FindFirstChild("Stage floor") then
		box(m,"Stage floor",0,-0.75,0,91,1.5,74,rgb("4b84df"),true)
	end
	for x = -42,42,7 do box(m,"Inlaid tile",x,0.02,0,0.08,0.035,74,rgb("669cec")) end
	for z = -35,35,7 do box(m,"Inlaid tile",0,0.02,z,91,0.035,0.08,rgb("669cec")) end
	box(m,"Golden plinth",0,0.9,9,15,1.8,12,ink,true)
	box(m,"Golden rim",0,1.9,9,12,0.25,9,yellow,true)
	local egg = EggModel.build("Golden",7,true)
	egg:PivotTo(CFrame.new(0,6.6,9))
	egg.Parent = m
	local marquee = arch(m,0,16,35,"DON’T CRACK THE EGG!",yellow)
	for i = -7,7 do box(m,"Marquee bulb",i*2.35,8.7,14.95,0.35,0.35,0.18,i%2==0 and pink or yellow) end
	billboard(marquee,"GREEN MEADOWS  /  COURIER ARENA",27,1.7,Vector3.new(0,-2,0),aqua)
	local spawn = m:FindFirstChild("CourierSpawn")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "CourierSpawn"
		spawn.Size = Vector3.new(12,0.25,8)
		spawn.Position = Vector3.new(0,0.14,-22)
		spawn.Color = aqua
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Anchored = true
		spawn.Parent = m
	end
	local function portal(x,z,text,key,color)
		arch(m,x,z,11,text,color)
		local pad = box(m,text,x,0.3,z,12,0.6,8,color,true)
		local prompt = Instance.new("ProximityPrompt",pad)
		prompt.ActionText = text
		prompt.ObjectText = "Courier Arena"
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position-pad.Position).Magnitude <= 12 then action(player,key) end
		end)
	end
	portal(-29,-4,"RACE QUEUE","queue",aqua)
	portal(29,-4,"PRACTICE","practice",green)
	portal(-29,23,"EGG SHOP","Shop",pink)
	portal(29,23,"GREEN MEADOWS","Courses",yellow)
	local practice = {model = m, obstacles = {}}
	box(m,"Practice deck",29,0.2,-22,22,0.4,17,rgb("815de3"),true)
	Obstacles.add(practice,"sweep",Vector3.new(29,0.4,-22),1,{damage = false, size = Vector3.new(15,0.9,1.3)})
	local board = box(m,"Server leaderboard",0,6,34,22,11,1,ink)
	local gui = Instance.new("SurfaceGui",board)
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 32
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local text = Instance.new("TextLabel",gui)
	text.Size = UDim2.fromScale(1,1)
	text.BackgroundTransparency = 1
	text.TextColor3 = yellow
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	local podium = {}
	for i = 1,3 do
		local x,z,h = (i-2)*7,27,4-i
		box(m,"Podium",x,h/2,z,6,h,5,lane[i],true)
		local sign = box(m,"Podium marker",x,h+0.2,z,1,0.2,1,cream)
		podium[i] = billboard(sign,tostring(i),6,1.4,Vector3.new(0,1.8,0),yellow)
	end
	for _, x in {-54,54} do scenery(m,x,0,100+x) end
	return spawn.Position + Vector3.new(0,3.56,0), practice, text, podium
end

function W.course(level, x, z)
	local spec = Levels[level]
	local model = Instance.new("Model")
	model.Name = spec.name
	local c = {model=model, x=x, z=z, checks={}, obstacles={}, zones={}, length=#spec.stations*60+12}
	local function deck(rel, length, width, color, ox)
		return box(model,"Course deck",x+(ox or 0),-0.85,z+rel,width,1.7,length,color,true)
	end
	deck(-2,28,32,ink)
	arch(model,x,z-10,29,spec.name,yellow)
	local pool = box(model,"Splash pool",x,-10,z+c.length/2,64,1,c.length+38,rgb("3bbcdf"))
	pool.Material = Enum.Material.Glass
	pool.Transparency = 0.14
	for _, side in {-1,1} do
		box(model,"Meadow bank",x+side*54,-12,z+c.length/2,42,12,c.length+55,green,true)
		for i=1,math.ceil(c.length/75) do scenery(model,x+side*53,z+i*63-35,i+side*7+level*20) end
		for row=1,3 do
			box(model,"Spectator bleachers",x+side*(23+row*2),row*0.6-1,z+18,2,row*1.2,33,lane[row],true)
		end
	end
	for i, station in spec.stations do
		local start = 12+(i-1)*60
		local color = lane[i]
		for j, kind in station do
			local middle = start + 11.5 + (j-1)*23
			local center = Vector3.new(x,0,z+middle)
			if kind == "moving" or kind == "tilt" or kind == "beam" then
				deck(middle-8.5,6,24,color)
				deck(middle+8.5,6,24,color)
				Obstacles.add(c,kind,center,i+j*0.55)
			else
				deck(middle,23,kind == "zone" and 24 or 26,color)
				if kind == "zone" then
					for _, side in {-1,1} do
						local edge=box(model,"Crack Zone border",x+side*11.6,0.055,z+middle,0.65,0.11,23,rgb("ff6930"))
						edge.Material = Enum.Material.Neon
					end
					arch(model,x,z+middle-9,22,"CRACK ZONE",rgb("ff8a47"))
					table.insert(c.zones,{z=z+middle, extent=10.5})
					Obstacles.add(c,"ball",center+Vector3.new(0,0,4),i+j,{range=7})
				else
					Obstacles.add(c,kind,center,i+j*0.55,{speed=Obstacles.definitions[kind].speed and Obstacles.definitions[kind].speed*(1+(level-1)*0.08)})
					for _, side in {-1,1} do
						box(model,"Hazard stripe",x+side*12.4,0.03,z+middle,0.55,0.055,22.8,yellow)
					end
				end
			end
		end
		local rel = start+53
		deck(rel,14,30,ink)
		checker(model,x,z+rel,28)
		if i < #spec.stations then
			local sign = box(model,"Checkpoint sign",x-13,2.4,z+rel,0.25,3,0.25,aqua)
			billboard(sign,("CHECKPOINT %d"):format(i),9,2.2,Vector3.new(0,1.6,0),aqua)
			table.insert(c.checks,z+rel)
		end
	end
	c.finish = z+c.length+8
	deck(c.length+9,18,32,ink)
	arch(model,x,c.finish,29,"DELIVER HERE",yellow)
	checker(model,x,c.finish,31)
	model.Parent = workspace
	return c
end
return W
