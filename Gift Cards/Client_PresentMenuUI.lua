function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)
	local vert = UI.CreateVerticalLayoutGroup (rootParent);
	setMaxSize (400, 400);
	-- if (game.Settings.CommerceGame == false) then
	-- 	horz = UI.CreateHorizontalLayoutGroup (vert);
	-- 	UI.CreateLabel (horz).SetText ("This mod cannot function in this game because it is not a Commerce game");
	-- 	return;
	-- end

	if (game.Us == nil) then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText ("Spectators cannot use this mod");
		return;
	else
		localPlayerID = game.Us.ID;
	end

	-- if(game.Game.PlayingPlayers[game.Us.ID] == nil)then
	-- 	horz = UI.CreateHorizontalLayoutGroup(vert);
	-- 	UI.CreateLabel(horz).SetText("You have been eliminated, so menu is disabled");
	-- 	return;
	-- end

	UI.CreateLabel (vert).SetText ("[GIFT CARDS]\n").SetColor (getColourCode ("card play heading"));
	-- getDefinedCardList (game);
	displayMenu (game, vert, close);

	--debug data for error in game https://www.warzone.com/MultiPlayer?GameID=42876634
	-- if (game.Us ~= nil and game.Us.ID == 1058239) then
	-- 	game.CreateDialog (showDebugWindow); --show Debug Window to output debug data to
	-- end
end

function displayMenu (game, windowUI, close)
	--showDefinedCards (Game);
	local publicGameData = Mod.PublicGameData;
	-- local localPlayerIsHost = game.Us ~= nil and game.Us.ID == game.Settings.StartedBy;
	-- local localPlayerIsPlayerInGame = (game.Us ~= nil) and (game.Game.PlayingPlayers[game.Us.ID] ~= nil);
	-- if (game.Game.ID == 41159857 and game.Us ~= nil and game.Us.ID == 1058239) then localPlayerIsHost = true; end --"Encirclement + Forts v2b" game; host is not in game so can't set card prices (oops) - manual fix to permit krinid to set card prices
	-- if (game.Game.ID == 41661316 and game.Us ~= nil and game.Us.ID == 1058239) then localPlayerIsHost = true; end --"Biohazard" game; host is not in game so can't set card prices (oops) - manual fix to permit krinid to set card prices
	-- if (game.Game.ID == 40767112 and game.Us.ID == 1058239) then localPlayerIsHost = true; publicGameData.CardData.CardPricesFinalized = false; publicGameData.CardData.HostHasAdjustedPricing = false; end --for this game, re-assign card prices
	-- if (game.Game.ID == 40767112 and game.Us.ID == 1058239) then publicGameData.CardData.CardPricesFinalized = true; publicGameData.CardData.HostHasAdjustedPricing = true; end --for this game, re-assign card prices

	print ("Local player: " .. tostring (game.Us.ID));
	print ("game.LatestStanding.Cards==nil --> "..tostring (game.LatestStanding.Cards == nil));
	print ("game.LatestStanding.Cards [game.Us.ID]==nil --> "..tostring (game.LatestStanding.Cards [game.Us.ID]== nil));
	for k,v in pairs (game.LatestStanding.Cards) do
		print ("[CARDS] Player "..k);
		for k2,vp in pairs (v.Pieces) do
			print ("[PIECES] "..k,k2,vp);
		end
		for k3,vwc in pairs (v.WholeCards) do
			print ("[CARDS] "..k,k3,vwc.CardID);
		end
	end

	-- captureCardCounts ();
	local vertHeader = UI.CreateVerticalLayoutGroup (windowUI).SetFlexibleWidth (1);
	local strPrompt = "Select player to gift to";
	UI.CreateLabel (vertHeader).SetText ("Select a player to give cards or card pieces to");
	targetPlayerBtn = nil; --no target player selected yet
	targetPlayerBtn = UI.CreateButton (vertHeader).SetText ("[Select a player]").SetOnClick (function() targetPlayerClicked (game, strPrompt); end).SetColor (getColourCode ("minor heading"));
	-- UI.CreateLabel (vertHeader).SetText ("");
	-- targetPlayerBtn = UI.CreateButton (vert).SetText("Select player").SetColor ("#00FFFF").SetOnClick(function() targetPlayerClicked (strPrompt); end);
	targetPlayerClicked (game, strPrompt); --bring up the dialog

	UI.CreateButton (vertHeader).SetColor (getColourCode ("ok")).SetText("Add Gift Order").SetOnClick (function () executeGiftAction (game, targetPlayerID); end);

	UI.CreateEmpty (vertHeader);

	local vertRegularCards = UI.CreateVerticalLayoutGroup (vertHeader).SetFlexibleWidth (1);
	-- UI.CreateLabel (vertRegularCards).SetText ("\nStandard cards:").SetColor (getColourCode ("subheading"));
	local horz = UI.CreateHorizontalLayoutGroup (vertRegularCards); --.SetPreferredWidth (340);
	UI.CreateLabel (horz).SetText ("Standard cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (150);
	if (Mod.Settings.CanGiftWholeCards == true) then UI.CreateLabel (horz).SetText ("[cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (80); end
	if (Mod.Settings.CanGiftCardPieces == true) then UI.CreateLabel (horz).SetText ("[pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70); end

	--[[ local horz = UI.CreateHorizontalLayoutGroup(vertRegularCards).SetFlexibleWidth (1);
	UI.CreateLabel (horz).SetText ("\nStandard cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (150);
	UI.CreateLabel (horz).SetText ("[whole cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70);
	UI.CreateLabel (horz).SetText ("[card pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70); ]]

	--[[ local rowCardDetails = UI.CreateHorizontalLayoutGroup (vertRegularCards).SetFlexibleWidth (1);
	UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText ("Standard cards");
	UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
	UI.CreateButton (rowCardDetails).SetText ("^").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("a");
	UI.CreateButton (rowCardDetails).SetText ("v").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("b");
	UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
	UI.CreateButton (rowCardDetails).SetText ("^").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("c");
	UI.CreateButton (rowCardDetails).SetText ("v").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("d"); ]]

	--[[ local rowCardDetails = UI.CreateHorizontalLayoutGroup (vertRegularCards).SetFlexibleWidth (1);
	UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText ("Standard cards");
	UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.4).SetPreferredWidth (90).SetText ("1");
	-- UI.CreateButton (rowCardDetails).SetText ("^").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("a");
	-- UI.CreateButton (rowCardDetails).SetText ("v").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("b");
	UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.4).SetPreferredWidth (90).SetText ("2");
	-- UI.CreateButton (rowCardDetails).SetText ("^").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("c");
	-- UI.CreateButton (rowCardDetails).SetText ("v").SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("d"); ]]

	local vertCustomCards = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	-- UI.CreateLabel (vertCustomCards).SetText ("\nCustom cards:").SetColor (getColourCode ("subheading"));
	local horz = UI.CreateHorizontalLayoutGroup (vertCustomCards); --.SetPreferredWidth (340);
	UI.CreateLabel (horz).SetText ("Custom cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (150);
	if (Mod.Settings.CanGiftWholeCards == true) then UI.CreateLabel (horz).SetText ("[cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (80); end
	if (Mod.Settings.CanGiftCardPieces == true) then UI.CreateLabel (horz).SetText ("[pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70); end

	local cardCountTotal = 0;
	local cardCountRegular = 0;
	local cardCountCustom = 0;
	tboxNumWholeCards = {};
	tboxNumCardPieces = {};
	-- intCardIDs = {}; --store card IDs; the 3 arrays are parallel, using same indexes to align to a single card ID

	for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
		cardCountTotal = cardCountTotal + 1;
		-- intCardIDs [cardCountTotal] = cardID;

		--regular cards go in the Vert area and are listed at the top
		--custom cards go in the Vert area and are listed at the bottom
		--if client player is host & cards aren't finalized, then add sliders and use a horizontal layout group to organize the labels & sliders -- but don't use hori groups for non-host players b/c it adds unnecessary vertical space and less buttons fit on a single viewing window
		local targetUI = vertRegularCards;

		-- this is a custom card; custom cards are >=1000000
		if (cardRecord.ID >= 1000000) then
			targetUI = vertCustomCards;
			cardCountCustom = cardCountCustom + 1;
			-- if (cardRecord.Price>0) then cardCountCustom_Buyable = cardCountCustom_Buyable + 1; cardCountTotal_Buyable = cardCountTotal_Buyable + 1; end
		else --this is a regular card; regular cards are <1000000
			cardCountRegular = cardCountRegular + 1;
			-- if (cardRecord.Price>0) then cardCountRegular_Buyable = cardCountRegular_Buyable + 1; cardCountTotal_Buyable = cardCountTotal_Buyable + 1; end
		end

		local interactable = true; --set .SetInteractable of buttons to this value; set to True when WholeCards/CardPieces can be gifted

		local strColourCode = getColourCode ("Card|"..tostring (cardRecord.Name));
		-- local intIndex = cardCountTotal;
		local intNumWholeCards = getWholeCardCount (game, game.Us.ID, cardRecord.ID);
		print ("[GET WC/CP] card Name " ..tostring (cardRecord.Name) .. ", card ID " ..tostring (cardRecord.ID) ..", #WC " ..tostring (intNumWholeCards));
		-- if (game.LatestStanding.Cards [game.Us.ID] ~= nil and game.LatestStanding.Cards [game.Us.ID].WholeCards [tonumber(cardRecord.ID)] ~= nil) then intNumWholeCards = game.LatestStanding.Cards [game.Us.ID].WholeCards [tonumber(cardRecord.ID)] or 0; end
		local intNumCardPieces = getCardPieceCount (game, game.Us.ID, cardRecord.ID);
		-- if (game.LatestStanding.Cards [game.Us.ID] ~= nil and game.LatestStanding.Cards [game.Us.ID].Pieces [cardRecord.ID] ~= nil) then intNumCardPieces = game.LatestStanding.Cards [game.Us.ID].Pieces [cardRecord.ID] or 0; end
		local strButtonMsg = cardRecord.Name .. " [" .. tostring (intNumWholeCards) .. "//" .. tostring (intNumCardPieces) .. "]";

		if (intNumWholeCards == 0 and intNumCardPieces == 0) then
			interactable = false;
		else

 			--[[local rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1).SetPreferredWidth (340);
			UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetInteractable (interactable).SetText ("Standard cards:").SetColor (strColourCode);
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetInteractable (interactable).SetText ("Standard cards:").SetColor (strColourCode);
			UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (horz).SetText ("Standard cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (200);
			-- UI.CreateLabel (horz).SetText ("[whole cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70);
			-- UI.CreateLabel (horz).SetText ("[card pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70);]]

 			--[[local rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1).SetPreferredWidth (340);
			-- UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetInteractable (interactable).SetText ("Standard cards:").SetColor (strColourCode);
			UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText ("Standard cards:").SetColor (strColourCode);
			-- UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (horz).SetText ("Standard cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (200);
			-- UI.CreateLabel (horz).SetText ("[whole cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70);
			-- UI.CreateLabel (horz).SetText ("[card pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70); ]]

			--[[local  rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1).SetPreferredWidth (340);
			UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetInteractable (interactable).SetText ("Standard cards:").SetColor (strColourCode);
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText ("Standard cards:").SetColor (strColourCode);
			UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (70).SetText ("0");
			-- UI.CreateLabel (horz).SetText ("Standard cards:").SetColor (getColourCode ("subheading")).SetPreferredWidth (200);
			-- UI.CreateLabel (horz).SetText ("[whole cards]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70);
			-- UI.CreateLabel (horz).SetText ("[card pieces]").SetColor (getColourCode ("minor heading")).SetPreferredWidth (70); ]]

			--ACTUAL
			local rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1).SetPreferredWidth (340);
			UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetInteractable (interactable).SetText (strButtonMsg).SetColor (strColourCode);
			if (Mod.Settings.CanGiftWholeCards == true) then
				tboxNumWholeCards [cardID] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
				UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumWholeCards[cardID].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[cardID].GetText ())+1)))); end).SetColor (strColourCode);
				UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumWholeCards[cardID].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[cardID].GetText ())-1)))); end).SetColor (strColourCode);
			end
			if (Mod.Settings.CanGiftCardPieces == true) then
				tboxNumCardPieces [cardID] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
				UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumCardPieces[cardID].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[cardID].GetText ())+1)))); end).SetColor (strColourCode);
				UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumCardPieces[cardID].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[cardID].GetText ())-1)))); end).SetColor (strColourCode);
			end

			-- local rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1);
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText (strButtonMsg).SetColor (strColourCode);
			-- tboxNumWholeCards [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumWholeCards[intIndex].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[intIndex].GetText ())+1)))); end).SetColor (strColourCode);
			-- UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumWholeCards[intIndex].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[intIndex].GetText ())-1)))); end).SetColor (strColourCode);
			-- tboxNumCardPieces [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumCardPieces[intIndex].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[intIndex].GetText ())+1)))); end).SetColor (strColourCode);
			-- UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetOnClick (function() tboxNumCardPieces[intIndex].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[intIndex].GetText ())-1)))); end).SetColor (strColourCode);

			-- local rowCardDetails = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth (1);
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (200).SetText (strButtonMsg).SetColor (strColourCode);
			-- tboxNumWholeCards [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("^");
			-- UI.CreateLabel (rowCardDetails).SetFlexibleWidth (0.1).SetPreferredWidth (10).SetText ("v");
			-- tboxNumCardPieces [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetPreferredWidth (50).SetText ("0");
			-- UI.CreateLabel (rowCardDetails).SetText ("^").SetFlexibleWidth (0.1).SetPreferredWidth (10);
			-- UI.CreateLabel (rowCardDetails).SetText ("v").SetFlexibleWidth (0.1).SetPreferredWidth (10);

			-- UI.CreateButton (rowCardDetails).SetFlexibleWidth (0.6).SetInteractable (interactable).SetText (strButtonMsg).SetColor (strColourCode);
			-- tboxNumWholeCards [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetText ("0");
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetOnClick (function() tboxNumWholeCards[intIndex].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[intIndex].GetText ())+1)))); end).SetColor (strColourCode);
			-- UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetOnClick (function() tboxNumWholeCards[intIndex].SetText (tostring (math.min (intNumWholeCards, math.max (0, tonumber (tboxNumWholeCards[intIndex].GetText ())-1)))); end).SetColor (strColourCode);
			-- tboxNumCardPieces [cardCountTotal] = UI.CreateTextInputField (rowCardDetails).SetFlexibleWidth (0.2).SetText ("0");
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetInteractable (interactable).SetFlexibleWidth (0.1).SetOnClick (function() tboxNumCardPieces[intIndex].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[intIndex].GetText ())+1)))); end).SetColor (strColourCode);
			-- UI.CreateButton (rowCardDetails).SetText ("v").SetInteractable (interactable).SetFlexibleWidth (0.1).SetOnClick (function() tboxNumCardPieces[intIndex].SetText (tostring (math.min (intNumCardPieces, math.max (0, tonumber (tboxNumCardPieces[intIndex].GetText ())-1)))); end).SetColor (strColourCode);

			-- NIFnumWholeCards = UI.CreateNumberInputField (rowCardDetails).SetSliderMinValue (0).SetSliderMaxValue (1).SetValue (0).SetWholeNumbers (true).SetBoxPreferredWidth (50).SetSliderPreferredWidth (1);
			-- NIFnumWholeCards = UI.CreateNumberInputField (rowCardDetails).SetBoxPreferredWidth (50).SetSliderPreferredWidth (1).SetSliderMinValue (0).SetSliderMaxValue (1).SetValue (0).SetWholeNumbers (true);
			-- NIFnumCardPieces = UI.CreateNumberInputField (rowCardDetails).SetPreferredWidth (10).SetBoxPreferredWidth (50).SetSliderPreferredWidth (0).SetSliderMinValue (1).SetSliderMaxValue (1).SetValue (0).SetWholeNumbers (true);
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- UI.CreateButton (rowCardDetails).SetText ("^").SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- UI.CreateButton (rowCardDetails).SetText ("v").SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- UI.CreateButton (rowCardDetails).SetText ("^↑▲").SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- UI.CreateButton (rowCardDetails).SetText ("v↓▼").SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- local vertUpDownButtons = UI.CreateVerticalLayoutGroup (rowCardDetails);
			-- UI.CreateButton (vertUpDownButtons).SetText ("^↑▲").SetPreferredHeight (20).SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			-- UI.CreateButton (vertUpDownButtons).SetText ("v↓▼").SetPreferredHeight (20).SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
			--▲▼ ↑↓ ^v
		end
	end

	--disable debug data until needed again
	if (false) then --game.Us.ID == 1058239) then
		DebugWindow = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
		UI.CreateLabel (DebugWindow).SetText ("\n\n- - - - - [DEBUG DATA START] - - - - -");
		UI.CreateLabel (DebugWindow).SetText ("Server time: "..game.Game.ServerTime);
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountRegular.." standard card(s) in game, "..cardCountRegular_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountCustom.. " custom card(s)], "..cardCountCustom_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountTotal.." total card(s)], "..cardCountTotal_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("Prices finalized == "..tostring(publicGameData.CardData.CardPricesFinalized));

		if (game.Us~=nil) then --a player in the game
			--UI.CreateLabel (DebugWindow).SetText ("text \n\nClient player");
			UI.CreateLabel (DebugWindow).SetText ("Client player "..game.Us.ID .."/"..toPlayerName (game.Us.ID, game)..", State: "..tostring(game.Game.Players[game.Us.ID].State).."/"..tostring(WLplayerStates ()[game.Game.Players[game.Us.ID].State]).. ", IsActive: "..tostring(game.Game.Players[game.Us.ID].State == WL.GamePlayerState.Playing).. ", IsHost: "..tostring(localPlayerIsHost));
		else
			--client local player is a Spectator, don't reference game.Us which ==nil
			UI.CreateLabel (DebugWindow).SetText ("Client player is Spectator");
		end

		UI.CreateLabel (DebugWindow).SetText ("\nGame host: "..game.Settings.StartedBy.."/".. toPlayerName(game.Settings.StartedBy, game));

		UI.CreateLabel (DebugWindow).SetText ("\nPlayers in the game:");
		for k,v in pairs (game.Game.Players) do
			--local strPlayerIsHost = "";
			--if (localPlayerIsHost) then strPlayerIsHost = " [HOST]"; end
			UI.CreateLabel (DebugWindow).SetText ("   Player "..k .."/"..toPlayerName (k, game)..", State: "..tostring(v.State).."/"..tostring(WLplayerStates ()[v.State]).. ", IsActive: "..tostring(game.Game.Players[k].State == WL.GamePlayerState.Playing) .. ", IsHost: "..tostring (k == game.Settings.StartedBy));
		end
		UI.CreateLabel (DebugWindow).SetText ("- - - - - [DEBUG DATA END] - - - - -");
	end
end

function pluralForm (num)
	if (num == 1) then return "";
	else return "s";
	end
end

function executeGiftAction (game, targetPlayerID)
	print ("[EXECUTE GIFT ACTION] targetPlayerID==" ..tostring (targetPlayerID));
	if (targetPlayerID == nil) then UI.Alert ("Select a player to gift to"); return; end
	print ("[EXECUTE GIFT ACTION] targetPlayerName==" ..game.Game.Players [targetPlayerID].DisplayName (nil, false));

	local strOrderContent = "Gift Cards|" ..tostring (targetPlayerID);
	local strOrderMessage = "Gift cards to '" ..toPlayerName (targetPlayerID, game) .."': ";
	local strOrderMessageCardInfo = "";
	local intNumWholeCardsToGift = 0;
	local intNumCardPiecesToGift = 0;

	for k,v in pairs (Mod.Settings.CanGiftWholeCards == true and tboxNumWholeCards or tboxNumCardPieces) do
		local intNumWholeCards = Mod.Settings.CanGiftWholeCards == true and math.min (tonumber (tboxNumWholeCards [k].GetText ()), getWholeCardCount (game, localPlayerID, k)) or 0;
		local intNumCardPieces = Mod.Settings.CanGiftCardPieces == true and math.min (tonumber (tboxNumCardPieces [k].GetText ()), getCardPieceCount (game, localPlayerID, k)) or 0;
		print("Card " ..k.. "/" ..Mod.PublicGameData.CardData.DefinedCards[k].Name.. ", WC " ..intNumWholeCards.. ", CP " ..intNumCardPieces);

		if (intNumWholeCards + intNumCardPieces > 0) then

			strOrderContent = strOrderContent .. "|" ..tostring (k) .. ":" ..intNumWholeCards .. "," .. intNumCardPieces;
			if (strOrderMessageCardInfo ~= "") then strOrderMessageCardInfo = strOrderMessageCardInfo .. ", "; end
			strOrderMessageCardInfo = strOrderMessageCardInfo .. Mod.PublicGameData.CardData.DefinedCards[k].Name.. " (";

			if (intNumWholeCards > 0 and intNumCardPieces > 0) then
				strOrderMessageCardInfo = strOrderMessageCardInfo .. tostring (intNumWholeCards).. " card" ..pluralForm (intNumWholeCards).. " & " ..tostring (intNumCardPieces).. " piece" ..pluralForm (intNumCardPieces);
			elseif (intNumWholeCards > 0) then
				strOrderMessageCardInfo = strOrderMessageCardInfo .. tostring (intNumWholeCards).. " card" ..pluralForm (intNumWholeCards);
			elseif (intNumCardPieces > 0) then
				strOrderMessageCardInfo = strOrderMessageCardInfo .. tostring (intNumCardPieces) .. " piece" ..pluralForm (intNumCardPieces);
			end

			strOrderMessageCardInfo = strOrderMessageCardInfo .. ")";
			intNumWholeCardsToGift = intNumWholeCardsToGift + intNumWholeCards;
			intNumCardPiecesToGift = intNumCardPiecesToGift + intNumCardPieces;
		end
	end
	strOrderMessage = strOrderMessage .. strOrderMessageCardInfo;
	print ("[GIFT ACTION] [order content]" ..strOrderContent);
	print ("[GIFT ACTION] [order message]" ..strOrderMessage);

	if (strOrderMessageCardInfo == "") then
		UI.Alert ("Select at least 1 card or card piece to gift");
		return;
	else
		local order = WL.GameOrderCustom.Create (game.Us.ID, strOrderMessage, strOrderContent);

		local orders = game.Orders;
		if (game.Us.HasCommittedOrders == true) then
			UI.Alert ("You must uncommit first");
			return;
		else
			table.insert (orders, order);
			game.Orders = orders;
		end
	end

	-- local strGiftSummary = "[GIFT ACTION] ";
	-- for k,v in pairs (tboxNumWholeCards) do
	-- 	strGiftSummary = strGiftSummary .. "cardID="..tostring (k)..", wholeCards="..tostring (v.GetText ()).. " | ";
	-- end
	-- for k,v in pairs (tboxNumCardPieces) do
	-- 	strGiftSummary = strGiftSummary .. "cardID="..tostring (k)..", cardPieces="..tostring (v.GetText ()).. " | ";
	-- end
	-- print (strGiftSummary);

	-- for k,v in pairs (tboxNumWholeCards) do
	-- 	print ("[GIFT ACTION] whole cards, cardID=="..tostring (k)..", numCards=="..tostring (v.GetText ()));

	-- end
	-- for k,v in pairs (tboxNumCardPieces) do
	-- 	print ("[GIFT ACTION] card pieces, cardID=="..tostring (k)..", numCardPieces=="..tostring (v.GetText ()));
	-- 	-- for each card, send a custom order with the number of whole cards and card pieces to gift; include the card ID in the payload so the server can identify which card to gift, and include the number of whole cards and pieces to gift in the payload so the server can verify that the client isn't trying to gift more cards than they have
	-- 	-- format the payload like "Gift Cards|targetPlayerID|cardID|numWholeCardsToGift|numCardPiecesToGift"
	-- end
end

function map (array, func)
	local new_array = {}
	local i = 1;
	for _,v in pairs (array) do
		new_array [i] = func(v);
		i = i + 1;
	end
	return new_array
end

function filter (array, func)
	local new_array = {}
	local i = 1;
	for _,v in pairs(array) do
		if (func (v)) then
			new_array [i] = v;
			i = i + 1;
		end
	end
	return new_array
end

function targetPlayerClicked (game, strText)
	local options = map (filter (game.Game.Players, isPotentialTarget), PlayerButton);
	UI.PromptFromList (strText, options);
end

--Determines if the player is one we can propose an alliance to.
function isPotentialTarget (player)
	if (localPlayerID == player.ID) then return false end; -- can't select self

	if (player.State ~= WL.GamePlayerState.Playing) then return false end; --skip players not alive anymore, or that declined the game

	--if (Game.Settings.SinglePlayer) then return true end; --in single player, allow proposing with everyone
    --return not player.IsAI; --In multi-player, never allow proposing with an AI.
    return (player.State == WL.GamePlayerState.Playing); --return true if they are still playing, false otherwise
end

function PlayerButton (player)
	local name = player.DisplayName (nil, false);
	local ret = {};
	-- ret ["text"] = name;
	ret ["player"] = player.ID;
	ret ["selected"] =
		function ()
			targetPlayerBtn.SetText (name);
			targetPlayerID = player.ID;
		end
	return ret;
end

function WLplayerStates ()
	local WLplayerStatesTable = {
		[WL.GamePlayerState.Invited] = 'Invited',
		[WL.GamePlayerState.Playing] = 'Playing',
		[WL.GamePlayerState.Eliminated] = 'Eliminated',
		[WL.GamePlayerState.Won] = 'Won',
		[WL.GamePlayerState.Declined] = 'Declined',
		[WL.GamePlayerState.RemovedByHost] = 'RemovedByHost',
		[WL.GamePlayerState.SurrenderAccepted] = 'SurrenderAccepted',
		[WL.GamePlayerState.Booted] = 'Booted',
		[WL.GamePlayerState.EndedByVote] = 'EndedByVote'
	};
	return WLplayerStatesTable;
end

function toPlayerName (playerid, game)
	if (playerid ~= nil) then
		if (playerid < 50) then
				return ("AI"..playerid);
		else
			for _,playerinfo in pairs (game.Game.Players) do
				if(playerid == playerinfo.ID) then
					return (playerinfo.DisplayName (nil, false));
				end
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found
end

function showDefinedCards (game)
    print ("[PresentMenuUI] CARD OVERVIEW");

    local cards = getDefinedCardList (game);

    local strText = "";
    for k,v in pairs (cards) do
        if (k>=1000000) then strText = strText .. "\n"..v.." / ["..k.."]"; end
    end
    labelStuff = UI.CreateLabel (vert);
	strText = "\n\nCUSTOM CARDS THAT NEED PRICES ASSIGNED:"..strText;
    labelStuff.SetText (strText.."\n");
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
function getDefinedCardList (game)
	print ("[CARDS DEFINED IN THIS GAME]");
	local count = 0;
	local cards = {};
	local publicGameData = Mod.PublicGameData;

	publicGameData.CardData = {};
	publicGameData.CardData.DefinedCards = nil;
	--Mod.PublicGameData = publicGameData;

	if (game==nil) then print ("game is nil"); return nil; end
	if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
	if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end
	print ("game==nil --> "..tostring (game==nil).."::");
	print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
	print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
	--print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
	--print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
	--print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));

	for cardID, cardConfig in pairs(game.Settings.Cards) do
		local strCardName = getCardName_fromObject(cardConfig);
		--print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces.."::");
		cards[cardID] = strCardName;
		count = count +1
		--printObjectDetails (cardConfig, "cardConfig");
	end
	--printObjectDetails (cards, "card", count .." defined cards total");
	return cards;
end

--given a card name, return it's cardID
function getCardID (strCardNameToMatch, game)
	--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
	local cards={};
	print ("[getCardID] match name=="..strCardNameToMatch.."::");
	print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
	print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
	print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
	print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));
	if (Mod.PublicGameData.CardData.DefinedCards == nil) then
		print ("run function");
		cards = getDefinedCardList (game);
	else
		print ("get from pgd");
		cards = Mod.PublicGameData.CardData.DefinedCards;
	end

	--print ("[getCardID] tablelength=="..tablelength (cards));
	for cardID, strCardName in pairs(cards) do
		--print ("[getCardID] cardID=="..cardID..", cardName=="..strCardName.."::");
		if (strCardName == strCardNameToMatch) then
			--print ("[getCardID] matching card cardID=="..cardID.."::");
			return cardID;
		end
	end
	return nil; --cardName not found
end

function getCardName_fromID(cardID, game);
	print ("cardID=="..cardID);
	local cardConfig = game.Settings.Cards[tonumber(cardID)];
	return getCardName_fromObject (cardConfig);
end

function getCardName_fromObject(cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
	if cardConfig.proxyType == 'CardGameCustom' then
		return cardConfig.Name;
	end

	if cardConfig.proxyType == 'CardGameAbandon' then
		-- Abandon card was the original name of the Emergency Blockade card
		return 'Emergency Blockade card';
	end
	return cardConfig.proxyType:match("^CardGame(.*)");
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="ok") then return getColours()["Dark Green"]; --standard green used for "Ok" buttons
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

function getColours()
    local colors = {}; -- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end

function captureCardCounts (game)
	boolCardsCaptured = true;
	for k,v in pairs (game.LatestStanding.Cards) do --for each element table of player,PlayerCards
		Cards [k] = {};
		Cards [k].Pieces = {};
		Cards [k].WholeCards = {};
		for k2,vp in pairs (v.Pieces) do
			-- print ("[PIECES] "..k,k2,vp);
			Cards [k].Pieces [k2]= vp;
		end
		-- print ("[CARDS] TOTAL "..k,#v.WholeCards)
		for k3,vwc in pairs (v.WholeCards) do
			-- print ("[CARDS] "..k,k3,vwc.CardID);
			if (Cards [k].WholeCards [vwc.CardID] == nil) then Cards [k].WholeCards [vwc.CardID] = 0; end
			Cards [k].WholeCards [vwc.CardID] = Cards [k].WholeCards [vwc.CardID] + 1;
			-- Cards[k].WholeCards [vwc.CardID] = true;
		end
	end
end

function getWholeCardCount (game, playerID, cardID)
	local intNumCards = 0;

	if (game.LatestStanding.Cards [playerID] == nil) then return 0; end

	for k,v in pairs (game.LatestStanding.Cards [playerID].WholeCards) do
		if (v.CardID == tonumber(cardID)) then intNumCards = intNumCards + 1; end
	end

	-- if (game.LatestStanding.Cards [playerID] ~= nil and game.LatestStanding.Cards [playerID].WholeCards ~= nil and game.LatestStanding.Cards [playerID].WholeCards [cardID] ~= nil) then
	-- 	return game.LatestStanding.Cards [playerID].WholeCards [cardID];
	-- end
	return (intNumCards);
end

function getCardPieceCount (game, playerID, cardID)
	local intNumPieces = 0;
	if (game.LatestStanding.Cards [playerID] ~= nil and game.LatestStanding.Cards [playerID].Pieces ~= nil and game.LatestStanding.Cards [playerID].Pieces [cardID] ~= nil) then
		intNumPieces = game.LatestStanding.Cards [playerID].Pieces [cardID];
	end
	return (intNumPieces);
end