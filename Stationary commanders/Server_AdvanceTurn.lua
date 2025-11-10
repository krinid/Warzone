require('tblprint');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	local isAttackTransfer = order.proxyType == 'GameOrderAttackTransfer';
	local isAirlift = order.proxyType == 'GameOrderPlayCardAirlift';

	if not (isAttackTransfer or isAirlift) then
		return;
	end

	local orderArmies = order[(isAttackTransfer and 'NumArmies' or 'Armies')];

	if #orderArmies.SpecialUnits < 1 then
		return;
	end

	local commanders = {};

	for _, unit in pairs(orderArmies.SpecialUnits) do
		if unit.proxyType == 'Commander' then
			table.insert(commanders, unit);
		end
	end

	if #commanders < 1 then
		return;
	end

	function skip()
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		-- show better skipped message
		local visibility = game.Settings.FogLevel == WL.GameFogLevel.NoFog and nil or {};
		local orderType = (isAirlift and 'airlift' or 'attack/transfer') .. ' involving commanders';
		local from = ' from ' .. game.Map.Territories[(isAirlift and order.FromTerritoryID or order.From)].Name;
		local to = ' to ' .. game.Map.Territories[(isAirlift and order.ToTerritoryID or order.To)].Name;

		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Mod skipped order: ' .. orderType .. from .. to, visibility));
	end

	if game.Settings.NoSplit then
		-- if it is no split mode and game has commanders and each player has 1 territory then the game cant progress
		-- so lets make sure it can progress before skipping orders

		local playerOwnedTerrs = {};
		local canSkip = false;

		for _, territory in pairs(game.ServerGame.LatestTurnStanding.Territories) do
			if not territory.IsNeutral then
				if not playerOwnedTerrs[territory.OwnerPlayerID] then
					playerOwnedTerrs[territory.OwnerPlayerID] = 0;
				end

				playerOwnedTerrs[territory.OwnerPlayerID] = playerOwnedTerrs[territory.OwnerPlayerID] + 1;

				if playerOwnedTerrs[territory.OwnerPlayerID] > 1 then
					canSkip = true;
					break;
				end
			end
		end

		if canSkip then
			skip();
			-- dont recreate the order because its no split mode
		end
	else
		local numArmies = orderArmies.Subtract(WL.Armies.Create(0, commanders));
		local newOrder = nil;

		if isAttackTransfer then
			newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, numArmies, order.AttackTeammates);
		elseif isAirlift then
			newOrder = WL.GameOrderPlayCardAirlift.Create(order.CardInstanceID, order.PlayerID, order.FromTerritoryID, order.ToTerritoryID, numArmies);
		end

		skip();
		addNewOrder(newOrder);
	end
end
