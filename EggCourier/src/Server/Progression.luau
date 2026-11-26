local shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Economy = require(shared.EconomyConfig)
local Season = require(shared.SeasonConfig)
local Levels = require(shared.Levels)
local Rules = require(shared.RaceRules)
local Cosmetics = require(shared.Cosmetics)
local Data = require(script.Parent.Data)

local Progression = {}
local ranks = {Bronze=1, Silver=2, Gold=3}
local collections = {}
for _, egg in ipairs(Cosmetics.entries) do
	if egg.collection then
		collections[egg.collection] = collections[egg.collection] or {}
		table.insert(collections[egg.collection],egg.id)
	end
end

local function seasonData(data)
	if not data.seasons[Season.id] then
		data.seasons[Season.id] = {xp=0,premium=false,claimedFree={},claimedPremium={}}
	end
	return data.seasons[Season.id]
end

local function addXP(data, amount)
	data.xp += amount
	seasonData(data).xp += amount
end

function Progression.credit(data, id, amount)
	data.cartonCredits[id] = (data.cartonCredits[id] or 0) + (amount or 1)
end

function Progression.grantEgg(data, id, earned)
	if not Cosmetics.byId[id] or data.skins[id] then return false end
	data.skins[id] = true
	data.cartonRevision += 1
	local collection = Cosmetics.byId[id].collection
	if collection and not data.collections[collection] then
		local complete = true
		for _, required in collections[collection] do
			if not data.skins[required] then complete = false break end
		end
		if complete then
			data.collections[collection] = true
			data.titlesOwned[collection.." Collector"] = true
		end
	end
	if earned then
		data.earnedSkins[id] = true
		local total = 0
		for _ in data.earnedSkins do total += 1 end
		local reached = math.floor(total/Economy.collectionMilestone)
		if reached > (data.collectionMilestone or 0) then
			data.collectionMilestone = reached
			Progression.credit(data,"classic")
		end
	end
	return true
end

local function questBucket(data, period)
	local now = os.time()
	local calendar = if period == "daily" then math.floor(now/86400)
		elseif period == "weekly" then math.floor((now+259200)/604800)
		else 0
	local bucket = data.questStats[period]
	if not bucket or bucket.calendar ~= calendar then
		bucket = {calendar=calendar,counts={},claimed={},courses={}}
		data.questStats[period] = bucket
	end
	return bucket
end

local function note(data, metric, level)
	for _, period in {"daily","weekly","lifetime"} do
		local bucket = questBucket(data,period)
		if metric == "finishes" and period == "daily" then
			local key = tostring(level)
			if bucket.courses[key] then continue end
			bucket.courses[key] = true
		end
		bucket.counts[metric] = (bucket.counts[metric] or 0)+1
	end
end

local function questStatus(data, quest)
	local bucket = questBucket(data,quest.period)
	return {
		progress=math.min(quest.goal,bucket.counts[quest.metric] or 0),
		goal=quest.goal,claimed=bucket.claimed[quest.id] == true,
	}
end

function Progression.claimQuests(data, id)
	local total = 0
	for _, quest in ipairs(Economy.quests) do
		if id ~= "claim" and id ~= quest.id then continue end
		local status = questStatus(data,quest)
		if not status.claimed and status.progress >= quest.goal then
			questBucket(data,quest.period).claimed[quest.id] = true
			data.coins += quest.coins
			addXP(data,quest.xp)
			if quest.carton then Progression.credit(data,quest.carton) end
			total += 1
		end
	end
	return total
end

local function grantReward(data, reward)
	if reward.kind == "egg" then Progression.grantEgg(data,reward.id)
	elseif reward.kind == "carton" then Progression.credit(data,reward.id)
	elseif reward.kind == "coins" then data.coins += reward.amount
	elseif reward.kind == "trail" then data.trails[reward.id] = true
	elseif reward.kind == "title" then data.titlesOwned[reward.id] = true
	elseif reward.kind == "victory" then data.victories[reward.id] = true
	elseif reward.kind == "banner" then data.banners[reward.id] = true
	elseif reward.kind == "accessory" then data.accessories[reward.id] = true end
end

function Progression.claimSeason(data, premiumOnly)
	local state = seasonData(data)
	local count = 0
	for tier=1,Season.level(state.xp) do
		local key = tostring(tier)
		local rewards = Season.tiers[tier]
		if not premiumOnly and not state.claimedFree[key] then
			grantReward(data,rewards.free)
			state.claimedFree[key] = true
			count += 1
		end
		if state.premium and not state.claimedPremium[key] then
			grantReward(data,rewards.premium)
			state.claimedPremium[key] = true
			count += 1
		end
	end
	return count
end

function Progression.grantPremium(data, id)
	if id == "season" then
		local state = seasonData(data)
		if state.premium then return false end
		state.premium = true
		Progression.claimSeason(data,true)
		return true
	end
	local offer = Economy.collectorById[id]
	if not offer or data.entitlements[id] then return false end
	for _, egg in offer.eggs do Progression.grantEgg(data,egg) end
	for _, extra in offer.extras or {} do grantReward(data,extra) end
	data.entitlements[id] = true
	return true
end

function Progression.finish(player, result)
	local data = Data.get(player)
	local level = Levels[result.level]
	if not data or not level then return {coins=0,xp=0} end
	local mode, time = result.mode, result.time
	local recordKey = Rules.recordKey(result.level)
	local record = not data.records[recordKey] or time < data.records[recordKey]
	if record then
		data.records[recordKey] = time
		note(data,"best")
	end
	local medal
	if mode == "adventure" then
		local limit = level.time or 180
		local thresholds = level.medal or {}
		local gold = thresholds.gold or limit*Economy.medalThresholds.gold
		local silver = thresholds.silver or limit*Economy.medalThresholds.silver
		medal = if time <= gold then "Gold" elseif time <= silver then "Silver" else "Bronze"
		if medal == "Gold" then note(data,"gold",result.level) end
		local key = tostring(result.level)
		if not data.medals[key] or ranks[medal] > (ranks[data.medals[key]] or 0) then
			data.medals[key] = medal
		end
		if level.worldKey and not data.collections["medal:"..level.worldKey] then
			local complete, count = true, 0
			for i, course in ipairs(Levels) do
				if course.worldKey ~= level.worldKey or course.championship then continue end
				count += 1
				if not data.medals[tostring(i)] then complete = false break end
			end
			if complete and count > 0 then
				data.collections["medal:"..level.worldKey] = true
				Progression.credit(data,"adventure")
			end
		end
	end
	local coins = if mode == "quick" then Economy.placement(mode,result.place) else 0
	local xpKey = mode .. "Finish"
	local xp = (Economy.seasonXP[xpKey] or 0) + (result.perfect and Economy.seasonXP.perfect or 0)
	data.deliveries += 1
	data.coins += coins
	addXP(data,xp)
	if data.unlocked == result.level then data.unlocked += 1 end
	note(data,"finishes",result.level)
	if result.perfect then note(data,"perfect") end
	if mode == "quick" and result.place <= 3 then note(data,"podiums") end
	Data.summary(player)
	return {coins=coins,record=record,medal=medal,xp=xp}
end

function Progression.place(player, place, mode, raceId)
	local data = Data.get(player)
	if not data or mode ~= "royale" or not Economy.royalePlacementCoins[place] then return {coins=0,xp=0} end
	-- Main owns the per-tournament award latch. Remember the most recent ID as
	-- a second guard if a caller provides it.
	if raceId and data.placements.royale == raceId then return {coins=0,xp=0} end
	data.placements.royale = raceId
	local coins = Economy.placement(mode,place)
	local xp = Economy.seasonXP.royalePlacement
	data.coins += coins
	if place == 1 then
		data.wins += 1
		data.championships += 1
		xp += Economy.seasonXP.championship
		note(data,"championships")
	end
	if place <= 3 then note(data,"podiums") end
	addXP(data,xp)
	Data.summary(player)
	task.spawn(Data.save,player,false)
	return {coins=coins,xp=xp}
end

function Progression.relic(player, worldKey, relicId)
	local data = Data.get(player)
	if not data then return false end
	local relics = data.relics[worldKey] or {}
	if relics[relicId] then return false end
	relics[relicId] = true
	data.relics[worldKey] = relics
	local count = 0
	for _ in relics do count += 1 end
	if count == Economy.relicsPerWorld then
		Progression.credit(data, if worldKey == "galactic" then "galactic" elseif worldKey == "cloud" or worldKey == "frozen" then "enchanted" else "adventure")
	end
	addXP(data,Economy.seasonXP.relic)
	note(data,"relics")
	Data.summary(player)
	task.spawn(Data.save,player,false)
	return true
end

function Progression.summary(player)
	local data = Data.get(player)
	if not data then return nil end
	local quests = {}
	for _, quest in ipairs(Economy.quests) do quests[quest.id] = questStatus(data,quest) end
	return {
		skins=data.skins, trails=data.trails, skin=data.skin, trail=data.trail, title=data.title,
		records=data.records, deliveries=data.deliveries, coins=data.coins, legacyCoins=data.legacyCoins,
		championships=data.championships, wins=data.wins, xp=data.xp, favorites=data.favorites,
		medals=data.medals, relics=data.relics, season=seasonData(data), quests=quests,
		cartonCredits=data.cartonCredits, cartonRevision=data.cartonRevision, championCartonsOpened=data.championCartonsOpened,
		collections=data.collections, entitlements=data.entitlements, titlesOwned=data.titlesOwned,
		accessories=data.accessories, victories=data.victories, banners=data.banners,
		customTitle=data.customTitle, accessory=data.accessory, victory=data.victory, banner=data.banner,
	}
end

return Progression
