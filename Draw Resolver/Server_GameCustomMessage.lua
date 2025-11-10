require('tblprint');

function Server_GameCustomMessage(game, playerId, payload, setReturn)
	local publicGameData = Mod.PublicGameData;

	if not payload then
		setReturn(publicGameData.votes);
		return;
	end

	if type(payload.vote) == 'boolean' then
		publicGameData.votes[playerId] = payload.vote;
	end

	Mod.PublicGameData = publicGameData;
	setReturn(publicGameData.votes);
end
