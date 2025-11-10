require('setup');

function Server_StartGame(game, standing)
	if not game.Settings.AutomaticTerritoryDistribution then
		return;
	end

	setup(game);
end