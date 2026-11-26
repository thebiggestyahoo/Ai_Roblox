local Rules = {}

function Rules.crossing(previous, current, line, center, width, minY, maxY)
	if previous.Z >= line or current.Z < line then return nil end
	local fraction = (line-previous.Z)/(current.Z-previous.Z)
	local x = previous.X + (current.X-previous.X)*fraction
	local y = previous.Y + (current.Y-previous.Y)*fraction
	if math.abs(x-center) <= width and y >= (minY or 0.5) and y <= (maxY or 8.5) then return fraction end
	return nil
end

local cuts = {12, 9, 6, 3}
Rules.heatCount = #cuts + 1

function Rules.slots(starting, heat, remaining)
	local cut = cuts[heat]
	if not cut then return math.min(remaining,1) end
	return math.min(remaining, math.max(2, math.ceil(starting*cut/15)))
end

function Rules.drawMaps(random, levels)
	local candidates = {}
	for index, info in ipairs(levels) do
		if index ~= levels.final then
			table.insert(candidates,{index=index,stars=info.stars or 1,seed=random:NextNumber()})
		end
	end
	table.sort(candidates,function(a,b)
		if a.stars ~= b.stars then return a.stars < b.stars end
		if a.seed ~= b.seed then return a.seed < b.seed end
		return a.index < b.index
	end)
	assert(#candidates >= #cuts, "Egg Royale needs four qualifier maps")
	local maps = {}
	for heat = 1,#cuts do
		local min = math.floor((heat-1)*#candidates/#cuts)+1
		local max = math.floor(heat*#candidates/#cuts)
		maps[heat] = candidates[random:NextInteger(min,max)].index
	end
	maps[Rules.heatCount] = assert(levels.final, "Egg Royale needs a championship map")
	return maps
end

function Rules.recordKey(level)
	return "adventure:v1:" .. level
end

function Rules.rank(entries)
	table.sort(entries,function(a,b)
		if a.finishPlace ~= b.finishPlace then
			return (a.finishPlace or math.huge) < (b.finishPlace or math.huge)
		end
		if a.active ~= b.active then return a.active end
		if a.progress ~= b.progress then return a.progress > b.progress end
		if a.hp ~= b.hp then return a.hp > b.hp end
		return a.userId < b.userId
	end)
	return entries
end

return Rules
