function Server_GameCustomMessage (game, playerID, payload, setReturnTable)
	-- print ("SERVER MESSAGE - SET TO: " ..tostring (payload.Message).. "/" ..tostring (payload.Message=="VoteToWin"));
	if (payload.Message == 'VoteToWin') then
		UpdateVote (game, playerID, payload, setReturnTable);
	else
		error("Payload message not valid (" .. tostring(payload.Message) .. ")");
	end
end

--Update vote of playerID to payload.Vote; if all players have Voted to Win, end the game
function UpdateVote (game, playerID, payload, setReturnTable)
	local votes = Mod.PublicGameData.VoteToWin_Votes or {};
	votes [playerID] = payload.Vote;
	-- print ("SERVER ACTION - SET TO: " ..playerID, tostring (payload.Vote));

	--FOR TESTING ONLY: force all AIs to vote true or false
	-- for k,v in pairs (game.Game.PlayingPlayers) do if (v.IsAI == true or v.IsAIOrHumanTurnedIntoAI == true) then votes [k] = true; end end

	local publicGameData = Mod.PublicGameData;
	publicGameData.VoteToWin_Votes = votes;
	Mod.PublicGameData = publicGameData;

	--always return a table to the client
	setReturnTable ({ Votes = votes });
end