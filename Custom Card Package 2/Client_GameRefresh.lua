require('tblprint');

function Client_GameRefresh(game)
	if not (game.Us and game.Us.State == WL.GamePlayerState.Playing) then
		return;
	end

	local playerGD = Mod.PlayerGameData;

	if not playerGD.prefShowReceivedCardsMsg then
		return;
	end

	if playerGD.prefShowReceivedCardsMsg and playerGD.shownReceivedCardsMsg then
		return;
	end

	UI.Alert('You' .. (game.Us.Team == -1 and ' have' or 'r team has') .. ' some full card pieces. Go to Game > Mod: Custom Card Package 2 to use them.');
	game.SendGameCustomMessage('Acknowledging received cards message viewed...', {
		PlayerGameData = {
			shownReceivedCardsMsg = true
		}
	}, function() end);
end