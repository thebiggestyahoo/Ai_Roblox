local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Levels = require(ReplicatedStorage:WaitForChild("EggShared").Levels)
local player = Players.LocalPlayer
local Cinematics = {}
local shot
local reducedMotion = false
local attempted
local actionName = "SkipCourierIntro"

local function stop()
	local active = shot
	if not active then return end
	shot = nil
	active.connection:Disconnect()
	active.gui:Destroy()
	ContextActionService:UnbindAction(actionName)
	if active.camera == workspace.CurrentCamera and active.camera.CameraType == Enum.CameraType.Scriptable then
		active.camera.CameraType = active.cameraType
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then active.camera.CameraSubject = humanoid end
	end
end

function Cinematics.setReducedMotion(enabled)
	reducedMotion = enabled == true
	if reducedMotion then stop() end
end

local function prepareOverlay(level)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CourierCourseIntro"
	gui.DisplayOrder = 30
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local badge = Instance.new("TextLabel")
	badge.BackgroundColor3 = Color3.fromHex("262052")
	badge.BackgroundTransparency = 0.08
	badge.AnchorPoint = Vector2.new(0.5,1)
	badge.Position = UDim2.new(0.5,0,1,-56)
	badge.Size = UDim2.new(0.9,0,0,46)
	badge.TextColor3 = Color3.fromHex("fff7ff")
	badge.Font = Enum.Font.FredokaOne
	badge.TextScaled = true
	badge.Text = level.name
	badge.Parent = gui
	local titleLimit = Instance.new("UITextSizeConstraint",badge)
	titleLimit.MaxTextSize = 24
	Instance.new("UICorner",badge).CornerRadius = UDim.new(0,14)

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(0.5,1)
	skip.Position = UDim2.new(0.5,0,1,-6)
	skip.Size = UDim2.fromOffset(170,44)
	skip.BackgroundColor3 = Color3.fromHex("ffdb6d")
	skip.TextColor3 = Color3.fromHex("262052")
	skip.Font = Enum.Font.FredokaOne
	skip.TextSize = 16
	skip.Text = "Skip intro"
	skip.Parent = gui
	Instance.new("UICorner",skip).CornerRadius = UDim.new(0,12)
	skip.Activated:Connect(stop)

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

function Cinematics.update(state)
	local eligible = state.racing and (state.stage == "Preparation" or state.stage == "Countdown")
	if not eligible then
		attempted = nil
		stop()
		return
	end
	if reducedMotion or shot or attempted == state.level then return end
	local level = Levels[state.level]
	local model = level and workspace:FindFirstChild(level.name)
	local camera = workspace.CurrentCamera
	if not model or not camera or camera.CameraType == Enum.CameraType.Scriptable then return end
	local start = model:GetAttribute("CinematicStart")
	local finish = model:GetAttribute("CinematicEnd")
	local focus = model:GetAttribute("CinematicFocus")
	if typeof(start) ~= "Vector3" or typeof(finish) ~= "Vector3" or typeof(focus) ~= "Vector3" then return end
	local fullDuration = state.stage == "Preparation" and 2.15 or 1.35
	local duration = if state.stage == "Countdown" and state.deadline
		then math.min(fullDuration,state.deadline-workspace:GetServerTimeNow()-0.45)
		else fullDuration
	if duration < 0.55 then return end
	attempted = state.level

	local active = {camera=camera,cameraType=camera.CameraType,gui=prepareOverlay(level)}
	shot = active
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(start,focus)
	ContextActionService:BindAction(actionName, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then stop() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonY)

	local elapsed = 0
	active.connection = RunService.RenderStepped:Connect(function(delta)
		elapsed += delta
		if elapsed >= duration or workspace.CurrentCamera ~= camera or not model.Parent then
			stop()
			return
		end
		local t = elapsed/duration
		camera.CFrame = CFrame.lookAt(start:Lerp(finish,t*t*(3-2*t)),focus)
	end)
end

return Cinematics
