local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("EggShared")
local Cosmetics = require(Shared.Cosmetics)
local EggModel = require(Shared.EggModel)
local Audio = require(script.Parent.Audio)
local Reveal = {}
local active

local rgb = Color3.fromHex
local ink, plum, white = rgb("28204f"), rgb("53407c"), rgb("fff6f2")
local lightGold, gold, mint = rgb("fff0bd"), rgb("ffca57"), rgb("adf1c0")
local materials = Enum.Material
-- Shell, lining, trim, material, stamped packaging symbol.
local packaging = {
	classic={"b9d99b","eedca9","57997c",materials.SmoothPlastic,"farm"},
	adventure={"994b36","dec795","ffc37c",materials.Wood,"compass"},
	enchanted={"6952b5","ecd4ff","ffbaf1",materials.SmoothPlastic,"rune"},
	royal={"ad7955","a74f67","ffde8e",materials.Metal,"crown"},
	galactic={"485f87","90bbdc","91f3e4",materials.Metal,"circuit"},
	champion={"bb874f","f9d2a1","ffe89a",materials.Metal,"trophy"},
	starterCollector={"cc9288","f8e4b4","fff2db",materials.SmoothPlastic,"farm"},
	pirateCollector={"80514b","ded0aa","eebc70",materials.Wood,"compass"},
	relicCollector={"b38968","eac29c","baf1ca",materials.Sandstone,"rune"},
	dragonCollector={"8a4d72","ffb881","fcea9e",materials.SmoothPlastic,"claw"},
	galacticCollector={"4e5b93","a6a8e1","a9eaff",materials.Metal,"circuit"},
	deluxeCollector={"9f699c","f6bada","ffdd9c",materials.SmoothPlastic,"crown"},
}

local function widget(class, parent, color, size, position, radius)
	local object = Instance.new(class)
	object.BorderSizePixel = 0
	object.BackgroundTransparency = if color then 0 else 1
	if color then object.BackgroundColor3 = color end
	object.Size = size
	object.Position = position or UDim2.new()
	if radius then
		local corner = Instance.new("UICorner",object)
		corner.CornerRadius = UDim.new(0,radius)
	end
	object.Parent = parent
	return object
end

local function text(object, value, color, size)
	object.Text = value
	object.TextColor3 = color
	object.TextSize = size
	object.Font = Enum.Font.FredokaOne
	object.TextTruncate = Enum.TextTruncate.AtEnd
	return object
end

local function button(parent, title, color, size, position, callback)
	local item = text(widget("TextButton",parent,color,size,position,12),title,ink,15)
	item.Activated:Connect(callback)
	return item
end

local function asset(parent, name, size, position, color, material, class, rotation)
	local part = Instance.new(class or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	part.Color = color
	part.Material = material or materials.SmoothPlastic
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true,false,false,false
	part.Parent = parent
	return part
end

local function rounded(parent, name, size, position, color, material)
	local part = asset(parent,name,size,position,color,material)
	local mesh = Instance.new("SpecialMesh",part)
	mesh.MeshType = Enum.MeshType.Sphere
	return part
end

local function packageModel(view, key)
	local main, lining, highlight, material, ornament = table.unpack(packaging[key] or packaging.classic)
	main, lining, highlight = rgb(main), rgb(lining), rgb(highlight)
	local v = Vector3.new
	local base = Instance.new("Model", view)
	local cap = Instance.new("Model",view)
	local bevel = materials.SmoothPlastic
	local stage = asset(view,"Turntable",v(0.21,5.85,5.85),v(0,-0.40,0),plum,bevel,nil,CFrame.Angles(0,0,math.pi/2))
	stage.Shape = Enum.PartType.Cylinder
	asset(base,"Carton tray base",v(3.7,0.35,2.8),v(0,0,0),main,material)
	for _, x in {-1.75,1.75} do
		asset(base,"Carton fold",v(0.22,0.53,2.65),v(x,0.28,0),main,material)
	end
	for _, z in {-1.33,1.33} do
		asset(base,"Carton long fold",v(3.48,0.52,0.22),v(0,0.27,z),main,material)
	end
	for _, x in {-1.16,0,1.16} do
		for _, z in {-0.65,0.65} do
			rounded(base,"Moulded egg compartment",v(0.99,0.34,0.99),v(x,0.30,z),lining,bevel)
			rounded(base,"Compartment recess",v(0.61,0.22,0.61),v(x,0.389,z),main,material)
			rounded(base,"Compartment glimmer",v(0.49,0.043,0.49),v(x,0.483,z),highlight,materials.Neon)
		end
	end
	for _, x in {-0.58,0.58} do
		asset(base,"Carton divider",v(0.13,0.34,2.48),v(x,0.275,0),lining,bevel)
	end
	asset(base,"Center divider",v(3.44,0.32,0.13),v(0,0.27,0),lining,bevel)
	asset(cap,"Lid panel",v(3.72,0.21,2.8),v(0,0,0),main,material)
	asset(cap,"Lid label",v(2.85,0.028,2.20),v(0,0.116,0),lining,bevel)
	for _, x in {-1.49,1.49} do
		asset(cap,"Print border",v(0.047,0.035,2.27),v(x,0.128,0),highlight,bevel)
	end
	for _, z in {-1.13,1.13} do
		asset(cap,"Print border",v(3.0,0.035,0.05),v(0,0.128,z),highlight,bevel)
	end

	if ornament=="farm" then
		asset(cap,"Farm sign",v(1.18,0.04,0.68),v(0,0.14,0.13),main,bevel)
		asset(cap,"Painted roof",v(1.06,0.06,0.51),v(0,0.165,-0.33),highlight,bevel,"WedgePart")
		asset(cap,"Printed barn door",v(0.36,0.052,0.40),v(0,0.158,0.18),white,bevel)
	elseif ornament=="circuit" then
		for i=-1,1 do
			asset(cap,"Printed trace",v(1.08,0.04,0.074),v(0,0.155,i*0.36),highlight,materials.Neon)
			rounded(cap,"Circuit contact",v(0.13,0.045,0.13),v(0.69,0.16,i*0.36),main,bevel)
		end
	elseif ornament=="crown" or ornament=="trophy" then
		asset(cap,"Gold leaf base",v(1.04,0.051,0.12),v(0,0.162,0.43),highlight,materials.Metal)
		for i=-1,1 do
			asset(cap,"Gold leaf point",v(0.27,0.07,0.58-math.abs(i)*0.17),v(i*0.34,0.165,0.11),highlight,materials.Metal,"WedgePart")
		end
	else
		for i=1,4 do
			asset(cap,"Printed seal",v(0.062,0.038,1.02),v(0,0.150,0),highlight,bevel,nil,CFrame.Angles(0,i*math.pi/4,0))
		end
		rounded(cap,"Seal center",v(0.28,0.058,0.28),v(0,0.179,0),main,bevel)
	end
	base.WorldPivot, cap.WorldPivot = CFrame.identity, CFrame.identity
	return base, cap
end

local function knownRewards(payload)
	local results = {}
	for _, reward in ipairs(payload.eggs or payload.rewards or {}) do
		local id = if type(reward)=="table" then reward.id else reward
		local egg = Cosmetics.byId[id]
		if egg then table.insert(results,egg) end
	end
	return results
end

local function easeOut(r)
	return 1-(1-math.clamp(r,0,1))^3
end

function Reveal.show(gui, payload, props)
	local rewards = knownRewards(payload)
	local extras = payload.extras or {}
	if #rewards == 0 and #extras == 0 then return end
	if active then active:Destroy() end
	local layer = widget("Frame",gui,ink,UDim2.fromScale(1,1))
	layer.Name = "CartonReveal"
	layer.ZIndex = 50
	layer.Active = true
	layer.BackgroundTransparency = 0.19
	active = layer
	local panel = widget("Frame",layer,ink,UDim2.new(1,-18,1,-18),UDim2.fromScale(0.5,0.5),19)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	local constraint = Instance.new("UISizeConstraint",panel)
	constraint.MaxSize = Vector2.new(540,510)
	local border = Instance.new("UIStroke",panel)
	border.Color = gold
	border.Thickness = 3
	local title = text(widget("TextLabel",panel,nil,UDim2.new(1,-77,0,44),UDim2.fromOffset(17,5)),payload.name or "Carton",white,23)
	title.TextXAlignment = Enum.TextXAlignment.Left

	local viewport = widget("ViewportFrame",panel,plum,UDim2.new(1,-24,0.48,-36),UDim2.fromOffset(12,49),16)
	viewport.Ambient = rgb("e9dbff")
	viewport.LightDirection = Vector3.new(-0.6,-1,-0.37)
	viewport.LightColor = rgb("fff0d9")
	local world = Instance.new("WorldModel",viewport)
	local camera = Instance.new("Camera",viewport)
	camera.CFrame = CFrame.lookAt(Vector3.new(5.0,3.6,7.5),Vector3.new(0,0.48,0))
	camera.FieldOfView = 39
	viewport.CurrentCamera = camera
	local base, lid = packageModel(world,payload.id)
	local eggs = {}
	for i=1,math.min(3,#rewards) do
		local egg = EggModel.build(rewards[i].id,0.88,true)
		table.insert(eggs,egg)
	end

	local status = text(widget("TextLabel",panel,nil,UDim2.new(1,-24,0,34),UDim2.new(0,12,0.48,15)),"Opening carton…",gold,18)
	local list = widget("ScrollingFrame",panel,plum,UDim2.new(1,-24,0.52,-112),UDim2.new(0,12,0.48,50),11)
	list.Visible = false
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = gold
	local flow = Instance.new("UIListLayout",list)
	flow.Padding = UDim.new(0,5)
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	local padding = Instance.new("UIPadding",list)
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0,7),UDim.new(0,8)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0,6),UDim.new(0,6)

	local selected = rewards[1]
	local items = {}
	local done = false
	local connection
	local finish
	local previousSelection = GuiService.SelectedObject
	local gamepad = UserInputService:GetLastInputType().Name:find("Gamepad",1,true) ~= nil
	local skip = button(panel,"Skip",gold,UDim2.new(1,-24,0,43),UDim2.new(0,12,1,-53),function() finish() end)
	local collection = button(panel,"Collection",lightGold,UDim2.new(0.48,-12,0,43),UDim2.new(0,12,1,-53),function()
		layer:Destroy()
		if props.onCollection then props.onCollection() end
	end)
	local equip = button(panel,"Equip egg",mint,UDim2.new(0.52,-17,0,43),UDim2.new(0.48,5,1,-53),function()
		if not selected then return end
		props.send("skin",selected.id)
		layer:Destroy()
		if props.onCollection then props.onCollection() end
	end)
	collection.Visible, equip.Visible = false, false
	local close = button(panel,"×",lightGold,UDim2.fromOffset(42,37),UDim2.new(1,-51,0,8),function() layer:Destroy() end)
	if gamepad then GuiService.SelectedObject = skip end

	local function pose(age)
		local turn = math.max(0, 2.7-age)*0.41
		local rise = easeOut(age/0.54)
		local open = easeOut((age-0.68)/0.82)
		local cframe = CFrame.new(0,-2*(1-rise),0)*CFrame.Angles(0,turn,0)
		base:PivotTo(cframe)
		lid:PivotTo(cframe*CFrame.new(0,0.60,-1.36)*CFrame.Angles(-open*1.39,0,0)*CFrame.new(0,0,1.36))
		local lift = easeOut((age-1.11)/0.91)
		for i, egg in ipairs(eggs) do
			if lift > 0 then
				if not egg.Parent then egg.Parent = world end
				local x = (i-(#eggs+1)/2)*1.14
				local spin = (age-1.11)*1.8
				egg:PivotTo(cframe*CFrame.new(x,0.42+lift*1.32,0.12)*CFrame.Angles(0,math.pi+spin,0))
			end
		end
	end

	finish = function()
		if done then return end
		done = true
		if connection then connection:Disconnect() end
		pose(2.53)
		local highest = rewards[1]
		for _, egg in ipairs(rewards) do
			if egg.rank > highest.rank then highest = egg end
		end
		if highest then
			status.TextColor3 = rgb(Cosmetics.rarities[highest.rarity].color)
			Audio.play("Carton" .. highest.rarity)
		end
		status.Text = ("%d %s unlocked"):format(#rewards+#extras,(#rewards+#extras==1 and "cosmetic" or "cosmetics"))
		skip.Visible = false
		collection.Visible, equip.Visible = true,#rewards>0
		list.Visible = true
		for i, egg in ipairs(rewards) do
			local rarity = Cosmetics.rarities[egg.rarity]
			local item = button(list,rarity.mark .. "  " .. egg.name .. "  ·  " .. egg.rarity,
				egg==selected and gold or rgb(rarity.color),UDim2.new(1,-5,0,33),nil,function()
					selected = egg
					for reward, buttonItem in pairs(items) do
						buttonItem.BackgroundColor3 = reward == egg and gold or rgb(Cosmetics.rarities[reward.rarity].color)
					end
					for _, preview in ipairs(eggs) do preview:Destroy() end
					table.clear(eggs)
					local preview = EggModel.build(egg.id,1.05,true)
					table.insert(eggs,preview)
					pose(2.53)
				end)
			item.LayoutOrder = i
			item.TextSize = 13
			items[egg] = item
		end
		for i, extra in ipairs(extras) do
			local row = text(widget("TextLabel",list,nil,UDim2.new(1,-5,0,30)),extra.name or extra.id or "Cosmetic",white,13)
			row.LayoutOrder = #rewards+i
		end
		if gamepad then GuiService.SelectedObject = selected and equip or collection end
	end

	layer.Destroying:Once(function()
		if connection then connection:Disconnect() end
		for _, egg in ipairs(eggs) do if not egg.Parent then egg:Destroy() end end
		if active==layer then
			active = nil
			local current = GuiService.SelectedObject
			if gamepad and (not current or current:IsDescendantOf(layer)) then
				GuiService.SelectedObject = if previousSelection and previousSelection.Parent then previousSelection else nil
			end
		end
	end)
	if props.reducedMotion then
		finish()
	else
		local age = 0
		pose(age)
		connection = RunService.RenderStepped:Connect(function(dt)
			age += dt
			if age>=2.53 then finish() else pose(age) end
		end)
	end
	return layer
end

return Reveal
