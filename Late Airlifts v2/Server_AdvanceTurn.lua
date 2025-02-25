function Server_AdvanceTurn_Start (game,addNewOrder)
	SkippedAirlifts = {};
	executed = false;
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)	
	if(executed == false)then
		if(order.proxyType == 'GameOrderPlayCardAirlift')then
			SkippedAirlifts[tablelength(SkippedAirlifts)] = order;
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		end
	end
end
function Server_AdvanceTurn_End(game,addNewOrder)
	if(executed == false) then
		executed = true;
		for _,order in pairs(SkippedAirlifts)do
			local toowner = game.ServerGame.LatestTurnStanding.Territories[order.ToTerritoryID].OwnerPlayerID;
			local fromowner = game.ServerGame.LatestTurnStanding.Territories[order.ToTerritoryID].OwnerPlayerID;
			
			--weed odd all scenarios where the airlift would fail and cancel the airlift in those cases (and don't consume the card)
			boolExecuteAirlift = true;
			if(toowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false; end --cancel order if TO territory is neutral
			if(fromowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false; end --cancel order if FROM territory is neutral
			if(order.PlayerID ~= game.ServerGame.LatestTurnStanding.Territories[order.FromTerritoryID].OwnerPlayerID) then boolExecuteAirlift=false; end --cancel order if player sending airlift no longer owns the FROM territory
			if(game.ServerGame.Game.Players[order.PlayerID].Team == game.ServerGame.Game.Players[toowner].Team) then boolExecuteAirlift=false; end --cancel order if TO territory is not owned by player sending airlift (or his team)
			if(game.ServerGame.Game.Players[order.PlayerID].Team == game.ServerGame.Game.Players[fromowner].Team) then boolExecuteAirlift=false; end --cancel order if FROM territory is not owned by player sending airlift (or his team)

			--if operation hasn't been canceled, execute the airlift & consume the card
			if(boolExecuteAirlift==true) then
				addNewOrder(order);
			else
			--airlift has been canceled; add a message in game history to inform user why; don't consume the airlift card
				addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Airlift from "..game.Map.Territories[order.FromTerritoryID].Name.." to "..game.Map.Territories[order.ToTerritoryID].Name.." has been canceled as you no longer own both territories", {}, {},{}));
			end
		end
	end
end
function tablelength(T)
	local count = 0;
	for _ in pairs(T) do count = count + 1 end;
	return count;
end
