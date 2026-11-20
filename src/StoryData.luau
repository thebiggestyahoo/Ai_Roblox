-- Times here are seconds in the original voice take, relative to each paragraph.
-- Scene starts, captions and the conformed audio share NarrationTiming.
local V=Vector3.new
local function ease(t,a,b)
	local x=math.clamp((t-a)/(b-a),0,1)
	return x*x*(3-2*x)
end
local function mix(a,b,x) return a+(b-a)*x end
local function pulse(t,a,b,c,d) return ease(t,a,b)*(1-ease(t,c,d)) end
local forward,back=V(0,0,1),V(0,0,-1)
local S={}

local function classroom(c,t,repair)
	local rumor=pulse(t,.55,1.42,3.17,3.8)
	local laugh=pulse(t,3.7,4.15,5.2,6.15)*(repair and .22 or 1)
	local turn=ease(t,5.25,6.7)
	local stand=repair and ease(t,3.62,4.15) or 0
	local talk=repair and pulse(t,4.4,4.68,5.93,6.45) or 0
	c:actor("Rumor",V(-6,-.63,2),forward,{sit=1,lean=rumor*15,yaw=rumor*37,right=rumor*40,spread=rumor*16,talk=rumor})
	c:actor("Student",V(6,-.63,2),forward,{sit=1,pitch=-laugh*17,yaw=-15+35*laugh,right=laugh*31,talk=laugh})
	c:actor("Extra",V(6,-.63,7),forward,{sit=1,pitch=-laugh*12,yaw=30*laugh,talk=laugh})
	c:actor("Teacher",V(1,0,10),back,{right=laugh*24,left=laugh*19,talk=laugh})
	c:actor("Lucas",V(-2,-.63,2),V(.42*turn,0,1),{sit=1,pitch=repair and -3 or 11*turn,yaw=55*turn,roll=turn*5,smile=repair and ease(t,7.53,8.83)*.8 or 0,sad=repair and 0 or .6*turn,lean=repair and -3*turn or 9*turn})
	c:actor("Noah",V(2,mix(-.63,0,stand),2-mix(0,.36,stand)),V(-.38*turn,0,1),
		{sit=1-stand,pitch=repair and -6*stand or 21*turn,yaw=repair and 17*talk or -31*turn,right=24+talk*27,left=17,talk=talk,lean=8*(1-stand)})
	if t<3.6 then
		c:shot(V(9,7,-12),V(-2,3.3,2.2),49,V(-.35,0,0))
	elseif t<(repair and 4.02 or 5.35) then
		c:shot(V(-9,4.8,5.7),V(-3,3,2.1),39,V(.19,0,0))
	elseif t<8.02 then
		c:shot(V(4.7,repair and 3.4 or 4.55,6.7),V(2,repair and 4.3 or 3.63,1.94),35,V(-.13,.1,0))
	else
		c:shot(V(-.45,3.95,6.4),V(-2,3.63,2),29,V(-.18,0,.15))
	end
end

S[1]=function(c,t)
	c:set("Shop","blue")
	c:actor("Noah",V(.3,.13,-5.7),forward,{pitch=-13*ease(t,2,4),roll=-5})
	c:actor("Keeper",V(-.7,.21,4),back,{})
	c:prop("watch",V(-.9,3.8,-3.9),-.07)
	if t<1.98 then
		c:shot(V(-.74,3.94,-5.58),V(-.9,3.83,-3.9),28,V(-.13,0,-.22))
	elseif t<3.6 then
		c:shot(V(.8,6.1,-23),V(0,6.9,-.3),45,V(.21,.05,.5))
	else
		c:shot(V(2.15,5.05,-2.7),V(.3,4.65,-5.7),29,V(-.12,0,-.13))
	end
end

S[2]=function(c,t)
	c:set("School","cool")
	classroom(c,t,false)
end

S[3]=function(c,t)
	if t>=4.05 then
		c:set("Shop","blue")
		c:shopLight(ease(t,4.18,4.65))
		c:actor("Noah",V(-4,.13,-11),V(4,0,11),{pitch=-9*ease(t,4.3,6.1)})
		c:shot(V(-4.4,6.1,-24),V(-.5,6.5,-.5),47,V(1,.12,1.04))
		return
	end
	c:set("Yard","cool")
	c:walk("Lucas",V(-.8,0,1),V(-4,0,-11.8),t,0,3,"walk",{pitch=13,lean=7})
	c:actor("Noah",V(2.3,0,-1.2),V(-.4,0,-1),{right=62*ease(t,1.5,2.2),bend=55*ease(t,1.5,2.2),pitch=10})
	c:walk("Student",V(6,0,-4),V(14,0,-8),t,0,3,"walk",{})
	if t<1.9 then
		c:shot(V(4.6,5.4,1),V(-1.4,3.15,-5.8),45,V(-1,0,-1.6))
	else
		c:hand("phone","Noah",V(-.04,.02,-.17),math.pi)
		c:shot(V(3.1,5.35,-.2),V(2.15,3.85,-2.45),37,V(-.2,-.08,-.06),"phone")
	end
end

S[4]=function(c,t)
	c:set("Shop",t<6.2 and "blue" or "amber")
	c:actor("Keeper",V(-.55,.2,10.15),back,{pitch=8-13*ease(t,8,9.7),talk=pulse(t,9.65,10.2,11.2,11.65)})
	c:walk("Noah",V(0,.12,-4.2),V(0,.2,6.0),t,4.64,8.1,"walk",{right=38*pulse(t,5,5.55,6.12,6.48)})
	c:door(ease(t,5.3,5.92)*(1-ease(t,7.4,8.5)))
	c:prop("watch",V(-.9,3.04,8.18),0,-1.3)
	if t<2.15 then
		c:shot(V(.3,8,-21),V(0,8.33,-.5),56,V(-.12,0,.35))
	elseif t<5 then
		c:shot(V(.05,7.71,-11.8),V(0,7.65,-.62),36,V(0,-.08,.15))
	elseif t<7.2 then
		c:shot(V(.65,5.15,-5.4),V(0,3.77,2.1),40,V(-.22,.04,.62))
	elseif t<9.05 then
		c:shot(V(4.8,5.38,4.6),V(.25,5.5,13.6),42,V(-.24,0,.23))
	else
		c:shot(V(1.45,5.2,6.5),V(-.55,4.77,10.15),29,V(-.24,.03,.12))
	end
end

S[5]=function(c,t)
	c:set("Shop","amber")
	local offer=pulse(t,.92,1.9,2.8,3.25)
	local receive=ease(t,1.65,2.35)
	c:actor("Noah",V(-.6,.2,6.77),forward,{right=receive*51,bend=receive*17, left=receive*27,pitch=mix(-5,16,receive),talk=pulse(t,0,.2,.9,1.3)})
	c:actor("Keeper",V(-.57,.2,9.85),back,{right=offer*83,bend=offer*11,left=27*pulse(t,5.6,6.7,7.7,8.1),talk=pulse(t,2.85,3.16,7.5,7.95)})
	c:prop("ledger",V(1.25,3.09,8.42),.08,-1.25)
	c:ledger(.38,"FIRST CHANCE\nONE TREASURED MEMORY")
	if t<.94 then
		c:prop("watch",V(-.8,3.09,8.33),0,-1.32)
	elseif t<2.2 then
		c:transfer("watch","Keeper","Noah",ease(t,1.33,2.2),V(0,.06,-.11))
	else
		c:hand("watch","Noah",V(.015,.09,-.14),.22)
	end
	if t<1.44 then
		c:shot(V(3.9,5.25,6.35),V(-.58,4.25,8.25),40,V(-.25,0,.12))
	elseif t<3.05 then
		c:shot(V(1.13,4.86,6),V(-.67,3.6,8.1),33,V(-.06,.03,.15),"watch")
	elseif t<7.99 then
		c:shot(V(.34,5.45,6.65),V(-.57,4.87,9.82),32,V(.18,-.09,.07))
	else
		c:shot(V(-2.42,4.97,9.62),V(-.6,4.65,6.77),27,V(.11,0,-.13))
	end
end

S[6]=function(c,t)
	if t<1.47 then
		c:set("Shop","amber")
		c:actor("Noah",V(-.6,.2,6.77),forward,{right=57,bend=23,left=44,leftBend=44,pitch=19,wrist=75*ease(t,.06,.72)})
		c:hand("watch","Noah",V(.015,.09,-.14),.22)
		c:shot(V(1.1,4.8,7.64),V(-.61,3.9,7.45),28,V(0,0,-.25),"watch")
		c:rewind(ease(t,.22,1.38))
	else
		c:set("School","warm")
		classroom(c,t-1.47,true)
		c:rewind((1-ease(t,1.47,2.02))*.85)
	end
end

S[7]=function(c,t)
	if t>=4.43 and t<6.58 then
		c:set("River","memory")
		c:shot(V(4.2,4.6,-11.5),V(0,5.4,0),47,V(-.18,.06,.07))
		c:mist(.88-.34*pulse(t,4.43,4.96,5.73,6.58))
		return
	end
	c:set("Street","warm")
	local ask=pulse(t,.78,1.5,3.25,4.25)
	c:walk("Noah",V(-7,.14,-13),V(2,.14,-13),t,0,3.76,"walk",{pitch=ease(t,3.5,4.4)*18,yaw=11})
	c:walk("Lucas",V(-6,.14,-10.72),V(3,.14,-10.72),t,0,3.96,"walk",{left=ask*54,leftBend=ask*36,right=ask*36,talk=ask,yaw=-26*ask})
	if t<3.12 then
		c:shot(V(-1.1+math.min(t,3)*2,5.35,-17.8),V(-6+math.min(t,3)*2,4.25,-11.8),44,V(.3,0,0))
	elseif t<4.43 then
		c:shot(V(6.55,5.42,-14.6),V(2,4.53,-11.4),39,V(-.2,0,.16))
	else
		c:shot(V(5.8,4.96,-13.9),V(2,4.43,-13),28,V(-.32,0,.03))
	end
end

S[8]=function(c,t)
	c:set("Shop","amber")
	local exit=ease(t,9.62,13.6)
	local turn=math.pi*ease(t,8.8,9.61)
	if t<2 then
		c:walk("Noah",V(0,.14,-7.3),V(0,.2,6.65),t,0,1.95,"run",{lean=12,right=31*pulse(t,.48,.76,.97,1.2)})
	elseif t<9.62 then
		c:actor("Noah",V(0,.2,6.65),V(math.sin(turn),0,math.cos(turn)),{right=pulse(t,1.8,2.45,2.78,3.1)*72,lean=10,pitch=12*ease(t,6.7,8.7),talk=pulse(t,1.6,2,3,3.4)})
	else
		c:walk("Noah",V(0,.2,6.65),V(0,.14,-7.3),t,9.62,13.6,"walk",{pitch=19,lean=9})
	end
	c:actor("Keeper",V(-.55,.2,9.85),back,{left=pulse(t,3.35,4.04,5.53,6.24)*58,talk=pulse(t,5.7,6.13,8.66,9.08),pitch=7*exit})
	c:door(pulse(t,.52,.89,1.64,2.24)+pulse(t,11.15,11.61,12.55,13.35))
	if t<2.28 then c:hand("watch","Noah",V(.04,.02,-.12),0)
	else c:prop("watch",V(.02,3.09,8),.11,-1.32) end
	c:prop("ledger",V(1.15,3.1,8.31),0,-1.35)
	c:ledger(1-ease(t,7.9,9.06),"ONE TREASURED MEMORY")
	if t<1.62 then
		c:shot(V(4.9,5.3,4.92),V(0,3.6,.5),43,V(-.29,0,.2))
	elseif t<3.3 then
		c:shot(V(1.02,4.35,6.58),V(0,3.1,7.97),34,V(-.11,-.12,-.11),"watch")
	elseif t<5.79 then
		c:shot(V(3.31,4.88,5.6),V(3.49,4.85,9.58),32,V(.11,0,.1))
	elseif t<9.14 then
		c:shot(V(1.64,5.05,6.55),V(-.55,4.76,9.85),30,V(-.04,.01,.04))
	else
		c:shot(V(-3.6,4.83,7.1),V(0,3.8,1.1),42,V(0,0,0))
	end
end

local function porch(c,t,after)
	c:set("Home","morning")
	local confused= after and 1 or ease(t,7.72,9.25)
	local offer= after and 0 or pulse(t,1.57,2.3,6.46,7.21)
	local receive= after and 1 or ease(t,5.45,6.43)
	local knock=after and 0 or pulse(t,.07,.47,.68,1.32)
	local door=after and 1 or ease(t,.58,1.57)
	
	c:houseDoor(door)
	c:actor("Lucas",V(.36,.22,-3.19),forward,{right=offer*72+knock*(61+math.sin(t*24)*10),left=offer*46,bend=offer*30+knock*19,pitch=4+confused*8,yaw=confused*19,roll=confused*10,smile=(1-confused)*.45,sad=confused*.24,talk=after and pulse(t,1.48,1.8,3.29,3.61) or 0})
	local noahPose={right=receive*57,left=receive*31,bend=receive*17,pitch=(after and 12*ease(t,4.1,5.65) or receive*15),
		sad=after and .65*ease(t,4.3,6.5) or 0,talk=after and pulse(t,3.38,3.63,4.4,4.66)*1.5 or 0}
	if not after and t<1.86 then
		noahPose.right=26*pulse(t,.63,.85,1.1,1.52)
		c:walk("Noah",V(-.36,.19,1.25),V(-.36,.19,-.65),t,.98,1.85,"walk",noahPose)
	else
		c:actor("Noah",V(-.36,.19,-.65),back,noahPose)
	end
	if after or t>6.52 then
		c:hand("photo","Noah",V(.05,.06,-.18),math.pi)
	elseif t>5.45 then
		c:transfer("photo","Lucas","Noah",ease(t,5.45,6.52),V(.04,.08,-.16),math.pi)
	else
		c:hand("photo","Lucas",V(.06,.07,-.16),math.pi)
	end
	c:pocket("watch","Lucas")
	if not after then c:glow(pulse(t,6.25,6.6,7.62,8.18)*3) end
end

local function memory(c,t,fragment)
	c:set("River","memory")
	c:actor("YoungNoah",V(-1.2,4.78,3),back,{right=fragment and 24 or 62+17*math.sin(t*7),left=22,pitch=-7,roll=-10,smile=.87,talk=.9})
	c:actor("YoungLucas",V(1.18,4.78,3),back,{left=56+16*math.sin(t*8),right=24,pitch=-3,roll=8,smile=.9,talk=.9})
	if fragment then
		c:shot(V(-3.45,8.05,-1.9),V(.4,7.51,3),44,V(.26,0,.13))
	else
		c:shot(V(.2,8.08,-3.2),V(0,7.12,3.09),43,V(.14,.09,.17))
	end
end

S[9]=function(c,t)
	if t>=6.6 and t<8.13 then
		memory(c,t,t>7.49)
		c:mist((1-ease(t,6.6,6.86))*.66+ease(t,7.84,8.13)*.79)
		return
	end
	porch(c,t,false)
	if t<1.84 then
		c:shot(V(3.86,5.14,-7.28),V(0,3.4,-.6),45,V(-.16,0,.31))
	elseif t<3.31 then
		c:shot(V(-3.6,4.87,-3.9),V(0,3.96,-1.58),39,V(.12,0,.09))
	elseif t<6.6 then
		c:shot(V(1.58,5.55,-5.77),V(0,3.62,-1.85),43,V(-.04,-.25,0),"photo")
	else
		c:shot(V(-2.24,4.99,-.74),V(.36,4.7,-3.19),28,V(.06,0,.1))
	end
end

S[10]=function(c,t)
	porch(c,t,true)
	if t<3.44 then
		c:shot(V(-3.35,5.06,-.46),V(.36,4.74,-3.19),35,V(.05,.01,0))
	elseif t<4.9 then
		c:shot(V(2.03,4.95,-3.28),V(-.36,4.72,-.65),30,V(-.07,0,.13))
	elseif t<6.35 then
		c:shot(V(-1.35,3.85,-.68),V(.49,3.65,-2.8),28,V(.13,0,.08),"watch")
	else
		c:shot(V(-1.48,4.7,-4.19),V(-.36,4.7,-.65),26,V(.08,0,.25))
	end
end

S[11]=function(c,t)
	if t>=6.19 and t<6.86 then
		c:set("Shop","memory")
		c:actor("Lucas",V(0,.2,6.73),forward,{right=74,bend=17,pitch=12,sad=.38})
		c:actor("Keeper",V(-.55,.2,9.86),back,{right=64,bend=21,pitch=9})
		c:hand("photo","Lucas",V(.03,.06,-.14),.1)
		c:prop("watch",V(.08,3.14,8.16),.2,-1.42)
		c:shot(V(3.3,4.9,6.4),V(0,4.16,8),37,V(-.09,0,0))
		c:mist((1-ease(t,6.19,6.45))*.5)
		return
	elseif t>=6.86 and t<8.03 then
		memory(c,t,t>7.38)
		c:mist(ease(t,6.86,8.03)*.95)
		return
	end
	c:set("Shop","cool")
	c:walk("Noah",V(0,.18,2.2),V(0,.2,6.67),t,0,1.1,"run",{pitch=13*ease(t,5.1,8.9),lean=6})
	c:actor("Keeper",V(-.55,.2,9.86),back,{right=pulse(t,2.64,3.4,4.6,5.05)*63,pitch=6,talk=pulse(t,1.29,1.83,6.9,7.4)})
	local turn=ease(t,2.85,4.15)
	c:prop("ledger",V(.03,3.14,8.13),mix(math.pi,0,turn),mix(-1.5,-.96,turn))
	c:ledger(1,"LUCAS — ALL MEMORIES\nOF NOAH")
	if t<3.8 then
		c:shot(V(4.6,5.15,6),V(0,4.09,8.08),39,V(-.18,.04,.11))
	elseif t<6.86 then
		c:shot(V(.28,6.45,3.37),V(.03,3.15,8.13),48,V(-.15,-.1,.1),"ledger")
	else
		c:shot(V(-1.34,4.8,9.92),V(0,4.71,6.67),28,V(.16,.02,-.17))
	end
end

S[12]=function(c,t)
	c:set("River","sunset")
	local sit=ease(t,4.72,5.48)
	local climb=ease(t,1.95,3.62)
	local turn=ease(t,5.68,6.45)
	c:actor("Lucas",V(1.36,5.16,2.42),back,{sit=1,pitch=13-15*turn,yaw=35*turn,roll=5*turn,smile=.8*ease(t,7.4,8.4),talk=pulse(t,8.03,8.35,8.84,9.18)})
	if t<1.95 then
		c:walk("Noah",V(-1.1,0,-9.2),V(0,0,-3.45),t,0,1.95,"walk",{pitch=-8})
	elseif t<3.62 then
		c:actor("Noah",V(0,4.78*climb,mix(-3.45,-2.15,climb)),forward,{climb=1})
	elseif t<4.72 then
		c:walk("Noah",V(0,4.78,-2.15),V(-1.17,4.78,2.45),t,3.62,4.72,"walk",{})
	else
		c:actor("Noah",V(-1.17,mix(4.78,5.16,sit),2.45),V(mix(.75,0,sit),0,mix(1,-1,sit)),{sit=sit,pitch=5,yaw=-33*turn,smile=.56*ease(t,8.1,9.15),talk=pulse(t,5.7,6.05,7.34,7.89),right=18*pulse(t,5.9,6.2,7,7.34)})
	end
	c:prop("photo",V(.08,6.04,2.65),-.14,-1.47)
	if t<2.84 then
		c:shot(V(9.2,7.95,-17),V(0,5.12,.58),45,V(-.65,.08,.51))
	elseif t<4.21 then
		c:shot(V(-3.8,7.4,-7.5),V(0,6.9,1.5),43,V(.16,.2,.31))
	elseif t<9.35 then
		c:shot(V(-.47,9.4,-2.78),V(0,8.05,2.45),38,V(.22,-.15,.1))
	elseif t<13.06 then
		c:shot(V(6.72,8.02,-12.35),V(0,6.75,1.8),48,V(.6,.31,-.47))
	else
		c:shot(V(.6,7.82,.46),V(.08,6.05,2.65),32,V(.06,.02,.08))
	end
end
return S
