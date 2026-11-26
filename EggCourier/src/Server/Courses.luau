local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Levels = require(Shared.Levels)
local Obstacles = require(script.Parent.Obstacles)

local Courses = {}
local rgb = Color3.fromHex
local v = Vector3.new
local ink, cream = rgb("151f26"), rgb("ffedca")
local red, amber = rgb("ff4c42"), rgb("ffc455")

local tones = {
	temple={"668270","d4ab6d","30664c"}, pirate={"93674b","c59863","17667f"},
	prehistoric={"62734b","97b867","4e8b64"}, factory={"975a82","ce9db7","78526c"},
	frozen={"81c6df","bde9f0","4c8fb7"}, cloud={"887dc0","b5b5e4","716ba8"},
	neon={"423c67","62508b","252849"}, galactic={"494877","7271b8","1d2446"},
}

local function colorsFor(world)
	local tonesForWorld = tones[world.key]
	return {
		deck=rgb(tonesForWorld[1]), rock=rgb(tonesForWorld[2]), ground=rgb(tonesForWorld[3]),
		rim=rgb(world.accent), lane=rgb("b0f5c3"), hazard=rgb("ff815e"),
	}
end

local function part(c, name, px, py, pz, size, color, solid, shape, angles)
	local cf = CFrame.new(c.x+px,py,c.z+pz)
	local p = Obstacles.part(c.model,name,size,angles and cf*angles or cf,color,solid == true,shape)
	if not solid then p.CanQuery = false end
	return p
end

local function deck(c, first, last, width, offset, top, color)
	return part(c,"Runway",offset or 0,(top or 0)-0.9,(first+last)/2,v(width,1.8,last-first),color or c.colors.deck,true)
end

local function light(c, name, px, py, pz, size, color, shape, angles)
	local p = part(c,name,px,py,pz,size,color,false,shape,angles)
	p.Material = Enum.Material.Neon
	p.CastShadow = false
	return p
end

local function marking(c, z, width, top, color)
	part(c,"Tread edge",0,top+0.025,z,v(width,0.05,0.24),color)
end

local function plaque(c, text, px, py, pz, width, height, color)
	local board = part(c,"Course sign",px,py,pz,v(width,height,0.38),ink)
	for _, face in {Enum.NormalId.Front,Enum.NormalId.Back} do
		local surface = Instance.new("SurfaceGui",board)
		surface.Face = face
		surface.CanvasSize = Vector2.new(700,100)
		surface.LightInfluence = 0
		local words = Instance.new("TextLabel",surface)
		words.Size = UDim2.fromScale(0.94,0.8)
		words.Position = UDim2.fromScale(0.03,0.1)
		words.BackgroundTransparency = 1
		words.TextColor3 = color
		words.Font = Enum.Font.FredokaOne
		words.Text = text
		words.TextScaled = true
	end
end

local function gate(c, text, z, width, color)
	for _, side in {-1,1} do
		part(c,"Gate stanchion",side*(width/2+0.6),4,z,v(1.05,8,1.05),ink)
		light(c,"Gate tube",side*(width/2+0.6),4,z-0.58,v(0.26,7.2,0.12),color)
	end
	plaque(c,text,0,8,z,width+2.1,2.25,color)
end

local function finishGate(c)
	local z = c.length+3.4
	local color = c.colors.rim
	for _, side in {-1,1} do
		part(c,"Finish tower",side*15.15,5.5,z,v(1.2,11,1.5),ink)
		light(c,"Finish tower lamp",side*15.15,5.5,z-0.78,v(0.29,9.25,0.1),color)
	end
	local board = part(c,"Finish scoreboard",0,11.85,z,v(31.4,5.65,0.6),ink)
	for _, side in {-1,1} do
		light(c,"Scoreboard trim",0,11.85+side*2.6,z,v(30.55,0.14,0.72),color)
	end
	c.finishDisplay = {}
	for _, face in {Enum.NormalId.Front,Enum.NormalId.Back} do
		local surface = Instance.new("SurfaceGui",board)
		surface.Face = face
		surface.CanvasSize = Vector2.new(850,153)
		surface.LightInfluence = 0
		surface.MaxDistance = 155
		local title = Instance.new("TextLabel",surface)
		title.Name = "Finish heading"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.04,0.065)
		title.Size = UDim2.fromScale(0.92,0.39)
		title.Text = "FINISH"
		title.TextColor3 = cream
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		local counter = Instance.new("TextLabel",surface)
		counter.Name = "Finish slots"
		counter.BackgroundTransparency = 1
		counter.Position = UDim2.fromScale(0.06,0.51)
		counter.Size = UDim2.fromScale(0.88,0.38)
		counter.Text = "-- / -- IN"
		counter.TextColor3 = color
		counter.Font = Enum.Font.GothamBold
		counter.TextScaled = true
		table.insert(c.finishDisplay,counter)
	end
end

local ball = Enum.PartType.Ball
local cylinder = Enum.PartType.Cylinder
local vertical = CFrame.Angles(0,0,math.pi/2)
local deckWidth, arenaWidth = 34, 30
local bayTint = rgb("a1e6b6")

local function bay(c,z,width)
	part(c,"Safe waiting stripe",0,0.036,z,v(width,0.072,1.2),bayTint)
	for _, side in {-1,1} do
		light(c,"Refuge lamp",side*(width/2+0.4),0.3,z,v(0.38,0.56,0.72),c.colors.lane)
	end
end

local function hazard(c,kind,x,y,z,phase,settings)
	local stats = table.clone(settings or {})
	local definition = Obstacles.definitions[kind]
	if definition.speed and kind ~= "wind" and kind ~= "slide" and kind ~= "launch" and kind ~= "gravity" then
		stats.speed = (stats.speed or definition.speed)*c.pace
	end
	stats.color = stats.color or c.colors.hazard
	return Obstacles.add(c,kind,v(c.x+x,y,c.z+z),phase,stats)
end

local function ledge(c,first,last,width,x,top)
	deck(c,first,last,width,x,top,c.colors.deck)
	local mid = (first+last)*0.5
	for _, side in {-1,1} do
		part(c,"Platform lip",x+side*(width*0.5-0.18),top+0.028,mid,v(0.3,0.055,last-first),c.colors.rim)
	end
end

local function ramp(c,x,first,last,width,bottom,top)
	local span, rise = last-first, top-bottom
	local angle = math.atan2(-rise,span)
	local cf = CFrame.Angles(angle,0,0)
	part(c,"Sloped runway",x,(top+bottom)*0.5-0.55,(first+last)*0.5,
		v(width,1.1,math.sqrt(span*span+rise*rise)+0.3),c.colors.deck,true,nil,cf)
end

local function rideDetail(c,ride,name,offset,size,tint,shape,angles)
	local base = ride.CFrame*CFrame.new(offset)
	local detail = Obstacles.part(c.model,name,size,angles and base*angles or base,tint,false,shape)
	detail.CanQuery, detail.CastShadow, detail.Massless = false, false, true
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = ride, detail, detail
	detail.Anchored = false
end

local function rail(c,x,first,last)
	for _, side in {-1,1} do
		part(c,"Cart rail",x+side*2.75,-1.36,(first+last)*0.5,v(0.24,0.24,last-first),c.colors.rim)
	end
	for row=first+2,last-2,5.4 do
		part(c,"Rail tie",x,-1.65,row,v(6.9,0.24,0.75),ink)
	end
end

local function flaggedLane(c,x,first,last,width)
	ledge(c,first,last,width,x,0)
	for row=first+2,last-2,10 do
		part(c,"Detour marker",x,0.035,row,v(1.5,0.07,1.25),c.colors.lane)
	end
end

local encounters = {}

function encounters.weave(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,4 do
		local side = if (i+variant)%2==0 then 1 else -1
		local row = z+9+i*(length-22)/5
		local height = i==2 and 3.2 or 4.8
		part(c,"Slalom barricade",side*6,height/2,row,v(17,height,3.15),c.colors.rock,true)
		part(c,"Barricade cap",side*6,height,row,v(17.3,0.28,3.4),c.colors.rim)
		bay(c,row-3.9,28)
	end
end

function encounters.sweepers(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+8+i*(length-20)/4
		local x = ((i+variant)%2==0 and -1 or 1)*6
		hazard(c,"sweep",x,0,row,i*1.9,{size=v(13.5,0.78,1.1),y=0.56,speed=1.04+i*0.11})
		part(c,"Sweep center",x,0.035,row,v(0.07,13.5,13.5),c.colors.rock,false,cylinder,vertical)
		bay(c,row-7.8,28)
	end
end

function encounters.rollers(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+7+i*(length-20)/4
		local x = ((i+variant)%2==0 and -1 or 1)*6
		hazard(c,"roller",x,0,row,i*2.07,{size=v(10.6,2.5,2.5),y=1.25,range=4.8,speed=1.33})
		bay(c,row-3.9,28)
	end
end

function encounters.bouncers(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+8+i*(length-22)/4
		local x = ((i+variant)%2==0 and -1 or 1)*4.8
		hazard(c,"ball",x,0,row,i*1.93,{size=v(6.1,6.1,6.1),y=3.05,range=6.6,bounce=1.85,speed=1.21})
		bay(c,row-5.1,28)
	end
end

function encounters.hammers(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+9+i*(length-22)/4
		local side = if (i+variant)%2==0 then 1 else -1
		part(c,"Hammer support",side*15.7,8,row,v(1.3,16,1.3),ink)
		part(c,"Hammer bracket",side*10.5,16,row,v(11,0.8,0.8),c.colors.rock)
		hazard(c,"pendulum",side*5.5,0,row,i*2.3,{size=v(5.2,5.2,5.2),range=6.2,speed=1.22})
		bay(c,row-4.8,28)
	end
end

function encounters.pistons(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,4 do
		local row = z+9+i*(length-24)/5
		local side = if (i+variant)%2==0 then 1 else -1
		part(c,"Hydraulic piston housing",side*14.7,2.6,row,v(3,5.2,4.5),ink)
		hazard(c,"foam",side*7.8,0,row,i*1.78,{size=v(9.6,4.2,2.1),y=2.1,range=5,speed=1.18})
		bay(c,row-3.7,28)
	end
end

function encounters.locks(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+9+i*(length-22)/4
		local side = if (i+variant)%2==0 then 1 else -1
		hazard(c,"gate",side*7.75,0,row,i*1.69,{size=v(14.5,5.4,1.2),y=2.7,color=c.colors.rim})
		part(c,"Door jamb",side*14.8,5,row,v(1.4,10,2.5),c.colors.rock,true)
		part(c,"Door lintel",side*7.6,10,row,v(15.2,1.2,2.45),c.colors.rock)
		part(c,"Fixed barrier", -side*6.5,2.45,row,v(12.8,4.9,1.2),c.colors.rock,true)
		bay(c,row-4.7,28)
	end
end

function encounters.hotFloor(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,4 do
		local row = z+9+i*(length-24)/5
		local x = ((i+variant)%2==0 and -1 or 1)*6.2
		hazard(c,"pulse",x,0,row,i*1.71,{size=v(17.4,0.22,4.45),period=5.28,open=1.54,color=ink})
		bay(c,row-4.6,28)
	end
end

function encounters.boulderLane(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,2 do
		local row = z+length*(0.28+(i-1)*0.43)
		local x = ((i+variant)%2==0 and -1 or 1)*5.45
		for _, side in {-1,1} do
			part(c,"Boulder refuge",x+side*8.3,0.07,row,v(3.15,0.14,13.4),c.colors.lane)
			part(c,"Carved boulder rail",x+side*6.3,0.2,row,v(0.33,0.4,18),c.colors.rock)
		end
		hazard(c,"boulder",x,0,row,i*3.9,{size=v(9.25,9.25,9.25),y=4.63,range=12.5,period=8,travel=3.35,color=c.colors.rock})
	end
end

function encounters.migration(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+9+i*(length-22)/4
		local side = if (i+variant)%2==0 then 1 else -1
		local x = side*4.5
		local moving = hazard(c,"sentry",x,0,row,i*2.24,{
			color=rgb("78a853"), size=v(7.8,5.2,5.55), y=2.6, period=9.1, range=9.4,
		})
		moving.part.Shape = ball
		moving.details = {}
		local function detail(name,dx,y,dz,size,tint)
			local object = part(c,name,x+dx,y,row+dz,size,tint,false,ball)
			table.insert(moving.details,{part=object,offset=CFrame.new(dx,y-2.6,dz)})
		end
		detail("Marching hatchling head",-3.8,4.25,0,v(3.2,3.1,3),rgb("92c85c"))
		detail("Marching hatchling eye",-4.6,4.8,-1.21,v(0.55,0.77,0.38),ink)
		detail("Marching hatchling tail",4.0,2.0,0,v(4.6,1.5,1.6),rgb("6d9b52"))
		for _, dx in {-1.7,1.6} do
			detail("Marching hatchling foot",dx,0.69,-1.65,v(1.8,1.3,1.7),rgb("5f884a"))
		end
		bay(c,row-4.8,28)
	end
end

function encounters.belts(c,z,length,variant)
	local span = (length-14)/3
	for i=1,3 do
		local first = z+7+(i-1)*span
		local row = first+span/2
		local side = if (i+variant)%2==0 then 1 else -1
		hazard(c,"conveyor",side*7.5,0,row,i,{size=v(15,1.4,span+0.05),speed=8.5,color=ink})
		hazard(c,"conveyor",-side*7.5,0,row,i,{size=v(15,1.4,span+0.05),speed=-4,color=c.colors.rock})
		for offset=-span/2+3,span/2-1,4 do
			part(c,"Belt arrow",side*7.5,0.032,row+offset,v(3.7,0.064,0.75),c.colors.lane)
		end
		hazard(c,"pulse",side*7.5,0,row+span/2-3.2,i*2.1,{size=v(11.8,0.22,2.9),period=4.75,open=1.28,color=ink})
	end
end

function encounters.rafter(c,z,length,variant)
	local side = if variant%2==0 then 1 else -1
	local x = side*7.9
	local start, finish = z+7, z+length-7
	rail(c,x,start,finish)
	local span = finish-start
	local ride = hazard(c,"moving",x,0,start+span/2,0.7*variant,{
		size=v(10.1,1.4,14.5), range=(span-13.4)/2, speed=0.46, axis=Vector3.zAxis, color=c.colors.rim,
	}).part
	local theme = c.worldKey
	for _, edge in {-1,1} do
		if theme == "temple" or theme == "prehistoric" or theme == "neon" then
			for _, axel in {-1,1} do
				rideDetail(c,ride,"Courier trolley wheel",v(edge*4.4,-0.85,axel*4.4),v(0.75,1.65,1.65),ink,cylinder)
			end
			rideDetail(c,ride,"Courier trolley rail",v(edge*4.95,1.12,0),v(0.45,0.73,13.8),c.colors.rock)
		elseif theme == "pirate" or theme == "factory" then
			rideDetail(c,ride,"Cargo ferry pontoon",v(edge*4.4,-0.52,0),v(2.45,2.1,13.5),c.colors.rock,ball)
			rideDetail(c,ride,"Cargo ferry trim",v(edge*5,1.08,0),v(0.42,0.6,13.4),ink)
		else
			rideDetail(c,ride,"Gondola shell",v(edge*4.75,0.02,0),v(1.15,2.9,13.7),c.colors.rock,ball)
			rideDetail(c,ride,"Gondola marker",v(edge*4.98,0.18,0),v(0.42,0.68,7.9),c.colors.lane)
		end
	end
	for i=1,4 do
		local pace = span/4
		local first = start+(i-1)*pace
		flaggedLane(c,-x+((i%2==0 and 1 or -1)*1.8),first,first+pace-(i==4 and 0 or 3.65),10.4)
	end
end

function encounters.balance(c,z,length,variant)
	local span = (length-14)/4
	for i=1,4 do
		local x = (if (i+variant)%2==0 then 1 else -1)*2.65
		local first = z+7+(i-1)*span
		local size = span-3.65
		hazard(c,"tilt",x,0,first+size/2,i*1.4,
			{size=v(13,1.4,size),range=0.2,speed=0.95,color=c.colors.rim})
		flaggedLane(c,12.4,first,first+span-(i==4 and 0 or 3.3),5.6)
	end
end

function encounters.carousel(c,z,length,variant)
	local span = (length-14)/3
	for i=1,3 do
		local row = z+7+(i-0.5)*span
		local x = (if (i+variant)%2==0 then 1 else -1)*2.3
		local diameter = span-2.45
		hazard(c,"spin",x,0,row,0,{size=v(1.4,diameter,diameter),speed=(i%2==0 and -1 or 1)*0.86,color=c.colors.rim})
		hazard(c,"sweep",x,0,row,i*1.67,{size=v(diameter-1.9,0.63,0.94),y=0.59,speed=0.98})
	end
	flaggedLane(c,-11.6,z+7,z+length-7,5.2)
end

function encounters.piers(c,z,length,variant)
	local span = (length-14)/4
	for i=1,4 do
		local x = (if (i+variant)%2==0 then 1 else -1)*2.85
		local first = z+7+(i-1)*span
		local top = ({0,0.75,1.35,0.5})[i]
		ledge(c,first,first+span-(i==4 and 0 or 3.4),13.15,x,top)
		part(c,"Pier support",x,-3.85,first+4.2,v(3.6,7,3.6),c.colors.rock)
		ledge(c,first,first+span-(i==4 and 0 or 2.7),6,11.7,0)
	end
end

function encounters.blink(c,z,length,variant)
	local span = (length-14)/4
	for i=1,4 do
		local row = z+7+(i-0.5)*span
		local x = (if (i+variant)%2==0 then 1 else -1)*2.25
		hazard(c,"vanish",x,0,row,i*1.1,{size=v(12,1.4,span-2.8),period=6.4,open=1.75,color=c.colors.rim})
		ledge(c,row-span/2,row+span/2-2.3,5.7,-11.95,0)
	end
end

function encounters.shoves(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	local row = z+length/2
	local width = 27
	for _, side in {-1,1} do
		light(c,"Crack Zone edge",side*width/2,0.045,row,v(0.3,0.09,length-24),red)
	end
	gate(c,"CRACK ZONE · SHOVES ENABLED",z+10,width,amber)
	table.insert(c.zones,{z=c.z+row,extent=length/2-12,width=width/2})
	bay(c,z+length-8,28)
end

function encounters.lifts(c,z,length,variant)
	local span = (length-14)/3
	for i=1,3 do
		local row = z+7+(i-0.5)*span
		local x = (if (i+variant)%2==0 then 1 else -1)*2.7
		hazard(c,"moving",x,0.67,row,i*1.85,
			{size=v(13.85,1.4,span-2.75),range=1.15,speed=0.91,axis=Vector3.yAxis,color=c.colors.rim})
		ledge(c,row-span/2,row+span/2-2.2,6.4,11.2,0)
		for _, side in {-1,1} do
			part(c,"Lift columns",x+side*7.7,2.55,row,v(0.65,8,0.65),c.colors.rock)
		end
	end
end

function encounters.gust(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local row = z+8+i*(length-21)/4
		local side = if (i+variant)%2==0 then 1 else -1
		hazard(c,"wind",side*4.5,0,row,i,{size=v(17,10,11),axis=Vector3.xAxis*-side,speed=19,color=c.colors.rim})
		for offset=-2,2,2 do
			light(c,"Gust direction dash",side*4.5+offset,0.051,row+offset*0.75,v(1.1,0.09,0.42),c.colors.rim)
		end
		part(c,"Windbreak",side*12,1.5,row,v(2.6,3,8.1),c.colors.rock,true)
		bay(c,row-6.25,28)
	end
end

function encounters.boost(c,z,length,variant)
	deck(c,z,z+length,arenaWidth)
	for i=1,3 do
		local side = if (i+variant)%2==0 then 1 else -1
		local row = z+8+i*(length-21)/4
		hazard(c,"launch",side*5.7,0,row-3.1,i,{size=v(6,0.44,5.8),y=0.22,speed=35,color=c.colors.lane})
		part(c,"Hop barrier",side*5.7,0.92,row+2,v(6.7,1.84,0.8),c.colors.rock,true)
		hazard(c,"pulse",-side*6,0,row+2,i*2.4,{size=v(11.1,0.22,3),period=5.15,open=1.23,color=ink})
		bay(c,row-7.1,28)
	end
end

function encounters.slide(c,z,length,variant)
	local side = if variant%2==0 then 1 else -1
	local x = side*6.6
	local first, top, last = z+7,z+length*0.34,z+length-7
	ramp(c,x,first,top,12.3,0,4.4)
	ramp(c,x,top,last,12.3,4.4,0)
	hazard(c,"slide",x,2,(top+last)/2,0,{size=v(10.4,9,last-top-2),speed=22,color=c.colors.rim})
	for _, sideEdge in {-1,1} do
		part(c,"Slide edge",x+sideEdge*5.9,2.2,(top+last)/2,v(0.34,0.32,last-top),c.colors.rim,false,nil,
			CFrame.Angles(math.atan2(4.4,last-top),0,0))
	end
	local span = (last-first)/3
	for i=1,3 do
		ledge(c,first+(i-1)*span,first+i*span-(i==3 and 0 or 3.4),10.6,-x+(i%2==0 and -1.7 or 1.7),0)
	end
end

function encounters.switchback(c,z,length,variant)
	local start, span = z+7,(length-14)/5
	for i=1,5 do
		local first = start+(i-1)*span
		local x = (if variant%2==0 then 1 else -1)*({0,4.6,7.3,4.6,0})[i]
		local top = ({0,1.6,3.35,1.6,0})[i]
		ledge(c,first,first+span-(i==5 and 0 or 1.65),15,x,top)
		part(c,"Climb column",x,-3.6,first+span/2,v(2.8,7,2.8),c.colors.rock)
	end
end

function encounters.ice(c,z,length,variant)
	local floor = deck(c,z,z+length,arenaWidth,0,0,rgb("a8d8e5"))
	floor.CustomPhysicalProperties = PhysicalProperties.new(1,0.135,0)
	floor.Material = Enum.Material.Ice
	for i=1,3 do
		local row = z+9+i*(length-24)/4
		local side = if (i+variant)%2==0 then 1 else -1
		hazard(c,"snowball",side*5.1,0,row,i*2.4,{range=7.8,speed=1.35,color=cream})
		part(c,"Grippy snow shelf",-side*8,0.08,row-1.5,v(8.4,0.16,7.9),cream,true)
	end
end

function encounters.gravity(c,z,length,variant)
	local first, span = z+7,(length-14)/4
	for i=1,4 do
		local row = first+(i-0.5)*span
		local x = (if (i+variant)%2==0 then 1 else -1)*3.25
		local top = (i%2)*1.15
		local size = span-3.45
		ledge(c,row-size/2,row+size/2,14,x,top)
		hazard(c,"gravity",x,top,row,i,{size=v(12,11,size),y=5.5,speed=41,color=c.colors.lane})
		light(c,"Lift field marker",x,top+0.048,row,v(0.09,5.6,5.6),c.colors.lane,cylinder,vertical)
	end
	flaggedLane(c,-12.6,z+7,z+length-7,4.3)
end

local chapters = {
	-- Each chapter places three differently authored encounters under one set piece.
	expedition = {"Expedition camp","weave","piers","pistons"},
	idolRoom = {"Open the sun vault","locks","carousel","hotFloor"},
	boulderRun = {"Boulder escape: use the side refuges","boulderLane","piers","boulderLane"},
	cartTracks = {"Minecart dispatch: ride or take the ledges","rafter","belts","rafter"},
	waterfall = {"Waterfall crossing","gust","balance","slide"},
	sunExit = {"The mountain opens","switchback","boost","locks"},
	rootway = {"Roots over the ravine","weave","balance","switchback"},
	floodgates = {"Floodgates: wait for the green signal","locks","hotFloor","slide"},
	relicGallery = {"Lantern gallery","pistons","switchback","hammers"},
	crackBridge = {"Expedition relay bridge","piers","shoves","balance"},
	turningDoors = {"Clockwork stone doors","locks","sweepers","carousel"},
	harbor = {"Coastal village and the hidden trapdoor","weave","piers","locks"},
	seaSlide = {"Cavern spillway","slide","locks","slide"},
	rigging = {"Cross the rigging","hammers","balance","gust"},
	ghostShip = {"The ship under the mountain","rafter","balance","hammers"},
	reefExit = {"Last boat through the sea gate","locks","rafter","boost"},
	smuggler = {"Smuggler's lookout","pistons","switchback","locks"},
	tidePools = {"Low tide crossings","blink","slide","piers"},
	fieldStation = {"Field research station","weave","lifts","pistons"},
	migration = {"Creature migration: watch the trail","migration","gust","migration"},
	researchLift = {"Lift to canopy command","lifts","switchback","belts"},
	fossilBasin = {"Fossil terraces","switchback","piers","boulderLane"},
	canopyExit = {"Get to the canopy rescue platform","gust","switchback","boost"},
	canopyLift = {"Ride the canopy lifts","lifts","gust","rafter"},
	candyWorks = {"Candy workshop conveyor","belts","bouncers","weave"},
	chocolateRiver = {"Chocolate river barge","slide","rafter","balance"},
	mixingRoom = {"Giant mixers","carousel","sweepers","belts"},
	frostingLine = {"Frosting presses","pistons","rollers","boost"},
	sugarExit = {"Catch the last delivery belt","belts","locks","boost"},
	furnace = {"Boiler test loop","hotFloor","locks","rollers"},
	caramelLift = {"Caramel cooling towers","lifts","balance","belts"},
	skiVillage = {"Alpine outpost","weave","slide","ice"},
	avalanche = {"Avalanche alleys","ice","boulderLane","ice"},
	iceCaves = {"Crystal caves","blink","locks","switchback"},
	gondola = {"Mountain gondola","rafter","lifts","gust"},
	frostSpan = {"Span over frostfall","balance","piers","ice"},
	summitExit = {"Final whiteout","ice","switchback","boost"},
	skyGarden = {"Floating gardens","piers","weave","gust"},
	gustGates = {"Forecast: strong crosswind","gust","locks","boost"},
	cloudSteps = {"Stairways in the clouds","switchback","blink","lifts"},
	airships = {"A fleet on the wind","rafter","gust","balance"},
	ringway = {"Ringway transit","carousel","piers","gravity"},
	skyExit = {"Sky bell finale","boost","gust","switchback"},
	rooftop = {"Roof garden sprint","switchback","piers","weave"},
	signalYard = {"Switchyard: watch signal bars","locks","hotFloor","belts"},
	maglev = {"Maglev train crossing","rafter","belts","pistons"},
	arcade = {"Arcade alleys","bouncers","blink","pistons"},
	overpass = {"Billboard overpass","lifts","switchback","gust"},
	neonExit = {"Race the city power surge","belts","hotFloor","boost"},
	orbitalDock = {"Orbital docking bay","locks","rafter","boost"},
	gravityLab = {"Gravity reboot in progress","gravity","blink","gravity"},
	airlock = {"Emergency pressure doors","locks","gust","hotFloor"},
	cargoSpin = {"Rotating cargo ring","carousel","balance","sweepers"},
	satellites = {"Satellite array","blink","piers","gravity"},
	launchExit = {"Escape shuttle launch","locks","boost","belts"},
	crownEntry = {"Championship mission control","sweepers","locks","boost"},
	crownFerry = {"Transfer to the gold capsule","rafter","gravity","carousel"},
	crownTower = {"Launch tower climb","lifts","switchback","gust"},
	crownFinish = {"Final ascent","belts","locks","boost"},
}

local function tree(c,x,z,height,tint)
	part(c,"Storybook trunk",x,(height-6)/2-3,z,v(height*0.14,height-6,height*0.14),rgb("78563e"))
	part(c,"Storybook canopy",x,height-8,z,v(height*0.76,height*0.44,height*0.71),tint,false,ball)
	part(c,"Canopy lobe",x+height*0.18,height-9,z+height*0.1,v(height*0.52,height*0.34,height*0.55),tint,false,ball)
end

local function pillars(c,x,z,height)
	part(c,"Column pedestal",x,-0.35,z,v(5.8,1.3,6),c.colors.rock)
	part(c,"Carved column",x,height/2,z,v(3.7,height,3.6),c.colors.rock)
	part(c,"Lintel stone",x,height,z,v(6,1.35,5.6),c.colors.rim)
end

local function templeScene(c,z,chapter,index)
	for _, side in {-1,1} do
		for i=1,3 do tree(c,side*(26+i*3),z+(i-2)*34,26+i*3,rgb(i%2==0 and "78984d" or "4b8652")) end
	end
	if chapter == "waterfall" or chapter == "sunExit" or chapter == "floodgates" then
		for _, side in {-1,1} do
			local x = side*24
			part(c,"Aqueduct bluff",x,10,z+14,v(11,37,43),c.colors.rock)
			for i=1,4 do
				local veil = part(c,"Waterfall veil",x+(i-2)*2.4,9,z-8+(i%2)*1.7,v(2.8,34,1.55),rgb(i%2==0 and "a0ebde" or "48bcae"))
				veil.Transparency = 0.19
			end
			for i=1,4 do
				part(c,"Waterfall foam",x+(i-2.5)*3,-3.2,z-10,v(6,2.8,5),rgb("dbfff5"),false,ball)
			end
		end
	elseif chapter == "cartTracks" then
		for _, side in {-1,1} do
			for i=1,3 do
				pillars(c,side*22,z+(i-2)*17,11)
				light(c,"Mine signal lantern",side*19.4,10.4,z+(i-2)*17,v(0.64,0.83,0.68),c.colors.rim)
			end
		end
		part(c,"Mine gallery arch",0,15,z,v(48,2.5,2.1),c.colors.rock)
	else
		local x = index%2==0 and 37 or -37
		for i=1,5 do
			local width = 34-i*4.3
			part(c,"Sun temple terrace",x,i*3.8-5,z,v(width,4,width),c.colors.rock)
		end
		part(c,"Sun altar",x,17.7,z,v(8.7,4.2,8),c.colors.deck)
		light(c,"Sun seal",x,19.4,z-4.15,v(2.5,2.5,0.5),c.colors.rim)
		for _, side in {-1,1} do pillars(c,side*19,z-18,11.2) end
	end
end

local function ship(c,x,z,scale)
	for i=1,6 do
		local row = z+(i-3.5)*9*scale
		local width = (20-math.abs(i-3.5)*4.4)*scale
		part(c,"Timber hull",x,-3.6,row,v(width,6.2*scale,9.2*scale),rgb("79563f"),
			false,nil,CFrame.Angles(0,0,(i-3.5)*0.019))
		part(c,"Gold gunwale",x,0.2,row,v(width+0.45,0.4,9.3*scale),c.colors.rim)
	end
	for i=1,2 do
		local row = z+(i-1.5)*21*scale
		local height = (i==1 and 26 or 20)*scale
		part(c,"Pirate mast",x,height/2,row,v(1.35,height,1.35),rgb("72503f"))
		part(c,"Crossyard",x,height*0.78,row,v(16*scale,0.8,0.88),c.colors.rock)
		part(c,"Wind-filled sail",x,height*0.56,row-0.8,v(12.6*scale,9.4*scale,2.15),cream,false,ball)
		part(c,"Sail jewel",x,height*0.56,row-1.9,v(2.4*scale,2.4*scale,0.42),c.colors.rim,false,nil,CFrame.Angles(0,0,math.pi/4))
	end
end

local function pirateScene(c,z,chapter,index)
	if chapter == "ghostShip" or chapter == "rigging" then
		-- The concealed ship hangs directly over the playable hold and cargo routes.
		ship(c,0,z,1.15)
		for _, side in {-1,1} do
			part(c,"Cavern face",side*32,7,z,v(14,32,41),rgb("506476"),false,nil,CFrame.Angles(0,0,side*0.18))
		end
	elseif chapter == "harbor" or chapter == "reefExit" then
		for _, side in {-1,1} do
			for i=1,2 do
				local x, row = side*(27+i*6),z+(i-1.5)*20
				part(c,"Harbor cottage",x,4,row,v(9,8,11),c.colors.rock)
				part(c,"Tile roof",x,9,row,v(10.4,4,12),rgb(i%2==0 and "428586" or "b77056"),false,ball)
				light(c,"Cottage window",x-2.6,3.8,row-5.6,v(1.5,1.8,0.16),cream)
			end
		end
		ship(c,index%2==0 and 34 or -34,z+28,0.86)
	else
		for _, side in {-1,1} do
			for i=1,4 do
				part(c,"Sea grotto spire",side*(21+i*3),8,z+(i-2)*15,v(7+i,23+i*3,10),c.colors.rock,false,ball)
				part(c,"Grotto tip",side*(20+i*3),19,z+(i-2)*15,v(3.5,11,5),rgb("7aa0a7"),false,ball)
			end
		end
	end
end

local function prehistoricScene(c,z,chapter)
	for _, side in {-1,1} do
		for i=1,4 do
			tree(c,side*(22+i*5),z+(i-2.5)*20,24+i*5,rgb(i%2==0 and "719e48" or "589555"))
		end
	end
	if chapter == "migration" or chapter == "fossilBasin" then
		local x = -37
		local tint = chapter == "migration" and rgb("638a4e") or rgb("e3ca9e")
		part(c,"Longneck body",x,6,z,v(19,16,31),tint,false,ball)
		part(c,"Longneck neck",x,15,z-11,v(7,22,8),tint,false,ball)
		part(c,"Longneck head",x,24,z-14,v(8.8,6.7,9),tint,false,ball)
		part(c,"Longneck eye",x+3.7,25.1,z-16,v(1.35,1.35,1.35),ink,false,ball)
		for _, a in {-1,1} do
			for _, b in {-1,1} do part(c,"Longneck leg",x+a*4.9,-1,z+b*8,v(5.4,13,5.4),tint,false,ball) end
		end
	else
		for _, side in {-1,1} do
			local x = side*26
			part(c,"Field research cabin",x,5,z,v(13.5,9.8,22),c.colors.rock)
			part(c,"Cabin visor",x,10,z,v(14.5,1.12,22.7),c.colors.rim)
			for i=1,3 do
				light(c,"Observation glass",x-side*6.8,6.6,z+(i-2)*5,v(0.18,3.2,4),rgb("a9ebc4"))
			end
		end
	end
end

local function factoryScene(c,z,chapter)
	for _, side in {-1,1} do
		for i=1,3 do
			local x, row = side*(22+i*3),z+(i-2)*20
			part(c,"Recipe vat",x,4,row,v(10,9+i*0.5,9+i*0.5),c.colors.rock,false,cylinder,vertical)
			part(c,"Vat rim",x,9,row,v(0.63,10.3,10.3),c.colors.rim,false,cylinder,vertical)
			part(c,"Candy turbine",x,11.8,row,v(5,5,5),rgb(i%2==0 and "ef8496" or "9edbd5"),false,ball)
			part(c,"Vat pipe",x+side*4.8,8,row+3.2,v(2,14,2),ink)
		end
	end
	local glaze = chapter == "furnace" and rgb("f79d5c") or rgb("ffbbe1")
	for _, j in {-1,1} do
		part(c,"Overhead frosting pipe",j*9,14,z+2,v(2.15,2.15,42),glaze)
		part(c,"Overhead frosting manifold",j*9,13.4,z-20,v(4.8,4.8,4.8),glaze,false,ball)
	end
end

local function frozenScene(c,z,chapter)
	for _, side in {-1,1} do
		for i=1,5 do
			local x,row = side*(22+i*4),z+(i-3)*16
			local tall = 21+i*3
			part(c,"Glacier ridge",x,tall*0.32-5,row,v(12,tall,15),rgb(i%2==0 and "72b2cc" or "a9dce9"),
				false,nil,CFrame.Angles(0,i*0.22,side*i*0.08)).Material = Enum.Material.Ice
			part(c,"Glacier frost crown",x,tall*0.72-5,row,v(11.8,6.5,13.4),cream,false,ball)
		end
	end
	if chapter == "gondola" or chapter == "summitExit" then
		part(c,"Gondola station beam",0,13,z,v(48,2.05,2.1),ink)
		pillars(c,-20,z,13)
		pillars(c,20,z,13)
	end
end

local function cloudScene(c,z,chapter,index)
	for _, side in {-1,1} do
		for i=1,3 do
			local x,row = side*(25+i*7),z+(i-2)*33
			part(c,"Cloudbank",x,-5,row,v(27,9+i,16),rgb(i%2==0 and "d5dafa" or "f4eef8"),false,ball)
			part(c,"Sky borough",x,2,row,v(10,16+i*2,10),c.colors.rock,false,cylinder,vertical)
			part(c,"Borough cap",x,11+i,row,v(6,10.7,10.7),c.colors.rim,false,cylinder,vertical)
		end
	end
	if chapter == "airships" or chapter == "skyExit" then
		local x = index%2==0 and -31 or 31
		ship(c,x,z,0.77)
		part(c,"Airship balloon",x,28,z,v(22,13,33),rgb("edb5d5"),false,ball)
		for _, side in {-1,1} do
			part(c,"Airship rope",x+side*5,19,z+side*8,v(0.32,17,0.32),ink)
		end
	end
end

local function neonScene(c,z,chapter)
	for _, side in {-1,1} do
		for i=1,4 do
			local x,row = side*(23+i*3),z+(i-2.5)*21
			local height = 18+(i%3)*6
			part(c,"Metropolis tower",x,height/2-4,row,v(10.5,height,12),c.colors.rock)
			for j=1,3 do
				light(c,"Tower floor light",x-side*5.3,height-j*4.2,row,v(0.17,0.75,8.8),c.colors.rim)
			end
			part(c,"Rooftop cap",x,height-3,row,v(11.2,1.3,12.6),ink)
		end
	end
	if chapter == "maglev" or chapter == "neonExit" or chapter == "signalYard" then
		for i=1,3 do
			local row = z+(i-2)*14
			part(c,"Parked courier express",24,-0.65,row,v(8.2,7.2,13.4),rgb("d280c3"),false,ball)
			light(c,"Express window",19.97,0.46,row,v(0.11,2.1,6.8),rgb("ffc671"))
		end
	end
end

local function galacticScene(c,z,chapter,index)
	for _, side in {-1,1} do
		local x = side*(27+(index%2)*8)
		part(c,"Station habitat",x,11,z-10,v(17,17,21),c.colors.rock,false,ball)
		part(c,"Habitat equator",x,11,z-10,v(0.85,24,24),ink,false,cylinder,vertical)
		for i=1,4 do
			light(c,"Habitat window",x+side*6.15,9+i,z-11+(i%2)*3,v(1.3,0.77,1.3),c.colors.rim)
		end
		part(c,"Solar wing",x+side*14,13,z+15,v(16,0.55,8.8),c.colors.rock,false,nil,CFrame.Angles(0,0,side*0.31))
	end
	if chapter == "launchExit" or chapter == "crownFinish" then
		local hull = chapter == "crownFinish" and rgb("f5c659") or cream
		part(c,"Escape capsule",0,17,z+32,v(14,28,17),hull,false,ball)
		part(c,"Capsule glass",0,22,z+23,v(5.8,5.8,1.8),c.colors.deck,false,ball)
		for _, side in {-1,1} do
			part(c,"Capsule fin",side*8.9,11,z+33,v(8.2,2.5,6.1),c.colors.rock,false,nil,CFrame.Angles(0,0,-side*0.34))
		end
	end
end

local scenes = {
	temple=templeScene,pirate=pirateScene,prehistoric=prehistoricScene,factory=factoryScene,
	frozen=frozenScene,cloud=cloudScene,neon=neonScene,galactic=galacticScene,
}

local function addRelic(c,z,world,spec)
	local side = if c.level%2==0 then 1 else -1
	local x = side*20.4
	deck(c,z-2.8,z+6.9,10,x,0)
	part(c,"Relic plinth",x,0.44,z+2,v(3.5,0.9,3.5),c.colors.rock)
	local tint = c.colors.rim
	local body
	if world.key == "temple" then
		body = part(c,world.relic,x,1.65,z+2,v(1.45,1.85,1.25),tint,false,ball)
		for _, dx in {-0.33,0.33} do part(c,"Idol eye",x+dx,1.9,z+1.45,v(0.21,0.23,0.1),ink) end
		part(c,"Idol pedestal cuff",x,1.02,z+2,v(1.65,0.25,1.3),tint)
	elseif world.key == "pirate" then
		body = part(c,world.relic,x,1.63,z+2,v(0.38,1.75,1.75),tint,false,cylinder,CFrame.Angles(0,math.pi/2,0))
		part(c,"Compass needle",x,1.63,z+1.74,v(0.24,1.1,0.12),ink,false,nil,CFrame.Angles(0,0,math.pi/5))
	elseif world.key == "prehistoric" then
		body = part(c,world.relic,x,1.63,z+2,v(1.45,1.86,1.15),tint,false,ball)
		for _, dx in {-0.46,0,0.46} do part(c,"Fossil toe",x+dx,1.82,z+1.54,v(0.37,0.43,0.14),ink,false,ball) end
		part(c,"Fossil heel",x,1.43,z+1.47,v(0.77,0.48,0.18),ink,false,ball)
	elseif world.key == "factory" or world.key == "neon" then
		body = part(c,world.relic,x,1.58,z+2,v(1.52,1.38,0.43),tint,false,nil,CFrame.Angles(0,0,0.2))
		for dx=-1,1 do part(c,"Engraved circuit",x+dx*0.33,1.58,z+1.74,v(0.13,0.7,0.12),ink) end
	elseif world.key == "cloud" then
		body = part(c,world.relic,x,1.63,z+2,v(0.32,1.36,1.36),tint,false,cylinder,CFrame.Angles(0,math.pi/2,0))
		part(c,"Seal wing",x-0.74,1.55,z+2,v(1.04,0.6,0.28),cream,false,ball,CFrame.Angles(0,0,-0.25))
		part(c,"Seal wing",x+0.74,1.55,z+2,v(1.04,0.6,0.28),cream,false,ball,CFrame.Angles(0,0,0.25))
	else
		body = part(c,world.relic,x,1.65,z+2,v(0.92,1.7,0.92),tint,false,nil,CFrame.Angles(math.pi/6,math.pi/4,math.pi/8))
		part(c,"Crystal satellite",x+0.6,1.18,z+1.7,v(0.57,0.74,0.55),tint,false,nil,CFrame.Angles(0.18,0.4,0.3))
	end
	body.Material = Enum.Material.Neon
	local halo = Instance.new("PointLight",body)
	halo.Color, halo.Brightness, halo.Range = tint, 0.9, 7.5
	table.insert(c.relics,{id=spec.key,position=body.Position,part=body})
end

local function launchYard(c,spec,world)
	deck(c,-18,8,38)
	gate(c,spec.name,-15,36,c.colors.rim)
	for i=1,15 do
		local x = (i-8)*2.15
		part(c,"Launch position",x,0.03,-4.0,v(1.48,0.06,5.6),i%2==0 and c.colors.lane or c.colors.rim)
	end
	scenes[world.key](c,12,spec.sections[1],1)
end

local function landscape(c,world)
	for first=-52,c.length+52,280 do
		local span = math.min(283,c.length+53-first)
		local floor = part(c,"World backdrop",0,-10.55,first+span/2,v(144,0.8,span),c.colors.ground)
		floor.Material = if world.key == "factory" or world.key == "galactic" then Enum.Material.SmoothPlastic else Enum.Material.Glass
		if world.key == "galactic" or world.key == "cloud" then floor.Transparency = 0.54 end
	end
end

function Courses.course(level,x,z)
	local spec = assert(Levels[level],"Missing course")
	local world = assert(Levels.worldByKey[spec.worldKey],"Missing world")
	local model = Instance.new("Model")
	model.Name = spec.name
	local c = {
		model=model,x=x,z=z,level=level,worldKey=spec.worldKey,pace=spec.pace,colors=colorsFor(world),
		obstacles={},route={},zones={},relics={},finishWidth=17.7,
	}
	launchYard(c,spec,world)
	model:SetAttribute("CinematicStart",v(x-33,17,z-24))
	model:SetAttribute("CinematicEnd",v(x+25,12,z-7))
	model:SetAttribute("CinematicFocus",v(x,7,z+25))
	local cursor = 8
	local hasZone = table.find(spec.sections,"crackBridge") ~= nil
	for index, chapter in ipairs(spec.sections) do
		local layout = assert(chapters[chapter],chapter)
		gate(c,string.upper(layout[1]),cursor+2,30,c.colors.rim)
		for beat=2,#layout do
			local length = 77+((level*3+index*5+beat*7)%17)
			if layout[beat] == "shoves" then length = 42 end
			deck(c,cursor,cursor+7,deckWidth)
			deck(c,cursor+length-7,cursor+length,deckWidth)
			encounters[layout[beat]](c,cursor,length,index*3+beat*5+level)
			if beat==3 then scenes[world.key](c,cursor+length/2,chapter,index) end
			cursor += length
		end
		deck(c,cursor,cursor+13,deckWidth)
		bay(c,cursor+7,deckWidth-1)
		if index==2+level%4 and not spec.championship then addRelic(c,cursor+4,world,spec) end
		table.insert(c.route,{
			z=z+cursor+3,x=x,width=deckWidth/2+0.9,minY=0.45,maxY=17.5,
			checkpoint=v(x,3.65,z+cursor+7),
		})
		cursor += 13
		if index==3 and not hasZone then
			encounters.shoves(c,cursor,35,0)
			cursor += 35
		end
	end
	deck(c,cursor,cursor+24,36)
	c.length = cursor+9
	c.finish = z+c.length
	finishGate(c)
	for i=1,14 do
		for row=0,1 do
			part(c,"Checkered finish stripe",(i-7.5)*2.48,0.035,c.length+(row-0.5)*1.2,v(2.48,0.07,1.2),(i+row)%2==0 and cream or ink)
		end
	end
	landscape(c,world)
	model.Parent = workspace
	Obstacles.activate(c)
	Obstacles.update(c,0,{},function() end)
	return c
end

return Courses
