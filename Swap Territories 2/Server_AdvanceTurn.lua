require('settings');
require('tblprint');
require('version');

local executed = false;
local payload = 'SwapTerritories2_ServerAdvanceTurnEnd';

local swapSpecialUnits = nil;
local playerOwnedTerritories = {};
local specialUnitDetails = {};
--[[
	terrId = {
		unit = SpecialUnit,
		terrId = terrId,
		canBeSwapped = bool
	}
]]

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if order.proxyType == 'GameOrderCustom' and order.Payload == payload then
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		if not executed then
			main(game, addNewOrder);
			executed = true;
		end
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	addNewOrder(WL.GameOrderCustom.Create(getFirstPlayer(game), '', payload));
end

function getFirstPlayer(game)
	-- neutral isn't allowed for game order custom
	for playerId in pairs(game.ServerGame.Game.Players) do
		return playerId;
	end
end

function main(game, addNewOrder)
	if not serverCanRunMod(game) then
		return;
	end

	local pgd = Mod.PublicGameData;

	if pgd.lastSwappedOn and (pgd.lastSwappedOn + getSetting('SwapFreq') ~= game.ServerGame.Game.TurnNumber) then
		return;
	end

	swapSpecialUnits = getSetting('SpecialUnitSwappingEnabled');

	local terrIdsForSpecialUnitDetails = {};
	local chanceOfSwapping = (getSetting('ChanceOfSwapping') or 100) / 100;

	for tId, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if not terr.IsNeutral then
			if not playerOwnedTerritories[terr.OwnerPlayerID] then
				playerOwnedTerritories[terr.OwnerPlayerID] = {};
			end

			local numSpecialUnits = #terr.NumArmies.SpecialUnits;
			local canSwap = math.random() < chanceOfSwapping;

			if canSwap and numSpecialUnits == 0 and isSwappable(terr) then
				table.insert(playerOwnedTerritories[terr.OwnerPlayerID], tId);
			elseif swapSpecialUnits and numSpecialUnits > 0 then
				table.insert(playerOwnedTerritories[terr.OwnerPlayerID], tId);

				-- 0 armies stand guard required to create special units
				if game.Settings.OneArmyStandsGuard then
					table.remove(playerOwnedTerritories[terr.OwnerPlayerID]);
				else
					specialUnitDetails[tId] = {};
					table.insert(terrIdsForSpecialUnitDetails, tId);

					for _, unit in pairs(terr.NumArmies.SpecialUnits) do
						local obj = {
							unit = unit,
							terrId = tId,
							canBeSwapped = canSwap and getSetting('Swap' .. unit.proxyType) and isSwappable(terr)
						};

						table.insert(specialUnitDetails[tId], obj);
					end
				end
			end
		end
	end

	print('specialUnitDetails0 =');
	tblprint(specialUnitDetails);

	local swapList = decideSwaps(game);

	-- if swap with has a special unit that can't be swapped, mark it and all other units on the territory its on
	local i = 0;
	while i < #terrIdsForSpecialUnitDetails do
		i = i + 1;

		local tId = terrIdsForSpecialUnitDetails[i];
		local markAllInTerr = false;
		local j = 0;
		local traceback = false;

		while j < #specialUnitDetails[tId] do
			j = j + 1;

			local obj = specialUnitDetails[tId][j];

			if markAllInTerr then
				specialUnitDetails[tId][j].canBeSwapped = false;

				local unitType1 = getUnitType(obj.unit);
				local p1 = obj.unit.OwnerID;
				local p2 = swapList[p1];
				local broken = false;

				for terrId in pairs(specialUnitDetails) do
					for k, obj2 in pairs(specialUnitDetails[terrId]) do
						local unitType2 = getUnitType(obj2.unit);

						if obj2.canBeSwapped and obj2.unit.OwnerID == p2 and unitType1 == unitType2 then
							specialUnitDetails[terrId][k].canBeSwapped = false;
							broken = true;
							traceback = true;
							break;
						end
					end

					if broken then
						break;
					end
				end
			elseif not obj.canBeSwapped then
				markAllInTerr = true;
				j = 0;
			end
		end

		if traceback then
			i = 0;
		end
	end

	print('specialUnitDetails1 =');
	tblprint(specialUnitDetails);

	addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, 'Swap territories!', {}, doSwaps(game, swapList)));

	pgd.lastSwappedOn = game.ServerGame.Game.TurnNumber;
	Mod.PublicGameData = pgd;
end

function isSwappable(terr)
	local swapSpecialUnits = getSetting('SpecialUnitSwappingEnabled');
	local swapStructs = getSetting('StructureSwappingEnabled');

	if not swapSpecialUnits and #terr.NumArmies.SpecialUnits > 0 then
		return false;
	end

	if not swapStructs and terr.Structures then
		return false;
	end

	if swapStructs and terr.Structures then
		for structType in pairs(terr.Structures) do
			if not structCanBeSwapped(structType) then
				return false;
			end
		end
	end

	return true;
end

function structCanBeSwapped(structType)
	local map = {
        [WL.StructureType.City] = 'City',
        [WL.StructureType.ArmyCamp] = 'ArmyCamp',
        [WL.StructureType.Mine] = 'Mine',
        [WL.StructureType.Smelter] = 'Smelter',
        [WL.StructureType.Crafter] = 'Crafter',
        [WL.StructureType.Market] = 'Market',
        [WL.StructureType.ArmyCache] = 'ArmyCache',
        [WL.StructureType.MoneyCache] = 'MoneyCache',
        [WL.StructureType.ResourceCache] = 'ResourceCache',
        [WL.StructureType.MercenaryCamp] = 'MercenaryCamp',
        [WL.StructureType.Power] = 'Power',
        [WL.StructureType.Draft] = 'Draft',
        [WL.StructureType.Arena] = 'Arena',
        [WL.StructureType.Hospital] = 'Hospital',
        [WL.StructureType.DigSite] = 'DigSite',
        [WL.StructureType.Attack] = 'Attack',
        [WL.StructureType.Mortar] = 'Mortar',
        [WL.StructureType.Recipe] = 'Recipe'
    };

	return getSetting('Swap' .. map[structType]);
end

function getUnitType(unit)
	local unitType = unit.proxyType;-- Commander, CustomSpecialUnit
	if unitType == 'CustomSpecialUnit' then
		unitType = (unit.ModID or '') .. '_' .. unit.ImageFilename;
	end

	return unitType;
end

function doSwaps(game, swaps)
	print('init doSwaps');

	local mods = {};

	for pId, playerTerrs in pairs(playerOwnedTerritories) do
		if swaps[pId] ~= pId then
			for _, tId in pairs(playerTerrs) do
				local mod = nil;-- if not set to nil then there's a bug which doesnt make sense
				-- print('tId = ');
				-- print(tId);

				if specialUnitDetails[tId] then
					-- print('special units on this territory');
					-- all units on same territory have same canBeSwapped flag
					if specialUnitDetails[tId][1].canBeSwapped then
						-- print('can be swapped');
						mod = WL.TerritoryModification.Create(tId);
						mod.SetOwnerOpt = swaps[pId];

						local specialUnitsToRemove = {};
						local specialUnitsToAdd = {};

						for _, obj in pairs(specialUnitDetails[tId]) do
							-- print('obj = ');
							-- tblprint(obj);
							table.insert(specialUnitsToRemove, obj.unit.ID);

							local clone = cloneSpecialUnit(obj.unit, swaps[pId]);
							table.insert(specialUnitsToAdd, clone);
						end

						mod.RemoveSpecialUnitsOpt = specialUnitsToRemove;
						mod.AddSpecialUnits = specialUnitsToAdd;
					else
						-- print('cant be swapped');
					end
				else
					mod = WL.TerritoryModification.Create(tId);
					mod.SetOwnerOpt = swaps[pId];
				end

				-- print('mod = ');
				-- tblprint(mod);

				if mod then
					table.insert(mods, mod);
				end
			end
		end
	end
	-- print('mods = ');
	-- tblprint(mods);

	return mods;
end

function decideSwaps(game)
	-- only random swaps for now
	local players = {};
	for pId in pairs(game.ServerGame.Game.PlayingPlayers) do
		table.insert(players, pId);
	end

	local swaps = {};
	while true do
		if not players[1] then
			break;
		end

		local x = math.random(#players);
		local xId = players[x];
		table.remove(players, x);

		if not players[1] then
			swaps[xId] = xId;
			break;
		end

		local y = math.random(#players);
		local yId = players[y];
		table.remove(players, y);

		swaps[yId] = xId;
		swaps[xId] = yId;
	end

	print('swaps = ');
	tblprint(swaps);
	return swaps;
end

function cloneSpecialUnit(unit, unitOwner)
	if unit.proxyType == 'CustomSpecialUnit' then
		local builder = WL.CustomSpecialUnitBuilder.CreateCopy(unit);
		builder.OwnerID = unitOwner;
		return builder.Build();
	else
		return WL[unit.proxyType].Create(unitOwner);
	end
end
