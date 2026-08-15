require ('Bomb+ common');

function Client_PresentPlayCardUI (game, cardInstance, playCard)
    --when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

    WZcolours = getColours (); --set global variable for WZ usable colours for buttons;

    strPlayerName_cardPlayer = game.Us.DisplayName (nil, false);
    intPlayerID_cardPlayer = game.Us.PlayerID;

    strCardBeingPlayed = game.Settings.Cards [cardInstance.CardID].Name;
    print ("PLAY CARD="..strCardBeingPlayed.."::");
	play_Landmine_card (game, cardInstance, playCard);
end

function play_Landmine_card(game, cardInstance, playCard)
    print("[LANDMINE] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog (function (rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize (400, 600);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth (1);
        UI.CreateLabel (vert).SetText ("[LANDMINE]\n\n").SetColor (getColourCode ("card play heading"));
		UI.CreateLabel (vert).SetText (game.Settings.Cards [cardInstance.CardID].FriendlyDescription.. "\n \n");
		UI.CreateLabel (vert).SetText ("\n \n");
		UI.CreateEmpty (vert);
		UI.CreateLabel (vert).SetText ("_").SetColor ("#000000");

        TargetTerritoryBtn = UI.CreateButton (vert).SetText ("Select Territory").SetOnClick (TargetTerritoryClicked).SetColor (getColourCode ("minor heading"));
        TargetTerritoryInstructionLabel = UI.CreateLabel (vert).SetText ("");
        TargetTerritoryClicked ("Select the territory you wish to set a landmine on");

        UI.CreateButton (vert).SetText ("Play Card").SetColor(WZcolours ["Dark Green"]).SetOnClick (function ()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end

			local boolTargetIsSelf = game.LatestStanding.Territories [TargetTerritoryID].OwnerPlayerID == game.Us.ID;
			local boolTargetIsNeutral = game.LatestStanding.Territories [TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral;
			local boolTaretIsTeammate = game.Us.Team ~= -1 and game.Game.Players [game.LatestStanding.Territories [TargetTerritoryID].OwnerPlayerID].Team == game.Us.Team;
			local intDistanceToTarget = getDistanceToPlayersNearestTerritory (game, TargetTerritoryID, game.Us.ID);

			if (boolTargetIsSelf == false and boolTargetIsNeutral == false and boolTaretIsTeammate == false) then
				UI.Alert("You must place a landmine on a territory you own (or belongs to a teammate if a team game) or a neutral territory.");
                return;
			elseif (intDistanceToTarget > Mod.Settings.LandmineCastRange) then
                UI.Alert("You must set a landmine within " ..tonumber (Mod.Settings.LandmineCastRange).. " steps of a territory you own.");
                return;
            end

            local strLandmineMessage = strPlayerName_cardPlayer .. " plays a Landmine card on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
			local intTurnPhase = (Mod.Settings.LandmineImplementationPhase ~= nil and Mod.Settings.LandmineImplementationPhase) or (Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards);
			-- UI.Alert (intTurnPhase.. ", " ..WL.TurnPhase.ToString (intTurnPhase));

			if (WL.IsVersionOrHigher ("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine", 8, getColourInteger (0, 0, 0))}; --use Black for Bomb
                playCard (strLandmineMessage, 'Landmine|' .. TargetTerritoryID, intTurnPhase, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard (strLandmineMessage, 'Landmine|' .. TargetTerritoryID, intTurnPhase);
            end

            close();
        end);
    end);
end

--return true if player borders the territory; false otherwise
function doesPlayerBorderTerritory (game, intTerritoryID, intPlayerID)
	for _, conn in pairs (game.Map.Territories [intTerritoryID].ConnectedTo) do
		if (game.LatestStanding.Territories [conn.ID].OwnerPlayerID == intPlayerID) then return true; end
	end
	return false;
end

function TargetTerritoryClicked (strLabelText) --TargetTerritoryInstructionLabel, TargetTerritoryBtn)
	UI.InterceptNextTerritoryClick (TerritoryClicked);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText (strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable (false);
end

function TerritoryClicked (terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
    TargetTerritoryBtn.SetInteractable (true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText ("");
		TargetTerritoryID = nil;
        TargetTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText ("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
	end
end

function TargetPlayerClicked (strTextLabel)
	local players = filter (Game.Game.Players, function (p) return p.ID ~= Game.Us.ID end);
	local options = map (players, PlayerButton);
	UI.PromptFromList (strTextLabel, options);
end

function PlayerButton (player)
	local name = player.DisplayName (nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText (name);
		TargetPlayerID = player.ID;
	end
	return ret;
end

-- return distance from specific territory to the nearest territory owned by specified player
-- returns:
--   intDistance, intClosestTerritoryID
--   -1, nil  --> if no territory found (player has no territories / unreachable)
function getDistanceToPlayersNearestTerritory (game, sourceTerritoryID, targetPlayerID)
	local arrTerrProcessed = {};        -- terrs already processed
	local arrTerrListToProcess = {};    -- terrs remaining to be processed (current depth layer)
	local intDepth = 0;

	arrTerrProcessed [sourceTerritoryID] = true;
	table.insert (arrTerrListToProcess, sourceTerritoryID);

	-- check depth 0 case (source itself)
	if (game.LatestStanding.Territories [sourceTerritoryID].OwnerPlayerID == targetPlayerID) then return 0, sourceTerritoryID; end

	while (#arrTerrListToProcess > 0) do
		local arrNextTerrList = {};
		intDepth = intDepth + 1;
		for _, terrID in ipairs (arrTerrListToProcess) do
			for neighbourTerrID, _ in pairs (game.Map.Territories [terrID].ConnectedTo) do
				if not arrTerrProcessed [neighbourTerrID] then
					arrTerrProcessed [neighbourTerrID] = true;
					-- ownership check
					if (game.LatestStanding.Territories [neighbourTerrID].OwnerPlayerID == targetPlayerID) then
						return intDepth, neighbourTerrID; -- nearest match (guaranteed shortest)
					end
					table.insert (arrNextTerrList, neighbourTerrID);
				end
			end
		end
		arrTerrListToProcess = arrNextTerrList;
	end

	return -1, nil; -- player has no reachable territories
end