local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local StarterGui=game:GetService("StarterGui")
local TextService=game:GetService("TextService")
local shared=ReplicatedStorage:WaitForChild("RobloxCinematic")
local Config=require(shared.Config)
if Config.ExploreTown then return end
local stories=require(shared.StoryData)
local timing=require(shared.NarrationTiming)
local Props=require(shared.PhotoArt)
local camera=workspace.CurrentCamera
local V, RGB=Vector3.new,Color3.fromRGB
local gui=Instance.new("ScreenGui")
gui.Name,gui.IgnoreGuiInset,gui.ResetOnSpawn,gui.Parent="Riverside Film",true,false,Players.LocalPlayer:WaitForChild("PlayerGui")
local plate=Instance.new("Frame")
plate.BackgroundTransparency,plate.AnchorPoint,plate.Position,plate.Parent=1,Vector2.new(.5,.5),UDim2.fromScale(.5,.5),gui
local bars={}
for i=1,4 do
	local bar=Instance.new("Frame")
	bar.BackgroundColor3,bar.BorderSizePixel,bar.ZIndex,bar.Parent=Color3.new(),0,8,gui
	bars[i]=bar
end
local caption=Instance.new("TextLabel")
caption.Position,caption.Size,caption.Parent=UDim2.fromScale(.1,.787),UDim2.fromScale(.8,.105),plate
caption.BackgroundTransparency,caption.BackgroundColor3,caption.TextColor3,caption.TextStrokeTransparency=.2,RGB(15,20,28),RGB(255,245,222),1
caption.TextWrapped,caption.RichText,caption.Font=true,true,Enum.Font.GothamMedium
local corners=Instance.new("UICorner")
corners.CornerRadius,corners.Parent=UDim.new(.18,0),caption
local pad=Instance.new("UIPadding")
pad.PaddingLeft,pad.PaddingRight=UDim.new(.06,0),UDim.new(.06,0)
pad.PaddingTop,pad.PaddingBottom,pad.Parent=UDim.new(.1,0),UDim.new(.1,0),caption
local captionWidth=0
local captionPixels=18
local lastCaption,lastCaptionPixels
local storyWords={
	bus=true,ticket=true,backpack=true,waiting=true,wait=true,
	dark=true,plug=true,gate=true,blamed=true,ball=true,
}
local function captionMarkup(text)
	local escaped=text:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
	local colored=false
	return (escaped:gsub("%a+",function(word)
		if not colored and storyWords[word:lower()] then
			colored=true
			return '<font color="#FFD788"><b>'..word..'</b></font>'
		end
		return word
	end))
end
local function setCaption(text)
	if lastCaption==text and lastCaptionPixels==captionPixels then return end
	lastCaption,lastCaptionPixels=text,captionPixels
	caption.Text,caption.TextSize=captionMarkup(text),captionPixels
	caption.BackgroundTransparency=text=="" and 1 or .22
	if text~="" and captionWidth>0 then
		local measure=TextService:GetTextSize(text,captionPixels,caption.Font,Vector2.new(captionWidth*.69,1000))
		if measure.Y>captionPixels*2.4 then caption.TextSize=math.floor(captionPixels*.87) end
	end
end
caption.Text="Loading Riverside…"
local card=Instance.new("TextLabel")
card.Name,card.AnchorPoint,card.Position,card.Size="Time card",Vector2.new(.5,0),UDim2.fromScale(.5,.077),UDim2.fromScale(.81,.065)
card.BackgroundColor3,card.BackgroundTransparency,card.TextColor3,card.TextWrapped=RGB(19,24,33),.16,RGB(255,226,171),false
card.Font,card.ZIndex,card.Visible,card.Parent=Enum.Font.GothamBold,5,false,plate
local cardCorner=Instance.new("UICorner")
cardCorner.CornerRadius,cardCorner.Parent=UDim.new(.25,0),card
local fade=Instance.new("Frame")
fade.Size,fade.BackgroundColor3,fade.BorderSizePixel,fade.ZIndex,fade.Parent=UDim2.fromScale(1,1),Color3.new(),0,3,plate
caption.ZIndex=4
local function layout()
	local s=camera.ViewportSize
	local w,h=math.floor(math.min(s.X,s.Y*9/16)),math.floor(math.min(s.Y,s.X*16/9))
	local x,y=math.floor((s.X-w)/2),math.floor((s.Y-h)/2)
	plate.Size=UDim2.fromOffset(w,h)
	captionWidth,captionPixels=w,math.clamp(math.floor(w*.056),14,60)
	caption.TextSize=captionPixels
	card.TextSize=math.clamp(math.floor(w*.05),13,54)
	bars[1].Size=UDim2.fromOffset(x,s.Y)
	bars[2].Position,bars[2].Size=UDim2.fromOffset(x+w,0),UDim2.fromOffset(s.X-x-w,s.Y)
	bars[3].Position,bars[3].Size=UDim2.fromOffset(x,0),UDim2.fromOffset(w,y)
	bars[4].Position,bars[4].Size=UDim2.fromOffset(x,y+h),UDim2.fromOffset(w,s.Y-y-h)
end
camera.CameraType=Enum.CameraType.Scriptable
camera.FieldOfViewMode=Enum.FieldOfViewMode.Vertical
layout()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
task.defer(function() pcall(StarterGui.SetCoreGuiEnabled,StarterGui,Enum.CoreGuiType.All,false) end)
local runtime=ReplicatedStorage:WaitForChild("RiversideRuntime",40)
local map=workspace:WaitForChild("Riverside",25)
if not runtime or not map then caption.Text="Town failed to load. See Studio Output." return end
local start=os.clock()
while not runtime:GetAttribute("Ready") and os.clock()-start<40 do task.wait(.08) end
local Actor=require(runtime.ActorController)
local cast=runtime:WaitForChild("Cast")
local stage=Instance.new("Folder")
stage.Name,stage.Parent="Film playback",workspace
local props,busControls=Props.build(stage)
local actors={}
for _,template in cast:GetChildren() do
	local rig=template:Clone()
	rig.Parent=stage
	actors[rig.Name]=Actor.new(rig,Config)
end
local lamps={}
for _,item in map["Riverside Park"]:GetDescendants() do
	if item:IsA("PointLight") and item.Parent.Name=="Court floodlight" then table.insert(lamps,item) end
end
local correction=Instance.new("ColorCorrectionEffect")
correction.Saturation,correction.Contrast,correction.Parent=.07,.085,Lighting
local depth=Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if depth then depth.Enabled=false end
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then atmosphere.Density,atmosphere.Haze=.205,.9 end
local sound=Instance.new("Sound")
sound.Name,sound.Parent="Short narration",SoundService
local hidden=CFrame.new(0,-900,0)
local usedProps,usedActors={},{}
local staged,attachments={},{}
local names={}
for name in actors do table.insert(names,name) end
table.sort(names)
local blockers={}
for _,part in map:GetDescendants() do
	if part:IsA("BasePart") and part.CanCollide and part.Transparency<.48 then
		table.insert(blockers,part)
	end
end
local ray=RaycastParams.new()
ray.FilterType,ray.FilterDescendantsInstances=Enum.RaycastFilterType.Include,blockers
local box=OverlapParams.new()
box.FilterType,box.FilterDescendantsInstances=Enum.RaycastFilterType.Include,blockers
box.MaxParts=1
local function clear(a,b)
	return not workspace:Raycast(a,b-a,ray)
end
local function separate()
	for _=1,4 do
		for i,left in names do
			local a=staged[left]
			if not a then continue end
			for j=i+1,#names do
				local b=staged[names[j]]
				if not b or math.abs(a.p.Y-b.p.Y)>1.85 then continue end
				local delta=V(b.p.X-a.p.X,0,b.p.Z-a.p.Z)
				local minimum=(left=="Brother" or names[j]=="Brother") and 2.85 or 3.3
				if delta.Magnitude>=minimum then continue end
				local side=delta.Magnitude>.01 and delta.Unit or Vector3.xAxis
				local needed=(minimum-delta.Magnitude)*.57
				local a1,b1=a.p-side*needed,b.p+side*needed
				local up=V(0,1.45,0)
				local freeA,freeB=clear(a.p+up,a1+up),clear(b.p+up,b1+up)
				if freeA then a.p=a1 end
				if freeB then b.p=b1 end
				if freeA and not freeB and clear(a.p+up,a.p-side*needed+up) then a.p-=side*needed end
				if freeB and not freeA and clear(b.p+up,b.p+side*needed+up) then b.p+=side*needed end
			end
		end
	end
end
local function getHand(role,hand)
	local rig=actors[role].rig
	local part=rig:FindFirstChild(hand or "RightHand")
	return part and part.CFrame*CFrame.new(0,-.13,-.12) or rig:GetPivot()
end
local c={}
function c:actor(role,p,dir,pose,mode,speed)
	usedActors[role]=true
	staged[role]={p=p,dir=dir,pose=pose,mode=mode,speed=speed}
end
function c:path(role,a,b,t,first,last,mode,pose,face)
	local u=math.clamp((t-first)/(last-first),0,1)
	local r=.14
	local progress,velocity=u-r/2,1
	if u<r then progress,velocity=u*u/(2*r),u/r
	elseif u>1-r then progress,velocity=1-r-(1-u)^2/(2*r),(1-u)/r end
	local speed=(b-a).Magnitude*velocity/(1-r)/((last-first)*self.duration)
	self:actor(role,a:Lerp(b,progress/(1-r)),speed>.06 and b-a or face or b-a,pose,speed>.06 and mode or nil,speed)
end
function c:show(key,cf)
	usedProps[key]=true
	props[key]:PivotTo(cf)
end
function c:prop(key,p) self:show(key,CFrame.new(p)) end
function c:hand(key,role,hand)
	attachments[key]={role,hand}
end
function c:transfer(key,a,b,u,from,to)
	attachments[key]={a,from,b,to or from,u}
end
function c:toss(key,a,b,u,from,to)
	attachments[key]={a,from,b,to or from,u,true}
end
function c:tone(look) self.look=look end
function c:busState(open,hazards) self.busOpen,self.hazards=open,hazards end
function c:lights(on)
	for _,lamp in lamps do
		lamp.Enabled=on
		lamp.Parent.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end
function c:shot(p,target,fov)
	self.wanted,self.target,self.fov=p,target,fov
end
local function cameraCandidates(p,target)
	local direction=(p-target).Unit
	local side=direction:Cross(Vector3.yAxis).Unit
	return {
		p,p+side*2.7+V(0,.7,0),p-side*2.7+V(0,.7,0),
		p+V(0,2.8,0),p+side*5.3+V(0,1.8,0),p-side*5.3+V(0,1.8,0),
		p+direction*3.5+V(0,3.3,0),target+V(2,14,-10),target+V(-10,11,-5),
	}
end

local function scoreCamera(shot)
	local best,result=-math.huge,nil
	local bounds=math.tan(math.rad(shot.fov/2))
	for order,pos in cameraCandidates(shot.p,shot.target) do
		if #workspace:GetPartBoundsInBox(CFrame.new(pos),V(1.12,1.12,1.12),box)>0 then continue end
		if not clear(shot.target,pos) then continue end
		local cf=CFrame.lookAt(pos,shot.target)
		local total=0
		for _,sample in shot.samples do
			local count,grade=0,0
			for role,mark in sample do
				if role=="Driver" then continue end
				count+=1
				local middle=mark.p+V(0,2.46,0)
				local localPoint=cf:PointToObjectSpace(middle)
				local depth=-localPoint.Z
				if depth<=1 then grade-=7 continue end
				local edgeX=bounds*depth*9/16
				local edgeY=bounds*depth
				local horizontal=(math.abs(localPoint.X)+.91)/(edgeX*.96)
				local vertical=(math.abs(localPoint.Y)+2.02)/(edgeY*.98)
				grade+=2-math.max(0,horizontal-.88)*7-math.max(0,vertical-.92)*6
				if clear(middle,pos) then grade+=1.6 else grade-=5.1 end
				if not clear(mark.p+V(0,4,0),pos) then grade-=1.1 end
			end
			total+=grade/math.max(1,count)
		end
		local score=total/math.max(1,#shot.samples)-order*.11
		if score>best then best,result=score,pos end
	end
	if not result then
		warn("[Riverside Shorts] No clear camera candidate at "..tostring(shot.p))
		return shot.target+V(0,25,-3)
	end
	return result
end

local sampleDirector={}
function sampleDirector:actor(role,p,dir,pose,mode,speed)
	self.marks[role]={p=p}
end
sampleDirector.path=c.path
function sampleDirector:shot(p,target,fov) self.p,self.target,self.fov=p,target,fov end
function sampleDirector:lights() end
function sampleDirector:tone() end
function sampleDirector:busState() end
function sampleDirector:prop() end
function sampleDirector:hand() end
function sampleDirector:transfer() end
function sampleDirector:toss() end
local function planShots(film,track)
	local plan={}
	for i,scene in film.scenes do
		local groups={}
		local timing=track.cues[i]
		sampleDirector.duration=timing[2]-timing[1]
		for _,u in {0,.09,.2,.34,.48,.63,.78,.91,1} do
			sampleDirector.marks={}
			scene(sampleDirector,u)
			local group
			for _,candidate in groups do
				if candidate.p==sampleDirector.p and candidate.target==sampleDirector.target then group=candidate break end
			end
			if not group then
				group={p=sampleDirector.p,target=sampleDirector.target,fov=sampleDirector.fov,samples={}}
				table.insert(groups,group)
			end
			table.insert(group.samples,sampleDirector.marks)
		end
		for _,shot in groups do shot.cameraPosition=scoreCamera(shot) end
		plan[i]=groups
		if i%4==0 then task.wait() end
	end
	return plan
end
local lastShot,lastTarget,cameraPosition
local function chooseCamera(plans)
	local p,target,fov=c.wanted,c.target,c.fov
	if lastShot~=p or lastTarget~=target then
		local match
		for _,shot in plans do
			if shot.p==p and shot.target==target then match=shot break end
		end
		cameraPosition=match and match.cameraPosition or scoreCamera({p=p,target=target,fov=fov,samples={staged}})
		lastShot,lastTarget=p,target
	end
	camera.CFrame,camera.Focus,camera.FieldOfView=CFrame.lookAt(cameraPosition,target),CFrame.new(target),fov
end
local ids={"last-bus","park-lights"}
local index=Config.Film==ids[2] and 2 or 1
local film, track, epoch, active, plan
local fromTime, usingAudio, currentBeat, activeFilm=0,false,1,nil
local prepared={}
local preparing=false
local captions=Config.Captions
local looks={
	afternoon={16.12,.07,RGB(146,139,125),RGB(177,175,169),RGB(255,241,216)},
	["blue hour"]={18.35,.16,RGB(107,113,152),RGB(145,152,175),RGB(217,230,254)},
	memory={17.14,.20,RGB(158,143,123),RGB(199,184,156),RGB(255,237,202)},
	["next day"]={14.38,.11,RGB(143,160,163),RGB(175,192,190),RGB(238,254,239)},
}
local lastLook
local function grade(look)
	if lastLook==look then return end
	lastLook=look
	local values=looks[look]
	Lighting.ClockTime,Lighting.ExposureCompensation=values[1],values[2]
	Lighting.Ambient,Lighting.OutdoorAmbient=values[3],values[4]
	correction.TintColor=values[5]
end
local function play(startBeat)
	if preparing then return end
	active=false
	card.Visible=false
	lastShot,lastTarget=nil,nil
	local id=ids[index]
	film,track=stories[id],timing[id]
	for _,role in film.roles do
		if not actors[role] then caption.Text="Roblox could not load "..role..". See Studio Output." return end
	end
	if not prepared[id] then
		preparing=true
		setCaption("Checking camera positions…")
		prepared[id]=planShots(stories[id],timing[id])
		preparing=false
	end
	plan=prepared[id]
	grade(film.grade)
	c:lights(film.grade=="afternoon")
	sound:Stop()
	local asset=Config.AudioAssets[id] or ""
	if sound.SoundId~=asset then sound.SoundId=asset end
	usingAudio=false
	if asset~="" then
		preparing=true
		if not sound.IsLoaded then
			setCaption("Loading narration…")
			task.spawn(function() pcall(ContentProvider.PreloadAsync,ContentProvider,{sound}) end)
			local deadline=os.clock()+6
			while not sound.IsLoaded and os.clock()<deadline do task.wait(.08) end
		end
		usingAudio=sound.IsLoaded
		preparing=false
		if not usingAudio then warn("[Riverside Shorts] Narration asset did not load. This take uses the visual clock.") end
	end
	activeFilm=id
	currentBeat=math.clamp(startBeat or 1,1,#track.cues)
	fromTime=track.cues[currentBeat][1]
	lastCaption=nil
	setCaption("")
	epoch,active=os.clock(),true
	if usingAudio then
		sound:Play()
		sound.TimePosition=fromTime
	end
end
local function draw(t)
	local i=#track.cues
	while i>1 and t<track.cues[i][1] do i-=1 end
	local beat=track.cues[i]
	currentBeat=i
	c.t,c.duration=t,beat[2]-beat[1]
	table.clear(usedActors)
	table.clear(usedProps)
	table.clear(staged)
	table.clear(attachments)
	c.busOpen,c.hazards,c.look=0,false,film.grade
	film.scenes[i](c,math.clamp((t-beat[1])/c.duration,0,1))
	grade(c.look)
	if usedProps.bus then
		local pivot=props.bus:GetPivot()
		for door,entry in busControls.doors do
			entry[1]:PivotTo(pivot*CFrame.new(entry[2]+(door==1 and -.92 or .81)*c.busOpen,0,2.14))
		end
		local illuminated=c.hazards and math.floor(t*3.6)%2==0
		for _,indicator in busControls.indicators do
			indicator.Material=illuminated and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	separate()
	for role,mark in staged do
		actors[role]:set(Vector3.zero,mark.p,mark.dir,mark.pose,mark.mode,mark.speed,c.t)
	end
	for _,actor in actors do actor:prepareReaches() end
	for key,attachment in attachments do
		local a,hand,b,handB,alpha,toss=table.unpack(attachment,1,6)
		local cf=getHand(a,hand)
		if b then
			local handOut=getHand(b,handB)
			cf=cf:Lerp(handOut,alpha)
			if toss then
				cf+=V(0,math.sin(math.pi*alpha)*1.66,0)
			elseif alpha>.015 and alpha<.985 then
				local pa,pb=staged[a].p,staged[b].p
				local mids=pa:Lerp(pb,.5)+V(0,2.7,0)
				local across=Vector3.new(pb.X-pa.X,0,pb.Z-pa.Z)
				if across.Magnitude>.1 and across.Magnitude<4.5 then
					local weight=math.sin(math.pi*alpha)^.65
					local direction=across.Unit
					actors[a]:reach(hand,mids-direction*.15,weight)
					actors[b]:reach(handB,mids+direction*.15,weight)
					cf=CFrame.new(cf.Position:Lerp(mids,weight^3))*cf.Rotation
				end
			end
		end
		c:show(key,cf)
	end
	for _,actor in actors do actor:finishReaches() end
	chooseCamera(plan[i])
	for name,actor in actors do
		if not usedActors[name] and actor.root.Position.Y>-700 then actor:hide() end
	end
	for name,prop in props do
		if not usedProps[name] then prop:PivotTo(hidden) end
	end
	local text=""
	if captions then
		for _,subtitle in beat[3] do
			if t>=subtitle[1] and t<subtitle[2] then text=subtitle[3] break end
		end
	end
	setCaption(text)
	local offset=t-beat[1]
	local sceneCard
	if Config.TimeCards and i==2 and offset<1.55 then
		sceneCard=activeFilm=="last-bus" and "A MOMENT EARLIER" or "EARLIER THAT EVENING"
	elseif Config.TimeCards and i==20 and activeFilm=="park-lights" then
		local day=offset-c.duration*.43
		if day>=0 and day<1.55 then sceneCard="THE NEXT DAY" end
	end
	card.Visible=sceneCard~=nil
	if sceneCard then card.Text=sceneCard end
	fade.BackgroundTransparency=1-math.clamp((t-(track.finish-.28))/.28,0,1)
end
Run.PreAnimation:Connect(function()
	for name,actor in actors do if usedActors[name] then actor:resetTransforms() end end
end)
Run.PreSimulation:Connect(function()
	for name,actor in actors do if usedActors[name] then actor:apply() end end
end)
Run:BindToRenderStep("RiversideFilm",Enum.RenderPriority.Camera.Value+1,function()
	if not active then return end
	local t=fromTime+os.clock()-epoch
	if usingAudio and sound.IsPlaying then
		t=math.max(fromTime,sound.TimePosition)
	end
	draw(math.min(t,track.finish))
	if t>=track.finish then active=false sound:Stop() end
end)
Input.InputBegan:Connect(function(input,processed)
	if processed or preparing then return end
	if input.KeyCode==Enum.KeyCode.C then captions=not captions
	elseif input.KeyCode==Enum.KeyCode.R then play(1)
	elseif input.KeyCode==Enum.KeyCode.RightBracket and activeFilm then play(currentBeat+1)
	elseif input.KeyCode==Enum.KeyCode.LeftBracket and activeFilm then play(currentBeat-1)
	elseif input.KeyCode==Enum.KeyCode.N then index=index%#ids+1 play() end
end)
play(Config.StartBeat)
