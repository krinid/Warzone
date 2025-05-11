--common functions called through the various hooks specific to Punishment & Reward mode

--global variables
intNumTurnsToEvaluate = 11; --track average values over 10 turns (make configurable)
rewardIncrement = 0.1;
punishmentIncrement = -0.1;
--^^make some of these configurable in mod

--long term punishments - # turns with no territory increase:
--	- 1-3 turns - regular 1U penalty (not defined here), no additional long term penalty
--  - 4-6 turns - regular 1U penalty (not defined here), +1U long term penalty, no card pieces
--  - 7-9 turns - regular 1U penalty (not defined here), +2U long term penalty, -5% armies on all territories & territories with 0 units go neutral & blockade (with added units)
--  - 10+ turns - regular 1U penalty (not defined here), +3U long term penalty, -10% armies on all territories, territories with 0 units go neutral & blockade (with added units)
--  to end the punishments, territory count must exceed average territory count for past 10 turns <-- maybe? for now, just go by total consecutive turns with no increases
--  idea: continue with the consecutive punishment penalties as-is, so even 1 turn of increase ends that, but apply separate penalties for TOTAL turns with no increases and only increase those when current turn exceeds the average territory count within the eval range

--given the parameter arrPlayerData of a user's stats over a period of turns, calculate the long term reward/punishment for that player
--intNumTurns indicates how many most recent turns to observe
--currentTurnNumber is the highest populated element # of arrPlayerData
function assessLongTermPunishment (arrPlayerData, currentTurnNumber)
	local incomeAdjustments = {};
	incomeAdjustments.LongTermPenalty = 0; --# of penalty units to apply
	incomeAdjustments.ArmyReduction = 0; --army reduction factor (0.05 for 5% reduction), applies to deployed armies on territories
	incomeAdjustments.TerritoryReduction = 0; --reduction factor (0.05 for 5% reduction), applies to owned territories to be turned neutral (with additional blockaded armies? to avoid simple reclamation)
	incomeAdjustments.ZeroArmiesGoNeutral = false; --whether or not territories with 0 armies post reduction go neutral or not
	incomeAdjustments.BlockCardPieceReceiving = false; --whether to block card receiving pieces or not

	local lowestIndex = math.max (1, currentTurnNumber - intNumTurnsToEvaluate - 1);
	local intNumConsecutiveTurnsWithNoIncrease = 0;
	local intTotalTurnsWithNoIncrease = 0;
	local intHighestTerritoryCount = 0;
	local numAverageTerritoryCount = 0;
	local intRunningTerritoryCountForAverage = 0;
	local intActualNumTurnsEvaluated = currentTurnNumber>=intNumTurnsToEvaluate and intNumTurnsToEvaluate or currentTurnNumber; --if more turns have passed than we're tracking, eval full value of intNumTurnsToEvaluate, else just go up to currentTurnNumber

	local boolConsecutiveNoIncreaseStreakContinues = true;

	for k = currentTurnNumber, lowestIndex, -1 do
		local prevValue = 0;
		local currValue = 0;

		if (k>1) then prevValue = arrPlayerData.TerritoryCount[k-1]; end
		if (prevValue == nil) then prevValue = 0; end
		currValue = arrPlayerData.TerritoryCount[k];
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
		if (k == currentTurnNumber) then
			incomeAdjustments.CurrTurn = {};
			incomeAdjustments.CurrTurn.Attacks = arrPlayerData.Attacks[k]~=nil and 1 or 0;
			incomeAdjustments.CurrTurn.Captures = arrPlayerData.Captures[k]~=nil and 1 or 0;
			incomeAdjustments.CurrTurn.TerritoryCount = arrPlayerData.TerritoryCount[k];
			incomeAdjustments.CurrTurn.TerritoryCountIncreased = currValue > prevValue and 1 or 0;
			incomeAdjustments.CurrTurn.RewardUnits = incomeAdjustments.CurrTurn.Attacks + incomeAdjustments.CurrTurn.Captures + incomeAdjustments.CurrTurn.TerritoryCountIncreased;
			incomeAdjustments.CurrTurn.PunishmentUnits = 3 - (incomeAdjustments.CurrTurn.Attacks + incomeAdjustments.CurrTurn.Captures + incomeAdjustments.CurrTurn.TerritoryCountIncreased);
		end
	end

	numAverageTerritoryCount = intRunningTerritoryCountForAverage / intActualNumTurnsEvaluated;

	if (intNumConsecutiveTurnsWithNoIncrease == 0) then
		--no penalties, do nothing, default values are fine
	elseif (intNumConsecutiveTurnsWithNoIncrease <=3) then -- 1-3 turns - regular 1U penalty (not defined here), no additional long term penalty
		--for now, no additional penalties, just suffer the regular 1U penalty (not defined here)
	elseif (intNumConsecutiveTurnsWithNoIncrease <=6) then -- 4-6 turns - regular 1U penalty (not defined here), +1U long term penalty, no card pieces
		incomeAdjustments.LongTermPenalty = 1;
		incomeAdjustments.BlockCardPieceReceiving = true;
	elseif (intNumConsecutiveTurnsWithNoIncrease <=9) then -- 7-9 turns - regular 1U penalty (not defined here), +2U long term penalty, -5% armies on all territories & territories with 0 units go neutral & blockade (with added units)
		incomeAdjustments.LongTermPenalty = 2;
		incomeAdjustments.ArmyReduction = 0.05;
		incomeAdjustments.ZeroArmiesGoNeutral = true;
		incomeAdjustments.BlockCardPieceReceiving = true;
	elseif (intNumConsecutiveTurnsWithNoIncrease >=10) then -- 10+ turns - regular 1U penalty (not defined here), +3U long term penalty, -10% armies on all territories, territories with 0 armies go neutral
		incomeAdjustments.LongTermPenalty = 3;
		incomeAdjustments.ArmyReduction = 0.1;
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