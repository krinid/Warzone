require("utilities");

function Client_GameRefresh(clientGame)
  --check if the current client user has any pending Pestilences
  print ("[CLIENT] refresh started");
  --PrintProxyInfo (Mod.PublicGameData.PestilenceData, "a", "b");
  if (clientGame.Us ~= nil) then --can't check if client doesn't have an associated playerID
      local targetPlayerID = clientGame.Us.ID; --target player is the current player using the client

      -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
      --targetPlayerID = 1; --simulate being targeted by Pestilence since can't test this w/o actually being on, and AIs can't/won't do it
      -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 

      print ("(not next(Mod.PublicGameData))=="..tostring (not next(Mod.PublicGameData)));
      print ("(Mod.PublicGameData==nil)=="..tostring (Mod.PublicGameData==nil));
      print ("(not next(Mod.PublicGameData.PestilenceData))=="..tostring (not next(Mod.PublicGameData.PestilenceData)));
      print ("(clientGame == nil)=="..tostring (clientGame == nil));
      if (not next(Mod.PublicGameData)) then print ("[CLIENT] Mod.PublicGameData == nil; can't check Pestilence"); return; end
      if (not next(Mod.PublicGameData.PestilenceData)) then print ("[CLIENT] Mod.PublicGameData.PestilenceData == nil; can't check Pestilence or no Pestilence operations are pending"); return; end
      --this function gets called early on, possibly before many game variables are set up, namely initialization of Mod.PublicGameData & Mod.PublicGameData.PestilenceData, in which case just exit the function b/c can't do anything w/o those constructs
      --actually I believe this is a game bug; it seems to erase Mod.PublicGameData when a mod update is pushed while a game is running

      print ("[CLIENT] checking if client player has pending Pestilence: "..targetPlayerID .."/"..toPlayerName (targetPlayerID, clientGame).."::");

      --if (next (Mod.PublicGameData.PestilenceData[targetPlayerID])) then

      --check if client player has pending Pestilence records
      if (Mod.PublicGameData.PestilenceData[targetPlayerID] ~= nil) then
      --if (next (Mod.PublicGameData.PestilenceData[targetPlayerID])) then
          local pestilenceDataRecord = Mod.PublicGameData.PestilenceData[targetPlayerID];
          local castingPlayerID = pestilenceDataRecord.castingPlayer;
          local castingPlayerName = toPlayerName (castingPlayerID, clientGame);
          local PestilenceWarningTurn = pestilenceDataRecord.PestilenceWarningTurn; --for now, make PestilenceWarningTurn = current turn +1 turn from now (next turn)
          local PestilenceStartTurn = pestilenceDataRecord.PestilenceStartTurn;   --for now, make PestilenceStartTurn = current turn +2 turns from now 
          local PestilenceEndTurn = pestilenceDataRecord.PestilenceEndTurn;     --for now, make PestilenceEndTurn = current turn +2 turns from now (starts and ends on same turn, only impacts a player once)
          local turnNumber = tonumber (clientGame.Game.TurnNumber);

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

              local strPestilenceMessage = "!! PESTILENCE ALERT !!\n\nA player has invoked Pestilence on you. Each of your territorities will sustain ".. Mod.Settings.PestilenceStrength.." unit"..strPlural_units.." of damage for " .. Mod.Settings.PestilenceDuration .. " turn"..strPlural_duration.."."..
              "\n\nIf a territory is reduced to 0 armies, it will turn neutral.\n\nSpecial units are not affected by Pestilence, and will prevent a territory from turning to neutral." ..
              "\n\nPestilence details:\nDuration: "..Mod.Settings.PestilenceDuration.."\nStrength: " ..Mod.Settings.PestilenceStrength.."\nWarning turn: "..PestilenceWarningTurn.."\nStart turn: "..PestilenceStartTurn.."\nEnd turn: "..PestilenceEndTurn.."\nInvoked by: "..castingPlayerName
              
              print ("[CLIENT ALERT] "..strPestilenceMessage)
              UI.Alert (strPestilenceMessage);
          end
      else
          print ("[CLIENT] no pending Pestilences for "..targetPlayerID .."/".. toPlayerName (targetPlayerID, clientGame));
      end
  else
      print ("[CLIENT] can't acquire Client player object clilentGame.Us.ID");
  end
end