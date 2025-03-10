require("utilities");

function Client_GameRefresh(clientGame)
	print ("[CLIENT] refresh START - - - - - - - - - - ");
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiative this function
	checkForPendingPestilence (clientGame, false); --false indicates to not forcibly show the popup warning; only do it if it's 1st turn this time or appropriate time has elapsed since last display
	print ("[CLIENT] refresh END - - - - - - - - - - ");
	end

function checkForPendingPestilence (clientGame, boolForceWarningDisplay)
	--pestilence_lastPlayerWarning variable is used to track warning popups for the local client player, to avoid spamming warnings with every Refresh event
	--^^don't define as local; leave it as global so the value persists for a given client session instead of resetting to nil each time the function executes

	if (Mod.Settings.ActiveModules.Pestilence ~= true) then return; end --if Pestilence isn't active for this mod, do nothing, just return

	local pestilence_WarningFrequency = 5; --measured in seconds; send a new warning at this frequency

	--check if the current client user has any pending Pestilences
	--PrintProxyInfo (Mod.PublicGameData.PestilenceData, "a", "b");
	if (clientGame.Us ~= nil) then --can't check if client doesn't have an associated playerID (ie: isn't an active player, could be a spectator)
		local targetPlayerID = clientGame.Us.ID; --target player is the current player using the client
		local isPlayerActive = clientGame.Us.State == WL.GamePlayerState.Playing;
		local hasCommittedOrders = clientGame.Us.HasCommittedOrders;

		--[[print ("(not next(Mod.PublicGameData))=="..tostring (not next(Mod.PublicGameData)));
		print ("(Mod.PublicGameData==nil)=="..tostring (Mod.PublicGameData==nil));
		print ("(not next(Mod.PublicGameData.PestilenceData))=="..tostring (not next(Mod.PublicGameData.PestilenceData)));
		print ("(clientGame == nil)=="..tostring (clientGame == nil));]]
		if (not next(Mod.PublicGameData)) then print ("[CLIENT] Mod.PublicGameData == nil; can't check Pestilence"); return; end
		--if (not next(Mod.PublicGameData.PestilenceData)) then print ("[CLIENT] Mod.PublicGameData.PestilenceData == nil; can't check Pestilence or no Pestilence operations are pending"); return; end
		--this function gets called early on, possibly before many game variables are set up, namely initialization of Mod.PublicGameData & Mod.PublicGameData.PestilenceData, in which case just exit the function b/c can't do anything w/o those constructs
		--actually I believe this is a game bug; it seems to erase Mod.PublicGameData when a mod update is pushed while a game is running

		print ("[CLIENT] checking if client player has pending Pestilence: "..targetPlayerID .."/"..toPlayerName (targetPlayerID, clientGame)..", isPlayerActive==" ..tostring(isPlayerActive) .."::");

		--check if client player has pending Pestilence records and is an active player (ie: don't popup a Pestilence warning if the player is eliminated, this probably means they had a pending Pestilence order at time of elimination and will be continually harassed about it if they peruse the game)
		--don't show popup if player has already committed regardless of time since last warning popup (don't nag player post Commit)
		if (Mod.PublicGameData.PestilenceData[targetPlayerID] ~= nil and isPlayerActive==true and hasCommittedOrders==false) then
			local pestilenceDataRecord = Mod.PublicGameData.PestilenceData[targetPlayerID]; --get pestilence record for local client player

			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
			--local pestilenceDataRecord = {castingPlayer=1,targetPlayer=1058239,PestilenceWarningTurn=clientGame.Game.TurnNumber, PestilenceStartTurn=clientGame.Game.TurnNumber+1, PestilenceEndTurn=clientGame.Game.TurnNumber+2};
			--for reference: PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.PlayerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};
			--krinid userID=1058239
			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
			
			local castingPlayerID = pestilenceDataRecord.castingPlayer;
			local castingPlayerName = toPlayerName (castingPlayerID, clientGame);
			local PestilenceWarningTurn = pestilenceDataRecord.PestilenceWarningTurn; --for now, make PestilenceWarningTurn = current turn +1 turn from now (next turn)
			local PestilenceStartTurn = pestilenceDataRecord.PestilenceStartTurn;   --for now, make PestilenceStartTurn = current turn +2 turns from now 
			local PestilenceEndTurn = pestilenceDataRecord.PestilenceEndTurn;     --for now, make PestilenceEndTurn = current turn +2 turns from now (starts and ends on same turn, only impacts a player once)
			local turnNumber = tonumber (clientGame.Game.TurnNumber);

			local currentTime = clientGame.Game.ServerTime;
			local pestilence_nextPlayerWarning = nil;
			if (pestilence_lastPlayerWarning == nil) then
				pestilence_nextPlayerWarning = currentTime; --if hasn't been a previous warning, setup the time to send one asap
			else
				pestilence_nextPlayerWarning = tableToDate(addTime(dateToTable(pestilence_lastPlayerWarning), "Minutes", pestilence_WarningFrequency));
				--pestilence_nextPlayerWarning = tableToDate(addTime(dateToTable(pestilence_lastPlayerWarning), "Seconds", 15));
			end


			--print ("LAST WARNING DISPLAY: "..tostring (pestilence_lastPlayerWarning) ..", CURRENT TIME: "..currentTime..", dateIsEarlier==");--..dateIsEarlier(dateToTable(Mod.PlayerGameData.LastMessage), dateToTable(game.Game.ServerTime)).."::");
			--print ("LAST WARNING DISPLAY: "..tostring (pestilence_lastPlayerWarning) ..", NEXT WARNING DISPLAY: ".. tostring (pestilence_nextPlayerWarning) ..", CURRENT TIME: "..currentTime..", dateIsEarlier=="..tostring (dateIsEarlier(dateToTable(pestilence_lastPlayerWarning), dateToTable(currentTime))).."::");
			print ("LAST WARNING DISPLAY: "..tostring (pestilence_lastPlayerWarning));
			print ("NEXT WARNING DISPLAY: "..tostring (pestilence_nextPlayerWarning));
			print ("CURRENT TIME:         "..currentTime..", dateIsEarlier=="..tostring (dateIsEarlier(dateToTable(pestilence_nextPlayerWarning), dateToTable(currentTime))).."::");

			--there is a pending pestilence for the local client player; display a warning in any of these cases:
			--(A) boolForceWarningDisplay is set to true (1st press on Commit button during a turn)
			--(B) if player hasn't been warned yet
			--(C) if the minimum time to wait before next warning has elapsed
			if ((pestilence_lastPlayerWarning == nil) or (boolForceWarningDisplay==true) or (dateIsEarlier(dateToTable(pestilence_nextPlayerWarning), dateToTable(currentTime)))) then
				pestilence_lastPlayerWarning = currentTime;  --track time the warning is displayed to the client player

				--print ("[PESTILENCE PENDING] on player "..tostring(targetPlayerID)..", by "..tostring(castingPlayerID)..", damage=="..Mod.Settings.PestilenceStrength .."::warningTurn=="..PestilenceWarningTurn..", startTurn==".. PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");
				print ("[PESTILENCE PENDING] on player "..targetPlayerID.."/"..toPlayerName(targetPlayerID, clientGame)..", by "..castingPlayerID.."/"..toPlayerName(castingPlayerID, clientGame)..", damage=="..Mod.Settings.PestilenceStrength ..", currTurn=="..turnNumber..", warningTurn=="..PestilenceWarningTurn..", startTurn=="..PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");

				--if current turn is the Pestilence start turn, make it happen
				print ("currTurn=="..turnNumber..", startTurn=="..PestilenceStartTurn..", (PestilenceStartTurn >= turnNumber)", tostring (PestilenceStartTurn >= turnNumber));
				if (turnNumber >= PestilenceWarningTurn) then
					print ("[PESTILENCE EXECUTE START] on player "..targetPlayerID.."/"..toPlayerName(targetPlayerID, clientGame)..", by "..castingPlayerID.."/"..toPlayerName(castingPlayerID, clientGame)..", damage=="..Mod.Settings.PestilenceStrength ..", currTurn=="..turnNumber..", "..PestilenceWarningTurn..", startTurn=="..PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");

					--fields are Pestilence|playerID target|player ID caster|turn# Pestilence warning|turn# Pestilence begins|turn# Pestilence ends
					--publicGameData.PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.playerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};

					local strPlural_units = "";
					local strPlural_duration = "";

					if (Mod.Settings.PestilenceDuration > 1) then strPlural_duration = "s"; end
					if (Mod.Settings.PestilenceStrength > 1) then strPlural_units = "s"; end

					local strPestilenceMessage = "!! PESTILENCE ALERT !!\n\nA player ("..castingPlayerName..") has invoked Pestilence on you. Each of your territorities will sustain ".. Mod.Settings.PestilenceStrength.." unit"..strPlural_units.." of damage for " .. Mod.Settings.PestilenceDuration .. " turn"..strPlural_duration.."."..
					"\n\nIf a territory is reduced to 0 armies, it will turn neutral.\n\nSpecial units are not affected by Pestilence, and will prevent a territory from turning to neutral." ..
					"\n\n[Pestilence details]\nDuration: "..Mod.Settings.PestilenceDuration.."\nStrength: " ..Mod.Settings.PestilenceStrength.."\nWarning turn: "..PestilenceWarningTurn.."\nStart turn: "..PestilenceStartTurn.."\nEnd turn: "..PestilenceEndTurn.."\nInvoked by: "..castingPlayerName

					--print ("[CLIENT ALERT] "..strPestilenceMessage)
					UI.Alert (strPestilenceMessage);
				end
			end
			return true; --return True to indicate that there is a pending Pestilence order for the local client player
		else
			print ("[CLIENT] no pending Pestilences for "..targetPlayerID .."/".. toPlayerName (targetPlayerID, clientGame));
			return false; --return False to indicate that there are no pending Pestilence order for the local client player
		end
	else
		print ("[CLIENT] can't acquire Client player object clilentGame.Us.ID");
		return nil; --indicate inability to decipher whether a pending Pestilence order exists or not; this could happen for non-Active players, spectators of the game, etc
	end
end