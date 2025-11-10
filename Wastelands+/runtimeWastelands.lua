require('wastelands');

local wastelands = {};
local wastelanded = {list = {}, length = 0};
local available = {list = {}, length = 0};
local tMods = {
	byIndex = {},
	byId = {},
	length = 0
};

tMods.add = function(terrId, mod)
	if tMods.byId[terrId] then
		tMods.byIndex[tMods.byId[terrId]] = mod;
	else
		tMods.length = tMods.length + 1;
		tMods.byIndex[tMods.length] = mod;
		tMods.byId[terrId] = tMods.length;
	end
end

function makeRuntimeWastelands(game, addNewOrder)
	if Mod.Settings.TreatAllNeutralsAsWastelands and Mod.Settings.OverlapMode == 2 then
		-- takes no effect, prevents the territory loop
		return;
	end

	for terrId, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if terr.IsNeutral then
			available.length = available.length + 1;
			available.list[available.length] = terrId;

			if Mod.PublicGameData.wastelands[terrId] or Mod.Settings.TreatAllNeutralsAsWastelands then
				local ret = addWasteland(terrId, terr.NumArmies.NumArmies, wastelands, wastelanded);

				wastelands = ret.wastelands;
				wastelanded = ret.wastelanded;

				available.list[available.length] = nil;
				available.length = available.length - 1;
			end
		end
	end

	generateWastelands(1, function(numWastelands, size, rand)
		return rWGenerateWastelandGroup(game, numWastelands, size, rand);
	end);

	finish(wastelands, function(terrId, size)
		placeWasteland(terrId, size, game);
	end);

	addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, 'Made runtime wastelands', {}, tMods.byIndex));
end

function placeWasteland(terrId, size, game)
	-- standing doesnt get updated correctly on server end if multiple mods change it
	-- territory might not even be neutral if another mod sets ownership of territories
	-- try to give approximate armies needed

	local actualArmies = game.ServerGame.LatestTurnStanding.Territories[terrId].NumArmies.NumArmies;
	local armiesToAdd = 0;

	if size ~= actualArmies then
		local armiesToAdd = -(actualArmies - size);

		-- actualArmies = 5, size = 2
		-- armiesToAdd = -(5 - 2)
		-- armiesToAdd = -(3)

		-- actualArmies = 2, size = 5
		-- armiesToAdd = -(2 - 5)
		-- armiesToAdd = -(-3)
		-- armiesToAdd = 3

		local terrMod = WL.TerritoryModification.Create(terrId);

		terrMod.AddArmies = armiesToAdd;
		-- terrMod.SetArmiesTo = size;
		tMods.add(terrId, terrMod);
	end
end

function rWGenerateWastelandGroup(game, numWastelands, size, rand)
	local ret = generateWastelandGroup(
		numWastelands,
		size,
		rand,
		function(terrId, wSize)
			placeWasteland(terrId, wSize, game);
		end,
		available,
		wastelands,
		wastelanded
	);

	available = ret.available;
	wastelands = ret.wastelands;
	wastelanded = ret.wastelanded;

	return ret.earlyExit;
end