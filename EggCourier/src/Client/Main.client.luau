local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("EggShared")
local Config = require(Shared.Config)
local Levels = require(Shared.Levels)
local Rules = require(Shared.RaceRules)
local Egg = require(Shared.EggModel)
local Audio = require(script.Parent.Audio)
local remote = Shared:WaitForChild("CourierEvent")
local player = Players.LocalPlayer

local rgb = Color3.fromHex
local ink, charcoal, muted = rgb("20281f"), rgb("374138"), rgb("596451")
local paper, cream = rgb("fff5d8"), rgb("ebe1c4")
local yellow, lime, rust = rgb("ffc639"), rgb("d3f480"), rgb("ff7657")
local typeface = Enum.Font.GothamMedium
local heavy = Enum.Font.GothamBlack
local digits = Enum.Font.Code
local state = {stage = "Lobby", selected = 1, level = 1, deadline = 0}
local race = {hp = 3, place = 1, total = 1, progress = 0, cooldown = 0, recover = 0}
local profile = {skins = {Classic = true}, skin = "Classic", trails = {}, records = {}, title = 1}
local tab, preview = nil, "Classic"
local setTab, draw

local gui = Instance.new("ScreenGui")
gui.Name = "CourierBroadcast"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local instance = Instance.new("UICorner")
	instance.CornerRadius = UDim.new(0, radius)
	instance.Parent = parent
end

local function outline(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
end

local function frame(parent, color, size, position, radius)
	local instance = Instance.new("Frame")
	instance.BorderSizePixel = 0
	instance.BackgroundTransparency = color and 0 or 1
	if color then instance.BackgroundColor3 = color end
	instance.Size = size
	instance.Position = position or UDim2.new()
	if radius then corner(instance, radius) end
	instance.Parent = parent
	return instance
end

local function label(parent, text, color, size, position, textSize, font)
	local instance = Instance.new("TextLabel")
	instance.BackgroundTransparency = 1
	instance.TextColor3 = color
	instance.Text = text
	instance.Font = font or typeface
	instance.TextSize = textSize
	instance.TextTruncate = Enum.TextTruncate.AtEnd
	instance.Size = size
	instance.Position = position or UDim2.new()
	instance.Parent = parent
	return instance
end

local function left(instance)
	instance.TextXAlignment = Enum.TextXAlignment.Left
	return instance
end

local function button(parent, text, color, textColor, callback)
	local instance = Instance.new("TextButton")
	instance.AutoButtonColor = true
	instance.BorderSizePixel = 0
	instance.BackgroundColor3 = color
	instance.TextColor3 = textColor
	instance.Text = text
	instance.TextTruncate = Enum.TextTruncate.AtEnd
	instance.TextSize = 13
	instance.Font = Enum.Font.GothamBold
	instance.Size = UDim2.new(1, 0, 0, 36)
	corner(instance, 5)
	instance.Parent = parent
	instance.Activated:Connect(function()
		Audio.play("Click")
		callback()
	end)
	return instance
end

local function limit(parent, x, y)
	local instance = Instance.new("UISizeConstraint")
	instance.MaxSize = Vector2.new(x, y)
	instance.Parent = parent
end

local function fire(action, value)
	remote:FireServer(action, value)
end

local function now()
	return workspace:GetServerTimeNow()
end

local function clock(seconds)
	local rounded = math.max(0, math.ceil(seconds))
	return ("%d:%02d"):format(rounded // 60, rounded % 60)
end

local function isGamepad()
	return UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
end

local root = frame(gui, nil, UDim2.fromScale(1, 1))
local tint = frame(root, rust, UDim2.fromScale(1, 1))
tint.BackgroundTransparency = 1

local hud = frame(root, ink, UDim2.new(1, -30, 0, 69), UDim2.new(0.5, 0, 0, 8), 7)
hud.AnchorPoint = Vector2.new(0.5, 0)
limit(hud, 340, 69)
local courseName = left(label(hud, "", paper, UDim2.new(1, -117, 0, 22), UDim2.fromOffset(12, 5), 13, heavy))
local raceStatus = left(label(hud, "", lime, UDim2.new(1, -137, 0, 20), UDim2.fromOffset(12, 30), 12, digits))
local raceTime = label(hud, "0:00", yellow, UDim2.fromOffset(61, 28), UDim2.new(1, -70, 0, 3), 24, digits)
raceTime.TextXAlignment = Enum.TextXAlignment.Right
local eggs = {}
for index = 1, 3 do
	local icon = frame(hud, paper, UDim2.fromOffset(11, 15), UDim2.new(1, -55 + (index - 1) * 16, 0, 35), 7)
	icon.Rotation = 12
	eggs[index] = icon
end
local progress = frame(hud, charcoal, UDim2.new(1, -24, 0, 3), UDim2.fromOffset(12, 59), 2)
local progressFill = frame(progress, lime, UDim2.fromScale(0, 1), nil, 2)

local wallet = frame(root, paper, UDim2.fromOffset(93, 33), UDim2.new(1, -13, 0, 9), 5)
wallet.AnchorPoint = Vector2.new(1, 0)
outline(wallet, ink, 1.5)
local coin = frame(wallet, yellow, UDim2.fromOffset(14, 14), UDim2.fromOffset(10, 9), 7)
outline(coin, ink)
label(coin, "•", ink, UDim2.fromScale(1, 1), nil, 11, heavy)
local coinCount = left(label(wallet, "0", ink, UDim2.fromOffset(60, 25), UDim2.fromOffset(29, 4), 17, digits))

local dock = frame(root, ink, UDim2.new(1, -24, 0, 52), UDim2.new(0.5, 0, 1, -14), 7)
dock.AnchorPoint = Vector2.new(0.5, 1)
limit(dock, 448, 52)
local dockInterior = frame(dock, nil, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
local play = button(dockInterior, "RACE", yellow, ink, function()
	fire((state.queued or state.practiceQueued) and "lobby" or "queue")
end)
play.Size = UDim2.new(0.25, -4, 1, 0)
for index, item in ipairs({{"ISLANDS", "Courses"}, {"LOCKER", "Shop"}, {"STATS", "Stats"}, {"AUDIO", "Settings"}}) do
	local option = button(dockInterior, item[1], charcoal, paper, function()
		setTab(item[2])
	end)
	option.TextSize = 11
	option.Size = UDim2.new(0.1875, -4, 1, 0)
	option.Position = UDim2.fromScale(0.25 + (index - 1) * 0.1875, 0)
end
local queueStatus = label(root, "", paper, UDim2.new(1, -40, 0, 26), UDim2.new(0.5, 0, 1, -74), 13, heavy)
queueStatus.AnchorPoint = Vector2.new(0.5, 1)
queueStatus.TextStrokeColor3 = ink
queueStatus.TextStrokeTransparency = 0.16

local banner = label(root, "", paper, UDim2.new(1, -20, 0, 90), UDim2.new(0.5, 0, 0.33, 0), 72, heavy)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.TextStrokeColor3 = ink
banner.TextStrokeTransparency = 0.03
banner.Visible = false

local toast = frame(root, ink, UDim2.new(1, -36, 0, 31), UDim2.new(0.5, 0, 0, 85), 5)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Visible = false
toast.ZIndex = 12
limit(toast, 310, 31)
local toastText = label(toast, "", yellow, UDim2.new(1, -18, 1, 0), UDim2.fromOffset(9, 0), 12, heavy)
local toastVersion = 0
local function notice(message)
	toastVersion += 1
	local current = toastVersion
	toastText.Text = message
	toast.Visible = true
	task.delay(1.9, function()
		if current == toastVersion then toast.Visible = false end
	end)
end

local shove = button(root, "SHOVE", rust, ink, function() fire("shove") end)
shove.AnchorPoint = Vector2.new(1, 0.5)
shove.Position = UDim2.new(1, -14, 0.60, 0)
shove.Size = UDim2.fromOffset(92, 51)
shove.Visible = false
outline(shove, ink, 1.5)

local practiceExit = button(root, "LEAVE PRACTICE", ink, paper, function() fire("lobby") end)
practiceExit.AnchorPoint = Vector2.new(0.5, 1)
practiceExit.Position = UDim2.new(0.5, 0, 1, -14)
practiceExit.Size = UDim2.fromOffset(132, 34)
practiceExit.Visible = false

local resultOpen = button(root, "RESULTS", yellow, ink, function() setTab("Results") end)
resultOpen.AnchorPoint = Vector2.new(0.5, 1)
resultOpen.Position = UDim2.new(0.5, 0, 1, -14)
resultOpen.Size = UDim2.fromOffset(106, 36)
resultOpen.Visible = false

ContextActionService:BindAction("CourierShove", function(_, status)
	if not shove.Visible then return Enum.ContextActionResult.Pass end
	if status == Enum.UserInputState.Begin then fire("shove") end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

local modal = frame(root, nil, UDim2.fromScale(1, 1))
modal.ZIndex = 10
modal.Visible = false
local shade = frame(modal, ink, UDim2.fromScale(1, 1))
shade.BackgroundTransparency = 0.56
shade.Active = true
local panel = frame(modal, paper, UDim2.new(1, -26, 0, 240), UDim2.fromScale(0.5, 0.5), 7)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
limit(panel, 500, 620)
outline(panel, ink, 2)
local panelStripe = frame(panel, yellow, UDim2.new(1, 0, 0, 5), nil, 2)
local panelTitle = left(label(panel, "", ink, UDim2.new(1, -72, 0, 47), UDim2.fromOffset(15, 5), 23, heavy))
local close = button(panel, "✕", cream, ink, function() setTab(nil) end)
close.Size = UDim2.fromOffset(32, 31)
close.Position = UDim2.new(1, -44, 0, 13)
close.TextSize = 17

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.fromOffset(13, 54)
list.Size = UDim2.new(1, -26, 1, -67)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = muted
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = list

local function resizePanel()
	local viewportHeight = root.AbsoluteSize.Y
	if viewportHeight == 0 or not modal.Visible then return end
	panel.Size = UDim2.new(1, -26, 0, math.min(layout.AbsoluteContentSize.Y + 70, viewportHeight - 20, 620))
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizePanel)
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizePanel)

local rowOrder = 0
local function append(instance)
	rowOrder += 1
	instance.LayoutOrder = rowOrder
	return instance
end

local function row(text, color, size, font, height)
	return append(left(label(list, text, color or ink, UDim2.new(1, -9, 0, height or 28), UDim2.new(), size or 14, font)))
end

local function listButton(text, color, textColor, callback)
	local instance = append(button(list, text, color, textColor, callback))
	instance.Size = UDim2.new(1, -7, 0, 36)
	return instance
end

local function showCourses()
	local voting = state.stage == "Voting" and state.queued
	local unlocked = player:GetAttribute("Unlocked") or 1
	if voting then row("Choose a course for the next heat", ink, 13, heavy) end
	local previousIsland
	for index, course in ipairs(Levels) do
		local island = course.island or "Green Meadows"
		if island ~= previousIsland then
			row(string.upper(island), muted, 11, heavy, 25)
			previousIsland = island
		end
		local available = index <= unlocked
		local selected = index == state.selected
		local card = append(frame(list, selected and cream or paper, UDim2.new(1, -8, 0, 56), nil, 5))
		outline(card, selected and muted or cream)
		local detailWidth = voting and -10 or -83
		local title = ("%02d   %s"):format(index, course.name)
		if available then
			local select = button(card, title, selected and cream or paper, ink, function() fire("choose", tostring(index)) end)
			select.Size = UDim2.new(1, detailWidth, 0, 28)
			select.Position = UDim2.fromOffset(6, 2)
			select.TextXAlignment = Enum.TextXAlignment.Left
		else
			left(label(card, title, muted, UDim2.new(1, detailWidth, 0, 28), UDim2.fromOffset(6, 2), 13, heavy))
		end
		local detail = if selected then "SELECTED" elseif available then (course.rating or "OPEN") else "LOCKED FOR RACE"
		if available and not selected and typeof(detail) ~= "string" then detail = tostring(detail) end
		left(label(card, string.upper(detail), muted, UDim2.new(1, detailWidth, 0, 16), UDim2.fromOffset(6, 29), 10, digits))
		if not voting then
			local practice = button(card, "PRACTICE", ink, paper, function()
				fire("practice", tostring(index))
				setTab(nil)
			end)
			practice.Size = UDim2.fromOffset(69, 44)
			practice.Position = UDim2.new(1, -75, 0, 6)
			practice.TextSize = 10
		end
	end
end

local function showShop()
	local skin = Config.bySkin[preview]
	local cost = skin[3]
	local owned = profile.skins[preview]
	local enabled = Config.passes[preview] and Config.passes[preview] > 0
	local accent = Color3.fromRGB(table.unpack(skin[5]))
	local card = append(frame(list, ink, UDim2.new(1, -7, 0, 148), nil, 6))
	local view = Instance.new("ViewportFrame")
	view.BackgroundColor3 = accent
	view.BorderSizePixel = 0
	view.Size = UDim2.new(0.42, -12, 1, -16)
	view.Position = UDim2.fromOffset(8, 8)
	view.Ambient = rgb("e6e2d8")
	view.LightColor = paper
	view.LightDirection = Vector3.new(-1, -1, -1)
	corner(view, 4)
	view.Parent = card
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(1.7, 0.65, 4), Vector3.zero)
	camera.FieldOfView = 44
	camera.Parent = view
	view.CurrentCamera = camera
	local model = Egg.build(preview, 1.4, true)
	model.Parent = view

	local title = left(label(card, skin[2], paper, UDim2.new(0.58, -17, 0, 52), UDim2.new(0.42, 5, 0, 16), 19, heavy))
	title.TextWrapped = true
	title.TextTruncate = Enum.TextTruncate.None
	local action
	if owned and profile.skin == preview then
		action = "EQUIPPED"
	elseif owned then
		action = "EQUIP"
	elseif enabled then
		action = "VIEW PRICE"
	elseif typeof(cost) == "number" then
		action = ("BUY · %d COINS"):format(cost)
	end
	if action and action ~= "EQUIPPED" then
		local equip = button(card, action, yellow, ink, function() fire("skin", preview) end)
		equip.Size = UDim2.new(0.58, -17, 0, 34)
		equip.Position = UDim2.new(0.42, 5, 1, -47)
	else
		local message = if action then action elseif preview == "Cosmic" then "WORLD 4 REWARD" else "UNAVAILABLE"
		left(label(card, message, lime, UDim2.new(0.58, -17, 0, 34), UDim2.new(0.42, 5, 1, -47), 11, heavy))
	end

	local swatches = append(frame(list, nil, UDim2.new(1, -7, 0, math.ceil(#Config.skins / 4) * 43)))
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.25, -5, 0, 36)
	grid.CellPadding = UDim2.fromOffset(5, 7)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = swatches
	for index, item in ipairs(Config.skins) do
		local tile = button(swatches, item[1], item[1] == preview and ink or cream, item[1] == preview and paper or ink, function()
			local gamepad = isGamepad()
			preview = item[1]
			draw()
			if gamepad then GuiService.SelectedObject = close end
		end)
		tile.LayoutOrder = index
		tile.TextSize = 10
		local color = Color3.fromRGB(table.unpack(item[4]))
		local mark = frame(tile, color, UDim2.new(1, -10, 0, 3), UDim2.new(0, 5, 1, -5), 2)
		if profile.skins[item[1]] then outline(mark, item[1] == preview and paper or muted) end
	end
	row("TRAILS", muted, 11, heavy, 23)
	listButton("Remove trail", cream, ink, function() fire("trail", "") end)
	for _, id in {"Lightning", "Rainbow", "VIP"} do
		local price = Config.trails[id]
		if price or profile.trails[id] then
			local description = if profile.trail == id then "Equipped" elseif profile.trails[id] then "Equip" else ("%d coins"):format(price)
			listButton(id .. "   /   " .. description, cream, ink, function() fire("trail", id) end)
		end
	end
end

local function showStats()
	row(("%d coins     %d wins     %d XP"):format(player:GetAttribute("Coins") or 0, player:GetAttribute("Wins") or 0, player:GetAttribute("XP") or 0), ink, 16, digits, 33)
	for index, title in Config.titles do
		if index < 5 and (player:GetAttribute("XP") or 0) >= Config.titleXP[index] then
			listButton(title .. (profile.title == index and "  ✓" or ""), cream, ink, function() fire("title", tostring(index)) end)
		else
			row(title .. (index == 5 and "   /   World 4 reward" or ("   /   %d XP"):format(Config.titleXP[index])), muted, 12)
		end
	end
	for index, course in ipairs(Levels) do
		local record = profile.records[Rules.recordKey(index)]
		if record then row(("%s    %.2fs"):format(course.name, record), ink, 13, digits) end
	end
end

local function showSettings()
	for _, key in {"music", "effects"} do
		local caption = key == "music" and "Music" or "Sound effects"
		local control
		local function refresh()
			control.Text = ("%s   /   %d%%"):format(caption, math.round(Audio[key] * 100))
		end
		control = listButton("", cream, ink, function()
			Audio[key] = if Audio[key] >= 0.99 then 0 elseif Audio[key] == 0 then 0.25 else math.min(1, Audio[key] + 0.25)
			Audio.setLobby(not state.racing)
			refresh()
		end)
		refresh()
	end
end

local function showResults()
	local result = state.result
	if result then
		local finished = not result.out and not result.dnf
		local card = append(frame(list, ink, UDim2.new(1, -7, 0, 95), nil, 6))
		local place = finished and ("%02d"):format(result.place) or "OUT"
		label(card, place, finished and lime or rust, UDim2.fromOffset(103, 89), UDim2.fromOffset(3, 1), 39, heavy)
		frame(card, charcoal, UDim2.fromOffset(1, 62), UDim2.fromOffset(106, 16))
		local headline
		if result.practice and finished then headline = "PRACTICE CLEAR"
		elseif finished and (state.slots or 0) > 0 and not state.solo then headline = "QUALIFIED"
		elseif finished then headline = "FINISHED"
		else headline = "ELIMINATED" end
		left(label(card, headline, paper, UDim2.new(1, -129, 0, 23), UDim2.fromOffset(119, 10), 16, heavy))
		local summary = if finished then ("%.2fs     +%d coins"):format(result.time, result.coins or 0) else ("%d%% of course"):format(math.floor((result.progress or 0) * 100))
		left(label(card, summary, paper, UDim2.new(1, -129, 0, 22), UDim2.fromOffset(119, 35), 14, digits))
		local detail = if finished then (result.record and "PERSONAL BEST" or ("SHELL %d / 3"):format(result.hp or 0)) else (result.reason or "Time expired")
		left(label(card, detail, finished and lime or rust, UDim2.new(1, -125, 0, 21), UDim2.fromOffset(119, 63), 11, heavy))
	end
	for _, entry in state.scoreboard or {} do
		if entry.time and entry.place then
			row(("%02d  %s     %.2fs"):format(entry.place, entry.name, entry.time), muted, 12, digits, 24)
		end
	end
	local actions = append(frame(list, nil, UDim2.new(1, -7, 0, 40)))
	local replay = button(actions, "QUEUE AGAIN", yellow, ink, function() fire("next"); setTab(nil) end)
	replay.Size = UDim2.new(0.54, -4, 1, 0)
	local lobby = button(actions, "BACK TO HUB", cream, ink, function() fire("lobby"); setTab(nil) end)
	lobby.Size = UDim2.new(0.46, -4, 1, 0)
	lobby.Position = UDim2.new(0.54, 4, 0, 0)
end

local tabs = {
	Courses = {title = "Island trials", color = lime, render = showCourses},
	Shop = {title = "Egg locker", color = yellow, render = showShop},
	Stats = {title = "Courier record", color = lime, render = showStats},
	Settings = {title = "Audio", color = cream, render = showSettings},
	Results = {title = "Heat results", color = rust, render = showResults},
}

draw = function()
	for _, child in list:GetChildren() do
		if child ~= layout then child:Destroy() end
	end
	rowOrder = 0
	modal.Visible = tab ~= nil
	dock.Visible = tab == nil and not state.racing
	resultOpen.Visible = tab == nil and state.result ~= nil and state.racing == true and state.stage ~= "Returning"
	if not tab then return end
	local sheet = tabs[tab]
	panelTitle.Text = sheet.title
	panelStripe.BackgroundColor3 = sheet.color
	sheet.render()
	task.defer(resizePanel)
end

setTab = function(name)
	if name and not tabs[name] then return end
	tab = name
	draw()
	list.CanvasPosition = Vector2.zero
	if isGamepad() or GuiService.SelectedObject then
		GuiService.SelectedObject = if name then close elseif dock.Visible then play elseif state.result then resultOpen else nil
	end
end

local function confetti()
	for index = 1, 19 do
		local color = ({yellow, lime, rust})[index % 3 + 1]
		local bit = frame(root, color, UDim2.fromOffset(6, 9), UDim2.fromScale(0.5, 0.43))
		bit.ZIndex = 9
		bit.Rotation = index * 37
		TweenService:Create(bit, TweenInfo.new(0.8 + index % 4 * 0.12, Enum.EasingStyle.Quad), {
			Position = UDim2.fromScale(0.5 + math.cos(index) * 0.49, 0.49 + math.sin(index) * 0.41),
			Rotation = index * 74,
			BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(bit, 1.3)
	end
end

local fade = frame(root, ink, UDim2.fromScale(1, 1))
fade.BackgroundTransparency = 1
fade.ZIndex = 20
local function transition()
	fade.BackgroundTransparency = 0.11
	TweenService:Create(fade, TweenInfo.new(0.36, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
end

local lastCount, showGo = nil, 0
remote.OnClientEvent:Connect(function(kind, value, extra)
	if kind == "State" then
		local before = state
		state = value
		if state.racing and state.stage ~= before.stage and (state.stage == "Preparation" or state.stage == "Returning") then transition() end
		if state.stage == "Preparation" and before.stage ~= "Preparation" then
			race = {hp = 3, place = 1, total = state.total, progress = 0, cooldown = 0, recover = 0}
			lastCount = nil
		elseif state.stage == "Race" and before.stage == "Countdown" and state.racing then
			showGo = now() + 0.65
			Audio.play("Start")
		end
		Audio.setLobby(not state.racing)
		if state.stage == "Returning" or (not state.racing and tab == "Results") then
			setTab(nil)
		elseif state.result and state.racing and (not before.result or (state.stage == "Results" and before.stage ~= "Results")) then
			setTab("Results")
		elseif state.racing and not state.result and tab then
			setTab(nil)
		elseif state.stage == "Voting" and state.queued and before.stage ~= "Voting" then
			setTab("Courses")
		elseif tab == "Courses" or (tab == "Results" and state.stage == "Results") then
			local position = list.CanvasPosition
			draw()
			list.CanvasPosition = position
		else
			dock.Visible = tab == nil and not state.racing
		end
	elseif kind == "Race" then
		if value.zone and not race.zone and not state.practice and not state.solo then notice("CRACK ZONE · SHOVES LIVE") end
		race = value
	elseif kind == "Profile" then
		profile = value
		if tab == "Stats" or tab == "Shop" then
			local position = list.CanvasPosition
			local selected = GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(list)
			draw()
			list.CanvasPosition = position
			if selected then GuiService.SelectedObject = close end
		end
	elseif kind == "Open" then
		setTab(value)
	elseif kind == "Notice" then
		notice(value)
	elseif kind == "Pass" then
		local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, value)
		if not ok then notice("Purchase prompt unavailable") end
	elseif kind == "FX" then
		Audio.play(value)
		if value == "Crack" or value == "Break" then
			tint.BackgroundTransparency = 0.65
			TweenService:Create(tint, TweenInfo.new(0.32), {BackgroundTransparency = 1}):Play()
			notice(if value == "Break" then "SHELL BROKEN" elseif extra == 1 then "ONE HIT LEFT" else "SHELL CRACKED")
		elseif value == "Out" then
			notice(if typeof(extra) == "string" then extra else "ELIMINATED")
		elseif value == "Restart" then
			notice("BACK TO THE START")
		elseif value == "Finish" then
			confetti()
			if extra.coins > 0 then Audio.play("Coins") end
			if extra.place == 1 then Audio.play("Victory") end
		end
	end
end)

local queueText = {
	Lobby = "Waiting to start",
	Intermission = "Heat starts in %s",
	Voting = "Vote closes in %s",
	Preparation = "Loading course",
	Countdown = "Starting in %s",
	Race = "Queued for the next heat",
	Results = "Next heat after results",
	Returning = "Waiting to start",
}
local function updateHud(current)
	local racing = state.racing and not state.result and (state.stage == "Race" or state.stage == "Countdown" or state.stage == "Preparation")
	local lobby = not state.racing
	local leftSeconds = state.deadline - current
	hud.Visible = racing
	wallet.Visible = lobby and not modal.Visible
	coinCount.Text = tostring(player:GetAttribute("Coins") or 0)
	local queued = state.queued or state.practiceQueued
	play.Text = queued and "CANCEL" or "RACE"
	queueStatus.Visible = queued == true and lobby and not modal.Visible
	queueStatus.Text = (queueText[state.stage] or queueText.Lobby):format(clock(leftSeconds))
	practiceExit.Visible = racing and state.practice == true and not modal.Visible
	resultOpen.Visible = state.result ~= nil and state.racing == true and not modal.Visible and state.stage ~= "Returning"
	if racing then
		courseName.Text = Levels[state.level].name
		raceTime.Text = clock(leftSeconds)
		raceTime.TextColor3 = leftSeconds < 12 and state.stage == "Race" and rust or yellow
		local slots = state.slots or 0
		if state.practice then raceStatus.Text = "PRACTICE"
		elseif state.solo then raceStatus.Text = "TIME TRIAL"
		elseif slots > 0 then raceStatus.Text = ("#%d   /   %d OF %d IN"):format(race.place, state.qualified or 0, slots)
		else raceStatus.Text = ("#%d   /   %d RACERS"):format(race.place, race.total) end
		progressFill.Size = UDim2.fromScale(math.clamp(race.progress or 0, 0, 1), 1)
		for index, shell in ipairs(eggs) do
			shell.BackgroundColor3 = if index > race.hp then charcoal elseif race.hp == 1 then rust else paper
		end
	end

	local recover = race.recover or 0
	local shoveAvailable = racing and state.stage == "Race" and race.zone and not state.practice and not state.solo and recover <= current
	shove.Visible = shoveAvailable == true
	if shove.Visible then
		local cooldown = math.max(0, math.ceil((race.cooldown or 0) - current))
		shove.BackgroundColor3 = cooldown > 0 and charcoal or rust
		shove.TextColor3 = cooldown > 0 and paper or ink
		local input = UserInputService:GetLastInputType()
		shove.Text = if cooldown > 0 then ("%ds"):format(cooldown) elseif input == Enum.UserInputType.Touch then "SHOVE" elseif isGamepad() then "X  SHOVE" else "E  SHOVE"
	end
	if racing and state.stage == "Countdown" then
		local count = math.max(1, math.ceil(leftSeconds))
		banner.Visible = true
		banner.Text = tostring(count)
		banner.TextSize = 72
		if lastCount ~= count then
			lastCount = count
			Audio.play("Countdown")
		end
	elseif racing and current < showGo then
		banner.Visible = true
		banner.Text = "GO!"
		banner.TextSize = 72
	elseif racing and recover > current then
		banner.Visible = true
		banner.Text = ("RESTART IN %d"):format(math.ceil(recover - current))
		banner.TextSize = 28
	else
		banner.Visible = false
	end
end

local elapsed = 0
RunService.RenderStepped:Connect(function(deltaTime)
	elapsed += deltaTime
	local current = now()
	for _, courier in Players:GetPlayers() do
		local character = courier.Character
		local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
		local egg = character and character:FindFirstChild("CourierEgg")
		local shell = egg and egg.PrimaryPart
		local motor = shell and shell:FindFirstChild("EggMotor")
		if characterRoot and motor then
			local amplitude = math.clamp(characterRoot.AssemblyLinearVelocity.Magnitude / 16, 0.2, 1)
			motor.Transform = CFrame.new(0, math.sin(current * 11) * 0.084 * amplitude, 0)
				* CFrame.Angles(math.sin(current * 6) * 0.12 * amplitude, 0, math.cos(current * 9) * 0.14 * amplitude)
			if egg:GetAttribute("Skin") == "Rainbow" then
				local rainbow = Color3.fromHSV((current % 4) / 4, 0.66, 1)
				shell.Color = rainbow
				local crown = egg:FindFirstChild("Crown")
				if crown then crown.Color = rainbow end
			end
		end
	end
	if elapsed >= 0.08 then
		elapsed = 0
		updateHud(current)
	end
end)

ContextActionService:BindAction("CourierCloseMenu", function(_, status)
	if not tab then return Enum.ContextActionResult.Pass end
	if status == Enum.UserInputState.Begin then setTab(nil) end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonB)

Audio.setLobby(true)
updateHud(now())
fire("hello")
