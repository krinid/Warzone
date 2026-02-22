function Server_AdvanceTurn_End_orig (game, addNewOrder)
	Game = game
	TerritoryModifications = {};
	Annotations = {};
	local intNumPortals = Mod.Settings.NumPortals;

	--Swap the standing (owner, armies) of the connected portals
	for i = 1, #Mod.PrivateGameData.Portals do
		if (i <= intNumPortals) then -- for 3 portals: 1, 2, 3 swap with 4, 5, 6
print ("@@1 " ..i, i+intNumPortals, intNumPortals);
			TerritoryModifications[i] = terrModHelper (Mod.PrivateGameData.Portals[i], Mod.PrivateGameData.Portals [tonumber (i + intNumPortals)])
		else
print ("@@2 " ..i, i-intNumPortals, intNumPortals);
			TerritoryModifications[i] = terrModHelper (Mod.PrivateGameData.Portals[i], Mod.PrivateGameData.Portals [tonumber (i - intNumPortals)])
		end
		Annotations [Mod.PrivateGameData.Portals[i]] = WL.TerritoryAnnotation.Create ("Portal Swap", 3, getColourInteger (100, 0, 100)); --purple annotation for Portal Swap
	end

	local eventOrder = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Portals swap units", nil, TerritoryModifications, nil);
	eventOrder.TerritoryAnnotationsOpt = Annotations;
	addNewOrder(eventOrder);
end

function Server_AdvanceTurn_End (game, addNewOrder)
	Game = game
	TerritoryModifications = {};
	Annotations = {};
	local intNumPortals = Mod.Settings.NumPortals;

	--Swap the standing (owner, armies) of the connected portals
	for i = 1, #Mod.PrivateGameData.Portals do
		local sourceTerritoryID  = Mod.PrivateGameData.Portals[i];
		local sourceTerritoryActual = Game.ServerGame.LatestTurnStanding.Territories [sourceTerritoryID];
		local sourceTerritory = WL.TerritoryModification.Create (sourceTerritoryID);
		local targetTerritoryID = (i <= intNumPortals and Mod.PrivateGameData.Portals [tonumber (i + intNumPortals)] or Mod.PrivateGameData.Portals [tonumber (i - intNumPortals)]);
		-- local targetTerritory = Game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID];
		local targetTerritory = WL.TerritoryModification.Create (targetTerritoryID);
		local unitsToSwap = WL.Armies.Create (sourceTerritoryActual.NumArmies.NumArmies, sourceTerritoryActual.NumArmies.SpecialUnits);

		manual_move_units (addNewOrder, WL.PlayerID.Neutral, sourceTerritory, sourceTerritoryID, targetTerritory, targetTerritoryID, unitsToSwap);
		-- Annotations [Mod.PrivateGameData.Portals[i]] = WL.TerritoryAnnotation.Create ("Portal Swap", 3, getColourInteger (100, 0, 100)); --purple annotation for Portal Swap
	end

	-- local eventOrder = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Portals swap units", nil, TerritoryModifications, nil);
	-- eventOrder.TerritoryAnnotationsOpt = Annotations;
	-- addNewOrder(eventOrder);
end

function terrModHelper(targetTerritory, sourceTerritory)
print ("::"..targetTerritory, sourceTerritory)
	local terrMod = WL.TerritoryModification.Create (targetTerritory)

	terrMod.SetArmiesTo = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].NumArmies.NumArmies
	terrMod.SetOwnerOpt = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].OwnerPlayerID

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