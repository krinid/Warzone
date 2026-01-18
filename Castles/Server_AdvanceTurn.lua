require ("castles");

function Server_AdvanceTurn_End(game, addOrder)
	local arrCastleMaintenanceIncomeMods = {};
	for ID,_ in pairs (game.ServerGame.Game.PlayingPlayers) do
		local intCastleMaintenanceCost = math.floor (countSUinstancesOnWholeMapFor1Player_Server (game, ID, "Castle", false) * intCastleMaintenanceCost * -1 + 0.5);
		print ("END: "..intCastleMaintenanceCost, ID, intCastleMaintenanceCost);

		--if castle maintenance for current player in loop is > 0, add income mod to table to deduct cost from next turn's income; if ==0, don't add it so it doesn't clutter up the order with "Adds 0 to the income of [player]" messages
		if (intCastleMaintenanceCost > 0) then table.insert (arrCastleMaintenanceIncomeMods, WL.IncomeMod.Create (ID, intCastleMaintenanceCost), "Castle maintenance"); end
	end

	--add even if no orders are included, so there isn't a give away to other players that castles have been built (in the fog, etc) when the order suddenly appears on a given turn
	--but since all castle maintenance is being processed as a single order, do players see the content of the order anyhow and thus know how many castles each player have even they can't see the castles themselves on the map?
	addOrder (WL.GameOrderEvent.Create (0, "Castle maintenance", {}, {}, {}, arrCastleMaintenanceIncomeMods));

	--FOR TESTING ONLY:: set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	local intHaltOnTurnNumber = 1;
	if (boolHaltCodeExecutionAtEndofTurn==true and game.Game.TurnNumber >= intHaltOnTurnNumber) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'Castle|')) then  --look for the order inserted in Client_PresentCommercePurchaseUI
		local orderComponents = split (order.Payload, '|');
		local strOperation = orderComponents[2];
		local targetTerritoryID = tonumber (orderComponents[3]);
		local intArmyCountSpecified = math.max (0, tonumber (orderComponents[4]) or 0);

		-- print ("- - - - - -" ..targetTerritoryID, tostring (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies.NumArmies));
		-- print (tostring (game.ServerGame.LatestTurnStanding ==nil));
		-- print (tostring (game.ServerGame.LatestTurnStanding.Territories ==nil));
		-- print (tostring (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID] ==nil));
		-- print (tostring (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies.NumArmies));

		if (strOperation == "Purchase") then
			local goldSpent = tonumber (orderComponents[5]);
			local intArmiesEnteringCastle = math.max (0, math.min (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies.NumArmies, intArmyCountSpecified));
			local intCastlePower = intArmiesEnteringCastle * intArmyToCastlePowerRatio;
			local intNumCastlesOwned = countSUinstancesOnWholeMapFor1Player_Server (game, order.PlayerID, "Castle", false);
			local intNumCastlesPurchaseOrdersThisTurn = 0; --countSUsPurchasedThisTurn (Game, "Castle");
			local intCastleCost = intCastleBaseCost + intCastleCostIncrease * (intNumCastlesOwned + intNumCastlesPurchaseOrdersThisTurn);
			-- local intCurrentMaintenanceCost = math.floor (countSUinstancesOnWholeMapFor1Player (Game, Game.Us.ID, "Castle", false) * intCastleMaintenanceCost + 0.5);

			--check if player owns the target territory; if player doesn't own the territory anymore, cancel the castle build
			--also check if player paid enough gold for the castle, and if not, cancel the castle build (and flag them as a cheater); can only happen if they hack the client (etc)
			if (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID ~= order.PlayerID) then
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
				addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Castle purchase failed; territory no longer owned (" ..getTerritoryName (targetTerritoryID, game).. ")", {}, {}), false);
			elseif (goldSpent >= intCastleCost) then --player paid the right amount of gold (or more - which shouldn't happen)
				createCastle (game, order, addNewOrder, targetTerritoryID, intArmiesEnteringCastle, intCastlePower);
			else --player didn't pay enough gold; hacked the client? cancel build & flag as cheater
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
				addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Castle purchase failed --> invalid purchase price < proper cost of next castle (" ..tostring (intCastleCost).. " gold) attempted! Shame on you, CHEATER DETECTED", {}, {}), false);
			end
		elseif (strOperation == "Enter" or strOperation == "Exit") then
			local objCastleSU = getSUonTerritory (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies, "Castle", false);
			if (objCastleSU == nil) then addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Castle " ..strOperation.. " failed; no castle on territory " ..getTerritoryName (targetTerritoryID, game))); skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); return; end

			local intNumArmiesToEnterCastle = math.max (0, math.min ((strOperation == "Enter" and intArmyCountSpecified or 0), game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies));
			local intNumArmiesToExitCastle  = math.max (0, math.min ((strOperation == "Exit"  and intArmyCountSpecified or 0), math.floor (objCastleSU.Health / intArmyToCastlePowerRatio)));

			if (intNumArmiesToEnterCastle > 0) then
				modifyCastle (game, order, addNewOrder, targetTerritoryID, objCastleSU, -intNumArmiesToEnterCastle, objCastleSU.Health + intNumArmiesToEnterCastle * intArmyToCastlePowerRatio);
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
			elseif (intNumArmiesToExitCastle > 0) then
				modifyCastle (game, order, addNewOrder, targetTerritoryID, objCastleSU, intNumArmiesToExitCastle, objCastleSU.Health - intNumArmiesToExitCastle * intArmyToCastlePowerRatio);
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
			end
			--ref: local payload_Enter = 'Castle|Enter|' ..SelectedTerritory.ID.. "|" ..intArmiesToEnterCastle;
			--ref: local payload_Exit = 'Castle|Exit|' ..SelectedTerritory.ID.. "|" ..intArmiesToExitCastle;
		elseif (strOperation == "Scuttle") then
			local objCastleSU = getSUonTerritory (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies, "Castle", false);
			if (objCastleSU == nil) then addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Castle Scuttle failed; no castle on territory " ..getTerritoryName (targetTerritoryID, game))); skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); return; end
			--ref: local payload_Scuttle = 'Castle|Scuttle|' ..SelectedTerritory.ID;

			local terrMod = WL.TerritoryModification.Create (targetTerritoryID);
			terrMod.RemoveSpecialUnitsOpt = {objCastleSU.ID};
			local intNumArmiesToExitCastle  = math.floor (objCastleSU.Health / intArmyToCastlePowerRatio); --if there are armies in the castle (SU has health>0), force armies to exit the castle
			local strDescription = "Castle scuttled on " ..getTerritoryName (targetTerritoryID, game);
			if (intNumArmiesToExitCastle > 0) then
				terrMod.AddArmies = intNumArmiesToExitCastle;
				strDescription = strDescription .. "; " ..tostring (intNumArmiesToExitCastle).. " armies exited castle";
			end

			local event = WL.GameOrderEvent.Create(order.PlayerID, strDescription, {}, {terrMod});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Castle scuttled", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
			skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip order & suppress the 'Mod skipped order' message, since an order with details will be added below
			addNewOrder (event, false);
		else
			print ("[CASTLE] unsupported operation: " .. strOperation);
			return;
		end
	end
end

function modifyCastle (game, order, addNewOrder, targetTerritoryID, existingCastleSU, intNumArmiesOnTerritoryDelta, castlePower);
	--remove existing SU
	--replace with new SU
	--update army counts on territory

	local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];

	if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
		return; --can only build a castle onto a territory you control
	end

	local newCastleSU = createCastleSU (castlePower);
	local terrMod = WL.TerritoryModification.Create (targetTerritoryID);
	terrMod.AddSpecialUnits = {newCastleSU};
	terrMod.RemoveSpecialUnitsOpt = {existingCastleSU.ID};
	terrMod.AddArmies = intNumArmiesOnTerritoryDelta;
	local strDescription = tostring (math.abs (intNumArmiesOnTerritoryDelta)).. " armies " ..(intNumArmiesOnTerritoryDelta <0 and "entered" or "exited").. " castle  on " ..getTerritoryName (targetTerritoryID, game); --if delta is -ve then armies entered castle, else they exited
	local event = WL.GameOrderEvent.Create(order.PlayerID, strDescription, {}, {terrMod});
    event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Castle army enter/exit", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	addNewOrder (event, false);
end

function createCastle (game, order, addNewOrder, targetTerritoryID, intArmiesEnteringCastle, castlePower)
	local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];

	if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
		return; --can only build a castle onto a territory you control
	end

	if (order.CostOpt == nil) then
		return; --shouldn't ever happen, unless another mod interferes
	end

	local castleSU = createCastleSU (castlePower);
	local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
	terrMod.AddSpecialUnits = {castleSU};
	terrMod.AddArmies = -intArmiesEnteringCastle;
	local strDescription = "Purchased a Castle";
	if (castlePower > 0) then strDescription = strDescription .. ", " ..tostring (intArmiesEnteringCastle).. " armies entered it"; end
	local event = WL.GameOrderEvent.Create(order.PlayerID, strDescription, {}, {terrMod});
    event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	addNewOrder (event, false);
end

function createCastleSU (castlePower)
	local builder = WL.CustomSpecialUnitBuilder.Create(WL.PlayerID.Neutral); --assign unit to Neutral, not the purchaser of the Castle or owner of the territory; this makes it so it doesn't show up in the Attack/Transfer dialog
	builder.Name = 'Castle';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'Castle_60x63_clearBack.png'; --max size of 60x100 pixels
	builder.AttackPower = 0; --castle can't attack so this value doesn't matter, but set it to 0 in case some mod does something weird with it
	builder.DefensePower = castlePower;
	builder.CombatOrder = 1; --fights directly after armies; this prevents a territory with armies outside and no armies inside a castle (castle SU has 0 health) to be destroyed despite armies there to defend it (logistically this would make no sense)
	builder.Health = castlePower;
	builder.CanBeGiftedWithGiftCard = false;
	builder.CanBeTransferredToTeammate = false;
	builder.CanBeAirliftedToSelf = false;
	builder.CanBeAirliftedToTeammate = false;
	builder.IsVisibleToAllPlayers = false;
	builder.ModData = "Castle";
	return (builder.Build());
end