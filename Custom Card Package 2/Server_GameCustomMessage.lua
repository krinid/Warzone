require('tblprint');

function Server_GameCustomMessage(game, playerId, payload, setReturn)
	if type(payload) ~= 'table' then
		return;
	end

	for storageType in pairs(payload) do
		local stored = Mod[storageType];

		for key, value in pairs(payload[storageType]) do
			if storageType == 'PlayerGameData' then
				stored[playerId][key] = value;
			else
				stored[key] = value;
			end
		end

		Mod[storageType] = stored;
	end

	local ret = {
		PlayerGameData = Mod.PlayerGameData[playerId],
		PublicGameData = Mod.PublicGameData
	};

	setReturn(ret);
end