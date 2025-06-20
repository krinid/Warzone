--move these to PublicGameData? Mod.Settings?
disallowReverseSanctionsOnOthers = true;
disallowNormalSanctionsOnSelf = true;

-- function Server_AdvanceTurn_Start (game, addOrder)
-- end

-- function Server_AdvanceTurn_End(game, addOrder)
-- end

function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)
	local playerID = order.PlayerID;

	if (order.proxyType == 'GameOrderPlayCardSanctions') then
		print ("[Sanction card] cast "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage);
		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage>=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
			print ("[Sanction card] self-sanction for +ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self with positive sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage<0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning others with reverse sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
			print ("[Sanction card] permitted sanction type");
		end
	end
end