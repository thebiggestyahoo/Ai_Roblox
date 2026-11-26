local Rules = require("../src/Shared/RaceRules")
local Levels = require("../src/Shared/Levels")

local function point(x,y,z)
	return {X=x,Y=y,Z=z}
end

assert(Rules.crossing(point(0,4,7),point(0,4,9),8,0,12) == 0.5)
assert(Rules.crossing(point(0,4,9),point(0,4,7),8,0,12) == nil)
assert(Rules.crossing(point(0,4,8),point(0,4,9),8,0,12) == nil)
assert(Rules.crossing(point(20,4,7),point(20,4,9),8,0,12) == nil)
assert(Rules.crossing(point(0,10,7),point(0,10,9),8,0,12) == nil)
assert(Rules.crossing(point(11,4,7),point(13,4,9),8,0,12) == 0.5)
assert(Rules.crossing(point(0,10,7),point(0,10,9),8,0,12,0.5,11) == 0.5)

assert(Rules.heatCount == 5)
local remaining = 15
for heat, slots in {12,9,6,3,1} do
	assert(Rules.slots(15,heat,remaining) == slots)
	remaining = slots
end
assert(Rules.slots(8,1,8) == 7)
assert(Rules.slots(2,4,2) == 2)
assert(Rules.slots(2,5,2) == 1)

local random = {seed=563}
function random:NextNumber()
	self.seed = (self.seed * 48271) % 2147483647
	return self.seed / 2147483647
end
function random:NextInteger(low,high)
	return low + math.floor(self:NextNumber() * (high-low+1))
end

local plans = {}
for _=1,250 do
	local draft = Rules.drawMaps(random,Levels)
	assert(#draft == 5 and draft[5] == Levels.final)
	for i=1,4 do
		local map = draft[i]
		assert(map ~= Levels.final and Levels[map])
		assert(table.find(draft,map) == i)
		if i > 1 then assert(Levels[map].stars >= Levels[draft[i-1]].stars) end
	end
	plans[table.concat(draft,",")] = true
end
local planCount = 0
for _ in plans do planCount += 1 end
assert(planCount > 1)

local entries = {
	{userId=10,finishPlace=2,progress=100,hp=3,active=false},
	{userId=11,finishPlace=1,progress=100,hp=1,active=false},
	{userId=12,progress=77,hp=2,active=true},
	{userId=13,progress=98,hp=0,active=false},
	{userId=14,progress=77,hp=3,active=true},
	{userId=15,progress=77,hp=3,active=true},
}
Rules.rank(entries)
for index,userId in {11,10,14,15,12,13} do assert(entries[index].userId == userId) end
print("Five-round cuts, map selection, route boundaries and placement rules passed")
