local O = {}
local palette = {Color3.fromHex("ff536c"), Color3.fromHex("ffb632"), Color3.fromHex("965bff")}
local tileSafe = Color3.fromHex("9beecb")
local tileWarning = Color3.fromHex("ff9160")
local tileReturning = Color3.fromHex("bdf7e7")
local pulseSafe = Color3.fromHex("2a3c50")
local pulseWarning = Color3.fromHex("ffc34c")
local pulseLive = Color3.fromHex("ff4f54")
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
	pulse = {size = Vector3.new(14, 0.22, 5), y = 0.13, period = 3.8, open = 1.25, damage = 1},
	wind = {size = Vector3.new(10, 10, 14), y = 5, speed = 22},
	slide = {size = Vector3.new(10, 10, 14), y = 5, speed = 25},
	gate = {size = Vector3.new(9, 5, 1.2), y = 2.5, solid = true, period = 6.4, open = 3.5, range = 6.2},
	spin = {size = Vector3.new(1.4, 12, 12), solid = true, speed = 0.7, shape = Enum.PartType.Cylinder},
	sentry = {size = Vector3.new(7, 5.8, 4.8), y = 2.9, range = 7.7, period = 8.6, open = 3.7, damage = 1},
	boulder = {size = Vector3.new(8.8, 8.8, 8.8), y = 4.4, range = 18, period = 6.15, travel = 3.2, damage = 1, shape = Enum.PartType.Ball},
}
O.definitions = definitions

local function hitsRacer(localPos, half, shape, bodyHalf)
	if shape == Enum.PartType.Ball then
		local x = math.max(0,math.abs(localPos.X)-0.55)
		local y = math.max(0,math.abs(localPos.Y)-bodyHalf)
		local z = math.max(0,math.abs(localPos.Z)-0.55)
		return x*x+y*y+z*z < half.X*half.X
	end
	return math.abs(localPos.X) < half.X+0.55
		and math.abs(localPos.Y) < half.Y+bodyHalf
		and math.abs(localPos.Z) < half.Z+0.55
end

local function buildRideable(course, item)
	local platform, base, d = item.part, item.base, item.d
	local guide = make(course.model,"Platform guide",Vector3.one,base,platform.Color,false)
	guide.Transparency = 1
	guide.CanQuery = false
	guide.CastShadow = false

	local slides = item.kind == "moving"
	local axis = if slides then d.axis or Vector3.xAxis else Vector3.zAxis
	local perpendicular = if axis == Vector3.yAxis then Vector3.zAxis else Vector3.yAxis
	local mount = CFrame.fromMatrix(Vector3.zero,axis,perpendicular)
	local fixedAttachment = Instance.new("Attachment",guide)
	fixedAttachment.CFrame = mount
	local deckAttachment = Instance.new("Attachment",platform)
	deckAttachment.CFrame = mount

	local actuator = Instance.new(if slides then "PrismaticConstraint" else "HingeConstraint")
	actuator.Name = "Platform drive"
	actuator.Attachment0 = fixedAttachment
	actuator.Attachment1 = deckAttachment
	actuator.ActuatorType = Enum.ActuatorType.Servo
	actuator.LimitsEnabled = true
	local startingPosition = math.sin(item.phase)*d.range
	if slides then
		actuator.LowerLimit = -d.range-0.25
		actuator.UpperLimit = d.range+0.25
		actuator.LinearResponsiveness = 18
		actuator.ServoMaxForce = 240000
		actuator.Speed = d.speed*d.range+0.65
		actuator.TargetPosition = startingPosition
		platform.CFrame = base+axis*startingPosition
	else
		actuator.LowerAngle = -math.deg(d.range)-3
		actuator.UpperAngle = math.deg(d.range)+3
		actuator.AngularResponsiveness = 18
		actuator.ServoMaxTorque = 900000
		actuator.AngularSpeed = d.speed*d.range+0.35
		actuator.TargetAngle = math.deg(startingPosition)
		platform.CFrame = base*CFrame.Angles(0,0,startingPosition)
	end
	actuator.Parent = platform
	platform.CustomPhysicalProperties = PhysicalProperties.new(1,0.9,0,80,100)
	platform.Anchored = false
	item.actuator = actuator
end

local function buildSpin(course, item)
	local platform, base, d = item.part, item.base, item.d
	local guide = make(course.model,"Carousel axle",Vector3.one,base,platform.Color,false)
	guide.Transparency, guide.CanQuery, guide.CastShadow = 1, false, false
	local bearing = Instance.new("Attachment",guide)
	bearing.CFrame = CFrame.fromMatrix(Vector3.zero,Vector3.yAxis,Vector3.zAxis)
	local floorBearing = Instance.new("Attachment",platform)
	-- The cylinder's positive X axis becomes world Y when it stands upright.
	floorBearing.CFrame = CFrame.fromMatrix(Vector3.zero,Vector3.xAxis,Vector3.zAxis)
	platform.CFrame = base*CFrame.Angles(0,0,math.pi/2)
	local motor = Instance.new("HingeConstraint",platform)
	motor.Name = "Carousel motor"
	motor.Attachment0, motor.Attachment1 = bearing, floorBearing
	motor.ActuatorType = Enum.ActuatorType.Motor
	motor.AngularVelocity, motor.MotorMaxTorque = d.speed, 110000
	platform.CustomPhysicalProperties = PhysicalProperties.new(1,0.9,0,80,100)
	platform.Anchored = false
	item.actuator = motor
end

-- A returning floor can catch someone landing on top. Wait a full cycle
-- instead if it would spawn around someone already falling through its space.
local function overlapsFallingRacer(part, racers)
	local half = part.Size * 0.5
	for player, racer in racers do
		if racer.finished or racer.out or racer.recovering then continue end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local position = part.CFrame:PointToObjectSpace(root.Position)
		if math.abs(position.X) > half.X+0.8 or math.abs(position.Z) > half.Z+0.8 then continue end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local standingHeight = humanoid and humanoid.HipHeight+root.Size.Y/2 or 3
		if position.Y > -half.Y-2.8 and position.Y < half.Y+standingHeight-0.15 then
			return true
		end
	end
	return false
end

function O.add(course, kind, origin, phase, overrides)
	local d = table.clone(assert(definitions[kind], kind))
	for key, value in overrides or {} do d[key] = value end
	local cf = CFrame.new(origin + Vector3.new(0, d.y or -0.7, 0))
	local p = make(course.model, kind, d.size, cf, d.color or palette[math.floor(phase) % 3 + 1], d.solid == true, d.shape)
	if not d.solid then p.CanQuery = false end
	local item = {kind = kind, part = p, base = cf, phase = phase, d = d}
	if kind == "moving" or kind == "tilt" then buildRideable(course,item)
	elseif kind == "spin" then buildSpin(course,item) end
	if kind == "ice" then p.CustomPhysicalProperties = PhysicalProperties.new(1, 0.015, 0) end
	if kind == "conveyor" then p.AssemblyLinearVelocity = (d.axis or Vector3.zAxis)*d.speed end
	if kind == "gravity" or kind == "wind" or kind == "slide" then
		p.Transparency, p.CastShadow = 0.91, false
	end
	if kind == "gate" or kind == "sentry" then
		item.signal = make(course.model,"Timing signal",Vector3.new(d.size.X,0.06,1.7),
			CFrame.new(origin + Vector3.new(0,0.06,-2.6)),tileSafe,false)
		item.signal.Material = Enum.Material.Neon
		item.signal.CanQuery = false
	end
	if kind == "pulse" then p.Material = Enum.Material.Neon end
	if kind == "boulder" then
		p.Material = Enum.Material.Slate
		local start = cf.Position + Vector3.zAxis*d.range
		local warning = make(course.model,"Boulder warning",Vector3.new(3,0.08,1.2),
			CFrame.new(start.X,origin.Y+0.05,start.Z),pulseWarning,false)
		warning.Material = Enum.Material.Neon
		warning.CanQuery = false
		item.warning = warning
	end
	if kind == "pendulum" then
		item.pivot = origin + Vector3.new(0, 16, 0)
		item.arm = make(course.model, "Foam swing arm", Vector3.one, cf, Color3.fromHex("ffe6a2"), false)
	end
	table.insert(course.obstacles, item)
	return item
end

function O.activate(course)
	for _, item in course.obstacles do
		if item.actuator and item.part:CanSetNetworkOwnership() then
			-- The deck's contacts and travel stay on the server even with multiple riders.
			item.part:SetNetworkOwner(nil)
		end
	end
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
		local t = age * (d.speed or 1) + o.phase
		local s = math.sin(t)
		if o.actuator then
			if kind == "moving" then o.actuator.TargetPosition = s*d.range
			elseif kind == "tilt" then o.actuator.TargetAngle = math.deg(s*d.range) end
			continue
		end
		local active = true
		if kind == "sweep" then p.CFrame = o.base * CFrame.Angles(0, t, 0)
		elseif kind == "ball" then p.CFrame = o.base + Vector3.new(s * d.range, math.abs(math.sin(t * 1.6)) * (d.bounce or 5.6), 0)
		elseif kind == "foam" then p.CFrame = o.base + (d.axis or Vector3.xAxis) * (s * d.range)
		elseif kind == "roller" then p.CFrame = (o.base + Vector3.new(s * d.range, 0, 0)) * CFrame.Angles(t, 0, 0)
		elseif kind == "snowball" then p.CFrame = o.base + Vector3.new(0, 0, s * d.range)
		elseif kind == "pendulum" then
			local bob = o.base.Position + Vector3.new(s * d.range, math.abs(s)^2 * 4, 0)
			p.Position = bob
			o.arm.Size = Vector3.new(0.7, 0.7, (bob - o.pivot).Magnitude)
			o.arm.CFrame = CFrame.lookAt((bob + o.pivot) / 2, bob)
		elseif kind == "vanish" or kind == "collapse" then
			local cycle = (age + o.phase) % d.period
			local solid = cycle < d.period - d.open
			if solid and not p.CanCollide and age >= (o.blockedUntil or 0) and overlapsFallingRacer(p,racers) then
				o.blockedUntil = age+d.period-cycle
			end
			local blocked = age < (o.blockedUntil or 0)
			local mode
			if cycle >= d.period-0.48 then mode = "returning"
			elseif blocked then mode = "out"
			elseif not solid then mode = "out"
			elseif cycle > d.period-d.open-0.75 then mode = "warning"
			else mode = "solid" end
			if o.mode ~= mode then
				o.mode = mode
				p.CanCollide = mode == "solid" or mode == "warning"
				p.Transparency = if mode == "out" then 0.85 elseif mode == "returning" then 0.58 elseif mode == "warning" then 0.22 else 0
				p.Color = if mode == "warning" then tileWarning elseif mode == "returning" then tileReturning else d.color or tileSafe
			end
		elseif kind == "pulse" then
			local cycle = (age + o.phase) % d.period
			active = cycle >= d.period - d.open
			local mode = if active then "live" elseif cycle >= d.period-d.open-0.95 then "warning" else "safe"
			if o.mode ~= mode then
				o.mode = mode
				p.Color = if mode == "live" then pulseLive elseif mode == "warning" then pulseWarning else d.color or pulseSafe
				p.Transparency = if active then 0 else 0.16
			end
		elseif kind == "boulder" then
			local cycle = (age + o.phase) % d.period
			local traveled = math.min(cycle/d.travel,1)
			active = cycle < d.travel
			local position = active and (1-traveled*2)*d.range or d.range
			p.CFrame = (o.base + Vector3.zAxis*position) * CFrame.Angles(-traveled*8.2,0,0)
			local warning = not active and cycle >= d.period-1.15
			p.Transparency = if active then 0 elseif warning then 0.65 else 1
			o.warning.Transparency = if warning then 0 else 1
		elseif kind == "door" then p.CFrame = o.base + Vector3.new(0, (s + 1) * d.range / 2, 0)
		elseif kind == "gate" or kind == "sentry" then
			local cycle = (age+o.phase)%d.period
			local amount = if cycle < d.open then math.min(cycle/0.65,(d.open-cycle)/0.65,1) else 0
			if kind == "gate" then
				p.CFrame = o.base + Vector3.yAxis*amount*d.range
				-- The moving door is a readable wait, never a crushing hazard.
				p.CanCollide = amount < 0.82 and not overlapsFallingRacer(p,racers)
			else
				active = cycle < d.open
				local walk = math.clamp(cycle/d.open,0,1)
				p.CFrame = o.base + Vector3.xAxis*d.range*(1-2*walk)
				p.Transparency = if active then 0.1 elseif cycle > d.period-1.1 then 0.72 else 1
				for _, detail in ipairs(o.details or {}) do
					detail.part.CFrame = p.CFrame*detail.offset
					detail.part.Transparency = p.Transparency
				end
			end
			if kind == "gate" then
				o.signal.Color = if amount > 0.81 then tileSafe elseif cycle > d.period-1 or cycle < d.open then pulseWarning else pulseLive
			else
				o.signal.Color = if active then pulseLive elseif cycle > d.period-1.1 then pulseWarning else tileSafe
			end
		end
		if not active then continue end
		local forceZone = kind == "gravity" or kind == "wind" or kind == "slide"
		if not d.damage and kind ~= "launch" and not forceZone then continue end
		for player, racer in racers do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or root.Anchored or racer.finished or racer.out or racer.recovering then continue end
			local localPos = p.CFrame:PointToObjectSpace(root.Position)
			local half = p.Size * 0.5
			if d.damage then
				local hit
				if kind == "pulse" or kind == "sweep" or kind == "roller" then
					local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
					local standHeight = root.Size.Y*0.5 + (humanoid and humanoid.HipHeight or 0)
					if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
						local leg = player.Character:FindFirstChild("Left Leg")
						standHeight += leg and leg.Size.Y or 2
					end
					local feet = root.Position.Y-standHeight
					hit = feet < p.Position.Y + (kind == "roller" and half.Z or half.Y) + 0.18
						and math.abs(localPos.X) < half.X + 0.5
						and math.abs(kind == "roller" and (root.Position.Z-p.Position.Z) or localPos.Z) < half.Z + 0.46
				else
					hit = hitsRacer(localPos,half,d.shape,math.max(0.9,root.Size.Y*0.67))
				end
				if hit then damage(player, racer, d.damage, p) end
			elseif math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z then
				if kind == "launch" and localPos.Y > 0 and localPos.Y < 5 and root.AssemblyLinearVelocity.Y <= 1 then
					root.AssemblyLinearVelocity += Vector3.new(0, d.speed, 0)
				elseif forceZone and math.abs(localPos.Y) < half.Y then
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
					local axis = if kind == "gravity" then Vector3.yAxis elseif kind == "slide" then Vector3.zAxis else d.axis or Vector3.xAxis
					force.Force += axis * d.speed * root.AssemblyMass
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
