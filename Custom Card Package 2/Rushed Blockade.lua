function playCardRushedBlockade(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		data.phase = WL.TurnPhase.Attacks;
	end

	if not data.validateTerrSelection then
		data.validateTerrSelection = function(selectedTerr)
			if game.Settings.MultiAttack then
				data.selectedTerr = selectedTerr;

				return true;
			else
				local terrId = selectedTerr.ID;

				if game.LatestStanding.Territories[terrId].OwnerPlayerID == game.Us.ID then
					data.selectedTerr = selectedTerr;

					return true;
				else
					for terrId in pairs(selectedTerr.ConnectedTo) do
						if game.LatestStanding.Territories[terrId].OwnerPlayerID == game.Us.ID then
							data.selectedTerr = selectedTerr;

							return true;
						end
					end
				end
			end
		end;
	end

	if not data.errMsg then
		data.errMsg = 'You can only play a ' .. cardName .. ' Card on your own territories and adjacent ones';
	end

	createTerritorySelectionCard(game, tabData, cardName, btn, vert, vert2, data);
end

function playedCardRushedBlockade(wz, player, cardName, param)
	return playedTerritorySelectionCard(wz, player, cardName, param, function()
		local terrId = tonumber(param);
		local terr = wz.game.ServerGame.LatestTurnStanding.Territories[terrId];

		if terr.OwnerPlayerID ~= player.ID then
			return {};
		end

		local terrMod = WL.TerritoryModification.Create(terrId);

		terrMod.SetOwnerOpt = WL.PlayerID.Neutral;	
		terrMod.AddArmies = round(terr.NumArmies.NumArmies * getSetting(cardName .. 'Multiplier')) - terr.NumArmies.NumArmies;
		-- terrMod.SetArmiesTo = round(terr.NumArmies.NumArmies * getSetting(cardName .. 'Multiplier'));

		local eliminatingBecauseCommander = false;
		local removeSpecialUnitsOpt = {};

		for _, unit in pairs(terr.NumArmies.SpecialUnits) do
			if unit.proxyType == 'Commander' then
				eliminatingBecauseCommander = true;
			end

			table.insert(removeSpecialUnitsOpt, unit.ID);
		end

		terrMod.RemoveSpecialUnitsOpt = removeSpecialUnitsOpt;

		local mods = nil;

		if eliminatingBecauseCommander then
			mods = eliminate({player.ID}, wz.game.ServerGame.LatestTurnStanding.Territories, true, wz.game.Settings.SinglePlayer);
			table.insert(mods, terrMod);
		else
			mods = {terrMod};
		end

		return {
			terrModsOpt = mods
		}
	end);
end
