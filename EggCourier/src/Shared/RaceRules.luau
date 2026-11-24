local Rules = {}

function Rules.crossing(previous, current, line, center, width, minY, maxY)
	if previous.Z >= line or current.Z < line then return nil end
	local fraction = (line-previous.Z)/(current.Z-previous.Z)
	local x = previous.X + (current.X-previous.X)*fraction
	local y = previous.Y + (current.Y-previous.Y)*fraction
	if math.abs(x-center) <= width and y >= (minY or 0.5) and y <= (maxY or 8.5) then return fraction end
	return nil
end

local cuts = {12, 9, 6, 3, 2}
Rules.heatCount = #cuts

function Rules.slots(starting, heat, remaining)
	local cut = cuts[heat]
	if not cut then return 1 end
	return math.min(remaining, math.max(2, math.ceil(starting * cut / 15)))
end

function Rules.drawMaps(random)
	local opening = random:NextInteger(1,2)
	-- The catalog is ordered by difficulty. Draw three distinct middle courses.
	local middle = {3,4,5,6,7}
	for i=1,3 do
		local j = random:NextInteger(i,#middle)
		middle[i], middle[j] = middle[j], middle[i]
	end
	local chosen = {middle[1],middle[2],middle[3]}
	table.sort(chosen)
	return {opening,chosen[1],chosen[2],chosen[3],random:NextInteger(8,9)}
end

function Rules.recordKey(level)
	return "knockout:" .. level
end

function Rules.complete(data, level, time, perfect, place, competitive)
	local record = Rules.recordKey(level)
	local personal = not data.records[record] or time < data.records[record]
	if personal then data.records[record] = time end
	local reward = 50 + (perfect and 25 or 0)
	if competitive then
		reward += ({100,75,50})[place] or 0
		if place == 1 then data.wins += 1 end
	end
	if data.unlocked == level then
		data.unlocked += 1
		if level == 5 then reward += 500 end
	end
	data.xp += 30 + (perfect and 10 or 0)
	data.coins += reward
	return reward, personal
end
return Rules
