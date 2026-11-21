local Players = game:GetService("Players")
local Actor = {}
Actor.__index = Actor
local rad = math.rad
local id = CFrame.identity

function Actor.spawn(role, names, parent, outfitId)
	local rig
	for _,name in names do
		local ok, result = pcall(function()
			local desc
			if outfitId then
				desc=Players:GetHumanoidDescriptionFromOutfitIdAsync(outfitId)
			else
				local userId=Players:GetUserIdFromNameAsync(name)
				desc=Players:GetHumanoidDescriptionFromUserIdAsync(userId)
			end
			assert(desc, "Missing Roblox avatar description")
			-- Retain the catalog outfit; use familiar blocky proportions.
			desc.BodyTypeScale, desc.ProportionScale, desc.HeightScale = 0, 0, 1
			desc.WidthScale, desc.DepthScale, desc.HeadScale = 1, 1, 1
			desc.Torso, desc.LeftArm, desc.RightArm, desc.LeftLeg, desc.RightLeg = 0,0,0,0,0
			if role=="Brother" then
				desc.HeightScale,desc.WidthScale,desc.DepthScale,desc.HeadScale=.77,.76,.77,.9
			end
			return Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)
		end)
		if ok and result then rig=result break end
		outfitId=nil
		warn(("[Riverside Shorts] %s avatar %s: %s"):format(role,name,tostring(result)))
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
-- Classic heads get an illustrated face fitted to the head surface. Clothes,
-- hair, accessories and the underlying head remain the character's catalog assets.
local function classicFace(rig)
	local head=rig:FindFirstChild("Head")
	if not head then return nil end
	for _,node in head:GetChildren() do
		if node:IsA("Decal") and node.Face==Enum.NormalId.Front then node.Transparency=1 end
	end
	local gui=Instance.new("SurfaceGui")
	gui.Name,gui.Face,gui.CanvasSize,gui.LightInfluence,gui.Parent="Performance face",Enum.NormalId.Front,Vector2.new(256,256),.5,head
	local ink=Color3.fromRGB(43,29,31)
	local function mark(name,color,w,h,x,y,radius,parent)
		local f=Instance.new("Frame")
		f.Name,f.BackgroundColor3,f.BorderSizePixel=name,color,0
		f.AnchorPoint,f.Size,f.Position=Vector2.new(.5,.5),UDim2.fromScale(w,h),UDim2.fromScale(x,y)
		f.Parent=parent or gui
		local corner=Instance.new("UICorner")
		corner.CornerRadius,corner.Parent=UDim.new(radius or .45,0),f
		return f
	end
	local eye={}
	local brows={}
	for i,x in {.33,.67} do
		local white=mark("Sclera",Color3.fromRGB(255,240,225),.15,.143,x,.447)
		mark("Iris",i==1 and Color3.fromRGB(84,69,59) or Color3.fromRGB(80,67,59),.57,.85,.51,.49,.5,white)
		mark("Pupil",ink,.38,.65,.55,.5,.5,white)
		mark("Catchlight",Color3.fromRGB(255,249,232),.19,.19,.43,.3,.5,white)
		brows[i]=mark("Brow",ink,.16,.032,x,.318)
		eye[i]=white
	end
	local mouth=mark("Mouth",ink,.137,.045,.5,.675)
	local shine=mark("Smile highlight",Color3.fromRGB(251,228,209),.73,.22,.5,.25,.3,mouth)
	return function(pose,t)
		local smile,sad=pose.smile or 0,pose.sad or 0
		local worry,anger,surprise=pose.worry or 0,pose.anger or 0,pose.surprise or 0
		local talk=(pose.talk or 0)*(.4+.6*math.abs(math.sin(t*15)))
		local blink=math.max(0,1-math.abs(t%4.35-4.13)/.12)
		for i,white in eye do
			local side=i==1 and -1 or 1
			white.Size=UDim2.fromScale(.15,math.max(.017,(.141+.04*surprise-.04*smile-.035*anger)*(1-blink)))
			brows[i].Rotation=side*(15*worry+18*sad-24*anger-6*smile)
			brows[i].Position=UDim2.fromScale(.5+side*.17,.317-.041*surprise-.028*worry+.022*anger)
		end
		mouth.Size=UDim2.fromScale(.126+.092*smile-.039*surprise,.034+.078*smile+.117*talk+.09*surprise)
		mouth.Rotation=(sad+worry)*-8
		shine.Visible=smile>.35 and talk<.36
	end
end
function Actor.new(rig,config)
	local humanoid=rig:FindFirstChildOfClass("Humanoid")
	local animator=humanoid:FindFirstChildOfClass("Animator")
	local self=setmetatable({
		rig=rig, root=rig.PrimaryPart, height=humanoid.HipHeight+rig.PrimaryPart.Size.Y/2,
		motors={}, face=rig:FindFirstChildWhichIsA("FaceControls",true), tracks={walk=load(animator,config.Walk), run=load(animator,config.Run)},
		gait="", pose={}, reaches={}
	},Actor)
	if not self.face then self.classicFace=classicFace(rig) end
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
function Actor:reach(hand, position, weight)
	local arm = hand=="LeftHand" and "Left" or "Right"
	local reach=self.reaches[arm]
	if not reach then
		local upper=self.rig:FindFirstChild(arm.."UpperArm")
		local palm=self.rig:FindFirstChild(arm.."Hand")
		if not upper or not palm then return end
		local anchor=Instance.new("Part")
		anchor.Name,anchor.Size,anchor.Transparency="Reach target",Vector3.new(.05,.05,.05),1
		anchor.Anchored,anchor.CanCollide,anchor.CanQuery,anchor.CanTouch=true,false,false,false
		anchor.Parent=self.rig.Parent
		local target=Instance.new("Attachment")
		target.Parent=anchor
		local control=Instance.new("IKControl")
		control.Name,control.Type,control.ChainRoot,control.EndEffector=arm.." handoff",Enum.IKControlType.Position,upper,palm
		control.Target,control.SmoothTime,control.Weight=target,.055,0
		control.Parent=self.rig:FindFirstChildOfClass("Humanoid")
		reach={anchor=anchor,control=control}
		self.reaches[arm]=reach
	end
	reach.anchor.Position=position
	reach.control.Weight=math.clamp(weight,0,1)
	reach.control.Enabled=true
	reach.live=true
end

function Actor:prepareReaches()
	for _,reach in self.reaches do reach.live=false end
end

function Actor:finishReaches()
	for _,reach in self.reaches do
		if not reach.live then reach.control.Enabled=false end
	end
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
		local surprise=pose.surprise or 0
		local worry=pose.worry or 0
		local anger=pose.anger or 0
		local blink=math.max(0,1-math.abs((t+.7)%4.6-.13)/.13)
		self.face.LeftLipCornerPuller,self.face.RightLipCornerPuller=smile,smile
		self.face.LeftLipCornerDown,self.face.RightLipCornerDown=sad,sad
		self.face.LeftEyeClosed,self.face.RightEyeClosed=blink,blink
		self.face.LeftInnerBrowRaiser,self.face.RightInnerBrowRaiser=math.max(worry,sad)*.85,math.max(worry,sad)*.85
		self.face.LeftBrowLowerer,self.face.RightBrowLowerer=anger,anger
		self.face.LeftEyeUpperLidRaiser,self.face.RightEyeUpperLidRaiser=surprise,surprise
		self.face.JawDrop=math.min(1,surprise*.44+(pose.talk or 0)*(.11+.09*math.sin(t*15)))
	elseif self.classicFace then
		self.classicFace(pose,t)
	end
	local gesture=(pose.gesture or 0)+math.sin(t*9)*(pose.talk or 0)*7
	local stride=math.sin(t*(self.gait=="run" and 12 or 8))*math.min(self.speed*6,45)
	local fallback=(not animated and self.gait~="") and stride or 0
	local climbing=math.sin(t*8)*climb
	motor("Root",0,0,0,nil,true)
	motor("Waist",pose.lean or breath,pose.twist or 0,pose.tilt or 0,nil,true)
	motor("Neck",pitch+breath*1.3+(pose.talk or 0)*math.sin(t*10)*3,pose.yaw or 0,pose.roll or 0,nil,true)
	if not (self.reaches.Right and self.reaches.Right.live) then
		motor("RightShoulder",-(pose.right or 0)-gesture+fallback+climb*-108+climbing*36,0,pose.spread or 0,nil,true)
		motor("RightElbow",-(pose.bend or 0),0,0,nil,true)
		motor("RightWrist",0,pose.wrist or 0,0,nil,true)
	end
	if not (self.reaches.Left and self.reaches.Left.live) then
		motor("LeftShoulder",-(pose.left or 0)-gesture*.21-fallback+climb*-108-climbing*36,0,-(pose.spread or 0),nil,true)
		motor("LeftElbow",-(pose.leftBend or 0),0,0,nil,true)
	end
	motor("RightHip",-sit*86-fallback-climb*18-climbing*24,0,0,nil,true)
	motor("LeftHip",-sit*86+fallback-climb*18+climbing*24,0,0,nil,true)
	motor("RightKnee",sit*82+climb*26+math.max(fallback,0)*.4,0,0,nil,true)
	motor("LeftKnee",sit*82+climb*26+math.max(-fallback,0)*.4,0,0,nil,true)
end
return Actor
