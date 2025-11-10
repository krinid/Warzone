require('tblprint');

function Server_GameCustomMessage(game, playerId, payload, setReturn)
	local host = game.Settings.StartedBy;

	if not host then
		return;
	end

	local hostPlayer = game.Game.Players[host];

	if not (hostPlayer and hostPlayer.ID == playerId) then
		return;
	end

	local publicGD = Mod.PublicGameData;

	for key, value in pairs(payload) do
		publicGD[key] = value;
	end

	Mod.PublicGameData = publicGD;

	setReturn(publicGD);
end
