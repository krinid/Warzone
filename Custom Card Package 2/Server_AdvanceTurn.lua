require('settings');
require('eliminate');
require('number_util');
require('string_util');
require('tblprint');
require('version');
require('util');
require('cards');

function cardNameToFnName(cardName)
	-- for _G - https://stackoverflow.com/questions/1791234/lua-call-function-from-a-string-with-function-name
	return string.gsub(cardName, '[^%w_]', '');
end

function visibleToTeammates(assignedPlayer, players)
	if assignedPlayer == WL.PlayerID.Neutral then
		return {assignedPlayer};
	end

	local p = players[assignedPlayer];

	if p.Team == -1 then
		return {assignedPlayer};
	end

	local visTo = {};

	for _, playerId in pairs(Mod.PublicGameData.teams[p.Team].members) do
		table.insert(visTo, playerId);
	end

	return visTo;
end

local playersWithSuccessfulAttacks = {};

function Server_AdvanceTurn_Start(game, addNewOrder)
	if not serverCanRunMod(game) then
		return;
	end

	function LOG(msg)
		addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, msg, nil));
	end

	for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
		playersWithSuccessfulAttacks[playerId] = false;
	end

	local reconPlus = 'Reconnaissance+';

	if getSetting('Enable' .. reconPlus) and getSetting(reconPlus .. 'RandomAutoplay') then
		for teamType in pairs(Mod.PublicGameData.cardPieces) do
			for teamId in pairs(Mod.PublicGameData.cardPieces[teamType]) do
				local teamLeader = tonumber(teamType == 'teammed' and Mod.PublicGameData.teams[teamId].members[1] or teamId);
				local numPieces = Mod.PublicGameData.cardPieces[teamType][teamId].currentPieces[reconPlus] or 0;
				local wholeCards = math.floor(numPieces / getSetting(reconPlus .. 'PiecesInCard'));

				while wholeCards > 0 do
					local randomTerrId = Mod.PublicGameData.terrsArray[math.random(1, #Mod.PublicGameData.terrsArray)];
					local randomTerr = game.Map.Territories[randomTerrId];
					local msg = 'Play ' .. reconPlus .. ' Card on ' .. randomTerr.Name;
					local payload = 'CCP2_playedCard_' .. teamLeader .. '_<' .. reconPlus .. '=[' .. randomTerr.ID .. ']>';
					local order = WL.GameOrderCustom.Create(teamLeader, msg, payload);

					addNewOrder(order);
					wholeCards = wholeCards - 1;
				end
			end
		end
	end

	if not Mod.PublicGameData.activeCards then
		return;
	end

	for cardName in pairs(Mod.PublicGameData.activeCards) do
		_G['processStartTurn' .. cardNameToFnName(cardName)](game, addNewOrder, cardName);
	end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if not serverCanRunMod(game) then
		return;
	end

	local wz = {
		game = game,
		order = order,
		result = result,
		addNewOrder = addNewOrder,
		skipThisOrder = skipThisOrder,
		LOG = function(msg)
			addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, msg, nil));
		end
	};

	processGameOrderCustom(wz);

	if order.proxyType ~= 'GameOrderCustom' and order.proxyType ~= 'GameOrderEvent' then
		for cardName, enabled in pairs(Mod.PublicGameData.cardsThatCanBeActive) do
			if enabled then
				_G['processOrder' .. cardNameToFnName(cardName)](wz, cardName);
			end
		end
	end

	processGameOrderAttackTransfer(wz);
end

function Server_AdvanceTurn_End(game, addNewOrder)
	if not serverCanRunMod(game) then
		return;
	end

	-- automatically discard cards if cards held is above the limit
	if getSetting('LimitMaxCards') then
		local msgPrefix = 'Automatically removing card pieces from ';
		local msgSuffix = ' due to holding too many full cards';
		local limit = getSetting('MaxCardsLimit');

		for teamType in pairs(Mod.PublicGameData.cardPieces) do
			for teamId in pairs(Mod.PublicGameData.cardPieces[teamType]) do
				local unusedFullCards = 0;
				local sentAutoDiscardMsg = false;
				local teamLeader = tonumber(teamType == 'teammed' and Mod.PublicGameData.teams[teamId].members[1] or teamId);
				local player = game.ServerGame.Game.Players[teamLeader];
				local playerOrTeamName = player.Team == -1 and player.DisplayName(nil, false) or teamIdToTeamName(player.Team);
				local msg = msgPrefix .. playerOrTeamName .. msgSuffix;

				for cardName, pieces in pairs(Mod.PublicGameData.cardPieces[teamType][teamId].currentPieces) do
					local piecesInCard = getSetting(cardName .. 'PiecesInCard');
					local wholeCards = math.floor(pieces / piecesInCard);

					if (unusedFullCards + wholeCards) > limit then
						if not sentAutoDiscardMsg then
							addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, msg, visibleToTeammates(teamLeader, game.ServerGame.Game.Players)));
							sentAutoDiscardMsg = true;
						end

						local piecesToAdd;
						local remaining = limit - unusedFullCards;

						if remaining > 0 then
							unusedFullCards = limit;
							piecesToAdd = wholeCards - remaining;
						else
							piecesToAdd = wholeCards;
						end

						piecesToAdd = -piecesToAdd * piecesInCard;
						addNewOrder(WL.GameOrderCustom.Create(teamLeader, msg, 'CCP2_addCardPieces_' .. teamLeader .. '_<' .. cardName .. '=[' .. piecesToAdd .. ']>'));
					else
						unusedFullCards = unusedFullCards + wholeCards;
					end
				end
			end
		end
	end

	-- add earned pieces
	local earnedPieces = {};

	function addEarnedPieces(playerId, cardName, minNumPieces, maxNumPieces, chance)
		if not earnedPieces[playerId] then
			earnedPieces[playerId] = {};
		end

		local numPieces = minNumPieces;
		local i = maxNumPieces - minNumPieces;

		while i > 0 do
			if math.random(1, 100) < chance then
				numPieces = numPieces + 1
			end

			i = i - 1;
		end

		earnedPieces[playerId][cardName] = numPieces;
	end

	for _, cardName in pairs(Mod.PublicGameData.cardNames) do
		local enabled = getSetting('Enable' .. cardName);
		local minNumPieces = enabled and getSetting(cardName .. 'PiecesPerTurn') or 0;
		local wonByChance = enabled and getSetting(cardName .. 'WonByChance') or false;
		local maxNumPieces = enabled and getSetting(cardName .. 'PiecesPerTurnMaxLimit') or minNumPieces;
		local chance = enabled and getSetting(cardName .. 'WonByChancePercent') or 100;
		local needsAttack = enabled and getSetting(cardName .. 'NeedsSuccessfulAttackToEarnPiece');

		if maxNumPieces < minNumPieces then
			maxNumPieces = minNumPieces;
		end

		if enabled and (minNumPieces or wonByChance) then
			if needsAttack then
				for playerId, hadSuccessfulAttack in pairs(playersWithSuccessfulAttacks) do
					local player = game.ServerGame.Game.Players[playerId];

					if player.State == WL.GamePlayerState.Playing and hadSuccessfulAttack then
						addEarnedPieces(playerId, cardName, minNumPieces, maxNumPieces, chance);
					end
				end
			else
				for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
					addEarnedPieces(playerId, cardName, minNumPieces, maxNumPieces, chance);
				end
			end
		end
	end

	for playerId in pairs(earnedPieces) do
		local msg = game.ServerGame.Game.PlayingPlayers[playerId].DisplayName(nil, false) .. ' earned card pieces';

		addNewOrder(WL.GameOrderEvent.Create(playerId, msg, visibleToTeammates(playerId, game.ServerGame.Game.Players)));

		local payloadPrefix = 'CCP2_addCardPieces_' .. playerId .. '_<';

		for cardName, numPieces in pairs(earnedPieces[playerId]) do
			local payload = payloadPrefix .. cardName .. '=[' .. numPieces .. ']>';
			-- message here doesnt matter because payload gets processed and order is skipped
			local order = WL.GameOrderCustom.Create(playerId, '', payload);

			addNewOrder(order);
		end
	end
end

function processGameOrderCustom(wz)
	if not (wz.order.proxyType == 'GameOrderCustom' and startsWith(wz.order.Payload, 'CCP2_')) then
		return;
	end

	if wz.game.Settings.SinglePlayer and not canRunMod() then
		return;
	end

	parseGameOrderCustom(wz);
end

function parseGameOrderCustom(wz)
	-- https://www.lua.org/pil/20.2.html
	-- 'CCP2_addCardPieces_1000_<Reconnaissance+=[1],Reconnaissance+=[-1]>'
	-- 'CCP2_useCard_1000_<Reconnaissance+=[100],Reconnaissance+=[]>'
	-- 'CCP2_buyCard_1000_<Reconnaissance+=[],Reconnaissance+=[]>'

	local _, _, command, playerId, cards = string.find(wz.order.Payload, '^CCP2_([^_]+)_(-?%d+)_<([^>]+)>$');
	-- ai player id is negative in mp team games https://www.warzone.com/MultiPlayer?GameID=35407114

	if not (command and _G[command] and playerId and cards) then
		wz.LOG('invalid payload: ' .. wz.order.Payload);
		wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		return;
	end

	playerId = round(tonumber(playerId));

	if not wz.game.ServerGame.Game.PlayingPlayers[playerId] then
		wz.LOG('player ' .. tostring(playerId) .. ' isnt playing, payload = ' .. wz.order.Payload);
		wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		return;
	end

	local player = wz.game.ServerGame.Game.PlayingPlayers[playerId];
	local commaSplit = split(cards, ',');

	for _, str2 in pairs(commaSplit) do
		local _, _, cardName, param = string.find(str2, '^([^=]+)=%[([^%]]*)%]$');

		if not (cardName and param) then
			wz.LOG('cardName and or param is invalid. str2 = ' .. str2);
			wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		elseif cardName and param and getSetting('Enable' .. cardName) then
			wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

			_G[command](wz, player, cardName, param);
		end
	end
end

local function simulateAddCardPieces(wz, player, cardName, numPieces)
	numPieces = tonumber(numPieces);

	if numPieces == 0 then
		return 0;
	end

	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;
	local amountToAdd = numPieces;
	local currentPieces = Mod.PublicGameData.cardPieces[teamType][teamId].currentPieces[cardName];

	if (currentPieces + amountToAdd) < 0 then
		amountToAdd = -currentPieces;
	end

	return amountToAdd;
end

local function applyAddCardPieces(wz, player, cardName, numPieces)
	local amountAdded = simulateAddCardPieces(wz, player, cardName, numPieces);

	if amountAdded == 0 then
		return amountAdded;
	end

	-- remove the pieces
	local publicGD = Mod.PublicGameData;
	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;
	local currentPieces = publicGD.cardPieces[teamType][teamId].currentPieces[cardName];
	local resulting = currentPieces + amountAdded;

	publicGD.cardPieces[teamType][teamId].currentPieces[cardName] = resulting;
	Mod.PublicGameData = publicGD;

	-- check if there's any full cards
	local playerGD = Mod.PlayerGameData;
	local members = player.Team == -1 and {teamId} or publicGD.teams[teamId].members;
	local shownReceivedCardsMsg = resulting < getSetting(cardName .. 'PiecesInCard');

	for _, playerId in pairs(members) do
		playerGD[playerId].shownReceivedCardsMsg = shownReceivedCardsMsg;
	end

	Mod.PlayerGameData = playerGD;

	return amountAdded;
end

function addCardPieces(wz, player, cardName, param)
	local amountAdded = applyAddCardPieces(wz, player, cardName, param);

	if amountAdded == 0 then
		return;
	end

	local numPieces = math.abs(amountAdded);
	local piecesInCard = getSetting(cardName .. 'PiecesInCard');
	local fullCards = math.floor(numPieces / piecesInCard);
	local pieces = numPieces % piecesInCard;
	local msg = player.DisplayName(nil, false) .. ' ' .. (amountAdded > 0 and 'received' or 'lost');

	if fullCards > 0 then
		msg = msg .. ' ' .. fullCards .. ' full ' .. cardName .. ' Card' .. (fullCards == 1 and '' or 's');
	end

	if fullCards > 0 and pieces > 0 then
		msg = msg .. ' and';
	end

	if pieces > 0 then
		msg = msg .. ' ' .. pieces .. ' piece' .. (pieces == 1 and '' or 's');

		if fullCards == 0 then
			msg = msg .. ' of a ' .. cardName .. ' Card';
		end
	end

	wz.addNewOrder(WL.GameOrderEvent.Create(player.ID, msg, visibleToTeammates(player.ID, wz.game.ServerGame.Game.Players)));
end

function discardCard(wz, player, cardName)
	local amountAdded = applyAddCardPieces(wz, player, cardName, -getSetting(cardName .. 'PiecesInCard'));

	if amountAdded == 0 then
		return;
	end

	local msg = player.DisplayName(nil, false) .. ' discarded a ' .. cardName .. ' Card';
	local visTo = visibleToTeammates(player.ID, wz.game.ServerGame.Game.Players);

	wz.addNewOrder(WL.GameOrderEvent.Create(player.ID, msg, visTo));
end

function playedCard(wz, player, cardName, param)
	-- need to check if enough pieces to play card
	local piecesInCard = getSetting(cardName .. 'PiecesInCard');
	local publicGD = Mod.PublicGameData;
	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;

	if Mod.PublicGameData.cardPieces[teamType][teamId].currentPieces[cardName] < piecesInCard then
		return;
	end

	local success = _G['playedCard' .. cardNameToFnName(cardName)](wz, player, cardName, param);

	if not success then
		return;
	end

	if publicGD.cardsThatCanBeActive[cardName] then
		if not publicGD.activeCards then
			publicGD.activeCards = {};
		end

		if not publicGD.activeCards[cardName] then
			publicGD.activeCards[cardName] = {};
		end

		table.insert(publicGD.activeCards[cardName], {
			playedBy = player.ID,
			playedOnTurn = wz.game.ServerGame.Game.TurnNumber,
			param = param
		});
	end

	-- reduce number of current pieces
	local result = publicGD.cardPieces[teamType][teamId].currentPieces[cardName] - piecesInCard;

	publicGD.cardPieces[teamType][teamId].currentPieces[cardName] = result > -1 and result or 0;
	Mod.PublicGameData = publicGD;

	if type(success) == 'function' then
		success();
	end
end

function playedTerritorySelectionCard(wz, player, cardName, param, modifyEvent)
	local terrId = tonumber(param);
	local terr = wz.game.Map.Territories[terrId];

	if not terr then
		return;
	end

	local msg = 'Played a ' .. cardName .. ' Card on ' .. terr.Name;
	local visTo = visibleToTeammates(player.ID, wz.game.ServerGame.Game.Players);

	if Mod.PublicGameData.cardsThatCanBeActive[cardName] then
		local duration = getSetting(cardName .. 'Duration');

		if duration then
			msg = msg .. ' for ' .. duration .. ' turn' .. (duration == 1 and '' or 's');
			visTo = nil;
		end
	end

	local modifiedEvent = {};

	if type(modifyEvent) == 'function' then
		modifiedEvent = modifyEvent();
	end

	-- print('playedTerritorySelectionCard cardName = ' .. cardName);
	-- print('modifiedEvent =');
	-- tblprint(modifiedEvent);

	local event = WL.GameOrderEvent.Create(player.ID, msg, visTo, modifiedEvent.terrModsOpt, modifiedEvent.setResourcesOpt, modifiedEvent.incomeModsOpt);

	event.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY);
	wz.addNewOrder(event);

	return true;
end

function buyCard(wz, player, cardName)
	local visTo = visibleToTeammates(player.ID, wz.game.ServerGame.Game.Players);
	local order = WL.GameOrderEvent.Create(player.ID, 'Bought a ' .. cardName .. ' Card', visTo);

	order.AddResourceOpt = {
		[player.ID] = {
			[WL.ResourceType.Gold] = -getSetting(cardName .. 'Cost');
		}
	};
	wz.addNewOrder(order);

	local piecesInCard = getSetting(cardName .. 'PiecesInCard');
	local publicGD = Mod.PublicGameData;
	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;

	publicGD.cardPieces[teamType][teamId].currentPieces[cardName] = publicGD.cardPieces[teamType][teamId].currentPieces[cardName] + piecesInCard;
	Mod.PublicGameData = publicGD;
end

function processGameOrderAttackTransfer(wz)
	if not wz.order or not wz.result then
		return;
	end

	if wz.order.proxyType ~= 'GameOrderAttackTransfer' or wz.order.PlayerID == WL.PlayerID.Neutral or playersWithSuccessfulAttacks[wz.order.PlayerID] then
		return;
	end

	if wz.result.IsAttack and wz.result.IsSuccessful then
		playersWithSuccessfulAttacks[wz.order.PlayerID] = true;
	end
end

function removeActiveCardInstance(cardName, i)
	local publicGD = Mod.PublicGameData;
	table.remove(publicGD.activeCards[cardName], i);

	if #publicGD.activeCards[cardName] < 1 then
		publicGD.activeCards[cardName] = nil;
	end

	for cardName in pairs(publicGD.cardsThatCanBeActive) do
		if publicGD.activeCards[cardName] then
			Mod.PublicGameData = publicGD;
			return;
		end
	end

	publicGD.activeCards = nil;
	Mod.PublicGameData = publicGD;
end

function removeAllActiveCardInstancesOf(cardName)
	local publicGD = Mod.PublicGameData;

	publicGD.activeCards[cardName] = nil;

	for cardName in pairs(publicGD.activeCards) do
		if publicGD[cardName] then
			Mod.PublicGameData = publicGD;
			return;
		end
	end

	publicGD.activeCards = nil;
	Mod.PublicGameData = publicGD;
end

function removeExpiredCardInstances(game, addNewOrder, cardName)
	local duration = getSetting(cardName .. 'Duration') or 1;
	local i = 1;

	while true do
		if not Mod.PublicGameData.activeCards or not Mod.PublicGameData.activeCards[cardName] then
			break;
		end

		local activeCardInstance = Mod.PublicGameData.activeCards[cardName][i];

		if not activeCardInstance then
			break;
		end

		if activeCardInstance.playedOnTurn + duration == game.ServerGame.Game.TurnNumber then
			local terr = game.Map.Territories[tonumber(activeCardInstance.param)];
			local msg = 'A ' .. cardName .. ' Card that was played on ' .. terr.Name .. ' during turn ' .. activeCardInstance.playedOnTurn .. ' wore off';
			local event = WL.GameOrderEvent.Create(activeCardInstance.playedBy, msg, nil);

			event.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY);
			addNewOrder(event);
			removeActiveCardInstance(cardName, i);
			i = i - 1;
		end

		i = i + 1;
	end
end