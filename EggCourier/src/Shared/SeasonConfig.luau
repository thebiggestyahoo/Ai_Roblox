local Cosmetics = require(script.Parent.Cosmetics)

local Season = {
	id="great-eggscape", name="The Great Eggscape", number=1, xpPerTier=180, count=50,
	premiumPassId=0, suggestedRobux=1000, tiers={},
}

local function item(kind, id, name, amount)
	return {kind=kind, id=id, name=name, amount=amount}
end

local seasonalEggs = {}
for _, egg in ipairs(Cosmetics.entries) do
	if egg.source == "season" then table.insert(seasonalEggs,egg) end
end

local freeMilestones = {
	[1]=item("carton","classic","Classic Carton"),
	[5]=item("coins",nil,"100 Egg Coins",100),
	[10]=item("carton","classic","Classic Carton"),
	[15]=item("carton","adventure","Adventure Carton"),
	[20]=item("title","Explorer","Explorer title"),
	[25]=item("coins",nil,"250 Egg Coins",250),
	[30]=item("carton","adventure","Adventure Carton"),
	[35]=item("trail","Expedition","Expedition trail"),
	[40]=item("coins",nil,"500 Egg Coins",500),
	[45]=item("carton","enchanted","Enchanted Carton"),
	[50]=item("carton","royal","Royal Carton"),
}
local accessoryNames = {"Sun Pin", "Trail Ribbon", "Jade Compass", "Star Pin", "Cloud Patch", "Crown Patch"}
local banners = {"Expedition Dawn", "Hidden Grotto", "Magma Light", "Moonrise", "Royal Violet", "Star Trail"}
local titles = {"Relic Seeker", "Canyon Scout", "Storm Sailor", "Jungle Guide", "Moon Pilot", "Royal Explorer"}
local victories = {"Carton Confetti", "Relic Spark", "Shooting Star", "Aurora Burst", "Crown Parade", "Celestial Finale"}

for tier=1,Season.count do
	local amount = 25+math.floor(tier/10)*5
	local free = freeMilestones[tier] or item("coins",nil,("%d Egg Coins"):format(amount),amount)
	local eggIndex = if tier == 50 then #seasonalEggs elseif tier % 3 == 1 then (tier+2)//3 else nil
	local egg = eggIndex and seasonalEggs[eggIndex]
	local cycle = math.ceil(tier/8)
	local premium
	if egg then
		premium=item("egg",egg.id,egg.name)
	elseif tier%4 == 0 and banners[cycle] then
		premium=item("banner",banners[cycle],banners[cycle].." banner")
	elseif tier%4 == 1 and victories[cycle] then
		premium=item("victory",victories[cycle],victories[cycle].." victory")
	elseif tier%4 == 2 and titles[cycle] then
		premium=item("title",titles[cycle],titles[cycle].." title")
	elseif accessoryNames[cycle] then
		premium=item("accessory",accessoryNames[cycle],accessoryNames[cycle])
	else
		premium=item("trail","Aurora","Aurora trail")
	end
	table.insert(Season.tiers,{free=free,premium=premium})
end

function Season.level(xp)
	return math.clamp(1+math.floor(xp/Season.xpPerTier),1,Season.count)
end

return Season
