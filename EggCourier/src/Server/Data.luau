local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Rules = require(game:GetService("ReplicatedStorage"):WaitForChild("EggShared").RaceRules)
local token = Http:GenerateGUID(false)
local D = {sessions = {}}
local store

local function getStore()
	if not store then store = DataStoreService:GetDataStore("CourierProfiles_v1") end
	return store
end

local function normalize(raw)
	local data = typeof(raw) == "table" and raw or {}
	for key, fallback in {coins=0, wins=0, xp=0, unlocked=1} do
		local value = data[key]
		data[key] = if typeof(value) == "number" and value >= fallback then math.floor(value) else fallback
	end
	for _, key in {"skins","trails","records"} do
		if typeof(data[key]) ~= "table" then data[key] = {} end
	end
	data.skins.Classic = true
	if not data.skins[data.skin or ""] then data.skin = "Classic" end
	if typeof(data.title) ~= "number" then data.title = 1 end
	if typeof(data.trail) ~= "string" then data.trail = "" end
	return data
end

local function retry(operation)
	local errorMessage
	for attempt = 1, 3 do
		local ok, result = pcall(operation)
		if ok then return true, result end
		errorMessage = result
		if attempt < 3 then task.wait(attempt * 0.6) end
	end
	warn("Courier profile store:", errorMessage)
	return false, nil
end

local function key(player)
	return "u:" .. player.UserId
end

function D.load(player)
	if RunService:IsStudio() and game.GameId == 0 then
		local data = normalize(nil)
		D.sessions[player] = {data=data, temporary=true}
		return data
	end
	local ok, result = retry(function()
		return getStore():UpdateAsync(key(player), function(old)
			local envelope = typeof(old) == "table" and old or {}
			if envelope.owner and envelope.owner ~= token and (envelope.expires or 0) > os.time() then return nil end
			return {owner=token, expires=os.time()+180, data=normalize(envelope.data or (not envelope.owner and old))}
		end)
	end)
	if not result and (ok or not RunService:IsStudio()) then
		if player.Parent then player:Kick("Your courier profile is unavailable. Please rejoin in a moment.") end
		return nil
	end
	local session = {data=result and result.data or normalize(nil), temporary=result == nil}
	D.sessions[player] = session
	return session.data
end

function D.get(player)
	local session = D.sessions[player]
	return session and session.data
end

function D.save(player, release)
	local session = D.sessions[player]
	if not session then return end
	if release then session.closing = true end
	if session.saving then
		if not release then return end
		repeat task.wait(0.1) until not session.saving
		if D.sessions[player] ~= session then return end
	end
	if session.temporary then
		if release then D.sessions[player] = nil end
		return
	end
	session.saving = true
	local snapshot = table.clone(session.data)
	for _, field in {"skins","trails","records"} do snapshot[field] = table.clone(snapshot[field]) end
	local ok, result = retry(function()
		return getStore():UpdateAsync(key(player), function(old)
			if typeof(old) ~= "table" or old.owner ~= token then return nil end
			if release then return {data=snapshot} end
			return {owner=token, expires=os.time()+180, data=snapshot}
		end)
	end)
	if ok and not result and not release and player.Parent then
		player:Kick("Your courier profile moved to another server. Please rejoin.")
	end
	session.saving = false
	if release then D.sessions[player] = nil end
end

function D.summary(player)
	local data = D.get(player)
	if not data then return end
	player:SetAttribute("Coins",data.coins)
	player:SetAttribute("Wins",data.wins)
	player:SetAttribute("XP",data.xp)
	player:SetAttribute("Unlocked",data.unlocked)
end

function D.finish(player, level, time, perfect, place, competitive)
	local data = D.get(player)
	if not data then return 0, false end
	local reward, personal = Rules.complete(data,level,time,perfect,place,competitive)
	D.summary(player)
	return reward, personal
end
return D
