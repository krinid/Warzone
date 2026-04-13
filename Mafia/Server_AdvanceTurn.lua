-- function Server_AdvanceTurn_Start (game, addNewOrder)
-- end

function Server_AdvanceTurn_End (game, addNewOrder)
	local publicGameData = Mod.PublicGameData;
	local intEliminationStartTurn = Mod.Settings.EliminationStartTurn or 2;
	local intEliminationTurnFrequency = Mod.Settings.EliminationTurnFrequency or 5;
	local intNumEliminationsExecuted = publicGameData.NumEliminationsExecuted or 0;
	local intNumEliminationsRequired = math.floor ((game.Game.TurnNumber - intEliminationStartTurn) / intEliminationTurnFrequency) + (game.Game.TurnNumber >= intEliminationStartTurn and 1 or 0);

	local intLowestIncomeAmount = nil;
	local playersWithLowestIncome = {};
	local boolEliminationExecutedThisTurn = false;

	for _, player in pairs (game.ServerGame.Game.PlayingPlayers) do
		local intPlayerIncome = player.Income (0, game.ServerGame.LatestTurnStanding, true, true).Total; --get income ignoring reinf cards, army cap and sanctions
		if (intLowestIncomeAmount == nil) then intLowestIncomeAmount = intPlayerIncome; end
		if (intPlayerIncome < intLowestIncomeAmount) then playersWithLowestIncome = {}; end
		if (intPlayerIncome <= intLowestIncomeAmount) then
			table.insert (playersWithLowestIncome, player);
			intLowestIncomeAmount = intPlayerIncome;
		end
	end

	local intNumPendingEliminationsForThisTurn = intNumEliminationsRequired - intNumEliminationsExecuted;
	print ("[START] ELIMs done " ..tostring (intNumEliminationsExecuted).. ", ELIMs todo TOTAL " ..tostring (intNumEliminationsRequired).. ", ELIMs todo THIS TURN " ..tostring (intNumPendingEliminationsForThisTurn).. ", Lowest income " ..intLowestIncomeAmount..", # players " ..#playersWithLowestIncome ..", # playing players " ..#game.ServerGame.Game.PlayingPlayers);

	--if an elimination is due, find the lowest income player & elim them; if tied for lowest income, don't elim anyone & reevaluate next turn
	if (intNumPendingEliminationsForThisTurn > 0) then
		-- local boolEliminationDeferred = false;

		for k, player in pairs (playersWithLowestIncome) do
			-- if (#playersWithLowestIncome == 1) then
			-- 	--a single player is @ lowest income, eliminate that player
			-- 	print ("ELIM [SINGLE] " ..tostring (playersWithLowestIncome[1].ID).. "/" ..getPlayerName (game, playersWithLowestIncome[1].ID));
			-- 	intNumEliminationsExecuted = intNumEliminationsExecuted + 1;
			-- 	eliminatePlayer (game, addNewOrder, playersWithLowestIncome[1]);
			if (#playersWithLowestIncome <= intNumPendingEliminationsForThisTurn and #playersWithLowestIncome < #game.ServerGame.Game.PlayingPlayers) then
				--eliminate all the players with the lowest income, unless that would eliminate all remaining players, in which case don't eliminate anyone and proceed until the tie is broken
				-- for _, playerToEliminate in pairs (playersWithLowestIncome) do
					-- print ("ELIM [MULTIPLE] " ..tostring (playerToEliminate.ID).. "/" ..getPlayerName (game, playerToEliminate.ID));
					print ("ELIM " ..tostring (playersWithLowestIncome[k].ID).. "/" ..getPlayerName (game, playersWithLowestIncome[k].ID));
					intNumEliminationsExecuted = intNumEliminationsExecuted + 1;
					boolEliminationExecutedThisTurn = true;
					eliminatePlayer (game, addNewOrder, playersWithLowestIncome[k]);
					-- intNumEliminationsExecuted = intNumEliminationsExecuted + 1;
					-- eliminatePlayer (game, addNewOrder, playerToEliminate);
				-- end
			else
				--multiple players are tied, don't eliminate anyone, advance turn and eliminate when 1 player drops to lowest spot with no ties
				print ("TIE - don't ELIM " ..tostring (player.ID).. "/" ..getPlayerName (game, player.ID));
				-- boolEliminationDeferred = true;
			end
		end

		--if after processing elims for this round, if there are still elims pending for future turns, add a game message to notify players
		if (intNumEliminationsRequired > intNumEliminationsExecuted) then
			local intNumPendingEliminations = intNumEliminationsRequired - intNumEliminationsExecuted;
			local strMessage = tostring (intNumPendingEliminations > 1 and intNumPendingEliminations or "") .. tostring (intNumPendingEliminations > 1 and " " or "") .. "Mafia elimination" ..tostring (intNumPendingEliminations > 1 and "s" or "").. " pending" ..  tostring (boolEliminationExecutedThisTurn == false and " (" ..tonumber (#playersWithLowestIncome).. " players tied for lowest income)" or "");
			addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, strMessage));
		end
	end

	publicGameData.NumEliminationsExecuted = intNumEliminationsExecuted;
	Mod.PublicGameData = publicGameData;
	-- if (intNumEliminationsRequired > intNumEliminationsExecuted) then
	-- 	addNewOrder (WL.GameOrderEvent.Create (WL.Player.Neutral, "Mafia elimination pending next "));
	-- end
	print ("[END] ELIMs done " ..tostring (intNumEliminationsExecuted).. ", ELIMs todo " ..tostring (intNumEliminationsRequired).. ", Lowest income " ..intLowestIncomeAmount..", # players " ..#playersWithLowestIncome);
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

function eliminatePlayer (game, addNewOrder, player)
	local territoryModifications = {};

	for _, terr in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		if (terr.OwnerPlayerID == player.ID) then
			local terrMod = WL.TerritoryModification.Create (terr.ID);
			terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
			table.insert(territoryModifications, terrMod);
		end
	end
	addNewOrder (WL.GameOrderEvent.Create (player.ID, "Mafia elimination of ".. player.DisplayName (nil, false), nil, territoryModifications));
end