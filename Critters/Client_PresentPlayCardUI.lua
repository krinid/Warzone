require("utilities");
-- require("UI_Events");

--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI (game, cardInstance, playCard)
	--when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played
	Game = game; --make client game object available globally

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

	WZcolours = getColours (); --set global variable for WZ usable colours for buttons;

	strPlayerName_cardPlayer = game.Us.DisplayName (nil, false);
	intPlayerID_cardPlayer = game.Us.PlayerID;

	strCardBeingPlayed = game.Settings.Cards[cardInstance.CardID].Name;
	print ("PLAY CARD="..strCardBeingPlayed.."::");

		play_Critters_card (game, cardInstance, playCard);
end

function TargetCardClicked (strText, cards)
	UI.PromptFromList(strText, cards);
end

function TargetPlayerClicked_Fizz(strText)
	local options = map(filter(Game.Game.Players, IsPotentialTarget), PlayerButton);
	UI.PromptFromList(strText, options);
end

--Determines if the player is one we can propose an alliance to.
function IsPotentialTarget(player)
	-- if (Game.Us.ID == player.ID) then return false end; -- can't select self

	if (player.State ~= WL.GamePlayerState.Playing) then return false end; --skip players not alive anymore, or that declined the game

	--if (Game.Settings.SinglePlayer) then return true end; --in single player, allow proposing with everyone
	--return not player.IsAI; --In multi-player, never allow proposing with an AI.
	return (player.State == WL.GamePlayerState.Playing); --return true if they are still playing, false otherwise
end

function PlayerButton (player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end

function play_Critters_card (game, cardInstance, playCard)
	local winPlayCritters = createWindow (game);
	winPlayCritters.setMaxSize (400, 500);
	local rootParent = winPlayCritters.root;
	local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
	UI.CreateLabel (vert).SetText ("[Critters]\n\n").SetColor (getColourCode("card play heading"));

	TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked).SetColor ("#00FFFF");
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
	strCritters_TerritorySelectText = "   Select the territory you wish to Critters (convert from neutral and assign to a player)\n";
	TargetTerritoryClicked(strCritters_TerritorySelectText); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)
	UI.CreateLabel (vert).SetText("_").SetColor ("#151515");

	--add player selection here, default to self but allow to assign to others
	local assignToPlayerID = nil;
	local assignToPlayerName = nil;
	--add config items for can/can't assign to self/others

	--selected territory is  neutral, so apply the Critters order
	assignToPlayerID = intPlayerID_cardPlayer;
	assignToPlayerName = strPlayerName_cardPlayer;
	local arrValidTerrs = getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (game, intPlayerID_cardPlayer, 0, Mod.Settings.CrittersRange or 4000);
	-- local arrValidTerrs = getTerritoriesWithinDistanceFromAPlayerBelongingToAnotherPlayer (game, intPlayerID_cardPlayer, 0, 1);
	game.HighlightTerritories (arrValidTerrs);

	local horzTargetPlayer = UI.CreateHorizontalLayoutGroup (vert);

	if (Mod.Settings.CrittersCanAssignToAnotherPlayer == true) then
		CrittersSelectPlayerButton = UI.CreateButton(horzTargetPlayer).SetText("Select player").SetInteractable (Mod.Settings.CrittersCanAssignToAnotherPlayer).SetColor("#00FFFF").SetOnClick(function ()
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
		CrittersSelectPlayerButton.SetText ("Reselect player");
	end

	TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText ("Assign to: " ..assignToPlayerName);
	UI.CreateLabel (vert).SetText ("   Select the player to assign the target territory to");
	UI.CreateLabel (vert).SetText("_").SetColor ("#151515");

	UI.CreateButton(vert).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetOnClick(
		function ()

			print ("---");
			if (TargetTerritoryID == nil) then UI.Alert ("Pick a target territory"); return; end
			for k,v in pairs (arrValidTerrs) do print (k,v,getTerritoryName (k, game)); end
			print ("SELECT: ".. TargetTerritoryID, getTerritoryName (TargetTerritoryID, game));

			--check for CANCELED request, ie: no territory selected
			if (TargetTerritoryID == nil) then
				UI.Alert ("No territory selected. Please select a territory.");
				return;
			elseif (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= WL.PlayerID.Neutral) then -- territory is not neutral, alert player and cancel
				UI.Alert ("The selected territory is not neutral. Select a different territory that is neutral.");
				TargetTerritoryClicked(strCritters_TerritorySelectText); --bring up the territory select screen again
				return;
			elseif (valueInTable (arrValidTerrs, TargetTerritoryID) == false) then
				UI.Alert ("You must pick a territory within " ..tostring (Mod.Settings.CrittersRange).. " steps from a territory you own; they are highlighted for convenience");
				game.HighlightTerritories (arrValidTerrs);
				TargetTerritoryClicked(strCritters_TerritorySelectText); -- re-invoke the button click event for the 'Select Territory' button
				return;
			end

			-- print ("Critters order input::terr=" .. TargetTerritoryName .."::Neutralize|" .. TargetTerritoryID.."::");
			-- print ("territory="..TargetTerritoryName.."::,ID="..TargetTerritoryID.."::owner=="..game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID.."::neutralOwnerID="..WL.PlayerID.Neutral.."::assignToPlayerID="..assignToPlayerID.."::assignToPlayerName="..assignToPlayerName);

			local strCrittersMessage = strPlayerName_cardPlayer.." Crittersd " .. TargetTerritoryName ..", assigned to "..assignToPlayerName;
			local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
			if (WL.IsVersionOrHigher("5.34.1")) then
				local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Critters", 8, getColourInteger (0, 255, 0))}; --green annotation background for Critters
				playCard(strCrittersMessage, 'Critters|' .. TargetTerritoryID .. "|" .. assignToPlayerID, Mod.Settings.CrittersImplementationPhase or WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
			else
				playCard(strCrittersMessage, 'Critters|' .. TargetTerritoryID .. "|" .. assignToPlayerID, Mod.Settings.CrittersImplementationPhase or WL.TurnPhase.Gift);
			end
			--official playCard action; this plays the card via WZ interface, uses up a card (1 whole card), etc; can't put this in the move list at a specific spot but is required for card usage, etc
			winPlayCritters.close(); --close the popup dialog
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