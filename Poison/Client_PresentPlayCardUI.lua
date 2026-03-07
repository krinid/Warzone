require("utilities");
-- require("UI_Events");

--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI(game, cardInstance, playCard)
    --when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played
    Game = game; --make client game object available globally

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

    strPlayerName_cardPlayer = game.Us.DisplayName(nil, false);
    intPlayerID_cardPlayer = game.Us.PlayerID;
    PrintProxyInfo (cardInstance);
    printObjectDetails (cardInstance, "cardInstance", "[PresentPlayCardUI]");

    strCardBeingPlayed = game.Settings.Cards[cardInstance.CardID].Name;
    print ("PLAY CARD="..strCardBeingPlayed.."::");

    if (strCardBeingPlayed=="Poison") then
        --cast poison
    end
end

function TargetCardClicked (strText, cards)
	UI.PromptFromList(strText, cards);
end

function play_Shield_card(game, cardInstance, playCard)
    print("[SHIELD] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
        UI.CreateLabel (vert).SetText("[SHIELD]\n\n").SetColor(getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Shield on.");

        UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then 
                UI.Alert("You must select a territory you own.");
                return;
            end
            print("[SHIELD] order input::terr=" .. TargetTerritoryName .. "::Shield|" .. TargetTerritoryID .. "::");

            local strShieldMessage = strPlayerName_cardPlayer .. " creates a Shield on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Shield", 8, getColourInteger(0, 0, 255))}; --blue annotation background for Shield
                playCard(strShieldMessage, 'Shield|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards, territoryAnnotation, jumpToActionSpotOpt);
               else
                playCard(strShieldMessage, 'Shield|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards);
            end

            close();
        end);
    end);
end

function play_Phantom_card(game, cardInstance, playCard)
    print("[PHANTOM] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
        UI.CreateLabel (vert).SetText("[PHANTOM]\n\n").SetColor(getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Phantom on.");

        UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then
                UI.Alert("You must select a territory you own.");
                return;
            end
            print("[PHANTOM] order input::terr=" .. TargetTerritoryName .. "::Phantom|" .. TargetTerritoryID .. "::");

            local strPhantomMessage = strPlayerName_cardPlayer .. " creates a Phantom on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Phantom", 8, getColourInteger(0, 100, 0))}; --use Sickly Green for Poison
                playCard(strPhantomMessage, 'Phantom|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strPhantomMessage, 'Phantom|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards);
            end

            close();
        end);
    end);
end

function TargetPlayerClicked_Fizz(strText)
	local options = map(filter(Game.Game.Players, IsPotentialTarget), PlayerButton);
	UI.PromptFromList(strText, options);
end

--Determines if the player is one we can propose an alliance to.
function IsPotentialTarget(player)
	if (Game.Us.ID == player.ID) then return false end; -- can't select self

	if (player.State ~= WL.GamePlayerState.Playing) then return false end; --skip players not alive anymore, or that declined the game

	--if (Game.Settings.SinglePlayer) then return true end; --in single player, allow proposing with everyone
    --return not player.IsAI; --In multi-player, never allow proposing with an AI.
    return (player.State == WL.GamePlayerState.Playing); --return true if they are still playing, false otherwise
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end

function play_Earthquake_card(game, cardInstance, playCard)
    print("[EARTHQUAKE] card play clicked, played by=" .. strPlayerName_cardPlayer);
    EarthquakeGame = game;
    Earthquake_SelectedBonus = nil;

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,400);
        EarthquakeUI = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
        UI.CreateLabel (EarthquakeUI).SetText("[EARTHQUAKE]\n\n").SetColor(getColourCode("card play heading"));
        buttonEarthquakeSelectBonus = UI.CreateButton (EarthquakeUI).SetText("Select Bonus").SetInteractable(false).SetOnClick (function () buttonEarthquakeSelectBonus.SetInteractable(false); Earthquake_SelectedBonusID = UI.InterceptNextBonusLinkClick(EarthquakeTargetSelected); end);
        labelEarthquakeSelectBonus = UI.CreateLabel (EarthquakeUI).SetText("Select the bonus for the earthquake.\n");--.SetColor(getColourCode("card play heading"));
        Earthquake_SelectedBonusID = UI.InterceptNextBonusLinkClick(EarthquakeTargetSelected);
        Earthquake_PlayCardButton = UI.CreateButton(EarthquakeUI).SetColor(WZcolours["Dark Green"]).SetText("Play Card").SetOnClick(function()
            if (Earthquake_SelectedBonus == nil) then
                UI.Alert("You must select a bonus");
                return;
            end

            --[[print(strPlayerName_cardPlayer);
            print(Earthquake_SelectedBonus.ID);
            print(Earthquake_SelectedBonus.Name);]]

            print("[EARTHQUAKE] order input: bonus=" .. Earthquake_SelectedBonus.ID .. "/".. Earthquake_SelectedBonus.Name .." :: Earthquake|" .. Earthquake_SelectedBonus.ID);
            local strEarthquakeMessage = strPlayerName_cardPlayer .. " invokes an Earthquake on bonus " .. Earthquake_SelectedBonus.Name;
            local territoryAnnotation = {}; --{[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Earthquake", 10, getColourInteger(255,0,0))}; --red annotation background for Earthquake
            --table of (array/table of territoryIDs + territory annotation) doesn't work, gives error that it found dictionary, was expecting integer (b/c it's an array of integers)
            --neither does table of 1 element for (each territory + territory annotation) work, gives error that the record has no proxy ID (b/c it's not a single record which has the TerritoryAnnotation proxy type but instead an array, each element of which has a territory annotation proxy type)
            --so just pick 1 territory in the bonus to show the Earthquake
            local EQterritories = {};
            for _, terrID in pairs(game.Map.Bonuses[Earthquake_SelectedBonus.ID].Territories) do
                if (WL.IsVersionOrHigher("5.34.1")) then territoryAnnotation = {[terrID] = WL.TerritoryAnnotation.Create ("Earthquake", 8, getColourInteger (255, 0, 0))}; end --red annotation background for Earthquake
            end
            local jumpToActionSpotOpt = createJumpToLocationObject_Bonus (game, Earthquake_SelectedBonus.ID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                playCard(strEarthquakeMessage, 'Earthquake|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strEarthquakeMessage, 'Earthquake|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards);
            end

            --playCard(strEarthquakeMessage.."1", 'Earthquake1|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards);--, territoryAnnotation, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."2", 'Earthquake2|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, territoryAnnotation);--, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."2.5", 'Earthquake2|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, tAnn, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."3", 'Earthquake3|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, nil, jumpToActionSpotOpt);
            close();
        end);
        labelEarthquake_BonusTerrList = UI.CreateLabel (EarthquakeUI);
    end);
end

function EarthquakeTargetSelected(bonusDetails)
    --[[local targetPlayerName = toPlayerName(targetPlayerID, game);
    print("[EARTHQUAKE] target player selected: " .. targetPlayerName);
    playCard(strPlayerName_cardPlayer .. " invokes Earthquake on " .. targetPlayerName, 'Earthquake|' .. targetPlayerID, WL.TurnPhase.Gift);]]
    local strLabelText = "";
    if (UI.IsDestroyed(labelEarthquake_BonusTerrList)) then return; end --if the button is destroyed, the dialog is closed, so don't do anything
    labelEarthquake_BonusTerrList.SetText ("");
    strLabelText = "\nTerritories in bonus:\n\n";
    Earthquake_PlayCardButton.SetInteractable(true);
    buttonEarthquakeSelectBonus.SetInteractable(true);
    if bonusDetails == nil then return; end
    Earthquake_SelectedBonus = bonusDetails;

    labelEarthquakeSelectBonus.SetText ("Bonus selected: "..bonusDetails.ID.."/"..bonusDetails.Name);
    --buttonEarthquakeSelectBonus.SetText ("Bonus selected: "..bonusDetails.ID.."/"..bonusDetails.Name);

    for _, terrID in pairs(EarthquakeGame.Map.Bonuses[bonusDetails.ID].Territories) do
        strLabelText = strLabelText .. terrID .."/"..EarthquakeGame.Map.Territories[terrID].Name.."\n";
        --UI.CreateLabel (EarthquakeUI).SetText (terrID .."/"..EarthquakeGame.Map.Territories[terrID].Name);
        --UI.CreateButton (vert, game.Map.Territories[terrID].Name .. ": " .. rounding(Mod.PublicGameData.WellBeingMultiplier[terrID], 2), getPlayerColor(game.LatestStanding.Territories[terrID].OwnerPlayerID), function() if WL.IsVersionOrHigher("5.21") then game.HighlightTerritories({terrID}); game.CreateLocatorCircle(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY); end validateTerritory(game.Map.Territories[terrID]); end);
    end
    Game.HighlightTerritories(Game.Map.Bonuses[bonusDetails.ID].Territories);
    Earthquake_PlayCardButton.SetInteractable(true);
    buttonEarthquakeSelectBonus.SetInteractable(true);
    labelEarthquake_BonusTerrList.SetText (strLabelText);
    --close();
end

function play_Tornado_card(game, cardInstance, playCard)
    print("[TORNADO] card play clicked, played by=" .. strPlayerName_cardPlayer);
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
        UI.CreateLabel (vert).SetText("[TORNADO]\n\nSelect a territory to target with a Tornado:").SetColor(getColourCode("card play heading"));
        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to target with Tornado");
        UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("You must select a territory");
                return;
            end
            print("[TORNADO] order input: territory=" .. TargetTerritoryName .. " :: Tornado|" .. TargetTerritoryID);
            local strTornadoMessage = strPlayerName_cardPlayer .. " invokes a Tornado on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Tornado", 8, getColourInteger (255, 0, 0))}; --red annotation background for Tornado
                playCard(strTornadoMessage, 'Tornado|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strTornadoMessage, 'Tornado|' .. TargetTerritoryID, WL.TurnPhase.Gift);
            end
            close();
        end);
    end);
end

function play_Quicksand_card(game, cardInstance, playCard)
    print("[QUICKSAND] card play clicked, played by=" .. strPlayerName_cardPlayer);
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
        UI.CreateLabel (vert).SetText("[QUICKSAND]\n\nSelect a territory to convert into quicksand:").SetColor(getColourCode("card play heading"));
        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to apply Quicksand to");
        UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            print("[QUICKSAND] order input: territory=" .. TargetTerritoryName .. " :: Quicksand|" .. TargetTerritoryID);
            local strQuicksandMessage = strPlayerName_cardPlayer .. " transforms " .. TargetTerritoryName .. " into quicksand";
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Quicksand", 8, getColourInteger (255, 0, 0))}; --red annotation background for Quicksand
                playCard(strQuicksandMessage, 'Quicksand|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strQuicksandMessage, 'Quicksand|' .. TargetTerritoryID, WL.TurnPhase.Gift);
            end
            close();
        end);
    end);
end

function play_Monolith_card(game, cardInstance, playCard)
    print ("[MONOLITH] card play clicked, played by=" .. strPlayerName_cardPlayer.."::");
    --
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
        UI.CreateLabel (vert).SetText ("[MONOLITH]\n\n").SetColor (getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Monolith on."); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)
    
        UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(function() 

        --check for CANCELED request, ie: no territory selected
        if (TargetTerritoryID == nil) then
            UI.Alert("No territory selected. Please select a territory.");
            return;
        end
        if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then 
            -- client player does not own this territory, alert player and cancel
            UI.Alert("You must select a territory you own.");
            return;
        end
        print ("[MONOLITH] order input::terr=" .. TargetTerritoryName .."::Monolith|" .. TargetTerritoryID.."::");

        local strMonolithMessage = strPlayerName_cardPlayer.." creates a Monolith on " .. TargetTerritoryName;
        local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
        if (WL.IsVersionOrHigher("5.34.1")) then
            local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Monolith", 8, getColourInteger (0, 0, 255))}; --blue annotation background for Shield
            playCard(strMonolithMessage, 'Monolith|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
        else
            playCard(strMonolithMessage, 'Monolith|' .. TargetTerritoryID, WL.TurnPhase.Gift);
        end
        close();
        end);
    end);
end

function play_Deneutralize_card (game, cardInstance, playCard)
	local winPlayDeneutralize = createWindow (game);
	winPlayDeneutralize.setMaxSize (400, 500);
	local rootParent = winPlayDeneutralize.root;
	local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
	UI.CreateLabel (vert).SetText ("[DENEUTRALIZE]\n\n").SetColor (getColourCode("card play heading"));

	TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked).SetColor ("#00FFFF");
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
	strDeneutralize_TerritorySelectText = "   Select the territory you wish to deneutralize (convert from neutral and assign to a player)\n";
	TargetTerritoryClicked(strDeneutralize_TerritorySelectText); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)
	UI.CreateLabel (vert).SetText("_").SetColor ("#151515");

	--add player selection here, default to self but allow to assign to others
	local assignToPlayerID = nil;
	local assignToPlayerName = nil;
	--add config items for can/can't assign to self/others

	--selected territory is  neutral, so apply the deneutralize order
	assignToPlayerID = intPlayerID_cardPlayer;
	assignToPlayerName = strPlayerName_cardPlayer;
	local arrValidTerrs = getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (game, intPlayerID_cardPlayer, 0, Mod.Settings.DeneutralizeRange or 4000);
	-- local arrValidTerrs = getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (game, intPlayerID_cardPlayer, 0, 1);
	game.HighlightTerritories (arrValidTerrs);

	local horzTargetPlayer = UI.CreateHorizontalLayoutGroup (vert);

	if (Mod.Settings.DeneutralizeCanAssignToAnotherPlayer == true) then
		DeneutralizeSelectPlayerButton = UI.CreateButton(horzTargetPlayer).SetText("Select player").SetInteractable (Mod.Settings.DeneutralizeCanAssignToAnotherPlayer).SetColor("#00FFFF").SetOnClick(function ()
			local winSelectPlayer = createWindow (game);
			winSelectPlayer.setMaxSize (600, 500);
			UI.CreateLabel (winSelectPlayer.root).SetText ("Select player to assign target territory to:\n");
				--generate list of players for popup to select from; exclude self & eliminated (non-active) players; include AIs - game.Game.PlayingPlayers provides this list (compared to game.Game.Players which includes all players ever associated to the game, even those that declined the invite, were removed by host, etc)
				local numUserButtonsCreated = 0;
				for playerID,player in pairs(game.Game.PlayingPlayers) do
					UI.CreateButton(winSelectPlayer.root).SetText("Assign to: " ..toPlayerName(playerID,game)).SetColor (player.Color.HtmlColor).SetOnClick(function () assignToPlayerID = playerID; assignToPlayerName = getPlayerName (game, playerID); UI.Destroy (TargetPlayerLabel); TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText (assignToPlayerName); winSelectPlayer.close(); end);
					numUserButtonsCreated = numUserButtonsCreated + 1;
				end
				winSelectPlayer.setMaxSize (600, math.min (800, numUserButtonsCreated * 100));
		end);
		DeneutralizeSelectPlayerButton.SetText ("Reselect player");
	end

	TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText ("Assign to: " ..assignToPlayerName);
	UI.CreateLabel (vert).SetText ("   Select the player to assign the target territory to");
	UI.CreateLabel (vert).SetText("_").SetColor ("#151515");

	UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(
		function ()

			print ("---");
			for k,v in pairs (arrValidTerrs) do print (k,v,getTerritoryName (k, game)); end
			print ("SELECT: ".. TargetTerritoryID, getTerritoryName (TargetTerritoryID, game));

			--check for CANCELED request, ie: no territory selected
			if (TargetTerritoryID == nil) then
				UI.Alert ("No territory selected. Please select a territory.");
				return;
			elseif (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= WL.PlayerID.Neutral) then -- territory is not neutral, alert player and cancel
				UI.Alert ("The selected territory is not neutral. Select a different territory that is neutral.");
				TargetTerritoryClicked(strDeneutralize_TerritorySelectText); --bring up the territory select screen again
				return;
			elseif (valueInTable (arrValidTerrs, TargetTerritoryID) == false) then
				UI.Alert ("You must pick a territory within " ..tostring (Mod.Settings.DeneutralizeRange).. " steps from a territory you own; they are highlighted for convenience");
				game.HighlightTerritories (arrValidTerrs);
				TargetTerritoryClicked(strDeneutralize_TerritorySelectText); -- re-invoke the button click event for the 'Select Territory' button
				return;
			end

			-- print ("Deneutralize order input::terr=" .. TargetTerritoryName .."::Neutralize|" .. TargetTerritoryID.."::");
			-- print ("territory="..TargetTerritoryName.."::,ID="..TargetTerritoryID.."::owner=="..game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID.."::neutralOwnerID="..WL.PlayerID.Neutral.."::assignToPlayerID="..assignToPlayerID.."::assignToPlayerName="..assignToPlayerName);

			local strDeneutralizeMessage = strPlayerName_cardPlayer.." deneutralized " .. TargetTerritoryName ..", assigned to "..assignToPlayerName;
			local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
			if (WL.IsVersionOrHigher("5.34.1")) then
				local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Deneutralize", 8, getColourInteger (0, 255, 0))}; --green annotation background for Deneutralize
				playCard(strDeneutralizeMessage, 'Deneutralize|' .. TargetTerritoryID .. "|" .. assignToPlayerID, Mod.Settings.DeneutralizeImplementationPhase or WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
			else
				playCard(strDeneutralizeMessage, 'Deneutralize|' .. TargetTerritoryID .. "|" .. assignToPlayerID, Mod.Settings.DeneutralizeImplementationPhase or WL.TurnPhase.Gift);
			end
			--official playCard action; this plays the card via WZ interface, uses up a card (1 whole card), etc; can't put this in the move list at a specific spot but is required for card usage, etc
			winPlayDeneutralize.close(); --close the popup dialog
		end
	);
end

function play_Neutralize_card (game, cardInstance, playCard)
    --[[-- test writing to Mod.PublicGameData, Mod.PrivateGameData, Mod.PlayerGameData
    -- all data must be saved to a code construct, then have the code construct assigned the the Mod.Public/Private/PlayerGameData construct; can't modify variable values directly
    local data = Mod.PublicGameData;
    publicGameData = Mod.PublicGameData; --readable from anywhere, writeable only from Server hooks
    --privateGameData = Mod.PrivateGameData;  --readable only from Server hooks
    playerGameData = Mod.PlayerGameData;  --readable/writeable from both Client & Server hooks
        --Client hooks can only access data for the user associated with the Client hook (current player), doesn't need index b/c it can only access data for current player, automatically gets assigned playerID of current player
        --Server hooks access this using an index of playerID
    publicGameData.someProperty = "this is some public data";
    publicGameData.anotherProperty = "this is some public data";]]

    game.CreateDialog(
        function(rootParent, setMaxSize, setScrollable, game, close)
            setMaxSize(400, 300);
            local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
            UI.CreateLabel (vert).SetText ("[NEUTRALIZE]\n\n").SetColor (getColourCode("card play heading"));

            TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
            TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
            strNeutralize_TerritorySelectText = "Select the territory you wish to neutralize (turn to neutral).";
            TargetTerritoryClicked(strNeutralize_TerritorySelectText); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

            UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(
                function() 
                    --check for CANCELED request, ie: no territory selected
                    if (TargetTerritoryID == nil) then
                        UI.Alert("No territory selected. Please select a territory.");
                        return;
                    elseif (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral) then -- territory is already neutral, alert player and cancel
                        UI.Alert("The selected territory is already neutral. Select a different territory that is owned by a player.");
                        TargetTerritoryClicked(strNeutralize_TerritorySelectText); --bring up the territory select screen again
                        return;
                    end

                    --selected territory is not neutral, so apply the neutralize order
                    --print ("[!player!] Neutralize order input prep::");
                    print ("Neutralize order input::terr=" .. TargetTerritoryName .."::Neutralize|" .. TargetTerritoryID.."::");
                    print ("territory="..TargetTerritoryName.."::,ID="..TargetTerritoryID.."::owner=="..game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID.."::neutralOwnerID="..WL.PlayerID.Neutral);

                    --implement order in ReceiveGold phase for now; doing it in BombCards phase causes error if opponents (AIs in my testing) move specials (commander) on the neutralized units; orders never reach Server_AdvanceTurn_Start or _Order
                    local strNeutralizeMessage = strPlayerName_cardPlayer.." neutralized " .. TargetTerritoryName;
                    local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
                    if (WL.IsVersionOrHigher("5.34.1")) then
                        local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Neutralize", 8, getColourInteger (128, 128, 128))}; --use Light Grey colour for Neutralize
                        playCard(strNeutralizeMessage, 'Neutralize|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
                    else
                        playCard(strNeutralizeMessage, 'Neutralize|' .. TargetTerritoryID, WL.TurnPhase.Gift);
                    end
                    --official playCard action; this plays the card via WZ interface, uses up a card (1 whole card), etc; can't put this in the move list at a specific spot but is required for card usage, etc
                    close(); --close the popup dialog
                end
            );
        end
    );
end

function TargetTerritoryClicked (strLabelText) --TargetTerritoryInstructionLabel, TargetTerritoryBtn)
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
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
	end
end

function TargetPlayerClicked(strTextLabel)
	local players = filter(Game.Game.Players, function (p) return p.ID ~= Game.Us.ID end);
	local options = map(players, PlayerButton);
	UI.PromptFromList(strTextLabel, options);
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
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