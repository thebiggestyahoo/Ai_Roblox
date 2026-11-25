local Marketplace = game:GetService("MarketplaceService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Config = require(Shared.Config)
local Data = require(script.Parent.Data)
local Shop = {}
local random = Random.new()

function Shop.openBox(player, id)
	local data = Data.get(player)
	local box = Config.boxById[id]
	if not data or not box then return "Box unavailable" end
	local ready, nextReward = Config.boxStatus(box, data.skins, data.deliveries)
	if #ready == 0 then
		if nextReward then return ("Finish %d more races"):format(nextReward.deliveries - data.deliveries) end
		return "Box collection complete"
	end
	local reward = ready[random:NextInteger(1, #ready)]
	data.skins[reward.id] = true
	return nil, reward.id, reward.rarity
end

local function grant(player,id)
	local data = Data.get(player)
	if not data then return end
	data.skins[id] = true
	if id == "VIP" then data.trails.VIP = true end
end

local function owns(player,id,pass)
	local ok,result = pcall(Marketplace.UserOwnsGamePassAsync, Marketplace,player.UserId,pass)
	if ok and result then grant(player,id) end
	return ok, result
end

function Shop.refresh(player)
	for id, pass in Config.passes do
		if pass > 0 then owns(player,id,pass) end
	end
end

function Shop.listen(changed)
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(player, pass, purchased)
		if not purchased then return end
		for id, configured in Config.passes do
			if configured > 0 and configured == pass then
				-- This event is supplied by MarketplaceService on the server.
				grant(player,id)
				changed(player)
				break
			end
		end
	end)
end

function Shop.select(player,kind,id)
	local data = Data.get(player)
	if not data then return "Profile loading" end
	if kind == "skin" then
		local skin = Config.bySkin[id]
		if not skin then return "Unknown egg" end
		if not data.skins[id] then
			local box = Config.boxBySkin[id]
			if box then return "Earn this shell in the " .. box.name end
			local pass = Config.passes[id]
			if not pass or pass <= 0 then return "Currently unavailable" end
			local ok, owned = owns(player,id,pass)
			if not ok then return "Marketplace unavailable" end
			if not owned then return "Review the price in Roblox", pass end
		end
		data.skin = id
	elseif kind == "trail" then
		if id ~= "" and not data.trails[id] then
			local price = Config.trails[id]
			if not price or data.coins < price then return "Trail unavailable or insufficient coins" end
			data.coins -= price
			data.trails[id] = true
		end
		data.trail = id
	elseif kind == "title" then
		local number = tonumber(id)
		if not number or number % 1 ~= 0 or number > 4 or not Config.titleXP[number] or data.xp < Config.titleXP[number] then
			return "Title locked"
		end
		data.title = number
	end
	Data.summary(player)
	return "Equipped"
end
return Shop
