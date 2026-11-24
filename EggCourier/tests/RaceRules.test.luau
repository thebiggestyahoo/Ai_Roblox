local Rules = require("../src/Shared/RaceRules")
local Levels = require("../src/Shared/Levels")
local function point(x,y,z)
	return {X=x,Y=y,Z=z}
end
local function expect(actual, expected)
	assert(actual == expected, ("expected %s, got %s"):format(tostring(expected),tostring(actual)))
end

expect(Rules.crossing(point(0,4,7),point(0,4,9),8,0,12),0.5)
expect(Rules.crossing(point(0,4,9),point(0,4,7),8,0,12),nil)
expect(Rules.crossing(point(0,4,8),point(0,4,9),8,0,12),nil)
expect(Rules.crossing(point(20,4,7),point(20,4,9),8,0,12),nil)
expect(Rules.crossing(point(0,10,7),point(0,10,9),8,0,12),nil)
expect(Rules.crossing(point(11,4,7),point(13,4,9),8,0,12),0.5)
expect(Rules.crossing(point(0,10,7),point(0,10,9),8,0,12,0.5,11),0.5)

local remaining = 15
for heat, slots in {12,9,6,3,2,1} do
	expect(Rules.slots(15,heat,remaining),slots)
	remaining = slots
end
expect(Rules.slots(15,2,5),5)
expect(Rules.slots(8,1,8),7)
expect(Rules.slots(2,5,2),2)
expect(Rules.slots(2,6,2),1)

local random = {seed=563}
function random:NextInteger(low, high)
	self.seed = (self.seed * 48271) % 2147483647
	return low + self.seed % (high-low+1)
end
local plans = {}
for _=1,250 do
	local draft = Rules.drawMaps(random)
	expect(#draft,5)
	assert(draft[1] <= 2 and draft[5] >= 8)
	for i=2,#draft do assert(draft[i] > draft[i-1] and Levels[draft[i]]) end
	plans[table.concat(draft,",")] = true
end
local planCount = 0
for _ in plans do planCount += 1 end
expect(planCount,40)

local courier = {coins=0,xp=0,wins=0,unlocked=1,records={["1"]=21}}
local coins, personal = Rules.complete(courier,1,39,true,1,true)
expect(coins,175)
expect(personal,true)
expect(courier.unlocked,2)
expect(courier.wins,1)
expect(courier.xp,40)
coins, personal = Rules.complete(courier,1,42,false,1,false)
expect(coins,50)
expect(personal,false)
expect(courier.records["1"],21)
expect(courier.records[Rules.recordKey(1)],39)
expect(courier.unlocked,2)
expect(courier.wins,1)
coins, personal = Rules.complete(courier,2,48,false,2,true)
expect(coins,125)
expect(personal,true)
expect(courier.unlocked,3)
expect(Rules.complete(courier,3,49,true,3,true),125)
expect(Rules.complete(courier,4,52,false,4,true),50)
expect(Rules.complete(courier,5,56,true,1,false),575)
expect(courier.unlocked,6)
expect(Rules.complete(courier,5,55,true,1,false),75)
expect(courier.records[Rules.recordKey(5)],55)
expect(courier.coins,1175)
expect(#Levels,9)
local islands = {}
for _, level in ipairs(Levels) do
	assert(level.time >= 60 and level.time <= 120)
	assert(#level.sections >= 6)
	assert(#level.island > 0 and #level.rating > 0)
	islands[level.island] = true
end
local islandCount = 0
for _ in islands do islandCount += 1 end
expect(islandCount,5)
print("Race rules and level data checks passed")
