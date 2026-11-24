local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local EggModel = require(Shared.EggModel)
local Eggs = {}

local championRed = Color3.fromHex("ff334b")

function Eggs.aura(player, data)
	local character = player.Character
	if not character then return end
	local enabled = (data.wins or 0) > 0 and player:GetAttribute("WinnerAura") ~= false
	local highlight = character:FindFirstChild("ChampionOutline")
	if enabled and not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ChampionOutline"
		highlight.Adornee = character
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.OutlineColor = championRed
		highlight.OutlineTransparency = 0.04
		highlight.FillColor = championRed
		highlight.FillTransparency = 0.89
		highlight.Parent = character
	elseif not enabled and highlight then
		highlight:Destroy()
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local cosmetic = root:FindFirstChild("CourierTrail")
	if cosmetic then cosmetic.Enabled = not enabled end
	if not enabled then
		for _, name in {"ChampionTrail", "ChampionTrailLeft", "ChampionTrailRight"} do
			local object = root:FindFirstChild(name)
			if object then object:Destroy() end
		end
		return
	end
	if root:FindFirstChild("ChampionTrail") then return end

	local left = Instance.new("Attachment")
	left.Name = "ChampionTrailLeft"
	left.Position = Vector3.new(-0.78,-0.14,0.54)
	left.Parent = root
	local right = Instance.new("Attachment")
	right.Name = "ChampionTrailRight"
	right.Position = Vector3.new(0.78,-0.14,0.54)
	right.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "ChampionTrail"
	trail.Attachment0, trail.Attachment1 = left, right
	trail.Color = ColorSequence.new(championRed,Color3.fromHex("b8192d"))
	trail.Transparency = NumberSequence.new(0.2,1)
	trail.LightEmission = 0.55
	trail.Lifetime = 0.34
	trail.MinLength = 0.26
	trail.FaceCamera = true
	trail.Parent = root
end

local function poseArms(character, egg)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("UpperTorso")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 or not torso then return end

	local shell = egg.PrimaryPart
	local poseObjects = {}
	for side, direction in {Left=-1, Right=1} do
		local arm = character:FindFirstChild(side .. "UpperArm")
		local hand = character:FindFirstChild(side .. "Hand")
		if not arm or not hand then continue end

		local grip = Instance.new("Attachment")
		grip.Name = side .. "ShellGrip"
		grip.Position = Vector3.new(
			direction * (shell.Size.X * 0.32 + hand.Size.X * 0.42),
			-shell.Size.Y * 0.38,
			-shell.Size.Z * 0.1
		)
		grip.Parent = shell

		local elbow = Instance.new("Attachment")
		elbow.Name = side .. "CarryElbow"
		elbow.Position = Vector3.new(
			direction * (torso.Size.X * 0.72 + arm.Size.X * 0.7),
			torso.Size.Y * 0.2,
			-torso.Size.Z * 0.72
		)
		elbow.Parent = torso

		local carry = Instance.new("IKControl")
		carry.Name = side .. "EggCarry"
		carry.Type = Enum.IKControlType.Position
		carry.ChainRoot = arm
		carry.EndEffector = hand
		carry.Target = grip
		carry.Pole = elbow
		carry.SmoothTime = 0.055
		carry.Priority = 10
		carry.Parent = humanoid
		table.insert(poseObjects, carry)
		table.insert(poseObjects, elbow)
	end
	-- The targets go with the shell. Detach controls from the avatar when it breaks or is swapped.
	egg.Destroying:Once(function()
		for _, object in poseObjects do object:Destroy() end
	end)
end

function Eggs.attach(player, data, hp)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local existing = character:FindFirstChild("CourierEgg")
	if existing then existing:Destroy() end
	if hp <= 0 then return end
	local egg = EggModel.build(data.skin, head.Size.X * 1.5, false)
	local offset = CFrame.new(0,head.Size.Y/2+egg.PrimaryPart.Size.Y/2+0.34,0)
	egg:PivotTo(head.CFrame * offset)
	egg.Parent = character
	local motor = Instance.new("Motor6D")
	motor.Name = "EggMotor"
	motor.Part0 = head
	motor.Part1 = egg.PrimaryPart
	motor.C0 = offset
	motor.Parent = egg.PrimaryPart
	poseArms(character,egg)
	EggModel.condition(egg,hp)
	local previous = head:FindFirstChild("CourierTitle")
	if previous then previous:Destroy() end
	local nameplate = Instance.new("BillboardGui",head)
	nameplate.Name = "CourierTitle"
	nameplate.Size = UDim2.fromScale(6,0.8)
	nameplate.StudsOffset = Vector3.new(0,head.Size.Y+3,0)
	nameplate.MaxDistance = 36
	local title = Instance.new("TextLabel",nameplate)
	title.Size = UDim2.fromScale(1,1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextStrokeTransparency = 0.5
	title.TextColor3 = Color3.fromHex("fff4ab")
	local config = require(Shared.Config)
	title.Text = (data.skins.VIP and "VIP  •  " or "") .. (config.titles[data.title] or config.titles[1])
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		for _, name in {"CourierTrail","CourierTrailLeft","CourierTrailRight"} do
			local item = root:FindFirstChild(name)
			if item then item:Destroy() end
		end
		if data.trail ~= "" and data.trails[data.trail] then
			local left = Instance.new("Attachment",root)
			left.Name = "CourierTrailLeft"
			left.Position = Vector3.new(-0.65,0,0.5)
			local right = Instance.new("Attachment",root)
			right.Name = "CourierTrailRight"
			right.Position = Vector3.new(0.65,0,0.5)
			local trail = Instance.new("Trail",root)
			trail.Name = "CourierTrail"
			trail.Attachment0, trail.Attachment1 = left, right
			trail.Lifetime = 0.28
			trail.MinLength = 0.2
			trail.FaceCamera = true
			local color = if data.trail == "Rainbow" then Color3.fromHex("fc67ff") elseif data.trail == "VIP" then Color3.fromHex("ffdc53") else Color3.fromHex("5deaff")
			trail.Color = ColorSequence.new(color,Color3.fromHex("fff9d7"))
			trail.Transparency = NumberSequence.new(0.15,1)
		end
	end
	Eggs.aura(player,data)
end

function Eggs.condition(player, hp)
	local egg = player.Character and player.Character:FindFirstChild("CourierEgg")
	if not egg then return end
	EggModel.condition(egg,hp)
	if hp == 0 then
		for i = 1,8 do
			local fragment = Instance.new("WedgePart")
			fragment.Name = "Shell chip"
			fragment.Size = Vector3.new(0.32,0.28,0.42)
			fragment.Color = egg.PrimaryPart.Color
			fragment.CFrame = egg:GetPivot() * CFrame.Angles(i, i*0.4, 0)
			fragment.CanCollide = false
			fragment.CanTouch = false
			fragment.CanQuery = false
			fragment.Parent = workspace
			fragment.AssemblyLinearVelocity = Vector3.new(math.cos(i)*11,12+i,math.sin(i)*11)
			fragment.AssemblyAngularVelocity = Vector3.new(i,3,1)
			Debris:AddItem(fragment,0.7)
		end
		egg:Destroy()
	end
end
return Eggs
