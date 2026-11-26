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
local Cosmetics = require(Shared.Cosmetics)
local Egg = require(Shared.EggModel)
local Audio = require(script.Parent.Audio)
local Economy = require(Shared.EconomyConfig)
local Season = require(Shared.SeasonConfig)
local Atlas = require(script.Parent.AdventureAtlas)
local ProgressUI = require(script.Parent.ProgressUI)
local EggJournal = require(script.Parent.EggJournal)
local CartonReveal = require(script.Parent.CartonReveal)
local SocialUI = require(script.Parent.SocialUI)
local Cinematics = require(script.Parent.Cinematics)
local ChampionshipView = require(script.Parent.ChampionshipView)
local remote = Shared:WaitForChild("CourierEvent")
local player = Players.LocalPlayer

local rgb = Color3.fromHex
local ink, charcoal, muted = rgb("272054"), rgb("493b79"), rgb("5e5078")
local paper, cream = rgb("fff9ff"), rgb("ede3ff")
local yellow, lime, rust = rgb("ffcf4b"), rgb("a8f4bd"), rgb("ff8eb5")
local winnerRed = rgb("fa5451")
local worldColors = {}
for _, world in ipairs(Levels.worlds) do worldColors[world.key] = rgb(world.color) end
local typeface = Enum.Font.GothamMedium
local heavy = Enum.Font.FredokaOne
local digits = Enum.Font.GothamBold
local state = {stage = "Lobby", selected = 1, level = 1, deadline = 0}
local race = {hp = 3, place = 1, total = 1, progress = 0, cooldown = 0, recover = 0}
local profile = {skins = {Classic = true}, skin = "Classic", trails = {}, records = {}, title = 1, deliveries = 0}
local tab, worldKey
local reducedMotion = false
pcall(function() reducedMotion = GuiService.ReducedMotionEnabled end)
Cinematics.setReducedMotion(reducedMotion)
local setTab, draw
local advanceNote
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
	local scale = Instance.new("UIScale")
	scale.Parent = instance
	local scaleTween
	local function animate(target)
		if reducedMotion or not instance.Active then return end
		if scaleTween then scaleTween:Cancel() end
		scaleTween = TweenService:Create(scale,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{Scale=target})
		scaleTween:Play()
	end
	instance.MouseEnter:Connect(function() animate(1.025) end)
	instance.MouseLeave:Connect(function() animate(1) end)
	instance.SelectionGained:Connect(function() animate(1.025) end)
	instance.SelectionLost:Connect(function() animate(1) end)
	instance.MouseButton1Down:Connect(function() animate(0.975) end)
	instance.MouseButton1Up:Connect(function() animate(1) end)
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
	if state.duel or heat >= heats then return "CHAMPIONSHIP" end
	return ("ROUND %d / %d"):format(heat, heats)
end

local function showDock()
	return tab == nil and not state.racing and not state.room
end

local function hasResult()
	return state.stage ~= "Returning" and (typeof(state.result) == "table"
		or (state.stage == "Results" and state.room and state.championship ~= nil))
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

local dock = frame(root, ink, UDim2.new(1, -24, 0, 109), UDim2.new(0.5, 0, 1, -14), 7)
dock.AnchorPoint = Vector2.new(0.5, 1)
limit(dock, 510, 109)
bubblePanel(dock)
local dockInterior = frame(dock, nil, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
local play = button(dockInterior, "▶  PLAY", yellow, ink, function()
	if state.queued or state.practiceQueued then fire("lobby") else setTab("Play") end
end)
play.Size = UDim2.new(1,-4,0,49)
play.TextSize = 25
for index, item in ipairs({{"WORLDS", "Courses"}, {"EGGS", "Shop"}, {"PASS", "Season"}, {"MORE", "More"}}) do
	local option = button(dockInterior, item[1], (index%2==0 and cream or lime), ink, function()
		setTab(item[2])
	end)
	option.TextSize = 14
	option.Size = UDim2.new(0.25,-4,0,42)
	option.Position = UDim2.new((index-1)*0.25,0,0,54)
end
local queueStatus = label(root, "", paper, UDim2.new(1, -40, 0, 26), UDim2.new(0.5, 0, 1, -126), 13, heavy)
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
	if typeof(message) ~= "string" or message == "" then return end
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
	local settled = (ratio >= 1 or reducedMotion) and heat or heat - 1
	local steps = 10
	local offset = reducedMotion and steps or (1 - (1 - ratio) ^ 2.5) * steps
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
		card.row.BackgroundColor3 = if picked then (worldColors[item.worldKey] or yellow):Lerp(paper,0.66) elseif index == heat then cream else charcoal
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

local watchLive = button(root,"WATCH RACE",lime,ink,function()
	if state.spectate and state.spectate[1] then SocialUI.request("spectate",state.spectate[1]) end
end)
watchLive.AnchorPoint = Vector2.new(0.5,1)
watchLive.Position = UDim2.new(0.5,0,1,-128)
watchLive.Size = UDim2.fromOffset(128,42)
watchLive.Visible = false

local practiceExit = button(root, "LEAVE ADVENTURE", ink, paper, function() fire("lobby") end)
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
limit(panel, 610, 655)
bubblePanel(panel)
local panelStripe = frame(panel, yellow, UDim2.new(1, -16, 0, 43), UDim2.fromOffset(8, 7), 11)
outline(panelStripe, ink, 1.5)
local panelTitle = left(label(panel, "", ink, UDim2.new(1, -72, 0, 47), UDim2.fromOffset(20, 5), 25, heavy))
local close = button(panel, "✕", cream, ink, function() setTab(nil) end)
close.Size = UDim2.fromOffset(43, 42)
close.Position = UDim2.new(1, -53, 0, 8)
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
	panel.Size = UDim2.new(1, -26, 0, math.min(layout.AbsoluteContentSize.Y + 70, viewportHeight - 20, 655))
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
	instance.Size = UDim2.new(1, -7, 0, 44)
	return instance
end

local function eggPreview(parent, skin, size, position, background)
	local view = Instance.new("ViewportFrame")
	view.BackgroundColor3 = background or rgb("ddd1fe")
	view.BorderSizePixel = 0
	view.Ambient = rgb("dfdcff")
	view.LightColor = paper
	view.LightDirection = Vector3.new(-1,-1,-1)
	view.Size, view.Position = size, position
	corner(view,11)
	view.Parent = parent
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(1.68,0.63,4.5),Vector3.zero)
	camera.FieldOfView = 42
	camera.Parent = view
	view.CurrentCamera = camera
	local ok, shell = pcall(Egg.build, skin, 1.4, true)
	if ok then shell.Parent = view end
	return view
end

local function uiContext()
	return {
		list=list, row=row, append=append, listButton=listButton, frame=frame, label=label, left=left, button=button,
		outline=outline, corner=corner, eggPreview=eggPreview,
		ink=ink, charcoal=charcoal, paper=paper, cream=cream, yellow=yellow, lime=lime, muted=muted, heavy=heavy, digits=digits,
		profile=profile, state=state, reducedMotion=reducedMotion, worldKey=worldKey,
		economy=Economy, season=Season, levels=Levels, config=Config, cosmetics=Cosmetics, rules=Rules,
		send=fire, navigate=setTab, close=function() setTab(nil) end,
		selectWorld=function(key)
			worldKey = key
			setTab("Courses")
		end,
	}
end

local function showCourses() Atlas.render(uiContext()) end
local function showSeason() ProgressUI.season(uiContext()) end
local function showCartons() ProgressUI.cartons(uiContext()) end
local function showCollectors() ProgressUI.collectors(uiContext()) end
local function showQuests() ProgressUI.quests(uiContext()) end
local function showFriends() SocialUI.render("Friends", uiContext()) end
local function showMuseum() SocialUI.render("Museum", uiContext()) end

local function showShop()
	local options = append(frame(list,nil,UDim2.new(1,-7,0,47)))
	local boxes = button(options,"◒  CARTONS",yellow,ink,function() setTab("Cartons") end)
	boxes.Size = UDim2.new(0.5,-5,1,0)
	local styles = button(options,"✦  CUSTOMIZE",cream,ink,function() setTab("Customize") end)
	styles.Size, styles.Position = UDim2.new(0.5,-5,1,0),UDim2.new(0.5,5,0,0)
	append(EggJournal.render(list,{
		profile=profile, send=fire, reducedMotion=reducedMotion, navigate=setTab,
		close=function() setTab(nil) end, rerender=draw,
	}))
end

local function showCustomize()
	local legacy = profile.legacyCoins or 0
	if legacy > 0 then
		row(("%d carried-over coins for trails"):format(legacy),muted,13,digits,27)
	end
	for _, category in {
		{key="trail", items=profile.trails, current=profile.trail, name="Trails"},
		{key="accessory", items=profile.accessories, current=profile.accessory, name="Egg accessories"},
		{key="victory", items=profile.victories, current=profile.victory, name="Victory animations"},
		{key="banner", items=profile.banners, current=profile.banner, name="Profile banners"},
		{key="title", items=profile.titlesOwned, current=profile.customTitle, name="Season titles"},
	} do
		row(category.name,ink,17,heavy,40)
		if category.key ~= "title" and category.current and category.current ~= "" then
			listButton("Remove equipped " .. category.key,cream,ink,function() fire(category.key,"") end)
		end
		local ids = {}
		for id, owned in category.items or {} do
			if owned then table.insert(ids,id) end
		end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local name = string.gsub(id,"[_%-]"," ")
			listButton(name .. (category.current == id and " · Equipped" or ""),cream,ink,function() fire(category.key,id) end)
		end
		if category.key == "trail" then
			local available = {"Lightning","Rainbow"}
			for _, id in ipairs(available) do
				if not (category.items and category.items[id]) and Config.trails[id] then
					listButton(("%s trail  ·  %d coins"):format(id,Config.trails[id]),cream,ink,function() fire("trail",id) end)
				end
			end
		elseif #ids == 0 then
			row("Discover these through play and the Season Pass.",muted,12,nil,31)
		end
	end
end

local function showPlay()
	local hero = append(frame(list,ink,UDim2.new(1,-7,0,123),nil,12))
	outline(hero,ink,2)
	local skin = Cosmetics.byId[profile.skin] or Cosmetics.byId.Classic
	local viewport = eggPreview(hero,skin.id,UDim2.new(0.32,-10,1,-14),UDim2.fromOffset(7,7),lime)
	if not reducedMotion then
		task.spawn(function()
			while viewport.Parent and viewport:IsDescendantOf(list) do
				local camera = viewport.CurrentCamera
				local angle = now()*0.95
				camera.CFrame = CFrame.lookAt(Vector3.new(math.sin(angle)*4.1,0.68,math.cos(angle)*4.1),Vector3.zero)
				task.wait(0.07)
			end
		end)
	end
	left(label(hero,"Ready, courier?",yellow,UDim2.new(0.68,-18,0,35),UDim2.new(0.32,8,0,16),23,heavy))
	local premise = left(label(hero,"Reach the finish with your egg intact.",paper,
		UDim2.new(0.68,-18,0,48),UDim2.new(0.32,8,0,55),14))
	premise.TextWrapped = true
	for _, mode in {
		{title="EGG ROYALE", desc="Qualify across five rounds to become champion.", action="queue", color=yellow},
		{title="QUICK RACE", desc="One competitive race, start to finish.", action="quick", color=lime},
		{title="ADVENTURE MODE", desc="Explore courses and earn medals and relics.", color=cream},
	} do
		local card = append(frame(list,mode.color,UDim2.new(1,-7,0,90),nil,11))
		outline(card,ink,1.8)
		local option = button(card,mode.title,ink,paper,function()
			if mode.action then fire(mode.action); setTab(nil) else setTab("Courses") end
		end)
		option.Size, option.Position = UDim2.new(1,-14,0,43),UDim2.fromOffset(7,7)
		option.TextSize = 17
		local summary = label(card,mode.desc,ink,UDim2.new(1,-20,0,32),UDim2.fromOffset(10,53),12)
		summary.TextWrapped = true
	end
end

local function showMore()
	for _, item in {
		{"◒   Cartons","Cartons",yellow}, {"◎   Friends","Friends",lime}, {"✦   Quests","Quests",cream},
		{"★   Records","Stats",yellow}, {"◆   Egg Museum","Museum",lime}, {"⚙   Settings","Settings",cream},
	} do
		listButton(item[1],item[3],ink,function()
			if item[2] == "Museum" then SocialUI.openMuseum() else setTab(item[2]) end
		end)
	end
end

local function showStats()
	local wins = profile.championships or player:GetAttribute("Wins") or 0
	row(("%d championships  ·  %d finishes"):format(wins,profile.deliveries or 0), ink, 16, digits, 33)
	row(("%d Egg Coins  ·  %d Courier XP"):format(profile.coins or 0,profile.xp or 0),muted,13,digits,26)
	listButton("My Egg Museum",lime,ink,function() SocialUI.openMuseum() end)
	local earned = (profile.wins or player:GetAttribute("Wins") or 0) >= 1
	local proof = append(frame(list, ink, UDim2.new(1, -7, 0, 74), nil, 6))
	local insignia = frame(proof, earned and winnerRed or charcoal, UDim2.fromOffset(24, 33), UDim2.fromOffset(14, 19), 12)
	outline(insignia, earned and paper or muted, 1.5)
	insignia.Rotation = 14
	local textWidth = earned and -145 or -56
	left(label(proof, "Winner aura", paper, UDim2.new(1, textWidth, 0, 23), UDim2.fromOffset(48, 10), 15, heavy))
	local status = earned and "UNLOCKED" or "WIN TO UNLOCK"
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
		local record = profile.records and profile.records[Rules.recordKey(index)]
		local medal = profile.medals and profile.medals[tostring(index)]
		local detail = if typeof(medal) == "string" then "  ·  " .. medal else ""
		if record then row(("%s  ·  %.2fs%s"):format(course.name, record,detail), ink, 13, digits) end
	end
end

local function showSettings()
	listButton(reducedMotion and "Reduced motion: On" or "Reduced motion: Off",cream,ink,function()
		reducedMotion = not reducedMotion
		Cinematics.setReducedMotion(reducedMotion)
		draw()
	end)
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
		elseif result.practice and finished then headline = "ADVENTURE CLEAR"
		elseif finished and result.advanced then headline = "QUALIFIED"
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
		if result.medal then row("MEDAL  ·  " .. tostring(result.medal),ink,13,heavy,27) end
	end
	if result and result.tournamentPlace and result.tournamentPlace > 1 then
		row(("FINAL PLACE %d  ·  +%d EGG COINS"):format(result.tournamentPlace,result.coins or 0),ink,13,heavy,31)
	end
	if result and (result.xp or 0) > 0 then
		row(("+%d Pass XP"):format(result.xp),ink,13,heavy,26)
	end
	if result and not result.completed and (result.coins or 0) > 0 then
		row(("+%d Egg Coins"):format(result.coins),ink,13,heavy,26)
	end
	local winner = state.championship
	if winner then append(ChampionshipView.render(list,winner)) end
	if result and result.tournamentPlace then
		row(("TOURNAMENT PLACEMENT  ·  #%d"):format(result.tournamentPlace),ink,13,heavy,27)
	end

	local advanced = result and result.advanced and not result.champion
	if advanced then
		advanceNote = row("", ink, 12, digits, 28)
		local nextIndex = state.maps and state.maps[(state.heat or 1)+1]
		local upcoming = nextIndex and Levels[nextIndex]
		if upcoming then
			local tint = (worldColors[upcoming.worldKey] or yellow):Lerp(paper,0.56)
			local ribbon = append(frame(list,tint,UDim2.new(1,-7,0,63),nil,9))
			outline(ribbon,ink,1.5)
			left(label(ribbon,"UP NEXT  ·  " .. (upcoming.island or "Championship"),ink,UDim2.new(1,-22,0,21),UDim2.fromOffset(11,6),11,digits))
			left(label(ribbon,upcoming.name,ink,UDim2.new(1,-22,0,27),UDim2.fromOffset(11,29),17,heavy))
		end
	end
	if state.stage == "Race" and (not state.racing or result) and state.spectate and state.spectate[1] then
		listButton("Watch the race",lime,ink,function() SocialUI.request("spectate",state.spectate[1]) end)
	end
	local standingRows = state.standings or state.scoreboard or {}
	if #standingRows > 0 then
		local qualified = 0
		for _, entry in ipairs(standingRows) do
			if entry.status == "Qualified" then qualified += 1 end
		end
		local title = if state.tournament and state.stage == "Results" and not state.duel
			then ("%d racers advance"):format(qualified)
			else "Race standings"
		row(title,ink,15,heavy,29)
	end
	for _, entry in ipairs(standingRows) do
		local status = entry.status or "Finished"
		local accent = if status == "Eliminated" then rust elseif status == "Champion" then yellow elseif status == "Qualified" then lime else cream
		local standing = append(frame(list,accent,UDim2.new(1,-7,0,38),nil,8))
		if entry.userId then
			local portrait = Instance.new("ImageLabel")
			portrait.Size = UDim2.fromOffset(29,29)
			portrait.Position = UDim2.fromOffset(5,4)
			portrait.BackgroundTransparency = 1
			portrait.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(entry.userId)
			portrait.Parent = standing
			corner(portrait,9)
		end
		local rank = entry.place and ("%02d  "):format(entry.place) or ""
		left(label(standing,rank .. (entry.name or "Courier"),ink,UDim2.new(1,-136,1,0),UDim2.fromOffset(41,0),12,heavy))
		label(standing,status,ink,UDim2.fromOffset(88,38),UDim2.new(1,-93,0,0),11,digits)
	end
	if not advanced then
		local actions = append(frame(list, nil, UDim2.new(1, -7, 0, 40)))
		local replay = button(actions, state.mode == "adventure" and "RETRY ADVENTURE" or "QUEUE AGAIN", yellow, ink, function()
			if state.mode == "adventure" then fire("practice",tostring(state.level))
			else fire("next",state.mode == "quick" and "quick" or "royale") end
			setTab(nil)
		end)
		replay.Size = UDim2.new(0.54, -4, 1, 0)
		local lobby = button(actions, "BACK TO HUB", cream, ink, function() fire("lobby"); setTab(nil) end)
		lobby.Size = UDim2.new(0.46, -4, 1, 0)
		lobby.Position = UDim2.new(0.54, 4, 0, 0)
	end
end

local tabs = {
	Play = {title="Ready to race?", color=yellow, render=showPlay},
	More = {title="Courier menu", color=yellow, render=showMore},
	Season = {title="Season Pass", color=yellow, render=showSeason},
	Cartons = {title="Egg Cartons", color=yellow, render=showCartons},
	Collectors = {title="Collector Cartons", color=cream, render=showCollectors},
	Customize = {title="Customize", color=lime, render=showCustomize},
	Quests = {title="Quest Journal", color=lime, render=showQuests},
	Friends = {title="Friends and Parties", color=lime, render=showFriends},
	Museum = {title="Egg Museum", color=lime, render=showMuseum},
	Courses = {title = "Adventure Atlas", color = lime, render = showCourses},
	Shop = {title = "Egg Encyclopedia", color = yellow, render = showShop},
	Stats = {title = "Courier record", color = lime, render = showStats},
	Settings = {title = "Settings", color = cream, render = showSettings},
	Results = {title = "Heat results", color = rust, render = showResults},
}

draw = function()
	for _, child in list:GetChildren() do
		if child ~= layout then child:Destroy() end
	end
	rowOrder = 0
	advanceNote = nil
	auraToggle = nil
	modal.Visible = tab ~= nil
	dock.Visible = showDock()
	resultOpen.Visible = tab == nil and hasResult()
	if not tab then return end
	local sheet = tabs[tab]
	panelTitle.Text = if tab == "Results" and state.tournament and state.heat then
		if state.duel then "Championship results" else ("Round %d results"):format(state.heat)
		else sheet.title
	panelStripe.BackgroundColor3 = tab == "Results" and state.result and state.result.champion and winnerRed or sheet.color
	sheet.render()
	task.defer(resizePanel)
end

setTab = function(name)
	if name and not tabs[name] then return end
	local previous = tab
	tab = name
	draw()
	list.CanvasPosition = Vector2.zero
	if isGamepad() or GuiService.SelectedObject then
		GuiService.SelectedObject = if name then close elseif dock.Visible then play elseif state.result then resultOpen else nil
	end
	if (name == "Friends" or name == "Museum") and previous ~= name then SocialUI.request("refresh") end
end

SocialUI.bind({
	redraw=function() if tab == "Friends" or tab == "Museum" then draw() end end,
	notify=notice,
	close=function() setTab(nil) end,
	openMuseum=function() setTab("Museum") end,
	currentCourse=function() return state.selected or 1 end,
})

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
	if reducedMotion then return end
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
	if reducedMotion then return end
	fade.BackgroundTransparency = 0.11
	TweenService:Create(fade, TweenInfo.new(0.36, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
end

local lastCount, showGo, finishBanner, finishMessage = nil, 0, 0, ""
remote.OnClientEvent:Connect(function(kind, value, extra)
	if kind == "State" then
		local before = state
		state = value
		if state.racing and not before.racing then SocialUI.stop() end
		Cinematics.update(state,before)
		if state.racing and state.stage ~= before.stage and (state.stage == "Preparation" or state.stage == "Returning") then transition() end
		if state.stage == "Preparation" and before.stage ~= "Preparation" then
			race = {hp = 3, place = 1, total = state.total, progress = 0, cooldown = 0, recover = 0}
			lastCount = nil
		elseif state.stage == "Race" and before.stage == "Countdown" and state.racing then
			showGo = now() + 0.65
			Audio.play("Start")
		end
		local course = Levels[state.level]
		Audio.setScene(course and course.worldKey,state.racing)
		if state.stage == "Returning" or (tab == "Results" and not hasResult()) or (state.room and state.stage == "Draft" and tab) then
			setTab(nil)
		elseif hasResult() and ((state.result and (not before.result or before.result.champion ~= state.result.champion))
			or (state.stage == "Results" and before.stage ~= "Results")) then
			setTab("Results")
		elseif state.racing and not state.result and tab then
			setTab(nil)
		elseif (tab == "Results" and state.stage == "Results" and before.standings ~= state.standings)
			or (tab == "Courses" and before.selected ~= state.selected) then
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
		if tab and tab ~= "Results" and tab ~= "Settings" and tab ~= "Play" and tab ~= "More" then
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
		if typeof(value) == "table" then
			CartonReveal.show(gui,{
				id=value.id, name=value.name, rewards=value.eggs or value.rewards, extras=value.extras,
			},{reducedMotion=reducedMotion,send=fire,onCollection=function() setTab("Shop") end})
		end
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
			notice(extra and "BACK TO YOUR CHECKPOINT" or "BACK TO THE START")
		elseif value == "Checkpoint" then
			notice(("CHECKPOINT %d SAVED"):format(extra))
		elseif value == "Relic" then
			notice("RELIC DISCOVERED")
		elseif value == "Finish" then
			confetti()
			finishBanner = now() + 1.9
			finishMessage = if extra and extra.champion then "CHAMPION!" elseif extra and extra.advanced then "QUALIFIED!" else "FINISH!"
			if extra and (extra.coins or 0) > 0 then Audio.play("Coins") end
			if extra and extra.champion then Audio.play("Victory") end
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
	banner.ZIndex = 1
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
	local balance = profile.coins or player:GetAttribute("Coins") or 0
	coinCount.Text = tostring(balance)
	local queued = state.queued or state.practiceQueued
	play.Text = queued and "CANCEL QUEUE" or "▶  PLAY"
	queueStatus.Visible = showDock()
	local population = ("%02d / %02d"):format(state.queuedCount or 0, state.capacity or 15)
	local queueState = (queueText[state.stage] or queueText.Lobby):format(clock(leftSeconds))
	queueStatus.Text = if state.practiceQueued then "ADVENTURE QUEUED"
		elseif queued then queueState .. "  ·  " .. population
		else ""
	practiceExit.Visible = racing and state.practice == true and not modal.Visible
	resultOpen.Visible = hasResult() and not modal.Visible
	watchLive.Visible = (not racing and not modal.Visible and not hasResult() and state.stage == "Race"
		and state.spectate ~= nil and #state.spectate > 0)
	if racing then
		courseName.Text = Levels[state.level].name
		raceHeat.Text = if state.practice then "ADVENTURE MODE"
			elseif state.solo then "TIME TRIAL"
			elseif state.tournament then heatName(state.heat or 1)
			else "QUICK RACE"
		raceTime.Text = clock(leftSeconds)
		raceTime.TextColor3 = leftSeconds < 12 and state.stage == "Race" and rust or yellow
		local slots = state.slots or race.slots or 0
		local filled = math.max(state.qualified or 0, race.qualified or 0)
		local percent = math.floor((race.progress or 0) * 100)
		position.Text = (state.practice or state.solo) and ("%d%%"):format(percent) or ("#%02d"):format(race.place)
		raceStatus.Text = if state.practice then "CHECKPOINTS ENABLED"
			elseif state.solo then ""
			elseif slots > 0 then ("%02d/%02d QUALIFIED  ·  %d OPEN"):format(filled, slots, math.max(0, slots - filled))
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
	banner.TextColor3 = paper
	if racing and state.stage == "Countdown" then
		local count = math.max(1, math.ceil(leftSeconds))
		banner.Visible = true
		banner.Text = tostring(count)
		local course = Levels[state.level]
		local world = course and Levels.worldByKey[course.worldKey]
		banner.TextColor3 = if world then rgb(world.accent) else paper
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
		banner.Text = ("CHECKPOINT IN %d"):format(math.ceil(recover - current))
		banner.TextSize = 28
	elseif current < finishBanner then
		banner.Visible = true
		banner.Text = finishMessage
		banner.TextSize = 43
		banner.ZIndex = 15
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
			local amplitude = reducedMotion and 0 or math.clamp(characterRoot.AssemblyLinearVelocity.Magnitude / 16, 0.2, 1)
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
