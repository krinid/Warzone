local activeCardsApplied = {};

local function doReconnaissanceCardAffect(wz, cardName, i, activeCardInstance)
	if activeCardsApplied[i] then
		return;
	end

	activeCardsApplied[i] = true;

	local range = getSetting(cardName .. 'Range');
	local doneTerrs = {};

	function main(i, terrIds)
		if i == range then
			return;
		end

		local nextTerrs = {};

		for _, terrId in pairs(terrIds) do
			if not doneTerrs[terrId] then
				local reconCard = WL.NoParameterCardInstance.Create(WL.CardID.Reconnaissance);
				local order = WL.GameOrderPlayCardReconnaissance.Create(reconCard.ID, activeCardInstance.playedBy, terrId);

				wz.addNewOrder(order);

				if i + 1 < range then
					local terr = wz.game.Map.Territories[terrId];

					for connectedTo in pairs(terr.ConnectedTo) do
						table.insert(nextTerrs, connectedTo);
					end
				end

				doneTerrs[terrId] = true;
			end
		end

		main(i + 1, nextTerrs);
	end

	main(0, {tonumber(activeCardInstance.param)});
end

function playCardReconnaissance(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		data.phase = WL.TurnPhase.SpyingCards;
	end

	if not data.validateTerrSelection then
		data.validateTerrSelection = function(selectedTerr)
			return true;
		end;
	end

	if not data.errMsg then
		data.errMsg = '';
	end

	createTerritorySelectionCard(game, tabData, cardName, btn, vert, vert2, data);
end

function playedCardReconnaissance(wz, player, cardName, param)
	if not wz.game.Settings.Cards or not wz.game.Settings.Cards[WL.CardID.Reconnaissance] then
		return;
	end

	if not playedTerritorySelectionCard(wz, player, cardName, param) then
		return;
	end

	local i = 0;

	if Mod.PublicGameData.activeCards and Mod.PublicGameData.activeCards[cardName] then
		-- gets added as an active card after this function has finished executing
		i = #Mod.PublicGameData.activeCards[cardName] + 1;
	end

	doReconnaissanceCardAffect(wz, cardName, i, {playedBy = player.ID, playedOnTurn = wz.game.ServerGame.Game.TurnNumber, param = param});

	return true;
end

function processStartTurnReconnaissance(game, addNewOrder, cardName)
	removeExpiredCardInstances(game, addNewOrder, cardName);

	if not Mod.PublicGameData.activeCards or not Mod.PublicGameData.activeCards[cardName] then
		return;
	end

	for i, activeCardInstance in pairs(Mod.PublicGameData.activeCards[cardName]) do
		local terr = game.Map.Territories[tonumber(activeCardInstance.param)];
		local order = WL.GameOrderEvent.Create(activeCardInstance.playedBy, 'Continue ' .. cardName .. ' Card on ' .. terr.Name .. ' which was played during turn ' .. activeCardInstance.playedOnTurn);

		order.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY);
		addNewOrder(order);
		doReconnaissanceCardAffect({game = game, addNewOrder = addNewOrder}, cardName, i, activeCardInstance);
	end
end

function processOrderReconnaissance(wz, cardName)
	return;
end