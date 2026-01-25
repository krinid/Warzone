require("Utilities");

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "SmokeBomb|")) then
        local targetTerritoryID = tonumber(string.sub (order.ModData, 11));
		local td = game.Map.Territories[targetTerritoryID];
		local terrs = {targetTerritoryID};
		local intSmokeBombRange = Mod.Settings.Range; --distance smoke bomb spreads to; 0=targeted territory only; 1=spreads to directly bordering terrs, etc
		local intDuration = Mod.Settings.Duration; --duration in # of turns
		local intTurnExpiry = game.Game.TurnNumber + intDuration;
		local priority = 7000; -- between 6000 and 8999 means it won't obscure a player's own territories

		terrs = getTerritoriesWithinDistance (game, targetTerritoryID, intSmokeBombRange);
		local fogMod = WL.FogMod.Create ('Obscured by smoke bomb', WL.StandingFogLevel.Fogged, priority, terrs, nil);
		local event = WL.GameOrderEvent.Create (order.PlayerID, 'Detonated a smoke bomb', {});
		event.FogModsOpt = {fogMod};
		event.JumpToActionSpotOpt = WL.RectangleVM.Create (td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);

		if (WL.IsVersionOrHigher("5.34.1")) then
			event.TerritoryAnnotationsOpt = { [targetTerritoryID] = WL.TerritoryAnnotation.Create("Smoke Bomb") };
		end

		addNewOrder(event);

		--Store the FogMod IDs so they can be removed on the appropriate turn
		local priv = Mod.PrivateGameData;
		local arrFogModIDs = priv.FogModIDs or {};
		if (arrFogModIDs [intTurnExpiry] == nil) then arrFogModIDs [intTurnExpiry] = {}; end
		table.insert (arrFogModIDs [intTurnExpiry], fogMod.ID);
		priv.FogModIDs = arrFogModIDs;
		priv.FogModIDs = arrFogModIDs;
		Mod.PrivateGameData = priv;
	end
end

function Server_AdvanceTurn_Start (game, addNewOrder)
	--If we have any existing fog mods, remove them
	local priv = Mod.PrivateGameData;
	local arrFogModIDs = priv.FogModIDs or {};

	if (arrFogModIDs [game.Game.TurnNumber] == nil) then print ("nope"); return; end

	--if there are FogMods expiring this turn, remove them
	if (arrFogModIDs [game.Game.TurnNumber] ~= nil) then
		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, 'Smoke bombs dissipate', {});
		event.RemoveFogModsOpt = priv.FogModIDs [game.Game.TurnNumber];
		addNewOrder(event);
		priv.FogModIDs [game.Game.TurnNumber] = nil;
		-- priv.FogModIDs = nil;
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