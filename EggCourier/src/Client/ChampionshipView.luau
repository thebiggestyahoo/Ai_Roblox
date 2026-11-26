local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local EggModel = require(Shared.EggModel)
local TrophyModel = require(Shared.TrophyModel)

local View = {}
local stageGold = Color3.fromHex("ffcf60")
local titleInk = Color3.fromHex("241843")
local bannerColors = {
	["Expedition Dawn"]="bd7a5f", ["Hidden Grotto"]="387b79", ["Magma Light"]="964b7a",
	Moonrise="525399", ["Royal Violet"]="7e54ab", ["Star Trail"]="35548f",
}

local function podium(parent)
	local riser = Instance.new("Part")
	riser.Name = "Winner's pedestal"
	riser.Anchored = true
	riser.CanCollide = false
	riser.Size = Vector3.new(0.38,6,6)
	riser.Shape = Enum.PartType.Cylinder
	riser.CFrame = CFrame.new(0,-0.29,0)*CFrame.Angles(0,0,math.pi/2)
	riser.Color = stageGold
	riser.Parent = parent
end

local function previewAvatar(userId, scene)
	local winner = userId and Players:GetPlayerByUserId(userId)
	local character = winner and winner.Character
	if not character then return false end
	local original = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = original
	if not copy then return false end
	for _, object in copy:GetDescendants() do
		if object:IsA("LuaSourceContainer") or object:IsA("BillboardGui") or object:IsA("ParticleEmitter")
			or object:IsA("Trail") or object:IsA("Highlight") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
		elseif object:IsA("Humanoid") then
			object.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root then
		copy:Destroy()
		return false
	end
	copy.PrimaryPart = root
	copy:PivotTo(CFrame.new(-0.72,2.85,0.17))
	copy.Parent = scene
	return true
end

function View.render(parent, championship)
	local card = Instance.new("Frame")
	card.Name = "Champion presentation"
	card.Size = UDim2.new(1,-8,0,210)
	card.BackgroundColor3 = titleInk
	card.BorderSizePixel = 0
	card.Parent = parent
	Instance.new("UICorner",card).CornerRadius = UDim.new(0,14)

	local viewport = Instance.new("ViewportFrame")
	viewport.BorderSizePixel = 0
	viewport.Size = UDim2.new(1,-10,1,-47)
	viewport.Position = UDim2.fromOffset(5,5)
	viewport.BackgroundColor3 = Color3.fromHex(bannerColors[championship.banner or ""] or "5f468c")
	viewport.Ambient = Color3.fromHex("e3d9ff")
	viewport.LightColor = Color3.fromHex("fff5c6")
	viewport.LightDirection = Vector3.new(-2,-4,-2)
	viewport.Parent = card
	Instance.new("UICorner",viewport).CornerRadius = UDim.new(0,11)

	local world = Instance.new("WorldModel",viewport)
	podium(world)
	local camera = Instance.new("Camera",viewport)
	camera.FieldOfView = 38
	camera.CFrame = CFrame.lookAt(Vector3.new(3.8,4,-10.4),Vector3.new(0,2.28,0))
	viewport.CurrentCamera = camera

	local trophy = TrophyModel.build()
	trophy:PivotTo(CFrame.new(1.4,0.05,-0.48)*CFrame.Angles(0,-0.25,0))
	trophy.Parent = world
	local avatarFound = previewAvatar(championship.userId,world)
	local egg = EggModel.build(championship.skin or "Classic",avatarFound and 0.86 or 1.72,true)
	egg:PivotTo(CFrame.new(avatarFound and 1.42 or -0.65,avatarFound and 2.24 or 1.45,-0.2)*CFrame.Angles(0,-0.27,-0.13))
	egg.Parent = world

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0,8,1,-40)
	label.Size = UDim2.new(1,-16,0,36)
	label.TextColor3 = stageGold
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 15
	label.TextWrapped = true
	local earned = ("%s  •  +%d Egg Coins  •  +%d XP"):format(championship.name or "Champion",
		championship.coins or 0,championship.xp or 0)
	if championship.championships then
		earned ..= ("\n%d lifetime championships"):format(championship.championships)
	end
	label.Text = earned
	label.Parent = card
	return card
end

return View
