local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local EggModel = require(Shared.EggModel)
local Eggs = {}

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
