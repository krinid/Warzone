require('settings');
require('tblprint');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if order.proxyType ~= 'GameOrderAttackTransfer' or order.PlayerID == WL.PlayerID.Neutral then
		return;
	end

	local us = game.ServerGame.Game.PlayingPlayers[order.PlayerID];

	if not us.IsAIOrHumanTurnedIntoAI then
		return;
	end

	local to = game.ServerGame.LatestTurnStanding.Territories[order.To];
	local them = {
		PlayerID = WL.PlayerID.Neutral,
		Team = -1,
		IsAIOrHumanTurnedIntoAI = false
	};

	if to.OwnerPlayerID ~= WL.PlayerID.Neutral then
		them = game.ServerGame.Game.PlayingPlayers[to.OwnerPlayerID];
	end

	local usId = us.PlayerID or us.AIPlayerID;
	local themId = them.PlayerID or them.AIPlayerID;

	-- print('usId = ' .. usId);
	-- print('themId = ' .. themId);
	-- print('us.Team = ' .. us.Team);
	-- print('them.Team = ' .. them.Team);
	-- print('(us.Team ~= -1 and us.Team == them.Team) = ' .. tostring((us.Team ~= -1 and us.Team == them.Team)));
	-- print('us.PlayerID = ' .. tostring(us.PlayerID));
	-- print('them.PlayerID = ' .. tostring(them.PlayerID));
	-- print('us.PlayerID == them.PlayerID = ' .. tostring(us.PlayerID == them.PlayerID));

	local canMakeTransfers = getSetting('EnableTransfers');
	local canAttackOtherAIs = getSetting('EnableAttackOtherAIs');
	local canAttackNeutrals = getSetting('EnableAttackNeutrals');

	if not them.IsAIOrHumanTurnedIntoAI and themId ~= WL.PlayerID.Neutral and themId ~= usId then
		print('cant attack players');
		skip(game, order, skipThisOrder);
	elseif ((usId == themId) or (us.Team ~= -1 and us.Team == them.Team)) and not canMakeTransfers then
		print('cant make transfers');
		skip(game, order, skipThisOrder);
	elseif them.IsAIOrHumanTurnedIntoAI and usId ~= themId and not canAttackOtherAIs then
		print('cant attack other ais');
		skip(game, order, skipThisOrder);
	elseif themId == WL.PlayerID.Neutral and not canAttackNeutrals then
		print('cant attack neutrals');
		skip(game, order, skipThisOrder);
	end
end

function skip(game, order, skipThisOrder)
	local attackTransferFromOwner = order.PlayerID;
	local attackTransferToOwner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
	local attackTransferFrom = game.Map.Territories[order.From].Name;
	local attackTransferTo = game.Map.Territories[order.To].Name;

	-- print('about to skip order');
	-- print('from ' .. attackTransferFromOwner .. ' in ' .. attackTransferFrom);
	-- print('to ' .. attackTransferToOwner .. ' in ' .. attackTransferTo);
	-- print('order = ');
	-- tblprint(order);

	skipThisOrder(WL.ModOrderControl.Skip);
end
