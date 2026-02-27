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
		print ("[Sanction card] **CAST "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage.. ", isAI " ..tostring (game.Game.Players[order.PlayerID].IsAI).. ", IsAIorHumanTurnedIntoAI " ..tostring (game.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI));
		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage >=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
			print ("[Sanction card] self-sanction for +ve sanction SKIP");
			if (game.Game.Players[order.PlayerID].IsAI == false and game.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI == false) then addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self with positive sanctions is disallowed - Skipping order", {}, {},{})); end --only display message for human players; no need to notify players that an AI order was suppressed
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID ~= order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage <0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			if (game.Game.Players[order.PlayerID].IsAI == false and game.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI == false) then addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning others with reverse sanctions is disallowed - Skipping order", {}, {},{})); end --only display message for human players; no need to notify players that an AI order was suppressed
			-- skip (WL.ModOrderControl.Skip); --skip this order but show the Skip Message in order history
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
			print ("[Sanction card] permitted sanction type");
		end
	end
end