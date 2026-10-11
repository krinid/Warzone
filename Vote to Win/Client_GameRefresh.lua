local boolVTWpendingMessageDisplayed = false;

function Client_GameRefresh (game)
	if (game.Us == nil) then return; end --spectators don't get VTW messages
	local boolVTWstatus = VTWvoteIsActive_refresh (game);
	local boolVTWvote = Mod.PublicGameData.VoteToWin_Votes and Mod.PublicGameData.VoteToWin_Votes [game.Us.ID] or false;

	--popup message to local user if VTW is active, inform them how to Vote and what it means
	if (boolVTWstatus.Result == true and boolVTWvote == false and boolVTWpendingMessageDisplayed == false) then
		UI.Alert ("Vote to Win has activated - if all remaining players agree, the game will end\n\nClick Game/Vote to Win to cast your vote");
		boolVTWpendingMessageDisplayed = true; --don't show again until page is reloaded
	end
end

--return table indicating whether VTW votes are underway (1+ active players have voted), # of active players, # of VTW votes so far
function VTWvoteIsActive_refresh (game)
	--count # of active players & # of votes who VTW'd (only count active players)
	local intNumPlayersTotal = 0
	local intNumAIs = 0
	local intNumVTWvotes = 0;
	local votes = Mod.PublicGameData.VoteToWin_Votes or {};

	for playerID,player in pairs (game.Game.PlayingPlayers) do
		if (player.IsAI == false and player.IsAIOrHumanTurnedIntoAI == false) then
			intNumPlayersTotal = intNumPlayersTotal + 1;
			if (votes [playerID] == true) then intNumVTWvotes = intNumVTWvotes + 1; end
		else
			intNumAIs = intNumAIs + 1;
		end
	end

	-- print (tostring (intNumPlayersTotal) .." active players, " ..tostring (intNumVTWvotes).. " VTW votes, VTW == " ..tostring (intNumVTWvotes >= intNumPlayersTotal));
	return { Result = (intNumVTWvotes >= intNumPlayersTotal), VoteToWinCount = intNumVTWvotes, NumPlayers = intNumPlayersTotal, NumAIs = intNumAIs };
end