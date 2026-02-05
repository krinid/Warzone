require("Utilities");

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Beacon|")) then
        local targetTerritoryID = tonumber(string.sub (order.ModData, 8));
		local td = game.Map.Territories[targetTerritoryID];
		local terr = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];
		local structures = terr.Structures;
		if (structures == nil) then structures = {}; end;
	    local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);
		local terrs = {targetTerritoryID};
		local intBeaconRange = Mod.Settings.Range; --distance Beacon spreads to; 0=targeted territory only; 1=spreads to directly bordering terrs, etc
		local intDuration = Mod.Settings.Duration; --duration in # of turns
		local intTurnExpiry = game.Game.TurnNumber + intDuration;
		local priority = 8010; -- Smoke Bomb uses 7000, Phantom uses 8000 (default), so this reveals with priority over their fog; between 6000 and 8999 means it won't obscure a player's own territories

		terrs = getTerritoriesWithinDistance (game, targetTerritoryID, intBeaconRange);
		local fogMod = WL.FogMod.Create ('Revealed by Beacon|'..tostring (targetTerritoryID), WL.StandingFogLevel.Visible, priority, terrs, nil);

		if (structures [WL.StructureType.Custom("Beacon")] == nil) then structures [WL.StructureType.Custom("Beacon")] = 1;
		else structures [WL.StructureType.Custom("Beacon")] = structures [WL.StructureType.Custom("Beacon")] + 1;
		end
		impactedTerritory.SetStructuresOpt = structures;

		local event = WL.GameOrderEvent.Create (order.PlayerID, 'Placed a beacon', {}, {impactedTerritory});
		event.FogModsOpt = {fogMod};
		event.JumpToActionSpotOpt = WL.RectangleVM.Create (td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);

		if (WL.IsVersionOrHigher("5.34.1")) then
			event.TerritoryAnnotationsOpt = { [targetTerritoryID] = WL.TerritoryAnnotation.Create("Beacon") };
		end

		addNewOrder(event);

		--Store the FogMod IDs so they can be removed on the appropriate turn
		local priv = Mod.PrivateGameData;
		local arrFogModIDs = priv.FogModIDs or {};
		if (arrFogModIDs [intTurnExpiry] == nil) then arrFogModIDs [intTurnExpiry] = {}; end
		table.insert (arrFogModIDs [intTurnExpiry], fogMod.ID);
		priv.FogModIDs = arrFogModIDs;
		Mod.PrivateGameData = priv;
	end
end

function Server_AdvanceTurn_Start (game, addNewOrder)
	--If we have any existing fog mods, remove them
	local priv = Mod.PrivateGameData;
	local arrFogModIDs = priv.FogModIDs or {};
	local modifiedTerritories = {};

	if (arrFogModIDs [game.Game.TurnNumber] == nil) then print ("nope"); return; end

	--if there are FogMods expiring this turn, remove them
	if (arrFogModIDs [game.Game.TurnNumber] ~= nil) then
		local arrintBeaconStructureCount = {};
		for k,v in pairs (arrFogModIDs [game.Game.TurnNumber]) do
			-- print ("FOGMOD: "..tostring (v).. " / ".. tostring (v.ID) .." / ".. tostring (v.Priority) .." / ".. tostring (v.Message));
			fogmod = game.ServerGame.LatestTurnStanding.FogModsOpt [v];
			print ("FOGMOD: "..tostring (fogmod).. " / ".. tostring (fogmod.ID) .." / ".. tostring (fogmod.Priority) .." / ".. tostring (fogmod.Message));
			local targetTerritoryID = (split (fogmod.Message, '|'))[2]; --ge tthe territory # from the Message field to remove the Beacon Structure from the terr
			local terr = game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID];
			local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);
			local structures = terr.Structures;

			-- if (structures == nil or structures [WL.StructureType.Custom("Beacon")] == nil) then structures = {}; --arrintBeaconStructureCount [targetTerritoryID] = 0;
			-- elseif (structures [WL.StructureType.Custom("Beacon")] == nil) then structures [WL.StructureType.Custom("Beacon")] = 0; arrintBeaconStructureCount [targetTerritoryID] = 0;
			-- else
			if (structures ~= nil and structures [WL.StructureType.Custom("Beacon")] ~= nil) then
				if (arrintBeaconStructureCount [targetTerritoryID] == nil) then arrintBeaconStructureCount [targetTerritoryID] = structures [WL.StructureType.Custom("Beacon")]; end
				arrintBeaconStructureCount [targetTerritoryID] = math.max (0, arrintBeaconStructureCount [targetTerritoryID] -1);
				structures [WL.StructureType.Custom("Beacon")] = arrintBeaconStructureCount [targetTerritoryID];
			end
			impactedTerritory.SetStructuresOpt = structures;
			table.insert (modifiedTerritories, impactedTerritory);
		end

		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, 'Beacon effect dissipates', {}, modifiedTerritories);
		event.RemoveFogModsOpt = priv.FogModIDs [game.Game.TurnNumber];
		addNewOrder(event);
		priv.FogModIDs [game.Game.TurnNumber] = nil;
		Mod.PrivateGameData = priv;
	end
end

--return array list of territory IDs within specified distance from the target territory
function getTerritoriesWithinDistance (game, targetTerritoryID, intMaxDistance)
    local arrTerrProcessed = {}; --list of terrs already processed
    local arrTerrResults = {}; --resultant list of terrs within specified distance
    local arrTerrListToProcess = {}; --terrs remaining to be processed

	local intDepth = 0;
    arrTerrProcessed [targetTerritoryID] = true;
    table.insert(arrTerrResults, targetTerritoryID);
    table.insert(arrTerrListToProcess, targetTerritoryID);

    while (intDepth < intMaxDistance and #arrTerrListToProcess > 0) do
        local intNextTerrID = {};
        for _, terrID in ipairs(arrTerrListToProcess) do
            for neighbourTerrID, _ in pairs (game.Map.Territories [terrID].ConnectedTo) do
                if not arrTerrProcessed[neighbourTerrID] then
                    arrTerrProcessed[neighbourTerrID] = true;
                    table.insert(arrTerrResults, neighbourTerrID);
                    table.insert(intNextTerrID, neighbourTerrID);
                end
            end
        end
        arrTerrListToProcess = intNextTerrID;
        intDepth = intDepth + 1;
    end
    return (arrTerrResults);
end

function split(inputstr, sep)
	if inputstr == nil then return {}; end
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end