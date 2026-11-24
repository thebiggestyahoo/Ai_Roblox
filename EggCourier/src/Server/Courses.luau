local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Levels = require(Shared.Levels)
local Obstacles = require(script.Parent.Obstacles)

local Courses = {}
local rgb = Color3.fromHex
local v = Vector3.new
local ink, cream = rgb("151f26"), rgb("ffedca")
local red, amber = rgb("ff4c42"), rgb("ffc455")

local themes = {
	["Green Meadows"] = {deck="42573f", rim="eaa935", lane="e8c86e", hazard="ef6044", ground="56908a", rock="556548", sky="f6d6ad"},
	["The Egg Cooker"] = {deck="403738", rim="f89645", lane="ccb48f", hazard="ff582e", ground="cb4325", rock="342729", sky="fbb469"},
	["Frozen Eggs"] = {deck="2d6173", rim="97eee5", lane="b9edf2", hazard="f75f6a", ground="67aac3", rock="809eba", sky="a9e4ee"},
	["Eggstraterrestrial"] = {deck="252743", rim="b99cff", lane="86eed5", hazard="fa6e9e", ground="24253d", rock="322e57", sky="a898ff"},
	["Sunken Ruins"] = {deck="554d3e", rim="efb46b", lane="90ead8", hazard="af6a43", ground="2a7364", rock="645c49", sky="d6cbb0"},
}
for _, colors in themes do
	for name, hex in colors do colors[name] = rgb(hex) end
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

local function light(c, name, px, py, pz, size, color)
	local p = part(c,name,px,py,pz,size,color)
	p.Material = Enum.Material.Neon
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
		words.Font = Enum.Font.GothamBlack
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

local function footing(c, first, last, width)
	deck(c,first,last,width)
	marking(c,first+0.3,width-0.7,0,c.colors.lane)
end

local function obstacle(c, kind, x, y, z, phase, overrides)
	local stats = table.clone(overrides or {})
	local def = Obstacles.definitions[kind]
	if def.speed then stats.speed = (stats.speed or def.speed)*c.pace end
	stats.color = stats.color or c.colors.hazard
	return Obstacles.add(c,kind,v(c.x+x,y,c.z+z),phase,stats)
end

local function banks(c, z, finish, width, approach, landing)
	footing(c,z,z+approach,width)
	footing(c,z+finish-landing,z+finish,width)
	return finish, width
end

local function deckDots(c, x, z, width, y)
	for _, side in {-1,1} do
		local dotX = x+(width/2-0.5)*side
		light(c,"Edge bead",dotX,y+0.035,z,v(0.32,0.08,0.98),c.colors.rim)
	end
end

local function disc(c, x, z, radius, color)
	local orientation = CFrame.Angles(0,0,math.pi/2)
	part(c,"Circular perch",x,-0.65,z,v(1.3,radius*2,radius*2),color,true,Enum.PartType.Cylinder,orientation)
	part(c,"Perch trim",x,-0.93,z,v(0.24,radius*2+0.2,radius*2+0.2),c.colors.rim,false,Enum.PartType.Cylinder,orientation)
	for i=1,8 do
		local t=i*math.pi/4
		light(c,"Perch marker",x+(radius-0.5)*math.cos(t),0.025,z+(radius-0.5)*math.sin(t),v(0.5,0.08,0.5),c.colors.lane)
	end
end

local sections = {}

function sections.bumper(c,z,index)
	local width = 19
	deck(c,z,z+33,width)
	for i=1,3 do
		local row=z+4+i*6.7
		deckDots(c,0,row,width,0)
		obstacle(c,"ball",0,0,row,index*0.57+i*1.74,{size=v(7.2,7.2,7.2), range=8.2, speed=2.3})
	end
	return 33,width
end

function sections.punch(c,z,index)
	local width = 15
	deck(c,z,z+33,width)
	for i=1,3 do
		local row=z+3+i*7
		obstacle(c,"foam",0,0,row,index*0.78+i*2.09,{size=v(10.5,4.8,3.05),range=9.8,speed=2.06})
		for _, side in {-1,1} do
			part(c,"Piston housing",side*10.4,1.2,row,v(3.1,3.3,4.9),ink)
			light(c,"Piston stripe",side*9.85,3,row,v(0.5,0.12,3.4),c.colors.rim)
		end
	end
	return 33,width
end

function sections.steps(c,z,index)
	local width=15
	banks(c,z,50,width,5,5.8)
	for i=1,3 do
		local begin=z+9.4+(i-1)*11.55
		local px=(i%2==index%2 and -1 or 1)*(c.pace>1.1 and 3 or 2.4)
		local top=(i%2)*0.35
		deck(c,begin,begin+6.4,8.8,px,top,c.colors.deck)
		deckDots(c,px,begin+1,8.8,top)
		deckDots(c,px,begin+5.4,8.8,top)
	end
	return 50,width
end

function sections.spinners(c,z,index)
	local width=16
	banks(c,z,51,width,5.6,6)
	for i=1,2 do
		local px=(i%2==index%2 and -1 or 1)*1.2
		local row=z+15.9+(i-1)*18.6
		disc(c,px,row,7.5,c.colors.deck)
		obstacle(c,"sweep",px,0,row,index+i*2.3,{size=v(17.2,0.9,1.35),speed=2.22})
	end
	return 51,width
end

function sections.rafts(c,z,index)
	local width=16
	banks(c,z,45,width,6,6)
	for i=1,2 do
		obstacle(c,"moving",0,0,z+15.55+(i-1)*13.9,index+i*2.8,{
			size=v(11,1.4,9),range=2.7,speed=1.7,color=c.colors.rim,
		})
	end
	return 45,width
end

function sections.ferry(c,z,index)
	local width=17
	banks(c,z,43,width,7,9)
	obstacle(c,"moving",0,0,z+21,index*1.43,{
		size=v(11,1.4,10),axis=Vector3.zAxis,range=7.1,speed=1.22,color=c.colors.rim,
	})
	for _, side in {-1,1} do
		light(c,"Ferry track",side*6.7,-1.65,z+20.5,v(0.38,0.16,26.8),c.colors.lane)
		for i=1,3 do
			part(c,"Ferry track brace",side*6.7,-3.25,z+9+11*i,v(0.75,3.2,0.75),ink)
		end
	end
	return 43,width
end

function sections.tilts(c,z,index)
	local width=16
	banks(c,z,46,width,6,6)
	for i=1,2 do
		obstacle(c,"tilt",i%2==index%2 and -1.65 or 1.65,0,z+15.7+(i-1)*14.8,index+i*2.1,{
			size=v(8.4,1.4,9.6),range=0.36,pitch=0.09,speed=1.8,color=c.colors.rim,
		})
	end
	return 46,width
end

function sections.swing(c,z,index)
	local width=15
	deck(c,z,z+31,width)
	for i=1,2 do
		local row=z+5+i*8.1
		for _, side in {-1,1} do
			part(c,"Pendulum stanchion",side*9,8,row,v(1,16,1),ink)
		end
		part(c,"Pendulum crossbeam",0,16,row,v(19.5,1.15,1.15),ink)
		obstacle(c,"pendulum",0,0,row,index+i*2.3,{size=v(5.7,5.7,5.7),range=8.4,speed=2.08})
	end
	return 31,width
end

function sections.duel(c,z,index)
	local width=14.5
	deck(c,z,z+37,width)
	for _, side in {-1,1} do
		light(c,"Crack Zone edge",side*(width/2-0.3),0.04,z+18.5,v(0.34,0.09,26),red)
		for i=1,5 do
			part(c,"Warning hatch",side*(width/2-0.95),0.045,z+7.5+5.4*(i-1),v(1.3,0.07,0.24),amber,false,nil,CFrame.Angles(0,side*0.62,0))
		end
	end
	marking(c,z+5.5,width-0.5,0,red)
	marking(c,z+31.5,width-0.5,0,red)
	gate(c,"CRACK ZONE",z+5.5,width,amber)
	table.insert(c.zones,{z=c.z+18.5,extent=13,width=width/2})
	obstacle(c,"sweep",0,0,z+23,index*2.14,{size=v(width+1,0.72,0.95),speed=1.95,color=amber})
	return 37,width
end

function sections.shutters(c,z,index)
	local width=15
	deck(c,z,z+39,width)
	for i=1,3 do
		local row=z+5+i*8.2
		for _, side in {-1,1} do
			part(c,"Shutter guide",side*8.9,7.3,row,v(1.25,14.6,1.5),ink)
			light(c,"Shutter height rail",side*8.25,7.3,row-0.43,v(0.16,12,0.2),amber)
		end
		part(c,"Shutter rail top",0,14.6,row,v(19,0.9,1.7),ink)
		obstacle(c,"door",0,0,row,index*0.78+i*2.11,{size=v(16,7,1.2),y=3.5,range=7.2,speed=1.5})
		marking(c,row-1.3,width-0.6,0,amber)
	end
	return 39,width
end

function sections.blink(c,z,index)
	local width=16
	banks(c,z,49,width,6,6)
	deck(c,z+21,z+28,8.8)
	for i,row in {z+13.5,z+35.5} do
		obstacle(c,"vanish",0,0,row,index*0.63+i*1.86,{size=v(9,1.4,7),period=4.15,open=1.1,color=c.colors.rim})
		for _, side in {-1,1} do
			light(c,"Ghost tile mount",side*5.4,-0.8,row,v(0.42,0.35,7),c.colors.lane)
		end
	end
	return 49,width
end

function sections.heat(c,z,index)
	local width=15
	deck(c,z,z+33,width)
	for i=1,3 do
		local row=z+4+i*6.8
		obstacle(c,"pulse",0,0,row,index*0.55+i*1.2,{size=v(width+0.25,0.22,4.65),period=3.5,open=1.32,color=c.colors.deck})
		marking(c,row-2.65,width-0.5,0,c.colors.rim)
	end
	return 33,width
end

function sections.rollers(c,z,index)
	local width=15
	deck(c,z,z+30,width)
	for i=1,3 do
		local row=z+3+i*6.8
		deckDots(c,0,row,width,0)
		obstacle(c,"roller",0,0,row,index+i*1.9,{size=v(11.5,3.5,3.5),y=1.75,range=7.5,speed=2.4})
	end
	return 30,width
end

function sections.ice(c,z,index)
	local width=16.5
	local p=deck(c,z,z+41,width,0,0,rgb("83bdcd"))
	p.CustomPhysicalProperties=PhysicalProperties.new(1,0.012,0)
	p.Material=Enum.Material.Ice
	for _, side in {-1,1} do
		light(c,"Snowball lane",side*4.15,0.026,z+20,v(0.13,0.055,29),c.colors.lane)
		obstacle(c,"snowball",side*4.15,0,z+20,index*0.68+side*1.8,{size=v(6.3,6.3,6.3),y=3.15,range=12.9,speed=1.85,color=cream})
	end
	return 41,width
end

function sections.orbit(c,z,index)
	local width=16
	banks(c,z,47,width,4.5,5)
	for i=1,3 do
		local row=z+13+i*10-10
		local px=(i%2==index%2 and -1 or 1)*2.4
		disc(c,px,row,3.95,c.colors.deck)
		local radius=4.75
		for j=1,4 do
			local t=j*math.pi/2
			light(c,"Orbital thruster",px+radius*math.cos(t),-0.9,row+radius*math.sin(t),v(0.7,0.45,0.7),c.colors.rim)
		end
	end
	return 47,width
end

function sections.relic(c,z,index)
	local width=15.5
	deck(c,z,z+32,width)
	for i=1,3 do
		local row=z+7+i*5.3
		obstacle(c,"pulse",0,0,row,index*0.7+i*1.2,{size=v(width,0.22,4),period=3.85,open=1.47,color=c.colors.rock})
		for _, side in {-1,1} do
			part(c,"Stone column",side*8.7,1.3,row,v(1.4,2.6,1.4),c.colors.rock)
			light(c,"Column beacon",side*8.7,2.72,row,v(0.72,0.35,0.72),c.colors.lane)
		end
	end
	for _, side in {-1,1} do
		part(c,"Relic pedestal",side*10.2,1.05,z+5.5,v(2.7,2.1,3.4),ink)
		part(c,"Carved basalt face",side*10.2,3.55,z+5.5,v(2.8,3,2.1),c.colors.rock)
		for _, eye in {-1,1} do
			light(c,"Relic eye",side*10.2+eye*0.63,3.86,z+4.43,v(0.45,0.36,0.12),c.colors.lane)
		end
	end
	return 32,width
end

function sections.chase(c,z,index)
	local width=13
	banks(c,z,48,width,8,7)
	deck(c,z+8,z+41,9.8)
	gate(c,"BOULDERS • USE THE ALCOVES",z+4.5,18,c.colors.rim)
	for _, side in {-1,1} do
		for _, at in {17,30} do
			deck(c,z+at-2.65,z+at+2.65,5.1,side*5.6,0,c.colors.rock)
			light(c,"Alcove lip",side*7.95,0.04,z+at,v(0.21,0.08,4.8),c.colors.lane)
			part(c,"Alcove ruin",side*8.6,1.45,z+at,v(1.15,2.9,3.2),c.colors.rock)
		end
	end
	obstacle(c,"boulder",0,0,z+25,index*0.81,{color=c.colors.rock})
	return 48,width
end

function sections.rope(c,z,index)
	local width=15
	banks(c,z,46,width,6,6)
	for i=1,3 do
		local first=10.6+(i-1)*10.1
		local px=(i%2==index%2 and -1 or 1)*1.45
		local top=0.18*(i%2)
		deck(c,z+first,z+first+5.2,8.25,px,top,rgb("926648")).Material = Enum.Material.WoodPlanks
		for _, side in {-1,1} do
			part(c,"Rope bridge beam",px+side*3.9,-0.3+top,z+first+2.6,v(0.24,0.26,5.3),c.colors.rim)
		end
	end
	for _, side in {-1,1} do
		for _, row in {z+6,z+40} do
			part(c,"Broken bridge pier",side*5.3,1.2,row,v(0.95,2.4,0.95),c.colors.rock)
			part(c,"Tether",side*5.3,0.78,row+0.68,v(0.32,0.27,1.5),c.colors.rim,false,nil,CFrame.Angles(0.61,0,0))
		end
	end
	return 46,width
end

local function landmark(c, island, z)
	local colors = c.colors
	if island=="Green Meadows" then
		local x,y = 39,11
		part(c,"Fair wheel support",x,y/2-1,z,v(0.8,y+3,1),colors.rock)
		part(c,"Fair wheel axle",x,y,z,v(2.6,2.6,1.2),colors.rim,false,Enum.PartType.Ball)
		for i=1,10 do
			local t=math.pi*i/5
			local dx,dy=math.cos(t)*11,math.sin(t)*11
			part(c,"Wheel spoke",x+dx/2,y+dy/2,z,v(11,0.26,0.28),colors.rim,false,nil,CFrame.Angles(0,0,t))
			part(c,"Gondola",x+dx,y+dy,z,v(2.8,1.6,1.9),i%2==0 and colors.hazard or colors.lane)
			light(c,"Gondola light",x+dx,y+dy-0.38,z-0.96,v(1.6,0.18,0.13),cream)
		end
	elseif island=="The Egg Cooker" then
		for i=1,5 do
			local width = 24-3*i
			part(c,"Furnace shell",39,i*2.9-6,z,v(4,width,width),colors.rock,false,Enum.PartType.Cylinder,CFrame.Angles(0,0,math.pi/2))
		end
		light(c,"Furnace mouth",39,10.1,z,v(8.8,0.54,8.8),colors.hazard)
		for i=1,4 do
			part(c,"Foundry stack",39+i*3.3,7+i*2,z+5,v(2.05,15,2.05),ink)
		end
	elseif island=="Frozen Eggs" then
		for i=1,5 do
			local height=28-3.1*i
			part(c,"Glacier crown",34+i*2.6,height/2-7,z-i*1.25,v(6,height,9),i%2==0 and colors.sky or colors.rock,false,nil,CFrame.Angles(0,0,-0.21)).Material=Enum.Material.Ice
		end
	elseif island=="Eggstraterrestrial" then
		part(c,"Relay planet",43,21,z,v(24,24,24),colors.rock,false,Enum.PartType.Ball)
		part(c,"Dust ring",43,21,z,v(0.55,39,39),colors.rim,false,Enum.PartType.Cylinder,CFrame.Angles(0,0,1.2)).Transparency=0.32
	else
		for i=1,6 do
			local width=32-i*3.2
			part(c,"Temple terrace",40,3.08*i-8,z,v(width,3.4,width),colors.rock)
			part(c,"Temple trim",40,3.08*i-6.35,z,v(width+0.8,0.36,width+0.8),colors.rim)
		end
		part(c,"Temple shrine",40,14.2,z,v(8.4,6.9,8.9),ink)
		light(c,"Shrine portal",40,14.2,z-4.48,v(3.25,4.25,0.14),colors.lane)
	end
end

local function decorate(c, island, length)
	local colors = c.colors
	local water = part(c,"Island basin",0,-10.3,length/2,v(132,0.9,length+90),colors.ground)
	water.Material = if island=="The Egg Cooker" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	water.Transparency = if island=="Eggstraterrestrial" then 0.18 else 0.05
	local random = Random.new(c.level*193+41)
	landmark(c,island,math.floor(length*0.38))
	for _, side in {-1,1} do
		for i=1,math.ceil(length/21) do
			local z = i*21+random:NextNumber(-7,7)-10
			local x = side*random:NextNumber(21,51)
			local tall = random:NextNumber(3,13)
			local spread = random:NextNumber(4,11)
			local rotation = CFrame.Angles(0,random:NextNumber(0,math.pi),random:NextNumber(-0.29,0.29))
			if island=="The Egg Cooker" then
				part(c,"Basalt outcrop",x,-8+tall/2,z,v(spread,tall,spread*0.8),colors.rock,false,nil,rotation)
				light(c,"Magma seam",x,-8+tall/2,z-spread/2,v(spread*0.65,0.32,0.55),colors.rim)
				if i%3==0 then
					part(c,"Flue stack",x,-7+tall,z,v(12,spread*0.48,spread*0.48),ink,false,Enum.PartType.Cylinder,CFrame.Angles(0,0,math.pi/2))
				end
			elseif island=="Frozen Eggs" then
				part(c,"Ice shelf",x,-8.3,z,v(spread*2.2,2.6,spread*1.4),cream,false,nil,rotation)
				part(c,"Glacier shard",x,-8+tall/2,z-2,v(spread/2,tall,spread*0.6),colors.rock,false,nil,rotation).Material = Enum.Material.Ice
			elseif island=="Eggstraterrestrial" then
				local radius=spread*0.72
				part(c,"Planet",x,-6+tall,z,v(radius,radius,radius),i%2==0 and colors.rock or colors.rim,false,Enum.PartType.Ball)
				if i%3==0 then
					part(c,"Planet annulus",x,-6+tall,z,v(0.17,radius*1.75,radius*1.75),colors.sky,false,Enum.PartType.Cylinder,CFrame.Angles(0,0,1.26)).Transparency=0.45
				end
				light(c,"Pin star",x+side*9,-4+tall*1.1,z+3,v(0.46,0.46,0.46),colors.lane)
			elseif island=="Sunken Ruins" then
				part(c,"Fallen colonnade",x,-8+tall/2,z,v(spread*0.33,tall,spread*0.33),colors.rock,false,nil,rotation)
				part(c,"Masonry pad",x,-8.3,z,v(spread*1.32,2.2,spread*1.17),colors.rock)
				if i%4==0 then
					light(c,"Ruin lamp",x,-7.3+tall,z,v(0.34,0.64,0.34),colors.lane)
				end
			else
				part(c,"Meadow bluff",x,-8,z,v(spread*2,6,spread*2.5),colors.rock,false,Enum.PartType.Ball)
				part(c,"Tree trunk",x,-7+tall/2,z,v(0.94,tall,0.94),rgb("74513c"))
				part(c,"Tree crown",x,-6+tall,z,v(spread*0.82,spread,spread*0.82),i%2==0 and rgb("91a95b") or rgb("cfab5c"),false,Enum.PartType.Ball)
			end
		end
	end
end

function Courses.course(level, x, z)
	local spec = assert(Levels[level],"Missing course")
	local model = Instance.new("Model")
	model.Name = spec.name
	local c = {model=model,x=x,z=z,level=level,pace=spec.pace,colors=assert(themes[spec.island]),obstacles={},route={},zones={}}
	local cursor = 10
	deck(c,-17,cursor,35)
	gate(c,spec.name,-15,33,c.colors.rim)
	for i=1,6 do
		local laneX = (i-3.5)*4.5
		part(c,"Launch lane",laneX,0.03,-5.6,v(2.65,0.06,10.6),i%2==0 and c.colors.lane or c.colors.rim)
	end
	marking(c,9.25,34,0,c.colors.lane)
	for i, name in spec.sections do
		local build = assert(sections[name],name)
		local length, width = build(c,cursor,i)
		cursor += length
		table.insert(c.route,{z=z+cursor-1.05,x=x,width=width/2+1.5,minY=0.45,maxY=12.5})
	end
	deck(c,cursor,cursor+22,35)
	c.length = cursor+9
	c.finish = z+c.length
	gate(c,"FINISH",c.length+2,33,c.colors.rim)
	for i=1,14 do
		for row=0,1 do
			part(c,"Checkered finish stripe",(i-7.5)*2.36,0.035,c.length+(row-0.5)*1.2,v(2.36,0.07,1.2),(i+row)%2==0 and cream or ink)
		end
	end
	decorate(c,spec.island,c.length)
	model.Parent = workspace
	return c
end

return Courses
