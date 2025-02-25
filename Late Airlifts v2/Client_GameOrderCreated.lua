function Client_GameOrderCreated (game, order, skip)
	--check if an Airlift was entered, if so popup an alert to let player know it will occur at the end of a turn and not the beginning
	if (order.proxyType=='GameOrderPlayCardAirlift') then
		UI.Alert ("[LATE AIRLIFTS]\nAirlifts occur at the END OF A TURN (not the beginning) in this game.\n\nIf you no longer own the territory at that time, the airlift will not occur.");


		local toowner = game.LatestStanding.Territories[order.ToTerritoryID].OwnerPlayerID;
		local fromowner = game.LatestStanding.Territories[order.ToTerritoryID].OwnerPlayerID;

		print ("order player ID=="..order.PlayerID..", team=="..game.Game.Players[order.PlayerID].Team);
		print ("toowner      ID=="..toowner..", team=="..game.Game.Players[toowner].Team);
		print ("fromowner    ID=="..fromowner..", team=="..game.Game.Players[fromowner].Team);

		--weed odd all scenarios where the airlift would fail and cancel the airlift in those cases (and don't consume the card)
		local boolExecuteAirlift = true;
		if(toowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false; end --cancel order if TO territory is neutral
		if(fromowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false; end --cancel order if FROM territory is neutral
		--if(order.PlayerID ~= game.ServerGame.LatestTurnStanding.Territories[order.FromTerritoryID].OwnerPlayerID) then boolExecuteAirlift=false; end --cancel order if player sending airlift no longer owns the FROM territory
		if(game.Game.Players[order.PlayerID].Team ~= game.Game.Players[toowner].Team) then boolExecuteAirlift=false; end --cancel order if TO territory is not owned by player sending airlift (or his team)
		if(game.Game.Players[order.PlayerID].Team ~= game.Game.Players[fromowner].Team) then boolExecuteAirlift=false; end --cancel order if FROM territory is not owned by player sending airlift (or his team)

		--if operation hasn't been canceled, execute the airlift & consume the card
		if(boolExecuteAirlift==true) then
			print ("AIRLIFT YES");
			--addNewOrder(order);
		else
		--airlift has been canceled; add a message in game history to inform user why; don't consume the airlift card
			print ("airlift SKIP");
			--addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Airlift from "..game.Map.Territories[order.FromTerritoryID].Name.." to "..game.Map.Territories[order.ToTerritoryID].Name.." has been canceled as you no longer own both territories", {}, {},{}));
		end
	end
end