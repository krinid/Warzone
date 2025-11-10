require('tblprint');

function Server_GameCustomMessage(game, playerId, payload, setReturn)
	local host = game.ServerGame.Settings.StartedBy;

	if not host or not Mod.PlayerGameData[playerId] then
		return setReturn({});
	end

	if not payload then
		return setReturn(Mod.PlayerGameData[playerId]);
	end

	local playerGD = Mod.PlayerGameData;

	if payload.toEliminate and game.Game.PlayingPlayers[payload.toEliminate] and (playerId and playerId == host) then
		playerGD[host].eliminating[payload.toEliminate] = payload.shouldEliminate or nil;
	end

	Mod.PlayerGameData = playerGD;

	setReturn(Mod.PlayerGameData[host]);
end