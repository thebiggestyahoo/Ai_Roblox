local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local EggModel = require(Shared.EggModel)
local Trophy = require(Shared.TrophyModel)
local Eggs = {}
local activePoses = setmetatable({}, {__mode = "k"})

local function releasePose(egg)
	local release = activePoses[egg]
	if release then
		activePoses[egg] = nil
		release()
	end
end

local trailColors = {
	Lightning={"5deaff","fff9d7"}, Rainbow={"fc67ff","6beeff"}, VIP={"ffdc53","fff9d7"},
	Expedition={"feac62","74e6b2"}, Aurora={"78f8ef","cf99ff"},
}
local accessoryColors = {
	["Sun Pin"]="ffd35f", ["Trail Ribbon"]="ff9bc4", ["Jade Compass"]="73e7bb",
	["Star Pin"]="89dfff", ["Cloud Patch"]="efe1ff", ["Crown Patch"]="ffb56f",
}
local victoryColors = {
	["Carton Confetti"]={"ff81b2","8cf0ff"}, ["Relic Spark"]={"87ffd5","ffdd78"},
	["Shooting Star"]={"bba9ff","9df1ff"}, ["Aurora Burst"]={"86f4e4","e8a2ff"},
	["Crown Parade"]={"ffcd65","ff8768"}, ["Celestial Finale"]={"b9adff","fff5ba"},
}

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

local function poseArms(character, humanoid, torso, egg, offset)
	local shell = egg.PrimaryPart
	local poseObjects, shoulders = {}, {}
	local r15 = humanoid.RigType == Enum.HumanoidRigType.R15
	for side, direction in {Left=-1, Right=1} do
		local arm = character:FindFirstChild(r15 and (side .. "UpperArm") or (side .. " Arm"))
		if not arm then continue end
		local target = Vector3.new(direction*shell.Size.X*0.38, -shell.Size.Y*0.36, shell.Size.Z*0.12)
		if r15 then
			local hand = character:FindFirstChild(side .. "Hand")
			if not hand then continue end
			local grip = Instance.new("Attachment")
			grip.Name = side .. "ShellGrip"
			grip.Position = target
			grip.Parent = shell

			local elbow = Instance.new("Attachment")
			elbow.Name = side .. "CarryElbow"
			elbow.Position = Vector3.new(direction*(torso.Size.X*0.6+arm.Size.X*0.5), -torso.Size.Y*0.38, -torso.Size.Z*0.42)
			elbow.Parent = torso

			local carry = Instance.new("IKControl")
			carry.Name = side .. "EggCarry"
			carry.Type = Enum.IKControlType.Position
			carry.ChainRoot = arm
			carry.EndEffector = hand
			carry.EndEffectorOffset = CFrame.new(0,-hand.Size.Y*0.36,0)
			carry.Target = grip
			carry.Pole = elbow
			carry.SmoothTime = 0.04
			carry.Priority = 10
			carry.Parent = humanoid
			table.insert(poseObjects, carry)
			table.insert(poseObjects, elbow)
		else
			local shoulder = torso:FindFirstChild(side .. " Shoulder")
			if not shoulder or not shoulder:IsA("Motor6D") or not shoulder.Enabled then continue end
			local wrist = offset:PointToWorldSpace(target)
			local up = (shoulder.C0.Position-wrist).Unit
			local back = Vector3.xAxis:Cross(up).Unit
			local right = up:Cross(back)
			local brace = Instance.new("Weld")
			brace.Name = side .. "EggCarry"
			brace.Part0, brace.Part1 = torso, arm
			brace.C0 = CFrame.fromMatrix(wrist+up*arm.Size.Y*0.48,right,up,back)
			shoulder.Enabled = false
			brace.Parent = shell
			table.insert(shoulders,shoulder)
			table.insert(poseObjects,brace)
		end
	end
	activePoses[egg] = function()
		for _, object in poseObjects do object:Destroy() end
		for _, shoulder in shoulders do
			if shoulder.Parent then shoulder.Enabled = true end
		end
	end
	egg.Destroying:Once(function() releasePose(egg) end)
end

local function decorateShell(shell, accessory)
	local color = accessoryColors[accessory or ""]
	if not color then return end
	for index=0,4 do
		local angle = index*math.pi*0.4
		local pin = Instance.new("Part")
		pin.Name = "Equipped shell pin"
		pin.Shape = Enum.PartType.Ball
		pin.Material = Enum.Material.SmoothPlastic
		pin.Color = if index%2 == 0 then Color3.fromHex(color) else Color3.fromHex("fff7dc")
		pin.Size = Vector3.new(0.15,0.15,0.10)*shell.Size.X
		pin.CFrame = shell.CFrame*CFrame.new(
			(shell.Size.X*0.10)*math.cos(angle),
			(shell.Size.Y*0.21)+(shell.Size.X*0.10)*math.sin(angle),
			-shell.Size.Z*0.455
		)
		pin.CanCollide, pin.CanTouch, pin.CanQuery = false,false,false
		pin.Massless = true
		local weld = Instance.new("WeldConstraint",pin)
		weld.Part0, weld.Part1 = shell,pin
		pin.Parent = shell
	end
end

function Eggs.celebrate(player, data)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local colors = victoryColors[data.victory or ""] or {"ffcc60","fff2bd"}
	local trophy = Trophy.build()
	trophy:PivotTo(CFrame.new(root.Position+Vector3.new(0,3,0))*CFrame.Angles(0,math.pi,0))
	trophy.Parent = workspace
	Debris:AddItem(trophy,3)
	local confetti = Instance.new("ParticleEmitter")
	confetti.Name = "Victory color burst"
	confetti.Color = ColorSequence.new(Color3.fromHex(colors[1]),Color3.fromHex(colors[2]))
	confetti.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.24),NumberSequenceKeypoint.new(1,0)})
	confetti.Lifetime = NumberRange.new(0.9,1.7)
	confetti.Speed = NumberRange.new(4,11)
	confetti.SpreadAngle = Vector2.new(110,110)
	confetti.Acceleration = Vector3.new(0,-12,0)
	confetti.Rate = 0
	confetti.LightEmission = 0.55
	confetti.Parent = trophy.PrimaryPart
	confetti:Emit(data.victory and 52 or 28)
end

function Eggs.attach(player, data, hp)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local existing = character:FindFirstChild("CourierEgg")
	if existing then
		releasePose(existing)
		existing:Destroy()
	end
	if hp <= 0 then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not humanoid or not torso then return end
	local egg = EggModel.build(data.skin, math.clamp(torso.Size.X*0.72,0.65,2.6), false)
	local shell = egg.PrimaryPart
	local offset = CFrame.new(0,-torso.Size.Y*0.22,-(torso.Size.Z+shell.Size.Z)*0.5-0.12)
	egg:PivotTo(torso.CFrame * offset)
	egg.Parent = character
	local motor = Instance.new("Motor6D")
	motor.Name = "EggMotor"
	motor.Part0 = torso
	motor.Part1 = egg.PrimaryPart
	motor.C0 = offset
	motor.Parent = egg.PrimaryPart
	poseArms(character,humanoid,torso,egg,offset)
	decorateShell(shell,data.accessory)
	EggModel.condition(egg,hp)
	local previous = head:FindFirstChild("CourierTitle")
	if previous then previous:Destroy() end
	local nameplate = Instance.new("BillboardGui",head)
	nameplate.Name = "CourierTitle"
	nameplate.Size = UDim2.fromScale(6,0.8)
	nameplate.StudsOffset = Vector3.new(0,head.Size.Y+0.85,0)
	nameplate.MaxDistance = 36
	local title = Instance.new("TextLabel",nameplate)
	title.Size = UDim2.fromScale(1,1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextStrokeTransparency = 0.5
	title.TextColor3 = Color3.fromHex("fff4ab")
	local config = require(Shared.Config)
	title.Text = (data.skins.VIP and "VIP  •  " or "") .. (data.customTitle or config.titles[data.title] or config.titles[1])
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
			local colors = trailColors[data.trail] or trailColors.Lightning
			trail.Color = ColorSequence.new(Color3.fromHex(colors[1]),Color3.fromHex(colors[2]))
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
		releasePose(egg)
		egg:Destroy()
	end
end
return Eggs
