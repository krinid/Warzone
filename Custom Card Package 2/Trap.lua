function playCardTrap(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		-- use deploys as thats before any type of attack happens
		data.phase = WL.TurnPhase.Deploys;
	end

	if not data.validateTerrSelection then
		data.validateTerrSelection = function(selectedTerr)
			local terrId = selectedTerr.ID;
			local terr = game.LatestStanding.Territories[terrId];

			return terr.OwnerPlayerID == game.Us.ID;
		end;
	end

	if not data.errMsg then
		data.errMsg = 'You can only play a ' .. cardName .. ' Card on one of your own territories';
	end

	createTerritorySelectionCard(game, tabData, cardName, btn, vert, vert2, data);
end

function playedCardTrap(wz, player, cardName, param)
	return playedTerritorySelectionCard(wz, player, cardName, param);
end

function processStartTurnTrap(game, addNewOrder, cardName)
	removeAllActiveCardInstancesOf(cardName);
end

local function doTrapCardEffect(wz, cardName, i, activeCardInstance)
	local targetTerr = wz.order.To;
	local attackedBy = wz.order.PlayerID;
	local playedById = activeCardInstance.playedBy;
	local players = wz.game.ServerGame.Game.Players;
	local isDifferentPlayer = players[attackedBy].Team == -1 and attackedBy ~= playedById;
	local isDifferentTeam = players[attackedBy].Team ~= -1 and players[attackedBy].Team ~= players[playedById].Team;
	local terrName = wz.game.Map.Territories[targetTerr].Name;
	local eliminateIfCommander = getSetting(cardName .. 'EliminateIfCommander');
	local eliminatingBecauseCommander = false;

	if not (isDifferentPlayer or isDifferentTeam) then
		return;
	end

	local armiesTakingOver = wz.result.ActualArmies.Subtract(wz.result.AttackingArmiesKilled);
	local specialUnitsToRemove = {};

	for _, unit in pairs(armiesTakingOver.SpecialUnits) do
		if eliminateIfCommander and unit.proxyType == 'Commander' then
			eliminatingBecauseCommander = true;
		end

		table.insert(specialUnitsToRemove, unit.ID);
	end

	local mod = WL.TerritoryModification.Create(targetTerr);

	mod.SetOwnerOpt = WL.PlayerID.Neutral;
	mod.AddArmies = round(armiesTakingOver.NumArmies * getSetting(cardName .. 'Multiplier')) - armiesTakingOver.NumArmies;
	-- mod.SetArmiesTo = round(armiesTakingOver.NumArmies * getSetting(cardName .. 'Multiplier'));
	mod.RemoveSpecialUnitsOpt = specialUnitsToRemove;

	if eliminatingBecauseCommander then
		local mods = eliminate({attackedBy}, wz.game.ServerGame.LatestTurnStanding.Territories);

		table.insert(mods, mod);
		wz.addNewOrder(WL.GameOrderEvent.Create(playedById, 'Trap activated', {}, mods), true);
	else
		wz.addNewOrder(WL.GameOrderEvent.Create(playedById, 'Trap activated', {}, {mod}), true);
	end

	removeActiveCardInstance(cardName, i);
end

function processOrderTrap(wz, cardName)
	if not Mod.PublicGameData.activeCards then
		return;
	end

	if wz.order.proxyType ~= 'GameOrderAttackTransfer' then
		return;
	end

	if not (wz.result.IsAttack and wz.result.IsSuccessful) then
		return;
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

		if wz.order.To == tonumber(activeCardInstance.param) then
			doTrapCardEffect(wz, cardName, i, activeCardInstance);
			i = i - 1;
		end

		i = i + 1;
	end
end
