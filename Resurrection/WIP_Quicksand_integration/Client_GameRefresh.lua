function Client_GameRefresh(clientGame)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiative this function
    print ("[GAME REFRESH START]");
    popupWarning_toPlayResurrectionCard (clientGame, false); --false indicates to not forcibly show the popup warning; only do it if it's 1st turn this time or appropriate time has elapsed since last display
    print ("[GAME REFRESH END]");
end

function popupWarning_toPlayResurrectionCard (clientGame, boolForceWarningDisplay)
	--'Resurrection_lastPlayerWarning' variable is used to track warning popups for the local client player, to avoid spamming warnings with every Refresh event
	--^^don't define as local; leave it as global so the value persists for a given client session instead of resetting to nil each time the function executes

	local Resurrection_WarningFrequency = 5; --measured in seconds; send a new warning at this frequency

	--check if the current client user has any pending Resurrections
	print ("[CLIENT] refresh started - - - - - - - - - - ");
	if (clientGame.Us ~= nil) then --can't check if client doesn't have an associated playerID (ie: isn't an active player, could be a spectator)
		local targetPlayerID = clientGame.Us.ID; --target player is the current player using the client
		local isPlayerActive = clientGame.Us.State == WL.GamePlayerState.Playing;
		local hasCommittedOrders = clientGame.Us.HasCommittedOrders;

		if (not next(Mod.PublicGameData)) then print ("[CLIENT] Mod.PublicGameData == nil; can't check Resurrection"); return; end
		--if (not next(Mod.PublicGameData.ResurrectionData)) then print ("[CLIENT] Mod.PublicGameData.ResurrectionData == nil; can't check Resurrection or no Resurrection operations are pending"); return; end
		--this function gets called early on, possibly before many game variables are set up, namely initialization of Mod.PublicGameData & Mod.PublicGameData.ResurrectionData, in which case just exit the function b/c can't do anything w/o those constructs
		--actually I believe this is a game bug; it seems to erase Mod.PublicGameData when a mod update is pushed while a game is running

        local strPlayerName = clientGame.Us.DisplayName(nil, false);
		print ("[CLIENT] checking if client player has pending Resurrection: "..targetPlayerID .."/"..strPlayerName..", isPlayerActive==" ..tostring(isPlayerActive) .."::");

		--check if client player has a pending Resurrection and is an active player (ie: don't popup a Resurrection warning if the player is eliminated, this probably means they had a pending Resurrection order at time of elimination and will be continually harassed about it if they peruse the game)
		--don't show popup if player has already committed regardless of time since last warning popup (don't nag player post Commit)
		if (Mod.PublicGameData.ResurrectionData[targetPlayerID] ~= nil and isPlayerActive==true and hasCommittedOrders==false) then
			--there is a Resurrection pending, so popup a message

			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
			--local ResurrectionDataRecord = {castingPlayer=1,targetPlayer=1058239,ResurrectionWarningTurn=clientGame.Game.TurnNumber, ResurrectionStartTurn=clientGame.Game.TurnNumber+1, ResurrectionEndTurn=clientGame.Game.TurnNumber+2};
			--for reference: ResurrectionData [ResurrectionTarget_playerID] = {targetPlayer=ResurrectionTarget_playerID, castingPlayer=gameOrder.PlayerID, ResurrectionWarningTurn=ResurrectionWarningTurn, ResurrectionStartTurn=ResurrectionStartTurn, ResurrectionEndTurn=ResurrectionEndTurn};
			--krinid userID=1058239
			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
			
			local currentTime = clientGame.Game.ServerTime;
			local Resurrection_nextPlayerWarning = nil;
			if (Resurrection_lastPlayerWarning == nil) then
				Resurrection_nextPlayerWarning = currentTime; --if hasn't been a previous warning, setup the time to send one asap
			else
				Resurrection_nextPlayerWarning = tableToDate(addTime(dateToTable(Resurrection_lastPlayerWarning), "Minutes", Resurrection_WarningFrequency));
			end

			print ("LAST WARNING DISPLAY: "..tostring (Resurrection_lastPlayerWarning));
			print ("NEXT WARNING DISPLAY: "..tostring (Resurrection_nextPlayerWarning));
			print ("CURRENT TIME:         "..currentTime..", dateIsEarlier=="..tostring (dateIsEarlier(dateToTable(Resurrection_nextPlayerWarning), dateToTable(currentTime))).."::");

			--there is a pending Resurrection for the local client player; display a warning in any of these cases:
			--(A) boolForceWarningDisplay is set to true (1st press on Commit button during a turn)
			--(B) if player hasn't been warned yet
			--(C) if the minimum time to wait before next warning has elapsed
			if ((Resurrection_lastPlayerWarning == nil) or (boolForceWarningDisplay==true) or (dateIsEarlier(dateToTable(Resurrection_nextPlayerWarning), dateToTable(currentTime)))) then
				Resurrection_lastPlayerWarning = currentTime;  --track time the warning is displayed to the client player
				print ("[Resurrection PENDING] on player "..targetPlayerID.."/"..strPlayerName .."::");

                local strResurrectionMessage = "!! Resurrection ALERT !!\n\nYour Commander has died, so you must play your Resurrection card to resurrect your Commander to a territory of your choice.\n\nIf you don't play your card, your Commander will be resurrected to a random territory that you possess.";
                UI.Alert (strResurrectionMessage);
			end
			return true; --return True to indicate that there is a pending Resurrection order for the local client player
		else
			print ("[CLIENT] no pending Resurrections for "..targetPlayerID .."/".. strPlayerName);
			return false; --return False to indicate that there are no pending Resurrection order for the local client player
		end
	else
		print ("[CLIENT] can't acquire Client player object clilentGame.Us.ID");
		return nil; --indicate inability to decipher whether a pending Resurrection order exists or not; this could happen for non-Active players, spectators of the game, etc
	end
end

function dateIsEarlier(date1, date2)
	local list = getDateIndexList();
	for _, v in pairs(list) do
		if v == "MiliSeconds" then return false; end
		if date1[v] ~= date2[v] then
			if date1[v] < date2[v] then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end

function getDateIndexList() return {"Year", "Month", "Day", "Hours", "Minutes", "Seconds", "MiliSeconds"}; end

function getDateRestraints() return {99999999, 12, 30, 24, 60, 60, 1000} end;

function dateToTable(s)
	local list = getDateIndexList();
	local r = {};
	local i = 1;
	local buffer = "";
	local index = 1;
	while i <= string.len(s) do
		local c = string.sub(s, i, i);
		if c == "-" or c == " " or c == ":" then
			r[list[index]] = tonumber(buffer);
			buffer = "";
			index = index + 1;
		else
			buffer = buffer .. c;
		end
		i = i + 1;
	end
	r[list[index]] = tonumber(buffer);
	return r;
end

function tableToDate(t)
	return t.Year .. "-" .. addZeros("Month", t.Month) .. "-" .. addZeros("Day", t.Day) .. " " .. addZeros("Hours", t.Hours) .. ":" .. addZeros("Minutes", t.Minutes) .. ":" .. addZeros("Seconds", t.Seconds) .. ":" .. addZeros("MiliSeconds", t.MiliSeconds);
end

function addTime(t, field, i)
	local dateIndex = getDateIndexList();
	local restraint = getDateRestraints()[getTableKey(dateIndex, field)];
	t[field] = t[field] + i;
	if t[field] > restraint then
		t[field] = t[field] - restraint;
		addTime(t, dateIndex[getTableKey(dateIndex, field) - 1], 1);
	end
	return t;
end

function getTableKey(t, value)
	for i, v in pairs(t) do
		if value == v then return i; end
	end
end

function addZeros(field, i)
	if field == "MiliSeconds" then
		if i < 10 then
			return "00" .. i;
		elseif i < 100 then
			return "0" .. i;
		end
	else
		if i < 10 then
			return "0" .. i;
		end
	end
	return i;
end