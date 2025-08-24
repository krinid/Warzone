function Server_AdvanceTurn_Start (game, addOrder)
	--move these to PublicGameData
	print ("[S_AT_S] START");
	print ("[S_AT_S] END");
end

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E] START");

	--&&& combine these 2 and just make it display Punishment or Reward based on whether it's a net buff or nerf
		local strPunishmentOrReward = "Flat income (punishment = reward)";
		-- print ("[PUNREW] ".. ID, intPunishmentIncome, intRewardIncome, tostring (intPunishmentIncome < intRewardIncome),tostring (intNetRU_PU_Change));
		if (intNetRU_PU_Change > 0) then strPunishmentOrReward = "Reward";
		elseif (intNetRU_PU_Change < 0) then strPunishmentOrReward = "Punishment";
		else strPunishmentOrReward = "Flat income (punishment = reward)";
		end

		local strOrderMsg = strPunishmentOrReward.. ": " ..(intNetRU_PU_Change>0 and "+" or "")..tostring (intNetRU_PU_Change*100).. "% income";

		addOrder (WL.GameOrderEvent.Create (ID, strOrderMsg, {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome + intRewardIncome, strPunishmentOrReward.. " (" ..tostring (intPunishmentIncome + intRewardIncome).. ")")})); --floor = round down for punishment
		-- addOrder (WL.GameOrderEvent.Create (ID, "Punishment!", {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome, "Punishment (" .. intPunishmentIncome..")")})); --floor = round down for punishment
		-- addOrder (WL.GameOrderEvent.Create (ID, "Reward!",     {}, {}, {}, {WL.IncomeMod.Create(ID, intRewardIncome,     "Reward ("     .. intRewardIncome..")")})); --ceiling = round up for reward

		--if flag to block receiving card pieces @ end of turn is set, retract the card pieces that were given (revert card pieces & wholecards to the snapshot state)
		if (incomeAdjustments.BlockCardPieceReceiving == true) then processCardRetractions (game, addOrder, ID); end
		if (incomeAdjustments.ArmyReduction ~= 0) then reduceArmyCounts (game, addOrder, ID, incomeAdjustments.ArmyReduction); end

	publicGameData.PRdataByTurn[turnNumber].TerritoryCount = historicalTerritoryCount; --store Captures for this turn; this is easily retrievable by turn#, then by playerID
	-- print ("htc count "..#historicalTerritoryCount);
	Mod.PublicGameData = publicGameData;

	--crashNow ();
	print ("[S_AT_E] END");
end

function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)

end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end