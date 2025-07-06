--this code is shared between 2 client hooks: Client_PresentMenu.lua & Client_PresentCommercePurchaseUI.lua
function displayMenu (game, windowUI, close)
	--showDefinedCards (Game);
	local publicGameData = Mod.PublicGameData;
	local localPlayerIsHost = game.Us.ID == game.Settings.StartedBy;
	if (game.Game.ID == 41159857 and game.Us.ID == 1058239) then localPlayerIsHost = true; end --"Encirclement + Forts v2b" game; host is not in game so can't set card prices (oops) - manual fix to permit krinid to set card prices
	if (game.Game.ID == 41661316 and game.Us.ID == 1058239) then localPlayerIsHost = true; end --"Biohazard" game; host is not in game so can't set card prices (oops) - manual fix to permit krinid to set card prices
	-- if (game.Game.ID == 40767112 and game.Us.ID == 1058239) then localPlayerIsHost = true; publicGameData.CardData.CardPricesFinalized = false; publicGameData.CardData.HostHasAdjustedPricing = false; end --for this game, re-assign card prices
	-- if (game.Game.ID == 40767112 and game.Us.ID == 1058239) then publicGameData.CardData.CardPricesFinalized = true; publicGameData.CardData.HostHasAdjustedPricing = true; end --for this game, re-assign card prices

	--local buttonsCardPurchases = {};  --originally had these assigned but aren't actually using them, but leave them around until I'm sure they won't be required
	local sliderCardPrices = {};

	--delme delme delme -- for testing purposes only
	--localPlayerIsHost = false;
	--delme delme delme -- for testing purposes only

	local vertHeader = UI.CreateVerticalLayoutGroup(windowUI).SetFlexibleWidth (1);
	-- UI.CreateLabel (vertHeader).SetText ("[BUY CARDS]\n").SetColor (getColourCode("card play heading"));
	--[[UI.CreateLabel (vertHeader).SetText ("Turn #"..game.Game.TurnNumber);
	UI.CreateLabel (vertHeader).SetText ("Prices have been finalized == ".. tostring (publicGameData.CardData.CardPricesFinalized));
	UI.CreateLabel (vertHeader).SetText ("Host has updated pricing == " .. tostring (publicGameData.CardData.HostHasAdjustedPricing));]]

	print ("[BUY CARDS] Turn #"..game.Game.TurnNumber);
	print ("Prices have been finalized == ".. tostring (publicGameData.CardData.CardPricesFinalized));
	print ("Host has updated pricing == " .. tostring (publicGameData.CardData.HostHasAdjustedPricing));

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
		UI.CreateLabel (vertHeader).SetText ("\nEnter 0 for price to make a card unpurchasable\n");
		--UI.CreateLabel (vertHeader).SetText (" "); --empty label for visual vertical spacing
	end

	local vertRegularCards = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	UI.CreateLabel (vertRegularCards).SetText ("\nStandard cards:").SetColor (getColourCode("subheading"));
	local vertCustomCards = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
	UI.CreateLabel (vertCustomCards).SetText ("\nCustom cards:").SetColor (getColourCode("subheading"));

	local cardCountTotal = 0;
	local cardCountRegular = 0;
	local cardCountCustom = 0;
	local cardCountTotal_Buyable = 0;
	local cardCountRegular_Buyable = 0;
	local cardCountCustom_Buyable = 0;
	for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
		cardCountTotal = cardCountTotal + 1;
		--regular cards go in the Vert area and are listed at the top
		--custom cards go in the Vert area and are listed at the bottom
		--if client player is host & cards aren't finalized, then add sliders and use a horizontal layout group to organize the labels & sliders -- but don't use hori groups for non-host players b/c it adds unnecessary vertical space and less buttons fit on a single viewing window
		local targetUI = vertRegularCards;

		-- this is a custom card; custom cards are >=1000000
		if (cardRecord.ID >= 1000000) then
			targetUI = vertCustomCards;
			cardCountCustom = cardCountCustom + 1;
			if (cardRecord.Price>0) then cardCountCustom_Buyable = cardCountCustom_Buyable + 1; cardCountTotal_Buyable = cardCountTotal_Buyable + 1; end
		else --this is a regular card; regular cards are <1000000
			cardCountRegular = cardCountRegular + 1;
			if (cardRecord.Price>0) then cardCountRegular_Buyable = cardCountRegular_Buyable + 1; cardCountTotal_Buyable = cardCountTotal_Buyable + 1; end
		end
		local interactable = ((cardRecord.Price>=1) and (publicGameData.CardData.CardPricesFinalized==true)); --set .SetInteractable of the buttons to this value; set to True when prices have been finalized, otherwise False; if card price<=0 then make non-interactive (can't buy cards that cost 0 or negative)
		if (localPlayerIsHost==true and publicGameData.CardData.CardPricesFinalized == false) then targetUI = UI.CreateHorizontalLayoutGroup (targetUI).SetFlexibleWidth(100); end

		--only display a card in the list if (A) prices aren't finalized, or (B) the prices is >0; if it's not available for purchase, just don't show it in the list
		if (cardRecord.Price>0 or publicGameData.CardData.CardPricesFinalized == false) then
			UI.CreateButton(targetUI).SetFlexibleWidth (75).SetInteractable(interactable).SetText("Buy "..cardRecord.Name .." for " .. cardRecord.Price).SetOnClick(function() purchaseCard (game, cardRecord); end).SetColor (getColourCode ("Card|"..tostring (cardRecord.Name)));
-- UI.Alert ("Card|"..tostring (cardRecord.Name).."/"..cardRecord.Name.."/"..getColourCode ("Card|"..tostring (cardRecord.Name)));
		end

		--if client player is the host & prices aren't finalized, show a slider to be able to set the card price
		if (localPlayerIsHost==true and publicGameData.CardData.CardPricesFinalized == false) then
			sliderCardPrices [cardCountTotal] = UI.CreateNumberInputField(targetUI).SetSliderMinValue(1).SetSliderMaxValue(1000).SetValue(cardRecord.Price).SetFlexibleWidth (25).SetWholeNumbers(true);
		end
	end

	if (publicGameData.CardData.CardPricesFinalized == false) then
		if (cardCountRegular==0) then UI.CreateLabel (vertRegularCards).SetText ("[None]"); end
		if (cardCountCustom==0) then UI.CreateLabel (vertCustomCards).SetText ("[None]"); end
	else
		if (cardCountRegular_Buyable==0) then UI.CreateLabel (vertRegularCards).SetText ("[None]"); end
		if (cardCountCustom_Buyable==0) then UI.CreateLabel (vertCustomCards).SetText ("[None]"); end
	end

	--disable debug data until needed again
	if (false) then --game.Us.ID == 1058239) then
		DebugWindow = UI.CreateVerticalLayoutGroup(vertHeader).SetFlexibleWidth (1);
		UI.CreateLabel (DebugWindow).SetText ("\n\n- - - - - [DEBUG DATA START] - - - - -");
		UI.CreateLabel (DebugWindow).SetText ("Server time: "..game.Game.ServerTime);
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountRegular.." standard card(s) in game, "..cardCountRegular_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountCustom.. " custom card(s)], "..cardCountCustom_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("["..cardCountTotal.." total card(s)], "..cardCountTotal_Buyable.." buyable]");
		UI.CreateLabel (DebugWindow).SetText ("Prices finalized == "..tostring(publicGameData.CardData.CardPricesFinalized));

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
			--local strPlayerIsHost = "";
			--if (localPlayerIsHost) then strPlayerIsHost = " [HOST]"; end
			UI.CreateLabel (DebugWindow).SetText ("   Player "..k .."/"..toPlayerName (k, game)..", State: "..tostring(v.State).."/"..tostring(WLplayerStates ()[v.State]).. ", IsActive: "..tostring(game.Game.Players[k].State == WL.GamePlayerState.Playing) .. ", IsHost: "..tostring (k == game.Settings.StartedBy));
		end
		UI.CreateLabel (DebugWindow).SetText ("- - - - - [DEBUG DATA END] - - - - -");
	end
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

function purchaseCard (game, cardRecord)
	print ("buy "..cardRecord.ID,cardRecord.Name,cardRecord.Price);
	local strMessage = "Buy "..cardRecord.Name.." Card";
	local strPayload = "Buy Cards|"..cardRecord.ID .."|"..cardRecord.Price; --include card price here to compare in AdvanceTurn_Order, and if price paid != card price, client side tampering has occurred (or price changed via mod update after client submitted an order [oopsie])
	print (strMessage);
	print (strPayload);
	print ("custom order=="..game.Us.ID..", "..strMessage..", "..strPayload..", ".."resource=="..WL.ResourceType.Gold..", price=="..cardRecord.Price);
	local order = WL.GameOrderCustom.Create (game.Us.ID, strMessage, strPayload, {[WL.ResourceType.Gold] = cardRecord.Price });

	local orders = game.Orders;
	if (game.Us.HasCommittedOrders == true) then
		UI.Alert ("You must uncommit first");
		return;
	else
		table.insert(orders, order);
		game.Orders = orders;
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

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="Card|Reinforcement") then return getColours()["Dark Green"]; --green
	elseif (itemName=="Card|Spy") then return getColours()["Red"]; --
	elseif (itemName=="Card|Emergency Blockade card") then return getColours()["Blue"]; --
	elseif (itemName=="Card|OrderPriority") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|OrderDelay") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Airlift") then return "#777777"; --
	elseif (itemName=="Card|Gift") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Diplomacy") then return getColours()["Light Blue"]; --
	-- elseif (itemName=="Card|") then return getColours()["Medium Blue"]; --
	elseif (itemName=="Card|Sanctions") then return getColours()["Purple"]; --
	elseif (itemName=="Card|Reconnaissance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Surveillance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Blockade") then return getColours()["Blue"]; --
	elseif (itemName=="Card|Bomb") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Nuke") then return getColours()["Tyrian Purple"]; --
	elseif (itemName=="Card|Airstrike") then return getColours()["Ivory"]; --
	elseif (itemName=="Card|Pestilence") then return getColours()["Lime"]; --
	elseif (itemName=="Card|Isolation") then return getColours()["Red"]; --
	elseif (itemName=="Card|Shield") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Monolith") then return getColours()["Hot Pink"]; --
	elseif (itemName=="Card|Card Block") then return getColours()["Light Blue"]; --
	elseif (itemName=="Card|Card Pieces") then return getColours()["Sea Green"]; --
	elseif (itemName=="Card|Card Hold") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Phantom") then return getColours()["Smoky Black"]; --
	elseif (itemName=="Card|Neutralize") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Deneutralize") then return getColours()["Green"]; --
	elseif (itemName=="Card|Earthquake") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Tornado") then return getColours()["Charcoal"]; --
	elseif (itemName=="Card|Quicksand") then return getColours()["Saddle Brown"]; --
	elseif (itemName=="Card|Forest Fire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Resurrection") then return getColours()["Goldenrod"]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
    else return "#AAAAAA"; --return light grey for everything else
    end
end

function getColours()
    local colors = {}; -- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end