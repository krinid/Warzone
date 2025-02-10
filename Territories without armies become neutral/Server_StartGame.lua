require('tblprint');
require('version');

function Server_StartGame(game, standing)
	if not serverCanRunMod(game) then
		return;
	end

	setup(game, standing);
end

function setup(game, standing)
	local playerForGameOrderCustoms = game.Settings.StartedBy;-- can't use neutral

	if not playerForGameOrderCustoms then
		for playerId in pairs(game.ServerGame.Game.Players) do
			playerForGameOrderCustoms = playerId;

			break;
		end
	end

	local publicGD = Mod.PublicGameData;

	publicGD.modCanDoChanges = (not game.Settings.OneArmyStandsGuard) or (game.Settings.OneArmyStandsGuard and game.Settings.Commanders);
	publicGD.playerForGameOrderCustoms = playerForGameOrderCustoms;

	Mod.PublicGameData = publicGD;
end
