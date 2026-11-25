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
	for key, fallback in {coins=0, wins=0, xp=0, unlocked=1, deliveries=0} do
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

local function receiptLedger(envelope)
	return typeof(envelope.receipts) == "table" and envelope.receipts or {}
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
			return {
				owner=token, expires=os.time()+180, receipts=receiptLedger(envelope),
				data=normalize(envelope.data or (not envelope.owner and old)),
			}
		end)
	end)
	if not result and (ok or not RunService:IsStudio()) then
		if player.Parent then player:Kick("Your courier profile is unavailable. Please rejoin in a moment.") end
		return nil
	end
	local session = {data=result and result.data or normalize(nil), temporary=result == nil, receipts=result and receiptLedger(result)}
	D.sessions[player] = session
	return session.data
end

function D.get(player)
	local session = D.sessions[player]
	return session and session.data
end

local function beginWrite(player, session, waitForTurn, allowClosing)
	while session.saving do
		if not waitForTurn then return false end
		task.wait(0.1)
	end
	if D.sessions[player] ~= session or (session.closing and not allowClosing) then return false end
	session.saving = true
	return true
end

local function unappliedCoins(receipts, applied)
	local coins = 0
	for receiptId, amount in receipts do
		if applied[receiptId] == nil then coins += amount end
	end
	return coins
end

local function persist(player, session, release, receiptId, coinAmount)
	local snapshot = table.clone(session.data)
	for _, field in {"skins","trails","records"} do snapshot[field] = table.clone(snapshot[field]) end
	local ok, result = retry(function()
		return getStore():UpdateAsync(key(player), function(old)
			if typeof(old) ~= "table" or old.owner ~= token then return nil end
			local receipts = receiptLedger(old)
			if receiptId and receipts[receiptId] == nil then
				receipts = table.clone(receipts)
				receipts[receiptId] = coinAmount
			end
			-- A prior write can commit even when its response is lost. Carry those
			-- grants forward in every save before acknowledging them in memory.
			local savedData = table.clone(snapshot)
			savedData.coins += unappliedCoins(receipts, session.receipts)
			if release then return {data=savedData, receipts=receipts} end
			return {owner=token, expires=os.time()+180, data=savedData, receipts=receipts}
		end)
	end)
	if result then
		local receipts = receiptLedger(result)
		session.data.coins += unappliedCoins(receipts, session.receipts)
		session.receipts = receipts
	end
	session.saving = false
	return ok, result
end

function D.save(player, release)
	local session = D.sessions[player]
	if not session then return end
	if release then session.closing = true end
	if session.temporary then
		if release then D.sessions[player] = nil end
		return
	end
	if not beginWrite(player,session,release,release) then return end
	local balance = session.data.coins
	local ok, result = persist(player,session,release)
	if ok and not result and not release and player.Parent then
		player:Kick("Your courier profile moved to another server. Please rejoin.")
	end
	if release then D.sessions[player] = nil end
	if result and not release and session.data.coins ~= balance and player.Parent then D.summary(player) end
end

function D.canPurchase(player)
	local session = D.sessions[player]
	return session ~= nil and not session.temporary and not session.closing
end

function D.grantCoinPack(player, receiptId, coins)
	local session = D.sessions[player]
	if not session or session.temporary or not beginWrite(player,session,true,false) then return false end
	if session.receipts[receiptId] ~= nil then
		session.saving = false
		return true, false
	end
	local _, result = persist(player,session,false,receiptId,coins)
	if not result then return false end
	if player.Parent then D.summary(player) end
	return true, true
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
	data.deliveries += 1
	D.summary(player)
	return reward, personal
end

function D.crown(player)
	local data = D.get(player)
	if not data then return 0 end
	data.wins += 1
	data.coins += 100
	D.summary(player)
	return 100
end
return D
