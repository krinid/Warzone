function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)
	root = rootParent;
	mainUI = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth (1);
	setMaxSize (500, 500);
	populateWindow (game, mainUI, close, Mod.PublicGameData.VoteToWin_Votes or {});
end

--return table indicating whether VTW votes are underway (1+ active players have voted), # of active players, # of VTW votes so far
function VTWvoteIsActive (game, votes)
	--count # of active players & # of votes who VTW'd (only count active players)
	local intNumPlayersTotal = 0;
	local intNumAIs = 0;
	local intNumVTWvotes = 0;
	-- local votes = Mod.PublicGameData.VoteToWin_Votes or {};
	-- if (votes == nil) then votes = Mod.PublicGameData.VoteToWin_Votes or {}; end

	for playerID,player in pairs (game.Game.PlayingPlayers) do
		if (player.IsAI == false and player.IsAIOrHumanTurnedIntoAI == false) then
			intNumPlayersTotal = intNumPlayersTotal + 1;
			if (votes [playerID] == true) then intNumVTWvotes = intNumVTWvotes + 1; print ("VTW " .. tostring (playerID)); end
		else
			intNumAIs = intNumAIs + 1;
		end
	end

	print (tostring (intNumPlayersTotal) .." active players, " ..tostring (intNumAIs).. " AIs, " ..tostring (intNumVTWvotes).. " VTW votes, VTW == " ..tostring (intNumVTWvotes >= intNumPlayersTotal));
	return { Result = (intNumVTWvotes >= intNumPlayersTotal), VoteToWinCount = intNumVTWvotes, NumPlayers = intNumPlayersTotal, NumAIs = intNumAIs };
end

function populateWindow (game, vert, close, votes)
	-- if (game.Us == nil) then return; end; --spectators can't receive VTW requests
	-- local boolVTWactive = Mod.PublicGameData.VoteToWin_ProposalActive or false;
	if (votes == nil) then votes = Mod.PublicGameData.VoteToWin_Votes or {}; end
	local boolVTWvote = votes [game.Us.ID] == true;
	local boolActivePlayer = game.Us ~= nil and game.Game.PlayingPlayers [game.Us.ID] ~= nil or false;

	local labelVTWactiveMessageHeader = UI.CreateLabel (vert);
	local labelVTWactiveMessageDetails = UI.CreateLabel (vert);
	-- 	UI.CreateLabel (vert).SetText ("Vote to Win has been activated").SetColor ("#FFFF00");
	-- 	UI.CreateLabel (vert).SetText ("\n\nIf all remaining players Vote to Win, they will all win the game and share the points awarded for winning\n\nAI players will be ignored for Vote to Win purposes, only the votes of active players are relevant, AIs will be excluded from the group of winners\n");
	-- else UI.CreateLabel (vert).SetText ("Vote to Win has not been initiated\n\nTo initiative a Vote to Win sequence, click the 'Vote to Win' button below\n");
	-- end;

	--any player can initiative a VTW proposal, and it just counts as 1 vote, doesn't matter who started it, all other players can VTW or abstain
	--as with VTE, the game will continue regardless of VTW voting states, VTW state will continue forward

	local strVoteButtonText = not boolVTWvote and "Vote to Win" or "Retract Vote to Win";
	local strVoteButtonColour = not boolVTWvote and "#198225" or "#9A2929"; --WZ green & WZ red
	if (boolActivePlayer) then UI.CreateButton(vert).SetText (strVoteButtonText).SetColor (strVoteButtonColour).SetInteractable (boolActivePlayer).SetOnClick (function() SendVote (game, not boolVTWvote, close); end); end
	-- if (boolActivePlayer) then UI.CreateButton(vert).SetText ("Vote TRUE for AIs").SetColor ("#FF7D00").SetInteractable (true).SetOnClick (function() SendVote (game, not boolVTWvote, close); end); end

	local labelActivePlayers = UI.CreateLabel (vert);
	local labelPlayersVTW = UI.CreateLabel (vert);
	local vertPlayersWhoVoted = UI.CreateVerticalLayoutGroup (vert).SetFlexibleWidth (1);
	local labelPlayerNotVTW = UI.CreateLabel (vert);
	local vertPlayersWhoHaventVoted = UI.CreateVerticalLayoutGroup (vert).SetFlexibleWidth (1);
	local intNumPlayersVoted = 0;
	local intNumPlayersNotVoted = 0;
	local intNumAIs = 0;

	for playerID,player in pairs (game.Game.PlayingPlayers) do
		-- UI.Alert (playerID.."/"..player.DisplayName (nil, false));
		-- print ("CLIENT CURRENT VALUE - " ..playerID.."/"..playerID.DisplayName (nil, false).. "/" ..tostring (votes [playerID]));
		if (player.IsAI == false and player.IsAIOrHumanTurnedIntoAI == false) then
			if (votes [playerID] == true) then
				UI.CreateLabel (vertPlayersWhoVoted).SetText ("• " ..player.DisplayName (nil, false));
				intNumPlayersVoted = intNumPlayersVoted + 1;
			else
				UI.CreateLabel (vertPlayersWhoHaventVoted).SetText ("• " ..player.DisplayName (nil, false));
				intNumPlayersNotVoted = intNumPlayersNotVoted + 1;
			end
		else
			intNumAIs = intNumAIs + 1;
		end
	end

	if (intNumPlayersVoted > 0 and boolVTWvote == false) then
		labelVTWactiveMessageHeader.SetText ("Vote to Win has been activated").SetColor ("#FFFF00");
		labelVTWactiveMessageDetails.SetText ("\nIf all active players Vote to Win, they will all win the game and share the points awarded for winning\n\nAI players will be ignored for Vote to Win purposes, only the votes of active players are relevant, AIs will be excluded from the group of winners\n");
	elseif (intNumPlayersVoted > 0 and boolVTWvote == true) then
		labelVTWactiveMessageHeader.SetText ("Vote to Win has been activated (you have Voted already)").SetColor ("#FFFFFF");
		labelVTWactiveMessageDetails.SetText ("\nIf all active players Vote to Win, they will all win the game and share the points awarded for winning\n\nAI players will be ignored for Vote to Win purposes, only the votes of active players are relevant, AIs will be excluded from the group of winners\n");
	else
		labelVTWactiveMessageHeader.SetText ("Vote to Win has not been initiated").SetColor ("#FFFFFF");
		labelVTWactiveMessageDetails.SetText ("\nTo initiative a Vote to Win sequence, click the 'Vote to Win' button below\n");
	end

	if (intNumPlayersVoted == 0) then UI.CreateLabel (vertPlayersWhoVoted).SetText ("[None]"); end
	if (intNumPlayersNotVoted == 0) then UI.CreateLabel (vertPlayersWhoHaventVoted).SetText ("[None]"); end
	labelActivePlayers.SetText ("\n" ..tostring (intNumPlayersVoted).. " active players (" ..tostring (intNumAIs).. " AIs)").SetColor ("#FFFF00");
	labelPlayersVTW.SetText ("\nPlayers who have Voted to Win: (" ..tostring (intNumPlayersVoted).. ")").SetColor ("#198225");
	labelPlayerNotVTW.SetText ("\nPlayers who have not voted: (" ..tostring (intNumPlayersNotVoted).. ")").SetColor ("#9A2929");
end

--update player's vote to boolVote
function SendVote (game, boolVote, closeOpt)
	local payload = {};
	payload.Message = 'VoteToWin';
	payload.Vote = boolVote;
	payload.PlayerID = game.Us.ID;

	-- print ("CLIENT SET VALUE - " ..game.Us.ID.. "/" ..tostring (boolVote));
	game.SendGameCustomMessage ("Sending Vote to Win response...", payload, function (returnValue)
		if (UI.IsDestroyed (mainUI) == false) then UI.Destroy (mainUI); mainUI = UI.CreateVerticalLayoutGroup (root).SetFlexibleWidth (1); end
		populateWindow (game, mainUI, closeOpt, returnValue.Votes);
	end);
end