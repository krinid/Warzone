-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/eliminate

function eliminate(playerIds, territories, removeSpecialUnits, isSinglePlayer)
	-- https://www.warzone.com/wiki/Mod_API_Reference:TerritoryModification RemoveSpecialUnitsOpt 5.22
	-- there are times when special units are not on the same territory as who owns the territory
	-- eliminating a player should always remove all their special units, regardless of which territory they are on
	-- if special units can be removed

	local mods = {};
	local canRemoveSpecialUnits = removeSpecialUnits and ((not isSinglePlayer) or (isSinglePlayer and WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher('5.22')));

	for tId, territory in pairs(territories) do
		local mod = nil;
		local specialUnitsToRemove = {};

		for _, playerId in ipairs(playerIds) do
			if territory.OwnerPlayerID == playerId then
				if not mod then
					mod = WL.TerritoryModification.Create(territory.ID);
				end

				mod.SetOwnerOpt = WL.PlayerID.Neutral;

				if not canRemoveSpecialUnits then
					break;
				end
			end

			if canRemoveSpecialUnits then
				for _, su in pairs(territory.NumArmies.SpecialUnits) do
					if su.OwnerID == playerId then
						if not mod then
							mod = WL.TerritoryModification.Create(territory.ID);
						end

						table.insert(specialUnitsToRemove, su.ID);
					end
				end
			end
		end

		if mod then
			if #specialUnitsToRemove > 0 then
				mod.RemoveSpecialUnitsOpt = specialUnitsToRemove;
			end

			table.insert(mods, mod);
		end
	end

	return mods;
end
