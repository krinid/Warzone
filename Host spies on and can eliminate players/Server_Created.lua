require('tblprint');

function Server_Created(game, settings)
	local cards = {};

	if settings.Cards then
		for cardId, cardGame in pairs(settings.Cards) do
			cards[cardId] = cardGame;
		end
	end

	-- print('cards = ')
	-- tblprint(cards);

	if not cards[WL.CardID.Spy] then
		-- automatically include spy card that can't be earned
		local cardGame = WL.CardGameSpy.Create(1, 0, 0, 0, 100, true);
		-- print('created spy card')
		-- tblprint(cardGame);

		cards[WL.CardID.Spy] = cardGame;
		settings.Cards = cards;
		-- print('added spy card; cards = ');
		-- tblprint(settings.Cards);
	end
end