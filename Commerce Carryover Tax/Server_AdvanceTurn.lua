function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addOrder)
	if (order.proxyType == "GameOrderEvent" and order.Message == "Received Gold") then
		addOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "[gold mods here]"));
	end
end

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E] START");

	local intTaxStartAmount = Mod.Settings.TaxStartAmount or 0.0; --the % of carryover gold that isn't taxed, can be freely carried over to the following turn; default is 0.0 if not defined already
	local intTaxRate = Mod.Settings.TaxRate or 0.1; --the % tax rate for gold carried over; default is 0.1 if not defined already

	for playerID,objPlayer in pairs (game.ServerGame.Game.Players) do
		local intIncome = objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total;
		if (playerID == nil or game.ServerGame.LatestTurnStanding.Resources [playerID] == nil or game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold] == nil) then return; end --if playerID or the resources table is nil, just exit; maybe player is eliminated/booted?
		local intGoldInHand = game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold];
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold].. ", income " ..objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..intGoldInHand.. ", income " ..intIncome); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards

		local intTaxableAmount = 0; --default to 0; if gold in hand exceeds the non-taxable amount, set to at least 1 but calculate the actual taxable amount
		if (intGoldInHand > intIncome * intTaxStartAmount) then intTaxableAmount = math.max (1, math.floor (intGoldInHand - (intIncome * intTaxStartAmount) + 0.5)); end --minimum 1 gold if above non-taxable amount

		local intTaxAmount = math.floor (intTaxableAmount * intTaxRate + 0.5); --round to nearest whole gold
		local intTaxAmount_Income = math.min (intIncome, intTaxAmount); --math.ceil (intIncome, math.floor (intTaxableAmount * intTaxRate + 0.5)); --round to nearest whole gold, max value is player's full income; if income not enough to pay whole tax, deduct from gold in hand
		local intTaxAmount_GoldInHand = math.min (intTaxAmount - intTaxAmount_Income, intGoldInHand); -- and math.floor (intTaxableAmount * intTaxRate + 0.5) - intIncome or 0; --take the remainder of pending gold not collectible from income from gold inhand; round to nearest whole gold
		if (intTaxAmount > 0 and intIncome > 0) then intTaxAmount_Income = math.max (1, intTaxAmount_Income); --if player is carrying over gold in excess of Non-taxable amount, minimum tax is 1 gold
		elseif (intTaxAmount > 0 and intTaxAmount_Income == 0 and intGoldInHand > 0) then intTaxAmount_GoldInHand = math.max (1, intTaxAmount_GoldInHand); --if player has no income but is carrying over gold, minimum tax is 1 gold from gold in hand
		end

		if (intTaxAmount_Income > 0 or intTaxAmount_GoldInHand > 0) then
			print ("  player " ..tostring (playerID).. ", gold in hand " ..intGoldInHand.. ", income " ..intIncome.. ", taxable amount " ..intTaxableAmount.. ", tax amount (full) " ..intTaxAmount.. ", tax amount (income) " ..intTaxAmount_Income.. ", tax amount (gold in hand) " ..intTaxAmount_GoldInHand);
			-- if (intTaxAmount_Income > 0) then
			local arrTaxAmount_GoldInHand = {};
			if (intTaxAmount_GoldInHand > 0) then arrTaxAmount_GoldInHand[playerID] = {}; arrTaxAmount_GoldInHand[playerID][WL.ResourceType.Gold] = intGoldInHand - intTaxAmount_GoldInHand; end
			-- addOrder (WL.GameOrderEvent.Create (playerID, "Carryover tax: " .. tostring (intTaxAmount_Income) .. " gold", {}, {}, {}, {WL.IncomeMod.Create (playerID, -intTaxAmount_Income, "Carryover tax (" .. tostring (intTaxAmount_Income) .. ")")}));
			addOrder (WL.GameOrderEvent.Create (playerID, "Carryover tax: " .. tostring (intTaxAmount) .. " gold", {}, {}, arrTaxAmount_GoldInHand, {WL.IncomeMod.Create (playerID, -intTaxAmount_Income, "Carryover tax (" .. tostring (intTaxAmount_Income) .. ")")}));
			-- end
		end
	end
	--crashNow ();
	print ("[S_AT_E] END");
end

-- function Server_AdvanceTurn_Start (game, addOrder)
-- end

-- function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)
-- end