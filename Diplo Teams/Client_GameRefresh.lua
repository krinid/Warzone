require('History'); --dabo

require('Utilities');

--Alerts we've already told the server about, so that we don't show them twice while we wait for it to reply.
AcknowledgedAlertIDs = {};

function Client_GameRefresh(game)
	Client_GameRefresh_dabo (game);

	--Skip if we're not in the game.  We can't use game.SendGameCustomMessage as a spectator.
	if (game.Us == nil) then
		return;
	end

	local alerts = filter(Mod.PlayerGameData.Alerts or {}, function(alert) return AcknowledgedAlertIDs[alert.ID] ~= true; end);
	if (count(alerts) == 0) then
		return;
	end

	local message = table.concat(map(alerts, function(alert) return alert.Message; end), '\n\n');

	local payload = {};
	payload.Message = 'AckAlerts';
	payload.AlertIDs = map(alerts, function(alert) return alert.ID; end);

	for _,alert in pairs(alerts) do
		AcknowledgedAlertIDs[alert.ID] = true;
	end

	--Let the server know we've seen these so it can delete them.  Wait on showing them until it replies, just to avoid two things appearing on the screen at once.
	game.SendGameCustomMessage('Read receipt...', payload, function(returnValue)
		UI.Alert(message);
	end);
end

function Client_GameRefresh_dabo (game)
	if(game.Us == nil)then
		return;
	end
	--It appears that gamerefresh gets called before startgame, so this filters out a crash
	if(Mod.PlayerGameData.Peaceoffers == nil)then
		return;
	end
	if(Mod.PublicGameData.War[game.Us.ID] ==nil)then
		UI.Alert("I identified a problem with the data structure of this mod. This could be based on the device you are running(it is a normal bug for some devices that run the standalone client). Try using a different device. If the bug consists, please contact the author of this mod(go to mod info and click the github link).");
		return;
	end
	if(lastnachricht == nil)then
		lastnachricht = "";
	end
	local Nachricht = "";
    	if(tablelength(Mod.PlayerGameData.Peaceoffers)>0)then
    		Nachricht = Nachricht .. "\n" .. 'You have ' .. tablelength(Mod.PlayerGameData.Peaceoffers) .. ' open peace offer';
   	end
   	if(tablelength(Mod.PlayerGameData.AllyOffers)>0)then
     		Nachricht = Nachricht .. "\n" .. 'You have ' .. tablelength(Mod.PlayerGameData.AllyOffers) .. ' open ally offer';
  	end
	if(Mod.PlayerGameData.HasNewWar == true)then
		Nachricht = Nachricht .. "\n" .. 'You seem to be in war with a new player. Please check out the diplomacy overview in the mod menu or check the bottom of the history of the last turn to find out with who. This means you can already attack each other in this turn.';
	end
	ShowAllHistory(game,Nachricht);
end
function tablelength(T)
	if(T==nil)then
		return "error";
	end
	local count = 0;
	for _,elem in pairs(T)do
		count = count + 1;
	end
	return count;
end
