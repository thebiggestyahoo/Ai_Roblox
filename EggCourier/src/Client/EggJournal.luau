local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = RS:WaitForChild("EggShared")
local Cosmetics = require(Shared.Cosmetics)
local EggModel = require(Shared.EggModel)
local Economy = require(Shared.EconomyConfig)
local Journal = {}

local rgb = Color3.fromHex
local ink, plum, pale = rgb("28204f"), rgb("483779"), rgb("f9efff")
local frost, gold, mint = rgb("e8deff"), rgb("ffcf56"), rgb("a5edcb")
local heading, body = Enum.Font.FredokaOne, Enum.Font.GothamMedium
local pageSize = 15
local state = {rarity=0, collection=0, favorites=false, query="", page=1, selected="Classic"}

local function box(kind, parent, color, size, position, radius)
	local object = Instance.new(kind)
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

local function label(parent, text, size, position, textColor, font, pixels, alignment)
	local item = box("TextLabel",parent,nil,size,position)
	item.Text = text
	item.TextColor3 = textColor
	item.Font = font
	item.TextSize = pixels
	item.TextXAlignment = alignment or Enum.TextXAlignment.Left
	item.TextTruncate = Enum.TextTruncate.AtEnd
	return item
end

local function callButton(parent, text, size, position, background, textColor, callback)
	local item = box("TextButton",parent,background,size,position,11)
	item.Text = text
	item.TextColor3 = textColor
	item.Font = heading
	item.TextSize = 13
	item.TextTruncate = Enum.TextTruncate.AtEnd
	item.Activated:Connect(callback)
	return item
end

local function sourceLabel(entry)
	local source = Economy.sourceOf[entry.id] or entry.source
	return Cosmetics.sources[source] or "Collection reward"
end

local function preview(parent, entry, owned, reducedMotion)
	local view = box("ViewportFrame",parent,plum,UDim2.new(0.34,-3,1,-18),UDim2.fromOffset(9,9),12)
	view.LightColor = rgb("fff5e2")
	view.Ambient = rgb("dcd1ff")
	view.LightDirection = Vector3.new(-0.7,-0.55,-0.48)
	local camera = Instance.new("Camera",view)
	camera.CFrame = CFrame.lookAt(Vector3.new(0,0.36,3.2),Vector3.new(0,0.15,0))
	camera.FieldOfView = 38
	view.CurrentCamera = camera
	local egg = EggModel.build(entry.id,1.1,true)
	egg.Parent = view
	if not owned then
		for _, part in ipairs(egg:GetChildren()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.SmoothPlastic
				part.Color = ink
			end
		end
	end
	EggModel.previewPose(egg,2.68,0)
	if not reducedMotion and owned then
		local elapsed = 0
		local connection = RunService.RenderStepped:Connect(function(dt)
			elapsed += dt
			EggModel.previewPose(egg,2.68+elapsed*0.52,elapsed)
		end)
		view.Destroying:Once(function() connection:Disconnect() end)
	end
end

local function showCompletion(parent, found)
	local band = box("Frame",parent,ink,UDim2.new(1,0,0,72),nil,13)
	label(band,"Egg Encyclopedia",UDim2.new(1,-24,0,26),UDim2.fromOffset(12,6),pale,heading,22)
	label(band,("Discovered %d of %d"):format(found,#Cosmetics.entries),
		UDim2.new(1,-84,0,18),UDim2.fromOffset(12,34),frost,body,12)
	local percent = math.floor(found/#Cosmetics.entries*100)
	local percentLabel = label(band,("%d%%"):format(percent),UDim2.fromOffset(60,18),UDim2.new(1,-72,0,34),gold,heading,13,Enum.TextXAlignment.Right)
	percentLabel.Name = "CompletionPercent"
	local track = box("Frame",band,plum,UDim2.new(1,-24,0,7),UDim2.new(0,12,1,-14),4)
	if found > 0 then box("Frame",track,mint,UDim2.fromScale(found/#Cosmetics.entries,1),nil,4) end
end

function Journal.render(parent, props)
	local profile = props.profile or {}
	local owned, favorites = profile.skins or {}, profile.favorites or {}
	local width = UDim2.new(1,-9,0,0)
	local frame = box("Frame",parent,nil,width)
	frame.Name = "EggEncyclopedia"
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local flow = Instance.new("UIListLayout",frame)
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	flow.Padding = UDim.new(0,8)
	local found = 0
	for _, entry in ipairs(Cosmetics.entries) do
		if owned[entry.id] then found += 1 end
	end
	showCompletion(frame,found)

	local filters = box("Frame",frame,nil,UDim2.new(1,0,0,76))
	filters.LayoutOrder = 1
	local search = box("TextBox",filters,pale,UDim2.new(1,0,0,34),nil,9)
	search.Name = "SearchEggs"
	search.Text = state.query
	search.PlaceholderText = "Search the encyclopedia"
	search.PlaceholderColor3 = plum
	search.TextColor3 = ink
	search.ClearTextOnFocus = false
	search.Font = body
	search.TextSize = 14
	local result = box("Frame",frame,nil,UDim2.new(1,0,0,0))
	result.LayoutOrder = 2
	result.AutomaticSize = Enum.AutomaticSize.Y
	local refresh
	local rarity = callButton(filters,"",UDim2.new(0.33,-3,0,35),UDim2.fromOffset(0,41),plum,pale,function()
		state.rarity = (state.rarity+1)%(#Cosmetics.rarityOrder+1)
		state.page = 1
		refresh()
	end)
	local collection = callButton(filters,"",UDim2.new(0.34,-3,0,35),UDim2.new(0.33,0,0,41),plum,pale,function()
		state.collection = (state.collection+1)%(#Cosmetics.collections+1)
		state.page = 1
		refresh()
	end)
	local fav = callButton(filters,"",UDim2.new(0.33,0,0,35),UDim2.new(0.67,0,0,41),plum,pale,function()
		state.favorites = not state.favorites
		state.page = 1
		refresh()
	end)

	refresh = function()
		result:ClearAllChildren()
		local layout = Instance.new("UIListLayout",result)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0,7)
		local rarityId = Cosmetics.rarityOrder[state.rarity]
		local collectionId = Cosmetics.collections[state.collection]
		rarity.Text = rarityId or "All rarities"
		collection.Text = collectionId and collectionId[2] or "All collections"
		fav.Text = state.favorites and "★ Favorites" or "☆ Favorites"
		fav.BackgroundColor3 = state.favorites and gold or plum
		fav.TextColor3 = state.favorites and ink or pale
		local visible = {}
		local selected
		local query = string.lower(state.query)
		for _, entry in ipairs(Cosmetics.entries) do
			local matches = query == "" or string.find(string.lower(entry.name),query,1,true)
				or string.find(string.lower(entry.collection),query,1,true)
			if matches and (not rarityId or entry.rarity==rarityId)
				and (not collectionId or entry.collection==collectionId[1])
				and (not state.favorites or favorites[entry.id]) then
				table.insert(visible,entry)
				if state.selected==entry.id then selected = entry end
			end
		end
		if #visible==0 then
			label(result,"No eggs match these filters.",UDim2.new(1,0,0,48),nil,ink,body,14)
			return
		end
		local pages = math.ceil(#visible/pageSize)
		state.page = math.clamp(state.page,1,pages)
		local first = (state.page-1)*pageSize+1
		local last = math.min(first+pageSize-1,#visible)
		if not selected then selected = visible[first] end
		local spec = Cosmetics.rarities[selected.rarity]
		local detail = box("Frame",result,ink,UDim2.new(1,0,0,168),nil,14)
		preview(detail,selected,owned[selected.id],props.reducedMotion)
		local function words(txt, y, height, font, size, color)
			return label(detail,txt,UDim2.new(0.64,-11,0,height),UDim2.new(0.36,0,0,y),color,font,size)
		end
		words(spec.mark .. "  " .. selected.rarity .. "  ·  " .. selected.collection,10,18,heading,12,rgb(spec.color))
		words(selected.name,29,28,heading,19,pale)
		local description = words(selected.description,57,40,body,12,frost)
		description.TextWrapped = true
		description.TextTruncate = Enum.TextTruncate.None
		local source = owned[selected.id] and "Owned" or "Undiscovered"
		words(source .. "  ·  " .. sourceLabel(selected),97,21,body,11,mint)
		if owned[selected.id] then
			if profile.skin == selected.id then
				label(detail,"Equipped",UDim2.new(0.33,-3,0,36),UDim2.new(0.36,0,0,124),mint,heading,13,Enum.TextXAlignment.Center)
			else
				callButton(detail,"Equip",UDim2.new(0.33,-3,0,36),UDim2.new(0.36,0,0,124),mint,ink,function()
					props.send("skin",selected.id)
				end)
			end
			callButton(detail,favorites[selected.id] and "★ Saved" or "☆ Favorite",UDim2.new(0.29,-5,0,36),UDim2.new(0.69,0,0,124),gold,ink,function()
				props.send("favorite",selected.id)
			end)
		elseif props.navigate then
			callButton(detail,"Find cartons",UDim2.new(0.53,0,0,36),UDim2.new(0.36,0,0,124),gold,ink,function()
				props.navigate("Cartons")
			end)
		end

		if collectionId then
			local collected = 0
			for _, item in ipairs(visible) do if owned[item.id] then collected += 1 end end
			local caption = label(result,("%s entries found  %d / %d"):format(collectionId[2],collected,#visible),
				UDim2.new(1,0,0,23),nil,ink,body,12)
			caption.LayoutOrder = 1
		end
		local grid = box("Frame",result,nil,UDim2.new(1,0,0,math.ceil((last-first+1)/3)*52-6))
		grid.LayoutOrder = 2
		local grids = Instance.new("UIGridLayout",grid)
		grids.CellSize = UDim2.new(1/3,-4,0,46)
		grids.CellPadding = UDim2.fromOffset(6,6)
		grids.SortOrder = Enum.SortOrder.LayoutOrder
		for i=first,last do
			local entry = visible[i]
			local mark = if owned[entry.id] then Cosmetics.rarities[entry.rarity].mark else "○"
			local tile = callButton(grid,mark .. "  " .. entry.name,UDim2.new(),nil,entry.id==selected.id and gold or frost,ink,function()
				state.selected = entry.id
				refresh()
			end)
			tile.LayoutOrder = i
			tile.TextWrapped = true
			tile.TextTruncate = Enum.TextTruncate.None
			tile.TextSize = 12
		end
		if pages > 1 then
			local controls = box("Frame",result,nil,UDim2.new(1,0,0,40))
			controls.LayoutOrder = 3
			if state.page>1 then
				callButton(controls,"‹ Previous",UDim2.new(0.29,0,1,0),nil,plum,pale,function()
					state.page -= 1
					state.selected = ""
					refresh()
				end)
			end
			label(controls,("%d / %d"):format(state.page,pages),UDim2.new(0.38,0,1,0),UDim2.fromScale(0.31,0),ink,heading,14,Enum.TextXAlignment.Center)
			if state.page<pages then
				callButton(controls,"Next ›",UDim2.new(0.29,0,1,0),UDim2.fromScale(0.71,0),plum,pale,function()
					state.page += 1
					state.selected = ""
					refresh()
				end)
			end
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		state.query = search.Text
		state.page = 1
		refresh()
	end)
	refresh()
	return frame
end
return Journal
