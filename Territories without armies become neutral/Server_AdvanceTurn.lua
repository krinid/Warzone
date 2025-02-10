require('tblprint');
require('version');

local payloadPrefix = 'TWABN_TerrsChanged=';
local canRun = nil;

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if canRun == nil then
		canRun = serverCanRunMod(game);
	end

	if not canRun then
		return;
	end

	if not Mod.PublicGameData.modCanDoChanges then
		return;
	end

	-- player owned territories with 0 armies are allowed only if they were already there

	if order.proxyType == 'GameOrderCustom' then
		if not string.find(order.Payload, '^' .. payloadPrefix) then
			return;
		end

		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		processTerrsAffectedOrder(game, order.Payload, addNewOrder);
	elseif order.proxyType == 'GameOrderAttackTransfer' then
		makeTerrsAffectedOrder(addNewOrder, tostring(order.From) .. ',' .. tostring(order.To) .. ',');
	elseif order.proxyType == 'GameOrderPlayCardAirlift' then
		makeTerrsAffectedOrder(addNewOrder, tostring(order.FromTerritoryID) .. ',' .. tostring(ToTerritoryID) .. ',');
	elseif order.proxyType == 'GameOrderPlayCardBomb' then
		makeTerrsAffectedOrder(addNewOrder, tostring(order.TargetTerritoryID) .. ',');
	elseif order.proxyType == 'GameOrderBossEvent' then
		makeTerrsAffectedOrder(addNewOrder, '', order.ModifyTerritories);
	elseif order.proxyType == 'GameOrderEvent' then
		makeTerrsAffectedOrder(addNewOrder, '', order.TerritoryModifications);
	end
end

function makeTerrsAffectedOrder(addNewOrder, terrsAffectedStr, terrMods)
	if terrMods then
		terrsAffectedStr = '';

		for _, terrMod in pairs(terrMods) do
			terrsAffectedStr = terrsAffectedStr .. tostring(terrMod.TerritoryID) .. ',';
		end
	end

	addNewOrder(WL.GameOrderCustom.Create(Mod.PublicGameData.playerForGameOrderCustoms, '', payloadPrefix .. terrsAffectedStr), true);
end

function processTerrsAffectedOrder(game, payload, addNewOrder)
	-- print('payload = ' .. payload);

	local i = #payloadPrefix + 1;
	local terrId = '';
	local terrMods = {};

	while i < #payload + 1 do
		local c = string.sub(payload, i, i);
		-- print('c = ' .. c);

		if c == ',' then
			local real = #terrId > 0 and string.find(terrId, '^%d+$');
			local terr = real and game.ServerGame.LatestTurnStanding.Territories[tonumber(terrId)];

			if terr and terrHasNoArmies(terr) then
				local terrMod = WL.TerritoryModification.Create(terr.ID);

				terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
				table.insert(terrMods, terrMod);
			end

			terrId = '';
		else
			terrId = terrId .. c;
		end

		i = i + 1;
	end

	if #terrMods < 1 then
		return;
	end

	local msg = '';
	local terrDetails = game.Map.Territories[terrMods[1].TerritoryID];

	if #terrMods == 1 then
		msg = terrDetails.Name;
	else
		msg = 'Territories';
	end

	msg = msg .. ' had no armies and became neutral';

	local order = WL.GameOrderEvent.Create(WL.PlayerID.Neutral, msg, {}, terrMods);

	if #terrMods == 1 then
		-- if there's more than 1 territory involved, then action spot could hint at where it is if player cant see it
		order.JumpToActionSpotOpt = WL.RectangleVM.Create(terrDetails.MiddlePointX, terrDetails.MiddlePointY, terrDetails.MiddlePointX, terrDetails.MiddlePointY);
	end

	addNewOrder(order);
end

function terrHasNoArmies(terr)
	-- checks if non-neutral territories have armies

	if terr.IsNeutral then
		return false;
	end

	local hasSpecialUnits = false;

	for _, unit in pairs(terr.NumArmies.SpecialUnits) do
		if unit.OwnerID == terr.OwnerPlayerID then
			hasSpecialUnits = true;

			break;
		end
	end

	return terr.NumArmies.NumArmies == 0 and not hasSpecialUnits;
end
