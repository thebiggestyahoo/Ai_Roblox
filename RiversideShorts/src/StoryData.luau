local V=Vector3.new
local X,Z=V(1,0,0),V(0,0,-1)
local function point(x,z,y)
	return V(x,y or .23,z)
end
local function smooth(t,a,b)
	local u=math.clamp((t-a)/(b-a),0,1)
	return u*u*(3-2*u)
end
local function cue(t,a,b,c,d)
	return smooth(t,a,b)*(1-smooth(t,c,d))
end
local transit={}
transit[2]=function(c,t)
	local bus=point(-42+14*smooth(t,.43,1),-12,.09)
	c:prop("bus",bus)
	c:actor("Driver",bus+V(4.8,.67,-.56),X,{sit=1,right=34,left=34})
	c:path("Sister",point(-47.8,-8),point(-42.6,-8),t,0,.42,"run",
		{lean=5,right=cue(t,.17,.32,.66,.85)*(94+10*math.sin(t*35)),bend=14})
	c:hand("ticket","Sister","LeftHand")
	c:shot(V(-54.6,7.5,-9.23),V(-43.75,2.75,-8),59)
end
transit[3]=function(c,t)
	c:actor("Baker",point(-23,-4.16),-Z,{right=cue(t,.02,.2,.71,1)*64,bend=18,talk=cue(t,.18,.31,.7,.85)})
	c:path("Sister",point(-33,-7.8),point(-26.6,-6.05),t,0,.68,"run",{pitch=-5,left=26})
	c:hand("bag","Baker","RightHand")
	c:shot(V(-34.09,6.7,-18.37),V(-26.69,2.31,-5.75),52)
end

local park={}
local gate=point(37.6,2.68)
local function court(c,t,blame)
	c:actor("Captain",point(44.1,10.4),X,{right=blame*62,bend=20,spread=22*blame,talk=blame})
	c:actor("Friend",point(52.3,10.3),V(-.7,0,-.6),{right=blame*22,lean=4*blame})
end
park[1]=function(c,t)
	court(c,t,smooth(t,.3,.56))
	c:actor("NewKid",point(49.6,7.6),-X,{sad=.3,pitch=15*smooth(t,.25,.52),right=22})
	local bounce=math.abs(math.sin(math.pi*math.min(1,t/.31)))^1.4
	c:prop("ball",point(46.99+t*.57,8.06,.32+bounce*1.7))
	c:prop("bag",point(49.95,6.88,.62))
	c:lights(t<.16)
	if t<.28 then
		c:shot(V(48,9.9,-4.65),V(48.2,2.43,8.92),57)
	else
		c:shot(V(56.3,6.94,1.25),V(48.8,2.55,9.45),59)
	end
end
park[2]=function(c,t)
	court(c,t,cue(t,0,.1,.22,.44))
	local pickup=cue(t,.16,.28,.39,.47)
	c:path("NewKid",point(49.6,7.6),point(42.9,4.6),t,.42,1,"walk",{lean=pickup*36,right=65*pickup,pitch=19,sad=.45})
	if t<.32 then c:prop("bag",point(49.95,6.88,.62)) else c:hand("bag","NewKid","RightHand") end
	c:prop("ball",point(46.99,8.06,.45))
	c:shot(V(41.8,10.13,-2.3),V(47.11,2.46,8.87),58)
end
park[3]=function(c,t)
	local lean=cue(t,.23,.38,.65,.83)
	c:path("Captain",point(41.5,5.0),gate,t,0,.35,"walk",{lean=lean*26,right=lean*78,bend=13,pitch=lean*17},-X)
	c:prop("ball",V(43.5+1.9*smooth(t,.58,1),.42,7.2))
	c:prop("plug",point(37.6-.34*smooth(t,.35,.57),2.86,1.39))
	c:lights(t>=.57)
	c:shot(V(39.5,6.4,-6.5),V(38.2,2.23,3.17),55)
end
park[6]=function(c,t)
	c:lights(true)
	local shot=point(50.62,10.25)
	local launch=smooth(t,.05,.26)
	local arc=t<.26 and 0 or math.clamp((t-.26)/.40,0,1)
	local rebound=smooth(t,.66,.93)
	local rim=V(53,6.15,15.63)
	local ball=V(50.71,4.4,10.55):Lerp(rim,arc)+V(0,math.sin(math.pi*arc)*2.59,0)
	local reach=cue(t,.02,.18,.29,.48)
	c:actor("NewKid",shot,V(.4,0,1),{right=reach*145,left=reach*116,bend=39*(1-launch),pitch=-12*reach,smile=smooth(t,.72,.99)*.58})
	c:actor("Captain",point(46.3,8.05),V(.86,0,.49),{right=cue(t,.66,.8,.94,1)*78,talk=smooth(t,.7,.87),smile=.68})
	c:actor("Friend",point(54.8,9.58),V(-.4,0,.92),{right=68*smooth(t,.64,.89),left=43*smooth(t,.61,.84),bend=25,smile=.65})
	if t<.26 then c:hand("ball","NewKid","RightHand")
	elseif t<.96 then c:prop("ball",ball:Lerp(V(54.55,3.18,10.75),rebound))
	else c:hand("ball","Friend","RightHand") end
	if t<.66 then
		c:shot(V(62.35,7.8,4.86),V(50.49,3.34,10.25),55)
	else
		c:shot(V(57.9,6.4,17.9),V(51.0,2.59,9.38),60)
	end
end
-- Extra story beats are staged in the same streets, with motivated cuts across the route.
local function cast(c,role,x,z,direction,pose,y)
	c:actor(role,point(x,z,y),direction,pose)
end
local NE,NW=V(.8,0,.6),V(-.8,0,.6)
local function waiting(c,x,door)
	local bus=point(x,-12,.09)
	c:prop("bus",bus)
	c:busState(door or 0,door~=nil)
	c:actor("Driver",bus+V(4.8,.67,-.56),X,{sit=1,right=34,left=34})
end
local function pair(c,first,second)
	cast(c,"Sister",23.2,-8.3,X,first)
	cast(c,"Brother",26.65,-8.1,-X,second)
end
local function brothersShot(c,side)
	if side then c:shot(V(16.63,3.85,-6.31),V(25.7,2.65,-9.6),56)
	else c:shot(V(34.46,6.74,-7.28),V(25.24,2.54,-9.9),57) end
end
local lastBus={
	function(c,t)
		waiting(c,-42+11*smooth(t,.4,1))
		c:path("Sister",point(-56.1,-8.7),point(-48.1,-8.7),t,.05,.81,"run",{right=24,lean=13,worry=.8})
		c:hand("ticket","Sister","RightHand")
		if t<.4 then
			c:shot(V(-58.6,6.25,-17.7),V(-49.8,2.72,-9.88),59)
		else
			c:shot(V(-62.6,7.65,-6.85),V(-48.65,2.35,-10.8),60)
		end
	end,
	function(c,t)
		local phone=cue(t,.04,.2,.5,.73)
		cast(c,"Sister",-48.1,-8.7,X,{left=55*phone,leftBend=50*phone,pitch=24*phone,worry=.67})
		c:hand("phone","Sister","LeftHand")
		c:hand("ticket","Sister","RightHand")
		c:shot(V(-58.4,5.7,-16.4),V(-47.75,2.35,-8.6),56)
	end,
	transit[2],
	function(c,t)
		cast(c,"Sister",-42.6,-8,X,{left=32*cue(t,.22,.44,.66,.97),leftBend=68,pitch=17,worry=.91,sad=.27})
		c:hand("ticket","Sister","RightHand")
		c:shot(V(-51.7,4.95,-2),V(-41.8,2.47,-8.62),57)
	end,
	transit[3],
	function(c,t)
		cast(c,"Baker",-23,-3.85,Z,{talk=.82,right=50,left=67*cue(t,.33,.47,.77,.98),bend=16,smile=.25})
		cast(c,"Sister",-26.6,-6.05,NE,{worry=.67,pitch=-5,roll=7,left=19})
		c:hand("bag","Baker","RightHand")
		c:shot(V(-33.2,6.45,-12.3),V(-24.4,2.67,-4.85),57)
	end,
	function(c,t)
		cast(c,"Baker",-23,-3.85,NW,{right=72*cue(t,.03,.19,.41,.52),bend=10})
		cast(c,"Sister",-26.6,-6.05,NE,{right=69*smooth(t,.16,.44),left=39,bend=24,pitch=15,worry=.4})
		c:transfer("bag","Baker","Sister",smooth(t,.25,.56))
		c:shot(V(-19.25,5.85,-15.3),V(-24.7,2.5,-4.9),54)
	end,
	function(c,t)
		c:path("Sister",point(-26.6,-6.05),point(-19.4,-9.22),t,0,.68,"run",{right=30,lean=8,worry=.72})
		cast(c,"Baker",-23,-3.85,Z,{right=91*smooth(t,.12,.42),talk=.88})
		c:hand("bag","Sister","RightHand")
		c:shot(V(-16.19,7.5,-16.69),V(-23,2.64,-6.66),61)
	end,
	function(c,t)
		c:path("Sister",point(-7.2,-9.47),point(14.3,-9.45),t,.04,.70,"run",{lean=8+4*(1-smooth(t,.64,.8)),right=27,yaw=24*smooth(t,.7,.92)})
		c:path("Local",point(-1.82,-17.5),point(-1.82,-12.95),t,.03,.6,"walk",{})
		c:hand("bag","Sister","RightHand")
		if t<.37 then
			c:shot(V(-16.21,9.5,-13.68),V(-2.13,2.75,-10.8),60)
		else
			c:shot(V(17.8,7.05,-16.9),V(9.75,2.58,-10.0),60)
		end
	end,
	function(c,t)
		c:path("Sister",point(14.3,-9.4),point(20.18,-8.7),t,0,.66,"run",{right=24,worry=.52},X)
		cast(c,"Local",24.6,-8.2,X,{pitch=-4})
		c:hand("bag","Sister","RightHand")
		c:shot(V(10.03,8.5,-20.46),V(19.74,2.35,-8.76),55)
	end,
	function(c,t)
		cast(c,"Sister",20.18,-8.7,X,{talk=.59,left=61*cue(t,0,.16,.38,.49),right=25,worry=.35})
		cast(c,"Local",24.6,-8.2,X,{right=83*smooth(t,.39,.62),bend=6})
		c:hand("bag","Sister","RightHand")
		c:shot(V(31.72,6.25,-15.91),V(23.03,2.55,-8.8),56)
	end,
	function(c,t)
		waiting(c,11+10.25*smooth(t,0,.7),t>=.7 and 0 or nil)
		c:path("Sister",point(20.18,-8.7),point(23.2,-8.3),t,.11,.68,"run",{right=24},X)
		c:hand("bag","Sister","RightHand")
		if t<.61 then
			c:shot(V(15.4,9.18,-21.8),V(19.9,2.71,-10.85),60)
		else
			c:shot(V(37.6,8.1,-6.96),V(24.31,2.75,-10.4),58)
		end
	end,
	function(c,t)
		waiting(c,21.25,smooth(t,0,.18))
		cast(c,"Sister",23.2,-8.3,X,{right=24,surprise=.46})
		c:path("Brother",point(26.28,-10.35,.7),point(26.65,-8.1),t,.18,.62,"walk",{left=52,right=39,smile=.25},-X)
		c:hand("bag","Sister","RightHand")
		c:hand("cake","Brother","LeftHand")
		brothersShot(c,false)
	end,
	function(c,t)
		waiting(c,21.25,1)
		pair(c,{right=28,left=57*cue(t,.41,.59,.72,.99),talk=.68,worry=.57},{left=49,pitch=-4,surprise=.46})
		c:hand("bag","Sister","RightHand")
		c:hand("cake","Brother","LeftHand")
		brothersShot(c,true)
	end,
	function(c,t)
		waiting(c,21.25,1)
		pair(c,{right=28,pitch=6,worry=.24},{left=46,right=41*cue(t,.31,.49,.68,.91),talk=.69,smile=.25})
		c:hand("bag","Sister","RightHand")
		c:hand("cake","Brother","LeftHand")
		brothersShot(c,false)
	end,
	function(c,t)
		waiting(c,21.25,1)
		pair(c,{right=74*(1-smooth(t,.42,.76)),bend=19,smile=.56},
			{right=68*smooth(t,.26,.48),left=30,bend=19,smile=.73*smooth(t,.32,.71)})
		c:transfer("bag","Sister","Brother",smooth(t,.37,.68))
		c:hand("cake","Brother","LeftHand")
		brothersShot(c,true)
	end,
	function(c,t)
		waiting(c,21.25,1)
		pair(c,{left=62*smooth(t,.31,.55),leftBend=25,smile=.85},
			{left=71,leftBend=22,right=26,smile=.71})
		c:transfer("cake","Brother","Sister",smooth(t,.46,.73),"LeftHand")
		c:hand("bag","Brother","RightHand")
		brothersShot(c,false)
	end,
	function(c,t)
		waiting(c,21.25,1)
		c:path("Sister",point(23.2,-8.3),point(25.45,-9.91,.97),t,.4,.94,"walk",{right=68,smile=.55})
		c:path("Brother",point(28.02,-7.6),point(27.73,-7.6),t,.72,1,"walk",{right=27,smile=.51})
		c:hand("ticket","Sister","RightHand")
		c:hand("bag","Brother","RightHand")
		c:shot(V(35.93,9.13,-8.52),V(24.18,2.5,-10),59)
	end,
	function(c,t)
		local busX=21.25+13*smooth(t,.2,1)
		waiting(c,busX)
		cast(c,"Sister",busX+.42,-11.6,X,{sit=1,left=21,pitch=13,smile=.56},.58)
		cast(c,"Brother",busX-2.62,-11.6,X,{sit=1,right=21,smile=.75},.66)
		c:hand("phone","Sister","LeftHand")
		c:shot(V(40.27,10.62,-8.08),V(26.5,2.48,-11.5),61)
	end,
	function(c,t)
		c:path("Sister",point(-52.2,-8.85),point(-44.85,-8.85),t,.05,.8,"walk",{smile=.57,right=19})
		c:path("Brother",point(-48.5,-8.42),point(-41.15,-8.42),t,.05,.8,"walk",{smile=.73,left=32})
		c:hand("ticket","Brother","LeftHand")
		c:shot(V(-37.2,7,-20.3),V(-45.7,2.52,-8.65),59)
	end,
}

local function courtShot(c,mode)
	if mode==1 then c:shot(V(61.52,7.7,3.71),V(47.8,2.68,9.3),60)
	elseif mode==2 then c:shot(V(36.18,10,14.71),V(48.5,2.69,8.5),57)
	else c:shot(V(38.9,10.93,-0.1),V(46.24,2.38,8.02),58) end
end
local function trio(c,a,b,d)
	cast(c,"Captain",44.2,7.5,NE,a)
	cast(c,"NewKid",49.3,5.92,NW,b)
	cast(c,"Friend",51.85,10.72,V(-.78,0,-.6),d)
end
local function atGate(c,newPose,captainPose)
	cast(c,"NewKid",38.1,-2.22,NE,newPose)
	cast(c,"Captain",41.55,-1.42,-X,captainPose)
	c:shot(V(44.9,6.2,-11.2),V(39.82,2.51,-1.82),57)
end
local newPark={
	park[1],
	function(c,t)
		c:tone("memory")
		c:lights(true)
		c:path("NewKid",point(36.55,-1.35),point(39.1,3.1),t,.12,.84,"walk",{pitch=9,worry=.54})
		c:hand("ball","NewKid","LeftHand")
		c:shot(V(45.2,5.85,-8.9),V(37.9,2.62,.9),56)
	end,
	function(c,t)
		c:tone("memory")
		c:lights(true)
		trio(c,{right=49*smooth(t,.25,.49),smile=.27},{left=45,talk=.64,worry=.45},{right=19})
		c:hand("ball","NewKid","LeftHand")
		courtShot(c,1)
	end,
	function(c,t)
		c:lights(false)
		trio(c,{worry=.45,pitch=-2},{left=36,roll=-7,surprise=.62,sad=.35},
			{right=89*smooth(t,.12,.39),talk=.8,anger=.51})
		c:hand("ball","NewKid","LeftHand")
		courtShot(c,2)
	end,
	park[2],
	function(c,t)
		c:lights(false)
		c:path("Captain",point(45.9,7.9),point(40.8,5.36),t,.08,.85,"walk",{worry=.3,pitch=7},-X)
		cast(c,"Friend",51.85,10.72,V(-.7,0,-.5),{right=43*cue(t,.1,.25,.53,.75),talk=.58})
		c:prop("ball",V(46.99,.45,8.06))
		courtShot(c,3)
	end,
	function(c,t)
		c:lights(false)
		c:path("Captain",point(40.8,5.36),point(38.13,3.65),t,.03,.62,"walk",
			{pitch=25*smooth(t,.31,.62),right=24,lean=12*smooth(t,.56,.74),surprise=.35},-X)
		c:prop("plug",V(37.66,1.34,2.86))
		c:shot(V(35.66,6.15,-6.94),V(37.45,2.15,3.76),57)
	end,
	park[3],
	function(c,t)
		c:lights(true)
		if t<.55 then
			c:path("Captain",point(38.3,4.16),point(44.95,7.54),t,.01,.39,"run",{lean=10+24*cue(t,.29,.42,.54,1),right=39+19*smooth(t,.31,.46)})
			c:prop("ball",V(46.6-math.min(t,.55)*2.45,.43,8.05))
			c:shot(V(36.09,10.6,-6.9),V(42.4,2.43,5.8),59)
		else
			c:path("NewKid",point(42.5,-1.82),point(38.1,-2.22),t,.54,.98,"walk",{pitch=21,sad=.52})
			c:hand("bag","NewKid","RightHand")
			c:shot(V(46.2,6.55,-12.3),V(40.34,2.5,-1.96),55)
		end
	end,
	function(c,t)
		c:lights(true)
		atGate(c,{left=65*smooth(t,.29,.58),right=25,pitch=24,sad=.59,lean=8},
			{right=73,bend=28,worry=.38})
		c:transfer("ball","Captain","NewKid",smooth(t,.31,.67),nil,"LeftHand")
		c:hand("bag","NewKid","RightHand")
	end,
	function(c,t)
		c:lights(true)
		atGate(c,{left=35,talk=cue(t,.32,.47,.75,.91),pitch=5,worry=.47},
			{right=56*cue(t,.06,.2,.35,.56),talk=cue(t,0,.1,.27,.4),pitch=17*smooth(t,.58,.83),worry=.67})
		c:hand("bag","NewKid","RightHand")
		c:hand("ball","NewKid","LeftHand")
	end,
	function(c,t)
		c:lights(true)
		c:path("Captain",point(37.45,3.67),point(44.2,7.5),t,0,.92,"run",{lean=10,worry=.3},X)
		cast(c,"Friend",51.85,10.72,NW,{talk=.76,right=68*cue(t,.12,.24,.71,.95)})
		courtShot(c,1)
	end,
	function(c,t)
		c:lights(true)
		cast(c,"Captain",44.2,7.5,NE,{right=54*cue(t,.04,.17,.78,.97),talk=.88,worry=.32})
		cast(c,"Friend",51.85,10.72,NW,{right=45*(1-smooth(t,.17,.62)),pitch=13*smooth(t,.55,.88),sad=.29})
		courtShot(c,2)
	end,
	function(c,t)
		c:lights(true)
		c:path("Captain",point(44.2,7.5),point(39.1,4.33),t,.02,.59,"walk",{right=58*cue(t,.3,.59,.94,1),talk=.67},-X)
		c:path("Friend",point(51.85,10.72),point(41.48,6.93),t,.08,.9,"run",{right=35,pitch=3},-X)
		cast(c,"NewKid",38.1,-2.22,NE,{left=37,pitch=-8,worry=.31})
		c:hand("ball","NewKid","LeftHand")
		c:shot(V(28.35,7.42,-3),V(38.39,2.38,3.48),55)
	end,
	function(c,t)
		c:lights(true)
		c:path("NewKid",point(38.1,-2.22),point(43.2,5.45),t,.13,.95,"walk",{smile=.5,left=41})
		cast(c,"Captain",40.4,8.16,Z,{right=49,smile=.59})
		cast(c,"Friend",46.1,9.41,NW,{left=37,smile=.46})
		c:hand("ball","NewKid","LeftHand")
		c:prop("bag",V(35.42,1.98,1.82))
		c:shot(V(29.1,9.22,-4.11),V(38.48,2.55,4.31),58)
	end,
	function(c,t)
		c:lights(true)
		c:path("NewKid",point(45.7,6.5),point(50.55,10.35),t,.04,.46,"walk",
			{right=69*smooth(t,.49,.89),left=62*smooth(t,.49,.85),pitch=-13*smooth(t,.5,.82)},NE)
		cast(c,"Captain",42.0,7.6,NE,{smile=.42})
		cast(c,"Friend",55.7,9.3,NW,{smile=.45})
		c:hand("ball","NewKid","RightHand")
		c:shot(V(63.46,7.19,6.07),V(49,3.03,9.59),56)
	end,
	park[6],
	function(c,t)
		c:lights(true)
		cast(c,"Friend",54.8,9.58,NW,{right=68*cue(t,0,.15,.52,.65),left=46,smile=.66})
		cast(c,"NewKid",50.62,10.25,NE,{left=68*smooth(t,.26,.58),right=54*smooth(t,.3,.56),smile=.55,surprise=.25})
		cast(c,"Captain",45.3,6.59,NE,{smile=.72})
		c:toss("ball","Friend","NewKid",smooth(t,.25,.63))
		courtShot(c,2)
	end,
	function(c,t)
		c:lights(true)
		c:path("NewKid",point(49.65,8.98),point(51.5,12.1),t,.21,.73,"walk",{right=37,smile=.57},NE)
		c:path("Captain",point(45.3,6.59),point(43.1,5.37),t,.34,.81,"walk",{right=26,smile=.68},NE)
		c:path("Friend",point(54.27,11),point(56.2,9.59),t,.31,.8,"walk",{right=28,smile=.71},NW)
		c:hand("ball","NewKid","RightHand")
		c:shot(V(62.62,7.55,7.87),V(49.66,2.78,9.36),61)
	end,
	function(c,t)
		if t<.43 then
			c:lights(true)
			cast(c,"NewKid",51.5,12.1,NE,{right=52,left=28,smile=.64})
			cast(c,"Captain",43.1,5.37,NE,{smile=.67,right=19})
			cast(c,"Friend",56.2,9.59,NW,{smile=.74,right=48})
			c:hand("ball","NewKid","RightHand")
			c:shot(V(63,7.8,8.7),V(50.05,2.93,9.45),61)
		else
			c:tone("next day")
			c:lights(false)
			trio(c,{smile=.44,right=22},{smile=.82,right=75*cue(t,.47,.58,.89,1),talk=.73},
				{smile=.75,right=47*smooth(t,.57,.81)})
			cast(c,"Spectator",44.8,12.75,NE,{right=36*smooth(t,.66,.91),smile=.61})
			c:hand("ball","NewKid","LeftHand")
			c:shot(V(60.3,10.43,-0.7),V(48.41,2.43,8.34),59)
		end
	end,
}
return {
	["last-bus"]={grade="afternoon",scenes=lastBus,roles={"Sister","Brother","Baker","Driver","Local"}},
	["park-lights"]={grade="blue hour",scenes=newPark,roles={"Captain","NewKid","Friend","Spectator"}},
}
