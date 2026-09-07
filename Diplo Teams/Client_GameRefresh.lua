require ("utilities");

--Alerts we've already told the server about, so that we don't show them twice while we wait for it to reply.
AcknowledgedAlertIDs = {};
local intTurnNumberOfLastAlertDisplay; --indicates whether an alert for new wars has been displayed already in the current turn or not; this will reset when the local client page/app reloads and thus will send another reminder each time but won't pester the player every refresh cycle
--this handles the case where on Turn X a war alert was displayed, Turn advances to X+1 and a new war alert should be issued while the client hasn't reloaded the page/app

function Client_GameRefresh (game)
	if (game.Us == nil) then return; end --can't use game.SendGameCustomMessage as a spectator.
	-- if (Mod.PlayerGameData == nil or Mod.PlayerGameData.PeaceOffers == nil or Mod.PublicGameData == nil or Mod.PublicGameData.War == nil) then return; end --GameRefresh gets called before the game starts, and 'Mod' isn't writable at that stage, so avoid processing anything until StartGame finishes running properly

	--if there are pending Peace Offers or new War Declarations, send an Alert to the local client
	local strMessage = nil;

	if (tablelength (Mod.PlayerGameData.PeaceOffers) >0) then strMessage = 'You have ' .. tablelength (Mod.PlayerGameData.PeaceOffers) .. ' new Peace Offers (NAP)'; intTurnNumberOfLastAlertDisplay = nil; end

	if (intTurnNumberOfLastAlertDisplay ~= nil and intTurnNumberOfLastAlertDisplay >= game.Game.TurnNumber) then return; end --if alert has been displayed already, don't pester the local player

	if (Mod.PlayerGameData.HasNewWar == true) then
		if (strMessage ~= nil) then strMessage = strMessage .. "\n\n"; end
		strMessage = strMessage or "" .. "!! WAR !!\nYou are involved in a new WAR\n\nCheck the Diplo Teams information by clicking Game/Diplo Teams";
		-- local playerGameData = Mod.PlayerGameData;
		-- playerGameData.HasNewWar = false;
		-- Mod.PlayerGameData = playerGameData;  --  <--- can't write to 'Mod' here
	end
	if (strMessage ~= nil) then
		intTurnNumberOfLastAlertDisplay = game.Game.TurnNumber; --suppress further War alerts this turn unless client reloads
		if (true) then
			UI.Alert (strMessage);
			-- game.CreateDialog (CreateProposeDialog); end); -- <-- use this to create dialog using a new function as the receiver for the UI
		else
			--this works but it creates 2 windows - why? Getting called twice w/o clearing Mod.PlayerGameData.HasNewWar?
			--use this to define a nameless function inline to handle the dialog
			game.CreateDialog (
				function (rootParent, setMaxSize, setScrollable, game, close)
					setMaxSize (600, 300);
					UI.CreateLabel (rootParent).SetText ("NEW WAR DECLARATIONS or PEACE OFFERS").SetColor ("#00AAFF");
					UI.CreateLabel (rootParent).SetText (strMessage);
					strMessage = nil;
				end
			);
		end

		-- local payload = {};
		-- payload.Message = "SendAlert";
		-- payload.AlertContent = strMessage;
		-- payload.playerIDs = {Mod.Us.ID};
		-- Game.SendGameCustomMessage ("Sending alert...", payload, function (returnvalue)
		-- 			showedreturnmessage = false;
		-- 			UI.Alert (returnvalue.Message);
		-- 			end);

	end

	local alerts = filter (Mod.PlayerGameData.Alerts or {}, function (alert) return AcknowledgedAlertIDs [alert.ID] ~= true; end);
	if (count (alerts) == 0) then
		return;
	end

	local message = table.concat (map (alerts, function (alert) return alert.Message; end), '\n\n');

	local payload = {};
	payload.Message = 'AckAlerts';
	payload.AlertIDs = map (alerts, function (alert) return alert.ID; end);

	for _,alert in pairs (alerts) do
		AcknowledgedAlertIDs [alert.ID] = true;
	end

	--Let the server know we've seen these so it can delete them. Wait on showing them until it replies, just to avoid two things appearing on the screen at once.
	game.SendGameCustomMessage ('Read receipt...', payload, function (returnValue)
		UI.Alert (message);
	end);
end