require("utilities");

function Server_AdvanceTurn_Start (game,addNewOrder)
	-- skippedBombs = {};
	-- memory = {};
	-- executed = false;
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if(order.proxyType == 'GameOrderPlayCardBomb')then
		printObjectDetails (order, "order", "order details");
		printObjectDetails (order.ResultObj, "order.ResultObj1", "order.ResultObj2");
		printObjectDetails (result, "result", "result object");
		--addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, getPlayerName (game, order.PlayerID).. " bombs ".. game.Map.Territories[order.TargetTerritoryID].Name, {}, {terrMod}));
		local event = WL.GameOrderEvent.Create (order.PlayerID, getPlayerName (game, order.PlayerID).. " bombs ".. game.Map.Territories[order.TargetTerritoryID].Name, {}, {});
		event.RemoveWholeCardsOpt = {[order.PlayerID] = order.CardInstanceID};
		addNewOrder (event, false); --add new order remove the Bomb card + protecting the territory (don't do any damage)
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip original Bomb order (b/c there's no way to just remove the damage it does)
		breakMeNow ();
	end
end
-- function Server_AdvanceTurn_End(game,addNewOrder)
-- 	if(executed == false) then
-- 		executed = true;
-- 		for _, order in pairs(skippedBombs) do
-- 			if (order.PlayerID~=nil) then
-- 				bomber = game.ServerGame.Game.PlayingPlayers[order.PlayerID];
-- 				if (bomber ~= nil) then
-- 					bombedID = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID;
-- 					if (bombedID == WL.PlayerID.Neutral or bombedID == nil or game.ServerGame.Game.PlayingPlayers[bombedID] == nil) then
-- 						PlayBombCard(game, order, addNewOrder);
-- 					else 
-- 						bombed = game.ServerGame.Game.PlayingPlayers[bombedID];
-- 						if (bomber.Team~=bombed.Team or (bombed.Team == -1 and bombed.ID ~= order.PlayerID)) then
-- 							PlayBombCard(game, order, addNewOrder);
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end
-- function round (input)
-- 	local wholePart = math.floor(input);
-- 	local decimalPart = input - wholePart;
-- 	if (decimalPart) >= 0.5 then
-- 		return wholePart +1;
-- 	else
-- 		return wholePart;
-- 	end
-- end

-- function PlayBombCard(game, order, addNewOrder)
-- 		local terrMod = WL.TerritoryModification.Create(order.TargetTerritoryID);
-- 		local armies;
-- 		if (memory[order.TargetTerritoryID] == nil) then
-- 			armies = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies;
-- 		else
-- 			armies = memory[order.TargetTerritoryID];
-- 		end
-- 		armies =armies - round(armies*Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled);
-- 		if (armies < 1) then
-- 			if (Mod.Settings.specialUnits ~= true or tablelength(game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.SpecialUnits) ==0) then
-- 				terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
-- 			end
-- 			terrMod.SetArmiesTo = 0;
-- 		else
-- 			terrMod.SetArmiesTo = armies;
-- 		end
-- 		memory[order.TargetTerritoryID] = armies;
-- 		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Bombs ".. game.Map.Territories[order.TargetTerritoryID].Name, {}, {terrMod}));
-- end

-- function tablelength(T)
--   local count = 0
--   for _ in pairs(T) do count = count + 1 end
--   return count
-- end