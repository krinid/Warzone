function Server_AdvanceTurn_End (game, addNewOrder)
	execute_Portal_Swaps (game, addNewOrder);
	--DESIRED FUTURE STATE:
		--nothing happens here anymore
		--Portal Swaps are executed in ReceiveCards phase, triggered by a custom order added in Server_AdvanceTurn_Start
		--this is done so that other mods receive the proper LastTurnStanding state after Portals swaps things (so Recruiters, Workers, etc, will correctly execute based on where the SUs currently are, not where they were when Server_AdvanceTurn_End calls to all mods began processing)
end

function Server_AdvanceTurn_Start (game, addNewOrder)
	-- local intSomePlayerID = (function(t) for k,_ in pairs(t) do return k end end)(game.ServerGame.Game.Players); --get playerID of 1st player in the list game.ServerGame.Game.Players; this is needed b/c GameOrderCustom required the playerID of an actual player in the game and doesn't accept 0 or WL.PlayerID.Neutral
	-- addNewOrder (WL.GameOrderCustom.Create (intSomePlayerID, "Portals|Swap Prep", "Portals|Swap Prep", {}, WL.TurnPhase.SanctionCards, nil, nil)); --add order to invoke Portal Swaps (instead of processing in Server_AdvanceTurn_End)


	--TIMING isn't working; it keeps executing @ start of turn, ignoring the appropriately used WL.TurnPhase enum phase
end

function Server_AdvanceTurn_Order (game, order, orderResult, skipThisOrder, addNewOrder)
	-- if (order.proxyType=='GameOrderCustom' and order.Payload == "Portals|Swap Prep") then
	-- 	local intSomePlayerID = (function(t) for k,_ in pairs(t) do return k end end)(game.ServerGame.Game.Players); --get playerID of 1st player in the list game.ServerGame.Game.Players; this is needed b/c GameOrderCustom required the playerID of an actual player in the game and doesn't accept 0 or WL.PlayerID.Neutral
	-- 	addNewOrder (WL.GameOrderCustom.Create (intSomePlayerID, "Portals|Swap", "Portals|Swap", {}, WL.TurnPhase.ReceiveGold, nil, nil)); --add order to invoke Portal Swaps (instead of processing in Server_AdvanceTurn_End)
	-- 	-- addNewOrder (WL.GameOrderCustom.Create (intSomePlayerID, "Wildfire burns!", "Wildfire|Burn", {}, WL.TurnPhase.EmergencyBlockadeCards, nil, nil)); --add order to invoke wildifre burning during the EB card play phase

	-- elseif (order.proxyType=='GameOrderCustom' and order.Payload == "Portals|Swap") then
	-- 	execute_Portal_Swaps (game, addNewOrder);
	-- 	-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
	-- end
end

function execute_Portal_Swaps (game, addNewOrder)
	local intNumPortals = Mod.Settings.NumPortals;
	TerritoryModifications = {}; --[1] = array of terrMods for all portal terrs, stores the army swaps & up to 4 SU swaps for each terr; all these to be submitted in 1 order as 'Portal swaps'; [2,3,4...] = additional SUs
	Annotations = {}; --annotations corresponding to TerritoryModifications

	--NOTE: check for 1-way vs 2-way portals
		--for 2-way, swap contents of each terr
		--for 1-way, movement becomes a transfer (single player or team owns both terrs) or attack (different players/teams own each terr or 1 is neutral -- neutral units attack the player? I suppose they have to; or neutral are exempt?)

	--Swap the standing (owner, armies) of the connected portals
	for i = 1, #Mod.PrivateGameData.Portals do
		local sourceTerritoryID  = Mod.PrivateGameData.Portals[i];
		local sourceTerritoryActual = game.ServerGame.LatestTurnStanding.Territories [sourceTerritoryID];
		local sourceTerritory = WL.TerritoryModification.Create (sourceTerritoryID);
		local targetTerritoryID = (i <= intNumPortals and Mod.PrivateGameData.Portals [tonumber (i + intNumPortals)] or Mod.PrivateGameData.Portals [tonumber (i - intNumPortals)]);
		local targetTerritory = getTerrMod_SwapSourceTarget (game, sourceTerritoryID, targetTerritoryID);
		if (TerritoryModifications[1] == nil) then TerritoryModifications[1] = {}; end
		if (Annotations[1] == nil) then Annotations[1] = {}; end
		Annotations[1][targetTerritoryID] = WL.TerritoryAnnotation.Create ("Portal Swap", 3, getColourInteger (100, 0, 100)); --purple annotation for Portal Swap
		sourceTerritory.RemoveSpecialUnitsOpt = convert_SUobjects_to_SUguids (sourceTerritoryActual.NumArmies.SpecialUnits); --remove Specials from source territory that are moving to target territory

		table.insert (TerritoryModifications[1], sourceTerritory); --removes any SUs on source territory
		table.insert (TerritoryModifications[1], targetTerritory); --adjusts the armies/owner of the target territory to match the source territory

		--move SUs on source territory
		if (#sourceTerritoryActual.NumArmies.SpecialUnits > 0) then
			--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
			local specialsToAdd = split_table_into_blocks (sourceTerritoryActual.NumArmies.SpecialUnits, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders

			--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
			for k,v in pairs (specialsToAdd) do
				local targetTerritorySUs = WL.TerritoryModification.Create (targetTerritoryID);
				targetTerritorySUs.AddSpecialUnits = v; --add Specials to target territory that are moving from source territory
				if (TerritoryModifications[k] == nil) then TerritoryModifications[k] = {}; end
				if (Annotations[k] == nil) then Annotations[k] = {}; end
				table.insert (TerritoryModifications[k], targetTerritorySUs);
				local strMessage = k == 1 and "Portal Swap" or "Portal SU Swap";
				Annotations[k][targetTerritoryID] = WL.TerritoryAnnotation.Create (strMessage, 3, getColourInteger (100, 0, 100)); --purple annotation for Portal Swap
			end
		end
	end

	--submit the orders
	for k,v in pairs (TerritoryModifications) do
		local strMessage = k == 1 and "Portal Swap" or "Portal SU Swap";
		-- if (k > 1) then --k==1 is for army swaps + SU removals only
			local eventOrder = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, strMessage, nil, TerritoryModifications [k], nil);
			eventOrder.TerritoryAnnotationsOpt = Annotations [k];
			addNewOrder(eventOrder);
	end
end

--create & return a terrMod to change the targetTerritory to match the army counts & owner of the sourceTerritory
function getTerrMod_SwapSourceTarget (game, sourceTerritory, targetTerritory)
	local terrMod = WL.TerritoryModification.Create (targetTerritory);
	terrMod.SetArmiesTo = game.ServerGame.LatestTurnStanding.Territories [sourceTerritory].NumArmies.NumArmies;
	terrMod.SetOwnerOpt = game.ServerGame.LatestTurnStanding.Territories [sourceTerritory].OwnerPlayerID;
	return terrMod
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

--manually move units from one territory to another
function manual_move_units (addOrder, playerID, sourceTerritory, sourceTerritoryID, targetTerritory, targetTerritoryID, units)
	--adjust armies & SUs on FROM territory
	sourceTerritory.AddArmies = -1 * units.NumArmies; --reduce source territory armies by the number of armies moving to target territory
	sourceTerritory.RemoveSpecialUnitsOpt = convert_SUobjects_to_SUguids (units.SpecialUnits); --remove Specials from source territory that are moving to target territory
	--need to convert the table to get the SU GUIDs (needed to remove from Source territory) b/c it is stored as a table of SU objects (used to add to Target territory)

	--adjust armies on TO territory
	targetTerritory.AddArmies = units.NumArmies; --increase target territory armies by the number of armies moving from source territory
	targetTerritory.RemoveSpecialUnitsOpt = {}; --reset the Specials to an empty table, so it's not constantly sending a list of SUs to remove that have already been removed

	--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
	local specialsToAdd = split_table_into_blocks (units.SpecialUnits, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders
	local territoriesToModify = {sourceTerritory, targetTerritory}; --on 1st iteration, modify source & territory, on 2nd and after just do target territory with Special Units
	if (#specialsToAdd == 0) then addOrder (WL.GameOrderEvent.Create (playerID, "[manual move]", {}, territoriesToModify), true); end --if there are no Specials to add, do the order once for both territories

	--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
	for _,v in pairs (specialsToAdd) do
		targetTerritory.AddSpecialUnits = v; --add Specials to target territory that are moving from source territory
		local event = WL.GameOrderEvent.Create (playerID, "[manual units move]", {}, territoriesToModify);
		local annotations = {};
		annotations [sourceTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [SOURCE]", 5, getColourInteger (0, 255, 0)); --show source territory in Green annotation
		annotations [targetTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [TARGET]", 5, getColourInteger (255, 0, 0)); --show target territory in Red annotation
		event.TerritoryAnnotationsOpt = annotations; --use Red colour for Airstrike target, Green for source
		-- event.TerritoryAnnotationsOpt = {[targetTerritory] = WL.TerritoryAnnotation.Create ("Airstrike", 10, getColourInteger (255, 0, 0))}; --use Red colour for Airstrike
		addOrder (event, true);
		targetTerritory.AddArmies = 0; --reset the armies to 0 after 1st iteration, so that the next order doesn't add more armies to the target territory
		territoriesToModify = {targetTerritory}; --on 2nd and after iterations, just modify target territory with Special Units
	end
end

--given a table of SU objects, return a table containing their GUIDs
--this is used to remove Specials from the source territory (which is done by SU GUIDs) and add them to the target territory (which is done using SU objects)
function convert_SUobjects_to_SUguids (SUobjects)
	local SUguids = {};
	for _,v in pairs (SUobjects) do table.insert (SUguids, v.ID); end
	return (SUguids);
end

function split_table_into_blocks (data, blockSize)
	local blocks = {};
	for i = 1, #data, blockSize do
		local block = {};
		for j = i, math.min(i + blockSize - 1, #data) do
			table.insert(block, data[j]);
		end
		table.insert(blocks, block);
	end
	return blocks;
end