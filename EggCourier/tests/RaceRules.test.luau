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

local courier = {coins=0,xp=0,wins=0,unlocked=1,records={}}
local coins, personal = Rules.complete(courier,1,39,true,1,true)
expect(coins,175)
expect(personal,true)
expect(courier.unlocked,2)
expect(courier.wins,1)
expect(courier.xp,40)
coins, personal = Rules.complete(courier,1,42,false,1,false)
expect(coins,50)
expect(personal,false)
expect(courier.records["1"],39)
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
expect(courier.records["5"],55)
expect(courier.coins,1175)
expect(#Levels,5)
expect(#Levels.future,3)
for _, level in Levels.future do expect(#level.levels,5) end
for _, level in ipairs(Levels) do
	assert(level.time >= 60 and level.time <= 120)
	for _, station in level.stations do expect(#station,2) end
end
print("Race rules and level data checks passed")
