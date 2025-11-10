require('settings');
require('tblprint');

function Server_Created(game, settings)
	if not getSetting('EnableReconnaissance+') then
		return;
	end

	-- auto enable recon cards which cant be earned

	local cardSettings = {};

	if settings.Cards then
		for cardId, cardGame in pairs(settings.Cards) do
			cardSettings[cardId] = cardGame;
		end
	end

	if not cardSettings[WL.CardID.Reconnaissance] then
		cardSettings[WL.CardID.Reconnaissance] = WL.CardGameReconnaissance.Create(1, 0, 0, 0, 1);
	end

	settings.Cards = cardSettings;
end