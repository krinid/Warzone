function setup(game)
	print('in setup(game)');

-- 	print('game.State', game.State);

-- 	for key, value in pairs(WL.GameState) do
-- 		if key ~= 'ToString' then
-- 			print('game.State == WL.GameState.' .. key, game.State == WL.GameState[key]);
-- 		end
-- 	end

	-- game.State is nil on single player (possibly multiplayer as well) when using Server_StartDistribution and Server_StartGame in app version 5.33
	-- so disable this check

-- 	if not (game.State == WL.GameState.DistributingTerritories or game.State == WL.GameState.Playing) then
-- 		print('exit because game state');
-- 		return;
-- 	end

	local hostPlayerId = game.ServerGame.Settings.StartedBy;

	if not hostPlayerId then
		print('exit because no hostPlayerId');
		return;
	end

	local host = game.ServerGame.Game.Players[hostPlayerId];

	if not host then
		print('exit because no host');
		return;
	end

	local playerGD = {
		[hostPlayerId] = {
			eliminating = {}
		}
	};

	local publicGD = {
		teams = {}
	};

	for _, player in pairs(game.ServerGame.Game.PlayingPlayers) do
		if not playerGD[player.ID] then
			playerGD[player.ID] = {};
		end

		if player.Team ~= -1 then
			if not publicGD.teams[player.Team] then
				publicGD.teams[player.Team] = 0;
			end

			publicGD.teams[player.Team] = publicGD.teams[player.Team] + 1;

			if host.Team == player.Team and publicGD.teams[player.Team] > 1 then
				-- only need to know if there's more than 1 player on host's team
				break;
			end
		end
	end

	Mod.PlayerGameData = playerGD;
	Mod.PublicGameData = publicGD;

	print('setup complete');
end
