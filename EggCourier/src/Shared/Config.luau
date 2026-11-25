local C = {}
C.maxPlayers = 15
C.intermission = 15
C.draft = 8
C.countdown = 3
C.results = 14
C.heatResults = 6
C.protection = 1.15
C.shoveCooldown = 5
C.shoveRange = 8
C.practiceRestartDelay = 1.25
C.audio = {
	Music = 0, Countdown = 0, Start = 0, Crack = 0, Break = 0, Out = 0, Restart = 0,
	Coins = 0, Shove = 0, Finish = 0, Victory = 0, Click = 0,
}
C.passes = {Golden = 0, Rainbow = 0, Galaxy = 0, Royal = 0, VIP = 0}
-- Set productId to the matching repeatable Developer Product ID in Creator Dashboard.
-- The Roblox purchase prompt displays the actual price. Keep disabled products at 0.
C.coinPacks = {
	{key = "starter", name = "Starter pack", coins = 400, suggestedRobux = 29, productId = 0},
	{key = "courier", name = "Courier pack", coins = 1000, suggestedRobux = 59, productId = 0},
	{key = "collector", name = "Collector pack", coins = 2400, suggestedRobux = 119, productId = 0},
}
C.skins = {
	{"Classic", "Classic Egg", 0, {255, 240, 210}, {255, 185, 120}},
	{"Chocolate", "Chocolate Egg", false, {113, 57, 42}, {235, 154, 98}},
	{"Watermelon", "Watermelon Egg", false, {65, 184, 92}, {255, 97, 119}},
	{"Ninja", "Ninja Egg", false, {42, 46, 72}, {244, 83, 98}},
	{"Dinosaur", "Dinosaur Egg", false, {135, 219, 75}, {40, 123, 98}},
	{"Frozen", "Frozen Egg", false, {147, 225, 255}, {61, 138, 255}},
	{"Lava", "Lava Egg", false, {255, 103, 43}, {62, 34, 81}},
	{"Cosmic", "Cosmic Champion", false, {141, 75, 226}, {82, 255, 221}},
	{"Golden", "Golden Egg", false, {255, 196, 54}, {255, 245, 140}},
	{"Rainbow", "Animated Rainbow Egg", false, {250, 120, 194}, {93, 215, 255}},
	{"Galaxy", "Galaxy Egg", false, {77, 51, 161}, {250, 118, 237}},
	{"Royal", "Royal Egg", false, {157, 54, 178}, {255, 212, 74}},
	{"VIP", "VIP Egg Courier", false, {75, 234, 221}, {255, 221, 99}},
}
C.suggestedPrices = {Golden = 49, Rainbow = 79, Galaxy = 99, Royal = 149, VIP = 199}
C.trails = {Lightning = 600, Rainbow = 900}
C.titles = {"Rookie Courier", "Egg Protector", "Professional Deliverer", "Egg Master", "Egg Legend"}
C.titleXP = {0, 100, 300, 650, 1500}
C.boxes = {
	{id = "field", name = "Field Box", color = "a8e378", rewards = {
		{id = "Chocolate", rarity = "Common", deliveries = 1},
		{id = "Watermelon", rarity = "Common", deliveries = 3},
	}},
	{id = "hazard", name = "Hazard Box", color = "7ed8fb", rewards = {
		{id = "Ninja", rarity = "Rare", deliveries = 5},
		{id = "Dinosaur", rarity = "Rare", deliveries = 8},
	}},
	{id = "elemental", name = "Elemental Box", color = "d2a6ff", rewards = {
		{id = "Frozen", rarity = "Epic", deliveries = 12},
		{id = "Lava", rarity = "Legendary", deliveries = 16},
	}},
}

function C.boxStatus(box, skins, deliveries)
	local ready, nextReward, remaining = {}, nil, 0
	for _, reward in ipairs(box.rewards) do
		if not skins[reward.id] then
			remaining += 1
			if deliveries >= reward.deliveries then
				table.insert(ready, reward)
			elseif not nextReward then
				nextReward = reward
			end
		end
	end
	return ready, nextReward, remaining
end

C.bySkin = {}
for _, skin in C.skins do C.bySkin[skin[1]] = skin end
C.boxById, C.boxBySkin = {}, {}
for _, box in ipairs(C.boxes) do
	C.boxById[box.id] = box
	for _, reward in ipairs(box.rewards) do
		C.boxBySkin[reward.id] = {name = box.name, rarity = reward.rarity}
	end
end
return C
