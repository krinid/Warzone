-- popup a note in Client_GameRefresh to notify game host of need to set card prices

function Server_Created (game, settings)
    print ("[SERVER CREATED] START");
    local publicGameData = Mod.PublicGameData;
    publicGameData.CardData = {};
    publicGameData.CardData.DefinedCards = nil;
    Mod.PublicGameData = publicGameData;

    --use this is Client hooks
    --publicGameData.localPlayerIsHost = (game.Us.ID == game.Settings.StartedBy); --compare local playerID to game creator ID, if true->client player is the game host, so using this setting can permit that player to set prices for custom cards by end of T1

    getDefinedCardList (game); --save defined card list into Mod.Settings.CardData
    showDefinedCards ();
    print ("[SERVER CREATED] END");

    --cost of custom cards if not specified by host by end of T1 = d*r/g
    --r=# pieces required & g=# pieces granted per turn, where a low g/r means higher value = higher cost
    --d=default cost for example 100 gold
end

function showDefinedCards ()
    print ("[SERVER CREATED] CARD OVERVIEW");

    local publicGameData = Mod.PublicGameData;
    local cards = publicGameData.CardData.DefinedCards;

    local strText = "";
    for k,v in pairs (cards) do
            strText = strText .. "\n"..v.Name.." / ("..v.Price..") / ["..k.."]"; --end --cardID's for custom cards start at >1000000
    end
    print (strText);
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
    function getDefinedCardList (game)
        print ("[CARDS DEFINED IN THIS GAME]");
        local count = 0;
        local cards = {};
        local publicGameData = Mod.PublicGameData;

        publicGameData.CardData.HostHasAdjustedPricing = false; --this will change to True when host updates card prices
        publicGameData.CardData.CardPricesFinalized = false;    --this will change to True when host updates pricing and the Server_TurnAdvance_Start executes; if not finalized by end of T1, prices will be automatically finalized; players including host cannot buy cards until prices are finalized
    
        --if CardData structure isn't defined (eg: from an ongoing game before this was done this way), then initialize the variable and populate the list here
        if (publicGameData.CardData==nil) then publicGameData.CardData = {}; publicGameData.CardData.DefinedCards = nil; end
    
        if (publicGameData.CardData.DefinedCards ~= nil) then
            print ("[CARDS ALREADY DEFINED] don't regen list, just return existing table");
            return publicGameData.CardData.DefinedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
        else
            print ("[CARDS NOT DEFINED] generate the list, store it in publicGameData.CardData.DefinedCards");
            if (game==nil) then print ("game is nil"); return nil; end
            if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
            if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end
            print ("game==nil --> "..tostring (game==nil).."::");
            print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
            print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
            print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
            print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
            print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
            print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));
        
            for cardID, cardConfig in pairs(game.Settings.Cards) do
                local strCardName = getCardName_fromObject(cardConfig);
                local cardPrice = 0;
                local defaultCost = 1; --set default cost of custom cards to 50, final price to be defaultCost * ratio of #piecesRequired/#piecesGivenPerTurn - rough estimate of worth of card in lieu of host setting a manual value by end of T1
                count = count +1
                --printObjectDetails (cardConfig, "cardConfig");

                if (strCardName == "Reinforcement") then
                    cardPrice = Mod.Settings.ReinforcementCardCost;
                elseif (strCardName == "Gift") then
                    cardPrice = Mod.Settings.GiftCardCost;
                elseif (strCardName == "Spy") then
                    cardPrice = Mod.Settings.SpyCardCost;
                elseif (strCardName == "Emergency Blockade") then
                    cardPrice = Mod.Settings.EmergencyBlockadeCardCost;
                elseif (strCardName == "Blockade") then
                    cardPrice = Mod.Settings.BlockadeCardCost;
                elseif (strCardName == "Order Priority") then
                    cardPrice = Mod.Settings.OrderPriorityCardCost;
                elseif (strCardName == "Order Delay") then
                    cardPrice = Mod.Settings.OrderDelayCardCost;
                elseif (strCardName == "Airlift") then
                    cardPrice = Mod.Settings.AirliftCardCost;
                elseif (strCardName == "Diplomacy") then
                    cardPrice = Mod.Settings.DiplomacyCardCost;
                elseif (strCardName == "Sanctions") then
                    cardPrice = Mod.Settings.SanctionsCardCost;
                elseif (strCardName == "Reconnaissance") then
                    cardPrice = Mod.Settings.ReconnaissanceCardCost;
                elseif (strCardName == "Surveillance") then
                    cardPrice = Mod.Settings.SurveillanceCardCost;
                elseif (strCardName == "Bomb") then
                    cardPrice = Mod.Settings.BombCardCost;
                else
                    if (cardConfig.MinimumPiecesPerTurn<=0) then  --don't divide by 0; modify default price to defaultCost * #piecesRequired
                        cardPrice = defaultCost*cardConfig.NumPieces;
                    else --if #piecesGiven per turn >0 then divide by it to get a good estimate for default cost of card; if #piecesGiven per turn==1 then will be the same, and reduce for each additional card piece
                        cardPrice = defaultCost*(cardConfig.NumPieces/cardConfig.MinimumPiecesPerTurn); --set a default cost of 100 * ratio of (#pieces required/#pieces given each turn) as approximation of the card's worth; host can set manual value before end of T1
                    end 
                end 

                cards[cardID] = {Name=strCardName, Price=cardPrice, ID=cardID};
                print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces..", price=="..cardPrice.."::");
            end
            print (count .." defined cards total");
            publicGameData.CardData.DefinedCards = cards;
            Mod.PublicGameData = publicGameData;
            return cards;
        end
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
    
        for cardID, strCardName in pairs(cards) do
            if (strCardName == strCardNameToMatch) then
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