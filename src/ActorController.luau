local Players = game:GetService("Players")
local Actor = {}
Actor.__index = Actor
local rad = math.rad
local id = CFrame.identity

local tint = {
	Noah=Color3.fromRGB(205,158,115), Lucas=Color3.fromRGB(172,109,76),
	Keeper=Color3.fromRGB(201,168,132),
}
function Actor.spawn(role, names, parent)
	local rig
	for _,name in names do
		local ok, result = pcall(function()
			local userId = Players:GetUserIdFromNameAsync(name)
			local desc = Players:GetHumanoidDescriptionFromUserIdAsync(userId)
			assert(desc, "Missing Roblox avatar description")
			-- Retain the catalog outfit; use familiar blocky proportions.
			desc.BodyTypeScale, desc.ProportionScale, desc.HeightScale = 0, 0, 1
			desc.WidthScale, desc.DepthScale, desc.HeadScale = 1, 1, 1
			desc.Torso, desc.LeftArm, desc.RightArm, desc.LeftLeg, desc.RightLeg = 0,0,0,0,0
			if tint[role] then
				local skin=tint[role]
				desc.HeadColor,desc.LeftArmColor,desc.RightArmColor=skin,skin,skin
			end
			if role:sub(1,5)=="Young" then
				desc.HeightScale,desc.WidthScale,desc.DepthScale,desc.HeadScale=.77,.76,.77,.9
			end
			return Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)
		end)
		if ok and result then rig=result break end
		warn(("[Second Chances] %s avatar %s: %s"):format(role,name,tostring(result)))
	end
	if not rig then return nil end
	rig.Name = role
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = false
	local animator=humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator=Instance.new("Animator")
		animator.Parent=humanoid
	end
	for _,node in rig:GetDescendants() do
		if node:IsA("BasePart") then
			node.CanCollide, node.CanTouch, node.CanQuery = false,false,false
			node.Massless = true
		elseif node:IsA("Script") or node:IsA("LocalScript") then
			node:Destroy()
		end
	end
	local root=rig:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	rig.PrimaryPart = root
	rig:PivotTo(CFrame.new(0,-1000,0))
	rig.Parent = parent
	return rig
end

local function load(animator, asset)
	local clip=Instance.new("Animation")
	clip.AnimationId="rbxassetid://"..asset
	local ok,track=pcall(animator.LoadAnimation,animator,clip)
	if not ok then return nil end
	track.Priority=Enum.AnimationPriority.Movement
	track.Looped=true
	return track
end
function Actor.new(rig,config)
	local humanoid=rig:FindFirstChildOfClass("Humanoid")
	local animator=humanoid:FindFirstChildOfClass("Animator")
	local self=setmetatable({
		rig=rig, root=rig.PrimaryPart, height=humanoid.HipHeight+rig.PrimaryPart.Size.Y/2,
		motors={}, face=rig:FindFirstChildWhichIsA("FaceControls",true), tracks={walk=load(animator,config.Walk), run=load(animator,config.Run)},
		gait="", pose={}
	},Actor)
	for _,joint in rig:GetDescendants() do
		if joint:IsA("Motor6D") then self.motors[joint.Name]=joint end
	end
	return self
end
function Actor:set(origin, position, direction, pose, mode, speed, clock)
	local aim=Vector3.new(direction.X,0,direction.Z)
	local p=origin+position+Vector3.new(0,self.height,0)
	self.rig:PivotTo(CFrame.lookAt(p,p+aim))
	self.pose,self.clock,self.speed=pose or {},clock,speed or 0
	mode = mode or ""
	if mode~=self.gait then
		local old=self.tracks[self.gait]
		if old then old:Stop(.16) end
		self.gait=mode
		local track=self.tracks[mode]
		if track then track:Play(.16) end
	end
	local track=self.tracks[mode]
	if track and track.Length>0 then track:AdjustSpeed(math.clamp(self.speed/(mode=="run" and 11 or 5),.12,1.75)) end
end
function Actor:hide()
	self:set(Vector3.zero,Vector3.new(0,-1000,0),Vector3.zAxis,{},nil,0,0)
end

-- Layer local performance over Roblox locomotion in PreSimulation.
-- Transform leaves joint bind offsets intact. Upper-body beats run independently of footwork.
function Actor:resetTransforms()
	for _,joint in self.motors do joint.Transform=id end
end
function Actor:apply()
	local pose,t=self.pose,self.clock or 0
	local track=self.tracks[self.gait]
	if track and track.IsPlaying and track.Length>0 and self.speed<.03 then track:AdjustSpeed(0) end
	local animated=track and track.IsPlaying and track.Length>0
	local function motor(name,x,y,z,offset,overlay)
		local joint=self.motors[name]
		if joint then
			local base=overlay and animated and joint.Transform or id
			joint.Transform=base*(offset or id)*CFrame.Angles(rad(x or 0),rad(y or 0),rad(z or 0))
		end
	end
	local breath=math.sin(t*2.4)
	local sit=pose.sit or 0
	local climb=pose.climb or 0
	local pitch=pose.pitch or 0
	if self.face then
		local smile=pose.smile or 0
		local sad=pose.sad or 0
		local blink=math.max(0,1-math.abs((t+.7)%4.6-.13)/.13)
		self.face.LeftLipCornerPuller,self.face.RightLipCornerPuller=smile,smile
		self.face.LeftLipCornerDown,self.face.RightLipCornerDown=sad,sad
		self.face.LeftEyeClosed,self.face.RightEyeClosed=blink,blink
		self.face.JawDrop=math.min(1,(pose.talk or 0)*(.11+.09*math.sin(t*15)))
	end
	local gesture=(pose.gesture or 0)+math.sin(t*9)*(pose.talk or 0)*7
	local stride=math.sin(t*(self.gait=="run" and 12 or 8))*math.min(self.speed*6,45)
	local fallback=(not animated and self.gait~="") and stride or 0
	local climbing=math.sin(t*8)*climb
	motor("Root",0,0,0,nil,true)
	motor("Waist",pose.lean or breath,pose.twist or 0,pose.tilt or 0,nil,true)
	motor("Neck",pitch+breath*1.3+(pose.talk or 0)*math.sin(t*10)*3,pose.yaw or 0,pose.roll or 0,nil,true)
	motor("RightShoulder",-(pose.right or 0)-gesture+fallback+climb*-108+climbing*36,0,pose.spread or 0,nil,true)
	motor("LeftShoulder",-(pose.left or 0)-gesture*.21-fallback+climb*-108-climbing*36,0,-(pose.spread or 0),nil,true)
	motor("RightElbow",-(pose.bend or 0),0,0,nil,true)
	motor("LeftElbow",-(pose.leftBend or 0),0,0,nil,true)
	motor("RightWrist",0,pose.wrist or 0,0,nil,true)
	motor("RightHip",-sit*86-fallback-climb*18-climbing*24,0,0,nil,true)
	motor("LeftHip",-sit*86+fallback-climb*18+climbing*24,0,0,nil,true)
	motor("RightKnee",sit*82+climb*26+math.max(fallback,0)*.4,0,0,nil,true)
	motor("LeftKnee",sit*82+climb*26+math.max(-fallback,0)*.4,0,0,nil,true)
end
return Actor
