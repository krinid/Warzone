function playCardDoubleTap(game, tabData, cardName, btn, vert, vert2, data)
	if not data.mode then
		data.mode = 1;
	end

	function fromCheck(selectedTerr)
		local terrId = selectedTerr.ID;
		local terr = game.LatestStanding.Territories[terrId];

		return terr.OwnerPlayerID == game.Us.ID;
	end

	btn.SetInteractable(false);

	if not UI.IsDestroyed(vert2) then
		UI.Destroy(vert2);
	end

	local vert2 = Vert(vert);
	local errMsg;

	Label(vert2).SetText('Select territory that you want to attack from');
	createSelectTerritoryMenu(vert2, data.from, function(selectedTerr)
		if game.Settings.MultiAttack then
			-- only needs to be own territory at time of execution
			data.from = selectedTerr;
			playCardDoubleTap(game, tabData, cardName, btn, vert, vert2, data);
		else
			if fromCheck(selectedTerr) then
				errMsg.SetText('');
				data.from = selectedTerr;
				playCardDoubleTap(game, tabData, cardName, btn, vert, vert2, data);
			else
				errMsg.SetText('From must be one of your own territories');
			end
		end
	end);

	errMsg = Label(vert2).SetColor('#FF0000');

	local connectedTerrIds = nil;
	local connectedTerrNames = nil;

	if data.from then
		connectedTerrIds = {};
		connectedTerrNames = {};

		for terrId in pairs(data.from.ConnectedTo) do
			table.insert(connectedTerrIds, terrId);
			table.insert(connectedTerrNames, game.Map.Territories[terrId].Name);
		end
	end

	Dropdowns.create(vert2, 'Select neighboring territory that you want to attack', data.to, connectedTerrNames, function(n)
		data.to = n;
	end);

	local modes = {'Attack or Transfer'};

	if game.Settings.AllowAttackOnly then
		table.insert(modes, 'Attack Only');
	end

	if game.Settings.AllowTransferOnly then
		table.insert(modes, 'Transfer Only');
	end

	if #modes > 1 then
		Dropdowns.create(vert2, 'Attack/transfer mode', data.mode, modes, function(n)
			data.mode = n;
		end);
	end

	createDoneAndCancelForCardUse(game, tabData, cardName, vert2, game.Us.ID, function()
		if not (data.from and data.to) then
			return;
		end

		local to = game.Map.Territories[connectedTerrIds[data.to]];
		local mode = string.gsub(string.gsub(modes[data.mode], ' or ', ''), ' Only', '');
		-- lua doesnt have an or in patterns

		return {
			msg = ' from ' .. data.from.Name .. ' to ' .. to.Name,
			param = data.from.ID .. '_' .. to.ID .. '_' .. mode,
			phase = WL.TurnPhase.Attacks
		};
	end);
end

local failedAttacks = {};
--[[
{
	playerId = {
		fromTerrId = {
			toTerrId = {orders}
		}
	}
}
]]

local function doDoubleTapCardEffect(wz, player, cardName, param)
	for i, activeCardInstance in ipairs(Mod.PublicGameData.activeCards[cardName]) do
		if activeCardInstance.playedBy == player.ID and activeCardInstance.param == param then
			local params = split(activeCardInstance.param, '_');
			local from = wz.game.ServerGame.LatestTurnStanding.Territories[tonumber(params[1])];
			local to = wz.game.ServerGame.LatestTurnStanding.Territories[tonumber(params[2])];
			local mode = WL.AttackTransferEnum[params[3]];

			if (
				from.OwnerPlayerID == player.ID and
				failedAttacks[player.ID] and
				failedAttacks[player.ID][from.ID] and
				failedAttacks[player.ID][from.ID][to.ID]
			) then
				local order = failedAttacks[player.ID][from.ID][to.ID][1];
				local numArmies = from.NumArmies.Subtract(WL.Armies.Create(wz.game.Settings.OneArmyMustStandGuardOneOrZero));
				local newOrder = WL.GameOrderAttackTransfer.Create(player.ID, from.ID, to.ID, mode, false, numArmies, order.AttackTeammates);

				table.remove(failedAttacks[player.ID][from.ID][to.ID], 1);

				if #failedAttacks[player.ID][from.ID][to.ID] < 1 then
					failedAttacks[player.ID][from.ID][to.ID] = nil;
				end

				removeActiveCardInstance(cardName, i);
				wz.addNewOrder(newOrder);

				break;
			end
		end
	end
end

function playedCardDoubleTap(wz, player, cardName, param)
	local params = split(param, '_');

	if #params ~= 3 then
		return;
	end

	local from = wz.game.Map.Territories[tonumber(params[1])];
	local to = wz.game.Map.Territories[tonumber(params[2])];

	if not (from and to) then
		return;
	end

	local isConnected = false;

	for terrId in pairs(from.ConnectedTo) do
		if terrId == to.ID then
			isConnected = true;
			break;
		end
	end

	if not isConnected then
		return;
	end

	local mode = params[3];

	if type(WL.AttackTransferEnum[mode]) ~= 'number' then
		return;
	end

	local msg = 'Played a ' .. cardName .. ' Card from ' .. from.Name .. ' to ' .. to.Name;
	local event = WL.GameOrderEvent.Create(player.ID, msg, visibleToTeammates(player.ID, wz.game.ServerGame.Game.Players));
	event.JumpToActionSpotOpt = WL.RectangleVM.Create(from.MiddlePointX, from.MiddlePointY, from.MiddlePointX, from.MiddlePointY);

	wz.addNewOrder(event);

	return function()
		doDoubleTapCardEffect(wz, player, cardName, param);
	end;
end

function processStartTurnDoubleTap(game, addNewOrder, cardName)
	removeAllActiveCardInstancesOf(cardName);
end

function processOrderDoubleTap(wz, cardName)
	if wz.order.proxyType ~= 'GameOrderAttackTransfer' then
		return;
	end

	if not (wz.result.IsAttack and not wz.result.IsSuccessful) then
		return;
	end

	local playerId = wz.order.PlayerID;
	local from = wz.order.From;
	local to = wz.order.To;

	if not failedAttacks[playerId] then
		failedAttacks[playerId] = {};
	end

	if not failedAttacks[playerId][from] then
		failedAttacks[playerId][from] = {};
	end

	if not failedAttacks[playerId][from][to] then
		failedAttacks[playerId][from][to] = {};
	end

	table.insert(failedAttacks[playerId][from][to], wz.order);
end