local Config = require(script.Parent.Config)
local EggModel = {}

local function piece(model, name, size, cf, color, ball)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if ball then p.Shape = Enum.PartType.Ball end
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.Parent = model
	return p
end

function EggModel.build(id, width, anchored)
	local skin = Config.bySkin[id] or Config.bySkin.Classic
	local color = Color3.fromRGB(table.unpack(skin[4]))
	local accent = Color3.fromRGB(table.unpack(skin[5]))
	local model = Instance.new("Model")
	model.Name = "CourierEgg"
	local base = piece(model, "Shell", Vector3.new(1, 1.26, 1) * width, CFrame.new(0, -0.09 * width, 0), color, true)
	model.PrimaryPart = base
	piece(model, "Crown", Vector3.new(0.79, 0.96, 0.79) * width, CFrame.new(0, 0.27 * width, 0), color, true)
	if id ~= "Classic" then
		for i = 1, 6 do
			local angle = i * math.pi / 3
			local cf = CFrame.Angles(0, angle, 0) * CFrame.new(0, (i % 2 - 0.5) * 0.32 * width, -0.48 * width)
			piece(model, "Mark", Vector3.new(0.19, 0.22, 0.075) * width, cf, accent, true)
		end
	end
	local points = {{-0.16, 0.36}, {-0.01, 0.17}, {-0.11, 0.03}, {0.1, -0.12}, {0.02, -0.31}}
	for side = 1, 4 do
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local origin = Vector3.new(a[1], a[2], -0.494) * width
			local target = Vector3.new(b[1], b[2], -0.494) * width
			local cf = CFrame.Angles(0, side * math.pi / 2, 0) * CFrame.lookAt((origin + target) / 2, target)
			local crack = piece(model, i < 3 and "Crack1" or "Crack2", Vector3.new(0.036, 0.048, (target-origin).Magnitude / width) * width, cf, Color3.fromRGB(55, 38, 61))
			crack.Transparency = 1
		end
	end
	for _, p in model:GetChildren() do
		p.Anchored = anchored
		if p ~= base and not anchored then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = base
			weld.Part1 = p
			weld.Parent = p
		end
	end
	model:SetAttribute("Skin", id)
	return model
end

function EggModel.condition(model, hp)
	for _, p in model:GetChildren() do
		if p.Name == "Crack1" then p.Transparency = hp < 3 and 0 or 1 end
		if p.Name == "Crack2" then p.Transparency = hp < 2 and 0 or 1 end
	end
end
return EggModel
