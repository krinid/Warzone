function Server_AdvanceTurn_Start (game, addNewOrder)
	local votes = Mod.PublicGameData.VoteToWin_Votes or {};
	-- votes [playerID] = payload.Vote;
	-- print ("SERVER ACTION - SET TO: " ..playerID, tostring (payload.Vote));

	--count # of active players & # of votes who VTW'd (only count active players)
	local intNumPlayersTotal = 0
	local intNumVTWvotes = 0;
	local intNumAIs = 0;
	local playerList_Winners = {}; --these players will win the game
	local playerList_Eliminate = {}; --these players (AIs) will be eliminated
	local intTeamID = newTeamID (game);
	for playerID,player in pairs (game.Game.PlayingPlayers) do
		--ignore AIs, they don't count towards the votes and don't win the game, don't share the awarded points
		if (player.IsAI == false and player.IsAIOrHumanTurnedIntoAI == false) then
			intNumPlayersTotal = intNumPlayersTotal + 1;
			if (votes [playerID] == true) then intNumVTWvotes = intNumVTWvotes + 1; end
			playerList_Winners [playerID] = intTeamID;
		else
			intNumAIs = intNumAIs + 1;
			playerList_Eliminate [playerID] = true;
		end
	end

	-- print (tostring (intNumPlayersTotal) .." active players, " ..tostring (intNumVTWvotes).. " VTW votes, VTW == " ..tostring (intNumVTWvotes >= intNumPlayersTotal));

	--VTW criteria is met - end the game!
	if (intNumVTWvotes >= intNumPlayersTotal) then
		local terrMods = eliminatePlayers (game, playerList_Eliminate); --create terrMods table to eliminate all AIs (set their terrs to neutral)
		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "All remaining players have Voted to Win", nil, terrMods);
		event.AssignTeamOpt = playerList_Winners;
		event.Icon = "Vote to Win_Order_40x40";
		addNewOrder (event);
	end
end

function eliminatePlayers (game, playerList_Eliminate)
	local terrMods = {};
	for terrID,terr in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		if (playerList_Eliminate [terr.OwnerPlayerID] == true) then
			local terrMod = WL.TerritoryModification.Create (terrID);
			terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
			table.insert (terrMods, terrMod);
		end
	end
	return (terrMods);
end

--returns the team a player is on right now. Note that GamePlayer.Team is only the team they started the game on, so we must ask the game with the latest standing since this mod changes teams mid-game
function teamOfPlayer(game, playerID, standing)
	return game.Game.PlayerTeam (playerID, standing);
end

--return the next avaialble team ID (ie: 1 higher than the highest team ID currently in use)
function newTeamID (game)
	local NoTeam = -1; --indicates that a player is not on a team
	local highest = NoTeam;

	for _,player in pairs (game.Game.Players) do
		local team = teamOfPlayer (game, player.ID, game.ServerGame.LatestTurnStanding);
		if (team > highest) then highest = team; end;
	end

	return highest + 1;
end