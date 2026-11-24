local Rules = {}

function Rules.crossing(previous, current, line, center, width, minY, maxY)
	if previous.Z >= line or current.Z < line then return nil end
	local fraction = (line-previous.Z)/(current.Z-previous.Z)
	local x = previous.X + (current.X-previous.X)*fraction
	local y = previous.Y + (current.Y-previous.Y)*fraction
	if math.abs(x-center) <= width and y >= (minY or 0.5) and y <= (maxY or 8.5) then return fraction end
	return nil
end

function Rules.slots(entrants)
	if entrants <= 1 then return entrants end
	return math.min(entrants - 1, math.ceil(entrants * 0.6))
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
