local Cosmetics = require(script.Parent.Cosmetics)
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

local motifs = {}
local ocean = rgb("233858")
local white = rgb("fff6e8")

local function solid(egg, name, size, x, y, z, color, shape, yaw, roll, material)
	return piece(egg,name,Vector3.new(table.unpack(size)),CFrame.new(x,y,z)*CFrame.Angles(0,yaw or 0,roll or 0),color,shape,material)
end

local function face(egg, name, x, y, width, height, tint)
	local theta = x * 2
	return bead(egg,name,theta,y,width,height,tint,nil,0.048)
end

local function spokes(egg, name, cf, count, width, length, tint, material)
	for i=0,count-1 do
		piece(egg,name,Vector3.new(width,length,0.032),cf*CFrame.Angles(0,0,i*math.pi/count),tint,nil,material)
	end
end

function motifs.bloom(egg)
	for i, point in {{-0.69,0.28},{0.24,0.43},{0.73,-0.13}} do
		local cf = surface(point[1],point[2],0.049)
		for p=1,5 do
			local turn = CFrame.Angles(0,0,p*tau/5)
			piece(egg,"Flower petal",Vector3.new(0.086,0.149,0.038),cf*turn*CFrame.new(0,0.095,0),i==2 and white or egg.accent,sphere)
		end
		piece(egg,"Flower heart",Vector3.new(0.09,0.09,0.04),cf*CFrame.new(0,0,-0.028),gold,sphere)
	end
end

function motifs.seed(egg)
	for i=1,12 do
		bead(egg,"Seeds",i*2.399,(i%5-2)*0.215,0.06,0.1,cream,nil,0.04,i*0.32)
	end
end

function motifs.beak(egg)
	solid(egg,"Upper beak",{0.235,0.14,0.29},0,0,-0.49,egg.accent,"Wedge",math.pi)
	solid(egg,"Lower beak",{0.19,0.05,0.21},0,-0.08,-0.49,gold,sphere)
	for _, side in {-1,1} do
		face(egg,"Bright eye",side*0.23,0.17,0.085,0.11,coal)
	end
end

function motifs.tuft(egg)
	for _, side in {-1,1} do
		solid(egg,"Soft tuft",{0.15,0.25,0.11},side*0.075,0.715,0,egg.accent,sphere,0,-side*0.26)
	end
end

function motifs.stripe(egg)
	for i=1,3 do
		local y = (i-2)*0.27
		ring(egg,"Shell stripe",i==2 and 0.505 or 0.473,y,0,0.105,0.026,{egg.accent},plastic,12)
	end
end

function motifs.antenna(egg)
	for _, side in {-1,1} do
		segment(egg,"Bendy feeler",Vector3.new(side*0.18,0.51,0),Vector3.new(side*0.31,0.83,-0.027),0.043,0.043,coal)
		solid(egg,"Feeler tip",{0.13,0.13,0.13},side*0.31,0.83,-0.027,egg.accent,sphere)
	end
end

function motifs.basket(egg)
	local brown = rgb("a16b55")
	for i=1,4 do
		ring(egg,"Wicker weave",0.43+i*0.02,-0.59+i*0.08,0,0.055,0.055,{brown,gold},plastic,10)
	end
	for i=0,5 do
		local a,b = math.pi*i/6,math.pi*(i+1)/6
		segment(egg,"Wicker handle",Vector3.new(math.cos(a)*0.55,math.sin(a)*0.77,-0.04),
			Vector3.new(math.cos(b)*0.55,math.sin(b)*0.77,-0.04),0.045,0.045,brown)
	end
end

function motifs.leaf(egg)
	for side=-1,1,2 do
		solid(egg,"Layered leaves",{0.18,0.34,0.08},side*0.19,0.61,0, rgb("71a96c"),sphere,0,-side*0.73)
		solid(egg,"Leaf vein",{0.025,0.19,0.028},side*0.19,0.635,-0.047,cream,nil,0,-side*0.73)
	end
end

function motifs.ear(egg)
	for _, side in {-1,1} do
		solid(egg,"Floppy ear",{0.23,0.51,0.17},side*0.38,0.31,0.015,egg.accent,sphere,0,side*0.42)
	end
end

function motifs.snout(egg)
	solid(egg,"Puppy muzzle",{0.31,0.19,0.15},0,-0.13,-0.52,cream,sphere)
	solid(egg,"Nose",{0.12,0.08,0.057},0,-0.08,-0.605,coal,sphere)
	for _, side in {-1,1} do
		face(egg,"Pup eye",side*0.21,0.18,0.068,0.082,ocean)
	end
end

function motifs.wing(egg)
	for _, side in {-1,1} do
		for i=1,3 do
			local x = side*(0.49+0.055*i)
			local y = 0.2-i*0.115
			solid(egg,"Wing feather",{0.17,0.38,0.13},x,y,0.19,if i%2==0 then cream else egg.accent,sphere,0,-side*(0.39+i*0.24))
		end
	end
end

function motifs.cactus(egg)
	for _, side in {-1,1} do
		local x = side*0.55
		solid(egg,"Cactus pad",{0.27,0.44,0.18},x,side*0.09,0,rgb("8eca86"),sphere,0,-side*0.31)
		for i=1,2 do
			solid(egg,"Pale thorn",{0.05,0.09,0.042},x,-0.13+i*0.1+side*0.09,-0.11,cream,"Wedge")
		end
	end
end

function motifs.bow(egg)
	for _, side in {-1,1} do
		solid(egg,"Bow loop",{0.26,0.13,0.11},side*0.16,0.36,-0.46,egg.accent,sphere,0,side*0.21)
		solid(egg,"Bow tail",{0.094,0.19,0.038},side*0.081,0.244,-0.47,egg.accent,nil,0,side*0.31)
	end
	solid(egg,"Bow knot",{0.10,0.12,0.12},0,0.36,-0.53,white,sphere)
end

function motifs.hat(egg)
	solid(egg,"Expedition brim",{1.11,0.067,0.8},0,0.48,0,gold,sphere)
	solid(egg,"Felt crown",{0.64,0.33,0.59},0,0.57,0,egg.accent,sphere)
	ring(egg,"Hat band",0.294,0.55,0,0.059,0.028,{coal},plastic,8)
end

function motifs.scarf(egg)
	ring(egg,"Scarf wrap",0.448,-0.34,-0.12,0.10,0.06,{egg.accent},plastic,11)
	solid(egg,"Scarf tail",{0.18,0.31,0.10},0.39,-0.41,-0.26,egg.accent,nil,0,-0.35)
end

function motifs.panel(egg)
	for i=1,5 do
		local cf = surface(i*tau/5,0.09,0.045)
		piece(egg,"Shell panel",Vector3.new(0.24,0.34,0.047),cf,egg.accent,nil,metal)
		piece(egg,"Panel seam",Vector3.new(0.12,0.018,0.02),cf*CFrame.new(0,0.07,-0.035),coal)
	end
end

function motifs.glyph(egg)
	for i=0,2 do
		local a = i*tau/3
		line(egg,"Carved glyph",{{a-0.16,0.12},{a,0.28},{a+0.16,0.12},{a,0.04},{a-0.16,0.12}},0.035,egg.accent,neon)
		bead(egg,"Glyph dot",a,-0.065,0.047,0.047,cream,neon)
	end
end

function motifs.totem(egg)
	for _, side in {-1,1} do
		solid(egg,"Carved brow",{0.19,0.075,0.095},side*0.15,0.21,-0.46,cream,nil,0,side*0.23)
		face(egg,"Carved eye",side*0.15,0.095,0.102,0.09,ocean)
	end
	solid(egg,"Idol mouth",{0.24,0.08,0.09},0,-0.19,-0.495,egg.accent)
end

function motifs.bead(egg)
	ring(egg,"Carved neckband",0.45,-0.3,0,0.051,0.037,{gold,egg.accent},metal,10)
	for i=1,7 do
		bead(egg,"Engraved bead",i*tau/7,-0.37,0.11,0.11,cream,metal)
	end
end

function motifs.armor(egg)
	for _, side in {-1,1} do
		solid(egg,"Pauldron",{0.30,0.29,0.44},side*0.42,0.18,0,egg.accent,sphere)
		solid(egg,"Armor stud",{0.091,0.091,0.05},side*0.42,0.18,-0.218,cream,sphere)
	end
end

function motifs.crystal(egg)
	for i=1,4 do
		local angle = i*tau/4
		local cf = surface(angle,0.41,0.1)*CFrame.Angles(0,0,0.24)
		piece(egg,"Faceted crystal",Vector3.new(0.15,0.34,0.15),cf,egg.accent,"Wedge",Enum.Material.Glass)
		piece(egg,"Crystal glint",Vector3.new(0.042,0.16,0.03),cf*CFrame.new(0,0.02,-0.055),white,nil,neon)
	end
end

function motifs.skull(egg)
	for _, side in {-1,1} do
		face(egg,"Eye socket",side*0.18,0.12,0.19,0.18,ocean)
	end
	for i=-1,1 do
		face(egg,"Cut tooth",i*0.09,-0.23,0.073,0.131,white)
	end
	face(egg,"Nasal socket",0,-0.04,0.095,0.1,coal)
end

function motifs.shard(egg)
	for i=0,3 do
		piece(egg,"Shell shard",Vector3.new(0.09,0.28+i*0.048,0.12),
			surface(i*math.pi/2+0.22,0.27+i*0.062,0.073)*CFrame.Angles(0,0,0.28),egg.accent,"Wedge",Enum.Material.Ice)
	end
end

function motifs.tricorn(egg)
	solid(egg,"Captain brim",{1.18,0.10,0.79},0,0.51,0,coal,sphere)
	for i=1,3 do
		local cf = CFrame.Angles(0,i*tau/3,0)*CFrame.new(0,0.61,-0.27)*CFrame.Angles(-0.24,0,0)
		piece(egg,"Captain's folded felt",Vector3.new(0.67,0.24,0.12),cf,egg.accent,"Wedge")
	end
end

function motifs.anchor(egg)
	local cf = surface(0,-0.13,0.078)
	spokes(egg,"Anchor shank",cf,2,0.048,0.25,gold,metal)
	for _, side in {-1,1} do
		piece(egg,"Anchor fluke",Vector3.new(0.053,0.123,0.03),cf*CFrame.new(side*0.09,-0.099,0)*CFrame.Angles(0,0,-side*0.61),gold,nil,metal)
	end
end

function motifs.lock(egg)
	local cf = surface(0,0.04,0.085)
	piece(egg,"Lock body",Vector3.new(0.22,0.17,0.06),cf,gold,nil,metal)
	piece(egg,"Keyhole",Vector3.new(0.047,0.079,0.021),cf*CFrame.new(0,0,-0.035),coal,sphere)
end

function motifs.coins(egg)
	for i=-1,1 do
		local x = i*0.115
		solid(egg,"Gold coin",{0.05,0.14,0.14},x,-0.31+math.abs(i)*0.08,-0.42,gold,nil,math.pi/4+i*0.21,0,metal)
	end
end

function motifs.fossil(egg)
	for i=0,9 do
		local angle = i*0.86
		local size = 0.038+0.006*i
		bead(egg,"Fossil spiral",math.cos(angle)*size*i,math.sin(angle)*size*i*0.58,size+0.028,size+0.016,egg.accent,nil,0.042,angle)
	end
end

function motifs.ridge(egg) styles.Dinosaur(egg) end
function motifs.wizard(egg)
	solid(egg,"Wizard brim",{0.92,0.093,0.83},0,0.50,0,egg.accent,sphere)
	for i=1,4 do
		local span = 0.66-i*0.115
		solid(egg,"Bent wizard peak",{span,0.16,span},i*0.036,0.49+0.136*i,0,egg.accent,sphere,0,-0.23)
	end
end

function motifs.bottle(egg)
	solid(egg,"Flask neck",{0.29,0.23,0.28},0,0.65,0,egg.accent,sphere)
	solid(egg,"Flask stopper",{0.30,0.13,0.29},0,0.78,0,gold,sphere)
	ring(egg,"Potion fill line",0.49,-0.15,0.11,0.034,0.021,{white},neon,12)
end

function motifs.bubble(egg)
	for i=1,5 do
		local size = i%2==0 and 0.097 or 0.059
		bead(egg,"Suspended bubble",i*0.58-1.55,(i%3-1)*0.24,size,size,white,nil,0.076)
	end
end

function motifs.book(egg)
	local cf = surface(0,-0.089,0.08)*CFrame.Angles(0,0,0.19)
	piece(egg,"Book pages",Vector3.new(0.28,0.33,0.11),cf,cream)
	piece(egg,"Book cover",Vector3.new(0.30,0.36,0.055),cf*CFrame.new(0,0,-0.057),egg.accent)
	piece(egg,"Book spine",Vector3.new(0.058,0.36,0.14),cf*CFrame.new(-0.127,0,0),coal)
end

function motifs.flame(egg)
	for i=-1,1 do
		solid(egg,"Flame feather",{0.15,0.38+0.07*(i%2),0.21},0.12*i,0.67,0.15,egg.accent,"Wedge",0,i*0.29,neon)
	end
end

function motifs.orbit(egg)
	for i=1,3 do
		local phase = i*tau/3
		local dot = solid(egg,"Orbit mote",{0.11,0.11,0.11},math.cos(phase)*0.69,0.18+0.1*math.sin(phase),math.sin(phase)*0.69,
			i==1 and white or egg.accent,sphere,0,0,neon)
		dot:SetAttribute("OrbitPhase",phase)
		if not egg.anchored then
			local light = Instance.new("PointLight",dot)
			light.Color = egg.accent
			light.Range = 2.5
			light.Brightness = 0.5
		end
	end
end

function motifs.star(egg)
	for i=0,4 do
		spokes(egg,"Hand-drawn star",surface(0.67*i-1.2,(i%2)*0.36-0.12,0.06),2,0.031,0.11,cream,neon)
	end
end

function motifs.cloud(egg)
	for i=-2,2 do
		solid(egg,"Cloud tuft",{0.36,0.28+i%2*0.1,0.30},i*0.20,-0.29+i%2*0.1,0.24,white,sphere)
	end
end

function motifs.bolt(egg)
	line(egg,"Lightning bolt",{{0.24,0.44},{-0.23,0.05},{0.25,0.051},{-0.17,-0.39}},0.1,gold,neon,0.067)
end

function motifs.halo(egg) ring(egg,"Radiant halo",0.6,0.21,0.24,0.048,0.041,{egg.accent,cream},neon,12) end

function motifs.candy(egg)
	for i=-1,1 do
		solid(egg,"Candy button",{0.12,0.16,0.067},i*0.16,-0.09-math.abs(i)*0.04,-0.51,if i==0 then egg.accent else cream,sphere)
	end
	ring(egg,"Sugar stripe",0.392,0.43,0.06,0.12,0.03,{egg.accent,white},plastic,12)
end

function motifs.fringe(egg)
	for i=1,9 do
		bead(egg,"Hanging tassel",i*tau/9,-0.32,0.09,0.19,gold,nil,0.048,i%2*0.19)
	end
end

function motifs.crest(egg)
	local cf = surface(0,0.04,0.074)
	piece(egg,"Crest shield",Vector3.new(0.29,0.36,0.061),cf,egg.accent,"Wedge",metal)
	spokes(egg,"Crest badge",cf*CFrame.new(0,0,-0.051),2,0.042,0.16,cream)
end

function motifs.visor(egg)
	solid(egg,"Tinted visor",{0.61,0.23,0.16},0,0.12,-0.47,ocean,sphere,0,0,metal)
	solid(egg,"Visor reflection",{0.19,0.048,0.028},-0.14,0.16,-0.549,egg.accent,sphere,0,-0.13)
end

function motifs.crown(egg) styles.Royal(egg) end

function motifs.orb(egg)
	solid(egg,"Orb cradle",{0.31,0.071,0.26},0,-0.06,-0.52,gold,sphere,0,0,metal)
	solid(egg,"Glassy orb",{0.22,0.22,0.22},0,0.04,-0.56,egg.accent,sphere,0,0,Enum.Material.Glass)
end

function motifs.mirror(egg)
	solid(egg,"Mirror rim",{0.32,0.36,0.095},0,0.1,-0.487,gold,sphere,0,-0.23,metal)
	solid(egg,"Silver mirror",{0.23,0.26,0.043},0,0.10,-0.543,white,sphere,0,-0.23,metal)
end

function motifs.flare(egg)
	for i=0,5 do
		local cf = CFrame.Angles(0,i*tau/6,0)*CFrame.new(0,0.06,-0.57)*CFrame.Angles(-0.52,0,0)
		piece(egg,"Rayed prism",Vector3.new(0.08,0.25,0.09),cf,egg.accent,"Wedge",neon)
	end
end

function motifs.helmet(egg)
	ring(egg,"Pressure helmet collar",0.451,-0.303,0,0.11,0.07,{cream,egg.accent},metal,12)
	solid(egg,"Helmet shield",{0.68,0.46,0.23},0,0.15,-0.40,ocean,sphere,0,0,metal)
	for _, side in {-1,1} do
		solid(egg,"Helmet latch",{0.13,0.24,0.18},side*0.431,0.12,-0.048,egg.accent,sphere)
	end
end

function motifs.pack(egg)
	solid(egg,"Courier pack",{0.43,0.47,0.27},0,-0.025,0.452,egg.accent,nil,0,0,metal)
	for _, side in {-1,1} do
		solid(egg,"Pack latch",{0.09,0.16,0.06},side*0.13,0.11,0.603,cream,nil)
	end
end

function motifs.crater(egg)
	for i=1,5 do
		local theta,y = i*2.4,(i%3-1)*0.28
		bead(egg,"Crater rim",theta,y,0.18,0.145,egg.accent,nil,0.055)
		bead(egg,"Crater hollow",theta,y,0.11,0.079,ocean,nil,0.076)
	end
end

function motifs.planet(egg)
	ring(egg,"Planetary ring",0.65,-0.05,-0.37,0.052,0.098,{egg.accent},metal,12)
	solid(egg,"Companion planet",{0.24,0.24,0.24},0.58,0.43,0.13,cream,sphere)
end

function motifs.checker(egg)
	for i=0,11 do
		for row=-1,0 do
			piece(egg,"Racing check",Vector3.new(0.13,0.122,0.025),surface(i*tau/12,row*0.12-0.22,0.035),
				(i+row)%2==0 and white or ocean)
		end
	end
end

function motifs.medal(egg)
	ring(egg,"Ribbon collar",0.48,-0.25,0,0.069,0.036,{egg.accent},plastic,10)
	solid(egg,"Racer medal",{0.21,0.24,0.073},0,-0.31,-0.472,gold,sphere,0,0,metal)
	solid(egg,"Stamped medal",{0.105,0.11,0.044},0,-0.3,-0.507,cream,sphere)
end

function motifs.torch(egg)
	solid(egg,"Torch handle",{0.095,0.42,0.11},0.48,0.05,0.059,gold)
	solid(egg,"Torch flame",{0.18,0.25,0.16},0.48,0.35,0.059,egg.accent,"Wedge",0,0.35,neon)
end

function motifs.trophy(egg)
	solid(egg,"Trophy stem",{0.13,0.19,0.10},0,0.61,0.01,gold)
	solid(egg,"Trophy bowl",{0.39,0.29,0.28},0,0.81,0.01,gold,sphere,0,0,metal)
	for _, side in {-1,1} do
		solid(egg,"Trophy handle",{0.14,0.15,0.073},side*0.189,0.80,0.015,egg.accent,sphere)
	end
end

function motifs.hood(egg)
	solid(egg,"Hood fabric",{0.77,0.38,0.74},0,0.47,0.04,egg.accent,sphere)
	ring(egg,"Hood stitching",0.355,0.48,0,0.048,0.029,{white},plastic,10)
end

function motifs.boot(egg)
	for _, side in {-1,1} do
		solid(egg,"Rounded boot",{0.24,0.17,0.41},side*0.28,-0.53,-0.12,egg.accent,sphere)
		solid(egg,"Boot sole",{0.23,0.055,0.39},side*0.28,-0.60,-0.12,ocean,sphere)
	end
end

function motifs.chef(egg)
	for i=0,2 do
		solid(egg,"Chef cap puff",{0.32,0.31,0.31},math.cos(i*tau/3)*0.12,0.73,math.sin(i*tau/3)*0.12,white,sphere)
	end
	ring(egg,"Chef cap brim",0.26,0.63,0,0.10,0.04,{cream},plastic,10)
end

function motifs.apron(egg)
	piece(egg,"Canvas apron",Vector3.new(0.37,0.37,0.053),surface(0,-0.22,0.045),cream)
	piece(egg,"Deep apron pocket",Vector3.new(0.23,0.135,0.058),surface(0,-0.29,0.07),egg.accent)
end

function motifs.wheel(egg)
	for side=-1,1,2 do
		local cf = CFrame.new(side*0.43,-0.42,0.09)*CFrame.Angles(0,side*math.pi/2,0)
		piece(egg,"Cart wheel",Vector3.new(0.31,0.31,0.12),cf,coal,sphere)
		spokes(egg,"Wheel spoke",cf*CFrame.new(0,0,-0.066),3,0.035,0.235,gold,metal)
	end
end

function motifs.ship(egg)
	solid(egg,"Carved hull",{1.05,0.28,0.72},0,-0.42,0.035,ocean,sphere)
	ring(egg,"Hull trim",0.46,-0.35,0,0.052,0.066,{egg.accent},metal,10)
end

function motifs.sail(egg)
	solid(egg,"Sail mast",{0.063,0.59,0.068},0,0.58,0.29,gold)
	solid(egg,"Pressed canvas",{0.52,0.44,0.13},0,0.68,0.31,cream,"Wedge",0,-0.31)
end

function motifs.tentacle(egg)
	for i=0,3 do
		local rotation = CFrame.Angles(0,i*tau/4+0.37,0)
		local a = rotation * Vector3.new(0.32,-0.32,0)
		local b = rotation * Vector3.new(0.58,-0.4,0)
		local c = rotation * Vector3.new(0.68,-0.23,0)
		segment(egg,"Tentacle base",a,b,0.13,0.11,egg.accent)
		segment(egg,"Tentacle end",b,c,0.087,0.08,egg.accent)
		piece(egg,"Tentacle suction pad",Vector3.new(0.08,0.08,0.055),CFrame.new(b),cream,sphere)
	end
end

function motifs.compass(egg)
	local cf = surface(0,0.0,0.08)
	piece(egg,"Compass housing",Vector3.new(0.31,0.31,0.065),cf,gold,sphere,metal)
	piece(egg,"Compass dial",Vector3.new(0.25,0.25,0.05),cf*CFrame.new(0,0,-0.037),ocean,sphere)
	spokes(egg,"Compass needle",cf*CFrame.new(0,0,-0.064)*CFrame.Angles(0,0,0.45),2,0.027,0.204,egg.accent,neon)
end

function motifs.horn(egg)
	for _, side in {-1,1} do
		solid(egg,"Paired horn",{0.16,0.28,0.14},side*0.33,0.57,-0.14,cream,"Wedge",0,-side*0.27)
	end
end

function motifs.solar(egg)
	for _, side in {-1,1} do
		solid(egg,"Solar foil",{0.37,0.033,0.25},side*0.53,-0.22,0.17,rgb("5778af"),nil,0,side*0.15,metal)
		solid(egg,"Solar trace",{0.3,0.041,0.023},side*0.53,-0.187,0.17,egg.accent,nil,0,side*0.15,neon)
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
	local skin = Cosmetics.byId[id] or Cosmetics.byId.Classic
	local shellColor = rgb(skin.shell)
	local model = Instance.new("Model")
	model.Name = "CourierEgg"
	local egg = {
		model=model, width=width, anchored=anchored == true, accent=rgb(skin.accent),
	}
	local material = if id == "Frozen" then Enum.Material.Ice
		elseif (id == "Golden" or skin.rank >= 5) then metal else plastic
	model.PrimaryPart = piece(egg,"Shell",Vector3.new(1,shellHeight,1),CFrame.identity,shellColor,sphere,material)
	local style = styles[id]
	if style then style(egg) end
	for motif in string.gmatch(skin.style,"%S+") do
		motifs[motif](egg)
	end
	local paleCrack = shellColor.R*0.2126+shellColor.G*0.7152+shellColor.B*0.0722 < 0.43
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

-- Preview clients animate the orbit parts only on the model currently in view.
-- World copies keep their low-cost welded orbit markers.
function EggModel.previewPose(model, angle, elapsed)
	local cf = CFrame.Angles(0,angle,0)
	model:PivotTo(cf)
	local width = model.PrimaryPart.Size.X
	for _, part in ipairs(model:GetChildren()) do
		local phase = part:GetAttribute("OrbitPhase")
		if phase then
			local spin = phase+elapsed*1.45
			part.CFrame = cf*CFrame.new(math.cos(spin)*width*0.69,(0.18+0.11*math.sin(2*spin))*width,math.sin(spin)*width*0.69)
		end
	end
end

return EggModel
