local V, C, RGB = Vector3.new, CFrame.new, Color3.fromRGB
local M = Enum.Material
local palette = {
	asphalt=RGB(58,65,74), concrete=RGB(183,175,157), cream=RGB(241,216,169),
	dark=RGB(38,52,65), glass=RGB(101,157,173), grass=RGB(88,124,82),
	trim=RGB(248,223,181), teal=RGB(69,128,132), wood=RGB(130,88,55),
	light=RGB(255,204,133), brick=RGB(163,87,76), linen=RGB(230,177,108),
}
local W = {}
function W.build()
	local map=Instance.new("Folder")
	map.Name,map.Parent="Riverside",workspace
	local base=workspace:FindFirstChild("Baseplate")
	if base then base:Destroy() end
	local function group(name)
		local folder=Instance.new("Folder")
		folder.Name,folder.Parent=name,map
		return folder
	end
	local function part(parent,name,s,x,y,z,color,material)
		local p=Instance.new("Part")
		p.Name,p.Size,p.CFrame,p.Color=name,s,C(x,y,z),color
		p.Anchored,p.Material,p.TopSurface,p.BottomSurface=true,material or M.SmoothPlastic,Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
		p.Parent=parent
		return p
	end
	local function sign(parent,text,s,x,y,z,color)
		local board=part(parent,"Sign · "..text,s,x,y,z,color)
		local face=Instance.new("SurfaceGui")
		face.Face,face.LightInfluence,face.Parent=Enum.NormalId.Front,.25,board
		local word=Instance.new("TextLabel")
		word.Size,word.Text,word.Font=UDim2.fromScale(1,1),text,Enum.Font.GothamBold
		word.BackgroundTransparency,word.TextScaled,word.TextColor3,word.Parent=1,true,palette.cream,face
		word.Position,word.Size=UDim2.fromScale(.06,.1),UDim2.fromScale(.88,.8)
		local textSize=Instance.new("UITextSizeConstraint")
		textSize.MinTextSize,textSize.MaxTextSize,textSize.Parent=8,60,word
		return board
	end
	local function light(parent,name,x,y,z,brightness)
		local bulb=part(parent,name,V(.6,.28,.61),x,y,z,palette.light,M.Neon)
		local point=Instance.new("PointLight")
		point.Name,point.Range,point.Brightness,point.Color,point.Shadows,point.Parent="Bulb",25,brightness,palette.light,true,bulb
		return point
	end
	local streets=group("Streets and crossings")
	part(streets,"Neighborhood grounds",V(240,1,200),0,-.52,3,palette.grass,M.Grass)
	for _,z in {-60,-16,34,73} do
		part(streets,"Avenue asphalt",V(195,.12,11),0,.015,z,palette.asphalt,M.Asphalt)
		for x=-90,90,8 do part(streets,"Center stripe",V(3,.018,.11),x,.08,z,palette.linen) end
		for _,offset in {-7,7} do
			part(streets,"Raised sidewalk",V(198,.24,3.6),0,.08,z+offset,palette.concrete,M.Pavement)
		end
	end
	for _,x in {-68,0,69} do
		part(streets,"Cross street asphalt",V(11,.13,146),x,.017,8,palette.asphalt,M.Asphalt)
		for _,offset in {-7,7} do
			part(streets,"Cross street sidewalk",V(3.7,.25,147),x+offset,.08,8,palette.concrete,M.Pavement)
		end
		for _,z in {-60,-16,34,73} do
			part(streets,"Intersection",V(14,.25,11.5),x,.071,z,palette.asphalt,M.Asphalt)
			for i=-4,4,2 do
				part(streets,"Zebra stripe",V(.71,.014,2.9),x+i,.205,z+3.9,palette.cream)
			end
		end
	end
	local greens=group("Garden strips and street furniture")
	local function tree(x,z,scale)
		part(greens,"Bark",V(.62,6.2,.63)*scale,x,3.1*scale,z,palette.wood,M.Wood)
		for i=1,4 do
			local p=part(greens,"Leaf crown",V(3.5,3.1,3.9)*scale,x+math.cos(i*2)*scale,(5.2+i*.43)*scale,z+math.sin(i*2)*scale,
				RGB(65+i*9,106+i*10,73+i*4),M.Grass)
			p.Shape=Enum.PartType.Ball
		end
	end
	for _,z in {-53,-25,27,64} do
		for _,x in {-89,-55,-33,-15,16,36,53,87} do tree(x,z,1+(x%4)*.1) end
	end
	for _,x in {-62,-47,-25,16,33,55,80} do
		for _,z in {-9,-53,28} do
			part(greens,"Lamp post",V(.17,6.2,.17),x,3.1,z,palette.dark,M.Metal)
			light(greens,"Street lantern",x,6.24,z,1.04)
		end
	end
	local buildings=group("Mixed-use blocks")
	local waterfront=group("Riverfront and town square")
	part(waterfront,"Slate riverbank",V(205,.55,7.9),0,.1,86,palette.concrete,M.Slate)
	part(waterfront,"Shallow river",V(245,.19,22),0,-.015,100,RGB(75,136,154),M.Glass)
	for i=1,76 do
		local x=(i*47)%218-108
		local glint=part(waterfront,"Water glint",V(1.4+i%5,.015,.11),x,.09,91+(i*13)%17,RGB(120,178,176),M.SmoothPlastic)
		glint.CanCollide=false
	end
	for x=-94,94,6 do
		part(waterfront,"River rail post",V(.17,2.18,.17),x,1.46,89,palette.dark,M.Metal)
		if x<92 then part(waterfront,"River rail",V(6.1,.16,.12),x+3,2.39,89,palette.dark,M.Metal) end
		if x%18==0 then
			part(waterfront,"Pedestrian bench",V(4.5,.17,1.2),x,1.42,85.36,palette.wood,M.WoodPlanks)
			for _,dx in {-1.55,1.55} do
				part(waterfront,"Bench support",V(.13,1.2,.8),x+dx,.88,85.36,palette.dark,M.Metal)
			end
		end
	end
	part(waterfront,"Town square paving",V(33,.2,21),-53,.09,18,RGB(178,161,144),M.Pavement)
	for i=-4,4 do
		part(waterfront,"Square paving band",V(.07,.026,20.7),-53+i*3.75,.197,18,RGB(151,142,130),M.Slate)
	end
	local basin=part(waterfront,"Fountain bowl",V(.85,6.8,6.8),-53,.59,18,palette.cream,M.Marble)
	basin.Shape,basin.CFrame=Enum.PartType.Cylinder,basin.CFrame*CFrame.Angles(0,0,math.pi/2)
	local water=part(waterfront,"Fountain water",V(.12,6,6),-53,1.04,18,RGB(100,173,176),M.Glass)
	water.Shape,water.CFrame=Enum.PartType.Cylinder,water.CFrame*CFrame.Angles(0,0,math.pi/2)
	part(waterfront,"Memorial base",V(1.55,.91,1.55),-53,1.45,18,palette.teal,M.Slate)
	sign(waterfront,"RIVERSIDE SQUARE",V(5.8,.83,.17),-55,2.77,12.6,palette.dark)
	for _,x in {-63,-44} do
		tree(x,24,1.25)
		part(waterfront,"Stone planter",V(4.3,.61,3.4),x,.38,24,palette.cream,M.Slate)
	end
	local function storefront(name,x,z,width,depth,height,color,accessible)
		local group=Instance.new("Folder")
		group.Name,group.Parent=name,buildings
		part(group,"Footing",V(width+.8,.27,depth+.6),x,.08,z,palette.concrete,M.Concrete)
		for _,offset in {-width/2,width/2} do
			part(group,"Side masonry",V(.45,height,depth),x+offset,height/2,z,color,M.Brick)
		end
		part(group,"Rear masonry",V(width,height,.5),x,height/2,z+depth/2,color,M.Brick)
		local front=z-depth/2
		part(group,"Upper frontage",V(width,height-5,.45),x,5+(height-5)/2,front,color,M.Brick)
		for _,side in {-1,1} do
			local paneWidth=(width-3.8)/2
			local px=x+side*(1.9+paneWidth/2)
			part(group,"Sill course",V(paneWidth,1,.45),px,.53,front,color,M.Brick)
			local glass=part(group,"Store window",V(paneWidth,3.9,.2),px,3,front,palette.glass,M.Glass)
			glass.Transparency=accessible and .60 or .17
			for dx=-paneWidth/2+.5,paneWidth/2-.3,2.5 do
				part(group,"Glazing mullion",V(.14,4,.27),px+dx,2.99,front,palette.trim)
			end
		end
		if not accessible then part(group,"Entry door",V(3.6,4.85,.3),x,2.53,front,palette.dark,M.WoodPlanks) end
		part(group,"Cornice",V(width+.7,.48,depth+.65),x,height,z,palette.cream,M.Concrete)
		part(group,"Roof rim",V(width+.76,.23,depth+.71),x,height+.31,z,palette.dark,M.Slate)
		for _,offset in {-1,1} do
			part(group,"Corner trim",V(.29,height+.15,.42),x+offset*(width/2-.23),height/2,front-.26,palette.trim,M.Concrete)
		end
		if name=="Terrace Homes" or name=="Apartments" then
			part(group,"Residential canopy",V(4.7,.17,2),x,4.7,front-1,palette.dark,M.Metal)
			part(group,"Front step",V(4.1,.19,1.12),x,.18,front-.65,palette.concrete,M.Slate)
			for _,dx in {-3.5,3.5} do
				part(group,"Front garden planter",V(2.8,.5,1.5),x+dx,.29,front-1.42,palette.wood,M.Wood)
				local shrub=part(group,"Front garden foliage",V(2.5,.88,1.34),x+dx,.86,front-1.41,palette.grass,M.Grass)
				shrub.Shape=Enum.PartType.Ball
			end
		end
		part(group,"Canvas canopy",V(width+.25,.26,2.2),x,5.35,front-.85,palette.teal,M.Fabric)
		for xx=-width/2+.65,width/2-.3,1.3 do
			part(group,"Canopy stripe",V(.59,.31,2.22),x+xx,5.35,front-.85,palette.cream,M.Fabric)
		end
		for y=8,height-1.4,4 do
			for dx=-width/2+2.35,width/2-1,4.6 do
				part(group,"Window casing",V(2.48,2.55,.22),x+dx,y,front-.27,palette.trim)
				part(group,"Upper pane",V(2.1,2.22,.25),x+dx,y,front-.37,palette.glass,M.Glass)
				part(group,"Crossbar",V(.10,2.24,.28),x+dx,y,front-.49,palette.dark)
			end
		end
		sign(group,name,V(width*.72,.89,.19),x,6.15,front-.32,palette.dark)
		return group
	end
	local bakery=storefront("Morrow Bakery",-23,1,16,12,12,palette.brick,true)
	part(bakery,"Pastry case",V(5.8,2.7,1.45),-27.1,1.54,.6,palette.wood,M.WoodPlanks)
	light(bakery,"Interior pendant",-23,4.6,.8,1.85)
	for i=1,7 do
		local bread=part(bakery,"Pastry",V(.46,.34,.49),-29.6+i*.64,3.09,.59,palette.linen)
		bread.Shape=Enum.PartType.Ball
	end
	local market=storefront("Market",-46,1,17,14,14,RGB(113,145,141),true)
	for _,x in {-51,-41} do
		for _,z in {-.75,2.35,5.52} do
			part(market,"Display table",V(3,1.67,.95),x,1.03,z,palette.wood,M.Wood)
			for i=1,5 do
				local crate=part(market,"Fruit display",V(.4,.32,.58),x-1.32+i*.44,2.03,z,i%2==0 and palette.brick or palette.linen)
				crate.Shape=Enum.PartType.Ball
			end
		end
	end
	light(market,"Market lamps",-46,4.6,1.4,1.8)
	storefront("Barber",12,1,12,13,11,RGB(193,139,91),false)
	storefront("Corner Books",28,1,15,13,14,RGB(120,137,167),true)
	local library=storefront("Library",89,4,19,14,16,RGB(161,116,103),true)
	for _,x in {83,95} do
		for _,y in {1.2,2.15,3.05} do
			part(library,"Book shelf",V(1.63,.13,5.4),x,y,5.1,palette.wood,M.Wood)
			for i=1,13 do
				part(library,"Book spine",V(.75,.42+(i%3)*.09,.32),x,y+.34,2.58+i*.37,
					({palette.teal,palette.linen,palette.brick})[i%3+1],M.SmoothPlastic)
			end
		end
	end
	light(library,"Reader's lamp",89,4.25,4,1.62)
	local school=storefront("Riverside High",-29,18,24,15,16,RGB(166,125,97),true)
	sign(school,"RIVERSIDE HIGH · WELCOME",V(8,1.2,.18),-29,4.6,24.39,palette.dark)
	for _,x in {-38,-35,-32,-26,-23,-20} do
		part(school,"Locker",V(1.12,3.9,.67),x,2.21,24.3,palette.teal,M.Metal)
		part(school,"Locker vent",V(.5,.11,.055),x,3.5,23.94,palette.dark)
	end
	light(school,"Lobby overhead",-29,5.13,18,1.9)
	storefront("Medical Centre",28,-41,19,15,13,RGB(156,163,141),true)
	storefront("Florist",-27,-41,14,14,12,RGB(143,108,132),true)
	for _,z in {-42,51,60} do
		for _,x in {-89,-48,-28,-12,13,31,50,90} do
			if not (z==-42 and (math.abs(x+27)<7 or math.abs(x-28)<7)) then
				local color=({RGB(154,117,109),RGB(125,149,150),RGB(173,150,111),RGB(130,135,160)})[x%4+1]
				storefront(z<0 and "Apartments" or "Terrace Homes",x,z,12,8,9+x%3,color,false)
			end
		end
	end
	local transit=group("Riverside transit")
	for _,x in {-42,25} do
		part(transit,"Bus platform",V(16,.28,4),x,.14,-8,palette.concrete,M.Pavement)
		part(transit,"Shelter roof",V(7.7,.2,2.3),x,5.21,-6.1,palette.teal,M.Metal)
		for _,dx in {-3.5,3.5} do part(transit,"Shelter post",V(.16,5,.18),x+dx,2.64,-5.26,palette.dark,M.Metal) end
		part(transit,"Bench",V(4.9,.21,1),x,1.45,-5.77,palette.wood,M.WoodPlanks)
		sign(transit,x<0 and "1 · MARKET" or "2 · RIVER PARK",V(5.4,.8,.16),x,4.55,-6.06,palette.dark)
		part(transit,"Route marker",V(.16,5.6,.16),x-5,2.9,-8.77,palette.dark,M.Metal)
	end
	local park=group("Riverside Park")
	for xx=38.5,58.5,2.5 do
		part(park,"Court rear upright",V(.14,3.2,.16),xx,1.7,20.7,palette.dark,M.Metal)
		part(park,"Court rear rail",V(2.55,.13,.13),xx-1.25,3.25,20.7,palette.dark,M.Metal)
	end
	for z=4.4,18.6,2.35 do
		part(park,"Court sideline fencing post",V(.13,2.55,.15),59.35,1.38,z,palette.dark,M.Metal)
		part(park,"Court sideline top rail",V(.14,.1,2.4),59.35,2.68,z-.55,palette.dark,M.Metal)
	end
	for _,x in {34.45,36.27} do part(park,"Gate pier",V(.23,3.5,.23),x,1.88,2.05,palette.dark,M.Metal) end
	light(park,"Park entry lantern",34.45,3.64,2.05,1.47)
	part(park,"Park bench seat",V(3.5,.2,1.15),34.7,1.37,1.7,palette.wood,M.WoodPlanks)
	part(park,"Park bench back",V(3.5,.27,.15),34.7,1.77,2.16,palette.wood,M.WoodPlanks)
	for _,x in {33.45,35.95} do part(park,"Park bench legs",V(.13,1.1,.85),x,.75,1.72,palette.dark,M.Metal) end
	part(park,"Basketball asphalt",V(21,.2,18),48,.08,11,RGB(104,104,123),M.Pavement)
	for _,z in {3,11,19} do part(park,"Court line",V(19,.023,.13),48,.197,z,palette.cream) end
	for _,x in {38,57.8} do part(park,"Sideline",V(.12,.025,16),x,.198,11,palette.cream) end
	part(park,"Goal post",V(.23,7,.24),53,3.5,17.3,palette.dark,M.Metal)
	part(park,"Backboard",V(3.5,1.95,.16),53,6.73,17.1,palette.cream)
	for i=1,18 do
		local angle=i*math.pi/9
		part(park,"Rim",V(.24,.11,.23),53+math.cos(angle)*.77,6.11,16.38+math.sin(angle)*.77,palette.brick,M.Metal)
	end
	for _,x in {37.8,58.4} do
		part(park,"Floodlight mast",V(.23,9,.23),x,4.5,18,palette.dark,M.Metal)
		local flood=light(park,"Court floodlight",x,9.16,18,2.8)
		flood.Range=42
	end
	part(park,"Electricity box",V(.78,2,.35),37.25,1.15,3.12,palette.teal,M.Metal)
	part(park,"Park path",V(6,.15,29),32,.04,7,palette.concrete,M.Pavement)
	sign(park,"RIVERSIDE PARK",V(6.5,.7,.17),32,3.3,-1.6,palette.dark)
	for _,x in {38,48,59} do tree(x,24,.91) end
	local spawn=Instance.new("SpawnLocation")
	spawn.Name,spawn.Size,spawn.CFrame,spawn.Anchored="Town entrance",V(4,.22,4),C(-31,.2,-8.1),true
	spawn.Transparency,spawn.Neutral,spawn.Duration,spawn.Parent=1,true,0,map
	return map
end
return W
