-- require("util");
-- function Server_AdvanceTurn_Start(game, addNewOrder)
-- 	print(getIncomeThreshold(game.ServerGame.Game.TurnNumber));
-- end

function Server_AdvanceTurn_End(game, addNewOrder)
	-- local intHighestIncomeAmount = 0;
	local intLowestIncomeAmount = nil;
	-- local incomeThreshold = getIncomeThreshold(game.ServerGame.Game.TurnNumber);
	local playersWithLowestIncome = {};
	-- local someoneAboveThreshold = false;

	for _, player in pairs(game.ServerGame.Game.PlayingPlayers) do
		local intPlayerIncome = player.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total;
		if (intLowestIncomeAmount == nil) then intLowestIncomeAmount = intPlayerIncome; end
		if (intPlayerIncome < intLowestIncomeAmount) then playersWithLowestIncome = {}; end
		if (intPlayerIncome <= intLowestIncomeAmount) then
			table.insert (playersWithLowestIncome, player);
			intLowestIncomeAmount = intPlayerIncome;
		end
	end

	print ("Lowest income " ..intLowestIncomeAmount..", # players " ..#playersWithLowestIncome);

	if (#playersWithLowestIncome == 1) then
		print ("ELIM " ..tostring (player.ID).. "/" ..getPlayerName (game, player.ID));
	else
		for _, player in pairs (playersWithLowestIncome) do
			-- if someoneAboveThreshold or player.Income(0, game.ServerGame.LatestTurnStanding, true, true).Total ~= highestIncome then
			print ("TIE - don't ELIM " ..tostring (player.ID).. "/" ..getPlayerName (game, player.ID));
				-- local mods = {};
				-- for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				-- 	if terr.OwnerPlayerID == player.ID then
				-- 		local mod = WL.TerritoryModification.Create (terr.ID);
				-- 		mod.SetOwnerOpt = WL.PlayerID.Neutral;
				-- 		table.insert(mods, mod);
				-- 	end
				-- end
				-- addNewOrder(WL.GameOrderEvent.Create(player.ID, player.DisplayName(nil, false) .. " was with " .. player.Income(0, game.ServerGame.LatestTurnStanding, true, true).Total .. " income below the income threshold", nil, mods));
			-- end
		end
	end
end

function getPlayerName (game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber (playerid) == WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber (playerid) < 0) then return ("fogged");
	elseif (tonumber (playerid) < 50) then return ("AI "..playerid);
	else
		for _,playerinfo in pairs (game.Game.Players) do
			if (tonumber (playerid) == tonumber (playerinfo.ID))then
				return (playerinfo.DisplayName (nil, false));
			end
		end
	end
	return "[Error - Player ID not found,playerid==]" ..tostring (playerid); --only reaches here if no player name was found but playerID >50 was provided
end