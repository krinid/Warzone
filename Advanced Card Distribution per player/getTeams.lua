local function getInitalCardPieces(settings)
	local pieces = {};

	for cardId, cardGame in pairs(settings.Cards) do
		pieces[cardId] = cardGame.InitialPieces;
	end

	return pieces;
end

local function addCardPieces(settings, currentCardPieces)
	local added = {};

	for cardId, pieces in pairs(currentCardPieces) do
		added[cardId] = pieces + settings.Cards[cardId].InitialPieces;
	end

	return added;
end

function getTeams(game)
	if not Mod.PublicGameData.useDiff or Mod.PublicGameData.teams then
		return;
	end

	local teams = {
		teamed = {},
		noTeam = {}
	};

	for playerId, player in pairs(game.ServerGame.Game.Players) do
		if player.Team == -1 then
			teams.noTeam[playerId] = {
				currentCardPieces = getInitalCardPieces(game.Settings),
				rewardedPieces = {}
			};
		else
			if not teams.teamed[player.Team] then
				teams.teamed[player.Team] = {
					members = {},
					currentCardPieces = getInitalCardPieces(game.Settings),
					rewardedPieces = {}
				};
			else
				teams.teamed[player.Team].currentCardPieces = addCardPieces(game.Settings, teams.teamed[player.Team].currentCardPieces);
			end

			table.insert(teams.teamed[player.Team].members, playerId);
		end
	end

	return teams;
end
