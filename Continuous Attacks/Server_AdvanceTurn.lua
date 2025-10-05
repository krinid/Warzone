---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addOrder)
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	--check ATTACK/TRANSFER orders to see if any rules are broken and need intervention, eg: moving TO/FROM an Isolated territory or OUT of Quicksanded territory
	if (order.proxyType == 'GameOrderAttackTransfer') then
		print ("[[  ATTACK // TRANSFER ]] PRE  player " ..order.PlayerID.. "/" ..getPlayerName (game, order.PlayerID).. ", FROM "..order.From.."/"..getTerritoryName (order.From, game)..", TO "..order.To.."/"..getTerritoryName (order.To, game) ..
			", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", ByPercent "..tostring (order.ByPercent)..", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", #SUs attacking "..#order.NumArmies.SpecialUnits..", Actual #SUs attacking "..#result.ActualArmies.SpecialUnits..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits);
		local intRemainingAttackingArmies = result.ActualArmies.NumArmies - result.AttackingArmiesKilled.NumArmies;
		if (result.ActualArmies.NumArmies > 0 and (result.AttackingArmiesKilled.NumArmies > 0 or result.DefendingArmiesKilled.NumArmies > 0) and intRemainingAttackingArmies > 0) then
			addOrder (WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newNumArmies, order.AttackTeammates));
		end
	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<0) then return ("fogged");
	elseif (tonumber(playerid)<50) then return ("AI "..playerid);
	else
		for _,playerinfo in pairs(game.Game.Players) do
			if(tonumber(playerid) == tonumber(playerinfo.ID))then
				return (playerinfo.DisplayName(nil, false));
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found but playerID >50 was provided
end