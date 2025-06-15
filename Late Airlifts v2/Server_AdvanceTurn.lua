function Server_AdvanceTurn_Start (game,addNewOrder)
	SkippedAirlifts = {};
	executed = false;
	boolPermitNextAirlift = false; --used to coordinate with other mods like Airstrike that use Airlifts that should not be deferred to end of turn
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)	
	--Server_AdvanceTurn_Order is called:
		-- (1) for each regular order submitted by players, (2) for each order added by mods during execution of , (3) by various WZ core engine items, but also importantly:
		-- (4) by orders added via 'addNewOrder' during execution of Server_AdvanceTurn_End; so while executing _End (after all normaly orders are processed), execution is sent back to _Order when new orders are added during _End for consistent order processing

	--if current order is an Airlift, add to the SkippedAirlifts structure to be processed at end of turn iff:
		-- (A) 'executed' is false (this means all regular orders haven't finished processing, this is not an additional order added during _End), and
		-- (B) boolPermitNextAirlift==false; this is set to true when an order from another mod like Airstrike is submitted that permits an Airlift mid-turn w/o deferring to the end
	if (order.proxyType == 'GameOrderPlayCardAirlift' and boolPermitNextAirlift == true) then
		--permit this airlift, don't defer it until end of turn; this is an airlift used by another mod like Airstrike, not a regular airlift
		--all that's required to permit it is to not enter the next condition in this IF structure (which will skip the order and defer it to end of turn)
		boolPermitNextAirlift = false; --reset this flag; only permit 1 airlift, and still defer the rest until end of turn as per usual with Late Airlifts
	elseif (order.proxyType == 'GameOrderPlayCardAirlift' and executed == false and boolPermitNextAirlift == false) then
		SkippedAirlifts[tablelength(SkippedAirlifts)] = order;
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
	elseif (order.proxyType == "GameOrderEvent" and startsWith (order.Message, "Late Airlifts|Permit mid-turn Airlift")) then
		--order is a custom order from another mod to permit airlifts mid-turn
		--eg: "Late Airlifts|Permit mid-turn Airlift" from the Airstrike mod; the first part "Late Airlifts|Permit" is the same, and the last part "|Airstrike" indicates the mod invoking the mid-turn airlift
		boolPermitNextAirlift = true; --permit the next airlift to occur mid-turn
	end
end

function Server_AdvanceTurn_End(game,addNewOrder)
	if(executed == false) then
		executed = true;
		for _,order in pairs(SkippedAirlifts)do
			local toowner = game.ServerGame.LatestTurnStanding.Territories[order.ToTerritoryID].OwnerPlayerID;
			local fromowner = game.ServerGame.LatestTurnStanding.Territories[order.FromTerritoryID].OwnerPlayerID;
			local orderplayerTeam = game.ServerGame.Game.Players[order.PlayerID].Team;
			local toownerTeam = -1; --indicates player doesn't belong to a team
			local fromownerTeam = -1; --indicates player doesn't belong to a team

			--weed odd all scenarios where the airlift would fail and cancel the airlift in those cases (and don't consume the card)
			local boolExecuteAirlift = true;

			--cancel order if TO territory is neutral
			if (toowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false;
			else toownerTeam = game.ServerGame.Game.Players[toowner].Team;
			end

			--cancel order if FROM territory is neutral
			if (fromowner == WL.PlayerID.Neutral) then boolExecuteAirlift=false;
			else fromownerTeam = game.ServerGame.Game.Players[fromowner].Team;
			end

			print ("toownerTeam=="..toownerTeam..", fromownerTeam=="..fromownerTeam);

			--if player is on a team, check if TO and FROM territories belong to the same team, if so allow airlift, if not cancel it
			if (orderplayerTeam >=0) then --player has a team, check TO/FROM territory ownership for team alignment (not just solo alignment) and permit it
				print ("[TEAMS]");
				if(orderplayerTeam ~= toownerTeam) then boolExecuteAirlift=false; end --cancel order if TO territory is not owned by team member that order player sending airlift belongs to
				if(orderplayerTeam ~= fromownerTeam) then boolExecuteAirlift=false; end --cancel order if FROM territory is not owned by team member that order player sending airlift belongs to
			else --order player has no team alignment so do solo ownership checks on TO/FROM territory ownership
				print ("[SOLO / NO TEAMS]");
				if(order.PlayerID ~= fromowner) then boolExecuteAirlift=false; end --cancel order if player sending airlift no longer owns the FROM territory
				if(order.PlayerID ~= toowner) then boolExecuteAirlift=false; end --cancel order if player sending airlift no longer owns the FROM territory
			end

			print ("[SA_TE]---------------");
			print ("order player ID=="..order.PlayerID..", team=="..orderplayerTeam);
			print ("toowner      ID=="..toowner..", team=="..toownerTeam);
			print ("fromowner    ID=="..fromowner..", team=="..fromownerTeam);

			--if operation hasn't been canceled, execute the airlift & consume the card
			if(boolExecuteAirlift==true) then
				print ("AIRLIFT PERMIT");
				addNewOrder(order);
			else
			--airlift has been canceled; add a message in game history to inform user why; don't consume the airlift card
				print ("airlift SKIP");
				addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Airlift from "..game.Map.Territories[order.FromTerritoryID].Name.." to "..game.Map.Territories[order.ToTerritoryID].Name.." has been canceled as you no longer controlling both territories", {}, {},{}));
			end
		end
	end
end

function tablelength(T)
	local count = 0;
	for _ in pairs(T) do count = count + 1 end;
	return count;
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end