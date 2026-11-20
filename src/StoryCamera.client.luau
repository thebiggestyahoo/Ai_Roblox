local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local ContentProvider=game:GetService("ContentProvider")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("RobloxCinematic")
local Config=require(shared.Config)
local Story=require(shared.StoryData)
local Timing=require(shared.NarrationTiming)
local Props=require(shared.PhotoArt)
local camera=workspace.CurrentCamera
local V=Vector3.new
local CF=CFrame.new
local RGB=Color3.fromRGB
local hide=CF(0,-1100,0)
local rate=Timing.rate

local gui=Instance.new("ScreenGui")
gui.Name,gui.IgnoreGuiInset,gui.DisplayOrder,gui.ResetOnSpawn="Second Chances",true,100,false
gui.Parent=player:WaitForChild("PlayerGui")
local portrait=Instance.new("Frame")
portrait.AnchorPoint,portrait.Position=Vector2.new(.5,.5),UDim2.fromScale(.5,.5)
portrait.BackgroundTransparency,portrait.Parent=1,gui
local left=Instance.new("Frame")
local right=Instance.new("Frame")
local top=Instance.new("Frame")
local bottom=Instance.new("Frame")
for _,bar in {left,right,top,bottom} do
	bar.BorderSizePixel,bar.BackgroundColor3,bar.ZIndex,bar.Parent=0,Color3.new(),9,gui
end
local flash=Instance.new("Frame")
flash.Size,flash.BorderSizePixel,flash.BackgroundColor3,flash.BackgroundTransparency,flash.ZIndex,flash.Parent=
	UDim2.fromScale(1,1),0,RGB(255,226,163),1,2,portrait
local crop=Instance.new("Frame")
crop.BackgroundTransparency,crop.Position,crop.Size,crop.Visible,crop.ZIndex,crop.Parent=
	1,UDim2.fromScale(.08,.07),UDim2.fromScale(.84,.84),false,5,portrait
local stroke=Instance.new("UIStroke")
stroke.Color,stroke.Thickness,stroke.Parent=RGB(251,199,104),1,crop
local function label(name,position,size,font)
	local l=Instance.new("TextLabel")
	l.Name,l.Position,l.Size,l.Font=name,position,size,font
	l.BackgroundTransparency,l.TextScaled,l.TextWrapped=1,true,true
	l.TextColor3,l.TextStrokeColor3,l.TextStrokeTransparency=RGB(255,245,223),RGB(18,18,20),.36
	l.ZIndex,l.Parent=4,portrait
	return l
end
local captions=label("Captions",UDim2.fromScale(.08,.758),UDim2.fromScale(.84,.094),Enum.Font.GothamMedium)
local status=label("Status",UDim2.fromScale(.09,.36),UDim2.fromScale(.82,.18),Enum.Font.GothamBold)
local title=label("Title",UDim2.fromScale(.12,.27),UDim2.fromScale(.76,.16),Enum.Font.GothamBold)
title.Text,title.TextTransparency="THE SHOP THAT SOLD\nSECOND CHANCES",1
local capLimit=Instance.new("UITextSizeConstraint")
capLimit.MaxTextSize,capLimit.Parent=43,captions
local black=Instance.new("Frame")
black.BorderSizePixel,black.Size,black.BackgroundColor3,black.BackgroundTransparency,black.ZIndex,black.Parent=
	0,UDim2.fromScale(1,1),Color3.new(),0,3,portrait
status.Text="Loading cast and sets…"
local function layout()
	local size=camera.ViewportSize
	local w,h=math.floor(math.min(size.X,size.Y*9/16)),math.floor(math.min(size.Y,size.X*16/9))
	local x,y=math.floor((size.X-w)/2),math.floor((size.Y-h)/2)
	portrait.Size=UDim2.fromOffset(w,h)
	left.Size, right.Position,right.Size=UDim2.fromOffset(x,size.Y),UDim2.fromOffset(x+w,0),UDim2.fromOffset(size.X-x-w,size.Y)
	top.Position,top.Size,bottom.Position,bottom.Size=UDim2.fromOffset(x,0),UDim2.fromOffset(w,y),UDim2.fromOffset(x,y+h),UDim2.fromOffset(w,size.Y-y-h)
end
layout()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
camera.CameraType=Enum.CameraType.Scriptable
task.defer(function()
	for _,key in {Enum.CoreGuiType.All} do pcall(StarterGui.SetCoreGuiEnabled,StarterGui,key,false) end
end)

local runtime=RS:WaitForChild("SecondChancesRuntime",45)
if not runtime then status.Text="The cinematic server did not start. Check Studio Output." return end
local loadStarted=os.clock()
while not runtime:GetAttribute("Ready") and os.clock()-loadStarted<45 do task.wait(.12) end
if not runtime:GetAttribute("Ready") then status.Text="Avatar loading timed out. Check Studio Output." return end
local stage=workspace:WaitForChild("SecondChances",20)
if not stage then status.Text="The cinematic sets did not replicate." return end
local cast=runtime:WaitForChild("Cast")
local originFolder=runtime:WaitForChild("Origins")
for _,name in {"Noah","Lucas","Keeper","Rumor","Teacher","Student","Extra","YoungNoah","YoungLucas"} do
	if not cast:WaitForChild(name,3) then
		status.Text="Roblox could not load "..name..". Check Config and Studio Output."
		return
	end
end
local Actor=require(runtime.ActorController)
local localScene=Instance.new("Folder")
localScene.Name,localScene.Parent="CinematicPlayback",workspace
local actors={}
for _,template in cast:GetChildren() do
	local rig=template:Clone()
	rig.Parent=localScene
	actors[template.Name]=Actor.new(rig,Config)
end
local river=stage:WaitForChild("River")
local shop=stage:WaitForChild("Shop")
local home=stage:WaitForChild("Home")
local props=Props.build(localScene,cast,river,originFolder.River.Value)
local shopDoor=shop:WaitForChild("Door")
local homeDoor=home:WaitForChild("HouseDoor")
local shopPivot,homePivot=shopDoor:GetPivot(),homeDoor:GetPivot()
local clocks={}
for i=1,12 do
	local clock=shop:WaitForChild("Clock"..i)
	clocks[i]={clock,clock:GetPivot()}
end
local mix=Instance.new("Sound")
mix.Name,mix.SoundId,mix.Volume,mix.Parent="Narration and score",Config.MixAsset,.9,SoundService
if Config.MixAsset~="" then
	task.spawn(function()
		local ok,err=pcall(ContentProvider.PreloadAsync,ContentProvider,{mix})
		if not ok then warn("[Second Chances] Audio preload: "..tostring(err)) end
	end)
	local begin=os.clock()
	while not mix.IsLoaded and os.clock()-begin<12 do task.wait(.1) end
	if not mix.IsLoaded then
		warn("[Second Chances] Audio asset could not load. Check experience permissions.")
	end
else
	warn("[Second Chances] Caption preview. Set Config.MixAsset for the supplied narration, score and foley.")
end
local playingAudio=Config.MixAsset~="" and mix.IsLoaded
local correction=Instance.new("ColorCorrectionEffect")
correction.Name,correction.Parent="Cinematic grade",Lighting
local bloom=Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity,bloom.Size,bloom.Threshold,bloom.Parent=.13,24,1.35,Lighting
local dof=Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
dof.InFocusRadius,dof.NearIntensity,dof.FarIntensity,dof.Parent=10,.08,.12,Lighting
local atmos=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmos.Color,atmos.Decay,atmos.Haze,atmos.Density,atmos.Parent=RGB(197,209,217),RGB(198,153,122),.85,.25,Lighting
local looks={
	blue={18.7,-.24,RGB(134,146,173),RGB(202,218,255),.09,-.13},
	cool={13.8,-.14,RGB(142,153,164),RGB(218,228,244),.12,-.19},
	warm={15.2,.2,RGB(182,165,144),RGB(255,238,212),.08,.016},
	amber={17.45,.08,RGB(168,136,115),RGB(255,226,189),.14,.02},
	morning={8.6,.27,RGB(177,180,165),RGB(255,243,215),.075,.02},
	memory={16.05,.37,RGB(201,181,138),RGB(255,227,176),.025,.12},
	sunset={17.8,.18,RGB(173,137,110),RGB(255,221,183),.12,.025},
}
local context={active={},visible={},propPos={},parts={},look="",t=0}
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
function context:set(name,look)
	if self.setName~=name then
		self.setName=name
		self.origin=originFolder[name].Value
		params.FilterDescendantsInstances={stage[name]}
	end
	if look~=self.look then
		self.look=look
		local l=looks[look]
		Lighting.ClockTime,Lighting.ExposureCompensation,Lighting.Ambient=l[1],l[2],l[3]
		Lighting.OutdoorAmbient=l[3]:Lerp(RGB(210,214,219),.25)
		correction.TintColor,correction.Contrast,correction.Saturation=l[4],l[5],l[6]
	end
end
function context:actor(role,pos,dir,pose,mode,speed)
	self.active[role]=true
	actors[role]:set(self.origin,pos,dir,pose,mode,speed,self.t)
end
function context:walk(role,a,b,t,first,last,mode,pose)
	local u=math.clamp((t-first)/(last-first),0,1)
	-- Short acceleration and braking ramps, with constant travel between them.
	local ramp=.14
	local progress,velocity
	if u<ramp then
		progress,velocity=u*u/(2*ramp),u/ramp
	elseif u>1-ramp then
		progress,velocity=1-ramp-(1-u)^2/(2*ramp),(1-u)/ramp
	else
		progress,velocity=u-ramp/2,1
	end
	local speed=(b-a).Magnitude*velocity*rate/((last-first)*(1-ramp))
	self:actor(role,a:Lerp(b,progress/(1-ramp)),b-a,pose,speed>.045 and mode or nil,speed)
end
function context:show(key,cf)
	self.visible[key]=true
	self.propPos[key]=cf
	props[key]:PivotTo(cf)
end
function context:prop(key,pos,yaw,pitch)
	self:show(key,CF(self.origin+pos)*CFrame.Angles(0,yaw or 0,0)*CFrame.Angles(pitch or 0,0,0))
end
local function handCF(role,offset,yaw)
	local hand=actors[role].rig:FindFirstChild("RightHand")
	local base=actors[role].root.CFrame
	local position=hand and hand.CFrame:PointToWorldSpace(offset) or base:PointToWorldSpace(V(-.85,-.2,-.58))
	return CF(position)*base.Rotation*CFrame.Angles(0,yaw or 0,0)*CFrame.Angles(-.2,0,0)
end
function context:hand(key,role,offset,yaw) self:show(key,handCF(role,offset,yaw)) end
function context:transfer(key,a,b,u,offset,yaw)
	self:show(key,handCF(a,offset,yaw):Lerp(handCF(b,offset,yaw),u))
end
function context:pocket(key,role)
	local r=actors[role].root.CFrame
	self:show(key,r*CF(-.43,.46,-.48)*CFrame.Angles(0,.2,-.19))
end
function context:ledger(open,entry)
	props.ledgerEntry.Text=entry
	props.cover:PivotTo(self.propPos.ledger*CF(-1.15,0,-.12)*CFrame.Angles(0,math.pi*open,0))
end
function context:glow(value) props.watchGlow.Brightness=value end
function context:shopLight(amount)
	local titlePart=shop:FindFirstChild("Shop title")
	titlePart:FindFirstChildOfClass("PointLight").Brightness=2*amount
	titlePart:FindFirstChildOfClass("SurfaceGui").Enabled=amount>.22
end
function context:door(amount) shopDoor:PivotTo(shopPivot*CFrame.Angles(0,-math.clamp(amount,0,1)*1.5,0)) end
function context:houseDoor(amount) homeDoor:PivotTo(homePivot*CFrame.Angles(0,math.clamp(amount,0,1)*1.55,0)) end
function context:mist(amount)
	flash.BackgroundColor3=RGB(242,229,194)
	flash.BackgroundTransparency=1-math.clamp(amount,0,1)
end
function context:rewind(amount)
	self:mist(amount*.75)
	self.reverse=1+amount*38
	props.watchGlow.Brightness=amount*4
end
function context:shot(from,target,fov,drift,focusProp)
	local shotKey=from
	-- Fixed origins identify authored shots. A tracking camera can vary its origin continuously.
	if not self.lastFrom or (self.lastFrom-shotKey).Magnitude>1.25 then self.shotStart=self.t end
	self.lastFrom=shotKey
	if focusProp and self.propPos[focusProp] then target=self.propPos[focusProp].Position-self.origin end
	local aim=self.origin+target
	local wanted=self.origin+from+drift*math.clamp((self.t-self.shotStart)/4,0,1)
	local direction=wanted-aim
	local hit=workspace:Raycast(aim,direction,params)
	if hit and hit.Instance.Transparency<.8 and hit.Distance>1.1 then
		wanted=aim+direction.Unit*math.max(1.05,hit.Distance-.16)
	end
	camera.CFrame,camera.Focus,camera.FieldOfView=CFrame.lookAt(wanted,aim),CF(aim),fov
	dof.FocusDistance=math.max(.4,(wanted-aim).Magnitude)
	dof.InFocusRadius=focusProp and 2.8 or 10
end

local showCaps=Config.Captions
local epoch,base,wasPlaying
local lastScene,currentScene
local keys={watch=true,photo=true,phone=true,ledger=true}
for key in keys do props[key]:PivotTo(hide) end
local function frame(time)
	local scene=#Timing.starts
	while scene>1 and time<Timing.starts[scene] do scene-=1 end
	currentScene=scene
	context.t=(time-Timing.starts[scene])*rate
	context.reverse=1
	table.clear(context.active)
	table.clear(context.visible)
	table.clear(context.propPos)
	flash.BackgroundTransparency=1
	props.watchGlow.Brightness=0
	if lastScene~=scene then
		context:shopLight(1)
		context.lastFrom=nil
		context:door(0)
		context:houseDoor(0)
	end
	Story[scene](context,context.t)
	lastScene=scene
	for key in keys do if not context.visible[key] then props[key]:PivotTo(hide) end end
	for name,actor in actors do
		if not context.active[name] and actor.root.Position.Y>-950 then actor:hide() end
	end
	local watch=props.watch:GetPivot()
	props.watchHand.CFrame=watch*CF(0,0,-.124)*CFrame.Angles(0,0,-math.rad(math.floor(time*context.reverse*8)*6))*CF(0,.10,0)
	if context.setName=="Shop" then
		for i,item in clocks do
			item[1]:PivotTo(item[2]*CFrame.Angles(0,0,-math.rad(i*23+math.floor(time*context.reverse*6)*6)))
		end
	end
	captions.Text=""
	if showCaps then
		for _,cue in Timing.captions[scene] do
			if time>=cue[1] and time<cue[2] then captions.Text=cue[3] break end
		end
	end
	title.TextTransparency=1-math.clamp(math.min((time-2.25)*2,(5.6-time)*1.7),0,1)
	black.BackgroundTransparency=1-math.clamp((time-(Timing.finish-1.2))/1.2,0,1)
end
local function play(scene)
	scene=math.clamp(scene,1,#Story)
	base,epoch=Timing.starts[scene],os.clock()
	if playingAudio then
		mix:Stop()
		mix.TimePosition=base
		mix:Play()
	end
	wasPlaying=true
	status.Text=""
end
Run.PreAnimation:Connect(function()
	for _,actor in actors do
		if actor.root.Position.Y>-950 then actor:resetTransforms() end
	end
end)
Run.PreSimulation:Connect(function()
	for _,actor in actors do
		if actor.root.Position.Y>-950 then actor:apply() end
	end
end)
Run:BindToRenderStep("SecondChancesDirector",Enum.RenderPriority.Camera.Value+1,function()
	if not wasPlaying then return end
	local wall=base+os.clock()-epoch
	local now=wall
	if playingAudio and mix.IsPlaying and mix.TimePosition>base then now=mix.TimePosition end
	if wall>=Timing.finish+.6 or now>=Timing.finish then
		wasPlaying=false
		mix:Stop()
		frame(Timing.finish)
	else
		frame(now)
	end
end)
Input.InputBegan:Connect(function(key,processed)
	if processed then return end
	if key.KeyCode==Enum.KeyCode.V then crop.Visible=not crop.Visible
	elseif key.KeyCode==Enum.KeyCode.C then showCaps=not showCaps
	elseif key.KeyCode==Enum.KeyCode.R or key.KeyCode==Enum.KeyCode.Space and not wasPlaying then play(Config.StartScene)
	elseif key.KeyCode==Enum.KeyCode.RightBracket then play((currentScene or 1)%#Story+1)
	elseif key.KeyCode==Enum.KeyCode.LeftBracket then play(((currentScene or 1)-2)%#Story+1) end
end)
frame(Timing.starts[Config.StartScene] or 0)
if Config.AutoPlay then play(Config.StartScene) else status.Text="Press Space to play" end
