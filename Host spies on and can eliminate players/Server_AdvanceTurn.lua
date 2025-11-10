require('eliminate');
require('tblprint');
require('version');

local satsPayload = 'NoTeaming_ServerAdvanceTurnStart';
local eliminatedPlayers = nil;
local canRun = false;
local host;

function Server_AdvanceTurn_Start(game, addNewOrder)
	print('in Server_AdvanceTurn_Start');

	canRun = serverCanRunMod(game);

	if not canRun then
		print('exit because cant run');
		return;
	end

	host = game.Settings.StartedBy;

	if not host then
		print('exit because no host');
		return;
	end

	local hostPlayer = game.Game.Players[host];

	if not hostPlayer then
		print('exit because no hostPlayer');
		return;
	end

	if not ((hostPlayer.Team == -1) or (hostPlayer.Team ~= -1 and Mod.PublicGameData.teams[hostPlayer.Team] == 1)) then
		print('exit because hostPlayer is part of a team');
		return;
	end

	print('carrying on as normal');
	addNewOrder(WL.GameOrderCustom.Create(host, '', satsPayload));
end

function sats(game, addNewOrder)
	eliminatePlayers(game, addNewOrder);
	giveSpyCardPieces(game, addNewOrder);

	local playerGD = Mod.PlayerGameData;

	playerGD[host].eliminating = {};
	Mod.PlayerGameData = playerGD;
end

function eliminatePlayers(game, addNewOrder)
	local eliminating = {};
	local msg = 'Eliminate ';

	eliminatedPlayers = {};

	for playerId in pairs(Mod.PlayerGameData[host].eliminating) do
		local player = game.ServerGame.Game.Players[playerId];

		if player and player.State == WL.GamePlayerState.Playing then
			msg = msg .. player.DisplayName(nil, false) .. ', ';
			table.insert(eliminating, playerId);
			eliminatedPlayers[playerId] = true;
		end
	end

	msg = string.gsub(msg, ', $', '');

	if #eliminating > 0 then
		addNewOrder(WL.GameOrderEvent.Create(host, msg, nil, eliminate(eliminating, game.ServerGame.LatestTurnStanding.Territories, true, game.Settings.SinglePlayer)));
	end
end

function giveSpyCardPieces(game, addNewOrder)
	local spyCardSettings = game.ServerGame.Settings.Cards[WL.CardID.Spy];

	playersNeedToSpyOn = {};
	numPlayersNeedToSpyOn = 0;
	existingSpyCards = {};

	-- print('eliminatedPlayers =');
	-- tblprint(eliminatedPlayers);

	for playerId, player in pairs(game.ServerGame.Game.PlayingPlayers) do
		if not eliminatedPlayers[playerId] and playerId ~= host then
			playersNeedToSpyOn[playerId] = true;
			numPlayersNeedToSpyOn = numPlayersNeedToSpyOn + 1;
		end
	end

	if spyCardSettings.CanSpyOnNeutral then
		playersNeedToSpyOn[WL.PlayerID.Neutral] = true;
		numPlayersNeedToSpyOn = numPlayersNeedToSpyOn + 1;
	end

	for _, activeCard in pairs(game.ServerGame.LatestTurnStanding.ActiveCards) do
		if activeCard.Card.proxyType == 'GameOrderPlayCardSpy' and activeCard.Card.PlayerID == host then
			if game.ServerGame.Game.TurnNumber + 1 < activeCard.ExpiresAfterTurn then
				local spyOn = activeCard.Card.TargetPlayerID;

				if playersNeedToSpyOn[spyOn] then
					playersNeedToSpyOn[spyOn] = nil;
					numPlayersNeedToSpyOn = numPlayersNeedToSpyOn - 1;
				end
			end
		end
	end

	-- print('playersNeedToSpyOn =');
	-- tblprint(playersNeedToSpyOn);

	local cards = game.ServerGame.LatestTurnStanding.Cards[host];

	if cards then
		for instanceId, instance in pairs(cards.WholeCards) do
			if instance.CardID == WL.CardID.Spy then
				existingSpyCards[instanceId] = true;
			end
		end
	end

	local numWholeCardsNeeded = numPlayersNeedToSpyOn;
	local piecesInCard = spyCardSettings.NumPieces;
	local numSpyCardPiecesToAdd = numWholeCardsNeeded * piecesInCard;
	local totalPiecesToAdd = numSpyCardPiecesToAdd;

	if totalPiecesToAdd ~= 0 then
		local order = WL.GameOrderEvent.Create(host, 'Enable host to spy on everyone', {});

		if totalPiecesToAdd ~= 0 then
			order.AddCardPiecesOpt = {[host] = {[WL.CardID.Spy] = totalPiecesToAdd}};
		end

		addNewOrder(order);
	end

	addNewOrder(WL.GameOrderCustom.Create(host, 'Spy on everyone', 'NoTeaming_spyoneveryone'));
end

local expectingSpyCardsToBePlayed = false;
local numSpyCardsPlayed = 0;

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if not host then
		return;
	end

	local hostPlayer = game.Game.Players[host];

	if not hostPlayer then
		return;
	end

	if not canRun then
		return;
	end

	if not ((hostPlayer.Team == -1) or (hostPlayer.Team ~= -1 and Mod.PublicGameData.teams[hostPlayer.Team] == 1)) then
		return;
	end

	preventInteractionsWithHost(game, order, result, skipThisOrder, addNewOrder);

	if order.PlayerID ~= host then
		return;
	end

	local disallowedOrderTypes = {
		GameOrderPurchase = true,
		GameOrderDeploy = true,
		GameOrderAttackTransfer = true,
		GameOrderBossEvent = true
	};

	-- other order types are allowed for cross-compatibility with other GM mods

	if disallowedOrderTypes[order.proxyType] then
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
	end

	if order.proxyType == 'GameOrderCustom' then
		if order.Payload == satsPayload then
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
			sats(game, addNewOrder);
		elseif order.Payload == 'NoTeaming_spyoneveryone' then
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
			expectingSpyCardsToBePlayed = true;
			spyOnEveryone(game, order, result, skipThisOrder, addNewOrder);
		end
	end

	-- prevent skipped card spam
	-- spying on everyone anyway
	if order.proxyType == 'GameOrderPlayCardSpy' then
		if expectingSpyCardsToBePlayed then
			numSpyCardsPlayed = numSpyCardsPlayed + 1;

			if numSpyCardsPlayed > numPlayersNeedToSpyOn then
				skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
			end
		end
	end
end

function spyOnEveryone(game, order, result, skipThisOrder, addNewOrder)
	local cards = game.ServerGame.LatestTurnStanding.Cards[host];

	if not cards then
		return;
	end

	local i = 0;

	for instanceId, instance in pairs(cards.WholeCards) do
		if instance.CardID == WL.CardID.Spy and not existingSpyCards[instanceId] then
			i = i + 1;

			for playerId in pairs(playersNeedToSpyOn) do
				addNewOrder(WL.GameOrderPlayCardSpy.Create(instanceId, host, playerId));
				playersNeedToSpyOn[playerId] = nil;
				break;
			end

			if i == numPlayersNeedToSpyOn then
				break;
			end
		end
	end
end

function preventInteractionsWithHost(game, order, result, skipThisOrder, addNewOrder)
	-- keep host alive to make sure the game stays in their dashboard for better accessibility

	local affectedTerrs = {};-- for skip order message to get correct visibility

	function addAffectedTerr(terrId)
		table.insert(affectedTerrs, WL.TerritoryModification.Create(terrId));
	end

	function getAffectedTerrName(i)
		return game.Map.Territories[affectedTerrs[i].TerritoryID].Name;
	end

	local playCardSkippedPrefix = 'play ' .. string.gsub(string.gsub(order.proxyType, 'GameOrderPlayCard', ''), 'Abandon', 'Emergency Blockade') .. ' Card order';

	function skip(action)
		local skippedMessage = WL.GameOrderEvent.Create(order.PlayerID, 'Skipped ' .. action .. ' because the host is not playing and must be kept alive', {}, affectedTerrs);

		if #affectedTerrs > 0 then
			local terr = game.Map.Territories[affectedTerrs[1].TerritoryID];

			skippedMessage.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY);
		end

		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		addNewOrder(skippedMessage);
	end

	if order.proxyType == 'GameOrderAttackTransfer' then
		local terr = game.ServerGame.LatestTurnStanding.Territories[order.To];

		if terr.OwnerPlayerID == host and order.PlayerID ~= host then
			addAffectedTerr(order.From);
			addAffectedTerr(order.To);
			skip('attack / transfer order from ' .. getAffectedTerrName(1) .. ' to ' .. getAffectedTerrName(2));
		end
	elseif order.proxyType == 'GameOrderPlayCardAbandon' or order.proxyType == 'GameOrderPlayCardBlockade' then
		local terr = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID];

		if terr.OwnerPlayerID == host then
			addAffectedTerr(terr.ID);
			skip(playCardSkippedPrefix .. ' on ' .. terr.Name);
		end
	elseif order.proxyType == 'GameOrderPlayCardAirlift' then
		local toTerr = game.ServerGame.LatestTurnStanding.Territories[order.ToTerritoryID];
		local fromTerr = game.ServerGame.LatestTurnStanding.Territories[order.FromTerritoryID];

		if toTerr.OwnerPlayerID == host or fromTerr.OwnerPlayerID == host then
			addAffectedTerr(fromTerr.ID);
			addAffectedTerr(toTerr.ID);
			skip(playCardSkippedPrefix .. ' from ' .. getAffectedTerrName(1) .. ' to ' .. getAffectedTerrName(2));
		end
	elseif order.proxyType == 'GameOrderPlayCardGift' then
		local terr = game.ServerGame.LatestTurnStanding.Territories[order.TerritoryID];

		if terr.OwnerPlayerID == host or order.GiftTo == host then
			addAffectedTerr(terr.ID);
			skip(playCardSkippedPrefix .. ' on ' .. terr.Name);
		end
	elseif order.proxyType == 'GameOrderEvent' then
		local orderChanged = false;
		local allowedTerrMods = {};

		for _, terrMod in pairs(order.TerritoryModifications) do
			local terr = game.ServerGame.LatestTurnStanding.Territories[terrMod.TerritoryID];

			if terr.OwnerPlayerID == host or (terr.OwnerPlayerID ~= host and terrMod.SetOwnerOpt == host) then
				orderChanged = true;
			else
				table.insert(allowedTerrMods, terrMod);
			end
		end

		if orderChanged then
			skip(order.Message);

			local newOrder = WL.GameOrderEvent.Create(order.PlayerID, order.Message, order.VisibleToOpt, allowedTerrMods, order.SetResourceOpt, order.IncomeMods);
			local optionalKeys = {'AddCardPiecesOpt', 'RemoveWholeCardsOpt', 'JumpToActionSpotOpt'};

			for _, key in pairs(optionalKeys) do
				if order[key] then
					newOrder[key] = order[key];
				end
			end

			addNewOrder(newOrder);
		end
	end
end
