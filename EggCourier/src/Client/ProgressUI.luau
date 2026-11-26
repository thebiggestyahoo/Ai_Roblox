local Marketplace = game:GetService("MarketplaceService")
local Atlas = require(script.Parent.AdventureAtlas)
local Pages = {}
local rgb = Color3.fromHex
local passPrices = {}

local function subtitle(ctx, text)
	local message = ctx.row(text, ctx.muted, 12, nil, 40)
	message.TextWrapped = true
	message.TextTruncate = Enum.TextTruncate.None
	return message
end

local function title(ctx, text)
	return ctx.row(text,ctx.ink,16,ctx.heavy,31)
end

local function longButton(ctx, text, color, callback)
	local control = ctx.listButton(text,color,ctx.ink,callback)
	control.Size = UDim2.new(1,-7,0,42)
	return control
end

local function shellName(ctx, id)
	local skin = ctx.cosmetics.byId[id]
	return skin and skin.name or id
end

local function addPrice(control, offer, pass)
	local price = passPrices[pass]
	if typeof(price) == "number" then
		control.Text = ("%s · %d Robux"):format(offer,price)
		return
	end
	task.spawn(function()
		local ok, details = pcall(Marketplace.GetProductInfo,Marketplace,pass,Enum.InfoType.GamePass)
		if ok and typeof(details) == "table" and typeof(details.PriceInRobux) == "number" and details.IsForSale ~= false then
			passPrices[pass] = details.PriceInRobux
		end
		if control.Parent then
			local loaded = passPrices[pass]
			control.Text = loaded and ("%s · %d Robux"):format(offer,loaded) or "View Roblox offer"
		end
	end)
end

local function passButton(ctx, offer, id, pass)
	if typeof(pass) ~= "number" or pass <= 0 then
		subtitle(ctx,"Preview only · This offer is currently unavailable.")
		return
	end
	local control = longButton(ctx, "View Roblox offer",ctx.yellow,function() ctx.send("premium",id) end)
	addPrice(control,offer,pass)
end

local function earnedCarton(ctx, carton)
	local profile = ctx.profile
	local pantry = profile.cartonCredits or {}
	local odds = ctx.economy.odds(carton, profile.skins)
	local credit = pantry[carton.id] or 0
	local accent = rgb(carton.color)
	local card = ctx.append(ctx.frame(ctx.list,accent,UDim2.new(1,-7,0,61),nil,10))
	ctx.outline(card,ctx.ink,1.6)
	local box = ctx.frame(card,ctx.paper,UDim2.fromOffset(46,37),UDim2.fromOffset(10,12),8)
	ctx.outline(box,ctx.ink,1.3)
	local lock = ctx.frame(box,accent,UDim2.fromOffset(29,5),UDim2.fromOffset(8,8),2)
	lock.Rotation = -8
	ctx.label(box,"◒  ◒",ctx.ink,UDim2.fromScale(1,1),UDim2.fromOffset(0,4),13,ctx.heavy)
	ctx.left(ctx.label(card,carton.name,ctx.ink,UDim2.new(1,-76,0,24),UDim2.fromOffset(65,8),18,ctx.heavy))
	local price = if carton.wins then "Championship reward" elseif credit > 0 then ("%d vouchers available"):format(credit) else ("%d earned Egg Coins"):format(carton.price)
	ctx.left(ctx.label(card,price,ctx.ink,UDim2.new(1,-76,0,18),UDim2.fromOffset(65,33),11,ctx.digits))

	if #odds == 0 then
		subtitle(ctx,"Collection complete.")
		return
	end
	local chance = {}
	local totalWeight = 0
	for _, offer in ipairs(odds) do totalWeight += offer.weight end
	for _, offer in ipairs(odds) do
		local skin = ctx.cosmetics.byId[offer.id]
		local description = if skin then ("%s · %s"):format(skin.name,skin.rarity) else shellName(ctx,offer.id)
		table.insert(chance,("%s  %.2f%% (%d/%d)"):format(description,offer.probability*100,offer.weight,totalWeight))
	end
	for _, text in ipairs(chance) do
		local chanceRow = ctx.row(text,ctx.ink,12,nil,27)
		chanceRow.TextWrapped = true
		chanceRow.TextTruncate = Enum.TextTruncate.None
	end
	local wins = profile.championships or 0
	local championReady = wins > (profile.championCartonsOpened or 0)
	local coins = profile.coins or 0
	local claim = credit > 0 or (carton.wins and championReady) or (not carton.wins and coins >= carton.price)
	if claim then
		local label = if credit > 0 then "Use voucher" elseif carton.wins then "Claim championship carton" else ("Open for %d Egg Coins"):format(carton.price)
		longButton(ctx,label,ctx.lime,function()
			ctx.send("carton",("%s|%d"):format(carton.id,profile.cartonRevision or 0))
		end)
	elseif carton.wins then
		subtitle(ctx,"Win Egg Royale to earn this carton.")
	else
		subtitle(ctx,("%d more Egg Coins to open."):format(carton.price - coins))
	end
end

function Pages.cartons(ctx)
	ctx.row(("%d earned Egg Coins"):format(ctx.profile.coins or 0),ctx.ink,17,ctx.heavy,34)
	longButton(ctx,"View Collector Cartons",ctx.cream,function() ctx.navigate("Collectors") end)
	subtitle(ctx,"Each opening gives one new egg. Percentages are rounded. Fractions show the exact odds.")
	for _, carton in ipairs(ctx.economy.cartons) do
		earnedCarton(ctx,carton)
	end
end

local function disclose(ctx, offer)
	title(ctx,offer.name)
	local allOwned = true
	for _, id in ipairs(offer.eggs or {}) do
		ctx.row(shellName(ctx,id),ctx.ink,13,nil,25)
		if not ctx.profile.skins[id] then allOwned = false end
	end
	local entitlements = ctx.profile.entitlements or {}
	for _, item in ipairs(offer.extras or {}) do
		ctx.row(item.name or item.id,ctx.ink,13,nil,25)
		if not entitlements[offer.id] then allOwned = false end
	end
	if allOwned then
		subtitle(ctx,"In your collection.")
	else
		passButton(ctx,"View Roblox offer",offer.id,offer.passId)
	end
end

function Pages.collectors(ctx)
	longButton(ctx,"← Earned Cartons",ctx.cream,function() ctx.navigate("Cartons") end)
	subtitle(ctx,"Collector Cartons include all the cosmetics listed below.")
	for _, carton in ipairs(ctx.economy.collectors) do disclose(ctx,carton) end
	if #(ctx.economy.directOffers or {}) > 0 then
		title(ctx,"Cosmetic offers")
		for _, offer in ipairs(ctx.economy.directOffers) do disclose(ctx,offer) end
	end
end

local rewardSigns = {coins="★", xp="✦", carton="◒", egg="◉", trail="↝", title="◆", cosmetic="◇"}
local rarityByKind = {coins="Common", xp="Common", carton="Rare", trail="Epic", title="Rare", accessory="Uncommon", victory="Epic", banner="Rare"}

local function rewardCard(ctx, parent, reward, reached, claimed, premium, ownedPremium, tier, rowY, width)
	local milestone = tier == #ctx.season.tiers or tier%5 == 0
	local fill = if premium then (milestone and rgb("ffe09a") or rgb("efe3d3")) else (milestone and rgb("b7f1d3") or ctx.cream)
	local card = ctx.frame(parent,fill,UDim2.fromOffset(width-10,107),UDim2.fromOffset(6,rowY),8)
	ctx.outline(card,ctx.ink,milestone and 2 or 1)
	local icon = rewardSigns[reward.kind] or "✦"
	ctx.label(card,icon,ctx.ink,UDim2.new(1,-12,0,24),UDim2.fromOffset(6,2),18,ctx.heavy)
	local text = ctx.label(card,reward.name or "Reward",ctx.ink,UDim2.new(1,-10,0,35),UDim2.fromOffset(5,24),11,ctx.heavy)
	text.TextWrapped = true
	text.TextTruncate = Enum.TextTruncate.None
	local skin = reward.kind == "egg" and ctx.cosmetics.byId[reward.id]
	local rarity = (skin and skin.rarity) or reward.rarity or rarityByKind[reward.kind] or "Special"
	ctx.label(card,rarity,ctx.muted,UDim2.new(1,-8,0,16),UDim2.fromOffset(4,62),10,ctx.digits)
	local status = if claimed then "Claimed"
		elseif not reached then "Locked"
		elseif premium and not ownedPremium then "Premium track"
		else "Ready to claim"
	ctx.label(card,status,ctx.ink,UDim2.new(1,-8,0,19),UDim2.fromOffset(4,81),10,ctx.digits)
end

local function seasonTrack(ctx, level, earned)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "SeasonRewardTracks"
	scroll.BackgroundColor3 = ctx.ink
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1,-7,0,318)
	scroll.ScrollBarThickness = 8
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroll.ClipsDescendants = true
	scroll.Parent = ctx.list
	ctx.corner(scroll,11)
	ctx.append(scroll)
	local coordinates = {}
	local x = 4
	for index in ipairs(ctx.season.tiers) do
		local width = (index%5 == 0) and 148 or 119
		coordinates[index] = {x=x,width=width}
		x += width
	end
	scroll.CanvasSize = UDim2.fromOffset(x+5,0)
	local visible = {}
	local freeClaims, premiumClaims = earned.claimedFree or {},earned.claimedPremium or {}
	local function updateVisibleTiers()
		local viewportLeft = scroll.CanvasPosition.X
		local viewportRight = viewportLeft + math.max(240,scroll.AbsoluteSize.X)
		for index, position in ipairs(coordinates) do
			local wanted = position.x < viewportRight+135 and position.x+position.width > viewportLeft-135
			local column = visible[index]
			if column and not wanted then
				column:Destroy()
				visible[index] = nil
			elseif wanted and not column then
				local tier = ctx.season.tiers[index]
				local width = position.width
				column = ctx.frame(scroll,nil,UDim2.fromOffset(width,300),UDim2.fromOffset(position.x,6))
				visible[index] = column
				local caption = if index%5 == 0 then ("TIER %02d ★"):format(index) else ("TIER %02d"):format(index)
				ctx.label(column,caption,ctx.paper,UDim2.new(1,-5,0,22),nil,12,ctx.heavy)
				ctx.label(column,"FREE",ctx.lime,UDim2.new(1,-5,0,19),UDim2.fromOffset(0,23),10,ctx.digits)
				ctx.label(column,"PREMIUM",ctx.yellow,UDim2.new(1,-5,0,19),UDim2.fromOffset(0,159),10,ctx.digits)
				rewardCard(ctx,column,tier.free,index<=level,freeClaims[tostring(index)] or freeClaims[index],false,true,index,44,width)
				rewardCard(ctx,column,tier.premium,index<=level,premiumClaims[tostring(index)] or premiumClaims[index],true,earned.premium,index,180,width)
			end
		end
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateVisibleTiers)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateVisibleTiers)
	updateVisibleTiers()
	local actions = ctx.append(ctx.frame(ctx.list,nil,UDim2.new(1,-7,0,43)))
	local back = ctx.button(actions,"← Earlier tiers",ctx.cream,ctx.ink,function()
		scroll.CanvasPosition -= Vector2.new(math.max(120,scroll.AbsoluteSize.X-25),0)
	end)
	back.Size = UDim2.new(0.5,-4,1,0)
	local forward = ctx.button(actions,"Later tiers →",ctx.cream,ctx.ink,function()
		scroll.CanvasPosition += Vector2.new(math.max(120,scroll.AbsoluteSize.X-25),0)
	end)
	forward.Size, forward.Position = UDim2.new(0.5,-4,1,0),UDim2.new(0.5,4,0,0)
	if coordinates[level] then
		longButton(ctx,"Jump to my tier",ctx.cream,function()
			scroll.CanvasPosition = Vector2.new(coordinates[level].x-4,0)
		end)
	end
end

function Pages.season(ctx)
	local earned = ctx.profile.season or {}
	local xp = earned.xp or 0
	local level = ctx.season.level(xp)
	local count = #ctx.season.tiers
	local hero = ctx.append(ctx.frame(ctx.list,ctx.ink,UDim2.new(1,-7,0,198),nil,12))
	ctx.outline(hero,ctx.ink,2)
	local world = ctx.levels.worlds[1]
	if world then
		Atlas.preview(hero,world,UDim2.new(1,-12,0,128),UDim2.fromOffset(6,6),true)
	end
	ctx.left(ctx.label(hero,("Season %d · %s"):format(ctx.season.number,ctx.season.name),ctx.paper,
		UDim2.new(1,-22,0,27),UDim2.fromOffset(11,136),17,ctx.heavy))
	local status = if level >= count then ("All %d tiers unlocked"):format(count) else ("%d of %d tiers · %d/%d XP to next tier"):format(level,count,xp%ctx.season.xpPerTier,ctx.season.xpPerTier)
	ctx.left(ctx.label(hero,status,ctx.paper,UDim2.new(1,-22,0,18),UDim2.fromOffset(11,161),11,ctx.digits))
	local meter = ctx.frame(hero,ctx.charcoal,UDim2.new(1,-22,0,7),UDim2.fromOffset(11,184),3)
	ctx.frame(meter,ctx.yellow,UDim2.fromScale(if level>=count then 1 else xp%ctx.season.xpPerTier/ctx.season.xpPerTier,1),nil,3)
	longButton(ctx,"Claim all unlocked rewards",ctx.lime,function() ctx.send("season","claim") end)
	seasonTrack(ctx,level,earned)
	local final = ctx.season.tiers[count]
	local grandEgg = final.premium.kind == "egg" and final.premium.id or final.free.kind == "egg" and final.free.id
	if grandEgg then
		local showcase = ctx.append(ctx.frame(ctx.list,ctx.cream,UDim2.new(1,-7,0,145),nil,10))
		ctx.eggPreview(showcase,grandEgg,UDim2.new(0.42,-10,1,-16),UDim2.fromOffset(8,8))
		ctx.left(ctx.label(showcase,("TIER %d"):format(count),ctx.muted,UDim2.new(0.58,-13,0,24),UDim2.new(0.42,6,0,23),12,ctx.digits))
		local caption = ctx.left(ctx.label(showcase,shellName(ctx,grandEgg),ctx.ink,UDim2.new(0.58,-13,0,53),UDim2.new(0.42,6,0,49),18,ctx.heavy))
		caption.TextWrapped = true
	end
	if earned.premium then
		subtitle(ctx,"Premium track unlocked.")
	else
		passButton(ctx,"Preview Premium","season",ctx.season.premiumPassId)
	end
end

function Pages.quests(ctx)
	local profile = ctx.profile
	local installed = profile.quests or {}
	local sections = {daily="Daily",weekly="Weekly",lifetime="Lifetime"}
	local previous
	for _, quest in ipairs(ctx.economy.quests or {}) do
		if previous ~= quest.period then
			title(ctx,sections[quest.period] or quest.period)
			previous = quest.period
		end
		local status = installed[quest.id] or {}
		local progress = math.min(status.progress or 0,quest.goal)
		local reward = ("%d coins · %d Pass XP"):format(quest.coins or 0,quest.xp or 0)
		if quest.carton then reward ..= " · Carton" end
		local card = ctx.append(ctx.frame(ctx.list,ctx.cream,UDim2.new(1,-7,0,80),nil,9))
		ctx.left(ctx.label(card,quest.name,ctx.ink,UDim2.new(1,-20,0,25),UDim2.fromOffset(10,6),15,ctx.heavy))
		local info = if status.claimed then "Claimed" else ("%d/%d  ·  %s"):format(progress,quest.goal,reward)
		ctx.left(ctx.label(card,info,ctx.muted,UDim2.new(1,-20,0,22),UDim2.fromOffset(10,32),11,ctx.digits))
		local bar = ctx.frame(card,rgb("d8caee"),UDim2.new(1,-20,0,7),UDim2.fromOffset(10,62),3)
		ctx.frame(bar,ctx.lime,UDim2.fromScale(progress/quest.goal,1),nil,3)
	end
	longButton(ctx,"Claim completed quests",ctx.yellow,function() ctx.send("quest","claim") end)
end

return Pages
