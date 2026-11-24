local Config = require(script.Parent.Config)
local EggModel = {}
local rgb = Color3.fromHex
local plastic, metal, neon = Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Neon
local sphere = "Sphere"
local shellHeight = 1.4
local gold = rgb("f2bb49")
local cream = rgb("fff4cb")
local coal = rgb("28232f")
local tau = math.pi * 2

local function piece(egg, name, size, cf, tint, shape, material)
	local p = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	p.Name = name
	p.Size = size * egg.width
	p.CFrame = CFrame.new(cf.Position * egg.width) * cf.Rotation
	p.Color = tint
	p.Material = material or plastic
	if shape == sphere then
		-- Use a built-in sphere mesh so the shell and small beads can keep distinct axis sizes.
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.one
		mesh.Parent = p
	end
	p.Anchored = egg.anchored
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.Parent = egg.model
	if egg.model.PrimaryPart and not egg.anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = egg.model.PrimaryPart
		weld.Part1 = p
		weld.Parent = p
	end
	return p
end

local function surface(theta, y, relief)
	local radius = 0.5 * math.sqrt(1 - (y / (shellHeight / 2)) ^ 2)
	local normal = Vector3.new(math.sin(theta) * radius * 4, y / 0.49, -math.cos(theta) * radius * 4).Unit
	local position = Vector3.new(math.sin(theta) * radius, y, -math.cos(theta) * radius) + normal * relief
	return CFrame.lookAt(position, position + normal)
end

local function bead(egg, name, theta, y, w, h, tint, material, relief, spin)
	return piece(egg,name,Vector3.new(w,h,w*0.23),surface(theta,y,relief or 0.02) * CFrame.Angles(0,0,spin or 0),tint,sphere,material)
end

local function segment(egg, name, a, b, thickness, height, tint, material)
	local cf = CFrame.lookAt((a+b)/2,b)
	return piece(egg,name,Vector3.new(thickness,height,(a-b).Magnitude+thickness*0.35),cf,tint,nil,material)
end

local function line(egg, name, points, thickness, tint, material, relief)
	for i=1,#points-1 do
		local a,b = points[i],points[i+1]
		segment(egg,name,surface(a[1],a[2],relief or 0.04).Position,surface(b[1],b[2],relief or 0.04).Position,thickness,thickness,tint,material)
	end
end

local function ring(egg, name, radius, y, tilt, bandHeight, thickness, colors, material, count)
	local axis = CFrame.Angles(0,0,tilt)
	for i=0,count-1 do
		local angleA, angleB = i*tau/count, (i+1)*tau/count
		local a = axis * Vector3.new(math.sin(angleA)*radius,y,-math.cos(angleA)*radius)
		local b = axis * Vector3.new(math.sin(angleB)*radius,y,-math.cos(angleB)*radius)
		local cf = CFrame.lookAt((a+b)/2,b,axis.UpVector)
		piece(egg,name,Vector3.new(thickness,bandHeight,(b-a).Magnitude+0.016),cf,colors[i%#colors+1],nil,material)
	end
end

local styles = {}

function styles.Chocolate(egg)
	local caramel = rgb("e8a66b")
	piece(egg,"Caramel glaze",Vector3.new(0.93,0.67,0.93),CFrame.new(0,0.39,0),caramel,sphere)
	for i=1,6 do
		bead(egg,"Icing drip",i*tau/6,0.28-0.034*(i%3),0.16,0.24+(i%3)*0.045,caramel,nil,0.026)
	end
	for i, tint in {cream,rgb("f47fa4"),rgb("7edbc1"),cream,rgb("f47fa4")} do
		bead(egg,"Sugar sprinkle",i*tau/5,0.37,0.035,0.10,tint,nil,0.057,0.9-i*0.38)
	end
end

function styles.Watermelon(egg)
	for i=1,6 do
		local angle = (i-0.5)*tau/6
		line(egg,"Rind stripe",{{angle-0.15,-0.53},{angle+0.08,-0.22},{angle-0.09,0.16},{angle+0.05,0.46}},
			0.043,rgb("1d7c49"),nil,0.072)
	end
	bead(egg,"Watermelon slice",0,0.01,0.31,0.30,egg.accent,nil,0.031)
	for i, seed in {{-0.14,0.06},{0.14,0.06},{0,-0.05}} do
		bead(egg,"Watermelon seed",seed[1],seed[2],0.035,0.055,coal,nil,0.055,(i-2)*0.34)
	end
end

function styles.Ninja(egg)
	ring(egg,"Scarlet headband",0.49,0.24,0,0.14,0.038,{egg.accent},plastic,10)
	bead(egg,"Mask panel",0,0.18,0.47,0.19,coal,nil,0.058)
	for _, side in {-1,1} do
		bead(egg,"Mask eye",side*0.20,0.20,0.10,0.047,cream,nil,0.093,side*0.20)
		piece(egg,"Headband tie",Vector3.new(0.075,0.30,0.14),
			CFrame.new(0.47+side*0.07,0.30+side*0.10,0.16)*CFrame.Angles(-0.82,0,-0.85-side*0.27),egg.accent)
	end
end

function styles.Dinosaur(egg)
	for i=1,5 do
		local y = 0.56-(i-1)*0.225
		local size = 0.16+0.04*(1-(i-3)^2/4)
		piece(egg,"Dinosaur spine",Vector3.new(size,0.19,size*1.28),
			surface(math.pi,y,0.064)*CFrame.Angles(0,math.pi,0),egg.accent,"Wedge")
	end
	for i, spot in {{0.4,0.2},{-0.55,0.36},{0.72,-0.24},{-0.56,-0.27},{2.05,-0.14},{-2.1,0.17}} do
		local size = if i%2 == 0 then 0.11 else 0.16
		bead(egg,"Dinosaur speckle",spot[1],spot[2],size,size*0.73,rgb("dfad63"))
	end
end

function styles.Frozen(egg)
	for i, shard in {{-0.65,0.47,0.38},{1.04,0.32,0.26},{2.45,0.45,0.46},{-2.0,0.31,0.31}} do
		piece(egg,"Glacier shard",Vector3.new(0.13,shard[3],0.19),
			surface(shard[1],shard[2],0.083)*CFrame.Angles(0,i*1.25,0.2),if i%2 == 0 then egg.accent else rgb("d8fbff"),"Wedge",Enum.Material.Ice)
	end
	local badge = surface(0,-0.05,0.04)
	for i=0,2 do
		piece(egg,"Snowflake",Vector3.new(0.058,0.33,0.019),badge*CFrame.Angles(0,0,i*math.pi/3),rgb("ebffff"),nil,neon)
	end
end

function styles.Lava(egg)
	for i=0,3 do
		local start = 0.32+i*tau/4
		line(egg,"Magma vein",{{start-0.19,0.47},{start+0.10,0.29},{start-0.13,0.03},{start+0.14,-0.19},{start,-0.45}},
			0.042,if i%2 == 0 then rgb("ff721f") else rgb("ffc147"),neon,0.055)
	end
	for i=0,2 do
		piece(egg,"Basalt outcrop",Vector3.new(0.23,0.24,0.19),
			surface(i*tau/3+0.3,0.47,0.055)*CFrame.Angles(0,0,0.6+i*0.8),rgb("423038"),"Wedge",Enum.Material.Basalt)
	end
end

function styles.Cosmic(egg)
	ring(egg,"Comet halo",0.57,0,-0.28,0.048,0.042,{egg.accent},neon,12)
	bead(egg,"Champion star",0.05,0.29,0.22,0.21,cream,neon,0.045)
	for _, side in {-1,1} do
		piece(egg,"Comet fin",Vector3.new(0.15,0.28,0.18),
			surface(side*1.45,-0.17,0.10)*CFrame.Angles(0,0,side*0.4),egg.accent,"Wedge",metal)
	end
end

function styles.Golden(egg)
	ring(egg,"Gold filigree",0.44,-0.39,0,0.105,0.048,{rgb("b37320"),gold},metal,10)
	for i=0,3 do
		local front = surface(i*math.pi/2,0.13,0.038)
		piece(egg,"Gold ingot badge",Vector3.new(0.18,0.23,0.036),front*CFrame.Angles(0,0,math.pi/4),cream,nil,metal)
	end
end

function styles.Rainbow(egg)
	ring(egg,"Prism ribbon",0.53,0.015,-0.34,0.165,0.04,{
		rgb("f95b69"),rgb("ff923b"),rgb("ffd449"),rgb("8de582"),rgb("58cae9"),rgb("a17af2"),
	},neon,12)
	for i=0,3 do
		bead(egg,"Prism highlight",i*tau/4,0.35,0.082,0.17,cream,neon,0.022,i)
	end
end

function styles.Galaxy(egg)
	ring(egg,"Saturn ring",0.625,0,0.32,0.045,0.12,{rgb("cf9eed"),rgb("efd1f7")},metal,12)
	for i, point in {{0,0.31},{0.39,0.42},{-0.37,-0.18},{1.5,-0.26},{-2.3,0.33},{2.6,0.24},{3.08,-0.34}} do
		local size = if i%2 == 0 then 0.07 else 0.035
		bead(egg,"Starlight",point[1],point[2],size,size,if i%2 == 0 then egg.accent else cream,neon)
	end
end

function styles.Royal(egg)
	ring(egg,"Crown band",0.37,0.495,0,0.12,0.07,{gold},metal,10)
	for i=0,4 do
		local azimuth = i*tau/5
		local cf = CFrame.Angles(0,azimuth,0)*CFrame.new(0,0.64,-0.35)*CFrame.Angles(-0.24,0,0)
		piece(egg,"Crown point",Vector3.new(0.145,0.24,0.12),cf,gold,"Wedge",metal)
		piece(egg,"Crown jewel",Vector3.new(0.068,0.068,0.038),cf*CFrame.new(0,0.062,-0.071),if i==0 then rgb("8bf0df") else rgb("f77f98"),sphere,neon)
	end
end

function styles.VIP(egg)
	ring(egg,"Courier webbing",0.50,0.15,0,0.12,0.044,{rgb("20596a")},plastic,10)
	for _, side in {-1,1} do
		bead(egg,"Aviator frame",side*0.21,0.16,0.21,0.19,gold,metal,0.038)
		bead(egg,"Aviator lens",side*0.21,0.16,0.157,0.143,rgb("295976"),metal,0.066)
		bead(egg,"Lens glint",side*0.21-0.04,0.184,0.051,0.035,cream,nil,0.086,0.5)
	end
end

local function addCracks(egg, tint)
	for i=0,2 do
		local a = 0.98+i*tau/3
		local upper = {{a-0.18,0.35},{a+0.07,0.17},{a-0.12,-0.01}}
		local lower = {{a-0.12,-0.01},{a+0.13,-0.16},{a+0.025,-0.32},{a+0.22,-0.46}}
		line(egg,"Crack1",upper,0.025,tint,nil,0.053)
		line(egg,"Crack2",lower,0.027,tint,nil,0.058)
	end
end

function EggModel.build(id, width, anchored)
	local skin = Config.bySkin[id] or Config.bySkin.Classic
	local shellColor = if id == "Lava" then rgb("241d27") else Color3.fromRGB(table.unpack(skin[4]))
	local model = Instance.new("Model")
	model.Name = "CourierEgg"
	local egg = {
		model=model, width=width, anchored=anchored == true, accent=Color3.fromRGB(table.unpack(skin[5])),
	}
	local material = if id == "Golden" then metal elseif id == "Frozen" then Enum.Material.Ice else plastic
	model.PrimaryPart = piece(egg,"Shell",Vector3.new(1,shellHeight,1),CFrame.identity,shellColor,sphere,material)
	local style = styles[id]
	if style then style(egg) end
	local paleCrack = id == "Chocolate" or id == "Ninja" or id == "Lava" or id == "Galaxy"
	addCracks(egg,if paleCrack then rgb("ffe2aa") else rgb("392633"))
	EggModel.condition(model,3)
	model:SetAttribute("Skin",id)
	return model
end

function EggModel.condition(model, hp)
	for _, p in model:GetChildren() do
		if p.Name == "Crack1" then p.Transparency = hp < 3 and 0 or 1 end
		if p.Name == "Crack2" then p.Transparency = hp < 2 and 0 or 1 end
	end
end

return EggModel
