local V = Vector3.new
local RGB = Color3.fromRGB
local M = Enum.Material
local W = {}
W.origins = {School = V(0,0,0), Yard = V(155,0,0), Shop = V(325,0,0), Street = V(500,0,0), Home = V(665,0,0), River = V(850,0,0)}
local wood, brass, paper = RGB(111,71,43), RGB(204,151,65), RGB(239,219,177)
local cream, brick, ink = RGB(228,202,166), RGB(135,72,63), RGB(35,42,48)
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material, p.Anchored, p.TopSurface, p.BottomSurface = material or M.SmoothPlastic, true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function label(p, face, message, color, bg)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.LightInfluence, gui.Parent = face, 0.22, p
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1,1), bg and 0 or 1
	text.BackgroundColor3, text.TextColor3 = bg or ink, color
	text.Font, text.TextScaled, text.Text = Enum.Font.GothamBold, true, message
	text.Parent = gui
	return text
end
local function lamp(p, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows, l.Parent = color, range, brightness, true, p
end
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name, m.Parent = name, parent
	return m
end
local function disk(parent, name, diameter, depth, cf, color, material)
	local p = part(parent, name, V(depth,diameter,diameter), cf * CFrame.Angles(0,math.pi/2,0), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function W.build()
	local root = Instance.new("Folder")
	root.Name, root.Parent = "SecondChances", workspace
	local base = workspace:FindFirstChild("Baseplate")
	if base then base:Destroy() end
	for name, origin in W.origins do
		local set = model(root,name)
		local function block(n,s,x,y,z,c,m)
			return part(set,n,s,CFrame.new(origin+V(x,y,z)),c,m)
		end
		local function sign(n, message, s,x,y,z,c)
			local p = block(n,s,x,y,z,c or ink)
			label(p, Enum.NormalId.Front,message,paper)
			return p
		end
		local function floor(c)
			block("Ground",V(136,1,160),0,-0.55,0,c,M.Concrete)
		end
		local function window(x,y,z)
			block("Window surround",V(5.5,5.2,0.3),x,y,z,ink)
			block("Blue glass",V(5.1,4.8,0.35),x,y,z,RGB(108,165,177),M.Glass)
			block("Mullion",V(0.13,4.9,0.42),x,y,z,cream)
			block("Sill",V(5.7,0.18,0.8),x,y-2.45,z,cream)
		end
		local function tree(x,z,scale)
			block("Trunk",V(0.85,8,0.9)*scale,x,4*scale,z,wood,M.Wood)
			for i=1,4 do
				local canopy = block("Canopy",V(5,4,5)*scale,x+math.cos(i*2)*scale*1.5,(7+i*.65)*scale,z+math.sin(i*2)*scale*1.5,
					RGB(41+i*7,76+i*12,48+i*4),M.Grass)
				canopy.Shape = Enum.PartType.Ball
			end
		end
		local function facade(x,z,w,h,c)
			block("Masonry frontage",V(w,h,2.8),x,h/2,z,c,M.Brick)
			block("Cornice",V(w+0.6,.5,3.3),x,h,z,cream)
			for y=6,h-2,6 do
				for dx=-w/2+3,w/2-2,6 do
					window(x+dx,y,z-1.55)
				end
			end
		end
		local function street()
			floor(RGB(79,95,73))
			local road=block("Asphalt",V(115,.12,13),0,.01,-23,RGB(47,60,67),M.Asphalt)
			if name=="Shop" then
				road.Reflectance=.08
				for i=1,17 do
					local wet=block("Rain sheen",V(i%4+1,.018,.4+i%3*.19),i*5.2-46,.08,-19-(i*7)%9,RGB(70,87,97),M.Glass)
					wet.Transparency=.28
				end
			end
			block("Pavement",V(105,.25,8),0,.02,-12,RGB(137,130,117),M.Pavement)
			for x=-51,51,6 do
				block("Road stripe",V(2.5,.02,.13),x,.09,-23,cream)
				block("Paving joint",V(.045,.02,7.9),x,.155,-12,ink)
			end
			for _,x in {-18,20} do
				block("Lamp post",V(.18,7,.18),x,3.5,-14,ink,M.Metal)
				local glass = block("Lantern",V(.68,.65,.68),x,7.2,-14,RGB(246,195,123),M.Neon)
				lamp(glass,glass.Color,13,1)
			end
		end
		if name == "School" then
			floor(RGB(157,145,125))
			block("Oak classroom floor",V(33,.15,31),0,0,0,cream,M.WoodPlanks)
			block("Front plaster",V(33,12,.4),0,6,13,RGB(122,160,156))
			block("Side plaster",V(.4,12,31),-16.5,6,0,RGB(187,192,167))
			block("Hall wall left",V(13,12,.4),-9.5,6,-15,cream)
			block("Hall wall right",V(12,12,.4),10,6,-15,cream)
			block("Corridor",V(31,.18,7),0,.015,-18.5,RGB(178,165,150),M.Pavement)
			for x=-13,13,2 do
				block("Lockers",V(1.8,5,1),x,2.5,-21,RGB(59,105,120),M.Metal)
				block("Locker vent",V(.9,.1,.04),x,4,-21.52,ink)
			end
			sign("Chalkboard","    AFTER-SCHOOL CLUBS\n    Art • River Cleanup • Drama",V(15,4,.22),0,6.3,12.7,RGB(43,81,76))
			sign("Project area","COMMUNITY PROJECTS",V(5,2,.2),10.8,6.1,12.7)
			for i,x in {-10,-4,4,10} do
				window(x,8.1,12.65)
				local fixture = block("Pendant",V(3,.12,1.6),x,10,2,cream,M.Neon)
				lamp(fixture,cream,16,.55)
			end
			for _,z in {-3,2,7} do
				for _,x in {-6,-2,2,6} do
					block("Desktop",V(2.65,.16,1.45),x,2.62,z+1.04,wood,M.Wood)
					for _,dx in {-1.08,1.08} do
						block("Desk frame",V(.12,2.56,.13),x+dx,1.28,z+1.45,ink,M.Metal)
					end
					block("Seat",V(1.65,.16,1.47),x,1.37,z-.14,RGB(53,105,110))
					block("Seat back",V(1.65,1.13,.13),x,1.87,z-.9,RGB(53,105,110))
					block("Notebook",V(.62,.055,.49),x+.58,2.73,z+.88,paper)
					block("School bag",V(.65,.92,.36),x+.9,.52,z-.62,RGB(83,90,115),M.Fabric)
				end
			end
			block("Teacher desk",V(5,2.8,1.45),-7,1.4,10.7,wood,M.Wood)
			block("Projector ceiling mount",V(.17,.72,.17),0,10.1,4.75,ink,M.Metal)
			block("Projector",V(1.05,.34,.72),0,9.65,4.75,ink,M.Metal)
			sign("Library notice","RETURN LIBRARY BOOKS",V(3.1,.83,.18),-10.3,5.7,12.66,RGB(133,83,61))
			sign("Club notice","RIVER CLEANUP\nSATURDAY",V(2.05,1.33,.16),10.3,4.35,12.63,RGB(49,99,103))
			block("Chalkboard rail",V(15.4,.16,.37),0,4.24,12.57,wood)
			for _,x in {-2,.8,3.9} do block("Chalk",V(.22,.06,.065),x,4.35,12.44,paper) end
			local clock = disk(set,"Classroom clock",1.6,.12,CFrame.new(origin+V(0,9.5,12.66)),paper)
			label(clock,Enum.NormalId.Right,"12\n9   •   3\n6",ink)
			block("Clock hand",V(.06,.48,.05),0,9.67,12.54,ink)
		elseif name == "Yard" then
			street()
			facade(0,7,37,14,brick)
			sign("School identification","RIVERSIDE HIGH",V(17,1.45,.3),0,5,4.9)
			block("School steps",V(16,.46,4),0,.22,3,cream,M.Concrete)
			block("Courtyard path",V(14,.13,20),0,.04,-6,cream,M.Pavement)
			for _,x in {-24,-15,15,24} do
				tree(x,-5,1)
				block("Brick planter",V(4,.6,4),x,.29,-5,brick,M.Brick)
			end
			for x=9,13,2 do
				block("Bike rack",V(.13,1.1,1.15),x,.55,-6,ink,M.Metal)
				for _,dz in {-0.55,0.55} do
					disk(set,"Bicycle wheel",.96,.08,CFrame.new(origin+V(x,.5,-6+dz))*CFrame.Angles(0,math.pi/2,0),ink,M.Rubber)
				end
			end
		elseif name == "Shop" then
			street()
			facade(-16,2,19,17,RGB(101,97,91))
			facade(16,2,19,20,brick)
			sign("Tailor window","ELM STREET TAILOR",V(7,1.05,.21),-13,4.8,.28,RGB(66,77,86))
			sign("Hardware window","RIVERSIDE HARDWARE",V(7.4,1.04,.22),14,4.75,.28,RGB(87,72,58))
			for _,x in {-10,10} do
				block("Rain gutter",V(.12,11,.14),x,5.5,.28,ink,M.Metal)
				block("Planter",V(2.15,.62,1.2),x,.37,-1.14,ink,M.Metal)
				block("Street shrub",V(1.85,.88,.9),x,.9,-1.14,RGB(61,94,66),M.Grass)
			end
			block("Shop floor",V(13,.24,17),0,.08,7,wood,M.WoodPlanks)
			block("Shop back",V(13,10,.5),0,5,15.5,RGB(63,71,64),M.WoodPlanks)
			for _,x in {-6.5,6.5} do
				block("Shop side",V(.45,10,17),x,5,7,RGB(87,74,59),M.WoodPlanks)
				for y=2,8,2 do
					block("Shelf",V(1.15,.18,9),x-math.sign(x)*.48,y,9,wood,M.Wood)
					for z=6,12,1.5 do
						block("Box and book spines",V(.65,.48+z%1,.92),x-math.sign(x)*.5,y+.37,z,RGB(112+z*4,84,55),M.Wood)
					end
				end
			end
			block("Ceiling",V(13,.35,17),0,10,7,RGB(76,65,51),M.Wood)
			block("Transom",V(13,3,.55),0,8.4,0,wood)
			for _,x in {-4.2,4.2} do
				block("Window plinth",V(4,2,.7),x,1,0,wood,M.WoodPlanks)
				local glass=block("Shop glass",V(3.85,4.85,.23),x,4.45,0,RGB(103,134,131),M.Glass)
				glass.Transparency=.5
				block("Window mullion",V(.2,5,.35),x,4.45,0,wood)
			end
			local title=sign("Shop title","SECOND CHANCES",V(10.5,1.5,.35),0,8.7,-.48,RGB(41,72,67))
			lamp(title,RGB(239,186,96),15,2)
			sign("Street warning","REFUNDS COST MORE",V(3.4,.4,.2),0,7.65,-.72,ink)
			sign("Counter warning","REFUNDS COST MORE",V(4.6,.53,.17),3.5,4.85,9.6,ink)
			block("Door jamb left",V(.22,7,.55),-1.93,3.5,0,wood)
			block("Door jamb right",V(.22,7,.55),1.93,3.5,0,wood)
			local door = model(set,"Door")
			door.WorldPivot = CFrame.new(origin+V(-1.8,0,0))
			part(door,"Door panel",V(3.55,2,.32),CFrame.new(origin+V(0,1.15,0)),wood,M.Wood)
			local pane=part(door,"Door glass",V(3.3,4.48,.14),CFrame.new(origin+V(0,4.4,0)),RGB(112,154,152),M.Glass)
			pane.Transparency=.65
			for _,x in {-1.7,1.7} do
				part(door,"Door stile",V(.22,6.65,.3),CFrame.new(origin+V(x,3.45,0)),wood,M.Wood)
			end
			part(door,"Brass pull",V(.13,.6,.28),CFrame.new(origin+V(1.43,3,-.26)),brass,M.Metal)
			block("Counter face",V(7,2.7,1.3),0,1.49,8.35,wood,M.WoodPlanks)
			block("Brass counter trim",V(7.15,.09,1.55),0,2.82,8.35,brass,M.Metal)
			block("Counter top",V(7.2,.14,1.6),0,2.94,8.35,RGB(79,103,96),M.Glass)
			block("Lamp stem",V(.1,1,.1),2.5,3.5,8.39,brass,M.Metal)
			local glow=block("Amber shade",V(.78,.39,.78),2.5,4,8.39,RGB(255,194,104),M.Neon)
			lamp(glow,glow.Color,19,2.1)
			for i=1,12 do
				local x=((i-1)%4-1.5)*2.6
				local y=4.2+math.floor((i-1)/4)*2
				local size=1.15+i%3*.21
				disk(set,"Clock case",size+.18,.25,CFrame.new(origin+V(x,y,15.08)),brass,M.Metal)
				disk(set,"Clock dial",size,.10,CFrame.new(origin+V(x,y,14.91)),paper)
				local hands=model(set,"Clock"..i)
				hands.WorldPivot=CFrame.new(origin+V(x,y,14.83))
				part(hands,"Second hand",V(.04,size*.45,.035),hands.WorldPivot*CFrame.new(0,size*.2,0),ink)
				part(hands,"Minute hand",V(size*.29,.065,.05),hands.WorldPivot*CFrame.new(size*.12,0,0),brick)
			end
		elseif name == "Home" or name == "Street" then
			street()
			for _,x in {-22,21,37} do
				facade(x,6,13,8, x>0 and RGB(102,138,139) or brick)
				tree(x+7,-3,1)
			end
			if name=="Home" then
				block("House foundation",V(16,.24,15),0,.04,6,cream,M.Concrete)
				block("Porch floor",V(12,.32,6),0,.05,-2.5,wood,M.WoodPlanks)
				block("Porch step",V(9,.16,1.8),0,.02,-6.1,cream,M.Concrete)
				block("Porch awning",V(14,.4,6.5),0,7,-2.5,RGB(56,88,89),M.Wood)
				for _,x in {-6,6} do
					block("Porch column",V(.36,7,.36),x,3.5,-5,cream)
					block("House front wall",V(6.3,9,.5),x*.79,4.5,.5,RGB(114,156,148),M.WoodPlanks)
					window(x*.78,5,.12)
					block("Flower box",V(3,.45,.86),x*.78,2.65,-.35,wood)
					for i=1,9 do
						local flower=block("Geranium",V(.35,.45,.35),x*.78+(i%5-2)*.52,2.99+i%2*.18,-.63+i%3*.2,RGB(186+i*5,68+i*5,85),M.Grass)
						flower.Shape=Enum.PartType.Ball
					end
				end
				block("Entry lintel",V(3,2.75,.45),0,7.65,.5,RGB(114,156,148),M.WoodPlanks)
				local door=model(set,"HouseDoor")
				door.WorldPivot=CFrame.new(origin+V(1.48,.21,.34))
				part(door,"Painted panel",V(2.93,6.03,.2),CFrame.new(origin+V(0,3.23,.34)),RGB(124,69,50),M.WoodPlanks)
				part(door,"Door knob",V(.15,.16,.18),CFrame.new(origin+V(-1.13,3.14,.16)),brass,M.Metal)
				block("Living room wall",V(16,9,.5),0,4.5,13,cream)
				block("House roof",V(17,.44,14.4),0,9,6.85,RGB(65,82,80),M.WoodPlanks)
				block("Side table",V(1.42,1.6,1.42),3.4,.88,10.65,wood,M.Wood)
				local innerLight=block("Living room lamp",V(.78,.48,.78),3.4,2.17,10.65,RGB(255,212,156),M.Neon)
				lamp(innerLight,innerLight.Color,12,1.2)
				for _,x in {-8,8} do block("Living room side",V(.4,9,13),x,4.5,7,cream) end
				block("Living room rug",V(9,.06,7),0,.2,6,RGB(126,68,61),M.Fabric)
				block("Sofa",V(6,1.25,2.05),0,.77,10.4,RGB(53,95,99),M.Fabric)
				block("Sofa back",V(6,1.9,.45),0,1.9,11.36,RGB(53,95,99),M.Fabric)
				sign("Entry number","24",V(.6,.47,.1),2,5.45,.11,ink)
			else
				facade(0,6,15,8,RGB(187,151,100))
				sign("River path wayfinding","RIVER PATH  →",V(5,1,.15),6,4,-7,RGB(48,91,72))
				for i=0,8 do tree(10+i*3,2+i%2*4,1+i%3*.15) end
			end
		else
			floor(RGB(74,110,68))
			block("River",V(133,.07,23),0,.04,-18,RGB(58,117,129),M.Glass)
			for i=1,44 do
				local x=(i*19)%125-62
				block("River glint",V(1.8+i%4*1.3,.018,.052),x,.092,-28+i%19,RGB(105,164,158),M.Neon)
			end
			block("River bank",V(100,.09,3.4),0,.025,-5.8,RGB(164,145,98),M.Ground)
			for i=1,39 do
				local x, z=(i*19)%113-56,(i*11)%32+3
				if math.abs(x)>11 or z>12 then tree(x,z,.73+i%5*.16) end
			end
			for _,x in {-3.5,3.5} do
				block("Support posts",V(.68,6.1,.68),x,3,2.5,wood,M.Wood)
			end
			for i=-5,5 do
				block("Platform boards",V(.89,.23,8.15),i*.9,4.65,1.5,wood,M.WoodPlanks)
			end
			for i=1,8 do
				block("Back boards",V(8.8,.49,.19),0,4.91+i*.51,5.45,RGB(107+i*3,72+i*2,49),M.WoodPlanks)
			end
			for _,x in {-4.9,4.9} do
				block("Railing",V(.15,.22,7.8),x,6.02,1.5,wood,M.Wood)
				for z=-2,5,1.13 do block("Railing spindle",V(.15,1.3,.15),x,5.35,z,wood,M.Wood) end
			end
			for _,x in {-2.6,2.6} do
				local roof=block("Roof",V(5.65,.19,6.1),x,9.8,2.6,RGB(74,94,69),M.WoodPlanks)
				roof.CFrame *= CFrame.Angles(0,0,-math.sign(x)*.23)
			end
			for _,x in {-1,1} do block("Ladder stile",V(.19,5.2,.19),x,2.59,-2.55,wood,M.Wood) end
			for i=1,8 do block("Ladder rung",V(2.12,.14,.22),0,i*.6,-2.55,cream,M.Wood) end
			local ladder=Instance.new("TrussPart")
			ladder.Name,ladder.Size,ladder.CFrame="Climbable ladder",V(2,5,2),CFrame.new(origin+V(0,2.5,-2.62))
			ladder.Transparency,ladder.Anchored,ladder.Parent=1,true,set
			block("Shared bench",V(5,.2,1.2),0,5.9,2.5,wood,M.WoodPlanks)
			block("Bench foot left",V(.25,1.14,.32),-1.8,5.29,2.5,wood,M.Wood)
			block("Bench foot right",V(.25,1.14,.32),1.8,5.29,2.5,wood,M.Wood)
			local signPart=sign("Hand-painted sign","NOAH + LUCAS\nRIVER CLUB",V(4.6,1.6,.17),0,7.65,5.27,RGB(45,105,108))
			signPart.CFrame *= CFrame.Angles(0,0,.06)
		end
	end
	return root
end
return W
