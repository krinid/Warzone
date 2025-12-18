--move these to PublicGameData? Mod.Settings?
disallowReverseSanctionsOnOthers = true;
disallowNormalSanctionsOnSelf = true;

function Client_GameOrderCreated (game, order, skip)
	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires submitting an order, which they can't do b/c they're not in the game)

	--skip +ve self-sanctions and -ve sanctions on others; so can't accidentally reduce own income, nor buff another player's income
    if (order.proxyType == 'GameOrderPlayCardSanctions') then
        print ("[Sanction card] cast "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage);

		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage>=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
            print ("[Sanction card] self-sanction for +ve sanction SKIP");
            -- addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self for positive sanctions is disallowed - Skipping order", {}, {},{}));
			UI.Alert ("Sanctioning yourself is disallowed");
            skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID ~= order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage<0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			UI.Alert ("Sanctioning other players using Reverse Sanctions is disallowed; playing this Sanction card increases a player's income and must be played on yourself to increase your own income");
			-- addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning other for reverse sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
            print ("[Sanction card] permitted sanction type");
        end
    end
end