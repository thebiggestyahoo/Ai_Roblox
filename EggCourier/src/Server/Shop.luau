local Marketplace = game:GetService("MarketplaceService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Config = require(Shared.Config)
local Economy = require(Shared.EconomyConfig)
local Season = require(Shared.SeasonConfig)
local Cosmetics = require(Shared.Cosmetics)
local Data = require(script.Parent.Data)
local Progression = require(script.Parent.Progression)

local Shop = {}
local random = Random.new()
local passByOffer, offerByPass = {}, {}

local function register(offer, pass)
	if typeof(pass) ~= "number" or pass <= 0 or pass % 1 ~= 0 then return end
	passByOffer[offer] = pass
	if offerByPass[pass] ~= nil then
		offerByPass[pass] = false
		warn("Conflicting Egg Courier game pass ID",pass)
	else
		offerByPass[pass] = offer
	end
end

for id, offer in Economy.collectorById do register(id,offer.passId) end
register("season",Season.premiumPassId)
for id, pass in Config.passes do register("legacy:"..id,pass) end

local function grant(player, offer)
	return Data.transact(player,function(data)
		if string.sub(offer,1,7) == "legacy:" then
			local id = string.sub(offer,8)
			local changed = Progression.grantEgg(data,id)
			if id == "VIP" and not data.trails.VIP then
				data.trails.VIP = true
				changed = true
			end
			return changed
		end
		return Progression.grantPremium(data,offer)
	end)
end

local function owns(player, pass)
	return pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,pass)
end

function Shop.refresh(player)
	if not Data.canPurchase(player) then return end
	for pass, offer in offerByPass do
		if not offer then continue end
		local ok, owned = owns(player,pass)
		if ok and owned then grant(player,offer) end
	end
	Data.summary(player)
end

function Shop.listen(changed)
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,pass,purchased)
		local offer = offerByPass[pass]
		if not purchased or not offer or not Data.canPurchase(player) then return end
		local ok, owned = owns(player,pass)
		if not ok or not owned then return end
		local saved, granted = grant(player,offer)
		if saved and granted then
			Data.summary(player)
			local collector = Economy.collectorById[offer]
			local reveal = if collector and #collector.eggs > 0 then {
				id=offer, name=collector.name, eggs=collector.eggs, extras=collector.extras,
			} else nil
			changed(player,reveal)
		end
	end)
end

local function prompt(player, offer)
	if offer ~= "season" and not Economy.collectorById[offer] then return "Collector offer unavailable" end
	local pass = passByOffer[offer]
	if not pass or offerByPass[pass] ~= offer or not Data.canPurchase(player) then
		return "This offer is currently unavailable"
	end
	local ok, owned = owns(player,pass)
	if not ok then return "Roblox purchases are unavailable" end
	if owned then
		grant(player,offer)
		Data.summary(player)
		return "Already unlocked"
	end
	return "Review the price in Roblox",nil,pass
end

local function openCarton(player, quote)
	local cartonId, revision = string.match(quote,"^(%a+)|(%d+)$")
	local carton = Economy.cartonById[cartonId]
	if not carton then return "Carton unavailable" end
	local saved, changed, message = Data.transact(player,function(data)
		if tonumber(revision) ~= data.cartonRevision then return false,"Review the updated odds and try again" end
		local entries = Economy.odds(carton,data.skins)
		if #entries == 0 then return false,"Carton collection complete" end
		local voucher = (data.cartonCredits[cartonId] or 0) > 0
		if carton.wins then
			if data.championships < (data.championCartonsOpened+1)*carton.wins then
				return false,"Win an Egg Royale championship to unlock this carton"
			end
		elseif not voucher and data.coins < carton.price then
			return false,"Earn more Egg Coins to open this carton"
		end
		local sum = 0
		for _, reward in entries do sum += reward.weight end
		local pick = random:NextInteger(1,sum)
		local eggId
		for _, reward in entries do
			pick -= reward.weight
			if pick <= 0 then eggId = reward.id break end
		end
		if not eggId then return false,"Carton reward unavailable" end
		if carton.wins then data.championCartonsOpened += 1
		elseif voucher then data.cartonCredits[cartonId] -= 1
		else data.coins -= carton.price end
		Progression.grantEgg(data,eggId,true)
		return true,{id=cartonId,name=carton.name,eggs={eggId},rarity=Cosmetics.byId[eggId].rarity}
	end)
	if not saved then return "Progress is syncing" end
	if not changed then return message end
	Data.summary(player)
	return nil,message
end

local function claim(player, id, season)
	local saved, changed, count = Data.transact(player,function(data)
		local result = if season then Progression.claimSeason(data) else Progression.claimQuests(data,id)
		return result > 0,result
	end)
	if not saved then return "Progress is syncing" end
	if not changed then return "No rewards ready to claim" end
	Data.summary(player)
	return ("%d reward%s claimed"):format(count,count == 1 and "" or "s")
end

local equipFields = {
	accessory="accessories", victory="victories", banner="banners",
}

function Shop.select(player,kind,id)
	local data = Data.get(player)
	if not data then return "Profile loading" end
	if kind == "skin" then
		if not Cosmetics.byId[id] then return "Unknown egg" end
		if not data.skins[id] then return "Unlock this egg to equip it" end
		data.skin = id
	elseif kind == "favorite" then
		if not data.skins[id] then return "Unlock this egg to favorite it" end
		data.favorites[id] = if data.favorites[id] then nil else true
		task.spawn(Data.save,player,false)
		return if data.favorites[id] then "Added to favorites" else "Removed from favorites"
	elseif kind == "trail" then
		if id ~= "" and not data.trails[id] then
			local price = Config.trails[id]
			if not price then return "Trail unavailable" end
			local saved, changed = Data.transact(player,function(current)
				if current.coins+current.legacyCoins < price then return false end
				local oldCoins = math.min(price,current.legacyCoins)
				current.legacyCoins -= oldCoins
				current.coins -= price-oldCoins
				current.trails[id] = true
				return true
			end)
			if not saved then return "Progress is syncing" end
			if not changed then return "Earn more coins for this trail" end
		end
		data.trail = id
	elseif kind == "title" then
		if data.titlesOwned[id] then
			data.customTitle = id
		else
			local number = tonumber(id)
			if not number or number % 1 ~= 0 or not Config.titleXP[number] or data.xp < Config.titleXP[number] then
				return "Title locked"
			end
			data.title, data.customTitle = number,nil
		end
	elseif equipFields[kind] then
		if id ~= "" and not data[equipFields[kind]][id] then return "Cosmetic locked" end
		data[kind] = if id ~= "" then id else nil
	else
		return "Unknown cosmetic"
	end
	Data.summary(player)
	return "Equipped"
end

function Shop.action(player,key,id)
	if typeof(id) ~= "string" then return "Item unavailable" end
	if key == "carton" then return openCarton(player,id) end
	if key == "premium" then return prompt(player,id) end
	if key == "season" then
		if id == "claim" then return claim(player,id,true) end
		return "Season action unavailable"
	end
	if key == "quest" then return claim(player,id,false) end
	return Shop.select(player,key,id)
end

return Shop
