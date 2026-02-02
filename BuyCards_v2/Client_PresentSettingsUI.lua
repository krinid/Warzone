function Client_PresentSettingsUI(rootParent)
	local publicGameData = Mod.PublicGameData;
	UI.CreateLabel (rootParent).SetText ("Enables use of gold to purchase cards. Host configures which cards can be purchased among the standard and custom cards, and their respective prices.");
	UI.CreateLabel (rootParent).SetText ("\n• Max # of buyable cards: " ..tostring (Mod.Settings.MaxBuyableCards > 0 and Mod.Settings.MaxBuyableCards or "No limit"));
	UI.CreateLabel (rootParent).SetText ("    (limit applies to all players collectively, each player purchase reduces the remaining cards available to all players)");
	UI.CreateLabel (rootParent).SetText ("• Cost increase when purchased: " ..tostring ((Mod.Settings.CostIncreaseRate or 0.1) *100).. "%");
	UI.CreateLabel (rootParent).SetText ("    (when 1 or more cards of a given type are purchased, the price for that card goes up by this rate relative to the card's base cost on the following turn)");
	UI.CreateLabel (rootParent).SetText ("• See Buy Cards panel in Commerce menu for current card prices");
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd: " ..tostring (publicGameData));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD: " ..tostring (publicGameData.CardData));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.DC: " ..tostring (publicGameData.CardData.DefinedCards));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.CPF: " ..tostring (publicGameData.CardData.CardPricesFinalized));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.HHAP: " ..tostring (publicGameData.CardData.HostHasAdjustedPricing));

	-- for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
	-- 	print (cardRecord.ID .."/" .. cardRecord.Name..", " ..cardRecord.Price);
	-- 	--for reference: publicGameData.CardData.DefinedCards [cardRecord.ID] = {Name=cardRecord.Name, Price=sliderCardPrices [cardCount].GetValue (), ID=cardID};
	-- end

	-- Mod.Settings.MaxBuyableCards = math.max (-1, MaxBuyableCards.GetValue()); --ensure value is -1 or >= 0; -1 = unlimited
	-- Mod.Settings.CostIncreaseRate = CostIncreaseRate.GetValue()/100; --value can be negative (gets cheaper), 0, or positive (gets more expensive)

	-- gameRefresh_Game = clientGame;
	-- gameRefresh_Mod = Mod;
	print ("CPSUI gameRefresh_Game==nil " ..tostring (gameRefresh_Game==nil));
	local winPlayDeneutralize = createWindow (gameRefresh_Game);
	winPlayDeneutralize.setMaxSize (400, 500);
	local rootParent = winPlayDeneutralize.root;
	-- local arrIntNumCardPriceIncreases = Mod.PublicGameData.NumCardPriceIncreases or {}; --# of card increases for each card = # of turns where a player has bought that card type; don't update this mid-turn else prices will increase for all users which gets hard to predict, orders may fail, etc
	-- local arrIntNumCardsPurchased = Mod.PublicGameData.NumCardsPurchased or {}; --running count of total cards of each type purchased by all players
	local arrIntNumCardPriceIncreases = gameRefresh_Mod.PublicGameData.NumCardPriceIncreases or {}; --# of card increases for each card = # of turns where a player has bought that card type; don't update this mid-turn else prices will increase for all users which gets hard to predict, orders may fail, etc
	local arrIntNumCardsPurchased = gameRefresh_Mod.PublicGameData.NumCardsPurchased or {}; --running count of total cards of each type purchased by all players
	-- local intMaxBuyableCards = Mod.Settings.MaxBuyableCards or -1; --# of each card that can be bought; -1 = unlimited; default is -1
	-- local intCostIncreaseRate = Mod.Settings.CostIncreaseRate or 0.0; --the ratio that the price of each card increases after a turn passes where a card was purchased, or within the same turn when 1 player buys >1 of the same type of card; default to 0.0 for purpose of ongoing games where this value isn't set (so card prices in ongoing games doesn't increase)
	local strDescription = "\ncard price increases ".. tostring (tablelength(arrIntNumCardPriceIncreases)) .. "\n# cards purchased " .. tostring (tablelength(arrIntNumCardsPurchased));
	UI.CreateLabel (rootParent).SetText (strDescription);
	UI.CreateLabel (rootParent).SetText ("xyz");



	UI.Alert (strDescription);


	displayMenu (gameRefresh_Game, rootParent, nil);
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

function showPopUpTurnPhaseDescriptions_StylishDialog (game)
	local winPlayDeneutralize = createWindow (game);
	winPlayDeneutralize.setMaxSize (400, 500);
	local rootParent = winPlayDeneutralize.root;

	local winPlayDeneutralize2 = createWindow (game);
	winPlayDeneutralize2.setMaxSize (400, 500);
	local rootParent2 = winPlayDeneutralize2.root;

	UI.CreateLabel (rootParent).SetText ("1 turn in Warzone consists of the following phases:\n");
	UI.CreateLabel (rootParent2).SetText ("1 turn in Warzone consists of the following phases:\n");

	local numUserButtonsCreated = 0;
	for k,v in pairs(WL.TurnPhase) do
		if (tostring (k) ~= "ToString") then UI.CreateButton (rootParent2).SetText(tostring (k).."/"..tostring(v)).SetColor (getColourCode ("Phase|"..tostring (k))); end --.SetOnClick(function () assignToPlayerID = playerID; assignToPlayerName = getPlayerName (game, playerID); UI.Destroy (TargetPlayerLabel); TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText (assignToPlayerName); winSelectPlayer.close(); end);
		if (tostring (k) ~= "ToString") then UI.CreateLabel (rootParent).SetText(tostring (k).."/"..tostring(v)).SetColor (getColourCode ("Phase|"..tostring (k))); end --.SetOnClick(function () assignToPlayerID = playerID; assignToPlayerName = getPlayerName (game, playerID); UI.Destroy (TargetPlayerLabel); TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText (assignToPlayerName); winSelectPlayer.close(); end);
		numUserButtonsCreated = numUserButtonsCreated + 1;
	end
end

function showPopUpTurnPhaseDescriptions_UIalert ()
	local strDescription = ("1 turn in Warzone consists of the following phases in this order:\n");

	local numUserButtonsCreated = 0;
	for k,v in pairs(WL.TurnPhase) do
		if (tostring (k) ~= "ToString") then strDescription = strDescription .. tostring (k).."\n"; end
		--"/"..tostring (v);  --.SetOnClick(function () assignToPlayerID = playerID; assignToPlayerName = getPlayerName (game, playerID); UI.Destroy (TargetPlayerLabel); TargetPlayerLabel = UI.CreateLabel (horzTargetPlayer).SetText (assignToPlayerName); winSelectPlayer.close(); end);
		numUserButtonsCreated = numUserButtonsCreated + 1;
	end
	local arrIntNumCardPriceIncreases = Mod.PublicGameData.NumCardPriceIncreases or {}; --# of card increases for each card = # of turns where a player has bought that card type; don't update this mid-turn else prices will increase for all users which gets hard to predict, orders may fail, etc
	local arrIntNumCardsPurchased = Mod.PublicGameData.NumCardsPurchased or {}; --running count of total cards of each type purchased by all players
	-- local intMaxBuyableCards = Mod.Settings.MaxBuyableCards or -1; --# of each card that can be bought; -1 = unlimited; default is -1
	-- local intCostIncreaseRate = Mod.Settings.CostIncreaseRate or 0.0; --the ratio that the price of each card increases after a turn passes where a card was purchased, or within the same turn when 1 player buys >1 of the same type of card; default to 0.0 for purpose of ongoing games where this value isn't set (so card prices in ongoing games doesn't increase)
	strDescription = strDescription .. "\ncard price increases ".. tostring (tablelength(arrIntNumCardPriceIncreases)) .. "\n# cards purchased " .. tostring (tablelength(intCostIncreaseRate));

	UI.Alert (strDescription);

end

function createWindow (game)
    local window = {root = nil, setMaxSize = nil, setScrollable = nil, game = nil, close = nil};

	game.CreateDialog (function(rootParent, setMaxSize, setScrollable, game2, close)
		window = {root = rootParent, setMaxSize = setMaxSize, setScrollable = setScrollable, game = game2, close = close};
    end);

    return window;
end

