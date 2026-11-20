local P={}
local V=Vector3.new
local RGB=Color3.fromRGB
local brass,paper,ink=RGB(216,160,66),RGB(232,209,165),RGB(51,42,39)
local function block(model,name,size,cf,color,material)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color=name,size,cf,color
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,false,false,false
	p.Material,p.Parent=material or Enum.Material.SmoothPlastic,model
	return p
end
local function model(parent,name)
	local m=Instance.new("Model")
	m.Name,m.Parent=name,parent
	return m
end
local function surface(p)
	local gui=Instance.new("SurfaceGui")
	gui.Face,gui.LightInfluence=Enum.NormalId.Front,0
	gui.CanvasSize=Vector2.new(640,400)
	gui.Parent=p
	return gui
end
local function text(gui,name,message,y,height,color)
	local label=Instance.new("TextLabel")
	label.Name,label.Text,label.TextColor3=name,message,color or ink
	label.TextScaled,label.TextWrapped,label.BackgroundTransparency=true,true,1
	label.Font=Enum.Font.GothamBold
	label.Position,label.Size=UDim2.fromScale(.06,y),UDim2.fromScale(.88,height)
	label.Parent=gui
	return label
end

function P.build(parent, cast, river, riverOrigin)
	local props={}
	local watch=model(parent,"GoldenWatch")
	watch.WorldPivot=CFrame.identity
	local function disc(name,diameter,depth,z,color,mat)
		local p=block(watch,name,V(depth,diameter,diameter),CFrame.new(0,0,z)*CFrame.Angles(0,math.pi/2,0),color,mat)
		p.Shape=Enum.PartType.Cylinder
		return p
	end
	disc("Gold bezel",.7,.13,0,brass,Enum.Material.Metal)
	disc("Ivory dial",.59,.04,-.075,paper)
	for i=1,12 do
		local a=i*math.pi/6
		block(watch,"Dial index",V(.024,.065,.02),CFrame.new(0,0,-.103)*CFrame.Angles(0,0,a)*CFrame.new(0,.239,0),ink)
	end
	block(watch,"Winding crown",V(.14,.13,.114),CFrame.new(0,.38,0),brass,Enum.Material.Metal)
	local hand=block(watch,"Reverse second hand",V(.022,.225,.015),CFrame.new(0,.10,-.124),RGB(136,52,36))
	block(watch,"Minute hand",V(.18,.027,.018),CFrame.new(.07,0,-.116),ink)
	local glow=Instance.new("PointLight")
	glow.Color,glow.Range,glow.Brightness,glow.Parent=brass,5,0,watch:FindFirstChild("Gold bezel")
	props.watch, props.watchHand, props.watchGlow=watch,hand,glow

	local photo=model(parent,"Photograph")
	photo.WorldPivot=CFrame.identity
	local card=block(photo,"Scuffed paper",V(1.35,.91,.034),CFrame.identity,paper)
	local g=surface(card)
	local viewport=Instance.new("ViewportFrame")
	viewport.Position,viewport.Size=UDim2.fromScale(.038,.055),UDim2.fromScale(.924,.76)
	viewport.BackgroundColor3,viewport.Ambient,viewport.LightColor=RGB(130,155,114),RGB(185,158,127),RGB(253,237,192)
	viewport.LightDirection=V(-1,-1,-1)
	viewport.Parent=g
	local world=Instance.new("WorldModel")
	world.Parent=viewport
	local camera=Instance.new("Camera")
	camera.CFrame,camera.FieldOfView,camera.Parent=CFrame.lookAt(V(0,2.2,-6.5),V(0,2.15,0)),37,viewport
	viewport.CurrentCamera=camera
	for i,name in {"YoungNoah","YoungLucas"} do
		local template=cast:FindFirstChild(name)
		if template then
			local rig=template:Clone()
			rig.Parent=world
			local p=V((i-1.5)*2.05,1.75,.22)
			rig:PivotTo(CFrame.lookAt(p,p+V((1.5-i)*.3,0,-1)))
			local arm=rig:FindFirstChild(i==1 and "RightShoulder" or "LeftShoulder",true)
			if arm and arm:IsA("Motor6D") then arm.C0 *= CFrame.Angles(-.65,0,i==1 and .24 or -.24) end
			local face=rig:FindFirstChildWhichIsA("FaceControls",true)
			if face then
				face.LeftLipCornerPuller,face.RightLipCornerPuller,face.JawDrop=.9,.9,.14
			end
		end
	end
	for _,name in {"Back boards","Hand-painted sign"} do
		for _,piece in river:GetChildren() do
			if piece.Name==name then
				local clone=piece:Clone()
				clone.Position=V(piece.Position.X-riverOrigin.X,piece.Position.Y-riverOrigin.Y-4.7,2.1)
				clone.Parent=world
			end
		end
	end
	text(g,"Date","RIVER CLUB  •  FIRST SUMMER",.84,.11)
	props.photo=photo

	local phone=model(parent,"Phone")
	phone.WorldPivot=CFrame.identity
	block(phone,"Case",V(.42,.72,.075),CFrame.identity,ink)
	local screen=block(phone,"Screen",V(.37,.65,.02),CFrame.new(0,0,-.045),RGB(56,86,96),Enum.Material.Neon)
	local sg=surface(screen)
	text(sg,"Contact","LUCAS",.15,.23,paper)
	text(sg,"CallState","NO ANSWER",.58,.22,paper)
	props.phone=phone

	local ledger=model(parent,"MemoryLedger")
	ledger.WorldPivot=CFrame.identity
	block(ledger,"Leather",V(2.35,1.49,.125),CFrame.identity,RGB(83,43,35),Enum.Material.Leather)
	local page=block(ledger,"Trade register",V(2.18,1.36,.05),CFrame.new(0,0,-.08),paper)
	local lg=surface(page)
	text(lg,"PageTitle","MEMORY LEDGER",.06,.21)
	text(lg,"Rule","REFUNDS COST MORE",.77,.14)
	props.ledgerEntry=text(lg,"Trade","",.32,.35)
	local cover=model(ledger,"Cover")
	cover.WorldPivot=CFrame.new(-1.15,0,-.12)
	local lid=block(cover,"Leather cover",V(2.28,1.42,.045),CFrame.new(0,0,-.12),RGB(100,59,45),Enum.Material.Leather)
	text(surface(lid),"Title","MEMORY LEDGER",.4,.23,paper)
	props.ledger,props.cover=ledger,cover
	return props
end
return P
