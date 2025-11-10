function playCardImmobilize(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		-- use deploys as thats before any type of attack happens
		data.phase = WL.TurnPhase.Deploys;
	end

	if not data.validateTerrSelection then
		data.validateTerrSelection = function(selectedTerr)
			local terrId = selectedTerr.ID;
			local terr = game.LatestStanding.Territories[terrId];

			if terr.OwnerPlayerID == game.Us.ID then
				return true;
			end

			for connectedTo in pairs(selectedTerr.ConnectedTo) do
				if game.LatestStanding.Territories[connectedTo].OwnerPlayerID == game.Us.ID then
					return true;
				end
			end

			return false;
		end;
	end

	if not data.errMsg then
		data.errMsg = 'You can only play a ' .. cardName .. ' Card on territories adjacent to yours';
	end

	createTerritorySelectionCard(game, tabData, cardName, btn, vert, vert2, data);
end

function playedCardImmobilize(wz, player, cardName, param)
	return playedTerritorySelectionCard(wz, player, cardName, param);
end

function processStartTurnImmobilize(game, addNewOrder, cardName)
	removeExpiredCardInstances(game, addNewOrder, cardName);
end

local function doImmobilizeCardEffect(wz, cardName, i, activeCardInstance)
	local affectedTerr = wz.game.Map.Territories[tonumber(activeCardInstance.param)];

	local isAttackTransfer = wz.order.proxyType == 'GameOrderAttackTransfer';
	local isAirlift = wz.order.proxyType == 'GameOrderPlayCardAirlift';

	local movementType = 'attack/transfer';
	local to = 'To';
	local from = 'From';

	if isAirlift then
		movementType = 'airlift';
		to = 'ToTerritoryID';
		from = 'FromTerritoryID';
	end

	local toName = wz.game.Map.Territories[wz.order[to]].Name;
	local fromName = wz.game.Map.Territories[wz.order[from]].Name;

	wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

	local msg = 'Skipped ' .. movementType .. ' to ' .. toName .. ' from ' .. fromName .. ' because a ' .. cardName .. ' Card was played on ' .. affectedTerr.Name;
	local event = WL.GameOrderEvent.Create(WL.PlayerID.Neutral, msg, {}, {WL.TerritoryModification.Create(affectedTerr.ID)});

	event.JumpToActionSpotOpt = WL.RectangleVM.Create(affectedTerr.MiddlePointX, affectedTerr.MiddlePointY, affectedTerr.MiddlePointX, affectedTerr.MiddlePointY);
	wz.addNewOrder(event);
end

function processOrderImmobilize(wz, cardName)
	if not Mod.PublicGameData.activeCards then
		return;
	end

	local isAttackTransfer = wz.order.proxyType == 'GameOrderAttackTransfer';
	local isAirlift = wz.order.proxyType == 'GameOrderPlayCardAirlift';

	if not (isAttackTransfer or isAirlift) then
		return;
	end

	local to = 'To';
	local from = 'From';

	if isAirlift then
		to = 'ToTerritoryID';
		from = 'FromTerritoryID';
	end

	local i = 1;

	while true do
		if not Mod.PublicGameData.activeCards or not Mod.PublicGameData.activeCards[cardName] then
			break;
		end

		local activeCardInstance = Mod.PublicGameData.activeCards[cardName][i];

		if not activeCardInstance then
			break;
		end

		local affectedTerr = tonumber(activeCardInstance.param);

		if wz.order[to] == affectedTerr or wz.order[from] == affectedTerr then
			doImmobilizeCardEffect(wz, cardName, i, activeCardInstance);
		end

		i = i + 1;
	end
end
