require('wastelands');

local wastelands = {};
local wastelanded = {list = {}, length = 0};
local available = {list = {}, length = 0};

function makeDistributionWastelands(game, standing)
	local numPlayers = 0;

	for _ in pairs(game.ServerGame.Game.Players) do
		numPlayers = numPlayers + 1;
	end

	local wastelandIndexes = {};
	local numTerritories = 0;

	for terrId, terr in pairs(standing.Territories) do
		numTerritories = numTerritories + 1;

		if terr.IsNeutral or (not game.Settings.AutomaticTerritoryDistribution and terr.OwnerPlayerID == WL.PlayerID.AvailableForDistribution) then
			available.length = available.length + 1;
			available.list[available.length] = terrId;
		end

		if wastelanded.length < game.Settings.NumberOfWastelands then
			if terr.IsNeutral and terr.NumArmies.NumArmies == game.Settings.WastelandSize then
				local ret = addWasteland(terrId, game.Settings.WastelandSize, wastelands, wastelanded);

				wastelands = ret.wastelands;
				wastelanded = ret.wastelanded;

				wastelandIndexes[wastelanded.length] = terrId;
				available.list[available.length] = nil;
				available.length = available.length - 1;
			end
		end
	end

	local numPickableTerrs = game.Settings.LimitDistributionTerritories;
	local maxWastelandedTerrs = numTerritories;

	if Mod.Settings.UseMaxTerrs and numPickableTerrs > 0 then
		maxWastelandedTerrs = maxWastelandedTerrs - (numPlayers * numPickableTerrs);
	else
		maxWastelandedTerrs = maxWastelandedTerrs - numPlayers;
	end

	while wastelanded.length > maxWastelandedTerrs do
		local terrId = wastelandIndexes[wastelanded.length];

		wastelands[terrId] = nil;
		wastelanded[wastelanded.length] = nil;
		wastelandIndexes[wastelanded.length] = nil;
		wastelanded.length = wastelanded.length - 1;

		if not game.Settings.AutomaticTerritoryDistribution then
			-- https://www.warzone.com/wiki/Mod_API_Reference#Newer_API_features

			if ((not game.Settings.SinglePlayer) or (game.Settings.SinglePlayer and WL and WL.isVersionOrHigher and WL.isVersionOrHigher('5.20'))) then 
				-- was a built in wasteland so change owner to available for distribution
				standing.Territories[terrId].OwnerPlayerID = WL.PlayerID.AvailableForDistribution;
			end
		end
	end

	wastelandIndexes = nil;

	while available.length + wastelanded.length > maxWastelandedTerrs do
		available.list[available.length] = nil;
		available.length = available.length - 1;
	end

	if Mod.Settings.CreateDistributionWastelandsAfterPicks and not game.Settings.AutomaticTerritoryDistribution then
		dWGenerateWastelandGroup(standing, maxWastelandedTerrs, game.Settings.NumberOfWastelands, game.Settings.WastelandSize, 0);
	end

	generateWastelands(2, function(numWastelands, size, rand)
		return dWGenerateWastelandGroup(standing, maxWastelandedTerrs, numWastelands, size, rand);
	end);

	finish(wastelands, function(terrId, size)
		placeWasteland(terrId, size, standing);
	end);
end

function placeWasteland(terrId, size, standing)
	standing.Territories[terrId].OwnerPlayerID = WL.PlayerID.Neutral;
	standing.Territories[terrId].NumArmies = WL.Armies.Create(size);
end

function dWGenerateWastelandGroup(standing, maxWastelandedTerrs, numWastelands, size, rand)
	local ret = generateWastelandGroup(
		numWastelands,
		size,
		rand,
		function(terrId, wSize)
			placeWasteland(terrId, wSize, standing);
		end,
		available,
		wastelands,
		wastelanded,
		maxWastelandedTerrs
	);

	available = ret.available;
	wastelands = ret.wastelands;
	wastelanded = ret.wastelanded;

	return ret.earlyExit;
end