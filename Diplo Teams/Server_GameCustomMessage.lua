require ('utilities');
require ('serverUtilities');

function Server_GameCustomMessage (game, playerID, payload, setReturnTable)
	process_WarPeaceChanges (game, playerID, payload, setReturnTable);
	process_TeamChanges (game, playerID, payload, setReturnTable);
end

function process_TeamChanges (game, playerID, payload, setReturnTable)
	if (payload.Message == 'ProposeTeamChange') then
		ProposeTeamChange (game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'DeclineTeamChange') then
		DeclineTeamChange (game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'AcceptTeamChange') then
		AcceptTeamChange (game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'Unteam') then
		Unteam (game, playerID, payload, setReturnTable);
	elseif (payload.Message == 'AckAlerts') then
		AckAlerts (game, playerID, payload, setReturnTable);
	-- elseif (payload.Message == 'SendAlert') then
	-- 	AlertPlayers (payload.playerIDs, payload.AlertContent); --send payload.message to all users in player.playerIDs
	end
end

--Asks everyone named to form a team together.  Nothing happens until they've all accepted.
function ProposeTeamChange (game, playerID, payload, setReturnTable)
	local playerIDs = payload.PlayerIDs or {};

	if (not contains (playerIDs, playerID)) then
		error ("You can't propose a team that you're not a part of");
	end
	--A team of just yourself is the same thing as leaving the team you're on, so send Unteam instead.
	if (count (playerIDs) < 2) then
		error ("A team needs at least two players");
	end

	local seen = {};
	for _,pid in pairs (playerIDs) do
		if (seen [pid]) then
			error("The same player was named twice in the proposed team");
		end
		seen [pid] = true;

		local gp = game.Game.Players[pid];
		if (gp == nil or gp.State ~= WL.GamePlayerState.Playing) then
			error ("You can't form a team with a player who isn't playing");
		end
	end

	--Everyone must be free of queued-up team changes, otherwise this proposal could never be executed.
	local conflict = FindConflict (game, playerIDs);
	if (conflict ~= nil) then
		setReturnTable ({ Error = conflict });
		return;
	end

	local request = {};
	request.ID = NewGuid();
	request.ProposerID = playerID;
	request.PlayerIDs = playerIDs;
	request.Accepted = {};
	request.Accepted [playerID] = true; --proposing it counts as accepting it

	--In single-player, AIs accept immediately so that the mod can be tried out.  In multi-player we never let players name an AI in the first place, since an AI would never respond.
	if (game.Settings.SinglePlayer) then
		for _,pid in pairs (playerIDs) do
			if (game.Game.Players [pid].IsAIOrHumanTurnedIntoAI) then
				request.Accepted [pid] = true;
			end
		end
	end

	SaveRequest (request);
	WriteRequestToPlayerData (request);

	AlertPlayers (playerIDs, PlayerName(game, playerID) .. ' has proposed a team with members ' .. PlayerNames (game, playerIDs) .. '. Access Game/Diplo Teams mod menu to accept or decline it the proposal', playerID);

	--Everyone may have accepted already if we auto-accepted for AIs above.
	if (HasAcceptedAll (request)) then
		TeamChangeAccepted (game, request, playerID);
		setReturnTable ({ ID = request.ID, Complete = true });
	else
		setReturnTable ({ ID = request.ID, Complete = false });
	end
end

--Turns down a proposal, which cancels it for everyone.
function DeclineTeamChange (game, playerID, payload, setReturnTable)
	local request = GetRequest (payload.ID);
	if (request == nil) then
		setReturnTable ({ Error = "That team change is no longer pending" });
		return;
	end
	if (not contains (request.PlayerIDs, playerID)) then
		error ("You're not a part of that team change");
	end

	DeleteRequest (request);

	AlertPlayers(request.PlayerIDs, PlayerName (game, playerID) .. ' declined the proposed team of ' .. PlayerNames (game, request.PlayerIDs), playerID);

	setReturnTable ({ Declined = true });
end

--Agrees to a proposal.  Once everyone named in it has accepted, the team change gets queued up for the turn advance.
function AcceptTeamChange (game, playerID, payload, setReturnTable)
	local request = GetRequest (payload.ID);
	if (request == nil) then
		setReturnTable ({ Error = "That team change is no longer pending" });
		return;
	end
	if (not contains (request.PlayerIDs, playerID)) then
		error ("You're not a part of that team change");
	end

	--Work out if we're the last one to accept before we write anything, so that we don't record an acceptance that we then can't act on.
	request.Accepted [playerID] = true;
	local complete = HasAcceptedAll (request);

	if (complete) then
		local conflict = FindConflict (game, request.PlayerIDs);
		if (conflict ~= nil) then
			setReturnTable ({ Error = conflict });
			return;
		end

		TeamChangeAccepted (game, request, playerID);
	else
		SaveRequest(request);
		WriteRequestToPlayerData (request);
	end

	setReturnTable ({ Complete = complete });
end

--Leaves the team you're on, without needing anyone's agreement.
function Unteam (game, playerID, payload, setReturnTable)
	local team = TeamOfPlayer (game, playerID, LatestStanding (game));
	if (team == NoTeam) then
		error ("You're not on a team");
	end

	local playerIDs = { playerID };

	local conflict = FindConflict (game, playerIDs);
	if (conflict ~= nil) then
		setReturnTable ({ Error = conflict });
		return;
	end

	local teammates = TeammatesOf (game, playerID, LatestStanding (game));

	RecordTeamChange (playerIDs, NoTeam);

	AlertPlayers (teammates, PlayerName (game, playerID) .. ' is leaving your team.  It takes effect when the turn advances.', playerID);

	setReturnTable ({ Complete = true });
end

--Everyone in the request has agreed, so queue the team change up for the turn advance and tell everyone about it.
function TeamChangeAccepted (game, request, lastPlayerToActID)
	--Always move everyone onto a brand new team, even if some of them are already together on one.  Anyone who changes teams leaves their cards behind, and it'd be unfair and surprising if that depended on which team they happened to end up on.
	RecordTeamChange (request.PlayerIDs, NewTeamID (game));

	DeleteRequest (request);

	local strTeamMemberNames = PlayerNames(game, request.PlayerIDs);
	AlertPlayers (request.PlayerIDs, 'The team of ' ..strTeamMemberNames.. ' has been accepted by all team members, and will take` effect when the turn advances', lastPlayerToActID);

	--queue announcement to be shown in order list @ start of turn
	local publicGameData = Mod.PublicGameData;
	if (publicGameData.Announcements == nil) then publicGameData.Announcements = {}; end
	local eventDetails = {playerID=WL.PlayerID.Neutral, message="Team Alliance has been formed by " ..strTeamMemberNames, visibility=nil};
	table.insert (publicGameData.Announcements, event);
	Mod.PublicGameData = publicGameData;
end

--The client shows alerts and then tells us it's done with them so we don't show them twice.
function AckAlerts (game, playerID, payload, setReturnTable)
	local playerData = Mod.PlayerGameData;

	if (playerData [playerID] ~= nil and playerData [playerID].Alerts ~= nil) then
		--Only remove the alerts the client told us it saw, since we may have added more since it read them.
		playerData [playerID].Alerts = filter (playerData [playerID].Alerts, function (alert) return not contains (payload.AlertIDs or {}, alert.ID); end);
		Mod.PlayerGameData = playerData;
	end

	setReturnTable ({ Acknowledged = true });
end

function process_WarPeaceChanges (game, playerID, payload, setReturnTable)
	--playerID is the player that sent the event, eg: that is Offering/Accepting/Declining Peace, Declaring War, etc
	local publicGameData = Mod.PublicGameData;
	local playerGameData = Mod.PlayerGameData;
	local rg = {};
	if (payload.Message == "Simulate War Declaration") then
		--nothing required here, all activity occurs in Client_PresentMenuUI.lua
	elseif (payload.Message == "Simulate Team Proposal") then
		print ("[SIMULATE TEAM PROPOSAL] [START]");
		local newPayload = {};
		newPayload.Message = 'ProposeTeamChange';
		newPayload.PlayerIDs = payload.PlayerIDs;
		ProposeTeamChange (game, payload.SendingPlayerID, newPayload, setReturnTable);
		rg.Message = PlayerName(game, playerID) .. " has proposed a team with members " .. PlayerNames (game, newPayload.PlayerIDs) .. ". Accept or Decline the proposal from the Diplo Teams mod menu from the Game button";
		-- AlertPlayers (playerIDs, PlayerName(game, playerID) .. ' has proposed a team with members ' .. PlayerNames (game, playerIDs) .. '. Access Game/Diplo Teams mod menu to accept or decline it the proposal', playerID);
		setReturnTable (rg);
		print ("[SIMULATE TEAM PROPOSAL] [END]");
	elseif (payload.Message == "Simulate Peace Offer") then
		print ("[SIMULATE PEACE OFFER] [START]");
		local target = tonumber (payload.TargetPlayerID);
		local sender = tonumber (payload.SendingPlayerID);
		-- if (playerGameData[target].PeaceOffers[sender] == nil) then
		if (playerGameData [target].PeaceOffers == nil) then playerGameData [target].PeaceOffers = {}; end
		if (playerGameData [target].PeaceOffers [sender] == nil) then playerGameData [target].PeaceOffers [sender] = {}; end
		playerGameData [target].PeaceOffers [sender].OfferedBy = sender;
		playerGameData [target].PeaceOffers [sender].OfferedInTurn = game.Game.NumberOfTurns;
		rg.Message = "Peace Offer";
		setReturnTable (rg);
		print ("[SIMULATE PEACE OFFER] [END]");
	elseif (payload.Message == "Peace") then
		local targetPlayerID = tonumber (payload.TargetPlayerID);
		if (game.ServerGame.Game.Players [targetPlayerID].IsAIOrHumanTurnedIntoAI == false) then
			if (playerGameData [targetPlayerID].PeaceOffers [playerID] ~= nil)then
				rg.Message = "Player ("  ..PlayerName (game, targetPlayerID).. ") already has a pending peace offer from you";
				setReturnTable(rg);
			else
				playerGameData [targetPlayerID].PeaceOffers [playerID] = {};
				playerGameData [targetPlayerID].PeaceOffers [playerID].OfferedBy = playerID;
				playerGameData [targetPlayerID].PeaceOffers [playerID].OfferedInTurn = game.Game.NumberOfTurns;
				rg.Message = "Peace Offer has been sent to player (" ..PlayerName (game, targetPlayerID).. ")";
				setReturnTable (rg);
			end
		else
			if (game.ServerGame.Game.Players [targetPlayerID].IsAI == false) then
				--human AIs can have PeaceOffers before they turn into AI, remove the old offers
				playerGameData [playerID].PeaceOffers [targetPlayerID] = nil;
			end
			local remainingwar = {};
			for _,with in pairs (publicGameData.War [targetPlayerID]) do
				--remove the war between the 2 players that just established peace
				if (with ~= playerID) then
					remainingwar [tablelength (remainingwar)+1] = with;
				end
			end
			publicGameData.War [targetPlayerID] = remainingwar;
			remainingwar = {};
			for _,with in pairs (publicGameData.War [playerID]) do
				if (with ~= targetPlayerID) then
					remainingwar [tablelength (remainingwar)+1] = with;
				end
			end
			publicGameData.War [playerID] = remainingwar;
			rg.Message = "Peace Offer has been accepted by the AI player (" ..PlayerName (game, targetPlayerID).. ")";

			--queue announcement to be shown in order list @ start of turn
			if (publicGameData.Announcements == nil) then publicGameData.Announcements = {}; end
			local playerList = {playerID, targetPlayerID};
			local eventDetails = {playerID=WL.PlayerID.Neutral, message="NAP established by '" ..PlayerName (game, playerID).."' and '" ..PlayerName (game, targetPlayerID).."'", visibility=playerList};
			-- print ("[ANNOUNCEMENT PREP] playerID " ..tostring (eventDetails.playerID).. ", message '" ..tostring (eventDetails.message).. ", visibility size " ..tablelength (eventDetails.visibility));
			table.insert (publicGameData.Announcements, eventDetails);
			Mod.PublicGameData = publicGameData;
			-- print ("Mod.PublicGameData.Announcements size " ..tablelength (Mod.PublicGameData.Announcements));
			setReturnTable (rg);
		end
	elseif (payload.Message == "Accept Peace" or payload.Message == "Decline Peace") then
		local targetPlayerID = tonumber (payload.TargetPlayerID);
		if (playerGameData [playerID].PeaceOffers [targetPlayerID] == nil) then
			rg.Message = "Peace Offer doesn't exist, reload the Diplo Teams mod menu to refresh current status";
			setReturnTable (rg);
		else
			if (payload.Message == "Accept Peace") then
				local remainingwar = {};
				publicGameData = Mod.PublicGameData;
				for _,with in pairs (publicGameData.War [targetPlayerID]) do
					if (with ~= playerID) then
						remainingwar [tablelength (remainingwar)+1] = with;
					end
				end
				publicGameData.War [targetPlayerID] = remainingwar;
				remainingwar = {};
				for _,with in pairs (publicGameData.War [playerID]) do
					if (with ~= targetPlayerID) then
						remainingwar [tablelength (remainingwar)+1] = with;
					end
				end
				publicGameData.War [playerID] = remainingwar;
				playerGameData [playerID].PeaceOffers [targetPlayerID] = nil
				playerGameData [targetPlayerID].PeaceOffers [playerID] = {}; --send notice back that the peace offer was accepted
				playerGameData [targetPlayerID].PeaceOffers [playerID].OfferAccepted = playerID;
				rg.Message = "Peace Offer from player (" ..PlayerName (game, targetPlayerID).. ") has been accepted";

				--queue announcement to be shown in order list @ start of turn
				if (publicGameData.Announcements == nil) then publicGameData.Announcements = {}; end
				local playerList = {playerID, targetPlayerID};
				local eventDetails = {playerID=WL.PlayerID.Neutral, message="NAP established by '" ..PlayerName (game, playerID).."' and '" ..PlayerName (game, targetPlayerID).."'", visibility=playerList};
				table.insert (publicGameData.Announcements, eventDetails);
				Mod.PublicGameData = publicGameData;

				setReturnTable (rg);
			else
				playerGameData [playerID].PeaceOffers [targetPlayerID] = nil
				rg.Message = "Peace Offer from player (" ..PlayerName (game, targetPlayerID).. ") has been declined";
				setReturnTable (rg);
			end
		end
	elseif (payload.Message == "Delete Peace Offer Acknowledgement") then
		-- payload.PeaceOfferer = offer.OfferAccepted;
		-- payload.PeaceAccepter = Game.Us.ID;
		local playerGameData = Mod.PlayerGameData;
		playerGameData [payload.PeaceAccepter].PeaceOffers [payload.PeaceOfferer] = {}; --delete the notification
		Mod.PlayerGameData = playerGameData;
	end
	Mod.PlayerGameData = playerGameData;
	Mod.PublicGameData = publicGameData;
end