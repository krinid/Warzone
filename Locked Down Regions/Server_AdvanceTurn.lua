require('tblprint');
require('version');

local canRun;

function Server_AdvanceTurn_Start(game, addNewOrder)
	local host = game.Settings.StartedBy;

	if not host then
		return;
	end

	if not game.Game.Players[host] then
		return;
	end

	canRun = serverCanRunMod(game);

	if not canRun then
		return;
	end

	local gameTurnNo = game.ServerGame.Game.TurnNumber;
	local publicGD = Mod.PublicGameData;

	for bonusId, turnNo in pairs(publicGD.lockedDownRegions) do
		if turnNo < gameTurnNo then
			local bonus = game.Map.Bonuses[bonusId];
			local bonusValue = game.Settings.OverriddenBonuses[bonusId] or bonus.Amount;
			local msg = 'Lockdown in ' .. bonus.Name .. ' [' .. bonusValue .. '] ended';

			addNewOrder(WL.GameOrderEvent.Create(host, msg, nil));
			publicGD.lockedDownRegions[bonusId] = nil;
		end
	end

	for bonusId, turnNo in pairs(publicGD.newLockedDownRegions) do
		local bonus = game.Map.Bonuses[bonusId];
		local bonusValue = game.Settings.OverriddenBonuses[bonusId] or bonus.Amount;
		local msg = 'Lockdown in ' .. bonus.Name .. ' [' .. bonusValue .. '] started, ends at end of turn ' .. turnNo;

		addNewOrder(WL.GameOrderEvent.Create(host, msg, nil));
		publicGD.lockedDownRegions[bonusId] = turnNo;
	end

	publicGD.newLockedDownRegions = {};
	Mod.PublicGameData = publicGD;
end

function Server_AdvanceTurn_Order(Game, order, result, skipThisOrder, addNewOrder)
	game = Game;

	-- skip orders by ai for easier debugging
-- 	if order.PlayerID ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI then
-- 		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
-- 		return;
-- 	end

	local host = game.Settings.StartedBy;

	if not host then
		return;
	end

	if not game.Game.Players[host] then
		return;
	end

	if not canRun then
		return;
	end

	local isAttackTransfer = order.proxyType == 'GameOrderAttackTransfer';
	local isAirlift = order.proxyType == 'GameOrderPlayCardAirlift';

	if not (isAttackTransfer or isAirlift) then
		return;
	end

-- 	print('in attack/transfer or airlift order');

	local movementType = 'attack/transfer';
	local fromKey = 'From';
	local toKey = 'To';

	if isAirlift then
		movementType = 'airlift';
		fromKey = 'FromTerritoryID';
		toKey = 'ToTerritoryID';
	end

	local from = order[fromKey];
	local fromTerr = game.Map.Territories[from];
	local fromInLockedDownRegion = territoryInLockedDownRegion(fromTerr.ID);

	local to = order[toKey];
	local toTerr = game.Map.Territories[to];
	local toInLockedDownRegion = territoryInLockedDownRegion(toTerr.ID);

-- 	print('fromTerr.Name = ' .. fromTerr.Name);
-- 	print('toTerr.Name = ' .. toTerr.Name);
-- 	print('fromInLockedDownRegion = ' .. tostring(fromInLockedDownRegion));
-- 	print('toInLockedDownRegion = ' .. tostring(toInLockedDownRegion));

	if fromInLockedDownRegion == toInLockedDownRegion then
		-- if neither or both territories are in the same bonus
		-- let the army movement happen

		print('neither or both territories in same bonus');
		return;
	end

-- 	print('both territories in different bonuses');

	local gameTurnNumber = game.ServerGame.Game.TurnNumber - 1;
	local fromIsActiveLockdown = fromInLockedDownRegion and (gameTurnNumber <= Mod.PublicGameData.lockedDownRegions[fromInLockedDownRegion]);
	local toIsActiveLockdown = toInLockedDownRegion and (gameTurnNumber <= Mod.PublicGameData.lockedDownRegions[toInLockedDownRegion]);
	local bothInActiveLockdown = fromIsActiveLockdown and toIsActiveLockdown;

-- 	print('gameTurnNumber', gameTurnNumber);
-- 	print(fromInLockedDownRegion and (Mod.PublicGameData.lockedDownRegions[fromInLockedDownRegion]));
-- 	print(toInLockedDownRegion and (Mod.PublicGameData.lockedDownRegions[toInLockedDownRegion]));
-- 	print('fromIsActiveLockdown', fromIsActiveLockdown);
-- 	print('toIsActiveLockdown', toIsActiveLockdown);

	if not (fromIsActiveLockdown or toIsActiveLockdown) then
		-- if neither of the territories are in an active lockdown
		-- let the army movement happen

-- 		print('neither of the territories are in an active lockdown');
		return;
	end

-- 	print('one or both territories are in an active lockdown');

	skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

	local msg = 'Skipped ' .. movementType .. ' to ' .. toTerr.Name .. ' from ' .. fromTerr.Name .. ' because it goes into or out of ';

	if fromIsActiveLockdown then
		local affectedBonus = game.Map.Bonuses[fromInLockedDownRegion];
		local bonusValue = game.Settings.OverriddenBonuses[affectedBonus.ID] or affectedBonus.Amount;

		msg = msg .. affectedBonus.Name .. ' [' .. bonusValue .. '] ';
	end

	if bothInActiveLockdown then
		msg = msg .. 'and ';
	end

	if toIsActiveLockdown then
		local affectedBonus = game.Map.Bonuses[toInLockedDownRegion];
		local bonusValue = game.Settings.OverriddenBonuses[affectedBonus.ID] or affectedBonus.Amount;

		msg = msg .. affectedBonus.Name .. ' [' .. bonusValue .. '] ';
	end

	msg = msg .. 'which ' .. (bothInActiveLockdown and 'are' or 'is') .. ' locked down until end of turn' .. (bothInActiveLockdown and 's' or '');

	if fromIsActiveLockdown then
		msg = msg .. ' ' .. Mod.PublicGameData.lockedDownRegions[fromInLockedDownRegion];
	end

	if bothInActiveLockdown then
		msg = msg .. ' and';
	end

	if toIsActiveLockdown then
		msg = msg .. ' ' .. Mod.PublicGameData.lockedDownRegions[toInLockedDownRegion];
	end

	local playerId = WL.PlayerID.Neutral;-- neutral so that skipped orders cant be used as delays
	local affectedTerr = fromIsActiveLockdown and fromTerr or toTerr;-- should only be from or to. if both use from
	local event = WL.GameOrderEvent.Create(playerId, msg, {}, {WL.TerritoryModification.Create(affectedTerr.ID)});

	event.JumpToActionSpotOpt = WL.RectangleVM.Create(affectedTerr.MiddlePointX , affectedTerr.MiddlePointY, affectedTerr.MiddlePointX, affectedTerr.MiddlePointY);
	addNewOrder(event);
end

function territoryInBonus(terrId, bonusId)
-- 	print('in territoryInBonus');

	local terr = game.Map.Territories[terrId];
	local bonusName = game.Map.Bonuses[bonusId].Name;

	for _, terrBonusId in pairs(terr.PartOfBonuses) do
		if terrBonusId == bonusId then
-- 			print(terr.Name .. ' is part of bonus ' .. bonusName);
			return bonusId;
		end
	end

-- 	print(terr.Name .. ' is not part of bonus ' .. bonusName);

	return nil;
end

function territoryInLockedDownRegion(terrId)
	local ret = nil;

	for bonusId in pairs(Mod.PublicGameData.lockedDownRegions) do
		ret = territoryInBonus(terrId, bonusId);

		if ret then
			break;
		end
	end

	return ret;
end
