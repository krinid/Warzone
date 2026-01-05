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
		if (intTaxableAmount > 0) then intTaxAmount = math.max (1, intTaxAmount); end --if player is carrying over gold in excess of Non-taxable amount, minimum tax is 1 gold
		print ("  gold in hand " ..intGoldInHand.. ", income " ..intIncome.. ", taxable amount " ..intTaxableAmount.. ", tax amount " ..intTaxAmount);
		if (intTaxAmount > 0) then
				addOrder (WL.GameOrderEvent.Create (playerID, "Carryover tax: " .. tostring (intTaxAmount) .. " gold", {}, {}, {}, {WL.IncomeMod.Create (playerID, -intTaxAmount, "Carryover tax (" .. tostring (intTaxAmount) .. ")")}));
		end
	end
	--crashNow ();
	print ("[S_AT_E] END");
end

-- function Server_AdvanceTurn_Start (game, addOrder)
-- end

-- function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)
-- end