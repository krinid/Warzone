require ('utilities');
require ('client');

function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)
	if (not WL.IsVersionOrHigher ("6.05")) then
		UI.Alert ("You must update your app to the latest version to use the Diplo Teams mod");
		return;
	end

	Game = game; --make it globally accessible
	Close = close;
	setMaxSize (500, 500);
	root = rootParent;
	mainmenu = UI.CreateButton (root).SetText ("Main Menu").SetOnClick (ShowMenu).SetColor ("#00FFFF");
	local vert = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth (1);
	mainUI = vert;

	if (game.Us == nil) then
		vert = UI.CreateVerticalLayoutGroup (rootParent);
		UI.CreateLabel (vert).SetText("As you are not participating in this game, you cannot use the Diplomacy Mod");
		return;
	elseif (game.Game.PlayingPlayers [game.Us.ID] == nil) then
		UI.CreateLabel (vert).SetText("As you have been eliminated, diplo functions are not available to you");
		return;
	elseif (Mod.PublicGameData.War == nil) then
		UI.CreateLabel (vert).SetText ("Diplo functions are not available during distribution stage");
		return;
	end

	ShowMenu ();
end

--Lists who's on a team with who right now.  Note that teams can change during the game, so we must ask the game rather than reading GamePlayer.Team, which is only the team they started on.
function ShowTeams (vert, game)

	local teams = {};
	local teamIDs = {};
	local noTeam = {};

	for _,gp in pairs (game.Game.PlayingPlayers) do
		local teamID = TeamOfPlayer (game, gp.ID, game.LatestStanding);
		if (teamID == NoTeam) then
			table.insert (noTeam, gp.ID);
		else
			if (teams [teamID] == nil) then
				teams [teamID] = {};
				table.insert (teamIDs, teamID);
			end
			table.insert (teams[teamID], gp.ID);
		end
	end

	-- if (count(teamIDs) == 0) then
	-- 	UI.CreateLabel(vert).SetText('Nobody is currently on a team.');
	-- else
	-- 	UI.CreateLabel(vert).SetText('Teams:');
	-- 	for _,teamID in ipairs(sortedCopy(teamIDs)) do
	-- 		UI.CreateLabel(vert).SetText(' - ' .. PlayerNames(game, teams[teamID]));
	-- 	end
	-- end

	-- if (count(noTeam) > 0) then
	-- 	UI.CreateLabel(vert).SetText('Not on a team: ' .. PlayerNames(game, noTeam));
	-- end
end

--Lists the proposals we're a part of that nobody has declined yet.
function ShowPendingRequests (vert, game)
	if (game.Us == nil) then return; end;
	local lblPendingRequestsMessage = UI.CreateLabel (vert);
	local intNumPeaceOffers = ShowPeaceOffers (vert);
	local intNumTeamProposals = showPendingTeamProposals (vert, game);
	if (intNumPeaceOffers + intNumTeamProposals <= 0) then lblPendingRequestsMessage.SetText ("You have no pending Peace Offers (NAP) or Team Proposals"); end
end

function showPendingTeamProposals (vert, game)
	local requests = Mod.PlayerGameData.PendingTeamRequests or {};
	local intNumRequests = count (requests);

	if (intNumRequests > 0) then
		UI.CreateLabel (vert).SetText ('Team/Alliance proposals:');

		for _, request in pairs (requests) do
			local row = UI.CreateHorizontalLayoutGroup (vert);
			UI.CreateButton (row).SetText ('Accept').SetInteractable (not HaveWeAccepted (game, request)).SetOnClick (function() SendAccept (game, request, Close); end).SetColor (getColourCode ("Button|Green"));
			UI.CreateButton (row).SetText ('Decline').SetOnClick (function () SendDecline (game, request, Close); end).SetColor (getColourCode ("Button|Red"));
			UI.CreateLabel (row).SetText ('  ' .. PlayerName (game, request.ProposerID) .. ' proposed team: ' .. PlayerNames (game, request.PlayerIDs));
			UI.CreateLabel (vert).SetText ('     Status: ' .. RequestStatus (game, request));
		end
	end
	return (intNumRequests);
end

function CreateProposeDialog(rootParent, setMaxSize, setScrollable, game, close)
	setMaxSize (450, 600);
	ProposeRoot = rootParent;
	ProposeClose = close;
	SelectedPlayerIDs = {};
	BuildProposeUI ();
end

--Rebuilt from scratch every time the player adds or removes someone from the team they're putting together.
function BuildProposeUI ()
	if (ProposeVert ~= nil and not UI.IsDestroyed (ProposeVert)) then UI.Destroy(ProposeVert); end

	ProposeVert = UI.CreateVerticalLayoutGroup(ProposeRoot).SetFlexibleWidth(1);
	UI.CreateLabel (ProposeVert).SetText ("[PROPOSE TEAM ALLIANCE]").SetColor (getColourCode ("main heading"));
	UI.CreateLabel (ProposeVert).SetText("• Teams are full & proper War.App teams - you can see each other territories through fog, transfer/airlift units between team members, points for won games will be evenly shared among team members, etc");
	if (GameHasCards (Game.Settings)) then
		UI.CreateLabel (ProposeVert).SetText("• When you join a team, your cards become property of the team");
		UI.CreateLabel (ProposeVert).SetText("• If you leave a team, you forfeit all cards and card pieces, they stay behind on the team with your old teammates");
	end

	UI.CreateLabel(ProposeVert).SetText('\nChoose who to invite to form a Team Alliance. All members must accept for it to take effect');

	UI.CreateLabel (ProposeVert).SetText ('\nTeam Alliance members are:').SetColor (getColourCode ("sub-heading"));
	UI.CreateLabel (ProposeVert).SetText ('  • ' .. PlayerName (Game, Game.Us.ID) .. ' (you)');

	for _,playerID in ipairs (SelectedPlayerIDs) do
		local row = UI.CreateHorizontalLayoutGroup (ProposeVert);
		UI.CreateLabel (row).SetText ('  • ' .. PlayerName (Game, playerID));
		UI.CreateButton (row).SetText ('Remove').SetColor (getColourCode ("Button|Red")).SetOnClick (function()
			SelectedPlayerIDs = filter (SelectedPlayerIDs, function (selected) return selected ~= playerID; end);
			BuildProposeUI ();
		end);
	end

	if (count (SelectedPlayerIDs) == 0) then
		--A team of just yourself would be the same as leaving your team, so don't let them propose one.
		UI.CreateLabel (ProposeVert).SetText('Add at least one other player before proposing');
	end

	UI.CreateButton (ProposeVert).SetText ('Add player').SetOnClick (AddPlayerClicked).SetColor (getColourCode ("Button|Light Blue"));
	UI.CreateButton (ProposeVert).SetText ('Propose team').SetInteractable (count (SelectedPlayerIDs) > 0).SetColor (getColourCode ("Button|Green")).SetOnClick (SubmitPropose);
	AddPlayerClicked ();
end

function AddPlayerClicked ()
	local players = filter (Game.Game.PlayingPlayers, IsPotentialTeammate);

	if (count (players) == 0) then
		UI.Alert ("No players remain that can be added to the team");
		return;
	end

	table.sort (players, function (a, b) return a.DisplayName (nil, false) < b.DisplayName (nil, false); end);
	UI.PromptFromList ("Select a player to add to the team or click cancel to stop selecting players\n\nIf you're looking to create a Team with someone you're currently at war with, you need to Offer Peace (NAP) first", map (players, PlayerButton));
end

--Determines if this is a player we can ask to join the team
function IsPotentialTeammate (player)
	if (player.ID == Game.Us.ID) then return false; end; --we're always on the team we propose

	if (contains (SelectedPlayerIDs, player.ID)) then return false; end; --already selected

	if (player.State ~= WL.GamePlayerState.Playing) then return false; end; --skip players who aren't alive anymore, or that declined the game.

	-- print ("CLIENT game check: ".. tostring (Game.ClientGame ~= nil));
	-- print ("SERVER game check: ".. tostring (Game.ServerGame ~= nil));
	-- print ("InWar check: ".. tostring (Game.Us.ID).. " vs " ..tostring (player.ID).. " == " ..tostring (InWar (Game.Us.ID, player.ID) == true));
	if (InWar (Game.Us.ID, player.ID) == true) then return false; end; --skip players where local player is already at war with -- must first arrange a NAP with them before can Team with them

	--An AI would never respond to a proposal, so don't allow naming one in multi-player. In single-player they accept automatically so the mod can be tried out.
	if (player.IsAIOrHumanTurnedIntoAI and not Game.Settings.SinglePlayer) then return false; end;

	return true;
end

function PlayerButton (player)
	local name = player.DisplayName (nil, false);
	local ret = {};

	if (WL.IsVersionOrHigher ("5.41.0")) then
		ret ["player"] = player.ID;
	else
		ret ["text"] = name;
	end

	ret ["selected"] = function()
		table.insert (SelectedPlayerIDs, player.ID);
		BuildProposeUI ();
	end
	return ret;
end

function SubmitPropose ()
	if (count (SelectedPlayerIDs) == 0) then
		UI.Alert ("A team needs at least one other player on it.  If you want to leave the team you're on, close this and use \"Leave my team\" instead.");
		return;
	end

	local playerIDs = { Game.Us.ID };
	for _,playerID in ipairs(SelectedPlayerIDs) do
		table.insert(playerIDs, playerID);
	end

	local payload = {};
	payload.Message = 'ProposeTeamChange';
	payload.PlayerIDs = playerIDs;

	--Close the propose dialog and the menu behind it, since what they're showing is about to be out of date.
	local closeBoth = function()
		-- ProposeClose();
		-- Close();
	end

	SendTeamMessage(Game, 'Proposing team...', payload, closeBoth, function(returnValue)
		if (returnValue.Complete) then
			return 'The Team Alliance of ' .. PlayerNames (Game, playerIDs) .. ' takes effect when the turn advances';
		else
			return 'Proposal was sent. If everyone accepts it, it will take effect at the start of the following turn';
		end
	end);
end

function OpenOfferPeace()
	DeleteUI ();
	local vert = UI.CreateVerticalLayoutGroup (mainUI);
	UI.CreateLabel (vert).SetText ("[OFFER PEACE (NAP)]").SetColor (getColourCode ("main heading"));
	UI.CreateLabel (vert).SetText ("• You can propose a Non-Aggresion Pact (NAP) to players you are at war with");
	UI.CreateLabel (vert).SetText ("• This puts you into a state of Peace, whereby neither player can attack each other");
	UI.CreateLabel (vert).SetText ("• In order to attack a player you are at peace with, you must Declare War\n");

	local horz = UI.CreateHorizontalLayoutGroup (vert);
	local horz = UI.CreateHorizontalLayoutGroup (vert);
	local horz = UI.CreateHorizontalLayoutGroup (vert);
	textelem = UI.CreateLabel (horz).SetText ("Offer peace to: ");
	TargetPlayerBtn = UI.CreateButton (horz).SetText ("Select player...").SetOnClick (TargetPlayerClickedOfferPeace);
	btnOfferPeace = UI.CreateButton (vert).SetText ("Offer Peace (NAP)").SetOnClick (commitofferpeace).SetColor (getColourCode ("Button|Green"));
	TargetPlayerClickedOfferPeace ();
end

function commitofferpeace()
	local offerto = TargetPlayerBtn.GetText ();
	if (offerto == "Select player...") then
		UI.Alert ("You need to choose a player first");
	else
		local payload = {};
		payload.Message = "Peace";
		payload.TargetPlayerID = SelectedData [1];
		Game.SendGameCustomMessage ("Sending request...", payload, function (returnvalue)
			showedreturnmessage = false;
			UI.Alert(returnvalue.Message);
			end);
		TargetPlayerBtn.SetText ("Select player...");
	end
end

function TargetPlayerClickedOfferPeace ()
	if (Mod.PublicGameData.War ~= nil and Mod.PublicGameData.War [Game.Us.ID] ~= nil) then
		local options = {};
		for _, player in pairs (Game.Game.PlayingPlayers) do
			for _, with in pairs (Mod.PublicGameData.War [Game.Us.ID]) do
				if (tostring (with) == tostring (player.ID)) then
					table.insert (options, player);
				end
			end
		end

		table.sort (options, function (a, b) return a.DisplayName (nil, false) < b.DisplayName (nil, false); end);
		UI.PromptFromList ("Select a player to offer peace to", map (options, PlayerButton_OfferPeace));
	end
end

function PlayerButton_OfferPeace (player)
	local name = player.DisplayName (nil, false);
	local ret = {};

	if (WL.IsVersionOrHigher("5.41.0")) then
		ret["player"] = player.ID;
	else
		ret["text"] = name;
	end

	ret["selected"] = function()
		SelectedData [1] = player.ID;
		TargetPlayerBtn.SetText (name);
	end
	return ret;
end

function ShowMenu ()
	DeleteUI ();
	local vert = mainUI;

	-- ShowTeams (vert, Game); --don't need this, can just look to the player dialog to see the teams
	UI.CreateLabel (vert).SetText ("- - - - - - - PENDING REQUESTS - - - - - - -").SetColor ("#FFFF00");
	ShowPendingRequests (vert, Game);

	local horz = UI.CreateHorizontalLayoutGroup (vert);
	local vertTeam = UI.CreateVerticalLayoutGroup (horz);
	local vertWar = UI.CreateVerticalLayoutGroup (horz);
	--this puts Team & War panes beside each other, to revert to above/below each other, just make vertTerm = vert, vertWar = vert and ignore the horz

	-- UI.CreateLabel (vert).SetText ("[TEAM OPTIONS]").SetColor ("#FFFF00");
	-- UI.CreateLabel (vert).SetText ("- - - - - - -").SetColor ("#FFFF00");
	-- UI.CreateLabel (vertTeam).SetText ("- - - - - - - TEAM ACTIONS - - - - - - -").SetColor ("#FFFF00");
	UI.CreateLabel (vertTeam).SetText ("- - TEAM ACTIONS - -").SetColor ("#FFFF00");
	UI.CreateButton (vertTeam).SetText ('Propose new team').SetOnClick (function() Game.CreateDialog (CreateProposeDialog); end);
	UI.CreateButton (vertTeam).SetText ('Leave current team').SetOnClick (function() SendUnteam (Game, Close); end).SetInteractable (TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding) ~= NoTeam);
	-- UI.CreateLabel (vert).SetText ("- - - - - - -").SetColor ("#FFFF00");

	showedreturnmessage = true;
	TargetPlayerBtn = nil;
	btnExecuteDeclare = nil;
	btnDeclareWar = nil;
	textelem = nil;
	btnExecuteDeclare = nil;
	btnOfferPeace = nil;
	SelectedData = {};

	-- UI.CreateLabel (vertWar).SetText ("- - - - - - - PEACE/WAR ACTIONS - - - - - - -").SetColor ("#FFFF00");
	UI.CreateLabel (vertWar).SetText ("- - PEACE/WAR ACTIONS - -").SetColor ("#FFFF00");
	btnDeclareWar = UI.CreateButton (vertWar).SetText ("Declare War").SetOnClick (OpenDeclareWar);
	btnOfferPeace = UI.CreateButton (vertWar).SetText ("Offer Peace (NAP)").SetOnClick (OpenOfferPeace);

	local boolSimulationOptionsEnabled = false;
	if (boolSimulationOptionsEnabled == true) then
		btnSimulateOfferWar = UI.CreateButton (vertWar).SetText ("Simulate War Declaration").SetOnClick (
			function ()
				local payload = {};
				payload.Message = "Simulate War Declaration";
				payload.SendingPlayerID = 1;
				payload.TargetPlayerID = 1058239;
				local orders = Game.Orders or {};
				local event = WL.GameOrderCustom.Create (Game.Us.ID, "Declared war on " .. tostring (payload.TargetPlayerID), "Diplo Teams|DeclareWar|" ..tostring (payload.SendingPlayerID).. "|" .. tostring (payload.TargetPlayerID));
				event.Icon = "Diplo Teams_order_40x40";
				table.insert (orders, event); --custom order indicating which player declared war on which player
				Game.Orders = orders;

				-- Game.SendGameCustomMessage ("Sending request...", payload, function (returnvalue)
				-- 	showedreturnmessage = false;
				-- 	UI.Alert (returnvalue.Message);
				-- 	end);
			end
		);

		btnSimulateOfferTeam = UI.CreateButton (vertWar).SetText ("Simulate Team Proposal").SetOnClick (
			function ()
				local payload = {};
				payload.Message = "Simulate Team Proposal";
				payload.SendingPlayerID = 1;
				payload.PlayerIDs = {1, 1058239};
				Game.SendGameCustomMessage ("Sending request...", payload, function (returnvalue)
					showedreturnmessage = false;
					UI.Alert (returnvalue.Message);
					end);
			end
		);

		btnSimulateOfferPeace = UI.CreateButton (vertWar).SetText ("Simulate Peace Offer").SetOnClick (
			function ()
				-- print ("yololo "..tostring (Game.Us.ID));
				local payload = {};
				payload.Message = "Simulate Peace Offer";
				payload.SendingPlayerID = 1;
				payload.TargetPlayerID = 1058239;
				Game.SendGameCustomMessage ("Sending request...", payload, function (returnvalue)
					showedreturnmessage = false;
					UI.Alert (returnvalue.Message);
					end);
			end
		);
	end

	-- UI.CreateLabel (vert).SetText ("- - - - - - -").SetColor ("#FFFF00");
	UI.CreateLabel (vert).SetText ("- - - - - - - TEAM/PEACE/WAR STATUS - - - - - - -").SetColor ("#FFFF00");
	local boolInAlliance = false;
	local lblAllianceList = UI.CreateLabel (vert);
	for _,player in pairs (Game.Game.PlayingPlayers) do
		if (player.ID ~= Game.Us.ID and (TeamOfPlayer (Game, player.ID, Game.LatestStanding) ~= -1 and TeamOfPlayer (Game, player.ID, Game.LatestStanding) == TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding))) then
			UI.CreateLabel (vert).SetText ("    ■ " .. toname (player.ID, Game));
			boolInAlliance = true;
		end
	end
	if (boolInAlliance == false) then lblAllianceList.SetText ("• In a team/alliance with: No one");
	else lblAllianceList.SetText ("• In a team/alliance with: ").SetColor ("#00AA00");
	end

	local boolAtWar = false; --at war with 1+ players
	local lblWarList = UI.CreateLabel (vert);
	if (Mod.PublicGameData.War ~= nil and Mod.PublicGameData.War [Game.Us.ID] ~= nil) then
		for _,warringPlayerID in pairs (Mod.PublicGameData.War [Game.Us.ID]) do
			if (Game.Game.PlayingPlayers [warringPlayerID] ~= nil) then
				UI.CreateLabel (vert).SetText ("    ■ " .. toname (warringPlayerID, Game));
				boolAtWar = true;
			end
		end
		if (boolAtWar == false) then lblWarList.SetText ("• At war with: No one");
		else lblWarList.SetText ("• At war with:").SetColor ("#FF0000");
		end
	end
	btnOfferPeace.SetInteractable (boolAtWar);

	local boolAtPeace = false;
	local lblPeaceList = UI.CreateLabel (vert);
	for _,player in pairs (Game.Game.PlayingPlayers) do
		if (player.ID ~= Game.Us.ID and (TeamOfPlayer (Game, player.ID, Game.LatestStanding) == -1 or TeamOfPlayer (Game, player.ID, Game.LatestStanding) ~= TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding)) and atWarWithPlayer (Game.Us.ID, player.ID) == false) then
			UI.CreateLabel (vert).SetText ("    ■ " .. toname (player.ID, Game));
			boolAtPeace = true;
		end
	end
	if (boolAtPeace == false) then lblPeaceList.SetText ("• At peace with: No one"); btnDeclareWar.SetInteractable (false);
	else lblPeaceList.SetText ("• At peace with: "); --use default colour, no reason to highlight this like Alliance/Teammate (GREEN) or War (RED)
	end

	-- print ("[FULL ONGOING WAR LIST]");
	-- for k,v in pairs (Mod.PublicGameData.War) do
	-- 	print ("  [WAR ITEM] " ..tostring (k).." vs " ..tostring (v) .. ", size " ..tablelength (v));
	-- 	for k2,v2 in pairs (v) do
	-- 		print ("    [WAR ITEM!] " ..tostring (k).." vs " ..tostring (v2));
	-- 	end
	-- end

end

function ShowPeaceOffers (vert)
	local intOfferCount = 0;
	if (tablelength (Mod.PlayerGameData.PeaceOffers) > 0) then
		lblPeaceOffers = UI.CreateLabel (vert).SetText ("Peace Offers:");

		for _,offer in pairs (Mod.PlayerGameData.PeaceOffers) do

			-- playerGameData [targetPlayerID].PeaceOffers [playerID].OfferAccepted = true;
			if (offer.OfferAccepted ~= nil) then
				--this is not a new Peace Offer but rather the response to a Peace Offer sent to another player from the local player
				--display acceptance message, then delete the Offer record notice
				UI.Alert ("Peace Offer you sent to " ..PlayerName (Game, offer.OfferAccepted).. " was accepted, you are now in NAP with this player");
				local playerGameData = Mod.PlayerGameData;
				playerGameData.PeaceOffers [offer.OfferAccepted] = {}; --delete the notification
				Mod.PlayerGameData = playerGameData;
			else
				--this is a new Peace Offer
				intOfferCount = intOfferCount + 1;

				local horz = UI.CreateHorizontalLayoutGroup (vert);
				print ("[PEACE OFFER] from " ..tostring (offer.OfferedBy));
				buttonAccept = UI.CreateButton (horz).SetText ("Accept").SetColor (getColourCode ("Button|Green"));
				local onclick2=function ()
					local payload = {};
					payload.Message = "Accept Peace";
					payload.Spieler = offer.OfferedBy;
					AcceptDeclinePeaceOffer (payload);
					end;
				buttonAccept.SetOnClick (onclick2);

				buttonDeny = UI.CreateButton (horz).SetText ("Decline").SetColor (getColourCode ("Button|Red"));
				local onclick=function ()
					local payload = {};
					payload.Message = "Decline Peace";
					payload.Spieler = offer.OfferedBy;
					AcceptDeclinePeaceOffer (payload);
					end;
				buttonDeny.SetOnClick (onclick);
				UI.CreateLabel (horz).SetText ("  " ..PlayerName (Game, offer.OfferedBy) .. " offers you peace");
			end
		end
	end
	return (intOfferCount);
end

function AcceptDeclinePeaceOffer(data)
	local payload = {};
	payload.Message = data.Message;
	payload.TargetPlayerID = data.Spieler;
	Game.SendGameCustomMessage ("Sending data...", payload, function(returnvalue)
		showedreturnmessage = false;
		UI.Alert(returnvalue.Message);
	end);
	ShowMenu ();
end

function toname (playerid,game)
	return game.Game.Players [tonumber (playerid)].DisplayName (nil, false);
end

function OpenDeclareWar ()
	DeleteUI ();
	local vert = UI.CreateVerticalLayoutGroup (mainUI);
	UI.CreateLabel (vert).SetText ("[DECLARE WAR]").SetColor (getColourCode ("main heading"));
	UI.CreateLabel (vert).SetText ("You declare war on a player in order to attack them. If you are in a Team Alliance with a player, you must first Offer Peace (NAP) before you can declare war on them\n");
	local horz = UI.CreateHorizontalLayoutGroup (mainUI);
	textelem = UI.CreateLabel (horz).SetText ("Declare war on: ").SetColor ("#FF0000");
	TargetPlayerBtn = UI.CreateButton (horz).SetText ("Select player...").SetOnClick (TargetPlayerClickedDeclareWar);
	btnExecuteDeclare = UI.CreateButton (mainUI).SetText ("Declare").SetOnClick (declare).SetColor (getColourCode ("Button|Green"));
	TargetPlayerClickedDeclareWar ();
end

function TargetPlayerClickedDeclareWar ()
	local playerList = {};
	for k, player in pairs (Game.Game.PlayingPlayers) do
		-- print ("PLAYER " ..k..", "..player.DisplayName (nil, false).. ", Team " ..tostring (TeamOfPlayer (Game, player.ID, Game.LatestStanding)).. ", Diff team: " ..tostring (TeamOfPlayer (Game, player.ID, Game.LatestStanding) == -1 or TeamOfPlayer (Game, player.ID, Game.LatestStanding) ~= TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding)).. ", Existing war order: " ..tostring (ContainsDeclareWarOrder (player.ID)));
		-- print ("    condition " ..tostring ((player.ID ~= Game.Us.ID and (TeamOfPlayer (Game, player.ID, Game.LatestStanding) == -1 or TeamOfPlayer (Game, player.ID, Game.LatestStanding) ~= TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding)) and ContainsDeclareWarOrder (player.ID) == false)));
		if (player.ID ~= Game.Us.ID and (TeamOfPlayer (Game, player.ID, Game.LatestStanding) == -1 or TeamOfPlayer (Game, player.ID, Game.LatestStanding) ~= TeamOfPlayer (Game, Game.Us.ID, Game.LatestStanding)) and ContainsDeclareWarOrder (player.ID) == false and atWarWithPlayer (Game.Us.ID, player.ID) == false) then
			table.insert (playerList, player);
		end
	end

	table.sort (playerList, function(a, b) return a.DisplayName(nil, false) < b.DisplayName(nil, false); end);
	if (tablelength (playerList) > 0) then
		UI.PromptFromList ("Select a player to declare war on", map (playerList, PlayerButton_DeclareWar));
	else
		UI.Alert ("No players are available to declare on\n\nYou are either in a team/alliance or already at war with all active players");
	end
end

function atWarWithPlayer (player1ID, player2ID)
	for _, warringPlayerID in pairs (Mod.PublicGameData.War [player1ID]) do
		if (warringPlayerID == player2ID) then
			return true;
		end
	end
	return false;
end

function PlayerButton_DeclareWar (player)
	local name = player.DisplayName (nil, false);
	local ret = {};

	if (WL.IsVersionOrHigher("5.41.0")) then
		ret["player"] = player.ID;
	else
		ret["text"] = name;
	end

	ret["selected"] = function()
		SelectedData [1] = player.ID;
		TargetPlayerBtn.SetText (name);
	end
	return ret;
end

function PlayerButton (player)
	local name = player.DisplayName(nil, false);
	local ret = {};

	if (WL.IsVersionOrHigher("5.41.0")) then
		ret["player"] = player.ID;
	else
		ret["text"] = name;
	end

	ret["selected"] = function()
		table.insert (SelectedPlayerIDs, player.ID);
		BuildProposeUI();
	end
	return ret;
end

function ContainsDeclareWarOrder (playerID)
	local gameorders = Game.Orders;
	for _,order in pairs (gameorders) do
		if (order.proxyType == "GameOrderCustom") then
			if (order.Payload == tostring (playerID)) then return true; end
		end
	end
	return false;
end

function declare ()
	local declareon = TargetPlayerBtn.GetText ();
	local orders = Game.Orders;
	local myID = Game.Us.ID;
	if (declareon == "Select player...") then
		UI.Alert ('You need to choose a player first');
		return;
	end
	if (Game.Us.HasCommittedOrders == true) then
		UI.Alert ("You need to uncommit first");
		return;
	end
	local event = WL.GameOrderCustom.Create (myID, "Declared war on " .. declareon, "Diplo Teams|DeclareWar|" ..tostring (myID).. "|" .. tostring (SelectedData[1]));
	event.Icon = "Diplo Teams_order_40x40";
	table.insert (orders, event); --custom order indicating which player declared war on which player
	Game.Orders = orders;
	TargetPlayerBtn.SetText ("Select player...");
end

function getplayerid (playername, game)
	for _,playerinfo in pairs (game.Game.Players) do
		local name = playerinfo.DisplayName (nil, false);
		if (name == playername) then
			return playerinfo.ID;
		end
	end
	return 0;
end

function PlayerButtonCustom (player,knopf,knopfid)
	local ret = {};
	ret ["text"] = toname (player.ID, Game);
	ret ["selected"] = function()
		SelectedData [knopfid] = player.ID;
		knopf.SetText (ret ["text"]);
	end
	return ret;
end

function DeleteUI ()
	if (not UI.IsDestroyed (mainUI)) then UI.Destroy (mainUI); end
	mainUI = UI.CreateVerticalLayoutGroup (root).SetFlexibleWidth (1);
	if (not UI.IsDestroyed (textelem)) then UI.Destroy (textelem); end
	if (not UI.IsDestroyed (TargetPlayerBtn)) then UI.Destroy (TargetPlayerBtn); end
	if (not UI.IsDestroyed (btnExecuteDeclare)) then UI.Destroy (btnExecuteDeclare); end
	if (not UI.IsDestroyed (btnDeclareWar)) then UI.Destroy (btnDeclareWar); end
	if (not UI.IsDestroyed (btnOfferPeace)) then UI.Destroy (btnOfferPeace); end
	textelem = nil;
	TargetPlayerBtn = nil;
	btnExecuteDeclare = nil;
	btnDeclareWar = nil;
	btnOfferPeace = nil;
end