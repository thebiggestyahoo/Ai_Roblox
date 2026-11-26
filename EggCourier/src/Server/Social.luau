local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("EggShared")
local Data = require(script.Parent.Data)

local Social = {}
local PARTY_LIMIT = 5
local INVITE_DURATION = 25
local museumDecorations = {velvet=true, ocean=true, sunset=true}

function Social.start(options)
	local remote = Instance.new("RemoteEvent")
	remote.Name = "CourierSocial"
	local groups, invites, requests, relationships = {}, {}, {}, {}

	local function deliver(player, kind, payload)
		if player.Parent == Players then remote:FireClient(player, kind, payload) end
	end

	local function notice(player, message)
		deliver(player, "Notice", message)
	end

	local function publicPlayer(player)
		local data = Data.get(player)
		return {
			id = player.UserId, name = player.DisplayName,
			skin = data and data.skin or "Classic",
			racing = player:GetAttribute("CourseRacing") == true,
		}
	end

	local function snapshot(player)
		local members, inbound, roster = {}, {}, {}
		local group = groups[player]
		if group then
			for _, member in group.members do table.insert(members, publicPlayer(member)) end
		end
		for sender, expiry in invites[player] or {} do
			if expiry > os.clock() and sender.Parent == Players then
				table.insert(inbound, publicPlayer(sender))
			end
		end
		for _, candidate in Players:GetPlayers() do
			if candidate ~= player and Data.get(candidate) then
				table.insert(roster, publicPlayer(candidate))
			end
		end
		table.sort(roster, function(a, b)
			if a.name == b.name then return a.id < b.id end
			return a.name < b.name
		end)
		deliver(player, "Party", {
			leader = group and group.members[1].UserId or player.UserId,
			members = members, invites = inbound, roster = roster,
			limit = PARTY_LIMIT,
		})
	end

	local function update(group)
		for _, member in group.members do snapshot(member) end
	end

	local function removeMember(player)
		local group = groups[player]
		if not group then return end
		groups[player] = nil
		local index = table.find(group.members, player)
		if index then table.remove(group.members, index) end
		update(group)
	end

	local function isFriend(player, target)
		if player == target then return true end
		-- Local multi-client tests use simulated accounts.
		if RunService:IsStudio() and (player.UserId < 0 or target.UserId < 0) then return true end
		local playerCache = relationships[player]
		local cached = playerCache and playerCache[target]
		if cached and cached.expires > os.clock() then return cached.allowed end
		local ok, allowed = pcall(player.IsFriendsWith, player, target.UserId)
		if player.Parent == Players and target.Parent == Players then
			playerCache = relationships[player] or {}
			relationships[player] = playerCache
			playerCache[target] = {expires = os.clock() + (ok and 30 or 3), allowed = ok and allowed == true}
		end
		return ok and allowed == true
	end

	local function hasAccess(player, target)
		local group = groups[player]
		local allowed = player == target or (group and group == groups[target]) or isFriend(player, target)
		return allowed and player.Parent == Players and target.Parent == Players
	end

	local function targetOf(id)
		if typeof(id) ~= "number" or id ~= math.floor(id) or math.abs(id) > 2^53 then return nil end
		local target = Players:GetPlayerByUserId(id)
		return target and Data.get(target) and target or nil
	end

	local function isAvailable(player)
		return player.Parent == Players and Data.get(player) ~= nil and options.canUse(player)
	end

	local function displayedSlots(data)
		local cabinet = data.museum or {}
		local slots = {}
		for slot = 1, 4 do
			local skin = cabinet[tostring(slot)]
			if typeof(skin) == "string" and data.skins[skin] then
				slots[tostring(slot)] = skin
			end
		end
		-- First-time visitors see owned favorites until the owner arranges a display.
		if not cabinet.arranged and next(slots) == nil then
			local favorites = {}
			for skin, favorite in data.favorites or {} do
				if favorite and data.skins[skin] then
					table.insert(favorites, skin)
				end
			end
			table.sort(favorites)
			if data.skin and not table.find(favorites, data.skin) then table.insert(favorites, 1, data.skin) end
			for slot = 1, math.min(4, #favorites) do slots[tostring(slot)] = favorites[slot] end
		end
		return slots
	end

	local function museum(owner, visitor)
		local data = Data.get(owner)
		if not data then return end
		local decoration = data.museum and data.museum.decoration
		local medals, records, collections = 0, 0, 0
		local ribbons = {gold=0, silver=0, bronze=0}
		for _, medal in data.medals or {} do
			local rank = typeof(medal) == "string" and string.lower(medal) or nil
			if rank and ribbons[rank] ~= nil then
				medals += 1
				ribbons[rank] += 1
			end
		end
		for _ in data.records or {} do records += 1 end
		for _, collection in data.collections or {} do if collection then collections += 1 end end
		deliver(visitor, "Museum", {
			owner = publicPlayer(owner), editable = owner == visitor, slots = displayedSlots(data),
			decoration = museumDecorations[decoration] and decoration or "velvet",
			championships = data.championships or data.wins or 0,
			medals = medals, ribbons = ribbons, records = records, collections = collections,
		})
	end

	local actions = {}
	actions.refresh = snapshot
	function actions.invite(player, id)
		local target = targetOf(id)
		if not target or target == player then return end
		if not isFriend(player, target) then
			notice(player, "Party invites are for Roblox friends in this server.")
			return
		end
		if not isAvailable(player) or not isAvailable(target) then
			notice(player, "Both players need to be in the lobby.")
			return
		end
		local group = groups[player]
		if group and group.members[1] ~= player then
			notice(player, "Only the party leader can invite.")
			return
		end
		if (group and #group.members >= PARTY_LIMIT) or groups[target] then
			notice(player, "That player or party is unavailable.")
			return
		end
		local inbound = invites[target] or {}
		invites[target] = inbound
		if (inbound[player] or 0) > os.clock() then return end
		local expiry = os.clock() + INVITE_DURATION
		inbound[player] = expiry
		snapshot(target)
		notice(target, player.DisplayName .. " sent a party invite. Open Friends to respond.")
		notice(player, "Party invite sent to " .. target.DisplayName .. ".")
		task.delay(INVITE_DURATION, function()
			if invites[target] == inbound and inbound[player] == expiry then
				inbound[player] = nil
				snapshot(target)
			end
		end)
	end

	function actions.accept(player, id)
		local sender = targetOf(id)
		local inbound = invites[player]
		if not sender or not inbound or (inbound[sender] or 0) <= os.clock() then
			notice(player, "That invite has expired.")
			return
		end
		if groups[player] or not isAvailable(player) or not isAvailable(sender) then
			notice(player, "Both players need to be available in the lobby.")
			return
		end
		local group = groups[sender]
		if group and (group.members[1] ~= sender or #group.members >= PARTY_LIMIT) then
			notice(player, "That party is unavailable.")
			return
		end
		invites[player] = nil
		if not group then
			group = {members = {sender}}
			groups[sender] = group
		end
		groups[player] = group
		table.insert(group.members, player)
		update(group)
		notice(player, "Joined " .. sender.DisplayName .. "’s party.")
	end

	function actions.decline(player, id)
		local sender = targetOf(id)
		if sender and invites[player] then invites[player][sender] = nil end
		snapshot(player)
	end

	function actions.leave(player)
		if not isAvailable(player) then
			notice(player, "Return to the lobby before leaving your party.")
			return
		end
		removeMember(player)
		snapshot(player)
	end

	function actions.queue(player, request)
		if typeof(request) ~= "table" then return end
		local mode, course, private = request.mode, request.course, request.private == true
		if mode ~= "royale" and mode ~= "quick" then return end
		if typeof(course) ~= "number" or course < 1 or course ~= math.floor(course) then return end
		local group = groups[player]
		if not group or group.members[1] ~= player then return end
		local live = table.clone(group.members)
		for _, member in live do
			if not isAvailable(member) then
				notice(player, "All party members need to be available in the lobby.")
				return
			end
		end
		local ok, message = options.queue(live, mode, course, private and mode == "quick")
		if not ok then
			notice(player, message or "The party could not join the queue.")
			return
		end
		for _, member in live do
			notice(member, message or "Your party joined the race queue.")
		end
	end

	function actions.spectate(player, id)
		local target = targetOf(id)
		if not target or target == player or not hasAccess(player, target) or not isAvailable(player)
			or not options.canSpectate(player, target) then
			notice(player, "Choose a friend who is currently racing.")
			return
		end
		deliver(player, "Spectate", target.UserId)
	end

	function actions.museum(player, id)
		local owner = if id == nil then player else targetOf(id)
		if owner and hasAccess(player, owner) and isAvailable(player) then
			museum(owner, player)
		else
			notice(player, "Visit a friend’s museum from the lobby.")
		end
	end

	function actions.pedestal(player, request)
		if typeof(request) ~= "table" or not isAvailable(player) then return end
		local slot = request.slot
		local skin = request.skin
		local data = Data.get(player)
		if typeof(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > 4
			or typeof(skin) ~= "string" or (skin ~= "" and data.skins[skin] ~= true) then return end
		local cabinet = displayedSlots(data)
		cabinet.decoration = data.museum and data.museum.decoration
		cabinet.arranged = true
		cabinet[tostring(slot)] = if skin == "" then nil else skin
		data.museum = cabinet
		museum(player, player)
		task.defer(Data.save, player, false)
	end

	function actions.decorate(player, decoration)
		if typeof(decoration) ~= "string" or not museumDecorations[decoration] or not isAvailable(player) then return end
		local data = Data.get(player)
		local cabinet = table.clone(data.museum or {})
		cabinet.decoration = decoration
		data.museum = cabinet
		museum(player, player)
		task.defer(Data.save, player, false)
	end

	remote.OnServerEvent:Connect(function(player, action, payload)
		if typeof(action) ~= "string" or #action > 12 or not actions[action] then return end
		local clock = os.clock()
		local limits = requests[player] or {}
		requests[player] = limits
		local bucket = if action == "refresh" then "refresh" elseif action == "invite" then "invite" else "interaction"
		if (limits[bucket] or 0) > clock then return end
		limits[bucket] = clock + (if action == "invite" then 1.5 else 0.18)
		if not Data.get(player) then return end
		actions[action](player, payload)
	end)
	Players.PlayerRemoving:Connect(function(player)
		removeMember(player)
		requests[player], relationships[player], invites[player] = nil, nil, nil
		for _, cache in relationships do cache[player] = nil end
		for target, inbound in invites do
			if inbound[player] then
				inbound[player] = nil
				snapshot(target)
			end
		end
	end)
	remote.Parent = Shared
end

return Social
