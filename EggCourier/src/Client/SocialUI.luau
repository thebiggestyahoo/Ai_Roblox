local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("EggShared")
local Cosmetics = require(Shared.Cosmetics)
local Egg = require(Shared.EggModel)
local Trophy = require(Shared.TrophyModel)

local SocialUI = {}
local hooks, remote
local party = {members = {}, invites = {}, roster = {}, limit = 5}
local museum, requestedMuseum
local selectedSlot, choosing, pickerPage = 1, false, 1
local viewing, stopGui
local watchConnections = {}

local function notify(message)
	if hooks and hooks.notify then hooks.notify(message) end
end

local function redraw()
	if hooks and hooks.redraw then hooks.redraw() end
end

function SocialUI.request(action, payload)
	if remote then remote:FireServer(action, payload) end
end

function SocialUI.stop()
	if not viewing then return end
	viewing = nil
	for _, connection in watchConnections do connection:Disconnect() end
	table.clear(watchConnections)
	if stopGui then stopGui:Destroy(); stopGui = nil end
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if camera and humanoid then camera.CameraSubject = humanoid end
end

local function watch(target)
	if not target then return end
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if not camera or not humanoid or target:GetAttribute("CourseRacing") ~= true then
		notify("That race is over.")
		return
	end
	SocialUI.stop()
	viewing = target
	if hooks.close then hooks.close() end
	camera.CameraSubject = humanoid
	table.insert(watchConnections, target:GetAttributeChangedSignal("CourseRacing"):Connect(function()
		if target:GetAttribute("CourseRacing") ~= true then SocialUI.stop() end
	end))
	table.insert(watchConnections, player:GetAttributeChangedSignal("CourseRacing"):Connect(function()
		if player:GetAttribute("CourseRacing") then SocialUI.stop() end
	end))
	table.insert(watchConnections, target.AncestryChanged:Connect(function()
		if target.Parent ~= Players then SocialUI.stop() end
	end))
	table.insert(watchConnections, target.CharacterRemoving:Connect(SocialUI.stop))
	table.insert(watchConnections, player.CharacterAdded:Connect(SocialUI.stop))

	stopGui = Instance.new("ScreenGui")
	stopGui.Name = "CourierSpectator"
	stopGui.ResetOnSpawn = false
	stopGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	stopGui.DisplayOrder = 12
	stopGui.Parent = player:WaitForChild("PlayerGui")
	local leave = Instance.new("TextButton")
	leave.Name = "ExitSpectating"
	leave.AnchorPoint = Vector2.new(0.5, 1)
	leave.Position = UDim2.new(0.5, 0, 1, -74)
	leave.Size = UDim2.fromOffset(184, 44)
	leave.BackgroundColor3 = Color3.fromHex("ffcc4a")
	leave.TextColor3 = Color3.fromHex("272054")
	leave.Font = Enum.Font.FredokaOne
	leave.Text = "STOP WATCHING"
	leave.TextSize = 16
	leave.BorderSizePixel = 0
	leave.Parent = stopGui
	Instance.new("UICorner", leave).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", leave)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = leave.TextColor3
	stroke.Thickness = 2
	leave.Activated:Connect(SocialUI.stop)
end

function SocialUI.bind(options)
	hooks = options
	if remote then return end
	task.spawn(function()
		remote = Shared:WaitForChild("CourierSocial", 15)
		if not remote then return end
		remote.OnClientEvent:Connect(function(kind, value)
			if kind == "Party" then
				party = value
				redraw()
			elseif kind == "Notice" then
				notify(value)
			elseif kind == "Museum" then
				local nextOwner = museum and museum.owner.id ~= value.owner.id
				museum = value
				if nextOwner then selectedSlot, choosing = 1, false end
				if requestedMuseum and requestedMuseum == value.owner.id then
					requestedMuseum = nil
					hooks.openMuseum()
				else
					redraw()
				end
			elseif kind == "Spectate" then
				watch(Players:GetPlayerByUserId(value))
			end
		end)
		SocialUI.request("refresh")
	end)
end

local function skinName(id)
	local skin = Cosmetics.byId[id]
	return skin and skin.name or id
end

local function badge(parent, id, size, position)
	local image = Instance.new("ImageLabel")
	image.Name = "Avatar portrait"
	image.BackgroundTransparency = 0
	image.BackgroundColor3 = Color3.fromHex("e5caff")
	image.Size = UDim2.fromOffset(size, size)
	image.Position = position
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Crop
	if id > 0 then image.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(id) end
	image.Parent = parent
	Instance.new("UICorner", image).CornerRadius = UDim.new(0, 10)
end

function SocialUI.openMuseum(owner)
	requestedMuseum = owner or player.UserId
	SocialUI.request("museum", owner)
end

local function partyEgg(parent, skin)
	local view = Instance.new("ViewportFrame")
	view.Name = "Equipped egg preview"
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromOffset(51, 48)
	view.Position = UDim2.new(1,-56,0,3)
	view.Ambient = Color3.fromHex("cec0dc")
	view.LightColor = Color3.fromHex("fff7de")
	view.Parent = parent
	local camera = Instance.new("Camera", view)
	camera.CFrame = CFrame.lookAt(Vector3.new(1.15,0.35,-2.65),Vector3.zero)
	camera.FieldOfView = 44
	view.CurrentCamera = camera
	Egg.build(skin, 1.05, true).Parent = view
end

local function renderFriends(ctx)
	local ownGroup = #party.members > 0
	local leader = party.leader == player.UserId
	ctx.listButton("MY EGG MUSEUM", ctx.yellow, ctx.ink, function() SocialUI.openMuseum() end)
	ctx.row(ownGroup and ("Party  %d/%d"):format(#party.members, party.limit) or "Party invites", ctx.ink, 18, ctx.heavy, 30)
	if ownGroup then
		for _, member in party.members do
			local card = ctx.append(ctx.frame(ctx.list, ctx.cream, UDim2.new(1, -8, 0, 55), nil, 8))
			badge(card, member.id, 39, UDim2.fromOffset(8, 8))
			partyEgg(card, member.skin)
			ctx.left(ctx.label(card, member.name .. (member.id == party.leader and "  ·  Leader" or ""), ctx.ink,
				UDim2.new(1, -117, 0, 24), UDim2.fromOffset(56, 4), 15, ctx.heavy))
			ctx.left(ctx.label(card, skinName(member.skin), ctx.muted, UDim2.new(1, -117, 0, 22), UDim2.fromOffset(56, 26), 12))
		end
		if leader then
			local function queue(mode, private)
				SocialUI.request("queue", {mode=mode, course=hooks.currentCourse(), private=private})
			end
			ctx.listButton("QUEUE EGG ROYALE", ctx.yellow, ctx.ink, function() queue("royale", false) end)
			ctx.listButton("QUEUE QUICK RACE", ctx.lime, ctx.ink, function() queue("quick", false) end)
			ctx.listButton("START PRIVATE QUICK RACE", ctx.cream, ctx.ink, function() queue("quick", true) end)
		end
		ctx.listButton("LEAVE PARTY", ctx.cream, ctx.ink, function() SocialUI.request("leave") end)
	end
	for _, invite in party.invites do
		ctx.row(("Invite from %s"):format(invite.name), ctx.ink, 15, ctx.heavy, 26)
		local actions = ctx.append(ctx.frame(ctx.list, nil, UDim2.new(1, -8, 0, 44)))
		local accept = ctx.button(actions, "JOIN PARTY", ctx.lime, ctx.ink, function() SocialUI.request("accept", invite.id) end)
		accept.Size = UDim2.new(0.5, -4, 1, 0)
		local decline = ctx.button(actions, "DECLINE", ctx.cream, ctx.ink, function() SocialUI.request("decline", invite.id) end)
		decline.Size = accept.Size
		decline.Position = UDim2.new(0.5, 4, 0, 0)
	end
	ctx.row("Players in this server", ctx.ink, 17, ctx.heavy, 31)
	if #party.roster == 0 then
		ctx.row("Friends who join this server will appear here.", ctx.muted, 12, nil, 28)
	else
		ctx.row("Invite, watch, or visit Roblox friends in this server.", ctx.muted, 12, nil, 27)
	end
	ctx.listButton("REFRESH PLAYERS", ctx.cream, ctx.ink, function() SocialUI.request("refresh") end)
	for _, candidate in party.roster do
		local target = Players:GetPlayerByUserId(candidate.id)
		if not target then continue end
		local active = target:GetAttribute("CourseRacing") == true
		local card = ctx.append(ctx.frame(ctx.list, ctx.cream, UDim2.new(1, -8, 0, 94), nil, 8))
		badge(card, candidate.id, 38, UDim2.fromOffset(7, 6))
		ctx.left(ctx.label(card, candidate.name, ctx.ink, UDim2.new(1, -64, 0, 21), UDim2.fromOffset(52, 4), 15, ctx.heavy))
		local status = active and "Racing" or "In the lobby"
		ctx.left(ctx.label(card, status .. "  /  " .. skinName(candidate.skin), ctx.muted,
			UDim2.new(1, -64, 0, 19), UDim2.fromOffset(52, 25), 11))
		local isMember = false
		for _, member in party.members do
			if member.id == candidate.id then isMember = true; break end
		end
		local actions = {
			{"MUSEUM", function() SocialUI.openMuseum(candidate.id) end},
		}
		if leader and not isMember and not active then
			table.insert(actions, {"INVITE", function() SocialUI.request("invite", candidate.id) end})
		end
		if active then
			table.insert(actions, {"WATCH", function() SocialUI.request("spectate", candidate.id) end})
		end
		for index, item in actions do
			local action = ctx.button(card, item[1], ctx.paper, ctx.ink, item[2])
			action.Position = UDim2.new((index-1)/#actions, 6, 0, 47)
			action.Size = UDim2.new(1/#actions, -12, 0, 40)
		end
	end
end

local function museumPart(parent, name, color, size, position, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Color = Color3.fromHex(color)
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	if shape then part.Shape = shape end
	part.Parent = parent
	return part
end

local function cylinder(parent, name, color, height, width, position)
	local part = museumPart(parent, name, color, Vector3.new(height, width, width), position, Enum.PartType.Cylinder)
	part.CFrame = CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
	return part
end

local roomStyles = {
	velvet = {name="Velvet", wall="432b64", floor="674f93", rail="d7a159", pillar="9164ab", pedestal="9064c1"},
	ocean = {name="Ocean", wall="214d67", floor="3c788a", rail="80cce3", pillar="4ea8a7", pedestal="4674a1"},
	sunset = {name="Sunset", wall="7b394f", floor="af6277", rail="f7b568", pillar="d47d77", pedestal="bd606e"},
}

local function display(ctx)
	local style = roomStyles[museum.decoration] or roomStyles.velvet
	local view = Instance.new("ViewportFrame")
	view.Name = "Gallery preview"
	view.Size = UDim2.new(1, -8, 0, 190)
	view.BackgroundColor3 = Color3.fromHex(style.wall)
	view.BorderSizePixel = 0
	view.LightDirection = Vector3.new(-0.7,-1,-0.5)
	view.LightColor = Color3.fromHex("fff0d2")
	view.Ambient = Color3.fromHex("c8c3e8")
	view.Parent = ctx.list
	Instance.new("UICorner", view).CornerRadius = UDim.new(0, 12)
	ctx.append(view)
	local room = Instance.new("WorldModel", view)
	museumPart(room, "Gallery floor", style.floor, Vector3.new(15,0.3,8), Vector3.new(0,-0.16,0.3))
	museumPart(room, "Gallery wall", style.wall, Vector3.new(15,7,0.35), Vector3.new(0,3.5,-4))
	museumPart(room, "Gallery rail", style.rail, Vector3.new(15,0.21,0.14), Vector3.new(0,0.67,-3.74))
	museumPart(room, "Gallery rail", style.rail, Vector3.new(15,0.21,0.14), Vector3.new(0,4.85,-3.74))
	for _, x in {-6, -3.1, 3.1, 6} do
		cylinder(room, "Gallery pillar", style.pillar, 5.1, 0.55, Vector3.new(x,2.55,-3.55))
		museumPart(room, "Gallery lamp", "ffcd82", Vector3.new(0.38,0.38,0.38), Vector3.new(x,4.95,-3.42), Enum.PartType.Ball)
	end
	cylinder(room, "Trophy stand", "7452aa", 1.45, 2.45, Vector3.new(0,0.72,-2.65))
	if museum.championships > 0 then
		local trophy = Trophy.build()
		trophy:PivotTo(CFrame.new(0,1.59,-2.65)*CFrame.Angles(0,math.pi,0))
		trophy.Parent = room
	end
	local medalColors = {gold="fbd269", silver="e1ebfa", bronze="f39058"}
	for i, rank in {"bronze","silver","gold"} do
		local earned = (museum.ribbons[rank] or 0) > 0
		local x = (i-2)*1.05
		local medal = museumPart(room, rank .. " medal", earned and medalColors[rank] or style.wall,
			Vector3.new(0.17,0.58,0.58), Vector3.new(x,4.25,-3.71), Enum.PartType.Cylinder)
		medal.CFrame *= CFrame.Angles(0,-math.pi/2,0)
	end
	for slot = 1, 4 do
		local x = (slot-2.5)*2.85
		local skin = museum.slots[tostring(slot)]
		cylinder(room, "Display pedestal", style.pedestal, 0.72, 2.24, Vector3.new(x,0.36,0.75))
		cylinder(room, "Display rim", selectedSlot == slot and "ffcd65" or "c49be6", 0.12, 2.25, Vector3.new(x,0.78,0.75))
		if skin and Cosmetics.byId[skin] then
			local model = Egg.build(skin, 1.2, true)
			model:PivotTo(CFrame.new(x,1.73,0.75)*CFrame.Angles(0,math.pi+0.2,0))
			model.Parent = room
		end
	end
	local camera = Instance.new("Camera", view)
	camera.FieldOfView = 39
	camera.CFrame = CFrame.lookAt(Vector3.new(0,5.42,17.6),Vector3.new(0,1.8,0))
	view.CurrentCamera = camera
end

local function chooseEgg(ctx)
	local choices = {}
	local profile = ctx.profile or {}
	for id, owned in profile.skins or {} do
		if owned and Cosmetics.byId[id] then table.insert(choices, id) end
	end
	local favorites = profile.favorites or {}
	table.sort(choices, function(a, b)
		local aFavorite, bFavorite = favorites[a] == true, favorites[b] == true
		if aFavorite ~= bFavorite then return aFavorite end
		return skinName(a) < skinName(b)
	end)
	local pages = math.max(1, math.ceil(#choices/5))
	pickerPage = math.clamp(pickerPage, 1, pages)
	for i = (pickerPage-1)*5+1, math.min(pickerPage*5,#choices) do
		local skin = choices[i]
		ctx.listButton(skinName(skin) .. (favorites[skin] and "  ★" or ""), ctx.cream, ctx.ink, function()
			choosing = false
			SocialUI.request("pedestal", {slot=selectedSlot, skin=skin})
		end)
	end
	if pages > 1 then
		ctx.listButton(("MORE EGGS  %d/%d"):format(pickerPage, pages), ctx.cream, ctx.ink, function()
			pickerPage = pickerPage%pages+1
			redraw()
		end)
	end
end

local function renderMuseum(ctx)
	if not museum then
		ctx.listButton("OPEN MY EGG MUSEUM", ctx.yellow, ctx.ink, function() SocialUI.openMuseum() end)
		return
	end
	ctx.row(museum.editable and "Your Egg Museum" or museum.owner.name .. "’s Egg Museum", ctx.ink, 19, ctx.heavy, 30)
	display(ctx)
	ctx.row(("%d titles  /  %d medals  /  %d PBs"):format(museum.championships,museum.medals,museum.records), ctx.ink, 13, ctx.heavy, 28)
	ctx.row(("%d complete collections"):format(museum.collections), ctx.muted, 12, nil, 22)
	local pedestals = ctx.append(ctx.frame(ctx.list, nil, UDim2.new(1, -8, 0, 44)))
	for slot = 1, 4 do
		local picker = ctx.button(pedestals, ("SLOT %d"):format(slot), slot == selectedSlot and ctx.yellow or ctx.cream, ctx.ink, function()
			selectedSlot, choosing, pickerPage = slot, false, 1
			redraw()
		end)
		picker.Size = UDim2.new(0.25, -4, 1, 0)
		picker.Position = UDim2.new((slot-1)/4, 2, 0, 0)
	end
	local current = museum.slots[tostring(selectedSlot)]
	ctx.row(current and skinName(current) or "Empty pedestal", ctx.ink, 15, ctx.heavy, 25)
	if museum.editable then
		ctx.listButton(choosing and "CANCEL" or "CHOOSE EGG FOR THIS SLOT", ctx.lime, ctx.ink, function()
			choosing, pickerPage = not choosing, 1
			redraw()
		end)
		if choosing then chooseEgg(ctx) end
		if not choosing then
			local nextStyle = if museum.decoration == "velvet" then "ocean" elseif museum.decoration == "ocean" then "sunset" else "velvet"
			ctx.listButton("GALLERY DECOR · " .. roomStyles[museum.decoration].name, ctx.cream, ctx.ink, function()
				SocialUI.request("decorate", nextStyle)
			end)
		end
		if current then
			ctx.listButton("CLEAR SLOT", ctx.cream, ctx.ink, function()
				choosing = false
				SocialUI.request("pedestal", {slot=selectedSlot, skin=""})
			end)
		end
	else
		ctx.listButton("MY EGG MUSEUM", ctx.yellow, ctx.ink, function() SocialUI.openMuseum() end)
	end
end

function SocialUI.render(page, ctx)
	if page == "Museum" then renderMuseum(ctx) else renderFriends(ctx) end
end

return SocialUI
