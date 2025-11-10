require('eliminate');
require('tblprint');
require('version');

local satsPayload = 'DrawResolver_ServerAdvanceTurnStart';
local canRun = false;
local winnerId;
local votes;

function Server_AdvanceTurn_Start(game, addNewOrder)
	canRun = serverCanRunMod(game);

	if not canRun then
		return;
	end

	votes = checkVotes(game)

	if votes.numPlaying ~= votes.numVotes then
		return;
	end

	local winner = math.random(1, votes.numPlaying);

	winnerId = votes.players[winner];
	votes.players[winner] = nil;

	addNewOrder(WL.GameOrderCustom.Create(winnerId, '', satsPayload));
end

function checkVotes(game)
	local publicGameData = Mod.PublicGameData;
	local numPlaying = 0;
	local numVotes = 0;
	local players = {};

	for playerId, player in pairs(game.ServerGame.Game.Players) do
		local playing = player.State == WL.GamePlayerState.Playing;

		if playing then
			numPlaying = numPlaying + 1;
			players[numPlaying] = playerId;

			if publicGameData.votes[playerId] or player.IsAIOrHumanTurnedIntoAI then
				numVotes = numVotes + 1;
			end
		else
			publicGameData.votes[playerId] = false;
		end
	end

	Mod.PublicGameData = publicGameData;

	return {players = players, numPlaying = numPlaying, numVotes = numVotes};
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if not (order.proxyType == 'GameOrderCustom' and order.Payload == satsPayload) then
		return;
	end

	if not canRun then
		return;
	end

	skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
	addNewOrder(WL.GameOrderEvent.Create(winnerId, 'Decided random winner', {}, eliminate(votes.players, game.ServerGame.LatestTurnStanding.Territories, true, game.Settings.SinglePlayer)));
end
