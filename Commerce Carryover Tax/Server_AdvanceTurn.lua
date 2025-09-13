local intTaxStartAmount = 0.0; --tax starts when gold carried over exceeds 0.0x income level, ie: all gold carried over is taxed
local intTaxRate = 0.1; --10% tax on gold carried over beyond 1x income level

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E] START");

	for playerID,objPlayer in pairs (game.ServerGame.Game.Players) do
		local intIncome = objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total;
		if (playerID == nil or game.ServerGame.LatestTurnStanding.Resources [playerID] == nil or game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold] == nil) then return; end --if playerID or the resources table is nil, just exit; maybe player is eliminated/booted?
		local intGoldInHand = game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold];
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..game.ServerGame.LatestTurnStanding.Resources [playerID][WL.ResourceType.Gold].. ", income " ..objPlayer.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards
		-- print (playerID.."/"..objPlayer.DisplayName (nil, false).. ", gold " ..intGoldInHand.. ", income " ..intIncome); --assume 0 reinf cards, use most recent standing, bypass army cap, bypass sanction cards
		local intTaxableAmount = math.max (1, math.floor (intGoldInHand - (intIncome * intTaxStartAmount) + 0.5)); --minimum 1 gold if above threshold up
		local intTaxAmount = math.floor (intTaxableAmount * intTaxRate + 0.5); --round to nearest whole gold
		if (intGoldInHand > 0) then intTaxAmount = math.max (1, intTaxAmount); end --if player is carrying over gold, minimum tax is 1 gold
		print ("  taxable amount " ..intTaxableAmount.. ", tax amount " ..intTaxAmount);
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