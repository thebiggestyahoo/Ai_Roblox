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
local ink, charcoal, muted = rgb("272054"), rgb("493b79"), rgb("5e5078")
local paper, cream = rgb("fff9ff"), rgb("ede3ff")
local yellow, lime, rust = rgb("ffcf4b"), rgb("a8f4bd"), rgb("ff8eb5")
local winnerRed = rgb("fa5451")
local worlds = {
	["Green Meadows"] = {color = rgb("b5e887"), hazards = "Rolling balls, spinners and rafts"},
	["The Egg Cooker"] = {color = rgb("ffad87"), hazards = "Heat vents and vanishing platforms"},
	["Frozen Eggs"] = {color = rgb("9ce6ff"), hazards = "Slippery ice and tilting platforms"},
	["Eggstraterrestrial"] = {color = rgb("d8bbff"), hazards = "Orbiting hazards and blink pads"},
	["Sunken Ruins"] = {color = rgb("8fe6cb"), hazards = "Rope crossings and relic chases"},
}
local typeface = Enum.Font.GothamMedium
local heavy = Enum.Font.FredokaOne
local digits = Enum.Font.GothamBold
local state = {stage = "Lobby", selected = 1, level = 1, deadline = 0}
local race = {hp = 3, place = 1, total = 1, progress = 0, cooldown = 0, recover = 0}
local profile = {skins = {Classic = true}, skin = "Classic", trails = {}, records = {}, title = 1, deliveries = 0}
local tab, preview = nil, "Classic"
local lockerPage = "Boxes"
local setTab, draw
local advanceNote
local lockerBalance
local auraToggle

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
	if radius then corner(instance, math.min(radius + 3, 18)) end
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
	instance.Font = heavy
	instance.Size = UDim2.new(1, 0, 0, 36)
	corner(instance, 11)
	outline(instance, ink, 1.5)
	local gloss = Instance.new("UIGradient")
	gloss.Rotation = 90
	gloss.Color = ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(206,198,229))
	gloss.Parent = instance
	instance.Parent = parent
	instance.Activated:Connect(function()
		Audio.play("Click")
		callback()
	end)
	return instance
end

local function bubblePanel(panel)
	outline(panel, rgb("241b50"), 2.5)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1,1,1),rgb("e7d9ff"))
	gradient.Parent = panel
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

local function heatName(heat)
	local heats = state.heats or 5
	if state.duel or heat > heats then return "FINAL DUEL" end
	return ("HEAT %02d / %02d"):format(heat, heats)
end

local function showDock()
	return tab == nil and not state.racing and not state.room
end

local function hasResult()
	return typeof(state.result) == "table" and state.stage ~= "Returning"
end

local root = frame(gui, nil, UDim2.fromScale(1, 1))
local tint = frame(root, rust, UDim2.fromScale(1, 1))
tint.BackgroundTransparency = 1

local hud = frame(root, ink, UDim2.new(1, -30, 0, 86), UDim2.new(0.5, 0, 0, 8), 7)
hud.AnchorPoint = Vector2.new(0.5, 0)
limit(hud, 340, 86)
bubblePanel(hud)
local raceHeat = left(label(hud, "", yellow, UDim2.new(1, -94, 0, 16), UDim2.fromOffset(12, 6), 11, digits))
local courseName = left(label(hud, "", paper, UDim2.new(1, -80, 0, 25), UDim2.fromOffset(12, 22), 15, heavy))
local position = left(label(hud, "", paper, UDim2.fromOffset(34, 19), UDim2.fromOffset(12, 50), 12, heavy))
local raceStatus = left(label(hud, "", lime, UDim2.new(1, -64, 0, 20), UDim2.fromOffset(51, 49), 12, digits))
local raceTime = label(hud, "0:00", yellow, UDim2.fromOffset(61, 28), UDim2.new(1, -70, 0, 3), 24, digits)
raceTime.TextXAlignment = Enum.TextXAlignment.Right
local eggs = {}
for index = 1, 3 do
	local icon = frame(hud, paper, UDim2.fromOffset(11, 15), UDim2.new(1, -55 + (index - 1) * 16, 0, 35), 7)
	icon.Rotation = 12
	eggs[index] = icon
end
local progress = frame(hud, charcoal, UDim2.new(1, -24, 0, 3), UDim2.fromOffset(12, 76), 2)
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
bubblePanel(dock)
local dockInterior = frame(dock, nil, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
local play = button(dockInterior, "QUEUE", yellow, ink, function()
	fire((state.queued or state.practiceQueued) and "lobby" or "queue")
end)
play.Size = UDim2.new(0.25, -4, 1, 0)
for index, item in ipairs({{"WORLDS", "Courses"}, {"LOCKER", "Shop"}, {"STATS", "Stats"}, {"AUDIO", "Settings"}}) do
	local option = button(dockInterior, item[1], charcoal, paper, function()
		setTab(item[2])
	end)
	option.TextSize = 11
	option.Size = UDim2.new(0.1875, -4, 1, 0)
	option.Position = UDim2.fromScale(0.25 + (index - 1) * 0.1875, 0)
end
local queueStatus = label(root, "", paper, UDim2.new(1, -40, 0, 26), UDim2.new(0.5, 0, 1, -68), 13, heavy)
queueStatus.AnchorPoint = Vector2.new(0.5, 1)
queueStatus.TextStrokeColor3 = ink
queueStatus.TextStrokeTransparency = 0.16

local staging = frame(root, ink, UDim2.new(1, -30, 0, 57), UDim2.new(0.5, 0, 0, 8), 7)
staging.AnchorPoint = Vector2.new(0.5, 0)
staging.Visible = false
limit(staging, 340, 57)
local stagingTitle = left(label(staging, "", yellow, UDim2.new(1, -24, 0, 21), UDim2.fromOffset(12, 5), 14, heavy))
local stagingBody = left(label(staging, "", paper, UDim2.new(1, -24, 0, 21), UDim2.fromOffset(12, 28), 12, digits))

local banner = label(root, "", paper, UDim2.new(1, -20, 0, 90), UDim2.new(0.5, 0, 0.33, 0), 72, heavy)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.TextStrokeColor3 = ink
banner.TextStrokeTransparency = 0.03
banner.Visible = false

local toast = frame(root, ink, UDim2.new(1, -36, 0, 31), UDim2.new(0.5, 0, 0, 103), 5)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Visible = false
toast.ZIndex = 12
limit(toast, 400, 31)
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

local draft = frame(root, ink, UDim2.new(1, -24, 0, 233), UDim2.fromScale(0.5, 0.5), 7)
draft.AnchorPoint = Vector2.new(0.5, 0.5)
draft.ZIndex = 11
draft.Visible = false
limit(draft, 400, 233)
local draftScale = Instance.new("UIScale")
draftScale.Parent = draft
bubblePanel(draft)
frame(draft, yellow, UDim2.new(1, 0, 0, 4), nil, 2)
left(label(draft, "MAP DRAW", yellow, UDim2.new(1, -120, 0, 24), UDim2.fromOffset(12, 10), 18, heavy))
local draftCounter = label(draft, "", paper, UDim2.fromOffset(71, 24), UDim2.new(1, -82, 0, 11), 13, digits)
draftCounter.TextXAlignment = Enum.TextXAlignment.Right
local reel = frame(draft, charcoal, UDim2.new(1, -24, 0, 47), UDim2.fromOffset(12, 39), 4)
reel.ClipsDescendants = true
frame(reel, paper, UDim2.new(1, 0, 0, 25), UDim2.fromOffset(0, 11))
local reelNames = {}
for index = 1, 3 do
	reelNames[index] = label(reel, "", ink, UDim2.new(1, -16, 0, 25), UDim2.fromOffset(8, 11), 15, heavy)
end
local picks = {}
for index = 1, 5 do
	local row = frame(draft, charcoal, UDim2.new(1, -24, 0, 23), UDim2.fromOffset(12, 93 + (index - 1) * 26), 3)
	local heat = left(label(row, ("H%02d"):format(index), yellow, UDim2.fromOffset(26, 23), UDim2.fromOffset(6, 0), 11, digits))
	local name = left(label(row, "", paper, UDim2.new(1, -108, 1, 0), UDim2.fromOffset(35, 0), 12, heavy))
	local rating = label(row, "", lime, UDim2.fromOffset(68, 23), UDim2.new(1, -73, 0, 0), 10, digits)
	rating.TextXAlignment = Enum.TextXAlignment.Right
	picks[index] = {row = row, heat = heat, name = name, rating = rating}
end

local lastDraftStart, shownPicks = nil, 0
local function updateDraft(current)
	local maps = state.maps
	draft.Visible = state.stage == "Draft" and state.room == true and maps ~= nil and #maps > 0
	if not draft.Visible then return end
	draftScale.Scale = math.clamp((root.AbsoluteSize.Y - 16) / 233, 0.65, 1)
	local started = state.draftStarted or state.deadline - 8
	if started ~= lastDraftStart then
		lastDraftStart = started
		shownPicks = 0
	end
	local cadence = math.max((state.deadline - started) * 0.91 / #maps, 0.1)
	local elapsed = math.max(current - started, 0)
	local heat = math.min(math.floor(elapsed / cadence) + 1, #maps)
	local ratio = math.clamp((elapsed - (heat - 1) * cadence) / (cadence * 0.75), 0, 1)
	local settled = ratio >= 1 and heat or heat - 1
	local steps = 10
	local offset = (1 - (1 - ratio) ^ 2.5) * steps
	local step = math.floor(offset)
	for index, name in ipairs(reelNames) do
		local ticket = step + index - 2
		local candidate = (heat * 7 + ticket * 3) % #Levels + 1
		if ticket >= steps then candidate = maps[heat] end
		local item = Levels[candidate]
		local y = 11 + (index - 2 - (offset - step)) * 25
		name.Position = UDim2.fromOffset(8, y)
		name.Text = item and item.name or ""
		name.TextColor3 = math.abs(y - 11) < 13 and ink or paper
	end
	draftCounter.Text = ("%02d / %02d"):format(settled, #maps)
	for index, card in ipairs(picks) do
		local item = Levels[maps[index]]
		local picked = index <= settled and item ~= nil
		card.row.Visible = item ~= nil
		card.row.BackgroundColor3 = if picked then worlds[item.island].color elseif index == heat then cream else charcoal
		card.heat.TextColor3 = if picked or index == heat then ink else yellow
		card.name.TextColor3 = if picked or index == heat then ink else paper
		card.rating.TextColor3 = ink
		card.name.Text = if picked then item.name elseif index == heat then "Drawing…" else "—"
		card.rating.Text = if picked then string.upper(item.rating or "") else ""
	end
	if settled > shownPicks then
		shownPicks = settled
		Audio.play("Click")
	end
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
shade.BackgroundTransparency = 0.31
shade.Active = true
local panel = frame(modal, paper, UDim2.new(1, -26, 0, 240), UDim2.fromScale(0.5, 0.5), 7)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
limit(panel, 500, 620)
bubblePanel(panel)
local panelStripe = frame(panel, yellow, UDim2.new(1, -16, 0, 43), UDim2.fromOffset(8, 7), 11)
outline(panelStripe, ink, 1.5)
local panelTitle = left(label(panel, "", ink, UDim2.new(1, -72, 0, 47), UDim2.fromOffset(20, 5), 25, heavy))
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
	local unlocked = player:GetAttribute("Unlocked") or 1
	local previousIsland, worldNumber = nil, 0
	row("Pick a solo course or practice any map.", muted, 12, typeface, 22)
	for index, course in ipairs(Levels) do
		local island = course.island
		local theme = worlds[island]
		if island ~= previousIsland then
			worldNumber += 1
			local header = append(frame(list, theme.color, UDim2.new(1, -8, 0, 65), nil, 7))
			left(label(header, ("ISLAND %d"):format(worldNumber), ink, UDim2.new(1, -24, 0, 14), UDim2.fromOffset(12, 5), 10, digits))
			left(label(header, island, ink, UDim2.new(1, -24, 0, 23), UDim2.fromOffset(12, 19), 19, heavy))
			left(label(header, theme.hazards, ink, UDim2.new(1, -24, 0, 16), UDim2.fromOffset(12, 43), 11))
			previousIsland = island
		end
		local available = index <= unlocked
		local selected = index == state.selected
		local card = append(frame(list, selected and theme.color or cream, UDim2.new(1, -8, 0, 100), nil, 9))
		outline(card, ink, selected and 2 or 1)
		local title = ("%02d  %s"):format(index, course.name)
		left(label(card, title, ink, UDim2.new(1, -18, 0, 25), UDim2.fromOffset(9, 5), 16, heavy))
		left(label(card, course.hook, muted, UDim2.new(1, -18, 0, 19), UDim2.fromOffset(9, 28), 11))
		local best = profile.records[Rules.recordKey(index)]
		local detail = string.upper(course.rating)
		if best then detail ..= ("  ·  PB %.2fs"):format(best) end
		left(label(card, detail, ink, UDim2.new(1, -168, 0, 16), UDim2.fromOffset(9, 63), 10, digits))
		if available and not selected then
			local pick = button(card, "PICK", paper, ink, function() fire("choose", tostring(index)) end)
			pick.Size = UDim2.fromOffset(66, 42)
			pick.Position = UDim2.new(1, -148, 0, 50)
			pick.TextSize = 11
		else
			label(card, selected and "PICKED" or "LOCKED", ink, UDim2.fromOffset(66, 42), UDim2.new(1, -148, 0, 50), 10, heavy)
		end
		local practice = button(card, "PRACTICE", ink, paper, function()
			fire("practice", tostring(index))
			setTab(nil)
		end)
		practice.Size = UDim2.fromOffset(70, 42)
		practice.Position = UDim2.new(1, -76, 0, 50)
		practice.TextSize = 10
	end
end

local function restyleLocker(page)
	lockerPage = page
	local gamepad = isGamepad()
	draw()
	list.CanvasPosition = Vector2.zero
	if gamepad then GuiService.SelectedObject = close end
end

local function showEggs()
	local skin = Config.bySkin[preview]
	local source = Config.boxBySkin[preview]
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
	local skinMark = frame(card, accent, UDim2.fromOffset(11, 16), UDim2.new(0.42, 6, 0, 19), 6)
	skinMark.Rotation = 15

	local title = left(label(card, skin[2], paper, UDim2.new(0.58, -31, 0, 52), UDim2.new(0.42, 20, 0, 11), 18, heavy))
	title.TextWrapped = true
	title.TextTruncate = Enum.TextTruncate.None
	lockerBalance = left(label(card, "", lime, UDim2.new(0.58, -17, 0, 17), UDim2.new(0.42, 6, 0, 68), 11, digits))
	local action
	if owned and profile.skin == preview then
		action = "EQUIPPED"
	elseif owned then
		action = "EQUIP"
	elseif enabled then
		action = "VIEW PRICE"
	elseif source then
		action = "VIEW " .. string.upper(source.name)
	end
	if action and action ~= "EQUIPPED" then
		local equip = button(card, action, yellow, ink, function()
			if source and not owned then restyleLocker("Boxes") else fire("skin", preview) end
		end)
		equip.TextSize = 11
		equip.Size = UDim2.new(0.58, -17, 0, 34)
		equip.Position = UDim2.new(0.42, 5, 1, -47)
	else
		local message = if action then action elseif preview == "Cosmic" then "WORLD 4 REWARD" else "UNAVAILABLE"
		left(label(card, message, lime, UDim2.new(0.58, -17, 0, 34), UDim2.new(0.42, 5, 1, -47), 11, heavy))
	end

	if source then row(source.rarity .. " · " .. source.name, muted, 13, heavy, 22) end

	local collected = 0
	for _, item in ipairs(Config.skins) do
		if profile.skins[item[1]] then collected += 1 end
	end
	row(("COLLECTION   %d / %d"):format(collected, #Config.skins), muted, 11, heavy, 24)
	local swatches = append(frame(list, nil, UDim2.new(1, -7, 0, math.ceil(#Config.skins / 4) * 61)))
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.25, -5, 0, 54)
	grid.CellPadding = UDim2.fromOffset(5, 7)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = swatches
	for index, item in ipairs(Config.skins) do
		local active = item[1] == preview
		local tile = button(swatches, item[1], active and ink or cream, active and paper or ink, function()
			preview = item[1]
			restyleLocker("Eggs")
		end)
		tile.LayoutOrder = index
		tile.TextSize = 10
		tile.TextYAlignment = Enum.TextYAlignment.Bottom
		if active then outline(tile, yellow, 1.5) end
		local shellColor = Color3.fromRGB(table.unpack(item[4]))
		local markColor = Color3.fromRGB(table.unpack(item[5]))
		local icon = frame(tile, shellColor, UDim2.fromOffset(18, 26), UDim2.new(0.5, -9, 0, 6), 10)
		icon.Rotation = -12 + index % 5 * 5
		outline(icon, active and paper or ink, 1)
		local mark = frame(icon, markColor, UDim2.fromOffset(9, 6), UDim2.fromOffset(4, 13), 3)
		mark.Rotation = 12
		if profile.skins[item[1]] then
			local stamp = frame(tile, lime, UDim2.fromOffset(7, 7), UDim2.new(1, -11, 0, 4), 4)
			outline(stamp, ink)
		end
	end
end

local function showTrails()
	listButton("Remove trail", cream, ink, function() fire("trail", "") end)
	for _, id in {"Lightning", "Rainbow", "VIP"} do
		local price = Config.trails[id]
		if price or profile.trails[id] then
			local description = if profile.trail == id then "Equipped" elseif profile.trails[id] then "Equip" else ("%d coins"):format(price)
			listButton(id .. "   /   " .. description, cream, ink, function() fire("trail", id) end)
		end
	end
end

local function showCoinPacks()
	lockerBalance = row("", ink, 14, heavy)
	local detail = row("Coins buy trails.", muted, 12, typeface)
	detail.TextWrapped = true
	detail.TextTruncate = Enum.TextTruncate.None
	for _, entry in ipairs(Config.coinPacks or {}) do
		local active = typeof(entry.productId) == "number" and entry.productId > 0
		local card = append(frame(list, cream, UDim2.new(1, -7, 0, 75), nil, 6))
		local stack = frame(card, yellow, UDim2.fromOffset(28, 28), UDim2.fromOffset(11, 22), 14)
		outline(stack, ink, 1.5)
		label(stack, "•", ink, UDim2.fromScale(1, 1), nil, 18, heavy)
		left(label(card, entry.name, ink, UDim2.new(1, -174, 0, 22), UDim2.fromOffset(47, 12), 14, heavy))
		left(label(card, ("%d coins"):format(entry.coins), muted, UDim2.new(1, -174, 0, 20), UDim2.fromOffset(47, 38), 13, digits))
		if active then
			local offer = button(card, "VIEW ROBUX PRICE", ink, paper, function() fire("coins", entry.key) end)
			offer.Size = UDim2.fromOffset(108, 42)
			offer.Position = UDim2.new(1, -118, 0, 17)
			offer.TextSize = 10
		else
			label(card, "UNAVAILABLE", muted, UDim2.fromOffset(105, 42), UDim2.new(1, -118, 0, 17), 10, heavy)
		end
	end
end

local function showBoxes()
	local deliveries = profile.deliveries or 0
	row(("%d race finishes · Boxes are free"):format(deliveries), ink, 14, heavy, 27)
	for _, box in ipairs(Config.boxes) do
		local ready, nextReward, remaining = Config.boxStatus(box, profile.skins, deliveries)
		local accent = rgb(box.color)
		local heading = append(frame(list, accent, UDim2.new(1, -7, 0, 36), nil, 6))
		left(label(heading, box.name, ink, UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 15, heavy))
		for _, reward in ipairs(box.rewards) do
			local status
			if profile.skins[reward.id] then
				status = "Collected"
			elseif deliveries < reward.deliveries then
				status = ("%d finishes"):format(reward.deliveries)
			else
				status = ("%d%%"):format(100 / #ready)
			end
			row(("%s · %s · %s"):format(reward.id, reward.rarity, status), ink, 12, typeface, 23)
		end
		if #ready > 0 then
			listButton(("OPEN BOX  (%d READY)"):format(#ready), ink, paper, function()
				fire("box", box.id)
			end)
		elseif nextReward then
			row(("Next box in %d more finishes"):format(nextReward.deliveries - deliveries), muted, 12, typeface, 26)
		elseif remaining == 0 then
			row("Collection complete", muted, 12, typeface, 26)
		end
	end
end

local function showShop()
	local tabsBar = append(frame(list, ink, UDim2.new(1, -7, 0, 42), nil, 5))
	for index, page in ipairs({"Eggs", "Boxes", "Trails", "Coin packs"}) do
		local active = lockerPage == page
		local option = button(tabsBar, string.upper(page), active and yellow or charcoal, active and ink or paper, function()
			restyleLocker(page)
		end)
		option.Size = UDim2.new(1 / 4, -6, 1, -10)
		option.Position = UDim2.new((index - 1) / 4, 4, 0, 5)
		option.TextSize = 11
	end
	if lockerPage == "Boxes" then showBoxes()
	elseif lockerPage == "Trails" then showTrails()
	elseif lockerPage == "Coin packs" then showCoinPacks()
	else showEggs() end
end

local function showStats()
	local wins = player:GetAttribute("Wins") or 0
	row(("%d coins     %d wins     %d XP"):format(player:GetAttribute("Coins") or 0, wins, player:GetAttribute("XP") or 0), ink, 16, digits, 33)
	local earned = wins >= 1
	local proof = append(frame(list, ink, UDim2.new(1, -7, 0, 74), nil, 6))
	local insignia = frame(proof, earned and winnerRed or charcoal, UDim2.fromOffset(24, 33), UDim2.fromOffset(14, 19), 12)
	outline(insignia, earned and paper or muted, 1.5)
	insignia.Rotation = 14
	local textWidth = earned and -145 or -56
	left(label(proof, "Winner aura", paper, UDim2.new(1, textWidth, 0, 23), UDim2.fromOffset(48, 10), 15, heavy))
	local status = earned and "1 / 1 WIN" or "0 / 1 WIN"
	left(label(proof, status, earned and winnerRed or cream, UDim2.new(1, textWidth, 0, 21), UDim2.fromOffset(48, 39), 12, digits))
	if earned then
		local equipped = player:GetAttribute("WinnerAura") ~= false
		auraToggle = button(proof, equipped and "AURA ON" or "AURA OFF", equipped and winnerRed or charcoal, equipped and ink or paper, function()
			fire("aura")
		end)
		auraToggle.Size = UDim2.fromOffset(76, 39)
		auraToggle.Position = UDim2.new(1, -87, 0, 17)
		auraToggle.TextSize = 11
	end
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
		local champion = result.champion == true
		local card = append(frame(list, ink, UDim2.new(1, -7, 0, 95), nil, 6))
		local place = if champion then "WIN" elseif finished then ("%02d"):format(result.place or 1) else "OUT"
		local highlight = if champion then winnerRed elseif finished then lime else rust
		label(card, place, highlight, UDim2.fromOffset(103, 89), UDim2.fromOffset(3, 1), 39, heavy)
		frame(card, charcoal, UDim2.fromOffset(1, 62), UDim2.fromOffset(106, 16))
		local headline
		if champion then headline = "CHAMPION"
		elseif result.practice and finished then headline = "PRACTICE CLEAR"
		elseif finished and (state.slots or 0) > 0 and not state.solo then headline = "QUALIFIED"
		elseif finished then headline = "FINISHED"
		else headline = "ELIMINATED" end
		left(label(card, headline, paper, UDim2.new(1, -129, 0, 23), UDim2.fromOffset(119, 10), 16, heavy))
		local summary
		if finished and result.completed ~= false and result.time then
			summary = ("%.2fs     +%d coins"):format(result.time, result.coins or 0)
		elseif champion then
			summary = ("+%d coins"):format(result.coins or 0)
		else
			summary = ("%d%% of course"):format(math.floor((result.progress or 0) * 100))
		end
		left(label(card, summary, paper, UDim2.new(1, -129, 0, 22), UDim2.fromOffset(119, 35), 14, digits))
		local detail = if champion then result.reason or "TOURNAMENT WON"
			elseif finished then result.record and "PERSONAL BEST" or ("SHELL %d / 3"):format(result.hp or 0)
			else result.reason or "Time expired"
		local reason = left(label(card, detail, highlight, UDim2.new(1, -125, 0, 25), UDim2.fromOffset(119, 61), 11, heavy))
		reason.TextWrapped = true
		reason.TextTruncate = Enum.TextTruncate.None
	end
	if result and result.completed then
		if result.perfect then row("CLEAN DELIVERY · No hits", ink, 12, heavy, 24) end
		if result.previousBest and result.time then
			local delta = result.time - result.previousBest
			row(("PERSONAL BEST PACE   %+.2fs"):format(delta), ink, 12, digits, 24)
		end
		if result.deliveries then
			local nextMilestone
			local available = 0
			for _, box in ipairs(Config.boxes) do
				local ready, nextReward = Config.boxStatus(box, profile.skins, result.deliveries)
				available += #ready
				if nextReward and not nextMilestone then nextMilestone = nextReward.deliveries end
			end
			if available > 0 then
				row("Reward box ready in the locker", ink, 12, heavy, 24)
			elseif nextMilestone then
				row(("%d more finishes to your next box"):format(nextMilestone - result.deliveries), ink, 12, heavy, 24)
			end
		end
	end
	local advanced = result and result.advanced and not result.champion
	if advanced then
		advanceNote = row("", ink, 12, digits, 35)
	end
	for _, entry in state.scoreboard or {} do
		if entry.place then
			local detail = entry.time and entry.completed ~= false and ("     %.2fs"):format(entry.time) or ""
			row(("%02d  %s%s"):format(entry.place, entry.name, detail), muted, 12, digits, 24)
		end
	end
	if not advanced then
		local actions = append(frame(list, nil, UDim2.new(1, -7, 0, 40)))
		local replay = button(actions, "QUEUE AGAIN", yellow, ink, function() fire("next"); setTab(nil) end)
		replay.Size = UDim2.new(0.54, -4, 1, 0)
		local lobby = button(actions, "BACK TO HUB", cream, ink, function() fire("lobby"); setTab(nil) end)
		lobby.Size = UDim2.new(0.46, -4, 1, 0)
		lobby.Position = UDim2.new(0.54, 4, 0, 0)
	end
end

local tabs = {
	Courses = {title = "Choose a world", color = lime, render = showCourses},
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
	advanceNote = nil
	lockerBalance = nil
	auraToggle = nil
	modal.Visible = tab ~= nil
	dock.Visible = showDock()
	resultOpen.Visible = tab == nil and hasResult()
	if not tab then return end
	local sheet = tabs[tab]
	panelTitle.Text = if tab == "Results" and state.tournament and state.heat then
		if state.duel then "Final duel" else ("Heat %d results"):format(state.heat)
		else sheet.title
	panelStripe.BackgroundColor3 = tab == "Results" and state.result and state.result.champion and winnerRed or sheet.color
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

local function refreshAura()
	if tab ~= "Stats" then return end
	local scrolled = list.CanvasPosition
	local toggled = auraToggle and GuiService.SelectedObject == auraToggle
	draw()
	list.CanvasPosition = scrolled
	if toggled then GuiService.SelectedObject = auraToggle or close end
end
player:GetAttributeChangedSignal("WinnerAura"):Connect(refreshAura)
player:GetAttributeChangedSignal("Wins"):Connect(refreshAura)

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
		if state.stage == "Returning" or (tab == "Results" and not hasResult()) or (state.room and state.stage == "Draft" and tab) then
			setTab(nil)
		elseif hasResult() and (not before.result or before.result.champion ~= state.result.champion
			or (state.stage == "Results" and before.stage ~= "Results")) then
			setTab("Results")
		elseif state.racing and not state.result and tab then
			setTab(nil)
		elseif tab == "Courses" or (tab == "Results" and state.stage == "Results") then
			local position = list.CanvasPosition
			draw()
			list.CanvasPosition = position
		else
			dock.Visible = showDock()
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
	elseif kind == "BoxReward" then
		preview = value
		lockerPage = "Eggs"
		setTab("Shop")
		notice(extra .. " unlocked · " .. Config.bySkin[value][2])
	elseif kind == "Pass" then
		local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, value)
		if not ok then notice("Purchase prompt unavailable") end
	elseif kind == "Product" then
		local ok = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, value)
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
			if extra.champion then Audio.play("Victory") end
		end
	end
end)

local queueText = {
	Lobby = "RACE QUEUE",
	Intermission = "QUEUE CLOSES IN %s",
	Draft = "NEXT TOURNAMENT",
	Preparation = "NEXT TOURNAMENT",
	Countdown = "NEXT TOURNAMENT",
	Race = "NEXT TOURNAMENT",
	Results = "NEXT TOURNAMENT",
	Returning = "RACE QUEUE",
}
local function updateHud(current)
	local racing = state.racing and not state.result and (state.stage == "Race" or state.stage == "Countdown" or state.stage == "Preparation")
	local leftSeconds = state.deadline - current
	updateDraft(current)
	local waiting = state.room == true and not racing and not draft.Visible and not modal.Visible
	local announcement = not state.room and state.stage == "Results" and typeof(state.victor) == "string" and not modal.Visible
	staging.Visible = waiting or announcement
	if announcement then
		stagingTitle.Text = "TOURNAMENT CHAMPION"
		stagingBody.Text = state.victor
	elseif waiting then
		stagingTitle.Text = state.result and state.result.advanced and "QUALIFIED" or "TOURNAMENT"
		stagingBody.Text = state.result and "CHECK YOUR RESULTS" or "WAITING FOR THE NEXT HEAT"
	end
	if advanceNote then
		local nextHeat = heatName((state.heat or 1) + 1)
		advanceNote.Text = if state.stage == "Results" then ("%s IN %s"):format(nextHeat, clock(leftSeconds)) else ("%s · WAITING FOR FINISH"):format(nextHeat)
	end

	hud.Visible = racing
	wallet.Visible = not state.racing and not state.room and not modal.Visible
	local balance = player:GetAttribute("Coins") or 0
	coinCount.Text = tostring(balance)
	if lockerBalance then lockerBalance.Text = ("%d COINS"):format(balance) end
	local queued = state.queued or state.practiceQueued
	play.Text = queued and "CANCEL" or "QUEUE"
	queueStatus.Visible = showDock()
	local population = ("%02d / %02d"):format(state.queuedCount or 0, state.capacity or 15)
	local queueState = (queueText[state.stage] or queueText.Lobby):format(clock(leftSeconds))
	queueStatus.Text = state.practiceQueued and "PRACTICE QUEUED" or queueState .. "  ·  " .. population
	practiceExit.Visible = racing and state.practice == true and not modal.Visible
	resultOpen.Visible = hasResult() and not modal.Visible
	if racing then
		courseName.Text = Levels[state.level].name
		raceHeat.Text = if state.practice then "PRACTICE"
			elseif state.solo then "TIME TRIAL"
			elseif state.tournament then heatName(state.heat or 1)
			else "KNOCKOUT"
		raceTime.Text = clock(leftSeconds)
		raceTime.TextColor3 = leftSeconds < 12 and state.stage == "Race" and rust or yellow
		local slots = state.slots or race.slots or 0
		local filled = math.max(state.qualified or 0, race.qualified or 0)
		local percent = math.floor((race.progress or 0) * 100)
		position.Text = (state.practice or state.solo) and ("%d%%"):format(percent) or ("#%02d"):format(race.place)
		raceStatus.Text = if state.practice then "RESTARTS AT THE START"
			elseif state.solo then ""
			elseif slots > 0 then ("%02d/%02d FILLED  /  %d OPEN"):format(filled, slots, math.max(0, slots - filled))
			else ("%d RACERS"):format(race.total)
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
