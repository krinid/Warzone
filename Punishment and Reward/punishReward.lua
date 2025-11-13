--common functions called through the various hooks specific to Punishment & Reward mode

--global variables
intNumTurnsToEvaluate = 11; --track average values over 10 turns (make configurable)
rewardIncrement = 0.1;
punishmentIncrement = -0.1;
cityAverageToleranceLevel = 0.25; --quantity of cities of a territory must be within this ratio of the average of (total cities)/(total territories) to receive the city bonus
cityRewardIncrement = 0.01; --ratio of buff per city that fulfills (A) the tolerance requirement (with default tolerance% of av city/territory count) and (B) # territories with cities on them -- these are different bonuses and players collect both rewards separately
--^^ this ok for both (A) and (B) or do they need separate ratios?

strLongTermPunishmentL1 = "• 0-3 turns: no additional long term penalty";
strLongTermPunishmentL2 = "• 4-6 turns: " ..tostring (1*punishmentIncrement*100).. "% income penalty, no card pieces";
strLongTermPunishmentL3 = "• 7-9 turns: " ..tostring (2*punishmentIncrement*100).. "% income penalty, no card pieces, -10% armies on all territories, [future consideration: territories with 0 units go neutral & blockade (with added units)]";
strLongTermPunishmentL4 = "• 10+ turns: " ..tostring (3*punishmentIncrement*100).. "% income penalty, no card pieces, -20% armies on all territories, [future consideration: territories with 0 units go neutral & blockade (with added units)]";

strCityRewards1 = "• +" ..tostring (cityRewardIncrement*100).. "% for each territory you own that has at least 1 city on it";
strCityRewards2 = "• +" ..tostring (cityRewardIncrement*100).. "% for each territory you own that has a city quantity within " ..tostring (cityAverageToleranceLevel*100).. "% of your average # of cities per territory";
--^^make some of these configurable in mod

--long term punishments - # turns with no territory increase:
--	- 1-3 turns - regular 1U penalty (not defined here), no additional long term penalty
--  - 4-6 turns - regular 1U penalty (not defined here), +1U long term penalty, no card pieces
--  - 7-9 turns - regular 1U penalty (not defined here), +2U long term penalty, -10% armies on all territories & territories with 0 units go neutral & blockade (with added units)
--  - 10+ turns - regular 1U penalty (not defined here), +3U long term penalty, -20% armies on all territories, territories with 0 units go neutral & blockade (with added units)
--  to end the punishments, territory count must exceed average territory count for past 10 turns <-- maybe? for now, just go by total consecutive turns with no increases
--  idea: continue with the consecutive punishment penalties as-is, so even 1 turn of increase ends that, but apply separate penalties for TOTAL turns with no increases and only increase those when current turn exceeds the average territory count within the eval range

--given the parameter arrPlayerData of a user's stats over a period of turns, calculate the long term reward/punishment for that player
--intNumTurns indicates how many most recent turns to observe
--turnNumber is the highest populated element # of arrPlayerData
function assessLongTermPunishment (arrPlayerData, turnNumber)
	local incomeAdjustments = {};
	incomeAdjustments.LongTermPunishmentUnits = 0; --# of penalty units to apply
	incomeAdjustments.ArmyReduction = 0; --army reduction factor (0.05 for 5% reduction), applies to deployed armies on territories
	incomeAdjustments.TerritoryReduction = 0; --reduction factor (0.05 for 5% reduction), applies to owned territories to be turned neutral (with additional blockaded armies? to avoid simple reclamation)
	incomeAdjustments.ZeroArmiesGoNeutral = false; --whether or not territories with 0 armies post reduction go neutral or not
	incomeAdjustments.BlockCardPieceReceiving = false; --whether to block card receiving pieces or not

	incomeAdjustments.CurrTurn = {};
	incomeAdjustments.CurrTurn.Attacks = 0;
	incomeAdjustments.CurrTurn.Captures = 0;
	incomeAdjustments.CurrTurn.TerritoryCount = 0;
	incomeAdjustments.CurrTurn.TerritoryCountIncreased = 0;
	incomeAdjustments.CurrTurn.RewardUnits = 0;
	incomeAdjustments.CurrTurn.PunishmentUnits = 0;

	local lowestIndex = math.max (1, turnNumber - intNumTurnsToEvaluate + 1);
	local intNumConsecutiveTurnsWithNoIncrease = 0;
	local intTotalTurnsWithNoIncrease = 0;
	local intHighestTerritoryCount = 0;
	local numAverageTerritoryCount = 0;
	local intRunningTerritoryCountForAverage = 0;
	local intActualNumTurnsEvaluated = turnNumber>=intNumTurnsToEvaluate and intNumTurnsToEvaluate or turnNumber; --if more turns have passed than we're tracking, eval full value of intNumTurnsToEvaluate, else just go up to turnNumber

	local boolConsecutiveNoIncreaseStreakContinues = true;

	for k = turnNumber, lowestIndex, -1 do
		local prevValue = 0;
		local currValue = 0;

		if (k>1) then prevValue = arrPlayerData.TerritoryCount[k-1]; end
		if (prevValue == nil) then prevValue = 0; end
		currValue = arrPlayerData.TerritoryCount[k];
		if (currValue == nil) then currValue = 0; end
		if (currValue > intHighestTerritoryCount) then intHighestTerritoryCount = currValue; end --capture largest territory count in last 10 turns
		if (currValue == nil) then currValue = 0; end

		intRunningTerritoryCountForAverage = intRunningTerritoryCountForAverage + currValue;

		if (currValue <= prevValue) then
			if (boolConsecutiveNoIncreaseStreakContinues == true) then intNumConsecutiveTurnsWithNoIncrease = intNumConsecutiveTurnsWithNoIncrease + 1; end
			intTotalTurnsWithNoIncrease = intTotalTurnsWithNoIncrease + 1;
		else
			boolConsecutiveNoIncreaseStreakContinues = false; --the streak breaks
		end

		--if current element being processed is most recent turn number then process current turn stats
		if (k == turnNumber) then
			incomeAdjustments.CurrTurn = {};
			incomeAdjustments.CurrTurn.Attacks = arrPlayerData.Attacks[k]~=nil and 1 or 0;
			incomeAdjustments.CurrTurn.Captures = arrPlayerData.Captures[k]~=nil and 1 or 0;
			incomeAdjustments.CurrTurn.TerritoryCount = arrPlayerData.TerritoryCount[k];
			incomeAdjustments.CurrTurn.TerritoryCountIncreased = currValue > prevValue and 1 or 0;
			incomeAdjustments.CurrTurn.RewardUnits = incomeAdjustments.CurrTurn.Attacks + incomeAdjustments.CurrTurn.Captures + incomeAdjustments.CurrTurn.TerritoryCountIncreased;
			incomeAdjustments.CurrTurn.PunishmentUnits = 3 - (incomeAdjustments.CurrTurn.Attacks + incomeAdjustments.CurrTurn.Captures + incomeAdjustments.CurrTurn.TerritoryCountIncreased);
			-- incomeAdjustments.CurrTurn.NetIncomeAdjustment = incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement + incomeAdjustments.CurrTurn.PunishmentUnits * punishmentIncrement;
		end
	end

	numAverageTerritoryCount = intRunningTerritoryCountForAverage / intActualNumTurnsEvaluated;

	if (intNumConsecutiveTurnsWithNoIncrease == 0) then
		--no penalties, do nothing, default values are fine
	elseif (intNumConsecutiveTurnsWithNoIncrease <=3) then -- 1-3 turns - regular 1U penalty (not defined here), no additional long term penalty
		--for now, no additional penalties, just suffer the regular 1U penalty (not defined here)
	elseif (intNumConsecutiveTurnsWithNoIncrease <=6) then -- 4-6 turns - regular 1U penalty (not defined here), +1U long term penalty, no card pieces
		incomeAdjustments.LongTermPunishmentUnits = 1; --1 PU of punishment -- * punishmentIncrement;
		incomeAdjustments.BlockCardPieceReceiving = true;
	elseif (intNumConsecutiveTurnsWithNoIncrease <=9) then -- 7-9 turns - regular 1U penalty (not defined here), +2U long term penalty, -10% armies on all territories & territories with 0 units go neutral & blockade (with added units)
		incomeAdjustments.LongTermPunishmentUnits = 2; --2 PU of punishment --  * punishmentIncrement;
		incomeAdjustments.ArmyReduction = punishmentIncrement; --reduce armies by 1PU
		incomeAdjustments.ZeroArmiesGoNeutral = true;
		incomeAdjustments.BlockCardPieceReceiving = true;
	elseif (intNumConsecutiveTurnsWithNoIncrease >=10) then -- 10+ turns - regular 1U penalty (not defined here), +3U long term penalty, -20% armies on all territories, territories with 0 armies go neutral
		incomeAdjustments.LongTermPunishmentUnits = 3; --3 PU of punishment --  * punishmentIncrement;
		incomeAdjustments.ArmyReduction = 2*punishmentIncrement; --reduce armies by 2PU
		incomeAdjustments.TerritoryReduction = 0.05;
		incomeAdjustments.ZeroArmiesGoNeutral = true;
		incomeAdjustments.BlockCardPieceReceiving = true;
	end

	incomeAdjustments.NumTurnsWithNoIncrease = intTotalTurnsWithNoIncrease;
	incomeAdjustments.NumConsecutiveTurnsWithNoIncrease = intNumConsecutiveTurnsWithNoIncrease;
	incomeAdjustments.HighestTerritoryCount = intHighestTerritoryCount;
	incomeAdjustments.AverageTerritoryCount = numAverageTerritoryCount;
	incomeAdjustments.NumTurnsEvaluatedOn = intActualNumTurnsEvaluated;

	-- print ("-----NO_INCREASE #turns total " ..tostring (intTotalTurnsWithNoIncrease).. ", consecutive " ..tostring (intTotalTurnsWithNoIncrease).. ", average " ..tostring (numAverageTerritoryCount).. ", highest " ..tostring (intHighestTerritoryCount));
	-- print ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount));
	-- print ("Long-term penalty " ..incomeAdjustments.LongTermPenalty.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
	return (incomeAdjustments);
	-- publicGameData.PRdataByID[ID]
end

--calculate rewards to assign players for city bonuses
--search through table of 'territories' and generate results for players in table 'players'
function assessCityRewards (territories, players)
	local cityRewards = {};
	local territoriesWithCities = {};

	for _,terr in pairs (territories) do
		if (terr.OwnerPlayerID > 0 and players [terr.OwnerPlayerID] ~= nil) then --territory is not neutral & player is in parameter (specified 'players' table), so process this result
			--initialize object & property values if this is 1st encountering this playerID
			if (cityRewards [terr.OwnerPlayerID] == nil) then
				cityRewards [terr.OwnerPlayerID] = {};
				cityRewards [terr.OwnerPlayerID].numCities = 0;
				cityRewards [terr.OwnerPlayerID].numTerritoriesWithCities = 0;
				cityRewards [terr.OwnerPlayerID].numTerritories = 0;
				cityRewards [terr.OwnerPlayerID].aveCitiesPerTerritory = 0;
				cityRewards [terr.OwnerPlayerID].numCitiesWithinTolerance = 0;
				cityRewards [terr.OwnerPlayerID].rewardForTerritoriesWithCities = 0;
				cityRewards [terr.OwnerPlayerID].rewardForCityStacksWithinTolerance = 0;
				cityRewards [terr.OwnerPlayerID].rewardTotal = 0;
			end
			cityRewards [terr.OwnerPlayerID].numTerritories = cityRewards [terr.OwnerPlayerID].numTerritories + 1; --track #territories
			territoriesWithCities [terr.ID] = true;

			--track total #cities & #terrs that have cities on them
			if (terr.Structures and terr.Structures[WL.StructureType.City] and terr.Structures[WL.StructureType.City] > 0) then
				cityRewards [terr.OwnerPlayerID].numCities = cityRewards [terr.OwnerPlayerID].numCities + terr.Structures[WL.StructureType.City];
				cityRewards [terr.OwnerPlayerID].numTerritoriesWithCities = cityRewards [terr.OwnerPlayerID].numTerritoriesWithCities + 1;
			end
		end
		-- cityRewards [terr.OwnerPlayerID].aveCitiesPerTerritory = cityRewards[terr.OwnerPlayerID].numCities/cityRewards[terr.OwnerPlayerID].numTerritories;
	end

	-- calculate average cities per territory and store # of territories where the difference between city count & ave cities/terr is within tolerance
	for playerID, data in pairs (cityRewards) do
		if (data.numTerritories > 0) then
			-- data.aveCitiesPerTerritory = data.numCities / data.numTerritories;
			if (data.numTerritoriesWithCities == 0) then data.numTerritoriesWithCities = 0; --avoid divide by 0 (generates result of NaN, which oddly multiplied by 0 later actually still gives a result of 0 and doesn't generate an error, but better to just avoid /0)
			else data.aveCitiesPerTerritory = data.numCities / data.numTerritoriesWithCities;
			end

			local lowerBound = data.aveCitiesPerTerritory * (1 - cityAverageToleranceLevel);
			local upperBound = data.aveCitiesPerTerritory * (1 + cityAverageToleranceLevel);

			-- Count territories where city count falls within the tolerance range
			for _, terr in pairs(territories) do
				if (terr.OwnerPlayerID == playerID and terr.Structures and terr.Structures[WL.StructureType.City]) then
					local numCitiesInTerritory = terr.Structures[WL.StructureType.City];
					if (numCitiesInTerritory >= lowerBound and numCitiesInTerritory <= upperBound) then
						data.numCitiesWithinTolerance = data.numCitiesWithinTolerance + 1;
					end
				end
			end
		end
		cityRewards [playerID].rewardForTerritoriesWithCities =     cityRewardIncrement * cityRewards[playerID].numCities * cityRewards[playerID].numTerritoriesWithCities;
		cityRewards [playerID].rewardForCityStacksWithinTolerance = cityRewardIncrement * cityRewards[playerID].numCities * cityRewards[playerID].numCitiesWithinTolerance;
		cityRewards [playerID].rewardTotal = math.floor (cityRewards [playerID].rewardForTerritoriesWithCities + 0.5) + math.floor (cityRewards [playerID].rewardForCityStacksWithinTolerance + 0.5);
	end

	return (cityRewards);
	--for reference:
	-- local structures = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures;
	-- structures[WL.StructureType.Power] = structures[WL.StructureType.Power] + 1;
	-- structures[WL.StructureType.City] = Mod.Settings.NumCities * numWorkers;
	-- local structures = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures;
	-- if structures and structures[WL.StructureType.City] and structures[WL.StructureType.City] > 0 then
	-- 	local mod = WL.TerritoryModification.Create(order.TargetTerritoryID);
	-- 	mod.AddStructuresOpt = {
	-- 		[WL.StructureType.City] = -Mod.Settings.NumCities
	-- 	};
	-- 	print("test: " .. mod.AddStructuresOpt[WL.StructureType.City]);
end

--search through all territories in table 'territories' owned by playerID (if not specified, check for that SU type owned by any player), identify if an SU whose name matches strSUtypeName and was created by mod whose ID is intModID
--if both are specified, match both; if only one is specified, match whichever is specified
--when a match is found, return true; if no matches are found on all that player's territories, return false
function SUisInUse (playerID, territories, strSUtypeName, intModID)
	--if (playerID == nil) then return false; end --if playerID isn't defined, just return false
	if (strSUtypeName == nil and intModID == nil) then return false; end --if neither SU name or ModID is specified, just return false
	for _,territory in pairs (territories) do
		if (playerID == nil or territory.OwnerID == playerID) then --if no playerID is specified
			for _, specialUnit in pairs (territory.NumArmies.SpecialUnits) do
				if (specialUnit.proxyType == 'CustomSpecialUnit') then
					if (specialUnit.Name ~= nil and specialUnit.Name == strSUtypeName and intModID ~= nil and specialUnit.ModID == intModID) then return (true); end --if both strSUtypeName and intModID are specified, match them both
					if ((specialUnit.Name ~= nil and specialUnit.Name == strSUtypeName) or (intModID ~= nil and specialUnit.ModID == intModID)) then return (true); end --if only 1 of strSUtypeName or intModID are specified, match whichever one is specified
					--if required, add functionality to work for built-in units such as Commanders/Bosses/etc
				end
			end
		end
	end
	return (false);
end

function appendCommaSeparatedComponent (strText, strAppendText)
	local strReturnString = ""
	if (string.len (strText) ~= 0) then strReturnString = strText.. ", " ..strAppendText;
	else strReturnString = strAppendText;
	end
	return (strReturnString);
end