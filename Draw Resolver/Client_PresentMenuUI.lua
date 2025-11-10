require('tblprint');
require('ui');
require('version');

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	local playerIsPlaying = (game.Us ~= nil) and (game.Us.State == WL.GamePlayerState.Playing);
	local distributionOver = game.Game.TurnNumber > 0;

	if not playerIsPlaying or not distributionOver then
		return;
	end

	if not canRunMod() then
		return;
	end

	local WIDTH = 400;
	local HEIGHT = 250;

	setMaxSize(WIDTH, HEIGHT);

	local vert = Vert(rootParent);
	local uiElements = {
		vert = vert
	};

	makeMenu(game, uiElements, Mod.PublicGameData.votes);
end

function makeMenu(game, uiElements, votes)
	local container = Vert(uiElements.vert);
	local vtdContainer = Vert(container);
	local vtdBtn = Btn(vtdContainer);
	local votesList = Vert(vtdContainer);
	local votesContainer = Vert(container);

	local hasVoted = votes[game.Us.ID];

	if hasVoted then
		vtdBtn.SetText('Un-vote to decide a random winner');
		vtdBtn.SetOnClick(function()
			UI.Destroy(container);
			game.SendGameCustomMessage('Un-voting...', {vote = false}, function(votes)
				makeMenu(game, uiElements, votes);
			end);
		end);
	else
		vtdBtn.SetText('Vote to decided a random winner');
		vtdBtn.SetOnClick(function()
			UI.Destroy(container);
			game.SendGameCustomMessage('Voting...', {vote = true}, function(votes)
				makeMenu(game, uiElements, votes);
			end);
		end);
	end

	Label(votesContainer).SetText('The following players have voted to decide a random winner:');

	for playerId, voted in pairs(votes) do
		local player = game.Game.Players[playerId];

		if player.State == WL.GamePlayerState.Playing and (votes[playerId] or player.IsAIOrHumanTurnedIntoAI) then
			Label(votesContainer).SetText(player.DisplayName(nil, true));
		end
	end
end