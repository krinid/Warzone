function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Recon+|")) then
        local targetTerritoryID = tonumber(string.sub (order.ModData, 8));
		local td = game.Map.Territories[targetTerritoryID];
		local terr = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];
		-- local structures = terr.Structures;
		-- if (structures == nil) then structures = {}; end;
	    -- local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);
		local terrs = {targetTerritoryID};
		local intReconRange = Mod.Settings.Range; --distance Recon+ spreads to; 0=targeted territory only; 1=spreads to directly bordering terrs, etc
		local intDuration = Mod.Settings.Duration; --duration in # of turns
		local intTurnExpiry = game.Game.TurnNumber + intDuration;
		local priority = 7500; -- Smoke Bomb uses 7000, Phantom uses 8000 (default), so this reveals with priority over their fog; between 6000 and 8999 means it won't obscure a player's own territories

		local arrPlayerIDsToMakeVisible = getTeamPlayers (game, order.PlayerID); --get all players on the same team as the card player
		terrs = getTerritoriesWithinDistance (game, targetTerritoryID, intReconRange);
		local fogMod = WL.FogMod.Create ('Revealed by Recon+|'..tostring (targetTerritoryID), WL.StandingFogLevel.Visible, priority, terrs, arrPlayerIDsToMakeVisible);

		-- if (structures [WL.StructureType.Custom("Recon+")] == nil) then structures [WL.StructureType.Custom("Recon+")] = 1;
		-- else structures [WL.StructureType.Custom("Recon+")] = structures [WL.StructureType.Custom("Recon+")] + 1;
		-- end
		-- impactedTerritory.SetStructuresOpt = structures;

		local event = WL.GameOrderEvent.Create (order.PlayerID, 'Cast a Recon+', {}, {});
		event.FogModsOpt = {fogMod};
		event.JumpToActionSpotOpt = WL.RectangleVM.Create (td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);
		event.TerritoryAnnotationsOpt = { [targetTerritoryID] = WL.TerritoryAnnotation.Create("Recon+") };
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
	-- local modifiedTerritories = {};

	if (arrFogModIDs [game.Game.TurnNumber] == nil) then print ("nope"); return; end

	--if there are FogMods expiring this turn, remove them
	if (arrFogModIDs [game.Game.TurnNumber] ~= nil) then
		-- local arrintReconStructureCount = {};
		-- for k,v in pairs (arrFogModIDs [game.Game.TurnNumber]) do
		-- 	-- print ("FOGMOD: "..tostring (v).. " / ".. tostring (v.ID) .." / ".. tostring (v.Priority) .." / ".. tostring (v.Message));
		-- 	fogmod = game.ServerGame.LatestTurnStanding.FogModsOpt [v];
		-- 	-- print ("FOGMOD: "..tostring (fogmod).. " / ".. tostring (fogmod.ID) .." / ".. tostring (fogmod.Priority) .." / ".. tostring (fogmod.Message));
		-- 	local targetTerritoryID = (split (fogmod.Message, '|'))[2]; --don't actually need this
		-- 	local terr = game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID];
		-- 	local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);
		-- 	local structures = terr.Structures;

		-- 	if (structures ~= nil and structures [WL.StructureType.Custom("Recon+")] ~= nil) then
		-- 		if (arrintReconStructureCount [targetTerritoryID] == nil) then arrintReconStructureCount [targetTerritoryID] = structures [WL.StructureType.Custom("Recon+")]; end
		-- 		arrintReconStructureCount [targetTerritoryID] = math.max (0, arrintReconStructureCount [targetTerritoryID] -1);
		-- 		structures [WL.StructureType.Custom("Recon+")] = arrintReconStructureCount [targetTerritoryID];
		-- 	end
		-- 	impactedTerritory.SetStructuresOpt = structures;
		-- 	table.insert (modifiedTerritories, impactedTerritory);
		-- end

		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, 'Recon+ effect dissipates', {}, modifiedTerritories);
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

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

--return an array of all playerIDs for the team that the parameter playerID belongs to, including playerID itself
--if playerID is not on a team or teams aren't in use, return just the playerID itself (single element array)
function getTeamPlayers (game, playerID)
	local teamPlayerIDs = {};
	--if playerID is nil, neutral or <1, return empty array and exit function; (technically Neutral is 0 so <1 so not requried, but include it here in case WL.PlayerID.Neutral changes someday)
	if (playerID == nil or playerID == WL.PlayerID.Neutral or playerID <1) then return (teamPlayerIDs); end

	print ("[GETTEAMPLAYERS] player " ..playerID.. --[[ "/" ..getPlayerName (game, playerID).. ]] ", team " ..game.ServerGame.Game.Players[playerID].Team);

	--playerID is not on a team, so return just playerID)
	if (game.ServerGame.Game.Players[playerID].Team == -1) then
		table.insert(teamPlayerIDs, playerID);
		print ("[GETTEAMPLAYERS] no team - add single element only");
	else
		--playerID is on a team; looping through all players will inherently include playerID itself iff playerID is on a team (b/c -1==no team is specifically weeded out in the comparison in the loop), so no need to explicitly add playerID
		for _,v in pairs (game.ServerGame.Game.Players) do
			if (v.Team ~= -1 and v.Team == game.ServerGame.Game.Players[playerID].Team) then
				table.insert(teamPlayerIDs, v.ID);
			end
		end
	end
	print ("\n\n\n\nTEAM player count ".. #teamPlayerIDs);
	for k,v in pairs (teamPlayerIDs) do print ("team playerID #"..k..", "..v--[[ .."/"..getPlayerName (game, v) ]]); end
	return (teamPlayerIDs);
end