require('tblprint');
require('version');
require('setup');

function Server_StartGame(game, standing)
	print('in Server_StartGame');
	print('type(tblprint)', type(tblprint));
	print('type(serverCanRunMod)', type(serverCanRunMod));
	print('type(setup)', type(setup));

	if not serverCanRunMod(game) then
		print('exit Server_StartGame because server cannot run mod');
		return;
	end

	print('still in Server_StartGame');

	isAutoDist = game.ServerGame.Settings.AutomaticTerritoryDistribution;

	print('isAutoDist', isAutoDist);

	if isAutoDist then
		print('entered isAutoDist, about to call setup');
		setup(game);
	end

	print('about to call makeHostOnlyHaveOneTerritory');

	makeHostOnlyHaveOneTerritory(game, standing);

	print('exited Server_StartGame');
end

function makeHostOnlyHaveOneTerritory(game, standing)
	-- the host's territories can't be changed after distribution, so limit host to 1 territory

	local hasCustomScenario = not not game.ServerGame.Settings.CustomScenario;

	if hasCustomScenario and isAutoDist then
		-- host may have put their territories in a way to prevent fights between areas
		return;
	end

	local host = game.ServerGame.Settings.StartedBy;

	if not host then
		return;
	end

	local foundHostFirstTerr = false;

	for terrId, terr in pairs(standing.Territories) do
		if terr.OwnerPlayerID == host then
			if foundHostFirstTerr then
				if not hasCustomScenario then
					standing.Territories[terrId].NumArmies = WL.Armies.Create(game.ServerGame.Settings.InitialNeutralsInDistribution);
				end

				standing.Territories[terrId].OwnerPlayerID = WL.PlayerID.Neutral;
			else
				foundHostFirstTerr = true;
				standing.Territories[terrId].NumArmies = WL.Armies.Create(game.ServerGame.Settings.OneArmyMustStandGuardOneOrZero);
				standing.Territories[terrId].Structures = {};
			end
		end
	end
end