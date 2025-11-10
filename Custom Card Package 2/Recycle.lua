function playCardRecycle(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		data.phase = WL.TurnPhase.EmergencyBlockadeCards;
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

function playedCardRecycle(wz, player, cardName, param)
	return playedTerritorySelectionCard(wz, player, cardName, param, function()
		local terrId = tonumber(param);
		local terrFirstTurn = wz.game.ServerGame.TurnZeroStanding.Territories[terrId];
		local terrCurrTurn = wz.game.ServerGame.LatestTurnStanding.Territories[terrId];
		local currArmiesOnTerr = terrCurrTurn.NumArmies.NumArmies;
		local firstArmiesOnTerr = terrFirstTurn.NumArmies.NumArmies;
		local eliminateIfCommander = getSetting(cardName .. 'EliminateIfCommander');
		local eliminatingBecauseCommander = false;
		local armiesToAdd = -(currArmiesOnTerr - firstArmiesOnTerr);

		-- currArmiesOnTerr = 5, firstArmiesOnTerr = 2
		-- armiesToAdd = -(5 - 2)
		-- armiesToAdd = -(3)

		-- currArmiesOnTerr = 2, firstArmiesOnTerr = 5
		-- armiesToAdd = -(2 - 5)
		-- armiesToAdd = -(-3)
		-- armiesToAdd = 3

		local terrMod = WL.TerritoryModification.Create(terrId);

		terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
		terrMod.AddArmies = armiesToAdd;
		-- terrMod.SetArmiesTo = firstArmiesOnTerr;

		local removeSpecialUnitsOpt = {};
		local totalSpecialUnitValue = 0;
		local unitValuesStr = '';

		for _, unit in pairs(terrCurrTurn.NumArmies.SpecialUnits) do
			table.insert(removeSpecialUnitsOpt , unit.ID);

			local unitValue = 0;

			unitValuesStr = unitValuesStr .. '\n';

			if unit.proxyType == 'CustomSpecialUnit' then
				if unit.Health then
					unitValue = unit.Health;
				else
					unitValue = unit.DamageToKill;
				end

				unitValuesStr = unitValuesStr .. unit.Name;
			else
				if unit.proxyType == 'Commander' then
					if eliminateIfCommander then
						eliminatingBecauseCommander = true;
						break;
					end

					unitValue = 7;
				elseif unit.proxyType == 'Boss1' or unit.proxyType == 'Boss4' then
					unitValue = unit.Health;
				elseif unit.proxyType == 'Boss2' or unit.proxyType == 'Boss3' then
					unitValue = unit.Power;
				end

				unitValuesStr = unitValuesStr .. unit.proxyType;
			end

			unitValuesStr = unitValuesStr .. ' = ' .. unitValue;
			totalSpecialUnitValue = totalSpecialUnitValue + unitValue;
		end

		terrMod.RemoveSpecialUnitsOpt = removeSpecialUnitsOpt;

		local incomeModMsg = 'Value of armies that were on ' .. wz.game.Map.Territories[terrId].Name;

		if totalSpecialUnitValue > 0 then
			incomeModMsg = incomeModMsg .. '\nArmies = ' .. currArmiesOnTerr .. '\nSpecial units = ' .. totalSpecialUnitValue .. unitValuesStr;
		end

		local terrModsOpt = nil;
		local incomeModsOpt = nil;

		if eliminatingBecauseCommander then
			terrModsOpt = eliminate({player.ID}, wz.game.ServerGame.LatestTurnStanding.Territories, true, wz.game.Settings.SinglePlayer);
			table.insert(terrModsOpt, terrMod);
		else
			terrModsOpt = {terrMod};
			incomeModsOpt = {WL.IncomeMod.Create(player.ID, currArmiesOnTerr + totalSpecialUnitValue, incomeModMsg)};
		end

		return {
			terrModsOpt = terrModsOpt,
			incomeModsOpt = incomeModsOpt
		};
	end);
end
