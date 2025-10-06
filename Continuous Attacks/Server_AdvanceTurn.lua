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

	--boolProcessingContinuousAttackOrders is global variable to persist between orders; if nil set to false; if true then override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
	if (boolProcessingContinuousAttackOrders == nil) then boolProcessingContinuousAttackOrders = false; end

	-- local AttackPower = AttackingArmies.AttackPower;
	-- local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	-- local AttackDamage = math.floor (AttackPower * game.Settings.OffenseKillRate * totalAttackerAttackPowerPercentage + 0.5);
	-- local DefenseDamage = math.floor (DefensePower * game.Settings.DefenseKillRate * totalDefenderDefensePowerPercentage + 0.5);

	if (order.proxyType == 'GameOrderAttackTransfer') then
		if (boolProcessingContinuousAttackOrders == true) then
			result.ActualArmies = order.NumArmies; --override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
			result.AttackingArmiesKilled = WL.Armies.Create (math.floor (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * 0.7 + 0.5), {});
			result.DefendingArmiesKilled = WL.Armies.Create (math.floor (result.ActualArmies.NumArmies * 0.6 + 0.5), {});
			boolProcessingContinuousAttackOrders = false;
		end

		print ("\n[[  ATTACK // TRANSFER ]] PRE  player " ..order.PlayerID.. "/" ..getPlayerName (game, order.PlayerID).. ", FROM "..order.From.."/"..getTerritoryName (order.From, game)..", TO "..order.To.."/"..getTerritoryName (order.To, game) ..
			", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", ByPercent "..tostring (order.ByPercent)..", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", #SUs attacking "..#order.NumArmies.SpecialUnits..", Actual #SUs attacking "..#result.ActualArmies.SpecialUnits..
			", #defenderArmies " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies.. ", #defenderSUs " ..#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits..
			", attackPower " ..result.ActualArmies.AttackPower.. ", defensePower " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower..
			", attackDamage " ..(result.ActualArmies.AttackPower*0.6).. ", defenseDamage " ..(math.floor (result.ActualArmies.NumArmies * 0.6 + 0.5)).. "/"  ..(game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * 0.7)..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits);
		local intRemainingAttackingArmies = result.ActualArmies.NumArmies - result.AttackingArmiesKilled.NumArmies;
		local intRemainingDefendingArmies = game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies - result.DefendingArmiesKilled.NumArmies;
		local newArmies = WL.Armies.Create (intRemainingAttackingArmies, result.ActualArmies.SpecialUnits);
		if (result.ActualArmies.NumArmies > 0 and (result.AttackingArmiesKilled.NumArmies > 0 or result.DefendingArmiesKilled.NumArmies > 0) and (intRemainingAttackingArmies > 0 and intRemainingDefendingArmies > 0)) then
			addNewOrder (WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates));
			boolProcessingContinuousAttackOrders = true;
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