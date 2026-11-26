local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Physics = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")
local Http = game:GetService("HttpService")
local Shared = RS:WaitForChild("EggShared")
local Config = require(Shared.Config)
local Economy = require(Shared.EconomyConfig)
local Levels = require(Shared.Levels)
local Rules = require(Shared.RaceRules)
local World = require(script.Parent.World)
local Courses = require(script.Parent.Courses)
local Obstacles = require(script.Parent.Obstacles)
local Data = require(script.Parent.Data)
local Eggs = require(script.Parent.Eggs)
local Shop = require(script.Parent.Shop)
local CoinPacks = require(script.Parent.CoinPacks)
local Progression = require(script.Parent.Progression)
local Social = require(script.Parent.Social)

local remote = Instance.new("RemoteEvent")
remote.Name = "CourierEvent"
remote.Parent = Shared
local queue, practiceQueue, selected, rate = {}, {}, {}, {}
local shopping = {}
local racers = {}
local contenders, roster = {}, {}
local raceMode = "royale"
local privateRound = false
local championship, tournamentId
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
	local summary = Progression.summary(player)
	if summary then send(player,"Profile",summary) end
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

local function queuedCount(ticket)
	local count = 0
	for _, entry in queue do
		if not ticket or entry.mode == ticket.mode and entry.private == ticket.private then count += 1 end
	end
	return count
end

local function state(player)
	local r, ticket = racers[player], queue[player]
	local spectate, standings = {}, {}
	if stage == "Race" and not privateRound then
		for other, entry in racers do
			if other ~= player and not entry.finished then table.insert(spectate,other.UserId) end
		end
		table.sort(spectate)
	end
	for _, entry in roster do
		table.insert(standings,{
			userId=entry.userId, name=entry.name, skin=entry.skin, status=entry.status, place=entry.place,
		})
	end
	table.sort(standings,function(a,b)
		if a.place ~= b.place then return (a.place or math.huge) < (b.place or math.huge) end
		return a.userId < b.userId
	end)
	player:SetAttribute("CourseRacing",stage == "Race" and r ~= nil and not r.finished)
	send(player,"State",{
		stage=stage, deadline=deadline, level=level, racing=r ~= nil, queued=ticket ~= nil,
		practiceQueued=practiceQueue[player] ~= nil, selected=selected[player] or 1,
		practice=practiceMode, solo=entrants == 1, result=r and r.result,
		total=entrants, slots=slots, qualified=math.min(resultCount,slots),
		scoreboard=stage == "Results" and results or nil,
		room=roster[player] ~= nil or contenders[player] == true, tournament=tournament,
		duel=duel, heat=heat, heats=Rules.heatCount,
		draftStarted=draftStarted, maps=mapPlan, victor=victor,
		queuedCount=queuedCount(ticket), capacity=Config.maxPlayers,
		roundName=if duel then "Championship" elseif heat > 0 then "Round " .. heat elseif tournament then "Map draw" else nil,
		mode=raceMode, queueMode=ticket and ticket.mode, spectate=spectate, standings=standings,
		championship=championship,
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
		label.Text = ("%02d / %02d %s"):format(math.min(resultCount,slots),slots,duel and "CHAMPION" or tournament and "QUALIFIED" or "FINISHED")
	end
end

local function restartPractice(player,r,at)
	local d = Data.get(player)
	if not d or racers[player] ~= r or stage ~= "Race" then return end
	local checkpoint = r.checkpoint or r.spawn
	r.hp, r.recovering, r.perfect = 3, false, false
	r.immune = at + Config.protection
	r.lastHazard, r.shovedBy, r.shovedAt = nil, nil, nil
	r.routeIndex = r.checkpointIndex or 1
	r.progress, r.zone = math.max(course.z,checkpoint.Z), nil
	r.previous, r.lastSample = checkpoint, at
	r.speedOrigin, r.speedAt = checkpoint, at
	move(player,checkpoint,false)
	Eggs.attach(player,d,3)
	send(player,"FX","Restart",r.checkpoint ~= nil)
end

local function eliminate(player,r,reason)
	if r.finished then return end
	r.finished, r.recovering, r.zone = true, false, nil
	contenders[player] = nil
	local entry = roster[player]
	if entry then entry.status = "Eliminated" end
	r.result = {out=true,dnf=true,reason=reason,hp=r.hp,progress=progress(r),practice=practiceMode,mode=raceMode}
	move(player,lobby,false)
	local data = Data.get(player)
	if data then Eggs.attach(player,data,3) end
	send(player,"FX","Out",reason)
	broadcast()
end

local function releaseTicket(ticket, departing)
	if not ticket then return end
	for _, member in ticket.group do
		if queue[member] == ticket then
			queue[member] = nil
			if member ~= departing and departing then send(member,"Notice","Your party left the race queue") end
		end
	end
end

local function setTicket(group, mode, map, private)
	local ticket = {group=table.clone(group), mode=mode, map=map, private=private == true, at=now(workspace)}
	for _, player in ticket.group do
		queue[player],practiceQueue[player] = ticket,nil
	end
	return ticket
end

local function playable(map)
	return type(map) == "number" and map%1 == 0 and Levels[map] ~= nil and map ~= Levels.final
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

local function updated(player,reveal)
	profile(player)
	if reveal and not racers[player] then send(player,"BoxReward",reveal) end
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
	local r = racers[player]
	if key == "lobby" then
		if contenders[player] and (not r or not r.result or r.result.advanced) then return end
		releaseTicket(queue[player],player)
		practiceQueue[player] = nil
		if r and (r.finished or practiceMode or stage == "Results") then
			racers[player] = nil
			move(player,lobby,false)
			Eggs.attach(player,d,3)
		end
		broadcast()
		return
	end
	if contenders[player] and (not r or not r.result or r.result.advanced) then return end
	if (key == "next" or key == "queue" or key == "quick" or key == "practice") and r and r.finished then
		racers[player] = nil
		move(player,lobby,false)
		Eggs.attach(player,d,3)
	end
	if racers[player] then return end
	if key == "queue" or key == "quick" or key == "next" then
		local mode = if key == "quick" or id == "quick" then "quick" else "royale"
		releaseTicket(queue[player],player)
		setTicket({player},mode,selected[player],false)
		broadcast()
		return
	elseif key == "practice" then
		local choice = tonumber(id) or selected[player] or 1
		if playable(choice) then
			releaseTicket(queue[player],player)
			practiceQueue[player] = {map=choice, at=now(workspace)}
			broadcast()
		end
		return
	elseif key == "choose" then
		local n = tonumber(id)
		if playable(n) then selected[player] = n end
	elseif key == "aura" and d.wins > 0 then
		player:SetAttribute("WinnerAura",player:GetAttribute("WinnerAura") == false)
		Eggs.aura(player,d)
	elseif key == "Shop" or key == "Courses" then
		send(player,"Open",key)
	elseif key == "carton" or key == "season" or key == "favorite" or key == "premium"
		or key == "skin" or key == "title" or key == "trail" or key == "quest"
		or key == "accessory" or key == "victory" or key == "banner" then
		if shopping[player] then return end
		shopping[player] = true
		local message,reveal,pass = Shop.action(player,key,id)
		shopping[player] = nil
		if message then send(player,"Notice",message) end
		if reveal then send(player,"BoxReward",reveal) end
		if pass then send(player,"Pass",pass) end
		updated(player)
	end
	state(player)
end

Social.start({
	canUse=function(player)
		return not racers[player] and not contenders[player] and not queue[player] and not practiceQueue[player]
	end,
	canSpectate=function(viewer,target)
		return stage == "Race" and not privateRound and not (racers[viewer] and not racers[viewer].finished)
			and racers[target] ~= nil and not racers[target].finished
	end,
	queue=function(group, mode, map, private)
		if #group == 0 or #group > Config.maxPlayers or (mode ~= "quick" and mode ~= "royale") then
			return false,"Invalid race"
		end
		for _, player in group do
			if not Data.get(player) or racers[player] or contenders[player] or queue[player] or practiceQueue[player] then
				return false,"Everyone needs to be available in the lobby"
			end
		end
		if private and mode ~= "quick" then return false,"Private races use Quick Race" end
		setTicket(group,mode,playable(map) and map or selected[group[1]],private)
		broadcast()
		return true,private and "Private race queued" or "Party queued"
	end,
})

lobby,demo,leaderboard,podium = World.lobby(action)
for _, instance in workspace:GetChildren() do
	if instance.Name == "Baseplate" and instance:IsA("BasePart") then instance:Destroy() end
end

remote.OnServerEvent:Connect(function(player,key,id)
	if typeof(key) ~= "string" or #key > 16 or (id ~= nil and (typeof(id) ~= "string" or #id > 90)) then return end
	if (key == "skin" or key == "title" or key == "trail" or key == "choose" or key == "carton" or key == "premium") and id == nil then return end
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
			if r.recovering then move(player,r.checkpoint or r.spawn,true) end
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
	releaseTicket(queue[player],player)
	local entry, r = roster[player], racers[player]
	if entry then
		entry.status = "Disconnected"
		if r then entry.roundResult = r end
	end
	racers[player],practiceQueue[player],selected[player],rate[player] = nil,nil,nil,nil
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

local function award(player, place)
	local entry = roster[player]
	if not entry or entry.place then return end
	entry.place = place
	if player.Parent ~= Players or not Data.get(player) then return end
	local reward = Progression.place(player,place,"royale",tournamentId) or {}
	local r = racers[player]
	if r and r.result then
		r.result.tournamentPlace = place
		r.result.coins = (r.result.coins or 0)+(reward.coins or 0)
		r.result.xp = (r.result.xp or 0)+(reward.xp or 0)
	end
	profile(player)
	return reward
end

local function crown(player,r,reason)
	if victor then return end
	victor = player.DisplayName
	local entry = roster[player]
	entry.status = "Champion"
	local reward = award(player,1) or {}
	local d = Data.get(player)
	local championships = d and d.championships or 0
	local championCarton = Economy.cartonById.champion
	local cartons = 0
	if d and championCarton then
		local unlocked = math.floor(championships/championCarton.wins) - d.championCartonsOpened
		cartons = math.clamp(unlocked,0,#Economy.odds(championCarton,d.skins))
	end
	r.result.champion,r.result.advanced,r.result.reason = true,false,reason
	championship = {
		userId=player.UserId,name=player.DisplayName,skin=entry.skin,
		coins=reward.coins or 0,xp=reward.xp or 0,time=r.result.time,reason=reason,
		victory=d and d.victory,banner=d and d.banner,championships=championships,championCartonsAvailable=cartons,
	}
	player:SetAttribute("WinnerAura",true)
	if d then
		Eggs.aura(player,d)
		Eggs.celebrate(player,d)
	end
end

local function claimUnfinishedChampion(player,r,reason)
	r.finished,r.finishPlace,r.zone = true,1,nil
	r.result = {place=1,hp=r.hp,coins=0,completed=false,mode=raceMode}
	crown(player,r,reason)
	resultCount = 1
	table.insert(results,{name=player.DisplayName,place=1,completed=false,userId=player.UserId})
	finishDisplay()
	finishBurst(rootOf(player))
	send(player,"FX","Finish",r.result)
end

local function finish(player,r,time)
	r.finished, r.zone = true, nil
	resultCount += 1
	r.finishPlace = resultCount
	local entry = roster[player]
	if entry then entry.status = duel and "Finished" or "Qualified" end
	local data = Data.get(player)
	local previousBest = data and data.records[Rules.recordKey(level)]
	local reward = if privateRound then {} else Progression.finish(player,{
		level=level,mode=raceMode,time=time,perfect=r.perfect,place=resultCount,
	}) or {}
	r.result = {
		place=resultCount,time=time,hp=r.hp,coins=reward.coins or 0,record=reward.record == true,
		practice=practiceMode,advanced=tournament and not duel,completed=true,perfect=r.perfect,
		previousBest=previousBest,medal=reward.medal,xp=reward.xp or 0,mode=raceMode,
	}
	if duel and not victor then crown(player,r,"First across the finish") end
	table.insert(results,{name=player.DisplayName,time=time,place=resultCount,userId=player.UserId})
	finishDisplay()
	finishBurst(rootOf(player))
	send(player,"FX","Finish",r.result)
	profile(player)
	if not privateRound then task.spawn(Data.save,player,false) end
	broadcast()
	move(player,Vector3.new(course.x+math.clamp((resultCount-6)*2,-12,12),3.65,course.finish+5),true)
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
					if practiceMode and gate.checkpoint then
						r.checkpoint,r.checkpointIndex = gate.checkpoint,r.routeIndex
						send(player,"FX","Checkpoint",r.routeIndex-1)
					end
					gate = course.route[r.routeIndex]
				end
			else
				local fraction = Rules.crossing(previous,p,course.finish,course.x,course.finishWidth or 15.8,course.finishMinY or 0.5,course.finishMaxY or 12.5)
				if fraction and r.hp > 0 then
					local arrival = previousTime + (at-previousTime)*fraction
					if arrival <= ends then table.insert(candidates,{player=player,r=r,arrival=arrival}) end
				end
			end
			r.progress = math.clamp(p.Z,course.z,gate and gate.z or course.finish)
			r.bestProgress = math.max(r.bestProgress or course.z,r.progress)
			r.zone = zoneFor(root)
			if practiceMode then
				for _, relic in course.relics or {} do
					if not r.seenRelics[relic.id] and (p-relic.position).Magnitude <= (relic.radius or 4.2) then
						r.seenRelics[relic.id] = true
						if Progression.relic(player,Levels[level].worldKey,relic.id) then
							profile(player)
							send(player,"FX","Relic",relic.id)
						end
					end
				end
			end
		end
		table.sort(candidates,function(a,b)
			if a.arrival == b.arrival then return a.player.UserId < b.player.UserId end
			return a.arrival < b.arrival
		end)
		local finishCapacity = duel and entrants or slots
		for _, entry in candidates do
			if resultCount >= finishCapacity then break end
			finish(entry.player,entry.r,entry.arrival-entry.r.attemptStarted)
		end
		if resultCount >= finishCapacity then
			for player, r in racers do
				if not r.finished then eliminate(player,r,"All finish slots claimed") end
			end
		else
			Obstacles.update(course,at-started,racers,damage)
			if duel and not victor then
				local only, count
				count = 0
				for player, r in racers do
					if not r.finished then
						only = player
						count += 1
					end
				end
				if count == 1 and entrants > 1 then
					claimUnfinishedChampion(only,racers[only],"Last racer standing")
					broadcast()
				end
			end
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
					cooldown=r.cooldown, progress=progress(r), slots=slots, qualified=math.min(resultCount,slots),
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

local function readyPlayer(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return player.Parent == Players and Data.get(player) ~= nil and not shopping[player]
		and rootOf(player) ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function eligibleTicket(ticket)
	for _, player in ticket.group do
		if queue[player] ~= ticket or not readyPlayer(player) then return false end
	end
	return true
end

local function buildGroup(first)
	local tickets, seen = {}, {}
	local group = {}
	for _, ticket in queue do
		if not seen[ticket] and ticket.mode == first.mode and not ticket.private and eligibleTicket(ticket) then
			seen[ticket] = true
			table.insert(tickets,ticket)
		end
	end
	table.sort(tickets,function(a,b)
		if a.at ~= b.at then return a.at < b.at end
		return a.group[1].UserId < b.group[1].UserId
	end)
	for _, ticket in tickets do
		if #group+#ticket.group <= Config.maxPlayers then
			for _, player in ticket.group do table.insert(group,player) end
		end
	end
	return group
end

local function rankRound(group)
	local ranked = {}
	for _, player in group do
		local entry = roster[player]
		local r = racers[player] or (entry and entry.roundResult)
		if r then
			local active = player.Parent == Players and not r.finished
			table.insert(ranked,{
				player=player, userId=player.UserId, active=active, finishPlace=r.finishPlace,
				progress=r.bestProgress or r.progress, hp=r.hp, race=r,
			})
		end
	end
	return Rules.rank(ranked)
end

local function settleChampionship(ranked)
	if victor then return end
	local first = ranked[1]
	if not first or not first.active then return end
	claimUnfinishedChampion(first.player,first.race,"Led the field when time ran out")
end

local function settleRound(group)
	local ranked = rankRound(group)
	local advancing, promoted = {}, {}
	if tournament then
		if duel then
			settleChampionship(ranked)
		else
			for _, line in ranked do
				if #advancing >= slots then break end
				local player,r = line.player,line.race
				if player.Parent ~= Players or (not line.finishPlace and not line.active) then continue end
				if not line.finishPlace then
					r.finished,r.zone = true,nil
					r.result = {
						place=#advancing+1,hp=r.hp,advanced=true,completed=false,mode=raceMode,
						reason="Qualified on distance",progress=progress(r),
					}
					roster[player].status = "Qualified"
					resultCount += 1
					table.insert(results,{name=player.DisplayName,place=r.result.place,completed=false,userId=player.UserId})
				end
				table.insert(advancing,player)
				promoted[player] = true
			end
			finishDisplay()
		end
	end
	local placement = math.max(2,#advancing+1)
	for _, line in ranked do
		local player,r = line.player,line.race
		if not promoted[player] and not (r.result and r.result.champion) then
			if player.Parent == Players and not r.finished then
				eliminate(player,r,duel and "Championship ended" or "Time ran out")
			end
			if tournament then
				award(player,math.min(placement,Config.maxPlayers))
				placement += 1
			end
		end
	end
	return advancing
end

local function runHeat(group,map,slotCount,final)
	level,entrants,slots,duel = map,#group,slotCount,final
	results,resultCount = {},0
	course = Courses.course(level,0,420)
	finishDisplay()
	local at = now(workspace)
	for i,player in group do
		local offset = if #group == 1 then 0 else ((i-1)/(#group-1)-0.5)*31
		local spot = Vector3.new(course.x+offset,3.65,course.z-4)
		local r = {hp=3,routeIndex=1,spawn=spot,previous=spot,lastSample=at,
			progress=course.z,immune=at+Config.countdown+1,cooldown=0,perfect=true,seenRelics={}}
		racers[player] = r
		local entry = roster[player]
		if entry then
			entry.status,entry.roundResult = "Racing",r
		end
		queue[player],practiceQueue[player] = nil,nil
		move(player,spot,true)
		Eggs.attach(player,Data.get(player),3)
	end
	phase("Preparation",1.7)
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
			r.speedOrigin,r.speedAt = root.Position,started
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
	local advancing = settleRound(group)
	phase("Results",if #advancing>0 then Config.heatResults else Config.results)
	waitPhase()

	local output, forfeited = {}, {}
	for _, player in advancing do
		if readyPlayer(player) then
			table.insert(output,player)
		else
			table.insert(forfeited,player)
		end
	end
	for index, player in forfeited do
		contenders[player] = nil
		award(player,math.min(math.max(1,#output)+index,Config.maxPlayers))
	end
	if #output == 0 then phase("Returning",0.5) end
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
	return output
end

local function runTournament(group)
	tournament = true
	tournamentId = Http:GenerateGUID(false)
	local starting = #group
	for _,player in group do
		local data = Data.get(player)
		contenders[player] = true
		roster[player] = {userId=player.UserId,name=player.DisplayName,skin=data.skin,status="Ready"}
		queue[player] = nil
	end
	mapPlan = Rules.drawMaps(random,Levels)
	draftStarted = now(workspace)
	phase("Draft",Config.draft)
	waitPhase()
	local available, forfeited = {}, {}
	for _,player in group do
		table.insert(if readyPlayer(player) then available else forfeited,player)
	end
	for i,player in forfeited do
		contenders[player] = nil
		award(player,math.min(math.max(1,#available)+i,Config.maxPlayers))
	end
	group = available
	for index,map in mapPlan do
		if #group == 0 then break end
		local final = index == Rules.heatCount
		if #group == 1 and not final then continue end
		heat = index
		group = runHeat(group,map,Rules.slots(starting,index,#group),final)
	end
end

local function nextActivity()
	local first, adventurer
	for _, ticket in queue do
		if (not first or ticket.at < first.at) and eligibleTicket(ticket) then first = ticket end
	end
	for player, ticket in practiceQueue do
		if (not adventurer or ticket.at < practiceQueue[adventurer].at) and readyPlayer(player) then
			adventurer = player
		end
	end
	if adventurer and (not first or practiceQueue[adventurer].at < first.at) then return nil,adventurer end
	return first,nil
end

task.spawn(function()
	while true do
		table.clear(contenders)
		table.clear(roster)
		tournament,duel,heat,practiceMode,privateRound = false,false,0,false,false
		mapPlan,draftStarted,victor,championship = nil,nil,nil,nil
		entrants,slots,resultCount = 0,0,0
		raceMode = "royale"
		phase("Lobby")
		local ticket, adventurer
		repeat
			task.wait(0.2)
			ticket,adventurer = nextActivity()
		until ticket or adventurer
		if adventurer then
			practiceMode,raceMode = true,"adventure"
			runHeat({adventurer},practiceQueue[adventurer].map,1,false)
		elseif ticket.private then
			privateRound,raceMode = true,"quick"
			runHeat(ticket.group,ticket.map or 1,#ticket.group,false)
		else
			raceMode = ticket.mode
			phase("Intermission",Config.intermission)
			while now(workspace) < deadline and queuedCount(ticket) < Config.maxPlayers and queuedCount(ticket) > 0 do
				task.wait(0.12)
			end
			local group = buildGroup(ticket)
			if #group >= 2 and ticket.mode == "royale" then
				runTournament(group)
			elseif #group > 0 then
				raceMode = "quick"
				if ticket.mode == "royale" then send(group[1],"Notice","Only one racer joined. Starting Quick Race.") end
				local first = queue[group[1]]
				runHeat(group,(first and first.map) or selected[group[1]] or 1,#group,false)
			end
		end
	end
end)
