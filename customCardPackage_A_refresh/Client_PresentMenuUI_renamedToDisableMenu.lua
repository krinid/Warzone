function Client_PresentMenuUI(RootParent, setMaxSize, setScrollable, game, close)
	--deprecated, no longer required b/c they are actual cards that can be played normally w/o having to use the game/mod menu
end

function Client_PresentMenuUI_dabo1 (RootParent, setMaxSize, setScrollable, game, close)
	print ("[PresentMenuUI] CARD OVERVIEW");

	if game == nil then 		print('ClientGame is nil'); 	end
	if game.LatestStanding == nil then 		print('ClientGame.LatestStanding is nil'); 	end
	if game.LatestStanding.Cards == nil then 		print('ClientGame.LatestStanding.Cards is nil'); 	end
	if game.Us == nil then 		print('ClientGame.Us is nil'); 	end
	if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end
	--if game.game == nil then 		print('ClientGame.game is nil'); 	end
	--if game.game.Settings == nil then 		print('ClientGame.game.Settings is nil'); 	end
	--if game.game.Settings.Cards == nil then 		print('ClientGame.game.Settings.Cards is nil'); 	end
	print ("player="..game.Us.PlayerID.."::name="..game.Us.DisplayName(nil, false).."::team="..game.Us.Team.."::");

	for playerId, playerCards in pairs(game.LatestStanding.Cards) do
	--for playerId, playerCards in pairs(game.ServerGame.LatestTurnStanding.Cards) do
		local player = game.Us;
		--local player = game.LatestStanding.PlayingPlayers[playerId];
		--local player = game.ServerGame.Game.PlayingPlayers[playerId];

		print ("[[OBJECT PROPERTIES]]")
		printObjectDetails (playerCards, "playerCards");

		for cardId, numPieces in pairs(playerCards.Pieces) do
				print ("CARD PIECE id="..cardId..":: numPieces="..numPieces.."::");
		end
		--for cardId2, numWholeCards in pairs(playerCards.WholeCards) do
		--	print ("CARD id="..cardId2..":: numWholeCards="..numWholeCards.."::");
		--end
		for _, cardInstance in pairs(playerCards.WholeCards) do
			local cardId2 = cardInstance.CardID;
			local numWholeCards;
			print ("WHOLE CARD id="..cardId2.."::");--" numWholeCards="..numWholeCards.."::");
			printObjectDetails (cardInstance, "WHOLE CARD");
			--printObjectDetails (cardInstance.readableKeys, "WHOLE CARD - readable keys");
			--printObjectDetails (cardInstance.writableKeys, "WHOLE CARD - readable keys");
		end

	--[[if player then
			for cardId, numPieces in pairs(playerCards.Pieces) do
				if player.Team == -1 then
					--clone.noTeam[playerId].currentCardPieces[cardId] = numPieces;
					print ("CARD id="..cardID.."::");-- numPieces="..numPieces.."::");
					print ("CARD id="..cardID..":: numPieces="..numPieces.."::");
					-- game.Settings.Cards[cardId].name);-- .."::#cards="	..numPieces.."::");
				else
					--clone.teamed[player.Team].currentCardPieces[cardId] = (clone.teamed[player.Team].currentCardPieces[cardId] or 0) + numPieces;
				end
			end]]

			--[[for _, cardInstance in pairs(playerCards.WholeCards) do
				local cardId = cardInstance.CardID;
				local numPieces = game.Settings.Cards[cardId].NumPieces;

				if player.Team == -1 then
					clone.noTeam[playerId].currentCardPieces[cardId] = (clone.noTeam[playerId].currentCardPieces[cardId] or 0) + numPieces;
				else
					clone.teamed[player.Team].currentCardPieces[cardId] = (clone.teamed[player.Team].currentCardPieces[cardId] or 0) + numPieces;
				end
			end
		end]]
	end

	if(game.Us==nil)then
		UI.Alert('Spectators can not play cards');
		return;
	end
	if(Mod.PlayerGameData.PestCards == nil and Mod.PlayerGameData.NukeCards == nil and Mod.PlayerGameData.IsolationCards == nil)then
		UI.Alert('You cannot play cards during distribution');
		return;
	end
	rootParent=RootParent;
  	Game=game;
  	vertPestCard=nil;
  	PestCards=Mod.PlayerGameData.PestCards;
  	if(PestCards==nil)then
  	 	PestCards=0;
  	end
	NukeCards = -1;
	if(Mod.PlayerGameData.NukeCards~=nil)then
		NukeCards=Mod.PlayerGameData.NukeCards;
  		if(PestCards==nil)then
   			NukeCards=0;
  		end
	end
	IsolationCards=Mod.PlayerGameData.IsolationCards;
	if(IsolationCards==nil)then
  	 	IsolationCards=0;
  	end
	ShowFirstMenu();
  	setMaxSize(450, 350);
end

function printObjectDetails (object, strObjectName)
	print ("[PresentMenuUI] object="..strObjectName.."::");
	for _, value in pairs(object.readableKeys) do
        print("**"..value, tostring(object[value]).."::");
    end
	for _, value in pairs(object.writableKeys) do
        print("!!"..value, tostring(object[value]).."::");
    end
	for key, value in pairs(object) do
        print("##"..key.."::", value.."::");
    end
end

function ShowFirstMenu()
	if(Mod.Settings.PestCardIn)then
		PestCardsPlayed=0;
		for _,order in pairs(Game.Orders) do
			if(order.proxyType=="GameOrderCustom")then
				if(order.Payload~=nil)then
					if(split(order.Payload,'|')[1]=='Pestilence')then
						PestCardsPlayed=PestCardsPlayed+1;
					end
				end
			end
	  	end
		PestCardsFree=PestCards-PestCardsPlayed;
    		vertPest=UI.CreateVerticalLayoutGroup(rootParent);
    		PestText0=UI.CreateLabel(vertPest).SetText('Pestilence Card: ');
    		PestText1=UI.CreateLabel(vertPest).SetText('      You have '..tostring(PestCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.PestCardPieces)..'/'..Mod.Settings.PestCardPiecesNeeded..' Pieces.');
    		if(PestCardsFree>0)then
      			PestButton1=UI.CreateButton(vertPest).SetText('Play Pestilence Card').SetOnClick(PlayPestCard);
    		end
  	end
	if(Mod.Settings.NukeEnabled ~= nil and Mod.Settings.NukeEnabled)then
		if(NukeCards == -1)then
			UI.Alert('There is a bug. Please reload the game.');
		end
		NukeCardsPlayed=0;
		for _,order in pairs(Game.Orders) do
			if(order.proxyType=="GameOrderCustom")then
				if(order.Payload~=nil)then
					if(split(order.Payload,'|')[1]=='Nuke')then
						NukeCardsPlayed=NukeCardsPlayed+1;
					end
				end
			end
	  	end
	  	NukeCardsFree=NukeCards-NukeCardsPlayed;
    	  	vertNuke=UI.CreateVerticalLayoutGroup(rootParent);
          	NukeText0=UI.CreateLabel(vertNuke).SetText('Nuke Card: ');
          	NukeText1=UI.CreateLabel(vertNuke).SetText('      You have '..tostring(NukeCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.NukeCardPieces)..'/'..Mod.Settings.NukeCardPiecesNeeded..' Pieces.');
		if(NukeCardsFree>0)then
    			NukeButton1=UI.CreateButton(vertNuke).SetText('Play Nuke Card').SetOnClick(PlayNukeCard);
    	 	end
   	end
	if(Mod.Settings.IsolationEnabled)then
		IsolationCardsPlayed=0;
		for _,order in pairs(Game.Orders) do
			if(order.proxyType=="GameOrderCustom")then
				if(order.Payload~=nil)then
					if(split(order.Payload,'|')[1]=='Isolation')then
						IsolationCardsPlayed=IsolationCardsPlayed+1;
					end
				end
			end
	  	end
		IsolationCardsFree=IsolationCards-IsolationCardsPlayed;
    		vertIsolation=UI.CreateVerticalLayoutGroup(rootParent);
    		IsolationText0=UI.CreateLabel(vertIsolation).SetText('Isolation Card: ');
    		IsolationText1=UI.CreateLabel(vertIsolation).SetText('      You have '..tostring(IsolationCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.IsolationCardPieces)..'/'..Mod.Settings.IsolationPiecesNeeded..' Pieces.');
    		if(IsolationCardsFree>0)then
      			IsolationButton1=UI.CreateButton(vertIsolation).SetText('Play Isolation Card').SetOnClick(PlayIsolationCard);
    		end
  	end
end

function PlayNukeCard()
	if(Game.Us.HasCommittedOrders == true)then
		UI.Alert("You need to uncommit first");
		return;
	end
	options = map(Game.Map.Territories,SelectTerritory);
	UI.PromptFromList("Select the territory, you'd like to nuke", options);
	--new Fizz method: SelectTerritoryClicked(); --just start us immediately in selection mode, no reason to require them to click the button

	--local orders = Game.Orders;
	--table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, "[player] nukes " .. name, 'Nuke|'..terr.ID));

	--[[
	local name = terr.Name;
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function() 
		local orders = Game.Orders;
		table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, "[player] nukes " .. name, 'Nuke|'..terr.ID));
		NukeCardsFree=NukeCardsFree-1;
		if(NukeCardsFree == 0)then
			UI.Destroy(NukeButton1);
		end
		NukeText1.SetText('      You have got '..tostring(NukeCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.NukeCardPieces)..'/'..Mod.Settings.NukeCardPiecesNeeded..' Pieces.');
		Game.Orders = orders;
	end
	return ret;
	]]
end

--[[fizz funcs
function PresentBuyTankDialog(rootParent, setMaxSize, setScrollable, game, close)
	Close2 = close;

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel

	SelectTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

	BuyTankBtn = UI.CreateButton(vert).SetInteractable(false).SetText("Complete Purchase").SetOnClick(CompletePurchaseClicked);

	SelectTerritoryClicked(); --just start us immediately in selection mode, no reason to require them to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	TargetTerritoryInstructionLabel.SetText("Please click on the territory you wish to receive the tank on.  If needed, you can move this dialog out of the way.");
	SelectTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	SelectTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		SelectedTerritory = nil;
		BuyTankBtn.SetInteractable(false);
	else
		--Territory was clicked, check it
		if (Game.LatestStanding.Territories[terrDetails.ID].OwnerPlayerID ~= Game.Us.ID) then
			TargetTerritoryInstructionLabel.SetText("You may only receive a tank on a territory you own.  Please try again.");
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
			SelectedTerritory = terrDetails;
			BuyTankBtn.SetInteractable(true);
		end
	end
end
]]

function SelectTerritory(terr)
	local name = terr.Name;
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function() 
		local orders = Game.Orders;
		table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, "Nuke " .. name, 'Nuke|'..terr.ID)); --&&&
		print ("[legacy PLACE ORDER] Nuke " .. name, 'Nuke|'..terr.ID.."::");
		NukeCardsFree=NukeCardsFree-1;
		if(NukeCardsFree == 0)then
			UI.Destroy(NukeButton1);
		end
		--game.LatestTurnStanding.Cards
		NukeText1.SetText('You have '..tostring(NukeCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.NukeCardPieces)..'/'..Mod.Settings.NukeCardPiecesNeeded..' Pieces.');

		local clone = {
			teamed = {},
			noTeam = {}
		};
	
		Game.Orders = orders;
	end
	return ret;
end

function PlayIsolationCard()
	if(Game.Us.HasCommittedOrders == true)then
		UI.Alert("You need to uncommit first");
		return;
	end
	options = map(Game.Map.Territories,SelectTerritoryIso);
	UI.PromptFromList("Select the territory to be isolated.", options);
end
function SelectTerritoryIso(terr)
	local name = terr.Name;
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function() 
		local orders = Game.Orders;
		table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, "Play an Isolation Card on " .. name, 'Isolation|'..terr.ID));
		IsolationCardsFree=IsolationCardsFree-1;
		if(IsolationCardsFree == 0)then
			UI.Destroy(IsolationButton1);
		end
		IsolationText1.SetText('      You have got '..tostring(IsolationCardsFree)..' Cards and '..tostring(Mod.PlayerGameData.IsolationCardPieces)..'/'..Mod.Settings.IsolationPiecesNeeded..' Pieces.');
		Game.Orders = orders;
	end
	return ret;
end


function PlayPestCard()
	if(Game.Us.HasCommittedOrders == true)then
		UI.Alert("You need to uncommit first");
		return;
	end
	ClearUI();
	vertPestCard=UI.CreateVerticalLayoutGroup(rootParent);
	PestCardText0=UI.CreateLabel(vertPestCard).SetText('Select the player you want to play the Card on. Players who are already pestilenced will not be shown. Dont play 2 cards on one player, they are not stackable.');
	local Pestfuncs={};
	for playerID in pairs(Game.Game.Players) do
		if(playerID~=Game.Us.ID)then
     			if(Mod.PublicGameData.PestilenceStadium[playerID]~=nil)then
				if(Mod.PublicGameData.PestilenceStadium[playerID]==0)then
      					local locPlayerID=playerID;
      					Pestfuncs[playerID]=function() Pestilence(locPlayerID); end;
      					local pestPlayerButton = UI.CreateButton(vertPestCard).SetText(toname(playerID,Game)).SetOnClick(Pestfuncs[playerID]);
    				end
			else
				local locPlayerID=playerID;
      				Pestfuncs[playerID]=function() Pestilence(locPlayerID); end;
      				local pestPlayerButton = UI.CreateButton(vertPestCard).SetText(toname(playerID,Game)).SetOnClick(Pestfuncs[playerID]);
			end
		end
	end
end

function Pestilence(playerID)
	ClearUI();
	orders=Game.Orders;
	--Game.SendGameCustomMessage('Waiting for the server to respond...',{PestCardPlayer=playerID},PestCardPlayedCallback);
	table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, "Play a Pestilence Card on " .. toname(playerID,Game), 'Pestilence|'..tostring(playerID)));
	Game.Orders=orders;
	ShowFirstMenu();
end

function PestCardPlayedCallback()
	ShowFirstMenu();
end

function ClearUI()
	if(vertPest~=nil)then
		UI.Destroy(vertPest);
		vertPest = nil;
	end
	if(vertNuke~=nil)then
		UI.Destroy(vertNuke);
		vertNuke = nil;
	end
	if(vertPestCard~=nil)then
		UI.Destroy(vertPestCard);
		vertPestCard=nil;
	end
end

---------------------------------------------
---------------------------------------------
----                                     ----
----         COMFORT FUNCTIONS           ----
----                                     ----
---------------------------------------------
---------------------------------------------

function Contains(array,object)
	for obj in pairs(array) do
		if(obj==object)then
			return true;
		end
	end
	return false;
end

function toname(playerid,game)
	for _,playerinfo in pairs(game.Game.Players)do
		if(playerid == playerinfo.ID)then
			return playerinfo.DisplayName(nil, false);
		end
	end
	return "Error - Player ID not found. Please report to melwei[PG].";
end
function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end
function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end
function map(array, func)
	local new_array = {};
	local i = 1;
	for _,v in pairs(array) do
		new_array[i] = func(v);
		i = i + 1;
	end
	return new_array;
end
