require 'distributionWastelands'

function Server_StartDistribution(game, standing)
	if Mod.Settings.CreateDistributionWastelandsAfterPicks then
		clearWastelands(game, standing);
	else
		makeDistributionWastelands(game, standing);
	end
end

function clearWastelands(game, standing)
	local numWastelands = game.Settings.NumberOfWastelands;

	if numWastelands < 1 then
		return;
	end

	-- checking if should be pickable would be slow for non-full dist, esp. for bonuses with lots of territories and overlapping bonuses
	local distMode = game.Settings.DistributionModeID;
	local isFullDist = distMode == 0;
	local size = game.Settings.InitialNonDistributionArmies;-- this is usually correct

	local wastelandCount = 0;

	for terrId, terr in pairs(standing.Territories) do
		if wastelandCount == numWastelands then
			break;
		end

		if terr.IsNeutral and terr.NumArmies.NumArmies == game.Settings.WastelandSize then
			wastelandCount = wastelandCount + 1;

			if isFullDist then
				standing.Territories[terrId].OwnerPlayerID = WL.PlayerID.AvailableForDistribution;
			else
				standing.Territories[terrId].NumArmies = WL.Armies.Create(size);
			end
		end
	end
end