require('History'); --dabo

require('Utilities');
require('Client');

function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)

	if (not WL.IsVersionOrHigher("6.05")) then
		UI.Alert("You must update your app to the latest version to use the Diplo Teams mod");
		return;
	end

	Game = game; --make it globally accessible
	Close = close;

	setMaxSize(500, 500);

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1);
	ShowTeams(vert, game);
	ShowPendingRequests(vert, game);
	ShowActions(vert, game);

	Client_PresentMenuUI_dabo (vert, setMaxSize, setScrollable, game, close);
end

--Lists who's on a team with who right now.  Note that teams can change during the game, so we must ask the game rather than reading GamePlayer.Team, which is only the team they started on.
function ShowTeams(vert, game)

	local teams = {};
	local teamIDs = {};
	local noTeam = {};

	for _,gp in pairs(game.Game.PlayingPlayers) do
		local teamID = TeamOfPlayer(game, gp.ID, game.LatestStanding);
		if (teamID == NoTeam) then
			table.insert(noTeam, gp.ID);
		else
			if (teams[teamID] == nil) then
				teams[teamID] = {};
				table.insert(teamIDs, teamID);
			end
			table.insert(teams[teamID], gp.ID);
		end
	end

	if (count(teamIDs) == 0) then
		UI.CreateLabel(vert).SetText('Nobody is currently on a team.');
	else
		UI.CreateLabel(vert).SetText('Teams:');
		for _,teamID in ipairs(sortedCopy(teamIDs)) do
			UI.CreateLabel(vert).SetText(' - ' .. PlayerNames(game, teams[teamID]));
		end
	end

	-- if (count(noTeam) > 0) then
	-- 	UI.CreateLabel(vert).SetText('Not on a team: ' .. PlayerNames(game, noTeam));
	-- end
end

--Lists the proposals we're a part of that nobody has declined yet.
function ShowPendingRequests(vert, game)
	if (game.Us == nil) then return; end;

	local requests = Mod.PlayerGameData.PendingTeamRequests or {};
	if (count(requests) == 0) then return; end;

	UI.CreateLabel(vert).SetText('Proposed teams:');

	for _,request in pairs(requests) do
		UI.CreateLabel(vert).SetText(' - ' .. PlayerName(game, request.ProposerID) .. ' proposed a team of ' .. PlayerNames(game, request.PlayerIDs));
		UI.CreateLabel(vert).SetText('   ' .. RequestStatus(game, request));

		local row = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateButton(row).SetText('Accept').SetInteractable(not HaveWeAccepted(game, request)).SetOnClick(function() SendAccept(game, request, Close); end);
		UI.CreateButton(row).SetText('Decline').SetOnClick(function() SendDecline(game, request, Close); end);
	end
end

function ShowActions(vert, game)
	if (game.Us == nil) then
		UI.CreateLabel(vert).SetText("You can't change teams since you're not in this game.");
		return;
	end
	if (game.Us.State ~= WL.GamePlayerState.Playing) then
		UI.CreateLabel(vert).SetText("You can't change teams since you're no longer playing.");
		return;
	end

	if (GameHasCards(game.Settings)) then
		UI.CreateLabel(vert).SetText("Note: If you leave a team, the cards stay behind with your old teammates.");
	end

	UI.CreateButton(vert).SetText('Propose a team').SetOnClick(function() game.CreateDialog(CreateProposeDialog); end);

	if (TeamOfPlayer(game, game.Us.ID, game.LatestStanding) ~= NoTeam) then
		UI.CreateButton(vert).SetText('Leave my team').SetOnClick(function() SendUnteam(game, Close); end);
	end
end

function CreateProposeDialog(rootParent, setMaxSize, setScrollable, game, close)
	setMaxSize(450, 400);

	ProposeRoot = rootParent;
	ProposeClose = close;
	SelectedPlayerIDs = {};

	BuildProposeUI();
end

--Rebuilt from scratch every time the player adds or removes someone from the team they're putting together.
function BuildProposeUI()
	if (ProposeVert ~= nil and not UI.IsDestroyed(ProposeVert)) then
		UI.Destroy(ProposeVert);
	end

	ProposeVert = UI.CreateVerticalLayoutGroup(ProposeRoot).SetFlexibleWidth(1);

	UI.CreateLabel(ProposeVert).SetText('Choose exactly who should be on the team.  Everyone you name has to accept before it takes effect.');

	UI.CreateLabel(ProposeVert).SetText('The team will be:');
	UI.CreateLabel(ProposeVert).SetText(' - ' .. PlayerName(Game, Game.Us.ID) .. ' (you)');

	for _,playerID in ipairs(SelectedPlayerIDs) do
		local row = UI.CreateHorizontalLayoutGroup(ProposeVert);
		UI.CreateLabel(row).SetText(' - ' .. PlayerName(Game, playerID));
		UI.CreateButton(row).SetText('Remove').SetOnClick(function()
			SelectedPlayerIDs = filter(SelectedPlayerIDs, function(selected) return selected ~= playerID; end);
			BuildProposeUI();
		end);
	end

	if (count(SelectedPlayerIDs) == 0) then
		--A team of just yourself would be the same as leaving your team, so don't let them propose one.
		UI.CreateLabel(ProposeVert).SetText('Add at least one other player before proposing.');
	end

	UI.CreateButton(ProposeVert).SetText('Add player').SetOnClick(AddPlayerClicked);
	UI.CreateButton(ProposeVert).SetText('Propose team').SetInteractable(count(SelectedPlayerIDs) > 0).SetOnClick(SubmitPropose);
end

function AddPlayerClicked()
	local players = filter(Game.Game.PlayingPlayers, IsPotentialTeammate);

	if (count(players) == 0) then
		UI.Alert("There's nobody else you can add to the team.");
		return;
	end

	table.sort(players, function(a, b)
		return a.DisplayName(nil, false) < b.DisplayName(nil, false);
	end);

	UI.PromptFromList('Select a player to add to the team', map(players, PlayerButton));
end

--Determines if this is a player we can ask to join the team.
function IsPotentialTeammate(player)
	if (player.ID == Game.Us.ID) then return false; end; --we're always on the team we propose

	if (contains(SelectedPlayerIDs, player.ID)) then return false; end; --already on it

	if (player.State ~= WL.GamePlayerState.Playing) then return false; end; --skip players who aren't alive anymore, or that declined the game.

	--An AI would never respond to a proposal, so don't allow naming one in multi-player.  In single-player they accept automatically so the mod can be tried out.
	if (player.IsAIOrHumanTurnedIntoAI and not Game.Settings.SinglePlayer) then return false; end;

	return true;
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};

	if (WL.IsVersionOrHigher("5.41.0")) then
		ret["player"] = player.ID;
	else
		ret["text"] = name;
	end

	ret["selected"] = function()
		table.insert(SelectedPlayerIDs, player.ID);
		BuildProposeUI();
	end
	return ret;
end

function SubmitPropose()
	if (count(SelectedPlayerIDs) == 0) then
		UI.Alert("A team needs at least one other player on it.  If you want to leave the team you're on, close this and use \"Leave my team\" instead.");
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
		ProposeClose();
		Close();
	end

	SendTeamMessage(Game, 'Proposing team...', payload, closeBoth, function(returnValue)
		if (returnValue.Complete) then
			return 'The team of ' .. PlayerNames(Game, playerIDs) .. ' takes effect when the turn advances.';
		else
			return 'Your proposal was sent.  The team takes effect once everyone named in it accepts.';
		end
	end);
end

--dabo code
function Client_PresentMenuUI_dabo (rootParent, setMaxSize, setScrollable, game)
	showedreturnmessage = true;
	horzobjlist = {};
	TargetPlayerBtn = nil;
	declarebutton=nil;
	declarewarbutton=nil;
	textelem=nil;
	commitbutton =nil;
	offerpeacebutton = nil;
	offerallianzebutton = nil;
	pendingrequestbutton = nil;
	historybutton = nil;
	cancelallianzebutton = nil;
	SelectedData = {};
	Game = game;
	root = rootParent;
	horz = UI.CreateHorizontalLayoutGroup(root);
	-- setMaxSize(450, 350);
if(game.Us == nil) then
		vert = UI.CreateVerticalLayoutGroup(rootParent);
		UI.CreateLabel(vert).SetText("You cannot use the Diplomacy Mod, cause you aren't in the game");
		return;
	end
	if(Mod.PublicGameData.War ==nil)then
		UI.CreateLabel(horz).SetText("This menu is not avalible in distribution");
		return;
	end
	if(Mod.PublicGameData.War[game.Us.ID] ==nil)then
		UI.CreateLabel(horz).SetText("I identified a problem with the data structure of this mod. This could be based on the device you are running(it is a normal bug for some devices that run the standalone client). Try using a different device. If the bug consists, please contact the author of this mod(go to mod info and click the github link).");
		return;
	end
	print("Testlenght " .. tablelength(Mod.PublicGameData.War));
	for key,pd in pairs(Mod.PublicGameData.War)do
		print("Key(playerid out of Server_StartGame.lua: " .. key);
	end
	for _,pd in pairs(Game.Game.PlayingPlayers)do
		print("Playerid in  Client_PresentMenuUI.lua: " .. pd.ID);
		--if(Mod.PublicGameData.War[Game.Us.ID.."0"] == {} or Mod.PublicGameData.War[pd.ID .."0"] ~= nil)then
		--		print("Test" .. pd.ID);
		--end
	end
	if(game.Game.PlayingPlayers[game.Us.ID] == nil)then
		UI.CreateLabel(horz).SetText("You have been eliminated, so you are no longer able to interact with the mod");
		return;
	end
	mainmenu = UI.CreateButton(horz).SetText("Main Menu").SetOnClick(OpenMenu);
	vert = UI.CreateVerticalLayoutGroup(rootParent);
	OpenMenu(rootParent);
end
function OpenOfferPeace()
	DeleteUI();
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[0]).SetText("Offer peace to: ");
	TargetPlayerBtn = UI.CreateButton(horzobjlist[0]).SetText("Select player...").SetOnClick(TargetPlayerClickedOfferPeace);
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	commitbutton = UI.CreateButton(horzobjlist[1]).SetText("Offer").SetOnClick(commitofferpeace);
end
function commitofferpeace()
	local offerto = TargetPlayerBtn.GetText();
	if(offerto == "Select player...")then
		UI.Alert('You need to choose a player first');
	else
		local payload = {};
		payload.Message = "Peace";
		payload.TargetPlayerID = SelectedData[1];
		Game.SendGameCustomMessage("Sending request...", payload, function(returnvalue)
			showedreturnmessage = false;
			UI.Alert(returnvalue.Message);
			end);
		TargetPlayerBtn.SetText("Select player...");
	end
end
function TargetPlayerClickedOfferPeace()
	if(Mod.PublicGameData.War ~= nil and Mod.PublicGameData.War[Game.Us.ID] ~= nil)then--maybe unnessacary if(code in if still required)
		local options = {};
		for _,playerinstanze in pairs(Game.Game.PlayingPlayers)do
			for _,with in pairs(Mod.PublicGameData.War[Game.Us.ID])do
				if(tostring(with) == tostring(playerinstanze.ID))then
					table.insert(options,playerinstanze);
				end
			end
		end
		options = zusammen(options,PlayerButtonCustom,TargetPlayerBtn,1);
		UI.PromptFromList("Select the player you'd like to offer the peace to", options);
	end
end
function OpenhistoryMenu()
	DeleteUI();
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[0]).SetText("Public: red, Private: green (see mod description for explenation)");
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[1]).SetText("Mod history of this turn(to refresh it reopen the menu):");
	local historyamount = tablelength(Mod.PublicGameData.Historyorder);
	local number = 0;
	local locnumber = 0;
	while(number<historyamount)do
		if(Mod.PublicGameData.Historyorder[number] ~= nil)then
			local historyid = Mod.PublicGameData.Historyorder[number].ID;
			if(Mod.PublicGameData.Historyorder[number].Type == "Public")then
				horzobjlist[locnumber+2] = UI.CreateHorizontalLayoutGroup(root);
				local By =  Mod.PublicGameData.History[historyid].By;
				local Text =  Mod.PublicGameData.History[historyid].Text;
				textelem = UI.CreateLabel(horzobjlist[locnumber+2]).SetText(tostring(locnumber+1) .. " : " ..toname(By,Game) .. ":".. Text);
				textelem.SetColor('#ff0000');
				locnumber = locnumber + 1;
			else
				local spielerID =  Mod.PublicGameData.Historyorder[number].PlayerID;
				if(spielerID == Game.Us.ID)then
					horzobjlist[locnumber+2] = UI.CreateHorizontalLayoutGroup(root);
					local By = Mod.PlayerGameData.PrivateHistory[historyid].By;
					local Text = Mod.PlayerGameData.PrivateHistory[historyid].Text;
					textelem = UI.CreateLabel(horzobjlist[locnumber+2]).SetText(tostring(locnumber+1) .. " : " ..toname(By,Game) .. ":".. Text);
					textelem.SetColor('#00ff00');
					locnumber = locnumber + 1;
				end
			end
			number = number+1;
		end
	end
end
function OpenMenu()
	DeleteUI();
	declarewarbutton = UI.CreateButton(vert).SetText("Declare War").SetOnClick(OpenDeclarWar);
	offerpeacebutton = UI.CreateButton(vert).SetText("Offer Peace").SetOnClick(OpenOfferPeace);
	offerallianzebutton = UI.CreateButton(vert).SetText("Offer Alliance").SetOnClick(OpenOfferAlliance);
	cancelallianzebutton = UI.CreateButton(vert).SetText("Cancel Alliance").SetOnClick(OpenCancelAlliance);
	pendingrequestbutton = UI.CreateButton(vert).SetText("Pending Requests").SetOnClick(OpenPendingRequests);
	historybutton =  UI.CreateButton(vert).SetText("Mod History").SetOnClick(OpenhistoryMenu);
	--Disableing buttons that have no function due to the diplomacy and showing the diplomacy
	horzobjlist = {};
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	UI.CreateLabel(horzobjlist[0]).SetText("Your current diplomacy:");
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	horzobjlist[2] = UI.CreateVerticalLayoutGroup(root);
	local haswar = false;
	print(Game.Us.ID);
	if(Mod.PublicGameData.War~=nil and Mod.PublicGameData.War[Game.Us.ID]~=nil)then
		for _,with in pairs(Mod.PublicGameData.War[Game.Us.ID])do
			if(Game.Game.PlayingPlayers[with] ~= null)then
				UI.CreateLabel(horzobjlist[2]).SetText("-" .. toname(with,Game));
				haswar = true;
			end
		end
	end
	if(haswar == false)then
		UI.Destroy(horzobjlist[2]);
		horzobjlist[2] = nil;
		UI.CreateLabel(horzobjlist[1]).SetText("You are currently in war with no one.");
		offerpeacebutton.SetInteractable(false);
	else
		UI.CreateLabel(horzobjlist[1]).SetText("You are currently in war with the following player:");
		offerpeacebutton.SetInteractable(true);
	end
	horzobjlist[3] = UI.CreateHorizontalLayoutGroup(root);
	horzobjlist[4] = UI.CreateVerticalLayoutGroup(root);
	local foundpossibleally = false;
	local haspeace = false;
	for _,pd in pairs(Game.Game.PlayingPlayers)do
		if(pd.ID ~= Game.Us.ID)then
			local match2 = false;
			if(Mod.PublicGameData.War ~= nil and Mod.PublicGameData.War[Game.Us.ID] ~= nil)then
				for _,with in pairs(Mod.PublicGameData.War[Game.Us.ID])do
					if(with == pd.ID)then
						match2 = true;
					end
				end
				for _,with in pairs(Mod.PlayerGameData.Allianzen)do
					if(with == pd.ID)then
						match2 = true;
					end
				end
				if(match2 == false)then
					UI.CreateLabel(horzobjlist[4]).SetText("-" .. toname(pd.ID,Game));
					match = true;
					haspeace=true;
					if(pd.IsAI == false)then
						if(Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false)then 
							foundpossibleally=true;
						end
					end
				end
			end
		end
	end
	if(tablelength(Mod.PlayerGameData.Peaceoffers) == 0 and tablelength(Mod.PlayerGameData.AllyOffers)==0)then
		print(tablelength(Mod.PlayerGameData.Peaceoffers) .. " " .. tablelength(Mod.PlayerGameData.AllyOffers));
		pendingrequestbutton.SetInteractable(false);
	end
	if(haspeace)then
		UI.CreateLabel(horzobjlist[3]).SetText("You are currently in peace with the following player:");
		declarewarbutton.SetInteractable(true);
		offerallianzebutton.SetInteractable(true);
	else
		UI.CreateLabel(horzobjlist[3]).SetText("You are currently in peace with no one.");
		declarewarbutton.SetInteractable(false);
		offerallianzebutton.SetInteractable(false);
		UI.Destroy(horzobjlist[4]);
		horzobjlist[4] = nil;
	end
	if(foundpossibleally == false)then
		offerallianzebutton.SetInteractable(false);
	end
	horzobjlist[5] = UI.CreateHorizontalLayoutGroup(root);
	horzobjlist[6] = UI.CreateVerticalLayoutGroup(root);
	local hasalliance = false;
	for _,with in pairs(Mod.PlayerGameData.Allianzen)do
		if(Game.Game.PlayingPlayers[with] ~= null)then
			UI.CreateLabel(horzobjlist[6]).SetText("-" .. toname(with,Game));
			hasalliance = true;
		end
	end
	if(hasalliance)then
		UI.CreateLabel(horzobjlist[5]).SetText("You are currently allied with the following player:");
		cancelallianzebutton.SetInteractable(true);
	else
		UI.Destroy(horzobjlist[6]);
		horzobjlist[6] = nil;
		if(Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false)then 
			UI.CreateLabel(horzobjlist[5]).SetText("You are currently allied with no one.");
			cancelallianzebutton.SetInteractable(false);
		else
			UI.CreateLabel(horzobjlist[5]).SetText("The alliance system is disabled by settings.");
			cancelallianzebutton.SetInteractable(false);
		end
	end
end
function OpenCancelAlliance()
	DeleteUI();
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[0]).SetText("Cancel alliance with: ");
	TargetPlayerBtn = UI.CreateButton(horzobjlist[0]).SetText("Select player...").SetOnClick(TargetPlayerSelectCancelAlliance);
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	commitbutton = UI.CreateButton(horzobjlist[1]).SetText("Remove").SetOnClick(function()
			if(TargetPlayerBtn.GetText() == "Select player...")then
				UI.Alert('You need to choose a player first');
				return;
			end
			local cancelorder = WL.GameOrderCustom.Create(Game.Us.ID, "Cancel Alliance with " .. TargetPlayerBtn.GetText(), SelectedData[1]);
			local orders = Game.Orders;
			if(Game.Us.HasCommittedOrders == true)then
				UI.Alert("You need to uncommit first");
				return;
			end
			table.insert(orders, cancelorder);
			Game.Orders=orders;
		end);
end
function OpenOfferAlliance()
	DeleteUI();
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[0]).SetText("Offer Allianze To: ");
	TargetPlayerBtn = UI.CreateButton(horzobjlist[0]).SetText("Select player...").SetOnClick(TargetPlayerClickedOfferAllianze);
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	commitbutton = UI.CreateButton(horzobjlist[1]).SetText("Offer").SetOnClick(function()
			if(TargetPlayerBtn.GetText() == "Select player...")then
				UI.Alert('You need to choose a player first');
				return;
			end
			local payload = {};
			payload.Message = "Offer Allianze";
			payload.TargetPlayerID = SelectedData[1];
			Game.SendGameCustomMessage("Offering...", payload, function(returnvalue)	showedreturnmessage= false;UI.Alert(returnvalue.Message); end);
		end);
end
function TargetPlayerSelectCancelAlliance()
	local options = {};
	local match = false;
	for _,playerinstanze in pairs(Game.Game.PlayingPlayers)do
		for _,with in pairs(Mod.PlayerGameData.Allianzen)do
			if(with == playerinstanze.ID)then
				table.insert(options,playerinstanze);
				match = true;
			end
		end
	end
	if(match == false)then
		UI.Alert('You are not able to ally to anyone at the moment');
	else
		options = zusammen(options,PlayerButtonCustom,TargetPlayerBtn,1);
		UI.PromptFromList("Select the player you'd like to cancel the alliance with", options);
	end
end
function TargetPlayerClickedOfferAllianze()
	local options = {};
	local match2 = false;
	for _,playerinstanze in pairs(Game.Game.PlayingPlayers)do
		local match = false;
		for _,with in pairs(Mod.PublicGameData.War[Game.Us.ID])do
			if(with == playerinstanze.ID)then
				match=true;
			end
		end
		for _,with in pairs(Mod.PlayerGameData.Allianzen)do
			if(with == playerinstanze.ID)then
				match=true;
			end
		end
		if(match == false)then
			if(playerinstanze.IsAI == false and playerinstanze.ID ~= Game.Us.ID)then
				match2 = true;
				table.insert(options,playerinstanze);
			end
		end
	end
	if(match2 == false)then
		UI.Alert('You are not able to ally to anyone at the moment');
	else
		options = zusammen(options,PlayerButtonCustom,TargetPlayerBtn,1);
		UI.PromptFromList("Select the player you'd like to offer an allianze to", options);
	end
end
function OpenPendingRequests()
	DeleteUI();
	local haspeaceoffer = false;
	local hasallyoffer = false;
	if(haspeaceoffer == true)then
		ShowPeaceOffers();
	end
	if(hasallyoffer == true)then
		ShowTerritorySellOffers();
	end
	if(haspeaceoffer == false)then
		ShowPeaceOffers();
	end
	if(hasallyoffer == false)then
		ShowAllyOffers();
	end
end
function ShowPeaceOffers()
	horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
	UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText("Peace Offers");
	local hasoffer =false;
	for _,offer in pairs(Mod.PlayerGameData.Peaceoffers)do
		hasoffer = true;
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText(toname(offer.Offerby,Game) .. " offers you peace");
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		button = UI.CreateButton(horzobjlist[tablelength(horzobjlist)-1]).SetText("Deny");
		local onclick=function()
			local payload = {};
			payload.Message = "Decline Peace";
			payload.Spieler = offer.Offerby;
			AcceptPeaceOffer(payload);
			end;
		button.SetOnClick(onclick);
		button = UI.CreateButton(horzobjlist[tablelength(horzobjlist)-1]).SetText("Accept");
		local onclick2=function()
			local payload = {};
			payload.Message = "Accept Peace";
			payload.Spieler = offer.Offerby;
			AcceptPeaceOffer(payload);
			end;
		button.SetOnClick(onclick2);
	end
	if(hasoffer == false)then
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText("You have no peace offers");
	end
end
function ShowAllyOffers()
	horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
	UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText("Ally Offers");
	local hasoffer =false;
	for _,offer in pairs(Mod.PlayerGameData.AllyOffers)do
		hasoffer = true;
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText(toname(offer.OfferedBy,Game) .. " offers you an alliance");
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		button = UI.CreateButton(horzobjlist[tablelength(horzobjlist)-1]).SetText("Deny");
		local onclick=function()
			local payload = {};
			payload.Message = "Deny Allianze";
			payload.OfferedBy = offer.OfferedBy;
			Game.SendGameCustomMessage("Sending data...", payload, function(returnvalue)	showedreturnmessage=false;UI.Alert(returnvalue.Message); end);
			OpenPendingRequests();
			end;
		button.SetOnClick(onclick);
		button = UI.CreateButton(horzobjlist[tablelength(horzobjlist)-1]).SetText("Accept");
		local onclick2=function()
			local payload = {};
			payload.Message = "Accept Allianze";
			payload.OfferedBy = offer.OfferedBy;
			Game.SendGameCustomMessage("Sending data...", payload, function(returnvalue)	showedreturnmessage=false;UI.Alert(returnvalue.Message); end);
			OpenPendingRequests();
			end;
		button.SetOnClick(onclick2);
	end
	if(hasoffer == false)then
		horzobjlist[tablelength(horzobjlist)] = UI.CreateHorizontalLayoutGroup(root);
		if(Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false)then
			UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText("You have no alliance offer");
		else
			UI.CreateLabel(horzobjlist[tablelength(horzobjlist)-1]).SetText("Alliance system got per settings disabled");
		end
	end
end
function AcceptPeaceOffer(data)
	local payload = {};
	payload.Message = data.Message;
	payload.TargetPlayerID = data.Spieler;
	Game.SendGameCustomMessage("Sending data...", payload, function(returnvalue)	
		showedreturnmessage = false;
		UI.Alert(returnvalue.Message);
	end);
	OpenPendingRequests();
end
function toname(playerid,game)
	return game.Game.Players[tonumber(playerid)].DisplayName(nil, false);
end
function OpenDeclarWar()
	DeleteUI();
	horzobjlist[0] = UI.CreateHorizontalLayoutGroup(root);
	textelem = UI.CreateLabel(horzobjlist[0]).SetText("Declare war on: ");
	TargetPlayerBtn = UI.CreateButton(horzobjlist[0]).SetText("Select player...").SetOnClick(TargetPlayerClickedDeclareWar);
	horzobjlist[1] = UI.CreateHorizontalLayoutGroup(root);
	commitbutton = UI.CreateButton(horzobjlist[1]).SetText("Declare").SetOnClick(declare);
end
function TargetPlayerClickedDeclareWar()
	local options = {};
	for _,playerinstanze in pairs(Game.Game.PlayingPlayers)do
		local Match = false;
		for _,with in pairs(Mod.PublicGameData.War[Game.Us.ID])do
			if(with == playerinstanze.ID)then
				Match = true;
			end
		end
		for _,with in pairs(Mod.PlayerGameData.Allianzen)do
			if(with == playerinstanze.ID)then
				Match = true;
			end
		end
		if(Match == false)then
			if(playerinstanze.ID ~= Game.Us.ID)then
			--don't add, if already declare order existing
				if(ContainsDeclareWarOrder(playerinstanze.ID) == false)then
					table.insert(options,playerinstanze);
				end
			end
		end
	end
	options = zusammen(options,PlayerButtonCustom,TargetPlayerBtn,1);
	UI.PromptFromList("Select the player you'd like to declare war on", options);
end
function ContainsDeclareWarOrder(playerid)
	local gameorders = Game.Orders;
	for _,order in pairs(gameorders)do
		if(order.proxyType == "GameOrderCustom")then
			if(order.Payload == tostring(playerid))then
				return true;
			end
		end
	end
	return false;
end
function declare()
	local declareon = TargetPlayerBtn.GetText();
	local orders = Game.Orders;
	local myID = Game.Us.ID;
	if(declareon == "Select player...")then
		UI.Alert('You need to choose a player first');
		return;
	end
	if(Game.Us.HasCommittedOrders == true)then
		UI.Alert("You need to uncommit first");
		return;
	end
	table.insert(orders, WL.GameOrderCustom.Create(myID, "Declared war on " .. declareon, SelectedData[1]));
	Game.Orders = orders;
	TargetPlayerBtn.SetText("Select player...");
end
function getplayerid(playername,game)
	for _,playerinfo in pairs(game.Game.Players)do
		local name = playerinfo.DisplayName(nil, false);
		if(name == playername)then
			return playerinfo.ID;
		end
	end
	return 0;
end
function zusammen(array, func,knopf,knopfid)
	local new_array = {};
	local i = 1;
	for _,v in pairs(array) do
		new_array[i] = func(v,knopf,knopfid);
		i = i + 1;
	end
	return new_array;
end
function PlayerButtonCustom(player,knopf,knopfid)
	local ret = {};
	ret["text"] = toname(player.ID,Game);
	ret["selected"] = function() 
		SelectedData[knopfid] = player.ID;
		knopf.SetText(ret["text"]);
	end
	return ret;
end
function DeleteUI()
	if(textelem ~= nil)then
		UI.Destroy(textelem);
		textelem = nil;
	end
	if(TargetPlayerBtn ~= nil)then
		UI.Destroy(TargetPlayerBtn);
		TargetPlayerBtn = nil;
	end
	if(commitbutton ~= nil)then
		UI.Destroy(commitbutton);
		commitbutton = nil;
	end
	if(declarewarbutton ~= nil)then
		UI.Destroy(declarewarbutton);
		declarewarbutton = nil;
	end
	if(offerpeacebutton ~= nil)then
		UI.Destroy(offerpeacebutton);
		offerpeacebutton = nil;
	end
	if(offerallianzebutton ~= nil)then
		UI.Destroy(offerallianzebutton);
		offerallianzebutton = nil;
	end
	if(pendingrequestbutton ~= nil)then
		UI.Destroy(pendingrequestbutton);
		pendingrequestbutton = nil;
	end
	if(cancelallianzebutton ~= nil)then
		UI.Destroy(cancelallianzebutton);
		cancelallianzebutton = nil;
	end
	if(historybutton ~= nil)then
		UI.Destroy(historybutton);
		historybutton = nil;
	end
	for _,horzobj in pairs(horzobjlist)do
		UI.Destroy(horzobj);
	end
	horzobjlist = {};
end
function  tablelength(T)
	local count = 0;
	if(T==nil)then
		return 0;
	end
	for _, elem in pairs(T)do
		count = count + 1;
	end
	return count;
end
