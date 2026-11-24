local O = {}
local palette = {Color3.fromHex("ff536c"), Color3.fromHex("ffb632"), Color3.fromHex("965bff")}
local function make(parent, name, size, cf, color, solid, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.CanCollide = solid
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
O.part = make

local definitions = {
	sweep = {size = Vector3.new(22, 0.85, 1.4), y = 1.25, speed = 1.65, damage = 1},
	ball = {size = Vector3.new(6, 6, 6), y = 3, range = 9, speed = 1.8, damage = 1, shape = Enum.PartType.Ball},
	foam = {size = Vector3.new(10, 4, 3), y = 2, range = 10, speed = 1.85, damage = 1},
	pendulum = {size = Vector3.new(4.8, 4.8, 4.8), y = 2.7, range = 9.5, speed = 1.65, damage = 1, shape = Enum.PartType.Ball},
	moving = {size = Vector3.new(15, 1.4, 10), range = 3.6, speed = 1.55, solid = true},
	tilt = {size = Vector3.new(16, 1.4, 10), range = 0.25, speed = 1.7, solid = true},
	roller = {size = Vector3.new(10, 2.8, 2.8), y = 1.4, range = 5.8, speed = 1.9, damage = 1, shape = Enum.PartType.Cylinder},
	beam = {size = Vector3.new(8, 1.4, 10), solid = true},
	vanish = {size = Vector3.new(15, 1.4, 10), solid = true, period = 4, open = 1},
	collapse = {size = Vector3.new(15, 1.4, 10), solid = true, period = 5, open = 1.4},
	conveyor = {size = Vector3.new(20, 1.4, 10), solid = true, speed = 7},
	ice = {size = Vector3.new(20, 1.4, 10), solid = true},
	door = {size = Vector3.new(20, 6, 1.5), y = 3, solid = true, range = 6, speed = 1.4},
	launch = {size = Vector3.new(9, 0.5, 8), y = 0.25, solid = true, speed = 37},
	snowball = {size = Vector3.new(5, 5, 5), y = 2.5, range = 10, speed = 1.5, damage = 1, shape = Enum.PartType.Ball},
	gravity = {size = Vector3.new(17, 12, 12), y = 6, speed = 105},
}
O.definitions = definitions

function O.add(course, kind, origin, phase, overrides)
	local d = table.clone(assert(definitions[kind], kind))
	for key, value in overrides or {} do d[key] = value end
	local cf = CFrame.new(origin + Vector3.new(0, d.y or -0.7, 0))
	local p = make(course.model, kind, d.size, cf, palette[math.floor(phase) % 3 + 1], d.solid == true, d.shape)
	local item = {kind = kind, part = p, base = cf, phase = phase, d = d}
	if kind == "ice" then p.CustomPhysicalProperties = PhysicalProperties.new(1, 0.015, 0) end
	if kind == "conveyor" then p.AssemblyLinearVelocity = Vector3.new(0, 0, d.speed) end
	if kind == "gravity" then p.Transparency = 0.8 end
	if kind == "pendulum" then
		item.pivot = origin + Vector3.new(0, 16, 0)
		item.arm = make(course.model, "Foam swing arm", Vector3.one, cf, Color3.fromHex("ffe6a2"), false)
	end
	table.insert(course.obstacles, item)
	return item
end

function O.update(course, age, racers, damage)
	if course.gravityApplied then
		for root in course.gravityApplied do
			local force = root:FindFirstChild("CourseLift")
			if force then force.Force = Vector3.zero end
		end
	end
	for _, o in course.obstacles do
		local p, d, kind = o.part, o.d, o.kind
		local old = p.CFrame
		local t = age * (d.speed or 1) + o.phase
		local s = math.sin(t)
		if kind == "sweep" then p.CFrame = o.base * CFrame.Angles(0, t, 0)
		elseif kind == "ball" then p.CFrame = o.base + Vector3.new(s * d.range, math.abs(math.sin(t * 1.6)) * 5.6, 0)
		elseif kind == "foam" or kind == "moving" then p.CFrame = o.base + Vector3.new(s * d.range, 0, 0)
		elseif kind == "tilt" then p.CFrame = o.base * CFrame.Angles(0, 0, s * d.range)
		elseif kind == "roller" then p.CFrame = (o.base + Vector3.new(s * d.range, 0, 0)) * CFrame.Angles(t, 0, 0)
		elseif kind == "snowball" then p.CFrame = o.base + Vector3.new(0, 0, s * d.range)
		elseif kind == "pendulum" then
			local bob = o.base.Position + Vector3.new(s * d.range, math.abs(s)^2 * 4, 0)
			p.Position = bob
			o.arm.Size = Vector3.new(0.7, 0.7, (bob - o.pivot).Magnitude)
			o.arm.CFrame = CFrame.lookAt((bob + o.pivot) / 2, bob)
		elseif kind == "vanish" or kind == "collapse" then
			local cycle = (age + o.phase) % d.period
			p.CanCollide = cycle < d.period - d.open
			p.Transparency = if not p.CanCollide then 0.85 elseif cycle > d.period - d.open - 0.6 then 0.35 else 0
		elseif kind == "door" then p.CFrame = o.base + Vector3.new(0, (s + 1) * d.range / 2, 0)
		end
		if not d.damage and old == p.CFrame and kind ~= "launch" and kind ~= "gravity" then continue end
		for player, racer in racers do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or root.Anchored or racer.finished or racer.recovering then continue end
			local probe = if kind == "sweep" or kind == "roller" then root.Position-Vector3.yAxis else root.Position
			local localPos = p.CFrame:PointToObjectSpace(probe)
			local half = p.Size * 0.5
			if d.damage then
				if math.abs(localPos.X) < half.X + 0.85 and math.abs(localPos.Y) < half.Y + 1.75 and math.abs(localPos.Z) < half.Z + 0.85 then
					damage(player, racer, d.damage, p)
				end
			elseif kind == "moving" or kind == "tilt" then
				local previous = old:PointToObjectSpace(root.Position)
				if math.abs(previous.X) <= half.X and math.abs(previous.Z) <= half.Z and previous.Y > half.Y + 1.4 and previous.Y < half.Y + 3.5 and root.AssemblyLinearVelocity.Y < 5 then
					local carried = p.CFrame:PointToWorldSpace(previous)
					root.CFrame += carried-root.Position
				end
			elseif math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z then
				if kind == "launch" and localPos.Y > 0 and localPos.Y < 3.4 and root.AssemblyLinearVelocity.Y <= 1 then
					root.AssemblyLinearVelocity += Vector3.new(0, d.speed, 0)
				elseif kind == "gravity" and math.abs(localPos.Y) < half.Y then
					local force = root:FindFirstChild("CourseLift")
					if not force then
						local attachment = Instance.new("Attachment", root)
						attachment.Name = "CourseLiftAttachment"
						force = Instance.new("VectorForce", root)
						force.Name = "CourseLift"
						force.Attachment0 = attachment
						force.RelativeTo = Enum.ActuatorRelativeTo.World
						force.ApplyAtCenterOfMass = true
					end
					force.Force = Vector3.yAxis * d.speed * root.AssemblyMass
					course.gravityApplied = course.gravityApplied or {}
					course.gravityApplied[root] = true
				end
			end
		end
	end
end

function O.cleanup(course)
	for root in course.gravityApplied or {} do
		for _, name in {"CourseLift", "CourseLiftAttachment"} do
			local item = root:FindFirstChild(name)
			if item then item:Destroy() end
		end
	end
end
return O
