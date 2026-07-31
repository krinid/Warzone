--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI(game, cardInstance, playCard)
    --when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played
    Game = game; --make client game object available globally

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

    strPlayerName_cardPlayer = game.Us.DisplayName (nil, false);
    intPlayerID_cardPlayer = game.Us.PlayerID;
    strCardBeingPlayed = game.Settings.Cards [cardInstance.CardID].Name;
    print ("PLAY CARD="..strCardBeingPlayed.."::");

    if (strCardBeingPlayed == "Poison") then play_Poison_card (game, cardInstance, playCard); end
end

function TargetCardClicked (strText, cards)
	UI.PromptFromList(strText, cards);
end


function createDialog (rootParent, setMaxSize, setScrollable, game, close)
	PoisonDialog = {rootParent=rootParent, setMaxSize=setMaxSize, setScrollable=setScrollable, game=game, close=close};
	return (PoisonDialog); --unfortunately this return value is ignored b/c it is passed back to the calling parameter of game.CreateDialog and thus need to pass the real value back as a global variable
end

function play_Poison_card (game, cardInstance, playCard)
    print("[POISON] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");
	local intCastRange = Mod.Settings.PoisonCastRange or 4000; --default to 4000 if not set in the mod settings (cast anywhere on map)

	PoisonDialog = nil; --set global variable to nil, assign value in createDialog function
	game.CreateDialog (createDialog);
	PoisonDialog.setMaxSize (500, 400);
	local vert = UI.CreateVerticalLayoutGroup (PoisonDialog.rootParent).SetFlexibleWidth (1);
	UI.CreateLabel (vert).SetText ("[POISON]\n\n").SetColor (getColourCode ("card play heading"));

	TargetTerritoryBtn = UI.CreateButton (vert).SetText ("Select Territory").SetOnClick (TargetTerritoryClicked).SetColor (getColourCode ("Button|Cyan"));
	TargetTerritoryInstructionLabel = UI.CreateLabel (vert).SetText ("");
	TargetTerritoryClicked("Select the territory to spew Poison on.");

	-- local arrValidTerrs = getTerritoriesWithinDistance (game, intPlayerID_cardPlayer, Mod.Settings.PoisonCastRange or 4000);
	local arrValidTerrs = getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (Game, intPlayerID_cardPlayer, -1, (Mod.Settings.PoisonCastRange or 1));
	game.HighlightTerritories (arrValidTerrs);

	UI.CreateButton (vert).SetText ("Play Card").SetColor (getColourCode ("Button|Green")).SetOnClick (function()
		if (TargetTerritoryID == nil) then
			UI.Alert("No territory selected. Please select a territory.");
			return;
		end

		local intDistanceToTargetTerritory = getDistanceToPlayersNearestTerritory (game, TargetTerritoryID, intPlayerID_cardPlayer);
		if (intDistanceToTargetTerritory == -1 or intDistanceToTargetTerritory > intCastRange) then
			UI.Alert ("Selected territory must be within distance of " ..tostring (intCastRange).. " from a territory you own. Selected territory is distance of " ..tostring (intDistanceToTargetTerritory).. ".");
			return;
		end
		-- if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then
		-- 	UI.Alert("You must select a territory you own.");
		-- 	return;
		-- end
		-- print("[POISON] order input::terr=" .. TargetTerritoryName .. "::Phantom|" .. TargetTerritoryID .. "::");

		local strPoisonMessage = strPlayerName_cardPlayer .. " spews Poison on " .. TargetTerritoryName;
		local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
		local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Poison", 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison  
		playCard (strPoisonMessage, 'Poison|' .. TargetTerritoryID, WL.TurnPhase.BombCards, territoryAnnotation, jumpToActionSpotOpt);
		PoisonDialog.close ();
	end);
end

function TargetTerritoryClicked (strLabelText)
	UI.InterceptNextTerritoryClick (TerritoryClicked);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked (terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
    TargetTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		TargetTerritoryID = nil;
        TargetTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText ("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
		local arrImpactedTerrs = getTerritoriesWithinDistance (Game, TargetTerritoryID, (Mod.Settings.PoisonImpactRange or 1));
		Game.HighlightTerritories (arrImpactedTerrs);
	end
end

function getColours()
    local colors = {};					-- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
	colors.WZyellow = "#ABA500"; colors.WZgreen = "#198225"; colors["WZLight Blue"] = "#50B2E3"; colors.WZblue = "#242D9A"; colors.WZred = "#9A2929";
    return colors;
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="ok" or itemName=="Button|Green") then return getColours()["WZgreen"]; --standard green used for "Ok" buttons
	elseif (itemName=="selection" or itemName=="Button|Cyan") then return getColours()["Cyan"]; --standard green used for "Ok" buttons
	elseif (itemName=="Card|Reinforcement") then return getColours()["Dark Green"]; --standard green used for "Ok" buttons
	elseif (itemName=="Card|Spy") then return getColours()["Red"]; --
	elseif (itemName=="Card|Emergency Blockade card") then return getColours()["Royal Blue"]; --
	elseif (itemName=="Card|OrderPriority") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|OrderDelay") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Airlift") then return "#777777"; --
	elseif (itemName=="Card|Gift") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Diplomacy") then return getColours()["Light Blue"]; --
	-- elseif (itemName=="Card|") then return getColours()["Medium Blue"]; --
	elseif (itemName=="Card|Sanctions") then return getColours()["Purple"]; --
	elseif (itemName=="Card|Reconnaissance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Surveillance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Blockade") then return getColours()["Blue"]; --
	elseif (itemName=="Card|Bomb") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Bomb+ Card") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Nuke") then return getColours()["Tyrian Purple"]; --
	elseif (itemName=="Card|Airstrike") then return getColours()["Ivory"]; --
	elseif (itemName=="Card|Pestilence") then return getColours()["Lime"]; --
	elseif (itemName=="Card|Isolation") then return getColours()["Red"]; --
	elseif (itemName=="Card|Shield") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Monolith") then return getColours()["Hot Pink"]; --
	elseif (itemName=="Card|Card Block") then return getColours()["Light Blue"]; --
	elseif (itemName=="Card|Card Pieces") then return getColours()["Sea Green"]; --
	elseif (itemName=="Card|Card Hold") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Phantom") then return getColours()["Smoky Black"]; --
	elseif (itemName=="Card|Neutralize") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Deneutralize") then return getColours()["Green"]; --
	elseif (itemName=="Card|Earthquake") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Tornado") then return getColours()["Charcoal"]; --
	elseif (itemName=="Card|Quicksand") then return getColours()["Saddle Brown"]; --
	elseif (itemName=="Card|Forest Fire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Wildfire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Resurrection") then return getColours()["Goldenrod"]; --
	elseif (itemName=="Card|Fort Card") then return getColours()["Donkey Brown"]; --
	elseif (itemName=="Phase|Purchase") then return "#007700";
	elseif (itemName=="Phase|CardsWearOff") then return "#964B00";
	elseif (itemName=="Phase|Discards") then return "#654321";
	elseif (itemName=="Phase|OrderPriorityCards") then return getColours()["Yellow"];
	elseif (itemName=="Phase|SpyingCards") then return getColours()["Red"];
	elseif (itemName=="Phase|ReinforcementCards") then return getColours()["Dark Green"];
	elseif (itemName=="Phase|Deploys") then return "#00BB00";
	elseif (itemName=="Phase|BombCards") then return getColours()["Dark Magenta"];
	elseif (itemName=="Phase|EmergencyBlockadeCards") then return getColours()["Royal Blue"];
	elseif (itemName=="Phase|Airlift") then return "#777777";
	elseif (itemName=="Phase|Gift") then return getColours()["Aqua"];
	elseif (itemName=="Phase|Attacks") then return "#FF0000";
	elseif (itemName=="Phase|BlockadeCards") then return getColours()["Blue"];
	elseif (itemName=="Phase|DiplomacyCards") then return getColours()["Light Blue"];
	elseif (itemName=="Phase|SanctionCards") then return getColours()["Purple"];
	elseif (itemName=="Phase|ReceiveCards") then return "#005500";
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
    else return "#AAAAAA"; --return light grey for everything else
    end
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create (1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

-- returns array of territory IDs belonging to targetPlayerID (0=neutral, -1=all territories within distance regardless of which player or neutral) within distance intMaxDistance from any terr belonging to mainPlayerID
function getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (game, mainPlayerID, targetPlayerID, intMaxDistance)
  local arrTerrProcessed = {};        -- list of terrs already processed
    local arrTerrResults = {};          -- resultant list of matching terrs
    local arrTerrListToProcess = {};    -- terrs remaining to be processed

    local intDepth = 0;
	print ("[HIGHLIGHT TERRS] max distance " .. tostring (intMaxDistance) .. ", Mod setting " ..tostring (Mod.Settings.PoisonCastRange).. ", from player " .. tostring (mainPlayerID) .. " to player " .. tostring (targetPlayerID));

    -- initialize BFS with all territories owned by mainPlayerID
    for terrID, terrObj in pairs (game.LatestStanding.Territories) do
        if (terrObj.OwnerPlayerID == mainPlayerID) then
            arrTerrProcessed[terrID] = true;
            table.insert(arrTerrListToProcess, terrID);
        end
    end

    -- if main player owns no territories, return empty result
    if (#arrTerrListToProcess == 0) then
        return arrTerrResults;
    end

    -- -- depth 0 check (only matters if mainPlayerID == targetPlayerID)
    -- if (mainPlayerID == targetPlayerID) then
    --     for _, terrID in ipairs(arrTerrListToProcess) do
    --         table.insert(arrTerrResults, terrID);
    --     end
    -- end

    while (intDepth < intMaxDistance and #arrTerrListToProcess > 0) do
        local arrNextTerrList = {};
        intDepth = intDepth + 1;

        for _, terrID in ipairs(arrTerrListToProcess) do
            for neighbourTerrID, _ in pairs (game.Map.Territories[terrID].ConnectedTo) do
                if not arrTerrProcessed[neighbourTerrID] then
                    arrTerrProcessed[neighbourTerrID] = true;

                    -- ownership filter
                    if (targetPlayerID == -1 or game.LatestStanding.Territories[neighbourTerrID].OwnerPlayerID == targetPlayerID) then
                        table.insert(arrTerrResults, neighbourTerrID);
                    end

                    table.insert(arrNextTerrList, neighbourTerrID);
                end
            end
        end

        arrTerrListToProcess = arrNextTerrList;
    end

    return arrTerrResults;
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