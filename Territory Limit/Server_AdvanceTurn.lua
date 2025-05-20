require('UI');
function Server_AdvanceTurn_End(game, addNewOrder)
	local playerTerrs = {};

	for p, _ in pairs(game.Game.PlayingPlayers) do
		playerTerrs[p] = {};
	end

	for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if terr.OwnerPlayerID ~= WL.PlayerID.Neutral then
			-- print (terr.OwnerPlayerID.."/"..game.ServerGame.Game.Players[terr.OwnerPlayerID].DisplayName (nil, false)..", terr "..terr.ID.."/"..game.Map.Territories[terr.ID].Name..", #armies "..terr.NumArmies.NumArmies..", #SUs "..#terr.NumArmies.SpecialUnits);
			-- if #terr.NumArmies.SpecialUnits == 0 then  -- Ignore if it has special units
				local numArmies = terr.NumArmies.NumArmies
				local index = 0
				for i, terr2 in pairs(playerTerrs[terr.OwnerPlayerID]) do
					if game.ServerGame.LatestTurnStanding.Territories[terr2].NumArmies.NumArmies > numArmies then
						index = i
						break
					end
				end
				if index == 0 then
					index = #playerTerrs[terr.OwnerPlayerID] + 1
				end
				table.insert(playerTerrs[terr.OwnerPlayerID], index, terr.ID)
			-- end
		end
	end

	-- Now playerTerrs is a table with as key a PlayerID and as value a sorted array, with at index 1 the one with the most armies and the last index the terr with the least
	-- all territories included are owned by playing players (includes AIs), but no neutral territories

	--confirm that content playerTerrs is correct
	--[[for p, p2 in pairs(game.Game.PlayingPlayers) do
		print (p.."/"..game.ServerGame.Game.Players[p].DisplayName (nil, false).. ", #terrs "..#playerTerrs[p]..", limit ".. Mod.Settings.TerrLimit.. ", remove "..tostring (#playerTerrs[p] - Mod.Settings.TerrLimit));
		for k,v in pairs (playerTerrs[p]) do
			print (p.."/"..game.ServerGame.Game.Players[p].DisplayName (nil, false).. ", "..k..", "..v.."/"..game.Map.Territories[v].Name..", #armies "..game.ServerGame.LatestTurnStanding.Territories[v].NumArmies.NumArmies..", #SUs "..#game.ServerGame.LatestTurnStanding.Territories[v].NumArmies.SpecialUnits);
		end
	end]]

	for p, arr in pairs(playerTerrs) do
		local list = {};
		local t = {};
		local annotations = {};
		local numTerrsTurnedToNeutral = 0;
		local numTerrsToGoNeutral = 0;
		if (#playerTerrs[p] > Mod.Settings.TerrLimit) then numTerrsToGoNeutral = #playerTerrs[p] - Mod.Settings.TerrLimit; end
		print ("T".. tostring (game.Game.TurnNumber)..", " ..p.."/"..game.ServerGame.Game.Players[p].DisplayName (nil, false).. ", #terrs "..tostring (#playerTerrs[p])..", limit ".. tostring (Mod.Settings.TerrLimit).. ", remove "..numTerrsToGoNeutral);
		for i, v in pairs (arr) do -- = 1, #arr - Mod.Settings.TerrLimit do      -- I reversed the loop now
			local terr = game.ServerGame.LatestTurnStanding.Territories[arr[i]];

			--only turn terr neutral if (A) player still higher than the territory limit, and (B) if there are no SUs on the territory
			--NOTE: it's possible that many and possibly all territories have SUs, so that the player can't be brought within the territory limit, and this is fine, we prioritize not turning territories with SUs on them to neutral over bringing player within the territory limit
			if (numTerrsTurnedToNeutral < numTerrsToGoNeutral and #terr.NumArmies.SpecialUnits == 0) then
				numTerrsTurnedToNeutral = numTerrsTurnedToNeutral + 1;
				local mod = WL.TerritoryModification.Create(arr[i]);
				mod.SetOwnerOpt = WL.PlayerID.Neutral
				table.insert(list, mod);
				annotations [v] = WL.TerritoryAnnotation.Create ("Limit", 3, 0); --add small sized Annotation of a "Limit" in Black to indicate the territory turning to neutral
			end
		end
		if (#list > 0) then
			local event = WL.GameOrderEvent.Create(p, "Territory limit of " ..tostring (Mod.Settings.TerrLimit).. " exceeded, ".. tostring (numTerrsTurnedToNeutral).. " territories removed", {}, list);
			event.TerritoryAnnotationsOpt = annotations;
			addNewOrder(event);
		end
	end
end

function getTableLength(t)
	local a = 0;
	for i, _ in pairs(t) do

		a = a + 1;
	end
	return a;
end
