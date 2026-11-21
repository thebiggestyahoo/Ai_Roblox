-- Film props use project-built geometry; cast is loaded through Roblox avatar APIs.
local V, C, RGB=Vector3.new,CFrame.new,Color3.fromRGB
local P={}
function P.build(parent)
	local function model(name)
		local m=Instance.new("Model")
		m.Name,m.Parent,m.WorldPivot=name,parent,C()
		return m
	end
	local function part(m,name,s,x,y,z,color,mat,round)
		local p=Instance.new("Part")
		p.Name,p.Size,p.CFrame,p.Color=name,s,C(x,y,z),color
		p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,false,false,false
		p.Material,p.Parent=mat or Enum.Material.SmoothPlastic,m
		if round then p.Shape=Enum.PartType.Ball end
		return p
	end
	local bus=model("Bus")
	local teal, ivory, glass,dark=RGB(39,112,122),RGB(246,218,166),RGB(93,147,160),RGB(38,46,60)
	part(bus,"Chassis",V(12.8,.62,4.32),0,.89,0,teal)
	part(bus,"Roof",V(12.83,.42,4.42),0,6.16,0,ivory)
	part(bus,"Waist trim",V(12.86,.23,4.40),0,2.84,0,ivory)
	for _,z in {-2.14,2.14} do
		for x=-5.2,5.2,2.08 do
			if z<0 or x<3.35 then
				part(bus,"Passenger side panel",V(2.07,1.68,.14),x,1.95,z,teal)
			end
		end
		for x=-5,5,2 do
			if z<0 or x<3 then
				local pane=part(bus,"Passenger window",V(1.77,2.9,.12),x,4.44,z,glass,Enum.Material.Glass)
				pane.Transparency=.6
			end
			part(bus,"Window pillar",V(.26,3.1,.14),x-1,4.46,z,ivory)
		end
	end
	part(bus,"Windshield",V(.13,2.86,4.16),6.33,4.39,0,glass,Enum.Material.Glass)
	part(bus,"Rear window",V(.14,2.64,4.15),-6.37,4.4,0,glass,Enum.Material.Glass)
	for _,x in {-3,0,2.65} do
		part(bus,"Bus seat cushion",V(1.36,.18,1.35),x,2.8,.31,teal,Enum.Material.Fabric)
		part(bus,"Bus seat back",V(.21,1.17,1.35),x-.67,3.35,.31,teal,Enum.Material.Fabric)
	end
	part(bus,"Exit step",V(2.4,.25,.8),4.85,.66,2.18,dark)
	for _,x in {-4.45,4.45} do
		for _,z in {-1.84,1.84} do
			local wheel=part(bus,"Wheel",V(.43,1.31,1.31),x,.71,z,dark,Enum.Material.Rubber)
			wheel.Shape=Enum.PartType.Cylinder
			wheel.CFrame *= CFrame.Angles(0,math.pi/2,0)
			local rim=part(bus,"Hubcap",V(.48,.56,.56),x,.71,z,ivory,Enum.Material.Metal)
			rim.Shape=Enum.PartType.Cylinder
			rim.CFrame *= CFrame.Angles(0,math.pi/2,0)
		end
	end
	for _,z in {-1.2,1.2} do
		part(bus,"Headlight",V(.12,.46,.51),6.46,1.54,z,ivory,Enum.Material.Neon)
		part(bus,"Tail light",V(.12,.43,.35),-6.46,1.54,z,RGB(238,84,68),Enum.Material.Neon)
	end
	local doors={}
	for i,x in {4.59,5.73} do
		local leaf=Instance.new("Model")
		leaf.Name,leaf.Parent,leaf.WorldPivot="Powered entry door",bus,C(x,0,2.14)
		part(leaf,"Door lower panel",V(1.1,1.28,.13),x,1.8,2.14,teal)
		local glassPane=part(leaf,"Door safety glass",V(1.02,3.15,.1),x,4.06,2.13,glass,Enum.Material.Glass)
		glassPane.Transparency=.56
		for _,edge in {-.51,.51} do
			part(leaf,"Door edge",V(.11,4.51,.16),x+edge,3.46,2.15,ivory)
		end
		doors[i]={leaf,x}
	end
	local indicators={}
	local amber=RGB(255,174,48)
	for _,x in {-6.45,6.45} do
		for _,z in {-1.55,1.55} do
			table.insert(indicators,part(bus,"Amber indicator",V(.12,.23,.3),x,2.12,z,amber,Enum.Material.SmoothPlastic))
		end
	end
	local card=part(bus,"Route plate",V(2.7,.54,.15),-3,2.11,2.23,dark)
	local gui=Instance.new("SurfaceGui")
	gui.Face,gui.Parent=Enum.NormalId.Back,card
	local label=Instance.new("TextLabel")
	label.Text,label.TextScaled,label.TextColor3,label.Font="RIVERSIDE • 02",true,ivory,Enum.Font.GothamBold
	label.Size,label.BackgroundTransparency,label.Parent=UDim2.fromScale(1,1),1,gui
	local bag=model("Bag")
	part(bag,"Canvas bag",V(.86,1.07,.47),0,0,0,RGB(48,120,193),Enum.Material.Fabric,true)
	part(bag,"Front pocket",V(.6,.42,.16),0,-.16,-.23,RGB(30,75,133),Enum.Material.Fabric)
	part(bag,"Stitched badge",V(.13,.12,.024),.17,-.09,-.33,ivory)
	local cake=model("Cupcake")
	part(cake,"Wrapper",V(.31,.23,.31),0,.03,0,RGB(165,106,55))
	part(cake,"Frosting",V(.37,.23,.38),0,.19,0,RGB(245,139,158),nil,true)
	part(cake,"Cherry",V(.11,.11,.11),0,.32,0,RGB(205,55,73),nil,true)
	local ball=model("Ball")
	part(ball,"Basketball",V(.49,.49,.49),0,0,0,RGB(214,109,50),Enum.Material.Rubber,true)
	for i=0,11 do
		local angle=i*math.pi/6
		part(ball,"Seam",V(.016,.016,.03),math.cos(angle)*.244,math.sin(angle)*.244,0,dark)
	end
	local plug=model("Plug")
	part(plug,"Weatherproof plug",V(.28,.19,.31),0,0,0,RGB(214,165,82))
	local ticket=model("Ticket")
	part(ticket,"Yellow ticket",V(.23,.37,.022),0,0,0,RGB(250,209,116))
	local phone=model("Phone")
	part(phone,"Phone case",V(.33,.56,.075),0,0,0,dark,Enum.Material.SmoothPlastic)
	part(phone,"Front glass",V(.285,.49,.018),0,0,-.044,glass,Enum.Material.Glass)
	return {phone=phone,bus=bus,bag=bag,cake=cake,ball=ball,plug=plug,ticket=ticket},{doors=doors,indicators=indicators}
end
return P
