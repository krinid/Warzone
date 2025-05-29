require("utilities");
require("UI_Events");

--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI(game, cardInstance, playCard)
    --when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played
    Game = game; --make client game object available globally

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

    WZcolours = getColours (); --set global variable for WZ usable colours for buttons;

    strPlayerName_cardPlayer = game.Us.DisplayName(nil, false);
    intPlayerID_cardPlayer = game.Us.PlayerID;
    PrintProxyInfo (cardInstance);
    printObjectDetails (cardInstance, "cardInstance", "[PresentPlayCardUI]");

    strCardBeingPlayed = game.Settings.Cards[cardInstance.CardID].Name;
    print ("PLAY CARD="..strCardBeingPlayed.."::");

    if (strCardBeingPlayed=="Nuke") then
        play_Nuke_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Pestilence") then
        play_Pestilence_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Isolation") then
        play_Isolation_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Neutralize") then
        play_Neutralize_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Deneutralize") then
        play_Deneutralize_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Monolith") then
        play_Monolith_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed == "Shield") then
        play_Shield_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed == "Phantom") then
		play_Phantom_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Card Block") then
        play_CardBlock_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Earthquake") then
        play_Earthquake_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Tornado") then
        play_Tornado_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Quicksand") then
        play_Quicksand_card(game, cardInstance, playCard);
    elseif (strCardBeingPlayed=="Card Piece") then
        play_cardPiece_card (game, cardInstance, playCard)
    elseif (strCardBeingPlayed=="Airstrike") then
        print ("PLAY AIRSTRIKE");
        play_Airstrike_card (game, cardInstance, playCard)
    elseif (strCardBeingPlayed=="Forest Fire") then
        print ("PLAY FOREST FIRE");
        play_ForestFire_card (game, cardInstance, playCard)
    else
        print ("A custom card that the Custom Card Pack A does not handle has been played. card played="..strCardBeingPlayed.."::");
    end
end

function play_ForestFire_card (game, cardInstance, playCard)
    UI.Alert ("Forest Fire card . . .\n\ncoming soon to a Warzone near you\n\n\njust imagine be able to start a fire so wild that it keeps spreading each turn, farther and farther - be careful you don't burn your own lands down!");
end

function CardPiece_CardSelection_clicked (strText, cards, playCard, close)
	print ("CardPiece_CardSelection button clicked");

	CardOptions_PromptFromList = {}
	for k,v in pairs(cards) do
		print ("newObj item=="..k,v.."::");
        if (k ~= CardPieceCardID) then --don't add Card Piece card to the selection dialog to avoid increasing/infinite/loop card redemption
            table.insert (CardOptions_PromptFromList, {text=v, selected=function () CardPiece_cardType_selected({cardID=k,cardName=v}, playCard, close); end});
        end
	end

	UI.PromptFromList (strText, CardOptions_PromptFromList);
end

function CardPiece_cardType_selected (cardRecord, playCard, close)
	print ("CardPiece_cardType selected=="..tostring(cardRecord));
	print ("CardPiece_cardType selected:: name=="..cardRecord.cardID.."::value=="..cardRecord.cardName.."::");
	printObjectDetails (cardRecord, "selected card record", "card piece card selection");

    --don't allow using Card Piece card to receive Card Piece cards/pieces (to avoid looping/increasing amounts/infinite cards)
    if (cardRecord.cardID == CardPieceCardID) then
        UI.Alert ("Card Pieces card cannot be used to redeem Card Pieces cards or pieces. Choose a different card type.");
    end

    if (not (UI.IsDestroyed (TargetCardButton))) then TargetCardButton.SetText (cardRecord.cardName); end
    local strPlayCardPieceMsg = strPlayerName_cardPlayer .. " redeems a Card Piece card to receive "..cardRecord.cardName.." cards/pieces";
    playCard(strPlayCardPieceMsg, 'Card Piece|' .. cardRecord.cardID, WL.TurnPhase.Discards);
    print ("[PLAY Card Piece] "..strPlayCardPieceMsg.." // "..'Card Piece|' .. cardRecord.cardID);
    close(); --close the play card dialog
end

function TargetCardClicked (strText, cards)
	UI.PromptFromList(strText, cards);
end

function play_Shield_card(game, cardInstance, playCard)
    print("[SHIELD] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[SHIELD]\n\n").SetColor(getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Shield on.");

        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then 
                UI.Alert("You must select a territory you own.");
                return;
            end
            print("[SHIELD] order input::terr=" .. TargetTerritoryName .. "::Shield|" .. TargetTerritoryID .. "::");

            local strShieldMessage = strPlayerName_cardPlayer .. " creates a Shield on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Shield", 8, getColourInteger(0, 0, 255))}; --blue annotation background for Shield
                playCard(strShieldMessage, 'Shield|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards, territoryAnnotation, jumpToActionSpotOpt);
               else
                playCard(strShieldMessage, 'Shield|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards);
            end

            --for k,v in pairs (game.Orders) do print (k,v.proxyType); end

            --newOrder = game.Orders[1];
            --print (newOrder.proxyType);
            --newOrder.TerritoryAnnotationsOpt = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Shield", 10, 100)};
            --table.insert(orders, newOrder);
            --order.TerritoryAnnotationsOpt = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Shield", 10, 100)};
            --table.insert(orders, order);

            --for testing territory annotations with colour settings:
            --[[local orders = game.Orders;
            for terrID,v in pairs (game.LatestStanding.Territories) do
                colourNum = (terrID-1) * 9300;
                colourNum = getColourInteger (terrID%3==0 and 255 or 0, terrID%3==1 and 255 or 0, terrID%3==2 and 255 or 0); --set annotation background to pure R,G or B based on the mod 3 value
                local order = WL.GameOrderCustom.Create(game.Us.ID, colourNum.."/"..terrID, 'colour check|'..terrID);
                --order.TerritoryAnnotationsOpt = {[terrID] = WL.TerritoryAnnotation.Create (colourNum.."/"..terrID, 10, colourNum)};
                order.TerritoryAnnotationsOpt = {[terrID] = WL.TerritoryAnnotation.Create (terrID, 10, colourNum)};
                table.insert(orders, order);
            end
            newGame = game;
            newGame.Orders = orders;
            game = newGame;]]

            close();
        end);
    end);
end

function play_Phantom_card(game, cardInstance, playCard)
    print("[PHANTOM] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[PHANTOM]\n\n").SetColor(getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Phantom on.");

        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then 
                UI.Alert("You must select a territory you own.");
                return;
            end
            print("[PHANTOM] order input::terr=" .. TargetTerritoryName .. "::Phantom|" .. TargetTerritoryID .. "::");

            local strPhantomMessage = strPlayerName_cardPlayer .. " creates a Phantom on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Phantom", 8, getColourInteger(0, 0, 50))}; --use Blacky Blue for Phantom
                playCard(strPhantomMessage, 'Phantom|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strPhantomMessage, 'Phantom|' .. TargetTerritoryID, WL.TurnPhase.OrderPriorityCards);
            end

            close();
        end);
    end);
end

function play_CardBlock_card(game, cardInstance, playCard)
    local strPrompt = "Select the player you wish to block from playing cards";
    print("[CARD BLOCK] card play clicked, played by=" .. strPlayerName_cardPlayer);

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[CARD BLOCK]\n\n"..strPrompt).SetColor(getColourCode("card play heading"));
        TargetPlayerBtn = CreateButton (vert).SetText("Select player...").SetOnClick(function() TargetPlayerClicked_Fizz(strPrompt) end);

        CreateButton(vert).SetText("Play Card").SetOnClick(
        function()
            if (TargetPlayerID == nil) then
                UI.Alert("You must select a player");
                return;
            end

            print("[CARD BLOCK] order input: player=" .. TargetPlayerID .. "/".. toPlayerName(TargetPlayerID, game)..  " :: Card Block|" .. TargetPlayerID);
            playCard(strPlayerName_cardPlayer .. " applies Card Block on " .. toPlayerName(TargetPlayerID, game), 'Card Block|' .. TargetPlayerID, WL.TurnPhase.Discards);
            close();
        end);
        TargetPlayerClicked_Fizz(strPrompt);
    end);
end

function play_cardPiece_card (game, cardInstance, playCard)
    local publicGameData = Mod.PublicGameData;
    local cards = nil;
    CardPieceCardID = cardInstance.CardID; --ensure player doesn't redeem Card Piece cards/pieces; esp if redeem amount is >1 whole card, this results in receiving infinite turn-over-turn card/piece quantities

    print ("[PLAY CARD - CARD PIECE] "..CardPieceCardID.."::"); --/".. cards[CardPieceCardID] .. "//");

    cards = getDefinedCardList (game);

    print ("(cards==nil) --> "..tostring (cards==nil));
    print ("tablelength (cards) --> ".. tablelength (cards));

    --[[for k,v in pairs(cards) do
        print (k,v);
    end]]

    print ("[PLAY CARD - CARD PIECE] "..CardPieceCardID.."/".. cards[CardPieceCardID] .. "//".. game.Settings.Cards[CardPieceCardID].NumPieces);


    local strPrompt = "Select a card type to receive cards/pieces of:"

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[CARD PIECES]\n\n"..strPrompt).SetColor(getColourCode("card play heading"));
        TargetCardButton = CreateButton (vert).SetText("Select card...").SetOnClick(function() CardPiece_CardSelection_clicked (strPrompt, cards, playCard, close) end);
    end);
end

function TargetPlayerClicked_Fizz(strText)
	local options = map(filter(Game.Game.Players, IsPotentialTarget), PlayerButton);
	UI.PromptFromList(strText, options);
end

--Determines if the player is one we can propose an alliance to.
function IsPotentialTarget(player)
	if (Game.Us.ID == player.ID) then return false end; -- can't select self

	if (player.State ~= WL.GamePlayerState.Playing) then return false end; --skip players not alive anymore, or that declined the game

	--if (Game.Settings.SinglePlayer) then return true end; --in single player, allow proposing with everyone
    --return not player.IsAI; --In multi-player, never allow proposing with an AI.
    return (player.State == WL.GamePlayerState.Playing); --return true if they are still playing, false otherwise
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end

function play_Earthquake_card(game, cardInstance, playCard)
    print("[EARTHQUAKE] card play clicked, played by=" .. strPlayerName_cardPlayer);
    EarthquakeGame = game;
    Earthquake_SelectedBonus = nil;

    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,400);
        EarthquakeUI = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel (EarthquakeUI).SetText("[EARTHQUAKE]\n\n").SetColor(getColourCode("card play heading"));
        buttonEarthquakeSelectBonus = CreateButton (EarthquakeUI).SetText("Select Bonus").SetInteractable(false).SetOnClick (function () buttonEarthquakeSelectBonus.SetInteractable(false); Earthquake_SelectedBonusID = UI.InterceptNextBonusLinkClick(EarthquakeTargetSelected); end);
        labelEarthquakeSelectBonus = CreateLabel (EarthquakeUI).SetText("Select the bonus for the earthquake.\n");--.SetColor(getColourCode("card play heading"));
        Earthquake_SelectedBonusID = UI.InterceptNextBonusLinkClick(EarthquakeTargetSelected);
        Earthquake_PlayCardButton = UI.CreateButton(EarthquakeUI).SetText("Play Card").SetOnClick(function()
            if (Earthquake_SelectedBonus == nil) then
                UI.Alert("You must select a bonus");
                return;
            end

            --[[print(strPlayerName_cardPlayer);
            print(Earthquake_SelectedBonus.ID);
            print(Earthquake_SelectedBonus.Name);]]

            print("[EARTHQUAKE] order input: bonus=" .. Earthquake_SelectedBonus.ID .. "/".. Earthquake_SelectedBonus.Name .." :: Earthquake|" .. Earthquake_SelectedBonus.ID);
            local strEarthquakeMessage = strPlayerName_cardPlayer .. " invokes an Earthquake on bonus " .. Earthquake_SelectedBonus.Name;
            local territoryAnnotation = {}; --{[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Earthquake", 10, getColourInteger(255,0,0))}; --red annotation background for Earthquake
            --table of (array/table of territoryIDs + territory annotation) doesn't work, gives error that it found dictionary, was expecting integer (b/c it's an array of integers)
            --neither does table of 1 element for (each territory + territory annotation) work, gives error that the record has no proxy ID (b/c it's not a single record which has the TerritoryAnnotation proxy type but instead an array, each element of which has a territory annotation proxy type)
            --so just pick 1 territory in the bonus to show the Earthquake
            local EQterritories = {};
            for _, terrID in pairs(game.Map.Bonuses[Earthquake_SelectedBonus.ID].Territories) do
                if (WL.IsVersionOrHigher("5.34.1")) then territoryAnnotation = {[terrID] = WL.TerritoryAnnotation.Create ("Earthquake", 8, getColourInteger (255, 0, 0))}; end --red annotation background for Earthquake
            end
            local jumpToActionSpotOpt = createJumpToLocationObject_Bonus (game, Earthquake_SelectedBonus.ID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                playCard(strEarthquakeMessage, 'Earthquake|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strEarthquakeMessage, 'Earthquake|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards);
            end

            --playCard(strEarthquakeMessage.."1", 'Earthquake1|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards);--, territoryAnnotation, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."2", 'Earthquake2|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, territoryAnnotation);--, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."2.5", 'Earthquake2|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, tAnn, jumpToActionSpotOpt);
            --playCard(strEarthquakeMessage.."3", 'Earthquake3|' .. Earthquake_SelectedBonus.ID, WL.TurnPhase.ReceiveCards, nil, jumpToActionSpotOpt);
            close();
        end);
        labelEarthquake_BonusTerrList = CreateLabel (EarthquakeUI);
    end);
end

function EarthquakeTargetSelected(bonusDetails)
    --[[local targetPlayerName = toPlayerName(targetPlayerID, game);
    print("[EARTHQUAKE] target player selected: " .. targetPlayerName);
    playCard(strPlayerName_cardPlayer .. " invokes Earthquake on " .. targetPlayerName, 'Earthquake|' .. targetPlayerID, WL.TurnPhase.Gift);]]
    local strLabelText = "";
    if (UI.IsDestroyed(labelEarthquake_BonusTerrList)) then return; end --if the button is destroyed, the dialog is closed, so don't do anything
    labelEarthquake_BonusTerrList.SetText ("");
    strLabelText = "\nTerritories in bonus:\n\n";
    Earthquake_PlayCardButton.SetInteractable(true);
    buttonEarthquakeSelectBonus.SetInteractable(true);
    if bonusDetails == nil then return; end
    Earthquake_SelectedBonus = bonusDetails;

    labelEarthquakeSelectBonus.SetText ("Bonus selected: "..bonusDetails.ID.."/"..bonusDetails.Name);
    --buttonEarthquakeSelectBonus.SetText ("Bonus selected: "..bonusDetails.ID.."/"..bonusDetails.Name);

    for _, terrID in pairs(EarthquakeGame.Map.Bonuses[bonusDetails.ID].Territories) do
        strLabelText = strLabelText .. terrID .."/"..EarthquakeGame.Map.Territories[terrID].Name.."\n";
        --CreateLabel(EarthquakeUI).SetText (terrID .."/"..EarthquakeGame.Map.Territories[terrID].Name);
        --createButton(vert, game.Map.Territories[terrID].Name .. ": " .. rounding(Mod.PublicGameData.WellBeingMultiplier[terrID], 2), getPlayerColor(game.LatestStanding.Territories[terrID].OwnerPlayerID), function() if WL.IsVersionOrHigher("5.21") then game.HighlightTerritories({terrID}); game.CreateLocatorCircle(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY); end validateTerritory(game.Map.Territories[terrID]); end);
    end
    Game.HighlightTerritories(Game.Map.Bonuses[bonusDetails.ID].Territories);
    Earthquake_PlayCardButton.SetInteractable(true);
    buttonEarthquakeSelectBonus.SetInteractable(true);
    labelEarthquake_BonusTerrList.SetText (strLabelText);
    --close();
end

function play_Tornado_card(game, cardInstance, playCard)
    print("[TORNADO] card play clicked, played by=" .. strPlayerName_cardPlayer);
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[TORNADO]\n\nSelect a territory to target with a Tornado:").SetColor(getColourCode("card play heading"));
        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to target with Tornado");
        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("You must select a territory");
                return;
            end
            print("[TORNADO] order input: territory=" .. TargetTerritoryName .. " :: Tornado|" .. TargetTerritoryID);
            local strTornadoMessage = strPlayerName_cardPlayer .. " invokes a Tornado on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Tornado", 8, getColourInteger (255, 0, 0))}; --red annotation background for Tornado
                playCard(strTornadoMessage, 'Tornado|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strTornadoMessage, 'Tornado|' .. TargetTerritoryID, WL.TurnPhase.Gift);
            end
            close();
        end);
    end);
end

function play_Quicksand_card(game, cardInstance, playCard)
    print("[QUICKSAND] card play clicked, played by=" .. strPlayerName_cardPlayer);
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[QUICKSAND]\n\nSelect a territory to convert into quicksand:").SetColor(getColourCode("card play heading"));
        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to apply Quicksand to");
        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            print("[QUICKSAND] order input: territory=" .. TargetTerritoryName .. " :: Quicksand|" .. TargetTerritoryID);
            local strQuicksandMessage = strPlayerName_cardPlayer .. " transforms " .. TargetTerritoryName .. " into quicksand";
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Quicksand", 8, getColourInteger (255, 0, 0))}; --red annotation background for Quicksand
                playCard(strQuicksandMessage, 'Quicksand|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strQuicksandMessage, 'Quicksand|' .. TargetTerritoryID, WL.TurnPhase.Gift);
            end
            close();
        end);
    end);
end

function play_Monolith_card(game, cardInstance, playCard)
    print ("[MONOLITH] card play clicked, played by=" .. strPlayerName_cardPlayer.."::");
    --
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
        CreateLabel (vert).SetText ("[MONOLITH]\n\n").SetColor (getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to create a Monolith on."); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)
    
        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function() 

        --check for CANCELED request, ie: no territory selected
        if (TargetTerritoryID == nil) then
            UI.Alert("No territory selected. Please select a territory.");
            return;
        end
        if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then 
            -- client player does not own this territory, alert player and cancel
            UI.Alert("You must select a territory you own.");
            return;
        end
        print ("[MONOLITH] order input::terr=" .. TargetTerritoryName .."::Monolith|" .. TargetTerritoryID.."::");

        local strMonolithMessage = strPlayerName_cardPlayer.." creates a Monolith on " .. TargetTerritoryName;
        local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
        if (WL.IsVersionOrHigher("5.34.1")) then
            local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Monolith", 8, getColourInteger (0, 0, 255))}; --blue annotation background for Shield
            playCard(strMonolithMessage, 'Monolith|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
        else
            playCard(strMonolithMessage, 'Monolith|' .. TargetTerritoryID, WL.TurnPhase.Gift);
        end
        close();
        end);
    end);
end

function play_Deneutralize_card (game, cardInstance, playCard)
    game.CreateDialog(
        function(rootParent, setMaxSize, setScrollable, game, close)
            setMaxSize(400, 300);
            --local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
            local vert = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
            CreateLabel (vert).SetText ("[DENEUTRALIZE]\n\n").SetColor (getColourCode("card play heading"));

            TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
            TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
            strDeneutralize_TerritorySelectText = "Select the territory you wish to deneutralize (convert from neutral to owned by a player).";
            TargetTerritoryClicked(strDeneutralize_TerritorySelectText); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

            --add player selection here, default to self but allow to assign to others
            local assignToPlayerID = nil;
            local assignToPlayerName = nil;
            --add config items for can/can't assign to self/others

            UI.CreateButton(vert).SetText("Play Card").SetOnClick(
                function() 
                    --check for CANCELED request, ie: no territory selected
                    if (TargetTerritoryID == nil) then
                        UI.Alert("No territory selected. Please select a territory.");
                        return;
                    elseif (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= WL.PlayerID.Neutral) then -- territory is not neutral, alert player and cancel
                        UI.Alert("The selected territory is not neutral. Select a different territory that is neutral.");
                        TargetTerritoryClicked(strDeneutralize_TerritorySelectText); --bring up the territory select screen again
                        return;
                    end

                    --selected territory is  neutral, so apply the deneutralize order
                    assignToPlayerID = intPlayerID_cardPlayer;
                    assignToPlayerName = strPlayerName_cardPlayer;

                    print ("Deneutralize order input::terr=" .. TargetTerritoryName .."::Neutralize|" .. TargetTerritoryID.."::");
                    print ("territory="..TargetTerritoryName.."::,ID="..TargetTerritoryID.."::owner=="..game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID.."::neutralOwnerID="..WL.PlayerID.Neutral.."::assignToPlayerID="..assignToPlayerID.."::assignToPlayerName="..assignToPlayerName);

                    local strDeneutralizeMessage = strPlayerName_cardPlayer.." deneutralized " .. TargetTerritoryName ..", assigned to "..assignToPlayerName;
                    local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
                    if (WL.IsVersionOrHigher("5.34.1")) then
                        local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Deneutralize", 8, getColourInteger (0, 255, 0))}; --green annotation background for Deneutralize
                        playCard(strDeneutralizeMessage, 'Deneutralize|' .. TargetTerritoryID .. "|" .. assignToPlayerID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
                    else
                        playCard(strDeneutralizeMessage, 'Deneutralize|' .. TargetTerritoryID .. "|" .. assignToPlayerID, WL.TurnPhase.Gift);
                    end
                    --official playCard action; this plays the card via WZ interface, uses up a card (1 whole card), etc; can't put this in the move list at a specific spot but is required for card usage, etc
                    close(); --close the popup dialog
                end
            );
        end
    );
end

function play_Neutralize_card (game, cardInstance, playCard)
    --[[-- test writing to Mod.PublicGameData, Mod.PrivateGameData, Mod.PlayerGameData
    -- all data must be saved to a code construct, then have the code construct assigned the the Mod.Public/Private/PlayerGameData construct; can't modify variable values directly
    local data = Mod.PublicGameData;
    publicGameData = Mod.PublicGameData; --readable from anywhere, writeable only from Server hooks
    --privateGameData = Mod.PrivateGameData;  --readable only from Server hooks
    playerGameData = Mod.PlayerGameData;  --readable/writeable from both Client & Server hooks
        --Client hooks can only access data for the user associated with the Client hook (current player), doesn't need index b/c it can only access data for current player, automatically gets assigned playerID of current player
        --Server hooks access this using an index of playerID
    publicGameData.someProperty = "this is some public data";
    publicGameData.anotherProperty = "this is some public data";]]

    game.CreateDialog(
        function(rootParent, setMaxSize, setScrollable, game, close)
            setMaxSize(400, 300);
            local vert = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
            CreateLabel (vert).SetText ("[NEUTRALIZE]\n\n").SetColor (getColourCode("card play heading"));

            TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
            TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
            strNeutralize_TerritorySelectText = "Select the territory you wish to neutralize (turn to neutral).";
            TargetTerritoryClicked(strNeutralize_TerritorySelectText); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

            UI.CreateButton(vert).SetText("Play Card").SetOnClick(
                function() 
                    --check for CANCELED request, ie: no territory selected
                    if (TargetTerritoryID == nil) then
                        UI.Alert("No territory selected. Please select a territory.");
                        return;
                    elseif (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral) then -- territory is already neutral, alert player and cancel
                        UI.Alert("The selected territory is already neutral. Select a different territory that is owned by a player.");
                        TargetTerritoryClicked(strNeutralize_TerritorySelectText); --bring up the territory select screen again
                        return;
                    end

                    --selected territory is not neutral, so apply the neutralize order
                    --print ("[!player!] Neutralize order input prep::");
                    print ("Neutralize order input::terr=" .. TargetTerritoryName .."::Neutralize|" .. TargetTerritoryID.."::");
                    print ("territory="..TargetTerritoryName.."::,ID="..TargetTerritoryID.."::owner=="..game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID.."::neutralOwnerID="..WL.PlayerID.Neutral);

                    --implement order in ReceiveGold phase for now; doing it in BombCards phase causes error if opponents (AIs in my testing) move specials (commander) on the neutralized units; orders never reach Server_AdvanceTurn_Start or _Order
                    local strNeutralizeMessage = strPlayerName_cardPlayer.." neutralized " .. TargetTerritoryName;
                    local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
                    if (WL.IsVersionOrHigher("5.34.1")) then
                        local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Neutralize", 8, getColourInteger (128, 128, 128))}; --use Light Grey colour for Neutralize
                        playCard(strNeutralizeMessage, 'Neutralize|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
                    else
                        playCard(strNeutralizeMessage, 'Neutralize|' .. TargetTerritoryID, WL.TurnPhase.Gift);
                    end
                    --official playCard action; this plays the card via WZ interface, uses up a card (1 whole card), etc; can't put this in the move list at a specific spot but is required for card usage, etc
                    close(); --close the popup dialog
                end
            );
        end
    );
end

function play_Neutralize_card_TerritorySelectButton_clicked()
    UI.InterceptNextTerritoryClick(
        function(terrDetails)
            if terrDetails == nil then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end

            --TargetTerritoryID = terrDetails.ID;
            --TargetTerritoryName = terrDetails.Name;
            TargetTerritoryInstructionLabel.SetText("Selected territory: " .. TargetTerritoryName);
        end
    );
end

function play_Isolation_card(game, cardInstance, playCard)
    --game.CreateDialog (createIsolationCardDialog);
    print ("isolation prep, played by=" .. strPlayerName_cardPlayer.."::");
    --
    game.CreateDialog(function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
        CreateLabel (vert).SetText ("[ISOLATION]\n\n").SetColor (getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory you wish to isolate."); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

        UI.CreateButton(vert).SetText("Play Card").SetOnClick(function() 

        --check for CANCELED request, ie: no territory selected
        if (TargetTerritoryID == nil) then
            UI.Alert("No territory selected. Please select a territory.");
            return;
        end
            print ("Isolate order input::terr=" .. TargetTerritoryName .."::Isolation|" .. TargetTerritoryID.."::");

            local strIsolationMessage = strPlayerName_cardPlayer.." invoked isolation on " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Isolation", 8, getColourInteger (128, 128, 128))}; --Medium Grey annotation background for Isolation
                playCard(strIsolationMessage, 'Isolation|' .. TargetTerritoryID, WL.TurnPhase.Gift, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strIsolationMessage, 'Isolation|' .. TargetTerritoryID, WL.TurnPhase.Gift);
            end
            close();
        end);
    end);
end

function play_Pestilence_card(game, cardInstance, playCard)
    if(game.Us.HasCommittedOrders == true)then
        UI.Alert("You need to uncommit first");
        return;
    end

    require ("Client_GameRefresh");
    Client_GameRefresh (game);

    PestilencePlayerSelectDialog = nil;
    PestilencePlayerSelectDialog = game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 400);

        local vertPestiCard = CreateVert (rootParent);
        CreateLabel(vertPestiCard).SetText('[PESTILENCE]').SetColor (getColourCode ("card play heading"));
        CreateLabel(vertPestiCard).SetText('\nPestilence is not stackable, playing more than one instance has no additional effect.\n\n');
        local PestilenceTargetPlayerFuncs={};
        local strPlayersAlreadyTargetedByPestilence = "";
        local numUserButtonsCreated = 0;
        local labelPlayersAlreadyTargetedByPestilence = CreateLabel (vertPestiCard);
        CreateLabel (vertPestiCard).SetText ("Select player to invoke Pestilence on:");

        printObjectDetails (Mod.PublicGameData.PestilenceData, "Pestilence data", "full PublicGameDdata.Pestilence");
        for z,x in pairs (Mod.PublicGameData.PestilenceData) do
            print ("z=="..z);
            printObjectDetails (x, "Pestilence data record", "full publicgamedata.Pestilence");
        end
        print ("tablelength(Mod.PublicGameData.PestilenceData)=="..tablelength(Mod.PublicGameData.PestilenceData));

        --generate list of players for popup to select from; exclude self & eliminated (non-active) players; include AIs - game.Game.PlayingPlayers provides this list (compared to game.Game.Players which includes all players ever associated to the game, even those that declined the invite, were removed by host, etc)
        for playerID in pairs(game.Game.PlayingPlayers) do
            if (playerID~=game.Us.ID) then --don't show self in popup dialog
                if (Mod.PublicGameData.PestilenceData[playerID]==nil) then --create a button for this player if there is no Pestilence data for this playerID (ie: not currently targeted by Pestilence)
                    PestilenceTargetPlayerFuncs[playerID]=function() Pestilence(playerID,game,playCard,rootParent,close); end;
                    local pestPlayerButton = UI.CreateButton(vertPestiCard).SetText(toPlayerName(playerID,game)).SetOnClick(PestilenceTargetPlayerFuncs[playerID]);
                    numUserButtonsCreated = numUserButtonsCreated + 1;
                else
                        --player already targeted for Pestilence
                        print ("[PESTILENCE] player already targeted, player "..playerID.."/".. toPlayerName (playerID,game));
                        strPlayersAlreadyTargetedByPestilence = strPlayersAlreadyTargetedByPestilence .. "\n" ..toPlayerName (playerID,game);
                end
            end
        end
        if (strPlayersAlreadyTargetedByPestilence == "") then
            labelPlayersAlreadyTargetedByPestilence.SetText ("No players are currently being targeted by Pestilence.\n\n");
        else
            labelPlayersAlreadyTargetedByPestilence.SetText ("Players already targeted by Pestilence:" .. strPlayersAlreadyTargetedByPestilence .. "\n\n");
        end
        if (numUserButtonsCreated == 0) then
            CreateLabel (vertPestiCard).SetText ("All players are already targeted by Pestilence. You cannot invoke Pestilence this turn.").SetColor (getColourCode("error"));
        end
    end);
end

function Pestilence(playerID,game,playCard,rootParent,close)
    strTargetPlayerName=toPlayerName(playerID,game);
    print ("game.us.player="..game.Us.ID.."::Play a pestilence card on " .. strTargetPlayerName.. '::Pestilence|'..tostring(playerID).."::");
    orders=game.Orders;

    --future proof for being able to custom with/without warning, make warning far in advance or just slightly before, put activation far in advance or right away, modify duration so it can be multiple turns or just 1 turn
    local PestilenceWarningTurn = game.Game.TurnNumber+1; --for now, make PestilenceWarningTurn = 1 turn from now (next turn); perhaps make customizable in future (is this really required though?)
    local PestilenceStartTurn = game.Game.TurnNumber+2;   --for now, make PestilenceStartTurn = 2 turns from now; perhaps make customizable in future (is this really required though?)
    local PestilenceEndTurn = game.Game.TurnNumber + Mod.Settings.PestilenceDuration -1;   --sets end turn appropriately to align with specified duration for Pestilence

    local strModData; --text data fields separated by | to pass into the order
    --fields are Pestilence|playerID target|player ID caster|turn# Pestilence warning|turn# Pestilence begins|turn# Pestilence ends
    strModData = 'Pestilence|' .. tostring (playerID) .."|".. tostring (intPlayerID_cardPlayer) .. "|" .. tostring (PestilenceWarningTurn) .. "|" .. tostring (PestilenceStartTurn) .. "|" .. tostring (PestilenceEndTurn);

    if (playCard(strPlayerName_cardPlayer .. " invokes pestilence on " .. strTargetPlayerName, strModData)) then
        print ("[PESTILENCE] card played; ".. strPlayerName_cardPlayer .. " invokes pestilence on " .. strTargetPlayerName, strModData, Gift);
        close();
    end
end

function play_Nuke_card(game, cardInstance, playCard)
    TargetTerritoryID = nil;
    TargetTerritoryName = nil;
    local strNukeImplementationPhase; --friendly name of the turnPhase Nukes will execute on
    local intImplementationPhase;     --the internal WL # that represents the turnPhase that Nukes will execte on

    strNukeImplementationPhase = Mod.Settings.NukeImplementationPhase;
    intImplementationPhase = WLturnPhases()[strNukeImplementationPhase];
    print ("nuke turnPhase=="..strNukeImplementationPhase.."/"..intImplementationPhase.."::");

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
        CreateLabel (vert).SetText ("[NUKE]\n\n").SetColor (getColourCode("card play heading"));

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory you wish to nuke."); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

        UI.CreateButton(vert).SetText("Play Card").SetOnClick(
        function() 
            --check for CANCELED request, ie: no territory selected
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            print ("[!player!] nuke order input prep::");
            print ("[!player!] nuke order input::terr=" .. TargetTerritoryName .."::Nuke|" .. TargetTerritoryID.."::");

            local strNukeMessage = strPlayerName_cardPlayer .." nukes " .. TargetTerritoryName;
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
                local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Nuke", 8, getColourInteger(175, 0, 0))}; --Dark Red annotation background for Nuke
                playCard(strNukeMessage, 'Nuke|' .. TargetTerritoryID, intImplementationPhase, territoryAnnotation, jumpToActionSpotOpt);
            else
                playCard(strNukeMessage, 'Nuke|' .. TargetTerritoryID, intImplementationPhase);
            end
            close();
        end);
    end);
end

function play_Airstrike_card (game, cardInstance, playCard)
    TargetTerritoryID = nil;
    TargetTerritoryName = nil;
    SourceTerritoryID = nil;
    SourceTerritoryName = nil;
    intArmiesToSend = 0;

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(600, 600);
        airstrikeObject = {}; --global variable
		airstrikeObject.FROMselectedSUs = {}; --to store actual SU objects in order to create WL.Armies object to get its Attack Power
        airstrikeObject.vertTop = CreateVert (rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
        CreateLabel (airstrikeObject.vertTop).SetText ("[AIRSTRIKE]\n\n").SetColor (getColourCode("card play heading"));
        local vertTop = airstrikeObject.vertTop;

        local sourceButtonHorz = UI.CreateHorizontalLayoutGroup (vertTop);
        SourceTerritoryBtn = UI.CreateButton(sourceButtonHorz).SetText("Source Territory").SetOnClick(SourceTerritorySelectButton_Clicked_Airstrike);
        airstrikeObject.SourceTerritoryClicked_Airstrike = UI.CreateLabel(sourceButtonHorz).SetText("").SetColor (getColourCode("minor heading"));
        SourceTerritorySelectButton_Clicked_Airstrike("Select the territory you wish to attack from"); -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

        local targetButtonHorz = UI.CreateHorizontalLayoutGroup (vertTop);
        TargetTerritoryBtn = UI.CreateButton(targetButtonHorz).SetText("Target Territory").SetOnClick(TargetTerritoryClicked_Airstrike);
        TargetTerritoryInstructionLabel = UI.CreateLabel(targetButtonHorz).SetText("").SetColor (getColourCode("minor heading"));

        CreateLabel (vertTop).SetText (" "); --spacer

        local line = CreateHorz (vertTop);
        CreateLabel (line).SetText ("Number of armies to send  ");
        airstrikeObject.NIFarmies = CreateNumberInputField (line).SetValue(100).SetSliderMinValue(0).SetSliderMaxValue(1000);
        --CreateLabel (vertTop).SetText ("[all Special Units will be sent; unit selector coming soon]").SetColor (getColourCode ("subheading"));

		--if Mod Settings disallows sending Armies, force it to 0 (clearly to the player so it's obvious what's happening)
		if (Mod.Settings.AirstrikeCanSendRegularArmies == nil or Mod.Settings.AirstrikeCanSendRegularArmies == false) then
			airstrikeObject.NIFarmies.SetValue (0);
			airstrikeObject.NIFarmies.SetInteractable (false);
			CreateLabel (vertTop).SetText ("** This game is configured so you cannot send regular armies with an Airstrike").SetColor (getColourCode ("subheading"));
			CreateLabel (vertTop).SetText (" "); --spacer
		end

		airstrikeObject.SUpanelVert = UI.CreateVerticalLayoutGroup (vertTop).SetFlexibleWidth(1);
        CreateLabel (vertTop).SetText (" "); --spacer

        local playCardButtonhorz = UI.CreateHorizontalLayoutGroup (vertTop).SetFlexibleWidth(1.0);
        UI.CreateButton(playCardButtonhorz).SetText("Play Card").SetColor(WZcolours["Dark Green"]).SetFlexibleWidth(0.5).SetOnClick(
        function()
			updateAirstrikePanelDetails (); --update all values, ensure variables are up to date as per latest visual controls on Airstrike popup window
			--check for CANCELED request, ie: no territory selected
            if (SourceTerritoryID == nil and TargetTerritoryID == nil) then
                UI.Alert("Select SOURCE and TARGET territories to send units TO and FROM"); return;
            elseif (SourceTerritoryID == nil) then
                UI.Alert("Select a SOURCE territory to send units FROM"); return;
            elseif (TargetTerritoryID == nil) then
                UI.Alert("Select a TARGET territory to send units TO"); return;
            elseif (SourceTerritoryID == TargetTerritoryID) then
                UI.Alert("Select unique SOURCE and TARGET territories to send units TO and FROM"); return;
            elseif (airstrikeObject.FROMplayerID ~= airstrikeObject.OrderPlayerID) then
                UI.Alert("Select a SOURCE territory you own to send units FROM"); return;
            elseif (airstrikeObject.FROMselectedArmies == 0 and #airstrikeObject.FROMselectedSUs == 0) then
                UI.Alert("Airstrikes must send at least 1 army or special unit"); return;
            end
            --&&& check and warn if sending own C as a transfer to ally -- C will get left behind in Airlift (but not manual -- but make it so!)
            --&&& check and warn if sending units to ally who already has a C there -- usual function is take over the territory; if allied C is there, then can't take it over -- own C gets left behind, target territory remains owned by ally (still to be done)
            --^^ don't cancel moves, treat like attacking a Diplo ... can let it get decided during _Order; if ownership issues persist, above results result, but if resolved, then proceed normally

			generateStringOfSelectedSUs (); --generate the order text using friendly names of SUs & text for the order specifying GUIDs of SUs
			local intArmiesToSend = math.max (0, airstrikeObject.NIFarmies.GetValue ());

			local strAirstrikeMsg = strPlayerName_cardPlayer .." launches airstrike from " .. SourceTerritoryName .. " to " ..TargetTerritoryName ..", sending ".. tostring(intArmiesToSend).. " armies";
			local strSUsSent_PlainText = "";
			if (airstrikeObject.strSelectedSUs_Names ~= "") then
				strSUsSent_PlainText = airstrikeObject.strSelectedSUs_Names; --the plain text description of the SUs being sent (eg: Recruiter, Worker, Commander, Dragon, etc)
				strAirstrikeMsg = strAirstrikeMsg .. " and "..strSUsSent_PlainText;
			end
			local strAirstrikeOrder = 'Airstrike|' .. SourceTerritoryID .. "|" .. TargetTerritoryID.."|" .. intArmiesToSend.."|" .. tostring (airstrikeObject.strSelectedSUguids).."|".. strSUsSent_PlainText;
            print ("[AIRSTRIKE] ".. strAirstrikeMsg, strAirstrikeOrder);
            local jumpToActionSpotOpt = createJumpToLocationObject (game, TargetTerritoryID);
            if (WL.IsVersionOrHigher("5.34.1")) then
				local territoryAnnotations = {};
				territoryAnnotations [SourceTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [SOURCE]", 3, getColourInteger (0, 255, 0)); --show source territory in Green annotation
				territoryAnnotations [TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [TARGET]", 3, getColourInteger (255, 0, 0)); --show target territory in Red annotation
				-- local territoryAnnotation = {[TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike", 10, getColourInteger(255,0,0))}; --red annotation background for Airstrike
                playCard(strAirstrikeMsg, strAirstrikeOrder, nil, territoryAnnotations, jumpToActionSpotOpt); --[[, intImplementationPhase]]
                -- playCard(strAirstrikeMsg, 'Airstrike|' .. SourceTerritoryID .. "|" .. TargetTerritoryID.."|" .. intArmiesToSend.."|" .. tostring (airstrikeObject.strSelectedSUguids), nil, territoryAnnotation, jumpToActionSpotOpt); --[[, intImplementationPhase]]
            else
                playCard(strAirstrikeMsg, strAirstrikeOrder);
            end
            close();
        end);
        UI.CreateLabel (playCardButtonhorz).SetText (" ").SetFlexibleWidth(0.5);
    end);
end

function updateAirstrikePanelDetails ()
    --if (UI.IsDestroyed (airstrikeObject.airstrikeSUvert) ~= nil) then UI.Destroy (airstrikeObject.airstrikeSUvert); end
    if (not UI.IsDestroyed (airstrikeObject.airstrikeSUvert)) then UI.Destroy (airstrikeObject.airstrikeSUvert); end
    airstrikeObject.airstrikeSUvert = CreateVerticalLayoutGroup (airstrikeObject.vertTop);

	--set input field for max & current value to the # of armies on the select FROM territory for ease of use
    --if (SourceTerritoryID ~= nil) then airstrikeObject.NIFarmies.SetSliderMaxValue (Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.NumArmies); end
    --if (SourceTerritoryID ~= nil) then airstrikeObject.NIFarmies.SetSliderMaxValue (Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.NumArmies); airstrikeObject.NIFarmies.SetValue (Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.NumArmies); end

	--if Mod Settings disallows sending Armies, force it to 0 (clearly to the player so it's obvious what's happening)
	if (Mod.Settings.AirstrikeCanSendRegularArmies == nil or Mod.Settings.AirstrikeCanSendRegularArmies == false) then
		airstrikeObject.NIFarmies.SetValue (0);
		airstrikeObject.NIFarmies.SetInteractable (false);
	end

	airstrikeObject.OrderPlayerID = Game.Us.ID;
    airstrikeObject.FROMplayerID = SourceTerritoryID ~= nil and Game.LatestStanding.Territories[SourceTerritoryID].OwnerPlayerID or nil;
    airstrikeObject.TOplayerID = TargetTerritoryID ~= nil and Game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID or nil;
    airstrikeObject.OrderPlayerTeam = -1 or airstrikeObject.OrderPlayerID ~= nil and airstrikeObject.OrderPlayerID>0 and Game.Game.Players[airstrikeObject.OrderPlayerID].Team;
    airstrikeObject.FROMplayerTeam = -1 or airstrikeObject.FROMplayerID~=nil and airstrikeObject.FROMplayerID>0 and Game.Game.Players[airstrikeObject.FROMplayerID].Team;
    airstrikeObject.TOplayerTeam = -1 or airstrikeObject.TOplayerID~=nil and airstrikeObject.TOplayerID>0 and Game.Game.Players[airstrikeObject.TOplayerID].Team;
    --airstrikeObject.FROMplayerTeam = (nil or airstrikeObject.FROMplayerID~=nil and airstrikeObject.FROMplayerID>0 and Game.Game.Players[airstrikeObject.FROMplayerID].Team);
    --airstrikeObject.TOplayerTeam = (nil or airstrikeObject.TOplayerID~=nil and airstrikeObject.TOplayerID>0 and Game.Game.Players[airstrikeObject.TOplayerID].Team);
	generateStringOfSelectedSUs (); --generate table of selected SUs from the checkbox panel & store result in airstrikeObject.FROMselectedSUs
	-- print ("#selected SUs "..#airstrikeObject.FROMselectedSUs);
    airstrikeObject.FROMattackPower = SourceTerritoryID ~= nil and math.max (0, Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.AttackPower) or nil;
    airstrikeObject.TOdefensePower = TargetTerritoryID ~= nil and (math.max (0, Game.LatestStanding.Territories[TargetTerritoryID].NumArmies.DefensePower) + getArmiesDeployedThisTurnSoFar (Game, TargetTerritoryID)) or nil;
    airstrikeObject.FROMarmies = math.max (0, SourceTerritoryID ~= nil and Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.NumArmies or 0); --apply max (0, calc) to ensure no negative values which occur when territory is fogged (shows a large negative army count)
	airstrikeObject.FROMselectedArmies = math.max (0, airstrikeObject.NIFarmies.GetValue ()); --the # of armies select to be sent in Airstrike (not necessarily the full amount present on FROM territory)

    airstrikeObject.TOarmies = TargetTerritoryID ~= nil and (Game.LatestStanding.Territories[TargetTerritoryID].NumArmies.NumArmies + getArmiesDeployedThisTurnSoFar (Game, TargetTerritoryID)) or 0;
	if (airstrikeObject.TOarmies < 0) then airstrikeObject.TOarmies = 0; end --if <0 then territory is likely fogged and returning an invalid army count, so just set it to 0
    airstrikeObject.FROMnumSpecials = SourceTerritoryID ~= nil and #Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits or 0;
    airstrikeObject.TOnumSpecials = TargetTerritoryID ~= nil and #Game.LatestStanding.Territories[TargetTerritoryID].NumArmies.SpecialUnits or 0;
    airstrikeObject.DeploymentYield = 0.75; --default to 75%
    if (Mod.Settings.AirstrikeDeploymentYield ~= nil) then airstrikeObject.DeploymentYield = Mod.Settings.AirstrikeDeploymentYield/100; end --if mod setting is set, use that value instead of the default
    airstrikeObject.DeploymentYieldLoss = math.floor ((1-airstrikeObject.DeploymentYield) * airstrikeObject.FROMselectedArmies + 0.5);
    airstrikeObject.AttackTransfer = "tbd";
	if (airstrikeObject.FROMplayerID == nil or airstrikeObject.TOplayerID == nil) then airstrikeObject.AttackTransfer = "tbd";
	elseif (airstrikeObject.FROMplayerID ~= airstrikeObject.TOplayerID and (airstrikeObject.FROMplayerTeam==-1 or airstrikeObject.FROMplayerTeam>0 and airstrikeObject.FROMplayerTeam ~= airstrikeObject.TOplayerTeam)) then airstrikeObject.AttackTransfer = "Attack";
	elseif (airstrikeObject.FROMplayerID == airstrikeObject.TOplayerID or (airstrikeObject.FROMplayerTeam>0 or airstrikeObject.FROMplayerTeam == airstrikeObject.TOplayerTeam)) then airstrikeObject.AttackTransfer = "Transfer";
	end

	airstrikeObject.attackingArmies = nil;
	airstrikeObject.defendingArmies = nil;
	airstrikeObject.FROMactualAttackPower = 0;
    airstrikeObject.FROMattackPower_SelectedUnits = nil;
    local intFROMattackPower_kills = nil;
    local intTOdefensePower_kills = nil;
	-- if (SourceTerritoryID~=nil) then airstrikeObject.attackingArmies = WL.Armies.Create (airstrikeObject.FROMselectedArmies, Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits); airstrikeObject.FROMactualAttackPower = airstrikeObject.attackingArmies.AttackPower; end
	if (SourceTerritoryID~=nil) then
        airstrikeObject.attackingArmies = WL.Armies.Create (airstrikeObject.FROMselectedArmies, airstrikeObject.FROMselectedSUs);
        airstrikeObject.FROMactualAttackPower = math.max (0, airstrikeObject.attackingArmies.AttackPower);
        airstrikeObject.FROMattackPower_SelectedUnits = math.max (0, airstrikeObject.attackingArmies.AttackPower);
        intFROMattackPower_kills = math.floor (airstrikeObject.FROMattackPower_SelectedUnits * Game.Settings.OffenseKillRate + 0.5);
    end
	if (TargetTerritoryID~=nil) then
		-- UI.Alert (Game.LatestStanding.Territories[TargetTerritoryID].FogLevel .."/".. WL.StandingFogLevel.ToString (Game.LatestStanding.Territories[TargetTerritoryID].FogLevel));
		-- UI.Alert (tostring (airstrikeObject.TOarmies)..", ".. tostring (Game.LatestStanding.Territories[TargetTerritoryID].NumArmies.SpecialUnits or 0));
		-- FogLevel enum: 4=Fogged, 3=OwnerOnly, 2=Visible, 1=Self (what you own)
        airstrikeObject.defendingArmies = WL.Armies.Create (airstrikeObject.TOarmies, Game.LatestStanding.Territories[TargetTerritoryID].NumArmies.SpecialUnits or 0);
        intTOdefensePower_kills = math.floor (airstrikeObject.TOdefensePower * Game.Settings.DefenseKillRate + 0.5);
    end

    airstrikeObject.FROMTOhorz = CreateHorz (airstrikeObject.airstrikeSUvert).SetFlexibleWidth(1.0);
    airstrikeObject.FROMvert = CreateVert (airstrikeObject.FROMTOhorz).SetFlexibleWidth(0.5);
    airstrikeObject.TOvert = CreateVert (airstrikeObject.FROMTOhorz).SetFlexibleWidth(0.5);

    local strFROMteamText = ""; if (airstrikeObject.FROMplayerTeam >=0) then airstrikeObject.FROMplayerTeam = "/[team ".. tostring(airstrikeObject.FROMplayerTeam).."]"; end
    local strTOteamText = ""; if (airstrikeObject.TOplayerTeam >=0) then airstrikeObject.TOplayerTeam = "/[team ".. tostring(airstrikeObject.TOplayerTeam).."]"; end
    CreateLabel (airstrikeObject.FROMvert).SetText ("FROM: "..tostring (getTerritoryName(SourceTerritoryID, Game))).SetColor("#33FF33");
    CreateLabel (airstrikeObject.FROMvert).SetText ("Owner: "..tostring(getPlayerName(Game, airstrikeObject.FROMplayerID))..strFROMteamText);
    --CreateLabel (airstrikeObject.FROMvert).SetText ("Attack Power: ".. tostring(airstrikeObject.FROMattackPower) .." [".. tostring (airstrikeObject.FROMattackPower_SelectedUnits) .."]");
    CreateLabel (airstrikeObject.FROMvert).SetText ("Attack Power: ".. tostring (airstrikeObject.FROMattackPower_SelectedUnits) .. " [kills ".. tostring (intFROMattackPower_kills) .."]");

    -- CreateLabel (airstrikeObject.FROMvert).SetText ("#Armies: ".. tostring(airstrikeObject.FROMarmies).. " [".. tostring (airstrikeObject.FROMselectedArmies) .."]");
    CreateLabel (airstrikeObject.FROMvert).SetText ("#Armies: ".. tostring (airstrikeObject.FROMselectedArmies));
    -- CreateLabel (airstrikeObject.FROMvert).SetText ("#Special Units: ".. tostring(airstrikeObject.FROMnumSpecials).. " [".. tostring (#airstrikeObject.FROMselectedSUs) .."]");
    CreateLabel (airstrikeObject.FROMvert).SetText ("#Special Units: ".. tostring (#airstrikeObject.FROMselectedSUs));
    airstrikeObject.TOhorz = CreateHorz (airstrikeObject.airstrikeSUvert);
    CreateLabel (airstrikeObject.TOvert).SetText ("TO: "..tostring (getTerritoryName(TargetTerritoryID, Game))).SetColor((airstrikeObject.AttackTransfer=="Transfer" and ("#33FF33")) or "#FF3333"); --colour is GREEN for Transfer, RED for Attack or tbd (anything that isn't "Transfer")
    CreateLabel (airstrikeObject.TOvert).SetText ("Owner: "..tostring(getPlayerName (Game, airstrikeObject.TOplayerID))..strTOteamText);
    CreateLabel (airstrikeObject.TOvert).SetText ("Defense Power: ".. tostring(airstrikeObject.TOdefensePower) .. " [kills ".. tostring (intTOdefensePower_kills) .."]");
    CreateLabel (airstrikeObject.TOvert).SetText ("#Armies: ".. tostring(airstrikeObject.TOarmies));
    CreateLabel (airstrikeObject.TOvert).SetText ("#Special Units: ".. tostring(airstrikeObject.TOnumSpecials));
    --CreateLabel (airstrikeObject.airstrikeSUvert).SetText (" ");

	CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("\nDeployment yield: ".. airstrikeObject.DeploymentYield*100 .."% (for attacks)").SetColor (getColourCode("subheading"));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Armies shot out of sky: ".. airstrikeObject.DeploymentYieldLoss).SetColor (getColourCode("subheading"));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("• armies that die in addition to regular battle damage taken\n- Special Units are not impacted");
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("• Airstrikes on own or team territories transfer units to the target territory with no Yield Deployment loss, but you still take over the target territory and any units present there");
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText (" ");

	local AttackTransferHorz = UI.CreateHorizontalLayoutGroup (airstrikeObject.airstrikeSUvert);
    CreateLabel (AttackTransferHorz).SetText ("Attack/Transfer: ");
    CreateLabel (AttackTransferHorz).SetText (airstrikeObject.AttackTransfer).SetColor((airstrikeObject.AttackTransfer=="Transfer" and ("#33FF33")) or "#FF3333"); --colour is GREEN for Transfer, RED for Attack or tbd (anything that isn't "Transfer")
    CreateLabel (AttackTransferHorz).SetText (" (at current time)");
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can send regular armies: ".. tostring (Mod.Settings.AirstrikeCanSendRegularArmies));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can send Special Units: ".. tostring (Mod.Settings.AirstrikeCanSendSpecialUnits));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target fog: ".. tostring (Mod.Settings.AirstrikeCanTargetFoggedTerritories));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target neutrals: ".. tostring (Mod.Settings.AirstrikeCanTargetNeutrals));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target players: ".. tostring (Mod.Settings.AirstrikeCanTargetPlayers));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target structures: ".. tostring (Mod.Settings.AirstrikeCanTargetStructures));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target Special Units: ".. tostring (Mod.Settings.AirstrikeCanTargetSpecialUnits));
    CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can target Commanders: ".. tostring (Mod.Settings.AirstrikeCanTargetCommanders));
	--CreateLabel (airstrikeObject.airstrikeSUvert).SetText ("Can send Commanders: tbd"); --.. tostring (Mod.Settings.AirstrikeCan));
end

function SourceTerritorySelectButton_Clicked_Airstrike(strLabelText) --airstrikeObject.SourceTerritoryClicked_Airstrike, SourceTerritoryBtn)
	UI.InterceptNextTerritoryClick(SourceTerritoryClicked_Airstrike);
	if strLabelText ~= nil then airstrikeObject.SourceTerritoryClicked_Airstrike.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	SourceTerritoryBtn.SetInteractable(false);
end

function SourceTerritoryClicked_Airstrike(terrDetails)
	if (UI.IsDestroyed (SourceTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
	SourceTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		airstrikeObject.SourceTerritoryClicked_Airstrike.SetText("");
		SourceTerritoryID = nil;
        SourceTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		local intNumArmiesPresent = math.max (0, getArmiesDeployedThisTurnSoFar (Game, terrDetails.ID) + Game.LatestStanding.Territories[terrDetails.ID].NumArmies.NumArmies); --get armies present on source territory including current deployments during this turn; apply max (0, calc) to avoid negative #'s which occurs with fogged territories'
		airstrikeObject.NIFarmies.SetSliderMaxValue (intNumArmiesPresent);  --set max slider value for input field to # of armies on territory for ease of use (sum of current state + current deployments to source territory)
		--if (SourceTerritoryID == nil) then airstrikeObject.NIFarmies.SetValue (intNumArmiesPresent); end --set current value for input field to # of armies on territory for ease of use; only do if SourceTerritoryID==nil so we don't overwrite the #armies entry a player has made already

        if (Mod.Settings.AirstrikeCanSendRegularArmies == nil or Mod.Settings.AirstrikeCanSendRegularArmies == false) then
            airstrikeObject.NIFarmies.SetValue (0);
            airstrikeObject.NIFarmies.SetInteractable (false);
        else
            airstrikeObject.NIFarmies.SetValue (intNumArmiesPresent); --set current value for input field to # of armies on territory for ease of use; only do if SourceTerritoryID==nil so we don't overwrite the #armies entry a player has made already
        end

		airstrikeObject.SourceTerritoryClicked_Airstrike.SetText("Selected territory: " .. terrDetails.Name);
		SourceTerritoryID = terrDetails.ID;
        SourceTerritoryName = terrDetails.Name;

        populateSUpanel (); --populate the SP panel vert object with the SU's on the Source territory

		--activate the Target territory selector if it hasn't been populated already; if it's populated already, don't activate, b/c this is the player altering the Source territory, and we shouldn't force them to update the Target territory as well, which may be accurate already
		if (TargetTerritoryID == nil) then TargetTerritoryClicked_Airstrike ("Select the territory you wish to attack"); end -- auto-invoke the button click event for the 'Select Territory' button (don't wait for player to click it)

        updateAirstrikePanelDetails ();
	end
end

function TargetTerritoryClicked_Airstrike(strLabelText) --TargetTerritoryInstructionLabel, TargetTerritoryBtn)
	UI.InterceptNextTerritoryClick(TerritoryClicked_Airstrike);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked_Airstrike(terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
    TargetTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		TargetTerritoryID = nil;
        TargetTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
        updateAirstrikePanelDetails ();
	end
end

function populateSUpanel ()
    if (not UI.IsDestroyed (airstrikeObject.SUitemsVert)) then UI.Destroy (airstrikeObject.SUitemsVert); end
    airstrikeObject.SUitemsVert = UI.CreateVerticalLayoutGroup (airstrikeObject.SUpanelVert).SetFlexibleWidth(1);
    airstrikeObject.SUcheckboxes = {}; --array to store checkboxes for each SU on Source territory

	--if there are SUs on the source territory, display the Select/Deselect/Toggle buttons
	local buttonLine = UI.CreateHorizontalLayoutGroup (airstrikeObject.SUitemsVert).SetFlexibleWidth (1);

    local boolNumSUsIncluded = 0
	for k, SU in pairs (Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits) do
        --print (k, SU.ID);
        local strSUname = SU.proxyType; --this is accurate for Commander & Bosses (it makes the SU name 'Commander' or 'Boss 1/2/3/4')
        local boolIncludeSU = true;
        if (SU.proxyType == "CustomSpecialUnit") then
            strSUname = SU.Name;
            if (SU.Health ~= nil) then strSUname = strSUname .. " [health "..tostring(SU.Health).."]"; end
            if (isSpecialUnitAnImmovableUnit (SU) == true) then boolIncludeSU = false; end
        end
        if (boolIncludeSU == true) then airstrikeObject.SUcheckboxes[k] = UI.CreateCheckBox (airstrikeObject.SUitemsVert).SetText (strSUname).SetIsChecked (true).SetOnValueChanged (updateAirstrikePanelDetails); boolNumSUsIncluded = boolNumSUsIncluded + 1; end
    end
    if (boolNumSUsIncluded > 0) then
        if (#Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits >0) then
            UI.CreateLabel (buttonLine).SetText ("Special Units:").SetFlexibleWidth(0.25);
            UI.CreateButton (buttonLine).SetText ("Select All").SetOnClick (SUpanel_selectAll).SetColor (WZcolours.Green).SetFlexibleWidth(0.25);
            UI.CreateButton (buttonLine).SetText ("Deselect All").SetOnClick (SUpanel_deselectAll).SetColor(WZcolours.Red).SetFlexibleWidth(0.25);
            UI.CreateButton (buttonLine).SetText ("Toggle All").SetOnClick (SUpanel_toggleAll).SetColor (WZcolours.Yellow).SetFlexibleWidth(0.25);
        end
    end
	updateAirstrikePanelDetails ();
end

-- if (Mod.Settings.AirstrikeCanTargetNeutrals == nil) then Mod.Settings.AirstrikeCanTargetNeutrals = true; end
-- if (Mod.Settings.AirstrikeCanTargetPlayers == nil) then Mod.Settings.AirstrikeCanTargetPlayers = true; end
-- if (Mod.Settings.AirstrikeCanTargetFoggedTerritories == nil) then Mod.Settings.AirstrikeCanTargetFoggedTerritories = false; end
-- if (Mod.Settings.AirstrikeCanTargetCommanders == nil) then Mod.Settings.AirstrikeCanTargetCommanders = false; end
-- if (Mod.Settings.AirstrikeCanTargetSpecialUnits == nil) then Mod.Settings.AirstrikeCanTargetSpecialUnits = false; end
-- if (Mod.Settings.AirstrikeCanTargetStructures == nil) then Mod.Settings.AirstrikeCanTargetStructures = false; end
-- if (Mod.Settings.AirstrikeCanSendSpecialUnits == nil) then Mod.Settings.AirstrikeCanSendSpecialUnits = false; end


function generateTableOfSelectedSUs ()
	if (#airstrikeObject.SUcheckboxes==0) then return {}; end --return empty set if there are no checkboxes (no SUs)
	local selectedSUs = {};
	for k,cbox in pairs (airstrikeObject.SUcheckboxes) do
		if (cbox.GetIsChecked()) then table.insert (selectedSUs, Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits[k]); end
	end
	return selectedSUs;
end

function generateStringOfSelectedSUs ()
	airstrikeObject.strSelectedSUguids = "";
	airstrikeObject.strSelectedSUs_Names = "";
    airstrikeObject.FROMselectedSUs = {}; --to store the actual SU objects in order make a WL.Armies object and get its Attack Power
    if (airstrikeObject.SUcheckboxes == nil) then airstrikeObject.SUcheckboxes = {}; end
	if (#airstrikeObject.SUcheckboxes==0) then return; end --set empty strings if there are no checkboxes (no SUs)

	for k,cbox in pairs (airstrikeObject.SUcheckboxes) do
		if (cbox.GetIsChecked()) then
			if (airstrikeObject.strSelectedSUs_Names ~= "") then airstrikeObject.strSelectedSUs_Names = airstrikeObject.strSelectedSUs_Names .. ", "; airstrikeObject.strSelectedSUguids = airstrikeObject.strSelectedSUguids .. ","; end
			airstrikeObject.strSelectedSUguids = airstrikeObject.strSelectedSUguids .. Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits[k].ID;
			airstrikeObject.strSelectedSUs_Names = airstrikeObject.strSelectedSUs_Names .. cbox.GetText ();
            table.insert (airstrikeObject.FROMselectedSUs, Game.LatestStanding.Territories[SourceTerritoryID].NumArmies.SpecialUnits[k]); --add the SU to a table
		end
	end
	print ("Selected SU GUID string: "..airstrikeObject.strSelectedSUguids);
	print ("Selected SU name string: "..airstrikeObject.strSelectedSUs_Names);
end

function SUpanel_toggleAll ()
	if (#airstrikeObject.SUcheckboxes==0) then return; end --do nothing if there are no checkboxes (no SUs)
	for k,cbox in pairs (airstrikeObject.SUcheckboxes) do
		if (cbox.GetIsChecked()) then cbox.SetIsChecked(false); else cbox.SetIsChecked(true); end
	end
end

function SUpanel_deselectAll ()
	if (#airstrikeObject.SUcheckboxes==0) then return; end --do nothing if there are no checkboxes (no SUs)
	for k,cbox in pairs (airstrikeObject.SUcheckboxes) do cbox.SetIsChecked(false); end
end

function SUpanel_selectAll ()
	if (#airstrikeObject.SUcheckboxes==0) then return; end --do nothing if there are no checkboxes (no SUs)
	for k,cbox in pairs (airstrikeObject.SUcheckboxes) do cbox.SetIsChecked(true); end
end

function TargetTerritoryClicked(strLabelText) --TargetTerritoryInstructionLabel, TargetTerritoryBtn)
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable
    TargetTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		TargetTerritoryID = nil;
        TargetTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
	end
end

function TargetPlayerClicked(strTextLabel)
	local players = filter(Game.Game.Players, function (p) return p.ID ~= Game.Us.ID end);
	local options = map(players, PlayerButton);
	UI.PromptFromList(strTextLabel, options);
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end