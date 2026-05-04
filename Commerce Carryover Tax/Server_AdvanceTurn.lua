-- ---Server_AdvanceTurn_Start hook
-- ---@param game GameServerHook
-- ---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
-- function Server_AdvanceTurn_Start (game, addNewOrder)
-- end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addOrder)
	if (order.proxyType == "GameOrderEvent" and order.Message == "Received Gold") then
		--add a dummy order b/c right now gold in hand doesn't include the gold received during 'Received Gold' event (it needs to finish processing and this is currently being processed in parallel)
		--use the dummy order to trigger the real tax operation, whereby gold in hand includes the gold allocated for the following turn; then process the tax amount based on carryover amount (pre-allocation amount) but subtract from the new total gold in hand
		--this makes it so the tax is subtracted from gold in hand only, no IncomeMods are required, and thus the player can still see their normal income for the following turn
		addOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "CommerceCarryoverTax|ApplyTax"));
	elseif (order.proxyType == "GameOrderEvent" and order.Message == "CommerceCarryoverTax|ApplyTax") then
		apply_Commerce_Carryover_Tax (game, addOrder);
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
	end
end

-- ---Server_AdvanceTurn_End hook
-- ---@param game GameServerHook
-- ---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
-- function Server_AdvanceTurn_End(game, addOrder)
-- end

--apply the commerce carryover tax based on mod Settings
--this executes either during (A) Server_AdvanceTurn_Order when detecting the "Received Gold" event, or (B) during Server_AdvanceTurn_End if for some reason the tax wasn't applied during Server_AdvanceTurn_Order
--(B) is the legacy execution method, (A) is the new method but both are included in case there is a yet unknown edge case
--UPDATE: actually it only operates using (A); as it turns out 'Received Gold' despite getting processe during Server_AdvanceTurn_Order executes after all of Server_AdvanceTurn_End code is executed, so just execute during the 'Received Gold' event
--        'Received Gold' event requires Commerce to be active (else the order never gets generated) but this mod has no purpose unless Commerce is active anyhow, so just always executed during 'Received Gold' event
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function apply_Commerce_Carryover_Tax (game, addOrder)
	local intTaxStartAmount = Mod.Settings.TaxStartAmount or 0.0; --the % of carryover gold that isn't taxed, can be freely carried over to the following turn; default is 0.0 if not defined already
	local intTaxRate = Mod.Settings.TaxRate or 0.1; --the % tax rate for gold carried over; default is 0.1 if not defined already

	for playerID,objPlayer in pairs (game.ServerGame.Game.Players) do
		local intIncome = objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total;
		if (playerID == nil or game.ServerGame.LatestTurnStanding.Resources [playerID] == nil or game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold] == nil) then return; end --if playerID or the resources table is nil, just exit; maybe player is eliminated/booted?
		local intGoldInHand = game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold]; --this includes gold allocation for the following turn that was just distributed during 'Received Gold'
		local intGoldInHand_Carryover = intGoldInHand - intIncome; --subtract income from gold in hand; this is amount actually carried over into the following turn
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold].. ", income " ..objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..intGoldInHand.. ", income " ..intIncome); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards

		local intTaxableAmount = 0; --default to 0; if gold in hand exceeds the non-taxable amount, set to at least 1 but calculate the actual taxable amount
		if (intGoldInHand_Carryover > intIncome * intTaxStartAmount) then intTaxableAmount = math.max (1, math.floor (intGoldInHand_Carryover - (intIncome * intTaxStartAmount) + 0.5)); end --minimum 1 gold if above non-taxable amount

		local intTaxAmount = math.floor (intTaxableAmount * intTaxRate + 0.5); --round to nearest whole gold
		local intTaxAmount_GoldInHand = intTaxAmount;

		if (intTaxAmount_GoldInHand > 0) then
		-- if (intTaxAmount_Income > 0 or intTaxAmount_GoldInHand > 0) then
			print ("  player " ..tostring (playerID).. ", gold in hand " ..intGoldInHand.. ", gold carried over " ..intGoldInHand_Carryover.. ", income " ..intIncome.. ", taxable amount " ..intTaxableAmount.. ", tax amount (full) " ..intTaxAmount.. ", tax amount (income) " ..tostring (intTaxAmount_Income).. ", tax amount (gold in hand) " ..intTaxAmount_GoldInHand);
			local arrTaxAmount_GoldInHand = {};
			-- table.insert (arrIncomeMods, WL.IncomeMod.Create (playerID, -intTaxAmount_Income, "Carryover tax"));
			if (intTaxAmount_GoldInHand > 0) then arrTaxAmount_GoldInHand[playerID] = {}; arrTaxAmount_GoldInHand [playerID][WL.ResourceType.Gold] = math.max (0, intGoldInHand - intTaxAmount_GoldInHand); end --if income isn't high enough to cover the tax, take it from gold in hand but never go below 0 (it can break the game, player can't commit)
			addOrder (WL.GameOrderEvent.Create (playerID, "Carryover tax: " .. tostring (intTaxAmount) .. " gold", {}, {}, arrTaxAmount_GoldInHand, {}));
		end
	end
	--experimenting putting all income/resource adjustment orders together but it breaks visibility, showing all IncomeMods to all players - so just leave it as separate Event order belonging to the appropriate player, then it abides by the proper visibility rules
	-- addOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Commerce carryover tax", {}, {}, arrTaxAmount_GoldInHand, arrIncomeMods));
end