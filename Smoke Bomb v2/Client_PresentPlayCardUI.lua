require('Utilities')

--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI(game, cardInstance, playCard, closeCardsDialog)
    Game = game;

    --If this dialog is already open, close the previous one. This prevents two copies of it from being open at once which can cause errors due to only saving one instance of TargetTerritoryBtn
    if (Close ~= nil) then
        Close();
    end

	if (WL.IsVersionOrHigher("5.34")) then --closeCardsDialog callback did not exist prior to 5.34
        closeCardsDialog();
    end

    --If your mod has multiple cards, you can look at game.Settings.Cards[cardInstance.CardID].Name to see which one was played
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        Close = close;
        setMaxSize(400, 400);
        local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked).SetColor ("#00FFFF");
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

        UI.CreateButton(vert).SetText("Play Card").SetColor ("#008000").SetOnClick(function()
            if (TargetTerritoryID == nil) then
                TargetTerritoryInstructionLabel.SetText("You must select a territory first");
                return;
            end
            local td = game.Map.Territories[TargetTerritoryID];

            local annotations = nil;
            local jumpToSpot = nil;

            if (WL.IsVersionOrHigher("5.34.1")) then
                annotations = { [TargetTerritoryID] = WL.TerritoryAnnotation.Create("Smoke Bomb") };
                jumpToSpot = WL.RectangleVM.Create(td.MiddlePointX, td.MiddlePointY, td.MiddlePointX, td.MiddlePointY);
            end


            if (playCard ("Detonate a smoke bomb on " .. TargetTerritoryName, "SmokeBomb|" .. TargetTerritoryID, WL.TurnPhase.Deploys, annotations, jumpToSpot)) then
                close();
            end

		end);

	local strDescription = "\nSmoke bomb range: " ..tostring (Mod.Settings.Range) .. "\nDuration: " ..tostring (Mod.Settings.Duration).. " turn(s)";
	UI.CreateLabel (vert).SetText (strDescription);
	TargetTerritoryClicked (); --automatically prompt for territory selection
    end);
end



function TargetTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	TargetTerritoryInstructionLabel.SetText("Please click on the territory you wish to detonate a smoke bomb on.  If needed, you can move this dialog out of the way.");
	TargetTerritoryBtn.SetInteractable(false);
end


function TerritoryClicked(terrDetails)
	if UI.IsDestroyed(TargetTerritoryBtn) then
		-- Dialog was destroyed, so we don't need to intercept the click anymore
		return WL.CancelClickIntercept;
	end

    TargetTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
        TargetTerritoryID = nil;
        TargetTerritoryName = nil;
    else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
		local arrSmokeBombTerrs = getTerritoriesWithinDistance (Game, terrDetails.ID, Mod.Settings.Range); --get resultant set of territories that Smoke Bomb will impact & highlight them
		Game.HighlightTerritories (arrSmokeBombTerrs); --highlight the impacted terrs

		-- print (terrDetails.ID,terrDetails.Name);
		--compare to 71, Mauritania
		print ("Distance from 71/Mauritania to " ..terrDetails.ID .."/" ..terrDetails.Name .." is " .. tostring (getTerritoryDistance (Game, 71, terrDetails.ID)));
		local intDistance, closestTerrID = getDistanceToPlayersNearestTerritory (Game, terrDetails.ID, 1);
		print ("Distance from " ..terrDetails.ID .."/" ..terrDetails.Name .." to AI1 is " ..tostring (intDistance) .. " @ " ..intDistance .."/".. Game.Map.Territories [closestTerrID].Name);
		local intDistanceAB, playerAterrID, playerBterrID = getShortestDistanceBetweenPlayers (Game, 1, 1058239);
		print ("players "..Game.Game.Players[1].ID, Game.Game.Players[1058239].ID);
		print ("Distance from player[1] and player [2] is " ..tostring (intDistanceAB).. " between " .. tostring (playerAterrID) .."/" .." and " .. tostring (playerBterrID) .. "/");
		print ("Distance from player[1] and player [2] is " ..tostring (intDistanceAB).. " between " .. tostring (playerAterrID) .."/" ..tostring (Game.Map.Territories [playerAterrID].Name) .." and " .. tostring (playerBterrID) .. "/" ..tostring (Game.Map.Territories [playerBterrID].Name));
	end
end

-- return integer distance between two territories
-- returns:
--   0  = same territory
--   n  = number of hops between territories
--   -1 = not reachable (shouldn't happen on valid maps, but safe)
function getTerritoryDistance (game, sourceTerritoryID, targetTerritoryID)
	if (sourceTerritoryID == targetTerritoryID) then return 0; end --same territory, distance is 0

	local arrTerrProcessed = {};        -- terrs already processed
	local arrTerrListToProcess = {};    -- terrs remaining to be processed (current depth layer)
	local intDepth = 0;

	arrTerrProcessed[sourceTerritoryID] = true;
	table.insert (arrTerrListToProcess, sourceTerritoryID);

	while (#arrTerrListToProcess > 0) do
		local arrNextTerrList = {};
		intDepth = intDepth + 1;
		for _, terrID in ipairs(arrTerrListToProcess) do
			for neighbourTerrID, _ in pairs (game.Map.Territories[terrID].ConnectedTo) do
				if (neighbourTerrID == targetTerritoryID) then
					return (intDepth); -- shortest path found
				end
				if not arrTerrProcessed[neighbourTerrID] then
					arrTerrProcessed[neighbourTerrID] = true;
					table.insert(arrNextTerrList, neighbourTerrID);
				end
			end
		end
		arrTerrListToProcess = arrNextTerrList;
	end
	return (-1); -- target is not reached from source
end

-- return distance from specific territory to the nearest territory owned by specified player
-- returns:
--   intDistance, intClosestTerritoryID
--   -1, nil  --> if no territory found (player has no territories / unreachable)
function getDistanceToPlayersNearestTerritory (game, sourceTerritoryID, targetPlayerID)
	local arrTerrProcessed = {};        -- terrs already processed
	local arrTerrListToProcess = {};    -- terrs remaining to be processed (current depth layer)
	local intDepth = 0;

	arrTerrProcessed[sourceTerritoryID] = true;
	table.insert(arrTerrListToProcess, sourceTerritoryID);

	-- check depth 0 case (source itself)
	if (game.LatestStanding.Territories[sourceTerritoryID].OwnerPlayerID == targetPlayerID) then return 0, sourceTerritoryID; end

	while (#arrTerrListToProcess > 0) do
		local arrNextTerrList = {};
		intDepth = intDepth + 1;
		for _, terrID in ipairs(arrTerrListToProcess) do
			for neighbourTerrID, _ in pairs (game.Map.Territories[terrID].ConnectedTo) do
				if not arrTerrProcessed[neighbourTerrID] then
					arrTerrProcessed[neighbourTerrID] = true;
					-- ownership check
					if (game.LatestStanding.Territories[neighbourTerrID].OwnerPlayerID == targetPlayerID) then
						return intDepth, neighbourTerrID; -- nearest match (guaranteed shortest)
					end
					table.insert(arrNextTerrList, neighbourTerrID);
				end
			end
		end
		arrTerrListToProcess = arrNextTerrList;
	end

	return -1, nil; -- player has no reachable territories
end

-- return shortest distance between two players
-- returns:
--   intDistance, intPlayerATerritoryID, intPlayerBTerritoryID
--   -1, nil, nil  --> if no path exists (disconnected graph / invalid state)

function getShortestDistanceBetweenPlayers (game, playerAID, playerBID)
    local arrTerrProcessed = {};        -- terrs already processed
    local arrTerrListToProcess = {};    -- terrs remaining to be processed (current depth layer)
    local arrTerrOrigin = {};           -- map: terrID -> originating Player A territory
    local intDepth = 0;

    -- initialize BFS frontier with all Player A territories
    for terrID, terrObj in pairs(game.LatestStanding.Territories) do
        if (terrObj.OwnerPlayerID == playerAID) then
            arrTerrProcessed[terrID] = true;
            arrTerrOrigin[terrID] = terrID; -- origin is itself
            table.insert (arrTerrListToProcess, terrID);
        end
    end

    -- edge case: no territories for one of the players
    if (#arrTerrListToProcess == 0) then
        return -1, nil, nil;
    end

    -- check depth 0 overlap (same territory ownership impossible, but safe)
    for _, terrID in ipairs(arrTerrListToProcess) do
        if (game.LatestStanding.Territories[terrID].OwnerPlayerID == playerBID) then
            return 0, terrID, terrID;
        end
    end

    while (#arrTerrListToProcess > 0) do
        local arrNextTerrList = {};
        intDepth = intDepth + 1;
        for _, terrID in ipairs(arrTerrListToProcess) do
            local intOriginTerrID = arrTerrOrigin[terrID];
            for neighbourTerrID, _ in pairs (game.Map.Territories[terrID].ConnectedTo) do
                if not arrTerrProcessed[neighbourTerrID] then
                    arrTerrProcessed[neighbourTerrID] = true;
                    arrTerrOrigin[neighbourTerrID] = intOriginTerrID;

                    -- check if this neighbour belongs to Player B
                    if (game.LatestStanding.Territories[neighbourTerrID].OwnerPlayerID == playerBID) then
                        return intDepth, intOriginTerrID, neighbourTerrID;
                    end

                    table.insert(arrNextTerrList, neighbourTerrID);
                end
            end
        end
        arrTerrListToProcess = arrNextTerrList;
    end

    return -1, nil, nil; -- players not connected
end

--return array list of territory IDs within specified distance from the target territory
function getTerritoriesWithinDistance (game, targetTerritoryID, intMaxDistance)
    local arrTerrProcessed = {}; --list of terrs already processed
    local arrTerrResults = {}; --resultant list of terrs within specified distance
    local arrTerrListToProcess = {}; --terrs remaining to be processed

	local intDepth = 0;
    arrTerrProcessed [targetTerritoryID] = true;
    table.insert (arrTerrResults, targetTerritoryID);
    table.insert (arrTerrListToProcess, targetTerritoryID);

    while (intDepth < intMaxDistance and #arrTerrListToProcess > 0) do
        local intNextTerrID = {};
        for _, terrID in ipairs(arrTerrListToProcess) do
            for neighbourTerrID, _ in pairs (game.Map.Territories [terrID].ConnectedTo) do
                if not arrTerrProcessed [neighbourTerrID] then
                    arrTerrProcessed [neighbourTerrID] = true;
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