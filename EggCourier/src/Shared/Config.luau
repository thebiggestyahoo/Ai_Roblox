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
	CartonCommon = 0, CartonUncommon = 0, CartonRare = 0,
	CartonEpic = 0, CartonLegendary = 0, CartonMythic = 0,
}
-- Upload the original loops and cues from tools/compose_audio.py; use 0 for unavailable assets.
C.worldMusic = {temple=0, pirate=0, prehistoric=0, factory=0, frozen=0, cloud=0, neon=0, galactic=0}
C.passes = {Golden = 0, Rainbow = 0, Galaxy = 0, Royal = 0, VIP = 0}
-- Historical IDs only. Pending receipts credit the fixed-price trail balance.
-- This configuration does not enable a coin pack store.
C.legacyCoinProducts = {
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
C.trails = {Lightning = 600, Rainbow = 900}
C.titles = {"Rookie Courier", "Egg Protector", "Professional Deliverer", "Egg Master", "Egg Legend"}
C.titleXP = {0, 100, 300, 650, 1500}
C.bySkin = {}
for _, skin in C.skins do C.bySkin[skin[1]] = skin end
return C
