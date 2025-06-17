function Client_GameOrderCreated (game, order, skip)
    --local strCardTypeBeingPlayed = nil;
	--local cardOrderContentDetails = nil;
	--local publicGameData = Mod.PublicGameData;

	--move these to PublicGameData
	disallowReverseSanctionsOnOthers = true;
    disallowNormalSanctionsOnSelf = true;

    print ("[C_GOC] START");
	print ("[C_GOC] order proxyType=="..order.proxyType.."::");
    --UI.Alert ("Checking orders");
	--printObjectDetails (gameOrder, "gameOrder", "C_GOC"); --*** this LOC causes the WZ generic error when the order passed in is an Airlift order

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires submitting an order, which they can't do b/c they're not in the game)

	--skip +ve self-sanctions and -ve sanctions on others; so can't accidentally reduce own income, nor buff another player's income
    if (order.proxyType == 'GameOrderPlayCardSanctions') then
        print ("[Sanction card] cast "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage);

		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage>=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
            print ("[Sanction card] self-sanction for +ve sanction SKIP");
            -- addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self for positive sanctions is disallowed - Skipping order", {}, {},{}));
			UI.Alert ("Sanction self for positive sanctions is disallowed - Skipping order");
            skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage<0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			UI.Alert ("Sanctioning other for reverse sanctions is disallowed - Skipping order");
			-- addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning other for reverse sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
            print ("[Sanction card] permitted sanction type");
        end
    end

	-- addOrder (WL.GameOrderCustom.Create (1, "Capture card state 1", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 1b", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 2", "PunishReward|Capture card state", {}, WL.TurnPhase.SanctionCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 3", "PunishReward|Capture card state"));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 4", "PunishReward|Capture card state", nil, WL.TurnPhase.BlockadeCards));

	-- local newOrder = WL.GameOrderCustom.Create (1058239, "Capture card state 5", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards);
	-- --b/c this function has no addOrder callback parameter, need to manually add the order into the clientgame parameter 'game'
	-- local orders = game.Orders;
	-- table.insert(orders, newOrder);
	-- game.Orders = orders;

	print ("[C_GOC] END");
end