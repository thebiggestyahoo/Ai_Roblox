local Atlas = {}

local function part(parent, size, position, color, shape, rotation)
	local object = Instance.new("Part")
	object.Size = size
	object.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	object.Color = color
	object.Shape = shape or Enum.PartType.Block
	object.Material = Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanQuery = false
	object.Parent = parent
end

local v = Vector3.new
local rgb = Color3.fromHex
local ball = Enum.PartType.Ball
local cylinder = Enum.PartType.Cylinder
local disc = CFrame.Angles(0, 0, math.pi / 2)

local scenes = {
	temple = function(scene, color, accent)
		for step = 0, 3 do
			part(scene, v(3.6-step*0.66, 0.47, 3.7-step*0.66), v(0.25,0.78+step*0.47,0), accent:Lerp(color, step*0.14))
		end
		part(scene,v(0.85,0.48,0.13),v(0.25,2.1,0.86),rgb("60446b"))
		for _, x in {-2.4,2.1} do
			part(scene,v(0.24,1.1,0.24),v(x,1.25,0.55),rgb("8f5c4b"))
			part(scene,v(1.16,0.85,1.12),v(x,1.98,0.55),rgb("57bf76"),ball)
		end
	end,
	pirate = function(scene, color, accent)
		part(scene,v(3.6,0.78,1.9),v(0,0.85,0),rgb("875237"),ball)
		part(scene,v(3.12,0.14,1.4),v(0,1.17,0),accent)
		part(scene,v(0.15,2.4,0.15),v(0.03,2.22,0),rgb("6c463d"))
		part(scene,v(1.75,1.25,0.24),v(0.03,2.53,0.16),rgb("fff1dc"),ball)
		part(scene,v(1.2,0.42,0.12),v(-0.48,3.33,0.04),color)
	end,
	jungle = function(scene, color, accent)
		for i = 1, 4 do
			local x, z = (i-2.5)*1.15, (i%2-0.5)*1.5
			part(scene,v(0.31,1.2,0.31),v(x,1.15,z),rgb("815741"))
			part(scene,v(1.5,1.22,1.3),v(x,2,z),if i%2==0 then color else accent,ball)
		end
		part(scene,v(2.4,0.23,0.35),v(0,0.76,1.35),rgb("f6d5a2"))
	end,
	factory = function(scene, color, accent)
		part(scene,v(3.5,1.29,2.45),v(0,1.13,0),color)
		part(scene,v(3.75,0.24,2.64),v(0,1.9,0),accent)
		for i = 1, 3 do
			local x = i - 2
			part(scene,v(0.46,0.65,0.12),v(x,1.34,1.25),rgb("fff5b6"))
			part(scene,v(0.41,1.1+i*0.18,0.41),v(x,2.37,-0.7),accent)
		end
	end,
	galaxy = function(scene, color, accent)
		part(scene,v(2.2,2.2,2.2),v(0.15,1.52,0),color,ball)
		part(scene,v(0.12,3.84,3.84),v(0.15,1.52,0),accent,cylinder,CFrame.Angles(0,0,1.09))
		for _, x in {-2,2.35} do
			part(scene,v(0.71,0.71,0.71),v(x,1.16,0.7),rgb("fce295"),ball)
		end
	end,
	frost = function(scene, color, accent)
		for i = 1, 3 do
			local x = (i-2)*1.17
			local height = (i==2 and 2.27 or 1.57)
			local tilt = CFrame.Angles(0,0,(i-2)*0.15)
			part(scene,v(0.85,height,0.89),v(x,0.6+height/2,0),color,Enum.PartType.Block,tilt)
			part(scene,v(0.84,0.24,0.88),v(x,0.58+height,0),accent,Enum.PartType.Block,tilt)
		end
	end,
	neon = function(scene,color,accent)
		for i=1,4 do
			local h = (i==2 and 2.65 or (i==4 and 1.9 or 1.4))
			local x = (i-2.5)*0.99
			part(scene,v(0.72,h,0.76),v(x,0.62+h/2,0.1),color:Lerp(rgb("443562"),i*0.13))
			for j=1,math.floor(h/0.4) do
				part(scene,v(0.36,0.15,0.05),v(x,0.57+j*0.38,0.51),accent)
			end
		end
		part(scene,v(4.32,0.14,0.65),v(0,0.91,1.34),rgb("fa7dbc"))
	end,
	sky = function(scene, color, accent)
		for i = 1, 3 do
			part(scene,v(1.45,1.01,1.57),v((i-2)*1.25,0.67+i*0.27,0.34-i*0.34),color,ball)
			part(scene,v(0.43,1,0.43),v((i-2)*1.25,1.37+i*0.27,0.33-i*0.34),accent)
		end
	end,
	tide = function(scene, color, accent)
		part(scene,v(3.2,0.15,2.56),v(0,0.65,0),color)
		for i = 1, 4 do
			part(scene,v(0.39,1.3,0.39),v((i-2.5)*0.77,1.29,-0.25),accent)
		end
		part(scene,v(2.95,0.21,0.74),v(0,2,-0.25),accent)
	end,
}

local function modelType(world)
	local name = (world.key .. " " .. world.name):lower()
	if name:find("temple") then return "temple" end
	if name:find("pirate") or name:find("secret") then return "pirate" end
	if name:find("prehistor") or name:find("jungle") then return "jungle" end
	if name:find("factory") or name:find("candy") then return "factory" end
	if name:find("galac") or name:find("space") then return "galaxy" end
	if name:find("frost") or name:find("frozen") then return "frost" end
	if name:find("sky") or name:find("cloud") then return "sky" end
	if name:find("neon") then return "neon" end
	return "tide"
end

function Atlas.preview(parent, world, size, position, closeUp)
	local color = rgb(world.color)
	local accent = rgb(world.accent)
	local view = Instance.new("ViewportFrame")
	view.Size, view.Position = size, position
	view.BackgroundColor3 = color:Lerp(rgb("fff6eb"),0.55)
	view.BorderSizePixel = 0
	view.Active = false
	view.Ambient = rgb("f4e6ff")
	view.LightColor = rgb("fff1d7")
	view.LightDirection = v(-1,-1,-0.5)
	view.Parent = parent

	local corners = Instance.new("UICorner")
	corners.CornerRadius = UDim.new(0,11)
	corners.Parent = view
	local scene = Instance.new("WorldModel")
	scene.Parent = view
	part(scene,v(0.72,6.25,6.25),v(0,-0.22,0),color:Lerp(rgb("4e355f"),0.32),cylinder,disc)
	part(scene,v(0.25,5.91,5.91),v(0,0.27,0),color,cylinder,disc)
	part(scene,v(2.4,0.11,0.66),v(-1.02,0.44,1.34),accent)
	part(scene,v(0.72,0.11,1.68),v(0.29,0.44,1.39),accent)
	scenes[modelType(world)](scene, color, accent)
	local camera = Instance.new("Camera")
	camera.FieldOfView = closeUp and 37 or 39
	camera.CFrame = CFrame.lookAt(closeUp and v(7.6,5.5,8) or v(8.9,6.65,9.7), v(0,0.9,0))
	camera.Parent = view
	view.CurrentCamera = camera
	return view, camera
end

local function worldCard(ctx, parent, world, position, goal)
	local color = rgb(world.color)
	local card = ctx.frame(parent,color,UDim2.new(0.5,-17,0,155),position,12)
	ctx.outline(card, ctx.ink, 2)
	Atlas.preview(card, world, UDim2.new(1,-12,1,-56), UDim2.fromOffset(6,6), false)
	local open = ctx.button(card, world.name, ctx.paper, ctx.ink, function()
		ctx.selectWorld(world.key)
	end)
	open.TextSize = 13
	open.Size = UDim2.new(1,-12,0,42)
	open.Position = UDim2.new(0,6,1,-48)
	local previewButton = Instance.new("TextButton")
	previewButton.Name = "Open world preview"
	previewButton.Size = UDim2.new(1,-12,1,-55)
	previewButton.Position = UDim2.fromOffset(6,6)
	previewButton.BackgroundTransparency = 1
	previewButton.Text = ""
	previewButton.Selectable = false
	previewButton.Activated:Connect(function() ctx.selectWorld(world.key) end)
	previewButton.Parent = card
	local route = ctx.label(card, ("%d COURSES"):format(goal), ctx.ink,
		UDim2.new(1,-14,0,20), UDim2.fromOffset(7,8), 9, ctx.digits)
	route.BackgroundColor3 = ctx.paper
	route.BackgroundTransparency = 0.1
	ctx.corner(route, 8)
end

local function showAtlas(ctx)
	local worldList = ctx.levels.worlds
	ctx.row("Choose a destination for Adventure Mode.", ctx.muted, 13, nil, 26)
	local lines = math.ceil(#worldList/2)
	local area = ctx.append(ctx.frame(ctx.list,rgb("dce2ff"),UDim2.new(1,-7,0,lines*177+9),nil,11))
	for index=1,lines do
		local y = 87 + (index-1)*177
		ctx.frame(area,rgb("7b6ac7"),UDim2.new(0.57,0,0,6),UDim2.new(0.22,0,0,y),2)
		if index<lines then
			local x = if index%2==1 then 0.76 else 0.24
			ctx.frame(area,rgb("7b6ac7"),UDim2.fromOffset(6,177),UDim2.new(x,0,0,y),2)
			ctx.frame(area,rgb("ffe97b"),UDim2.fromOffset(9,9),UDim2.new(x,-1,0,y+94),3)
		end
	end
	for index, world in ipairs(worldList) do
		local count = 0
		for k, spec in ipairs(ctx.levels) do
			if spec.worldKey == world.key and k ~= ctx.levels.final then count += 1 end
		end
		local line = math.floor((index-1)/2)
		local flip = (index%2==0) ~= (line%2==1)
		worldCard(ctx,area,world,UDim2.new(flip and 0.5 or 0,8,0,8+177*line),count)
	end
end

local function showWorld(ctx, world)
	local color = rgb(world.color)
	local hero = ctx.append(ctx.frame(ctx.list, color, UDim2.new(1,-7,0,184), nil, 12))
	ctx.outline(hero, ctx.ink, 2)
	local _, camera = Atlas.preview(hero, world, UDim2.new(1,-14,1,-14), UDim2.fromOffset(7,7), true)
	if not ctx.reducedMotion then
		local target = camera.CFrame
		camera.CFrame = CFrame.lookAt(v(11,7,11),v(0,0.9,0))
		game:GetService("TweenService"):Create(camera,TweenInfo.new(0.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=target}):Play()
	end
	local caption = ctx.frame(hero,ctx.ink,UDim2.new(1,-14,0,37),UDim2.new(0,7,1,-44),8)
	ctx.label(caption,world.name,ctx.paper,UDim2.fromScale(1,1),nil,21,ctx.heavy)
	ctx.listButton("← Adventure Atlas", ctx.cream, ctx.ink, function() ctx.selectWorld(nil) end)
	local relics = ctx.profile.relics and ctx.profile.relics[world.key]
	local found = 0
	for _, discovered in relics or {} do if discovered then found += 1 end end
	ctx.row(("%d / %d relics discovered"):format(found,ctx.economy.relicsPerWorld),ctx.ink,12,ctx.digits,25)
	if world.hook then
		local hook = ctx.row(world.hook, ctx.muted, 12, nil, 42)
		hook.TextWrapped = true
		hook.TextTruncate = Enum.TextTruncate.None
	end
	for index, course in ipairs(ctx.levels) do
		if course.worldKey ~= world.key or index == ctx.levels.final then continue end
		local completed = ctx.profile.records and ctx.profile.records[ctx.rules.recordKey(index)]
		local medal = ctx.profile.medals and ctx.profile.medals[tostring(index)]
		local card = ctx.append(ctx.frame(ctx.list, ctx.cream, UDim2.new(1,-7,0,131), nil, 9))
		ctx.outline(card, ctx.ink, 1.5)
		ctx.left(ctx.label(card,course.name,ctx.ink,UDim2.new(1,-24,0,28),UDim2.fromOffset(12,4),18,ctx.heavy))
		local description = ctx.left(ctx.label(card,course.hook or "",ctx.muted,UDim2.new(1,-24,0,26),UDim2.fromOffset(12,32),11))
		description.TextWrapped = true
		local stars = math.clamp(course.stars or 1,1,5)
		local record = completed and ("  ·  Best %.2fs"):format(completed) or "  ·  No time yet"
		local medalText = typeof(medal) == "string" and ("  ·  " .. medal) or ""
		ctx.left(ctx.label(card, ("%s %d/5%s%s"):format(string.rep("★",stars),stars,record,medalText),
			ctx.ink, UDim2.new(1,-24,0,19),UDim2.fromOffset(12,62),11,ctx.digits))
		local action = ctx.button(card,"PLAY ADVENTURE",ctx.yellow,ctx.ink,function()
			ctx.send("practice", tostring(index))
			ctx.close()
		end)
		action.Size = UDim2.new(0.55,-13,0,42)
		action.Position = UDim2.new(0,10,1,-46)
		local selected = ctx.state.selected == index
		local quick = ctx.button(card,selected and "QUICK RACE PICK" or "SET AS QUICK PICK",selected and ctx.lime or ctx.paper,ctx.ink,function()
			if not selected then ctx.send("choose",tostring(index)) end
		end)
		quick.TextSize = 11
		quick.Size, quick.Position = UDim2.new(0.45,-13,0,42),UDim2.new(0.55,3,1,-46)
		quick.Active, quick.Selectable = not selected, not selected
	end
end

function Atlas.render(ctx)
	local selected
	for _, world in ipairs(ctx.levels.worlds) do
		if world.key == ctx.worldKey then selected = world break end
	end
	if selected then showWorld(ctx,selected) else showAtlas(ctx) end
end

return Atlas
