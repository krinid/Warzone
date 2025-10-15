require('Utilities');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	--Check if we see a Build Fort event.  If we do, add it to a global list that we'll check in BuildForts() below.
	if (order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, 'BuildFortCard_')) then  --look for the order that we inserted in Client_PresentMenuUI
		--Extract territory ID from the payload
		local terrID = tonumber (string.sub (order.ModData, 15));
		BuildFort (game, addNewOrder, order.PlayerID, terrID, order.Description)
	end

	--Check if this is an attack against a territory with a fort.
	if (order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack) then
		local structureID = WL.StructureType.Custom ("Fort"); --matches to StructureImages/Fort.png

		local structures = game.ServerGame.LatestTurnStanding.Territories[order.To].Structures;

		--If no fort here, abort.
		if (structures == nil) then return; end;

		local numFortsHere = 0;
		if (structures[structureID] ~= nil) then
			numFortsHere = numFortsHere + structures[structureID];
		end

		--If no fort here, abort.
		if (numFortsHere == 0) then return; end;

		--If an attack of 0, abort, so skipped orders don't destroy the fort
		if (result.ActualArmies.IsEmpty) then return; end;

		--Attack found against a fort!  Cancel the attack and remove the fort.
		structures[structureID] = structures[structureID] - 1;

		local terrMod = WL.TerritoryModification.Create(order.To);
		terrMod.SetStructuresOpt = structures;

		local td = game.Map.Territories[order.To];
		local event = WL.GameOrderEvent.Create (order.PlayerID, "Destroyed fort", {}, {terrMod});
		event.JumpToActionSpotOpt = WL.RectangleVM.Create(td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);
		if (WL.IsVersionOrHigher("5.34.1")) then
			event.TerritoryAnnotationsOpt = { [order.To] = WL.TerritoryAnnotation.Create("Destroy Fort") };
		end

		addNewOrder (event, true); -- The second argument makes sure this order isn't processed when the initial attack is skipped

		if (result.DefendingArmiesKilled.IsEmpty) then
			-- A successful attack on a territory where no defending armies were killed must mean it was a territory defended by 0 armies.  In this case, we can't stop the attack by simply setting DefendingArmiesKilled to 0, since attacks against 0 are always successful. 
			-- Instead of skipping the order, we can set the ActualArmies to 0, to make it a 0 army attack. Skipping the order would also skip the destroy fort order
			result.ActualArmies = WL.Armies.Create (0);
		else
			result.DefendingArmiesKilled = WL.Armies.Create (0);
		end
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	-- BuildForts(game, addNewOrder);
end

function BuildForts(game, addNewOrder)
	--Build any forts that we queued in up Server_AdvanceTurn_Order
	local structureID = WL.StructureType.Custom ("Fort"); --matches to StructureImages/Fort.png

	local priv = Mod.PrivateGameData;
	local pending = priv.PendingForts;
	if (pending == nil) then return; end;

	-- Remove any pending builds where the player lost control of the territory, so we don't build a fort for the new owner
	removeWhere (pending, function(t) return t.PlayerID ~= game.ServerGame.LatestTurnStanding.Territories[t.TerritoryID].OwnerPlayerID; end);

	-- We will now build a fort for each pending fort.  However, we need to take care to ensure that if there are two build orders for the same territory that we build both of them, so we first group by the territory ID so we get all build orders for the same territory together.
	for territoryID,pendingFortGroup in pairs(groupBy(pending, function(t) return t.TerritoryID; end)) do

		local numFortsToBuildHere = #pendingFortGroup;

		local structures = game.ServerGame.LatestTurnStanding.Territories[territoryID].Structures;


		if (structures == nil) then structures = {}; end;
		if (structures[structureID] == nil) then
			structures[structureID] = numFortsToBuildHere;
		else
			structures[structureID] = structures[structureID] + numFortsToBuildHere;
		end

		local terrMod = WL.TerritoryModification.Create(territoryID);
		terrMod.SetStructuresOpt = structures;

		local pendingFort = first(pendingFortGroup);

		local event = WL.GameOrderEvent.Create(pendingFort.PlayerID, pendingFort.Message, {}, {terrMod});

		local td = game.Map.Territories[territoryID];
		event.JumpToActionSpotOpt = WL.RectangleVM.Create(td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);
		if (WL.IsVersionOrHigher("5.34.1")) then
			event.TerritoryAnnotationsOpt = { [territoryID] = WL.TerritoryAnnotation.Create("Build Fort") };
		end

		addNewOrder(event);
	end

	priv.PendingForts = nil;
	Mod.PrivateGameData = priv;
end

function BuildFort (game, addNewOrder, playerID, territoryID, strMessage)
	--Build any forts that we queued in up Server_AdvanceTurn_Order
	local structureID = WL.StructureType.Custom ("Fort"); --matches to StructureImages/Fort.png

	-- if player building the fort doesn't own the territory anymore, don't build the fort
	if (game.ServerGame.LatestTurnStanding.Territories[territoryID].OwnerPlayerID ~= playerID) then
		addNewOrder (WL.GameOrderEvent.Create (playerID, "Failed to " .. strMessage));
	else
		local structures = game.ServerGame.LatestTurnStanding.Territories[territoryID].Structures;

		if (structures == nil) then structures = {}; end;
		if (structures[structureID] == nil) then
			structures[structureID] = 1;
		else
			structures[structureID] = structures[structureID] + 1;
		end

		local terrMod = WL.TerritoryModification.Create(territoryID);
		terrMod.SetStructuresOpt = structures;

		local event = WL.GameOrderEvent.Create(playerID, strMessage, {}, {terrMod});

		local td = game.Map.Territories[territoryID];
		event.JumpToActionSpotOpt = WL.RectangleVM.Create(td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);
		if (WL.IsVersionOrHigher("5.34.1")) then
			event.TerritoryAnnotationsOpt = { [territoryID] = WL.TerritoryAnnotation.Create("Build Fort") };
		end

		addNewOrder(event);
	end
end