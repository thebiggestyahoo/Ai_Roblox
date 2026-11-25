local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Physics = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")
local Shared = RS:WaitForChild("EggShared")
local Config = require(Shared.Config)
local Levels = require(Shared.Levels)
local Rules = require(Shared.RaceRules)
local World = require(script.Parent.World)
local Courses = require(script.Parent.Courses)
local Obstacles = require(script.Parent.Obstacles)
local Data = require(script.Parent.Data)
local Eggs = require(script.Parent.Eggs)
local Shop = require(script.Parent.Shop)
local CoinPacks = require(script.Parent.CoinPacks)

local remote = Instance.new("RemoteEvent")
remote.Name = "CourierEvent"
remote.Parent = Shared
local queue, practiceQueue, selected, rate = {}, {}, {}, {}
local shopping = {}
local racers = {}
local contenders = {}
local random = Random.new()
local course
local stage, deadline, level = "Lobby", 0, 1
local started, ends = 0, 0
local results, resultCount = {}, 0
local practiceMode, entrants, slots = false, 0, 0
local tournament, duel, heat = false, false, 0
local mapPlan, draftStarted, victor
local now = workspace.GetServerTimeNow
local lobby, demo, leaderboard, podium

pcall(function() Physics:RegisterCollisionGroup("Couriers") end)
Physics:CollisionGroupSetCollidable("Couriers","Couriers",false)

local function send(player, kind, value, extra)
	if player.Parent == Players then remote:FireClient(player,kind,value,extra) end
end

local function profile(player)
	local d = Data.get(player)
	if d then send(player,"Profile",{
		skins=d.skins, trails=d.trails, skin=d.skin, trail=d.trail, title=d.title, records=d.records, deliveries=d.deliveries,
	}) end
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function move(player, pos, frozen)
	local root = rootOf(player)
	if not root then return end
	root.Anchored = frozen == true
	root.CFrame = CFrame.lookAt(pos, pos + Vector3.zAxis)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function progress(r)
	return math.clamp((r.progress-course.z)/(course.finish-course.z),0,0.99)
end

local function queuedCount()
	local count = 0
	for _ in queue do count += 1 end
	return count
end

local function state(player)
	local r = racers[player]
	send(player,"State",{
		stage=stage, deadline=deadline, level=level, racing=r ~= nil, queued=queue[player] == true,
		practiceQueued=practiceQueue[player] ~= nil, selected=selected[player] or 1,
		practice=practiceMode, solo=entrants == 1, result=r and r.result,
		total=entrants, slots=slots, qualified=resultCount, scoreboard=stage == "Results" and results or nil,
		room=contenders[player] == true, tournament=tournament, duel=duel, heat=heat, heats=Rules.heatCount,
		draftStarted=draftStarted, maps=mapPlan, victor=victor,
		queuedCount=queuedCount(), capacity=Config.maxPlayers,
		roundName=if duel then "Final duel" elseif heat > 0 then "Heat " .. heat elseif tournament then "Map draw" else nil,
	})
end

local function broadcast()
	for _, player in Players:GetPlayers() do state(player) end
end

local function phase(name, duration)
	stage, deadline = name, if name=="Race" then ends else now(workspace)+(duration or 0)
	broadcast()
end

local function finishDisplay()
	for _, label in course.finishDisplay or {} do
		label.Text = ("%02d / %02d IN"):format(resultCount,slots)
	end
end

local function restartPractice(player,r,at)
	local d = Data.get(player)
	if not d or racers[player] ~= r or stage ~= "Race" then return end
	r.hp, r.recovering, r.perfect = 3, false, true
	r.immune = at + Config.protection
	r.lastHazard, r.shovedBy, r.shovedAt = nil, nil, nil
	r.routeIndex, r.progress, r.zone = 1, course.z, nil
	r.previous, r.lastSample, r.attemptStarted = r.spawn, at, at
	r.speedOrigin, r.speedAt = r.spawn, at
	move(player,r.spawn,false)
	Eggs.attach(player,d,3)
	send(player,"FX","Restart")
end

local function eliminate(player,r,reason)
	if r.finished then return end
	r.finished, r.recovering, r.zone = true, false, nil
	contenders[player] = nil
	r.result = {out=true,dnf=true,reason=reason,hp=r.hp,progress=progress(r),practice=practiceMode}
	move(player,lobby,false)
	local data = Data.get(player)
	if data then Eggs.attach(player,data,3) end
	send(player,"FX","Out",reason)
	state(player)
end

local function failedAttempt(player,r,reason,at)
	if practiceMode then
		r.recovering = true
		r.penaltyUntil = at+Config.practiceRestartDelay
		local root = rootOf(player)
		if root then root.Anchored = true end
	else
		eliminate(player,r,reason)
	end
end

local function damage(player,r,amount,source)
	local at = now(workspace)
	if stage ~= "Race" or r.finished or r.recovering or (source ~= "fall" and at < r.immune) then return false end
	if source == r.lastHazard and at-r.lastHit < 1.3 then return false end
	r.lastHazard,r.lastHit,r.immune = source,at,at+Config.protection
	r.hp = math.max(0,r.hp-amount)
	Eggs.condition(player,r.hp)
	r.perfect = false
	if r.hp == 0 then
		send(player,"FX","Break")
		local reason = if source == "fall" then
			(if r.shovedAt and at-r.shovedAt <= 2 then "Knocked off by " .. r.shovedBy else "Fell off the island")
			elseif typeof(source) == "Instance" and source:IsA("Player") then "Shoved out by " .. source.DisplayName
			else "Shell shattered"
		failedAttempt(player,r,reason,at)
	else
		send(player,"FX","Crack",r.hp)
	end
	return true
end

local function zoneFor(root)
	if not course or not root then return nil end
	local p = root.Position
	if p.Y < 0.8 or p.Y > 10 then return nil end
	for i, zone in course.zones do
		if math.abs(p.Z-zone.z) <= zone.extent and math.abs(p.X-(zone.x or course.x)) <= (zone.width or 11.5) then return i end
	end
	return nil
end

local function shove(player)
	local r, root = racers[player],rootOf(player)
	local at = now(workspace)
	if stage ~= "Race" or (practiceMode or entrants < 2) or not r or r.finished or r.recovering or not root or root.Anchored or at < r.cooldown or at < r.immune then return end
	local zone = zoneFor(root)
	if not zone then return end
	local closest, target, gap
	for other, rival in racers do
		if other == player or rival.finished or rival.recovering or at < rival.immune then continue end
		local otherRoot = rootOf(other)
		if not otherRoot or otherRoot.Anchored or zoneFor(otherRoot) ~= zone then continue end
		local delta = otherRoot.Position-root.Position
		local distance = delta.Magnitude
		if distance <= Config.shoveRange and (distance < 0.1 or root.CFrame.LookVector:Dot(delta.Unit) > 0.12) and (not gap or distance<gap) then
			closest,target,gap = other,otherRoot,distance
		end
	end
	r.cooldown = at+Config.shoveCooldown
	send(player,"FX","Shove")
	if closest and damage(closest,racers[closest],1,player) and not racers[closest].finished and not target.Anchored then
		local rival = racers[closest]
		rival.shovedBy, rival.shovedAt = player.DisplayName, at
		local offset = target.Position-root.Position
		local flat = Vector3.new(offset.X,0,offset.Z)
		if flat.Magnitude > 0.1 then
			local canSet = target:CanSetNetworkOwnership()
			if canSet then
				target:SetNetworkOwner(nil)
				task.delay(0.18,function()
					if target:IsDescendantOf(workspace) and target:CanSetNetworkOwnership() then
						target:SetNetworkOwnershipAuto()
					end
				end)
			end
			target.AssemblyLinearVelocity = flat.Unit*24 + Vector3.yAxis*9
		end
	end
end

local function updated(player)
	profile(player)
	local d = Data.get(player)
	if d and not racers[player] then Eggs.attach(player,d,3) end
end
Shop.listen(updated)
CoinPacks.start(function(player)
	profile(player)
	send(player,"Notice","Coins added to your locker")
end)

local function action(player, key, id)
	local d = Data.get(player)
	if not d then return end
	if key == "hello" then profile(player); state(player); return end
	if key == "shove" then shove(player); return end
	if key == "lobby" then
		local r = racers[player]
		if contenders[player] and (not r or not r.result or not r.result.champion) then return end
		queue[player],practiceQueue[player] = nil,nil
		if r and (r.finished or practiceMode or stage == "Results") then
			racers[player] = nil
			move(player,lobby,false)
			Eggs.attach(player,d,3)
		end
		broadcast()
		return
	end
	if contenders[player] and (not racers[player] or not racers[player].result or not racers[player].result.champion) then return end
	if key == "next" and racers[player] and (racers[player].finished or stage == "Results") then
		racers[player] = nil
		move(player,lobby,false)
		Eggs.attach(player,d,3)
	end
	if racers[player] then return end
	if key == "queue" or key == "next" then
		queue[player],practiceQueue[player] = true,nil
		broadcast()
		return
	elseif key == "practice" then
		local choice = tonumber(id) or selected[player] or 1
		if Levels[choice] then
			practiceQueue[player],queue[player] = choice,nil
			broadcast()
		end
		return
	elseif key == "choose" then
		local n = tonumber(id)
		if n and n % 1 == 0 and Levels[n] and n <= d.unlocked then
			selected[player] = n
		end
	elseif key == "box" then
		local message, reward, rarity = Shop.openBox(player,id)
		if reward then
			profile(player)
			send(player,"BoxReward",reward,rarity)
			task.spawn(Data.save,player,false)
		else
			send(player,"Notice",message)
		end
	elseif key == "skin" or key == "title" or key == "trail" then
		if shopping[player] then return end
		shopping[player] = true
		local message, pass = Shop.select(player,key,id)
		shopping[player] = nil
		send(player,"Notice",message)
		if pass then send(player,"Pass",pass) end
		updated(player)
	elseif key == "coins" then
		local product = CoinPacks.prompt(player,id)
		if product then send(player,"Product",product)
		else send(player,"Notice","This coin pack is unavailable") end
	elseif key == "aura" and d.wins > 0 then
		player:SetAttribute("WinnerAura",player:GetAttribute("WinnerAura") == false)
		Eggs.aura(player,d)
	elseif key == "Shop" or key == "Courses" then
		send(player,"Open",key)
	end
	state(player)
end

lobby,demo,leaderboard,podium = World.lobby(action)
for _, instance in workspace:GetChildren() do
	if instance.Name == "Baseplate" and instance:IsA("BasePart") then instance:Destroy() end
end

remote.OnServerEvent:Connect(function(player,key,id)
	if typeof(key) ~= "string" or #key > 12 or (id ~= nil and (typeof(id) ~= "string" or #id > 32)) then return end
	if (key == "skin" or key == "title" or key == "trail" or key == "choose" or key == "coins" or key == "box") and id == nil then return end
	local clock = os.clock()
	local limits = rate[player] or {}
	rate[player] = limits
	local bucket = if key == "shove" then "shove" else "menu"
	if limits[bucket] and clock < limits[bucket] then return end
	limits[bucket] = clock + 0.18
	action(player,key,id)
end)

local function spawned(player,character)
	local head = character:WaitForChild("Head",10)
	local root = character:WaitForChild("HumanoidRootPart",10)
	local humanoid = character:WaitForChild("Humanoid",10)
	if not head or not root or not humanoid or character ~= player.Character or not player.Parent then return end
	local function part(item)
		if item:IsA("BasePart") then item.CollisionGroup = "Couriers" end
	end
	if not character:GetAttribute("CourierCollisionReady") then
		character:SetAttribute("CourierCollisionReady",true)
		character.DescendantAdded:Connect(part)
		for _, item in character:GetDescendants() do part(item) end
	end
	local d = Data.get(player)
	if not d then return end
	local r = racers[player]
	if r and not r.finished then
		if stage == "Race" then
			if not r.recovering then failedAttempt(player,r,"Character reset",now(workspace)) end
			if r.recovering then move(player,r.spawn,true) end
			return
		elseif stage == "Preparation" or stage == "Countdown" then
			move(player,r.spawn,true)
			Eggs.attach(player,d,3)
			return
		end
	end
	move(player,lobby,false)
	Eggs.attach(player,d,3)
end

local function join(player)
	player.CharacterAdded:Connect(function(char) spawned(player,char) end)
	local d = Data.load(player)
	if not d then return end
	if player.Parent ~= Players then Data.save(player,true); return end
	Data.summary(player)
	if player.Character then task.spawn(spawned,player,player.Character) end
	profile(player)
	state(player)
	task.spawn(function() Shop.refresh(player); profile(player) end)
end

Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do task.spawn(join,player) end
Players.PlayerRemoving:Connect(function(player)
	racers[player],queue[player],practiceQueue[player],selected[player],rate[player] = nil,nil,nil,nil,nil
	contenders[player],shopping[player] = nil,nil
	broadcast()
	Data.save(player,true)
end)

task.spawn(function()
	while task.wait(45) do
		for player in Data.sessions do task.spawn(Data.save,player,false) end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in Data.sessions do
		pending += 1
		task.spawn(function()
			Data.save(player,true)
			pending -= 1
		end)
	end
	local untilTime = os.clock()+24
	while pending > 0 and os.clock() < untilTime do task.wait(0.1) end
end)

local function finishBurst(root)
	if not root then return end
	local point = Instance.new("Attachment",workspace.Terrain)
	point.WorldPosition = root.Position + Vector3.yAxis * 2.2
	for _, tint in {Color3.fromHex("ffdc53"),Color3.fromHex("fb5791"),Color3.fromHex("36d6ec")} do
		local emitter = Instance.new("ParticleEmitter",point)
		emitter.Rate = 0
		emitter.Color = ColorSequence.new(tint)
		emitter.Lifetime = NumberRange.new(0.6,1.2)
		emitter.Speed = NumberRange.new(7,16)
		emitter.Acceleration = -Vector3.yAxis * 16
		emitter.SpreadAngle = Vector2.new(85,85)
		emitter.Size = NumberSequence.new(0.34,0.05)
		emitter.RotSpeed = NumberRange.new(-120,120)
		emitter:Emit(10)
	end
	Debris:AddItem(point,1.5)
end

local function publishFinish(player,r)
	finishDisplay()
	if r.result.champion then
		player:SetAttribute("WinnerAura",true)
		Eggs.aura(player,Data.get(player))
		task.spawn(Data.save,player,false)
	end
	finishBurst(rootOf(player))
	send(player,"FX","Finish",r.result)
	profile(player)
	broadcast()
end

local function finish(player,r,time)
	r.finished, r.zone = true, nil
	resultCount += 1
	local coins, personal = 0,false
	local data = Data.get(player)
	local previousBest = data and data.records[Rules.recordKey(level)]
	if not practiceMode then
		coins,personal = Data.finish(player,level,time,r.perfect,resultCount,duel)
	end
	if duel then victor = player.DisplayName end
	r.result = {
		place=resultCount,time=time,hp=r.hp,coins=coins,record=personal,practice=practiceMode,
		advanced=tournament and not duel, champion=duel, completed=true,
		perfect=r.perfect, previousBest=not practiceMode and previousBest or nil,
		deliveries=not practiceMode and data and data.deliveries or nil,
	}
	table.insert(results,{name=player.DisplayName,time=time,place=resultCount})
	publishFinish(player,r)
	move(player,Vector3.new(course.x+math.clamp((resultCount-6)*2,-12,12),3.65,course.finish+5),true)
end

local function crown(player,r,reason)
	if victor or not contenders[player] then return end
	victor = player.DisplayName
	local result = r.result
	if not result then
		r.finished, r.zone = true, nil
		resultCount += 1
		local elapsed = math.min(ends,now(workspace)) - r.attemptStarted
		result = {place=1,hp=r.hp,coins=0,time=elapsed,completed=false}
		r.result = result
		table.insert(results,{name=player.DisplayName,time=elapsed,place=1,completed=false})
		move(player,Vector3.new(course.x,3.65,course.finish+5),true)
	end
	result.champion, result.advanced, result.reason = true, false, reason
	result.coins += Data.crown(player)
	publishFinish(player,r)
end

local function checkDuel()
	if not duel or victor then return end
	local survivor, entry
	for player,r in racers do
		if not r.finished then
			if survivor then return end
			survivor,entry = player,r
		end
	end
	if survivor then crown(survivor,entry,"Last racer standing") end
end

local tickAccumulator, hudAccumulator, boardAccumulator = 0,0,0
Run.Heartbeat:Connect(function(dt)
	tickAccumulator += dt
	hudAccumulator += dt
	boardAccumulator += dt
	if tickAccumulator < 1/30 then return end
	tickAccumulator %= 1/30
	local at = now(workspace)
	if stage == "Race" and course then
		local candidates = {}
		for player,r in racers do
			if r.finished then continue end
			local root = rootOf(player)
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health <= 0 and not r.recovering then
				failedAttempt(player,r,"Character reset",at)
			end
			if r.finished or not root or not humanoid or humanoid.Health <= 0 then continue end
			if r.recovering then
				if at >= r.penaltyUntil then restartPractice(player,r,at) end
				continue
			end
			local p = root.Position
			if p.Y < (course.fallY or -8.3) then
				damage(player,r,3,"fall")
				continue
			end
			local previous = r.previous
			local previousTime = r.lastSample
			r.previous,r.lastSample=p,at
			-- Discard implausible jumps, then validate course travel in route order.
			local speedAge = at-(r.speedAt or at)
			local sustained = speedAge >= 0.8 and (p.Z-r.speedOrigin.Z) > 14 + speedAge*27
			if (p-previous).Magnitude > math.max(14,(at-previousTime)*60) or sustained then
				local back = if sustained then r.speedOrigin else previous
				move(player,back,false)
				r.previous,r.speedOrigin,r.speedAt=back,back,at
				continue
			end
			if not r.speedAt or speedAge >= 0.8 then r.speedOrigin,r.speedAt=p,at end
			local gate = course.route[r.routeIndex]
			if gate then
				if Rules.crossing(previous,p,gate.z,gate.x,gate.width,gate.minY,gate.maxY) then
					r.routeIndex += 1
					gate = course.route[r.routeIndex]
				end
			else
				local fraction = Rules.crossing(previous,p,course.finish,course.x,15.8,0.5,12.5)
				if fraction and r.hp > 0 then
					local arrival = previousTime + (at-previousTime)*fraction
					if arrival <= ends then table.insert(candidates,{player=player,r=r,arrival=arrival}) end
				end
			end
			r.progress = math.clamp(p.Z,course.z,gate and gate.z or course.finish)
			r.zone = zoneFor(root)
		end
		table.sort(candidates,function(a,b)
			if a.arrival == b.arrival then return a.player.UserId < b.player.UserId end
			return a.arrival < b.arrival
		end)
		for _, entry in candidates do
			if resultCount == slots then break end
			finish(entry.player,entry.r,entry.arrival-entry.r.attemptStarted)
		end
		if resultCount == slots then
			for player, r in racers do
				if not r.finished then eliminate(player,r,"All finish slots claimed") end
			end
		else
			Obstacles.update(course,at-started,racers,damage)
			checkDuel()
		end
		if hudAccumulator >= 0.2 then
			hudAccumulator = 0
			local ranked = {}
			for player,r in racers do
				if not r.finished then table.insert(ranked,{player=player,r=r}) end
			end
			table.sort(ranked,function(a,b)
				if a.r.progress ~= b.r.progress then return a.r.progress>b.r.progress end
				return a.player.UserId < b.player.UserId
			end)
			for place, entry in ranked do
				local r=entry.r
				send(entry.player,"Race",{
					hp=r.hp, place=resultCount+place, total=entrants, zone=r.zone ~= nil,
					cooldown=r.cooldown, progress=progress(r), slots=slots, qualified=resultCount,
					recover=r.recovering and r.penaltyUntil or 0,
				})
			end
		end
	elseif stage == "Countdown" and course then
		Obstacles.update(course,0,{},damage)
	end
	Obstacles.update(demo,at % 10000,{},damage)
	if boardAccumulator >= 3 then
		boardAccumulator = 0
		local board = {}
		for player, session in Data.sessions do
			if player.Parent == Players then table.insert(board,{name=player.DisplayName,wins=session.data.wins}) end
		end
		table.sort(board,function(a,b) return a.wins>b.wins end)
		local lines={"SERVER LEADERS"}
		for i=1,math.min(3,#board) do table.insert(lines,("%d   %s   /   %d wins"):format(i,board[i].name,board[i].wins)) end
		leaderboard.Text=table.concat(lines,"\n")
		for i, marker in podium do
			marker.Text = board[i] and ("%d  %s"):format(i,board[i].name) or tostring(i)
		end
	end
end)

local function waitPhase()
	while now(workspace) < deadline do task.wait(0.1) end
end

local function ready(list)
	local found = {}
	for player in list do
		local root = rootOf(player)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if Data.get(player) and not shopping[player] and root and hum and hum.Health > 0 then table.insert(found,player) end
	end
	table.sort(found,function(a,b) return a.UserId < b.UserId end)
	return found
end

local function qualifiedPlayers()
	local advancing = {}
	for player,r in racers do
		if contenders[player] and r.result and r.result.advanced then
			table.insert(advancing,{player=player,place=r.result.place})
		end
	end
	table.sort(advancing,function(a,b) return a.place < b.place end)
	local players = {}
	for _, entry in advancing do table.insert(players,entry.player) end
	return players
end

local function settleDuel()
	if not duel or victor then return end
	local leader, best
	local tied = false
	for player,r in racers do
		if r.finished then continue end
		if not best or r.progress > best.progress or (r.progress == best.progress and r.hp > best.hp) then
			leader,best,tied = player,r,false
		elseif r.progress == best.progress and r.hp == best.hp then
			tied = true
		end
	end
	if tied then return "Final tied at the time limit" end
	if leader then
		crown(leader,best,"Led when time ran out")
		return "Lost the final tiebreak"
	end
end

local function runHeat(group,map,slotCount,final)
	level,entrants,slots,duel = map,#group,slotCount,final
	results,resultCount = {},0
	course = Courses.course(level,0,420)
	finishDisplay()
	local at = now(workspace)
	for i,player in group do
		local row = math.floor((i-1)/6)
		local rowSize = math.min(6,#group-row*6)
		local offset = ((i-1)%6-(rowSize-1)/2)*4.5
		local spot = Vector3.new(course.x+offset,3.65,course.z-4-row*4)
		racers[player] = {hp=3,routeIndex=1,spawn=spot,previous=spot,lastSample=at,
			progress=course.z,immune=at+Config.countdown+1,cooldown=0,perfect=true}
		queue[player],practiceQueue[player] = nil,nil
		move(player,spot,true)
		Eggs.attach(player,Data.get(player),3)
	end
	phase("Preparation",0.65)
	waitPhase()
	phase("Countdown",Config.countdown)
	waitPhase()
	started = now(workspace)
	ends = started+Levels[level].time
	local live = 0
	for player,r in racers do
		live += 1
		r.attemptStarted = started
		local root = rootOf(player)
		if root then
			root.Anchored = false
			r.previous,r.lastSample,r.immune = root.Position,started,started+1.5
		end
	end
	slots = math.min(slots,live)
	finishDisplay()
	phase("Race",Levels[level].time)
	while now(workspace) < ends do
		local active = false
		for _,r in racers do if not r.finished then active=true; break end end
		if not active then break end
		task.wait(0.15)
	end
	local outcome = settleDuel()
	for player,r in racers do
		if not r.finished then eliminate(player,r,outcome or "Time ran out") end
	end
	local advancing = qualifiedPlayers()
	if #advancing == 1 then crown(advancing[1],racers[advancing[1]],"Only qualifier left") end
	local continuing = #advancing > 1 and not victor
	phase("Results",if continuing then Config.heatResults else Config.results)
	waitPhase()
	advancing = qualifiedPlayers()
	if continuing and #advancing == 1 then
		crown(advancing[1],racers[advancing[1]],"Only qualifier left")
		phase("Results",Config.heatResults)
		waitPhase()
	end
	if victor then advancing = {} end
	if #advancing < 2 then phase("Returning",0.5) end
	for player in racers do
		move(player,lobby,false)
		local data = Data.get(player)
		if data then Eggs.attach(player,data,3) end
	end
	table.clear(racers)
	Obstacles.cleanup(course)
	course.model:Destroy()
	course = nil
	if stage == "Returning" then waitPhase() end
	return advancing
end

local function runTournament(group)
	tournament = true
	local starting = #group
	for _,player in group do
		contenders[player] = true
		queue[player] = nil
	end
	mapPlan = Rules.drawMaps(random)
	draftStarted = now(workspace)
	phase("Draft",Config.draft)
	waitPhase()
	local available = {}
	for _,player in group do
		if contenders[player] then table.insert(available,player) end
	end
	group = available
	if #group < 2 then
		tournament = false
		table.clear(contenders)
		local player = group[1]
		if player then runHeat(group,selected[player] or 1,1,false) end
		return
	end
	for index,map in mapPlan do
		heat = index
		group = runHeat(group,map,Rules.slots(starting,index,#group),false)
		if #group < 2 then return end
	end
	heat = Rules.heatCount+1
	runHeat(group,mapPlan[Rules.heatCount],1,true)
end

task.spawn(function()
	while true do
		table.clear(contenders)
		tournament,duel,heat,practiceMode = false,false,0,false
		mapPlan,draftStarted,victor = nil,nil,nil
		entrants,slots,resultCount = 0,0,0
		phase("Lobby")
		repeat task.wait(0.2) until next(queue) or next(practiceQueue)
		local group
		if next(queue) then
			phase("Intermission",Config.intermission)
			while now(workspace) < deadline and queuedCount() < Config.maxPlayers and next(queue) do task.wait(0.12) end
			group = ready(queue)
			for i=#group,Config.maxPlayers+1,-1 do group[i]=nil end
			if #group >= 2 then
				runTournament(group)
			elseif #group == 1 then
				runHeat(group,selected[group[1]] or 1,1,false)
			end
		else
			group = ready(practiceQueue)
			local player = group[1]
			if player then
				practiceMode = true
				runHeat({player},practiceQueue[player],1,false)
			end
		end
	end
end)
