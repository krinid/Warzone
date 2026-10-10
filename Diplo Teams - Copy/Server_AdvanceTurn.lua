require ('utilities');
require ('serverUtilities');

function Server_AdvanceTurn_Start (game, addNewOrder)
	--code for War/Peace relationships
	local playerGameData = Mod.PlayerGameData;
	RemainingDeclarations = {}; --list of wars to be declared @ end of turn in Server_AdvanceTurn_End
	for _,pid in pairs(game.Game.PlayingPlayers) do
		playerGameData [pid.ID].HasNewWar = false; --clear the indicator that there's a new war, reeval this in Game_Refresh and send alert to players if new War Declarations or Peace Offers have been made since turn advanced
	end
	Mod.PlayerGameData = playerGameData;

	--code War.App Team/Alliance relationships
	ExecuteTeamChanges (game, addNewOrder);
	CleanUpRequests (game);

	--if there are pending announcement events, add them here
	print ("Mod.PublicGameData.Announcements size " ..tablelength (Mod.PublicGameData.Announcements));
	for _,eventDetails in pairs (Mod.PublicGameData.Announcements or {}) do
		-- for ref: local eventDetails = {playerID=WL.PlayerID.Neutral, message="NAP established by '" ..PlayerName (game, playerID).."' and '" ..PlayerName (game, targetPlayerID).."'", visibility=playerList};
		print ("[ANNOUNCEMENT] playerID " ..tostring (eventDetails.playerID).. ", message '" ..tostring (eventDetails.message).. ", visibility size " ..tablelength (eventDetails.visibility));
		-- local event = WL.GameOrderEvent.Create (eventDetails.playerID, eventDetails.message); --, eventDetails.visibility);
		local event = WL.GameOrderEvent.Create (eventDetails.playerID, eventDetails.message, eventDetails.visibility);
		event.Icon = "Diplo Teams_order_40x40";
		addNewOrder (event);
	end
	local publicGameData = Mod.PublicGameData;
	publicGameData.Announcements = nil;
	Mod.PublicGameData = publicGameData;
end

--Executes every team change that was fully accepted.  We do it when the turn advances rather than the moment everyone accepted, so that teams never change while players are still entering their orders.
function ExecuteTeamChanges (game, addNewOrder)
	local priv = Mod.PrivateGameData;
	local changes = priv.AcceptedTeamChanges;
	if (changes == nil or count (changes) == 0) then return; end;

	--Group everyone moving onto the same team together so that forming a team reads as one event.
	local groups = {};
	local teamIDs = {};
	local leaving = {};

	for playerID,teamID in pairs (changes) do
		if (teamID == NoTeam) then
			table.insert (leaving, playerID);
		else
			if (groups [teamID] == nil) then
				groups [teamID] = {};
				table.insert (teamIDs, teamID);
			end
			table.insert (groups [teamID], playerID);
		end
	end

	--Players leaving a team get their own event, since they're not joining anyone.
	for _,playerID in ipairs (sortedCopy (leaving)) do
		local event = WL.GameOrderEvent.Create (playerID, PlayerName (game, playerID) .. ' left their team');
		event.AssignTeamOpt = { [playerID] = NoTeam };
		event.Icon = "Diplo Teams_order_40x40";
		addNewOrder (event);
	end

	for _,teamID in ipairs (sortedCopy (teamIDs)) do
		local playerIDs = sortedCopy (groups [teamID]);

		local assign = {};
		for _,playerID in ipairs (playerIDs) do
			assign [playerID] = teamID;
		end

		local event = WL.GameOrderEvent.Create (playerIDs[1], PlayerNames (game, playerIDs) .. ' have formed a team alliance');
		event.AssignTeamOpt = assign;
		event.Icon = "Diplo Teams_order_40x40";
		addNewOrder (event);
	end

	priv.AcceptedTeamChanges = nil;
	Mod.PrivateGameData = priv;
end

--Cancel any proposal that names someone who isn't playing anymore, since it could never be accepted by everyone.  This also keeps the list players see tidy.
function CleanUpRequests (game)
	local requests = Mod.PrivateGameData.PendingTeamRequest;
	if (requests == nil) then return; end;

	for _,request in pairs (requests) do
		local goneID = first (request.PlayerIDs, function (playerID)
			local gp = game.Game.Players [playerID];
			return gp == nil or gp.State ~= WL.GamePlayerState.Playing;
		end);

		if (goneID ~= nil) then
			DeleteRequest (request);
			AlertPlayers (request.PlayerIDs, 'The proposed team of ' .. PlayerNames (game, request.PlayerIDs) .. ' was cancelled, since ' .. PlayerName (game, goneID) .. ' is no longer playing.', nil);
		end
	end
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == "GameOrderAttackTransfer") then
		--allows transfering
		if (result.IsAttack) then
			--owner of the target territory
			local toowner = game.ServerGame.LatestTurnStanding.Territories [order.To].OwnerPlayerID;

			--allows attacking of neutral territories, and verification if order is not neutral required for compatibility with other mods
			--also permits attacking teammates (leave it to the 'Treat Teammates as Enemies' property - this is intentional and strategically useful in games)
			if (toowner ~= WL.PlayerID.Neutral and order.PlayerID ~= WL.PlayerID.Neutral and playersAreTeamMates (toowner, order.PlayerID, game, game.ServerGame.LatestTurnStanding) == false and InWar (order.PlayerID, toowner) == false) then
				result.ActualArmies = WL.Armies.Create (0, {});
				local event = WL.GameOrderEvent.Create (order.PlayerID, "[Attack skipped b/c not At War]");
				event.Icon = "Diplo Teams_order_40x40";
				addNewOrder (event);
				-- skipThisOrder (WL.ModOrderControl.Skip); --don't skip b/c the order was adjusted to be 0 armies/0 SUs so it draws the 0 unit attack arrow

				--Decleare War for AI if AI (verification if settings allow it is in DeclareWar)
				if (game.ServerGame.Game.Players [order.PlayerID].IsAIOrHumanTurnedIntoAI == true) then
					DeclareWar (order.PlayerID, toowner, game);
				end
			end
		end
	elseif (order.proxyType == "GameOrderCustom") then
		local ModData = split (order.Payload, "|");
		--Player war declaration
		if (ModData [1] == "Diplo Teams" and ModData [2] == "DeclareWar") then
			local playerIDdeclarer = tonumber (ModData [3]); --player that declared war
			local playerIDtarget = tonumber (ModData [4]); --player being declared on
			print ("[SATO] [WAR DECLARATION] " ..tostring (playerIDdeclarer).. " vs " ..tostring (playerIDtarget));
			if (InWar (playerIDdeclarer, playerIDtarget) == false) then
				-- "Diplo Teams|" ..tostring (myID).. "|" .. tostring (SelectedData[1])))
				print ("[SATO] [WAR DECLARATION] [EXECUTE DECLARATION]" ..tostring (playerIDdeclarer).. " vs " ..tostring (playerIDtarget));
				DeclareWar (playerIDdeclarer, playerIDtarget, game);
				local playerGameData = Mod.PlayerGameData;
				if (playerGameData [playerIDdeclarer] == nil) then playerGameData [playerIDdeclarer] = {}; end
				if (playerGameData [playerIDtarget] == nil) then playerGameData [playerIDtarget] = {}; end
				playerGameData [playerIDdeclarer].HasNewWar = true;
				playerGameData [playerIDtarget].HasNewWar = true;
				Mod.PlayerGameData = playerGameData;
			end
			skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip order, it will execute @ end of the turn in Server_AdvanceTurn_End
		end

	--Card playing verification
	elseif (order.proxyType == "GameOrderPlayCardSanctions") then
		if (IsPlayable (order.PlayerID, order.SanctionedPlayerID, game, Mod.Settings.SanctionCardRequireWar, Mod.Settings.SanctionCardRequirePeace, Mod.Settings.SanctionCardRequireAlly) == false) then
			skipThisOrder (WL.ModOrderControl.Skip);
		end
	elseif (order.proxyType == "GameOrderPlayCardBomb") then
		if(IsPlayable (order.PlayerID, game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID, game, Mod.Settings.BombCardRequireWar, Mod.Settings.BombCardRequirePeace, Mod.Settings.BombCardRequireAlly) == false) then
			skipThisOrder (WL.ModOrderControl.Skip);
		end
	elseif (finished == nil) then
		if (order.proxyType == "GameOrderPlayCardSpy") then
			if (IsPlayable (order.PlayerID, order.TargetPlayerID, game, Mod.Settings.SpyCardRequireWar, Mod.Settings.SpyCardRequirePeace, Mod.Settings.SpyCardRequireAlly) == false) then
				skipThisOrder (WL.ModOrderControl.Skip);
			end
		end
	elseif (order.proxyType == "GameOrderPlayCardGift") then
		if (IsPlayable (order.PlayerID, order.GiftTo, game, Mod.Settings.GiftCardRequireWar, Mod.Settings.GiftCardRequirePeace, Mod.Settings.GiftCardRequireAlly) == false) then
			skipThisOrder (WL.ModOrderControl.Skip);
		end
	end
end

function Server_AdvanceTurn_End (game, addNewOrder)
	local publicGameData = Mod.PublicGameData;
	local playerGameData = Mod.PlayerGameData;
	--Finishing war declaration
	print ("[SATE] #declarations " ..tablelength (RemainingDeclarations));
	for _,newwar in pairs (RemainingDeclarations) do
		if (game.ServerGame.Game.Players [newwar.S1].IsAI == false) then
			playerGameData [newwar.S1].HasNewWar = true;
		end
		if (game.ServerGame.Game.Players [newwar.S2].IsAI == false) then
			playerGameData [newwar.S2].HasNewWar = true;
		end
		--establish the war state between the players
		publicGameData.War [newwar.S1][tablelength (publicGameData.War [newwar.S1])+1] = newwar.S2;
		publicGameData.War [newwar.S2][tablelength (publicGameData.War [newwar.S2])+1] = newwar.S1;
		local event = WL.GameOrderEvent.Create (newwar.S1, "Declared war on " .. toname (newwar.S2,game), nil, nil, nil);
		event.Icon = "Diplo Teams_order_40x40";
		addNewOrder (event);
	end
	RemainingDeclarations = {};
	finished = true;
	Mod.PublicGameData = publicGameData;
	Mod.PlayerGameData = playerGameData;
end

--translates playerid to playername, which is required for history, since it is not userfriendly to show the id, but also results in static playernames and does not addapt to playername changes
function toname (playerid, game)
	return game.ServerGame.Game.Players [playerid].DisplayName (nil, false);
end

--Verifies if cards can be played based on mod settings for whether cards can be played on players you are At War, At Peace or Teammates with
--return true if play abides by the settings (don't skip the order, permit it to execute)
--return false if play doesn't abide and the order should be skipped
function IsPlayable (Player1ID, Player2ID, game, boolCanPlayAtWar, boolCanPlayAtPeace, boolCanPlayOnTeammates)
	--if either the playing player (currently this isn't possible, only Events can be attributed to WL.PlayerID.Neutral) or target player is Neutral, permit the play
	--this means any player can play cards on neutral territories, and possibly in the future 'Neutral' players (mod based actions?) who wouldn't have any Ally/War/Peace status with any players could also play cards
	if (Player1ID == WL.PlayerID.Neutral or Player2ID == WL.PlayerID.Neutral) then
		return true;
	end

	--check for At Peace/Teammates/At War conditions and permit play if meets criteria
	if (boolCanPlayAtPeace == true and InWar (Player1ID, Player2ID) == false and playersAreTeamMates (Player1ID, Player2ID, game, game.ServerGame.LatestTurnStanding) == false) then
		return true;
	elseif (boolCanPlayOnTeammates == true and playersAreTeamMates (Player1ID, Player2ID, game, game.ServerGame.LatestTurnStanding) == true) then
		return true;
	elseif (boolCanPlayAtWar == true) then
		--if the players are at war, permit it; if the players aren't at war and Player1 is an AI, Declare War on the target
		if (InWar (Player1ID, Player2ID) == true) then
			return true;
		else
			--If player1 is an AI, declare war on the target player2 if mod settings permit it (this is verified in DeclareWar)
			if (game.ServerGame.Game.Players [Player1ID].IsAIOrHumanTurnedIntoAI == true) then
				DeclareWar (Player1ID, Player2ID, game);
			end
			return false; --skip the order for this turn b/c not At War yet
		end
	end
	return false;
end

--execute declaration of war for Player1 on Player2
--if Player1 is a human player, always allow it; if Player1 is an AI, 
function DeclareWar (Player1, Player2, game)
	if (Player1 == Player2) then
		return; --can't declare on self; not sure why the function would be called in this manner, but if it happens, don't act on it (it wouldn't have any impact anyhow but it would appear in the War list as being at war with oneself which is simply odd)
	end

	--can't declare war if (A) already Allied (on a Team) with target player (which could have happened after the turn advanced) or (B) already at war with the player
	if (playersAreTeamMates (Player1, Player2, game, game.ServerGame.LatestTurnStanding) == false and InWar (Player1, Player2) == false) then
		if (game.ServerGame.Game.Players [Player1].IsAIOrHumanTurnedIntoAI == true) then
			if (game.ServerGame.Game.Players [Player2].IsAIOrHumanTurnedIntoAI == false and Mod.Settings.AllowAIDeclaration == false) then
				return;
			end
			if (game.ServerGame.Game.Players [Player2].IsAIOrHumanTurnedIntoAI == true and Mod.Settings.AIsDeclareAIs == false) then
				return;
			end
		end
		for _,newwar in pairs (RemainingDeclarations) do
			local P1 = newwar.S1;
			local P2 = newwar.S2;
			if (P1 == Player1 or P1 == Player2) then
				if (P2 == Player1 or P2 == Player2) then
					--declaration is already queued, don't need to add it again
					return;
				end
			end
		end
		RemainingDeclarations [tablelength(RemainingDeclarations)+1] = {};
		RemainingDeclarations [tablelength(RemainingDeclarations)].S1 = Player1;
		RemainingDeclarations [tablelength(RemainingDeclarations)].S2 = Player2;
	end
end