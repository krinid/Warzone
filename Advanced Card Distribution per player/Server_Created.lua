require('settings');
require('tblprint');

function Server_Created(game, settings)
	if not settings.Cards then
		return;
	end

	local pgd = {
		cardData = {},
		useDiff = false
	};

	for cardId, cardGame in pairs(settings.Cards) do
		local cardName = string.sub(cardGame.proxyType, #'CardGame' + 1);

		if getSetting('Enable' .. cardName) then
			pgd.cardData[cardId] = {
				lastGivenCardPiecesOn = nil
			};

			if getSetting('GetDiff' .. cardName) then
				pgd.useDiff = true;
			end
		end
	end

	Mod.PublicGameData = pgd;
end