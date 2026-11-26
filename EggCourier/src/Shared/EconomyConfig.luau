local Cosmetics = require(script.Parent.Cosmetics)

local Economy = {}

Economy.royalePlacementCoins = {150, 100, 75, 50, 50, 50, 40, 40, 40, 30, 30, 30, 20, 20, 20}
Economy.quickPlacementCoins = {35, 25, 20, 15, 15, 15, 10, 10, 10, 10, 10, 10, 10, 10, 10}
Economy.seasonXP = {royaleFinish = 65, royalePlacement = 85, championship = 60, quickFinish = 85, adventureFinish = 60, perfect = 20, relic = 25}
Economy.medalThresholds = {gold = 0.76, silver = 0.88}
Economy.relicsPerWorld = 3
Economy.collectionMilestone = 10

Economy.quests = {
	{id="deliver", name="Complete three courses", period="daily", metric="finishes", goal=3, coins=35, xp=35},
	{id="clean", name="Finish with an undamaged egg", period="daily", metric="perfect", goal=1, coins=25, xp=25},
	{id="personal", name="Set three personal bests", period="weekly", metric="best", goal=3, coins=80, xp=105},
	{id="gold", name="Earn two Gold medals in Adventure", period="weekly", metric="gold", goal=2, coins=70, xp=95},
	{id="explore", name="Find two hidden relics", period="lifetime", metric="relics", goal=2, coins=70, xp=95},
	{id="podium", name="Place top three five times", period="lifetime", metric="podiums", goal=5, coins=200, xp=180, carton="classic"},
	{id="championship", name="Win an Egg Royale title", period="lifetime", metric="championships", goal=1, coins=50, xp=200},
}

Economy.cartons = {
	{id="classic", name="Classic Carton", price=500, color="AEE7A5", material="Paper", rewards={}},
	{id="adventure", name="Adventure Carton", price=750, color="EDB97F", material="Wood", rewards={}},
	{id="enchanted", name="Enchanted Carton", price=1250, color="BEA4FE", material="Runes", rewards={}},
	{id="royal", name="Royal Carton", price=2000, color="FFD879", material="Velvet", rewards={}},
	{id="galactic", name="Galactic Carton", price=2500, color="82D6F3", material="Metal", rewards={}},
	{id="champion", name="Champion Carton", price=0, wins=1, color="FFE4A0", material="Trophy", rewards={}},
}

-- Assign experience game pass IDs in Creator Dashboard before enabling any offer.
-- These are one-time entitlements to a disclosed list of cosmetics.
Economy.collectors = {
	{id="starterCollector", name="Starter Collector Carton", passId=0, suggestedRobux=199, eggs={}},
	{id="pirateCollector", name="Pirate Collector Carton", passId=0, suggestedRobux=399, eggs={}},
	{id="relicCollector", name="Ancient Relic Collector Carton", passId=0, suggestedRobux=399, eggs={}},
	{id="dragonCollector", name="Dragon Collector Carton", passId=0, suggestedRobux=599, eggs={}},
	{id="galacticCollector", name="Galactic Collector Carton", passId=0, suggestedRobux=799, eggs={}},
	{id="deluxeCollector", name="Deluxe Collector Collection", passId=0, suggestedRobux=1499, eggs={}},
}
Economy.collectors[1].extras = {{kind="accessory",id="Sun Pin",name="Sun Pin egg accessory"}}
Economy.collectors[2].extras = {{kind="banner",id="Hidden Grotto",name="Hidden Grotto profile banner"}}
Economy.collectors[3].extras = {{kind="victory",id="Relic Spark",name="Relic Spark celebration"}}
Economy.collectors[4].extras = {{kind="accessory",id="Crown Patch",name="Crown Patch egg accessory"}}
Economy.collectors[5].extras = {{kind="trail",id="Aurora",name="Aurora trail"}}
Economy.collectors[6].extras = {
	{kind="victory",id="Celestial Finale",name="Celestial Finale celebration"},
	{kind="banner",id="Star Trail",name="Star Trail profile banner"},
}

Economy.directOffers = {
	{id="expeditionTrail",name="Expedition Trail",passId=0,suggestedRobux=99,eggs={},extras={
		{kind="trail",id="Expedition",name="Expedition trail"},
	}},
	{id="crownParade",name="Crown Parade Celebration",passId=0,suggestedRobux=199,eggs={},extras={
		{kind="victory",id="Crown Parade",name="Crown Parade celebration"},
	}},
	{id="compassPin",name="Jade Compass Accessory",passId=0,suggestedRobux=89,eggs={},extras={
		{kind="accessory",id="Jade Compass",name="Jade Compass egg accessory"},
	}},
	{id="explorerProfile",name="Explorer Profile Set",passId=0,suggestedRobux=149,eggs={},extras={
		{kind="title",id="Royal Explorer",name="Royal Explorer title"},
		{kind="banner",id="Expedition Dawn",name="Expedition Dawn profile banner"},
	}},
}

Economy.cartonById, Economy.collectorById, Economy.sourceOf = {}, {}, {}
for _, carton in Economy.cartons do Economy.cartonById[carton.id] = carton end
for _, offer in Economy.collectors do Economy.collectorById[offer.id] = offer end

for _, offer in Economy.directOffers do Economy.collectorById[offer.id] = offer end

local legacyPools = {
	Chocolate="classic", Watermelon="classic", Ninja="adventure", Dinosaur="adventure",
	Frozen="enchanted", Lava="enchanted", Cosmic="champion",
	Golden="royal", Rainbow="royal", Galaxy="galactic", Royal="royal", VIP="champion",
}

for _, egg in ipairs(Cosmetics.entries) do
	local source = legacyPools[egg.id] or egg.source
	Economy.sourceOf[egg.id] = source
	local carton = Economy.cartonById[source]
	local collector = Economy.collectorById[source]
	if carton then
		table.insert(carton.rewards,{id=egg.id,weight=Cosmetics.rarities[egg.rarity].weight})
	elseif collector then
		table.insert(collector.eggs,egg.id)
	end
end

function Economy.odds(carton, ownedSkins)
	local entries, weight = {}, 0
	for _, reward in ipairs(carton.rewards) do
		if not ownedSkins[reward.id] then
			weight += reward.weight
			table.insert(entries, {id=reward.id,weight=reward.weight})
		end
	end
	for _, reward in ipairs(entries) do reward.probability = reward.weight/weight end
	return entries
end

function Economy.placement(mode, place)
	local list = if mode == "royale" then Economy.royalePlacementCoins elseif mode == "quick" then Economy.quickPlacementCoins else {}
	return list[place] or 0
end

return Economy
