require('tblprint');
require('version');

function Server_StartGame(game)
	if not serverCanRunMod(game) then
		return;
	end

	local publicGameData = Mod.PublicGameData;

	publicGameData.votes = {};

	for playerId, _ in pairs(game.ServerGame.Game.Players) do
		publicGameData.votes[playerId] = false;
	end

	Mod.PublicGameData = publicGameData;
end