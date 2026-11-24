local Marketplace = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("EggShared")
local Config = require(Shared.Config)
local Data = require(script.Parent.Data)

local CoinPacks = {}
local byKey, byProduct = {}, {}

for _, pack in Config.coinPacks do
	byKey[pack.key] = pack
	local id = pack.productId
	if typeof(id) == "number" and id > 0 and id % 1 == 0
		and typeof(pack.coins) == "number" and pack.coins > 0 and pack.coins % 1 == 0 then
		if byProduct[id] ~= nil then
			byProduct[id] = false
			warn("Courier coin packs share developer product ID", id)
		else
			byProduct[id] = pack
		end
	end
end

function CoinPacks.prompt(player, packKey)
	local pack = byKey[packKey]
	if pack and byProduct[pack.productId] == pack and player.Parent == Players and Data.canPurchase(player) then
		return pack.productId
	end
	return nil
end

function CoinPacks.start(onChanged)
	Marketplace.ProcessReceipt = function(receipt)
		local pack = byProduct[receipt.ProductId]
		local id = receipt.PurchaseId
		if not pack or typeof(id) ~= "string" or id == "" then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local granted, credited = Data.grantCoinPack(player,id,pack.coins)
		if not granted then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if credited and onChanged then task.defer(onChanged,player) end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return CoinPacks
