require('Utilities');
require('ServerUtilities');

function Server_GameCustomMessage (game, playerID, payload, setReturnTable)
	Server_GameCustomMessage_dabo (game, playerID, payload, setReturnTable);

	if (payload.Message == 'ProposeTeamChange') then
		ProposeTeamChange(game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'DeclineTeamChange') then
		DeclineTeamChange(game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'AcceptTeamChange') then
		AcceptTeamChange(game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'Unteam') then
		Unteam(game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'AckAlerts') then
		AckAlerts(game, playerID, payload, setReturnTable);
	else
		error("Payload message not understood (" .. tostring(payload.Message) .. ")");
	end
end

--Asks everyone named to form a team together.  Nothing happens until they've all accepted.
function ProposeTeamChange(game, playerID, payload, setReturnTable)
	local playerIDs = payload.PlayerIDs or {};

	if (not contains(playerIDs, playerID)) then
		error("You can't propose a team that you're not a part of");
	end
	--A team of just yourself is the same thing as leaving the team you're on, so send Unteam instead.
	if (count(playerIDs) < 2) then
		error("A team needs at least two players");
	end

	local seen = {};
	for _,pid in pairs(playerIDs) do
		if (seen[pid]) then
			error("The same player was named twice in the proposed team");
		end
		seen[pid] = true;

		local gp = game.Game.Players[pid];
		if (gp == nil or gp.State ~= WL.GamePlayerState.Playing) then
			error("You can't form a team with a player who isn't playing");
		end
	end

	--Everyone must be free of queued-up team changes, otherwise this proposal could never be executed.
	local conflict = FindConflict(game, playerIDs);
	if (conflict ~= nil) then
		setReturnTable({ Error = conflict });
		return;
	end

	local request = {};
	request.ID = NewGuid();
	request.ProposerID = playerID;
	request.PlayerIDs = playerIDs;
	request.Accepted = {};
	request.Accepted[playerID] = true; --proposing it counts as accepting it

	--In single-player, AIs accept immediately so that the mod can be tried out.  In multi-player we never let players name an AI in the first place, since an AI would never respond.
	if (game.Settings.SinglePlayer) then
		for _,pid in pairs(playerIDs) do
			if (game.Game.Players[pid].IsAIOrHumanTurnedIntoAI) then
				request.Accepted[pid] = true;
			end
		end
	end

	SaveRequest(request);
	WriteRequestToPlayerData(request);

	AlertPlayers(playerIDs, PlayerName(game, playerID) .. ' has proposed a team of ' .. PlayerNames(game, playerIDs) .. '.  Open the Team Switcher mod from the game menu to accept or decline it.', playerID);

	--Everyone may have accepted already if we auto-accepted for AIs above.
	if (HasAcceptedAll(request)) then
		TeamChangeAccepted(game, request, playerID);
		setReturnTable({ ID = request.ID, Complete = true });
	else
		setReturnTable({ ID = request.ID, Complete = false });
	end
end

--Turns down a proposal, which cancels it for everyone.
function DeclineTeamChange(game, playerID, payload, setReturnTable)
	local request = GetRequest(payload.ID);
	if (request == nil) then
		setReturnTable({ Error = "That team change is no longer pending" });
		return;
	end
	if (not contains(request.PlayerIDs, playerID)) then
		error("You're not a part of that team change");
	end

	DeleteRequest(request);

	AlertPlayers(request.PlayerIDs, PlayerName(game, playerID) .. ' declined the proposed team of ' .. PlayerNames(game, request.PlayerIDs) .. '.', playerID);

	setReturnTable({ Declined = true });
end

--Agrees to a proposal.  Once everyone named in it has accepted, the team change gets queued up for the turn advance.
function AcceptTeamChange(game, playerID, payload, setReturnTable)
	local request = GetRequest(payload.ID);
	if (request == nil) then
		setReturnTable({ Error = "That team change is no longer pending" });
		return;
	end
	if (not contains(request.PlayerIDs, playerID)) then
		error("You're not a part of that team change");
	end

	--Work out if we're the last one to accept before we write anything, so that we don't record an acceptance that we then can't act on.
	request.Accepted[playerID] = true;
	local complete = HasAcceptedAll(request);

	if (complete) then
		local conflict = FindConflict(game, request.PlayerIDs);
		if (conflict ~= nil) then
			setReturnTable({ Error = conflict });
			return;
		end

		TeamChangeAccepted(game, request, playerID);
	else
		SaveRequest(request);
		WriteRequestToPlayerData(request);
	end

	setReturnTable({ Complete = complete });
end

--Leaves the team you're on, without needing anyone's agreement.
function Unteam(game, playerID, payload, setReturnTable)
	local team = TeamOfPlayer(game, playerID, LatestStanding(game));
	if (team == NoTeam) then
		error("You're not on a team");
	end

	local playerIDs = { playerID };

	local conflict = FindConflict(game, playerIDs);
	if (conflict ~= nil) then
		setReturnTable({ Error = conflict });
		return;
	end

	local teammates = TeammatesOf(game, playerID, LatestStanding(game));

	RecordTeamChange(playerIDs, NoTeam);

	AlertPlayers(teammates, PlayerName(game, playerID) .. ' is leaving your team.  It takes effect when the turn advances.', playerID);

	setReturnTable({ Complete = true });
end

--Everyone in the request has agreed, so queue the team change up for the turn advance and tell everyone about it.
function TeamChangeAccepted(game, request, lastPlayerToActID)
	--Always move everyone onto a brand new team, even if some of them are already together on one.  Anyone who changes teams leaves their cards behind, and it'd be unfair and surprising if that depended on which team they happened to end up on.
	RecordTeamChange(request.PlayerIDs, NewTeamID(game));

	DeleteRequest(request);

	AlertPlayers(request.PlayerIDs, 'The team of ' .. PlayerNames(game, request.PlayerIDs) .. ' has been accepted by everyone.  It takes effect when the turn advances.', lastPlayerToActID);
end

--The client shows alerts and then tells us it's done with them so we don't show them twice.
function AckAlerts(game, playerID, payload, setReturnTable)
	local playerData = Mod.PlayerGameData;

	if (playerData[playerID] ~= nil and playerData[playerID].Alerts ~= nil) then
		--Only remove the alerts the client told us it saw, since we may have added more since it read them.
		playerData[playerID].Alerts = filter(playerData[playerID].Alerts, function(alert) return not contains(payload.AlertIDs or {}, alert.ID); end);
		Mod.PlayerGameData = playerData;
	end

	setReturnTable({ Acknowledged = true });
end

function Server_GameCustomMessage_dabo (game, playerID, payload, setReturnTable)
	publicGameData = Mod.PublicGameData;
	playerGameData = Mod.PlayerGameData;
	local rg = {};
	if(payload.Message == "Accept Allianze" or payload.Message == "Deny Allianze")then
		if(playerGameData[playerID].AllyOffers[payload.OfferedBy] == nil)then
			--offer doesn't exist any longer
			rg.Message = "The Ally offer doesn't exist, maybe you already accepted or declined it. The next time you reload the game, it shouldn't be shown there.";
			setReturnTable(rg);
		else
			playerGameData[playerID].AllyOffers[payload.OfferedBy] = nil;
			if(payload.Message == "Accept Allianze")then
			--incase both send each other a ally offer, the offer of the other player is getting deleted
				playerGameData[payload.OfferedBy].AllyOffers[playerID] = nil;
				playerGameData[playerID].Allianzen[tablelength(playerGameData[playerID].Allianzen)+1] = payload.OfferedBy;
				playerGameData[payload.OfferedBy].Allianzen[tablelength(playerGameData[payload.OfferedBy].Allianzen)+1] = playerID;
				--accept ally message
				local message = {};
				message.By = playerID;
				message.Text = " accepted the alliance with " .. toname(payload.OfferedBy,game);
				if(Mod.Settings.PublicAllies == true)then
					local newhistoryid = tablelength(publicGameData.History);
					local additionalhistorydata = {};
					additionalhistorydata.Type = "Public";
					additionalhistorydata.ID = newhistoryid;
					publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
					publicGameData.History[newhistoryid] = message;
				else
					local newhistoryid = tablelength(playerGameData[playerID].PrivateHistory);
					local additionalhistorydata = {};
					additionalhistorydata.Type = "Private";
					additionalhistorydata.ID = newhistoryid;
					additionalhistorydata.PlayerID = playerID;
					publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
					playerGameData[playerID].PrivateHistory[newhistoryid] = message;
					newhistoryid = tablelength(playerGameData[payload.OfferedBy].PrivateHistory);
					additionalhistorydata = {};
					additionalhistorydata.Type = "Private";
					additionalhistorydata.ID = newhistoryid;
					additionalhistorydata.PlayerID = payload.OfferedBy;
					publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
					playerGameData[payload.OfferedBy].PrivateHistory[newhistoryid] = message;
				end
				Mod.PublicGameData = publicGameData;
				Mod.PlayerGameData = playerGameData;
				rg.Message = "You successfuly accepted the ally offer.";
				setReturnTable(rg);
			else
				--declined ally message
				local message = {};
				message.By = playerID;
				message.Text = " declined the alliance offer of " .. toname(payload.OfferedBy,game);
				local newhistoryid = tablelength(playerGameData[playerID].PrivateHistory);
				local additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = playerID;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[playerID].PrivateHistory[newhistoryid] = message;
				newhistoryid = tablelength(playerGameData[payload.OfferedBy].PrivateHistory);
				additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = payload.OfferedBy;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[payload.OfferedBy].PrivateHistory[newhistoryid] = message;
				Mod.PublicGameData = publicGameData;
				Mod.PlayerGameData = playerGameData;
				rg.Message = "You successfuly declined the ally offer.";
				setReturnTable(rg);
			end
		end	
	end
	if(payload.Message == "Offer Allianze")then
		local target = tonumber(payload.TargetPlayerID);
		if(playerGameData[target].AllyOffers[playerID] == nil)then
			playerGameData[target].AllyOffers[playerID] = {};
			playerGameData[target].AllyOffers[playerID].OfferedBy = playerID;
			playerGameData[target].AllyOffers[playerID].OfferedInTurn = game.Game.NumberOfTurns;
			local message = {};
			message.By = playerID;
			message.Text = " offered an alliance to " .. toname(target,game);
			local newhistoryid = tablelength(playerGameData[playerID].PrivateHistory);
			local additionalhistorydata = {};
			additionalhistorydata.Type = "Private";
			additionalhistorydata.ID = newhistoryid;
			additionalhistorydata.PlayerID = playerID;
			publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
			playerGameData[playerID].PrivateHistory[newhistoryid] = message;
			newhistoryid = tablelength(playerGameData[target].PrivateHistory);
			additionalhistorydata = {};
			additionalhistorydata.Type = "Private";
			additionalhistorydata.ID = newhistoryid;
			additionalhistorydata.PlayerID = target;
			publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
			playerGameData[target].PrivateHistory[newhistoryid] = message;
			Mod.PlayerGameData = playerGameData;
			Mod.PublicGameData = publicGameData;
			rg.Message = "The Player recieved the ally offer";
			setReturnTable(rg);
		else
			rg.Message = "The Player has already a pending ally offer by you";
			setReturnTable(rg);
		end
	end
 	if(payload.Message == "Peace")then
		local player = payload.TargetPlayerID;
		if(game.ServerGame.Game.Players[player].IsAIOrHumanTurnedIntoAI == false)then
			if(playerGameData[player].Peaceoffers[playerID] ~= nil)then
				rg.Message = "The Player has already a pending peace offer by you";
				setReturnTable(rg);
			else
				playerGameData[player].Peaceoffers[playerID] = {};
				playerGameData[player].Peaceoffers[playerID].Offerby = playerID;
				local message = {};
				message.By = playerID;
				message.Text = " Offered peace to " .. toname(player,game);
				local newhistoryid = tablelength(playerGameData[playerID].PrivateHistory);
				local additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = playerID;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[playerID].PrivateHistory[newhistoryid] = message;
				newhistoryid = tablelength(playerGameData[player].PrivateHistory);
				additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = player;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[player].PrivateHistory[newhistoryid] = message;
				Mod.PublicGameData = publicGameData;
				Mod.PlayerGameData = playerGameData;
				rg.Message = "The Offer has been submitted";
				setReturnTable(rg);
			end
		else
			if(game.ServerGame.Game.Players[player].IsAI == false)then
				--since human ais can have peaceoffers, before the turn into ai, this removes the old offers
				playerGameData[playerID].Peaceoffers[player] = nil;
			end
			local message = {};
			message.By = playerID;
			message.Text = " Accepted the peace with " .. toname(player,game);
			local newhistoryid = tablelength(publicGameData.History);
			local additionalhistorydata = {};
			additionalhistorydata.Type = "Public";
			additionalhistorydata.ID = newhistoryid;
			publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
			publicGameData.History[newhistoryid] = message;
			Mod.PlayerGameData=playerGameData;
			local remainingwar = {};
			for _,with in pairs(publicGameData.War[player]) do
				if(with~=playerID)then
					remainingwar[tablelength(remainingwar)+1] = with;
				end
			end
			publicGameData.War[player] = remainingwar;
			remainingwar = {};
			for _,with in pairs(publicGameData.War[playerID]) do
				if(with~=player)then
					remainingwar[tablelength(remainingwar)+1] = with;
				end
			end
			publicGameData.War[playerID] = remainingwar;
			Mod.PublicGameData = publicGameData;
			Mod.PlayerGameData = playerGameData;
			rg.Message = 'The AI accepted your offer';
			setReturnTable(rg);
		end
	end
	if(payload.Message == "Accept Peace" or payload.Message == "Decline Peace")then
		local player = tonumber(payload.TargetPlayerID);
		if(playerGameData[playerID].Peaceoffers[player] == nil)then
			rg.Message = "The Peace Offer doesn't exist, maybe you already accepted or declined it. The next time you reload the game, it shouldn't be shown there.";
			setReturnTable(rg);
		else
			if(payload.Message == "Accept Peace")then
				local remainingwar = {};
				publicGameData = Mod.PublicGameData;
				for _,with in pairs(publicGameData.War[player]) do
					if(with~=playerID)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[player] = remainingwar;
				remainingwar = {};
				for _,with in pairs(publicGameData.War[playerID]) do
					if(with~=player)then
						remainingwar[tablelength(remainingwar)+1] = with;
					end
				end
				publicGameData.War[playerID] = remainingwar;
				local message = {};
				message.By = playerID;
				message.Text = " Accepted the peace with " .. toname(player,game);
				local newhistoryid = tablelength(publicGameData.History);
				local additionalhistorydata = {};
				additionalhistorydata.Type = "Public";
				additionalhistorydata.ID = newhistoryid;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				publicGameData.History[newhistoryid] = message;
				playerGameData[playerID].Peaceoffers[player] = nil
				playerGameData[player].Peaceoffers[playerID] = nil
				Mod.PublicGameData = publicGameData;
				Mod.PlayerGameData = playerGameData;
				rg.Message = "The Peace Offer has been accepted.";
				setReturnTable(rg);
			else
				local message = {};
				message.By = playerID;
				message.Text = " Declined the peace with " .. toname(player,game);
				local newhistoryid = tablelength(playerGameData[playerID].PrivateHistory);
				local additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = playerID;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[playerID].PrivateHistory[newhistoryid] = message;
				local newhistoryid = tablelength(playerGameData[player].PrivateHistory);
				local additionalhistorydata = {};
				additionalhistorydata.Type = "Private";
				additionalhistorydata.ID = newhistoryid;
				additionalhistorydata.PlayerID = player;
				publicGameData.Historyorder[tablelength(publicGameData.Historyorder)] = additionalhistorydata;
				playerGameData[player].PrivateHistory[newhistoryid] = message;
				playerGameData[playerID].Peaceoffers[player] = nil
				Mod.PublicGameData = publicGameData;
				Mod.PlayerGameData = playerGameData;
				rg.Message = "The Peace Offer has been declined.";
				setReturnTable(rg);
			end
		end
	end
end
function toname(playerid,game)
	return game.ServerGame.Game.Players[playerid].DisplayName(nil, false);
end
function tablelength(T)
	local count = 0;
	for _,elem in pairs(T)do
		count = count + 1;
	end
	return count;
end
function GetOffer(offertype,spieler1,spieler2,terr)
	if(offertype ~= nil)then
		if(offertype[spieler1] ~= nil)then
			if(offertype[spieler1][spieler2] ~= nil)then
				if(terr ~= nil)then
					if(offertype[spieler1][spieler2][terr] ~= nil)then
						return offertype[spieler1][spieler2][terr];
					end
				else
					return offertype[spieler1][spieler2];
				end
			end
		end
	end
	return nil;
end
