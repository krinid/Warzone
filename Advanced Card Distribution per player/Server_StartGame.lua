require('tblprint');
require('getTeams');

function Server_StartGame(game)
	local teams = getTeams(game);

	if not teams then
		return;
	end

	local pgd = Mod.PublicGameData;

	pgd.teams = teams;
	Mod.PublicGameData = pgd;
end