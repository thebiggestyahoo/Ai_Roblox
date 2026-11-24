local C = {}
C.maxPlayers = 12
C.intermission = 15
C.voting = 8
C.countdown = 3
C.results = 14
C.protection = 1.15
C.shoveCooldown = 5
C.shoveRange = 8
C.practiceRestartDelay = 1.25
C.audio = {
	Music = 0, Countdown = 0, Start = 0, Crack = 0, Break = 0, Out = 0, Restart = 0,
	Coins = 0, Shove = 0, Finish = 0, Victory = 0, Click = 0,
}
C.passes = {Golden = 0, Rainbow = 0, Galaxy = 0, Royal = 0, VIP = 0}
C.skins = {
	{"Classic", "Classic Egg", 0, {255, 240, 210}, {255, 185, 120}},
	{"Chocolate", "Chocolate Egg", 250, {113, 57, 42}, {235, 154, 98}},
	{"Watermelon", "Watermelon Egg", 500, {65, 184, 92}, {255, 97, 119}},
	{"Ninja", "Ninja Egg", 750, {42, 46, 72}, {244, 83, 98}},
	{"Dinosaur", "Dinosaur Egg", 1000, {135, 219, 75}, {40, 123, 98}},
	{"Frozen", "Frozen Egg", 1500, {147, 225, 255}, {61, 138, 255}},
	{"Lava", "Lava Egg", 2000, {255, 103, 43}, {62, 34, 81}},
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
C.bySkin = {}
for _, skin in C.skins do C.bySkin[skin[1]] = skin end
return C
