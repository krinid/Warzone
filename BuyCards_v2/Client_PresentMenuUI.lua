function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	Game = game;
	root = rootParent;
	vert = UI.CreateVerticalLayoutGroup(root);
	setMaxSize(400, 400);
	if (game.Settings.CommerceGame == false) then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("This mod cannot function in this game because it is not a Commerce game");
		return;
	end
	if(game.Us == nil) then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("You are not playing in this game, so menu is disabled");
		return;
	end
	if(game.Game.PlayingPlayers[game.Us.ID] == nil)then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("You have been eliminated, so menu is disabled");
		return;
	end

	getDefinedCardList (game);
	displayMenu (game, close);
end

function displayMenu (game, close)
	--showDefinedCards (Game);
	local publicGameData = Mod.PublicGameData;
	local localPlayerIsHost = game.Us.ID == game.Settings.StartedBy;
	--local buttonsCardPurchases = {};  --originally had these assigned but aren't actually using them, but leave them around until I'm sure they won't be required
	local sliderCardPrices = {};

	--delme delme delme -- for testing purposes only
	--localPlayerIsHost = false;
	--delme delme delme -- for testing purposes only

	local vertHeader = UI.CreateVerticalLayoutGroup(root).SetFlexibleWidth (1);
	UI.CreateLabel (vertHeader).SetText ("[BUY CARDS]\n\n").SetColor (getColourCode("card play heading"));
	--[[UI.CreateLabel (vertHeader).SetText ("Turn #"..game.Game.TurnNumber);
	UI.CreateLabel (vertHeader).SetText ("Prices have been finalized == ".. tostring (publicGameData.CardData.CardPricesFinalized));
	UI.CreateLabel (vertHeader).SetText ("Host has updated pricing == " .. tostring (publicGameData.CardData.HostHasAdjustedPricing));]]
	print ("[BUY CARDS] Turn #"..game.Game.TurnNumber);
	print ("Prices have been finalized == ".. tostring (publicGameData.CardData.CardPricesFinalized));
	print ("Host has updated pricing == " .. tostring (publicGameData.CardData.HostHasAdjustedPricing));

	DebugWindow = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	UI.CreateLabel (DebugWindow).SetText ("- - - - - [DEBUG DATA START] - - - - -");
    UI.CreateLabel (DebugWindow).SetText ("Server time: "..game.Game.ServerTime);

	if (game.Us~=nil) then --a player in the game
		--UI.CreateLabel (DebugWindow).SetText ("text \n\nClient player");
		UI.CreateLabel (DebugWindow).SetText ("Client player "..game.Us.ID .."/"..toPlayerName (game.Us.ID, game)..", State: "..tostring(game.Game.Players[game.Us.ID].State).."/"..tostring(WLplayerStates ()[game.Game.Players[game.Us.ID].State]).. ", IsActive: "..tostring(game.Game.Players[game.Us.ID].State == WL.GamePlayerState.Playing).. ", IsHost: "..tostring(localPlayerIsHost));
	else
		--client local player is a Spectator, don't reference game.Us which ==nil
		UI.CreateLabel (DebugWindow).SetText ("Client player is Spectator");
	end

	UI.CreateLabel (DebugWindow).SetText ("\nGame host: "..game.Settings.StartedBy.."/".. toPlayerName(game.Settings.StartedBy, game));

	UI.CreateLabel (DebugWindow).SetText ("\nPlayers in the game:");
	for k,v in pairs (game.Game.Players) do
		local strPlayerIsHost = "";
		if (localPlayerIsHost) then strPlayerIsHost = " [HOST]"; end
		UI.CreateLabel (DebugWindow).SetText ("   Player "..k .."/"..toPlayerName (k, game)..", State: "..tostring(v.State).."/"..tostring(WLplayerStates ()[v.State]).. ", IsActive: "..tostring(game.Game.Players[k].State == WL.GamePlayerState.Playing) .. ", IsHost: "..tostring (k == game.Settings.StartedBy));
	end
	UI.CreateLabel (DebugWindow).SetText ("- - - - - [DEBUG DATA END] - - - - -");

	local cardCount = 0;
	local strUpdateButtonText = "Update Prices";
	
	--if local client player is host, allow price changes until end of T1
	if (publicGameData.CardData.CardPricesFinalized == false) then
		if (localPlayerIsHost==true) then
			local newCards = {};
			local strMessageToHost;
			if (publicGameData.CardData.HostHasAdjustedPricing == false) then
				strMessageToHost = "You are the game host and card prices have not been updated yet!"
			else
				strMessageToHost = "You are the game host. Card prices have been updated already, but you are able to re-update them until the turn advances."
				strUpdateButtonText = "Re-update Prices";
			end
			strMessageToHost = strMessageToHost .. "\n\nDefault prices have been assigned to custom cards - be sure to confirm and change them to align with your goals for this game."

			--Turn #0 = distribution phase (during Manual Distribution games; else for Auto-Dist games this function is called when it is already turn 1)
			if (game.Game.TurnNumber == 0) then
				strMessageToHost = strMessageToHost .."\n\nIf you set them this turn during the Distribution Phase, players will be able to buy cards starting from tun 1. If not, you will have until the end of Turn 1 to finalize the prices, after which they will be automatically finalized with their default values, but players won't be able to buy cards until turn 2.";
			else
				strMessageToHost = strMessageToHost .."\n\nYou must finalize the card prices this turn, else they will be automatically finalized with their default values when the turn advances. Players will be able to buy the cards starting from turn 2.";
			end

			--originally had a popup displaying alternate message after host applied prices, but just let it be quiet; if the host did the job already, don't harass him anymore with popups
			if (publicGameData.CardData.HostHasAdjustedPricing == false) then UI.Alert (strMessageToHost); end;

			if (publicGameData.CardData.HostHasAdjustedPricing == false) then
				UI.CreateLabel (vertHeader).SetText ("You are the game host and card prices have not been updated yet! Update the prices of all cards and click 'Update Prices' when finished.").SetColor ("#FF0000"); -- display in red!
			else
				UI.CreateLabel (vertHeader).SetText ("You are the game host. Card prices have been updated already, but you are able to re-update them until the turn advances."); -- display in standard colour
			end

			UpdateButton = UI.CreateButton(vertHeader).SetText (strUpdateButtonText).SetOnClick (
			function ()
				local cardCount = 0;
				for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
					cardCount = cardCount + 1;
					print (cardRecord.ID .."/" .. cardRecord.Name..", " ..cardRecord.Price.. "" ..", change to new price "..sliderCardPrices [cardCount].GetValue ());
					--for reference: publicGameData.CardData.DefinedCards [cardRecord.ID] = {Name=cardRecord.Name, Price=sliderCardPrices [cardCount].GetValue (), ID=cardID};
					newCards [cardRecord.ID] = {Name=cardRecord.Name, Price=sliderCardPrices [cardCount].GetValue (), ID=cardID};
					UI.Alert ("New card prices have been saved. When the turn advances, players will become available to buy cards at these new prices.");
				end
				--Mod.PublicGameData = publicGameData; --save the new values  <---- can't do this b/c this is a Client hook
				--this is a Client hook, so can't write to PublicGameData
				--instead use game.SendGameCustomMessage to send the updated PublicGameData table to Server_GameCustomMessage and save the updated card prices there
				publicGameData.CardData.HostHasAdjustedPricing = true; --signify that host has updated pricing; prices will be finalized when either Server_StartGame (if set during Distribution of a Manual Dist game) or when Server_TurnAdvance_End is called (for either Manual Dist or Auto-Dist game)
				publicGameData.CardData.DefinedCards = newCards;
				game.SendGameCustomMessage ("[waiting for server response]", publicGameData, function () end);
				UpdateButton.SetText ("Prices have been updated");
				
				--destroy the existing window & recreate it to refresh the content
				close (); --close the entire Client_PresentMenuUI window; originally just destroyed the vert container and refreshed it, but the server call to refresh public data took longer than the refresh did, so it didn't recognize the price update operation and nagged the host again
				--so just close the window and let the player re-open it if they want to go back in
			end);
		else --client player is not host, so display a message indicating that the host has not finalized the prices
			UI.CreateLabel (vertHeader).SetText ("The game host (".. toPlayerName(game.Settings.StartedBy, game) ..") has not finalized card prices yet. If they are finalized by end of this turn, you can buy cards starting next turn.").SetColor ("#FF0000");
			UI.CreateLabel (vertHeader).SetText ("\nDefault card prices are shown below. They may change next turn once the host finalizes the prices.");
		end
		UI.CreateLabel (vertHeader).SetText (" "); --empty label for visual vertical spacing
	end
	
	local vertRegularCards = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	UI.CreateLabel (vertRegularCards).SetText ("Regular cards:").SetColor (getColourCode("subheading"));
	local vertCustomCards = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	UI.CreateLabel (vertCustomCards).SetText ("\nCustom cards:").SetColor (getColourCode("subheading"));

	local cardCount = 0;
	local cardCountRegular = 0;
	local cardCountCustom = 0;
	for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
		cardCount = cardCount + 1;
		--regular cards go in the Vert area and are listed at the top
		--custom cards go in the Vert area and are listed at the bottom
		--if client player is host & cards aren't finalized, then add sliders and use a horizontal layout group to organize the labels & sliders -- but don't use hori groups for non-host players b/c it adds unnecessary vertical space and less buttons fit on a single viewing window
		local targetUI = vertRegularCards;
		
		-- this is a custom card; custom cards are >=1000000
		if (cardRecord.ID >= 1000000) then
			targetUI = vertCustomCards;
			cardCountCustom = cardCountCustom + 1;
		else --this is a regular card; regular cards are <1000000
			cardCountRegular = cardCountRegular + 1;
		end 
		local interactable = ((cardRecord.Price>=1) and (publicGameData.CardData.CardPricesFinalized==true)); --set .SetInteractable of the buttons to this value; set to True when prices have been finalized, otherwise False; if card price<=0 then make non-interactive (can't buy cards that cost 0 or negative)
		if (localPlayerIsHost==true and publicGameData.CardData.CardPricesFinalized == false) then targetUI = UI.CreateHorizontalLayoutGroup (targetUI); end
		
		--only display a card in the list if (A) prices aren't finalized, or (B) the prices is >0; if it's not available for purchase, just don't show it in the list
		if (cardRecord.Price>0 or publicGameData.CardData.CardPricesFinalized == false) then
			UI.CreateButton(targetUI).SetPreferredWidth(540).SetFlexibleWidth (1).SetInteractable(interactable).SetText("Buy "..cardRecord.Name .." for " .. cardRecord.Price).SetOnClick(function() purchaseCard (cardRecord); end);
		end 

		--if client player is the host & prices aren't finalized, show a slider to be able to set the card price
		if (localPlayerIsHost==true and publicGameData.CardData.CardPricesFinalized == false) then
			sliderCardPrices [cardCount] = UI.CreateNumberInputField(targetUI).SetSliderMinValue(1).SetSliderMaxValue(1000).SetValue(cardRecord.Price).SetPreferredWidth(25).SetFlexibleWidth (1).SetWholeNumbers(true);
		end
	end
	if (cardCountCustom==0) then UI.CreateLabel (vertCustomCards).SetText ("[None]"); end
	if (cardCountRegular==0) then UI.CreateLabel (vertRegularCards).SetText ("[None]"); end

end

function setCardPrice (cardRecord, newCardPrice)
	print ("set price of "..cardRecord.ID,cardRecord.Name,cardRecord.Price," to new price "..newCardPrice);
end 

function WLplayerStates ()
	local WLplayerStatesTable = {
		[WL.GamePlayerState.Invited] = 'Invited',
		[WL.GamePlayerState.Playing] = 'Playing',
		[WL.GamePlayerState.Eliminated] = 'Eliminated',
		[WL.GamePlayerState.Won] = 'Won',
		[WL.GamePlayerState.Declined] = 'Declined',
		[WL.GamePlayerState.RemovedByHost] = 'RemovedByHost',
		[WL.GamePlayerState.SurrenderAccepted] = 'SurrenderAccepted',
		[WL.GamePlayerState.Booted] = 'Booted',
		[WL.GamePlayerState.EndedByVote] = 'EndedByVote'
	};
	return WLplayerStatesTable;
end

function toPlayerName(playerid, game)
	if (playerid ~= nil) then
		if (playerid<50) then
				return ("AI"..playerid);
		else
			for _,playerinfo in pairs(game.Game.Players) do
				if(playerid == playerinfo.ID)then
					return (playerinfo.DisplayName(nil, false));
				end
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found
end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end

function purchaseCard (cardRecord)
	print ("buy "..cardRecord.ID,cardRecord.Name,cardRecord.Price);
	local strMessage = "Buy "..cardRecord.Name.." Card";
	local strPayload = "Buy Cards|"..cardRecord.ID .."|"..cardRecord.Price; --include card price here to compare in AdvanceTurn_Order, and if price paid != card price, client side tampering has occurred (or price changed via mod update after client submitted an order [oopsie])
	print (strMessage);
	print (strPayload);
	print ("custom order=="..Game.Us.ID..", "..strMessage..", "..strPayload..", ".."resource=="..WL.ResourceType.Gold..", price=="..cardRecord.Price);
	local order = WL.GameOrderCustom.Create (Game.Us.ID, strMessage, strPayload, {[WL.ResourceType.Gold] = cardRecord.Price });

	local orders = Game.Orders;
	if(Game.Us.HasCommittedOrders == true)then
		UI.Alert("You need to uncommit first");
		return;
	else
		table.insert(orders, order);
		Game.Orders = orders;
	end
end

function showDefinedCards (game)
    print ("[PresentMenuUI] CARD OVERVIEW");

    local cards = getDefinedCardList (game);

    local strText = "";
    for k,v in pairs (cards) do
        if (k>=1000000) then strText = strText .. "\n"..v.." / ["..k.."]"; end
    end
    labelStuff = UI.CreateLabel (vert);
	strText = "\n\nCUSTOM CARDS THAT NEED PRICES ASSIGNED:"..strText;
    labelStuff.SetText (strText.."\n");
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
	function getDefinedCardList (game)
		print ("[CARDS DEFINED IN THIS GAME]");
		local count = 0;
		local cards = {};
		local publicGameData = Mod.PublicGameData;

		publicGameData.CardData = {}; 
		publicGameData.CardData.DefinedCards = nil;
		--Mod.PublicGameData = publicGameData;
	
		if (game==nil) then print ("game is nil"); return nil; end
		if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
		if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end
		print ("game==nil --> "..tostring (game==nil).."::");
		print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
		print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
		--print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
		--print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
		--print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
		
		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			--print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces.."::");
			cards[cardID] = strCardName;
			count = count +1
			--printObjectDetails (cardConfig, "cardConfig");
		end
		--printObjectDetails (cards, "card", count .." defined cards total");
		return cards;
	end
	
	--given a card name, return it's cardID
	function getCardID (strCardNameToMatch, game)
		--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
		local cards={};
		print ("[getCardID] match name=="..strCardNameToMatch.."::");
		print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
		print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
		print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
		print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));
		if (Mod.PublicGameData.CardData.DefinedCards == nil) then
			print ("run function");
			cards = getDefinedCardList (game);
		else
			print ("get from pgd");
			cards = Mod.PublicGameData.CardData.DefinedCards;
		end
	
		--print ("[getCardID] tablelength=="..tablelength (cards));
		for cardID, strCardName in pairs(cards) do
			--print ("[getCardID] cardID=="..cardID..", cardName=="..strCardName.."::");
			if (strCardName == strCardNameToMatch) then
				--print ("[getCardID] matching card cardID=="..cardID.."::");
				return cardID;
			end
		end
		return nil; --cardName not found
	end
	
	function getCardName_fromID(cardID, game);
		print ("cardID=="..cardID);
		local cardConfig = game.Settings.Cards[tonumber(cardID)];
		return getCardName_fromObject (cardConfig);
	end
	
	function getCardName_fromObject(cardConfig)
		if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
		if cardConfig.proxyType == 'CardGameCustom' then
			return cardConfig.Name;
		end
	
		if cardConfig.proxyType == 'CardGameAbandon' then
			-- Abandon card was the original name of the Emergency Blockade card
			return 'Emergency Blockade card';
		end
		return cardConfig.proxyType:match("^CardGame(.*)");
	end