require('tblprint');

function Client_PresentPlayCardUI(game, cardInstance, playCard)
	if not (cardInstance.CardID == Mod.Settings.MysteryCardID) then
		return;
	end

	playCard('Play a Mystery Card', '', WL.TurnPhase.ReceiveCards);
end
