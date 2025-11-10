require('settings');
require('string_util');
require('tblprint');

local reachedEndOfTurn = false;

function Server_AdvanceTurn_Order(game, order)
	if not game.Settings.Cards or reachedEndOfTurn or not Mod.PublicGameData.useDiff then
		return;
	end

	if not startsWith(order.proxyType, 'GameOrderPlayCard') or order.PlayerID == WL.PlayerID.Neutral then
		return;
	end

	local playerId = order.PlayerID;
	local cardId = order.CardID;
	local player = game.ServerGame.Game.PlayingPlayers[playerId];
	local numPiecesInCard = game.Settings.Cards[cardId].NumPieces;
	local pgd = Mod.PublicGameData;

	-- check to make sure a mod didnt create and play a card on player behalf
	if player.Team == -1 then
		if (pgd.teams.noTeam[playerId].currentCardPieces[cardId] or 0) < numPiecesInCard then
			return;
		end
	else
		if (pgd.teams.teamed[player.Team].currentCardPieces[cardId] or 0) < numPiecesInCard then
			return;
		end
	end

	-- reduce from team total
	if player.Team == -1 then
		pgd.teams.noTeam[playerId].currentCardPieces[cardId] = pgd.teams.noTeam[playerId].currentCardPieces[cardId] - numPiecesInCard;
	else
		pgd.teams.teamed[player.Team].currentCardPieces[cardId] = pgd.teams.teamed[player.Team].currentCardPieces[cardId] - numPiecesInCard;
	end

	Mod.PublicGameData = pgd;
end

function Server_AdvanceTurn_End(game, addNewOrder)
	reachedEndOfTurn = true;

	if not game.Settings.Cards then
		return;
	end

	print('in Server_AdvanceTurn_End');

	addEndOfTurnCardPieces(game);

	local cardPiecesToAdd = {};
	local pgd = Mod.PublicGameData;

	for cardId, cardGame in pairs(game.Settings.Cards) do
		local cardName = string.sub(cardGame.proxyType, #'CardGame' + 1);

		if getSetting('Enable' .. cardName) then
			print(cardName .. ' is enabled');

			if not pgd.cardData[cardId].lastGivenCardPiecesOn or (pgd.cardData[cardId].lastGivenCardPiecesOn + getSetting('Freq' .. cardName) == game.ServerGame.Game.TurnNumber) then
				print('is time to give pieces of ' .. cardName);

				pgd.cardData[cardId].lastGivenCardPiecesOn = game.ServerGame.Game.TurnNumber;

				if getSetting('GetDiff' .. cardName) then
					print('doing GetDiff');

					for teamType in pairs(pgd.teams) do
						for teamId in pairs(pgd.teams[teamType]) do
							local playerId = teamId;

							if teamType == 'teamed' then
								playerId = pgd.teams[teamType][teamId].members[1];
							end

							print('teamType', teamType);
							print('teamId', teamId);
							print('playerId', playerId);

							local piecesSetting = getSetting('Pieces' .. cardName);
							local rewardedPieces = pgd.teams[teamType][teamId].rewardedPieces[cardId];

							print('piecesSetting', piecesSetting);
							print('rewardedPieces', rewardedPieces);

							local piecesToAdd = piecesSetting - rewardedPieces;

							if piecesToAdd > 0 then
								if not cardPiecesToAdd[playerId] then
									cardPiecesToAdd[playerId] = {};
								end

								cardPiecesToAdd[playerId][cardId] = piecesToAdd;
								pgd.teams[teamType][teamId].currentCardPieces[cardId] = pgd.teams[teamType][teamId].currentCardPieces[cardId] + piecesToAdd;
							end

							pgd.teams[teamType][teamId].rewardedPieces[cardId] = 0;
						end
					end
				else
					print('not doing GetDiff');

					for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
						if not cardPiecesToAdd[playerId] then
							cardPiecesToAdd[playerId] = {};
						end

						cardPiecesToAdd[playerId][cardId] = getSetting('Pieces' .. cardName);
					end
				end
			else
				print('not time to give pieces of ' .. cardName);
			end
		end
	end

	for playerId, pieces in pairs(cardPiecesToAdd) do
		-- no order is created if no cardPiecesToAdd given

		local event = WL.GameOrderEvent.Create(playerId, 'Receive card pieces', game.Settings.HasAnySortOfFog and {} or nil);

		event.AddCardPiecesOpt = {[playerId] = pieces};
		addNewOrder(event);
	end

	Mod.PublicGameData = pgd;
end

function addEndOfTurnCardPieces(game)
	if not Mod.PublicGameData.useDiff then
		return;
	end

	local endOfTurnPieces = getEndOfTurnCardPieces(game);
	local pgd = Mod.PublicGameData;

	for teamType in pairs(pgd.teams) do
		for teamId in pairs(pgd.teams[teamType]) do
			if teamType == 'teamed' then
				pgd.teams.teamed[teamId].members = endOfTurnPieces.teamed[teamId].members;
			end

			for cardId in pairs(game.Settings.Cards) do
				local currentPieces = pgd.teams[teamType][teamId].currentCardPieces[cardId] or 0;
				local endPieces = endOfTurnPieces[teamType][teamId] and (endOfTurnPieces[teamType][teamId].currentCardPieces[cardId] or 0) or 0;
				-- print('endPieces = ' .. tostring(endPieces));
				-- print('currentPieces = ' .. tostring(currentPieces));
				local highest = math.max(endPieces, currentPieces);
				local lowest = math.min(currentPieces, endPieces);
				-- print('highest = ' .. tostring(highest));
				-- print('lowest = ' .. tostring(lowest));

				pgd.teams[teamType][teamId].currentCardPieces[cardId] = endPieces;
				pgd.teams[teamType][teamId].rewardedPieces[cardId] = (pgd.teams[teamType][teamId].rewardedPieces[cardId] or 0) + highest - lowest;
				-- print('pgd.teams[teamType][teamId].rewardedPieces[cardId] = ');
				-- tblprint(pgd.teams[teamType][teamId].rewardedPieces[cardId]);
			end
		end
	end

	Mod.PublicGameData = pgd;
end

function getEndOfTurnCardPieces(game)
	if not Mod.PublicGameData.useDiff then
		return;
	end

	-- in teams and no teams, individual pieces are to each player
	-- whole cards given to a single player in teams (player who got the final piece gets the card)

	local clone = {
		teamed = {},
		noTeam = {}
	};

	for playerId, playerCards in pairs(game.ServerGame.LatestTurnStanding.Cards) do
		local player = game.ServerGame.Game.PlayingPlayers[playerId];

		if player then
			if player.Team == -1 then
				clone.noTeam[playerId] = {
					currentCardPieces = {}
				};
			else
				if not clone.teamed[player.Team] then
					clone.teamed[player.Team] = {
						members = {},
						currentCardPieces = {}
					};
				end

				table.insert(clone.teamed[player.Team].members, playerId);
			end

			for cardId, numPieces in pairs(playerCards.Pieces) do
				if player.Team == -1 then
					clone.noTeam[playerId].currentCardPieces[cardId] = numPieces;
				else
					clone.teamed[player.Team].currentCardPieces[cardId] = (clone.teamed[player.Team].currentCardPieces[cardId] or 0) + numPieces;
				end
			end

			for _, cardInstance in pairs(playerCards.WholeCards) do
				local cardId = cardInstance.CardID;
				local numPieces = game.Settings.Cards[cardId].NumPieces;

				if player.Team == -1 then
					clone.noTeam[playerId].currentCardPieces[cardId] = (clone.noTeam[playerId].currentCardPieces[cardId] or 0) + numPieces;
				else
					clone.teamed[player.Team].currentCardPieces[cardId] = (clone.teamed[player.Team].currentCardPieces[cardId] or 0) + numPieces;
				end
			end
		end
	end

	return clone;
end
