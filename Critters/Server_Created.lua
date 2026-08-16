require("utilities");

function Server_Created (game, settings)
    print ("[SERVER CREATED] START");
    initialize_debug_data (); --initialize data structures for outputting debug data from Server hooks to Client hooks for local client side display

    local privateGameData = Mod.PrivateGameData;
    local publicGameData = Mod.PublicGameData;
    privateGameData.NeutralizeData = {};   --set NeutralizeData to empty (initialize)
    publicGameData.IsolationData = {};    --set IsolationData to empty (initialize)
    publicGameData.PestilenceData = {};    --set PestilenceData to empty (initialize)
    privateGameData.ShieldData = {};     --set MonolithData to empty (initialize)
    privateGameData.MonolithData = {};     --set MonolithData to empty (initialize)
    privateGameData.PhantomData = {};      --set PhantomData to empty (initialize)
    publicGameData.CardBlockData = {};     --set CardBlockData to empty (initialize)
    publicGameData.TornadoData = {};       --set TornadoData to empty (initialize)
    publicGameData.QuicksandData = {};       --set TornadoData to empty (initialize)
    publicGameData.EarthquakeData = {};       --set TornadoData to empty (initialize)
    publicGameData.CardData = {};          --saves data for all defined cards including custom mods & the cardID for CardPieces card so can't use it to redeem CardPieces cards/pieces; set CardCardData to empty (initialize)
    publicGameData.CardData.DefinedCards = nil;
    publicGameData.CardData.CardPiecesCardID = nil;
    Mod.PrivateGameData = privateGameData;
    Mod.PublicGameData = publicGameData;

    for k,v in pairs (settings.Cards) do
        print (k,v.CardID);
    end

    --enable Airlift if Airstrike module is enabled
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Airstrike == true) then
        --check if Airlift card is enabled
        --print (WL.TurnPhase.ToString(WL.TurnPhase.SanctionCards));   --  <--- this works, it displays "SanctionCards"
        --print (WL.CardID.ToString(WL.CardID.Airlift)); -- <--- doesn't work b/c this isn't an Enum, it's just a constant

        print ("Airstrike enabled==true; module present; Airlift enabled=="..tostring (settings.Cards[WL.CardID.Airlift]~=nil)..", Airlift CardID=="..WL.CardID.Airlift);
        WL.TurnPhase.ToString(WL.TurnPhase.SanctionCards)
        --WL.TurnPhase.ToString(...)
        if (settings.Cards[WL.CardID.Airlift]==nil) then
            print ("[ENABLE AIRLIFT]");
            local cardGameAirlift = WL.CardGameAirlift.Create(999, 0, 0.0, 0); --numPieces, minPerTurn, weight, initialPieces
            --reference: WL.CardGameAirlift.Create(numPieces integer, minPerTurn integer, weight number, initialPieces integer) (static) returns CardGameAirlift:
            local newSettings = settings;
            local newCards = settings.Cards;
            newSettings.Cards[WL.CardID.Airlift] = cardGameAirlift;
            newCards[WL.CardID.Airlift] = cardGameAirlift;

            --not sure why but must re-assign all the existing cards again; probably something to do with how Lua handles non-contiguous element arrays
            for k, v in pairs(game.Settings.Cards) do
                newCards[k] = v;
            end
            settings.Cards = newCards;
        end
        print ("Airstrike enabled==true; module present; Airlift enabled=="..tostring (settings.Cards[WL.CardID.Airlift]~=nil)..", Airlift CardID=="..WL.CardID.Airlift);
    end
    --for k,v in pairs (settings.Cards) do
    --  print (k,v.CardID);
    --end

    initialize_CardData (game); --save defined card list into Mod.Settings.CardData
    --print ("game.Settings.Cards==nil --> "..tostring(game.Settings.Cards==nil));
    --print ("game.Settings==nil --> "..tostring(game.Settings==nil));
    --print ("game.Settings.Cards==nil --> "..tostring(game.Settings.Cards==nil));
    --print ("settings==nil --> "..tostring(settings==nil));
    --print ("settings.Cards==nil --> "..tostring(settings.Cards==nil));

    --printObjectDetails (cards, "cards", count .." defined cards total", game);

    --[[Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData.CardData.DefinedCards = getDefinedCardList (game);
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList

    printObjectDetails (Mod.PublicGameData.CardData.DefinedCards, "card PGD", "");--count .." defined cards total", game);
    print ("09----------------------");

    --if Mod.Settings.CardPiecesCardID is set, grab the cardID from this setting
    --standalone app can't grab this yet, need a new version
    if (Mod.Settings.CardPiecesCardID == nil) then
        print ("[CardPiece CardID] get from getCardID function");
        publicGameData.CardData.CardPiecesCardID = getCardID ("Card Piece");
        print ("10----------------------");
    else
        print ("[CardPiece CardID] acquired from Mod.Settings.CardPiecesCardID");
        publicGameData.CardData.CardPiecesCardID = Mod.Settings.CardPiecesCardID;
        print ("11----------------------");
    end
    print ("[CardPiece CardID] Mod.Settings.CardPiecesCardID=="..tostring (Mod.Settings.CardPiecesCardID));
    print ("12----------------------");]]

    print ("[SERVER CREATED] PrivateGameData & PublicGameData constructs initialized");

    --printObjectDetails (Mod.PublicGameData.CardData, "all card data", "");
    --printObjectDetails (Mod.PublicGameData.CardData.DefinedCards, "defined cards", "");
    --printObjectDetails (Mod.PublicGameData.CardData.CardPiecesCardID, "CardPiece cardID", "");

    print ("turn#="..game.Game.TurnNumber.."::");
    --dataStorageTest ();
    print ("[SERVER CREATED] END");
end

function dataStorageTest_pre ()
    --privateGameData = {NeutralizeData={1, "b", 3, "d"},   --set NeutralizeData to empty
    print ("[TEST private data]");
    for key,data in pairs(Mod.PrivateGameData) do
        print (key, data);
    end
    --[[print ("[TEST private data - NeutralizeData]");
    for key,data in pairs (Mod.PrivateGameData.NeutralizeData) do
        print (key, data);
    end
    printObjectDetails (Mod.PrivateGameData.NeutralizeData, "neuData");
    print ("display contents");
    --printObjectDetails ({"someobject", "somevalue"}, "randomobject");
    printObjectDetails (Mod.PublicGameData, "[public data]");
    printObjectDetails (Mod.PublicGameData.IsolatedTerritories, "[public data - isodata]");
    printObjectDetails (Mod.PrivateGameData, "[public data]");
    printObjectDetails (Mod.PrivateGameData.NeutralizeData, "[private data - neutralize data]");]]
end

function dataStorageTest ()
    -- test writing to Mod.PublicGameData, Mod.PrivateGameData, Mod.PlayerGameData
    -- all data must be saved to a code construct, then have the code construct assigned the the Mod.Public/Private/PlayerGameData construct; can't modify variable values directly
      local data = Mod.PublicGameData;
      publicGameData = Mod.PublicGameData; --readable from anywhere, writeable only from Server hooks
      privateGameData = Mod.PrivateGameData;  --readable only from Server hooks
      playerGameData = Mod.PlayerGameData;  --readable/writeable from both Client & Server hooks
          --Client hooks can only access data for the user associated with the Client hook (current player), doesn't need index b/c it can only access data for current player, automatically gets assigned playerID of current player
          --Server hooks access this using an index of playerID
          --but can't use [0]~[49], and can only use playerID #'s that are actually in the game, violations will generate 'trying to index nil' errors
          --best to abandon use of PlayerGameData & just use PublicGameData & PrivateGameData
      publicGameData.someProperty = "this is some public data";
      publicGameData.anotherProperty = "here is some more public data";
      publicGameData.wantMore = "would you like some more? (public ... data)";
    
      print ("[public data]");
      for key,data in pairs(publicGameData) do
          print (key, data);
      end

      privateGameData.someProperty = "this is some private data";
      privateGameData.anotherProperty = "here is some more private data";
      privateGameData.wantMore = "would you like some more? (private ... data)";
    
      print ("[private data]");
      for key,data in pairs(privateGameData) do
          print (key, data);
      end

      --1058239 = krinid
      --[[playerGameData[0].someProperty = "this is some player data [neutral?]";
      playerGameData[0].anotherProperty = "here is some more player data [neutral?]";
      playerGameData[0].wantMore = "would you like some more? (player ... data [neutral?])";
      
      playerGameData[1].someProperty = "this is some player data [AI1?]";
      playerGameData[1].anotherProperty = "here is some more player data [AI1?]";
      playerGameData[1].wantMore = "would you like some more? (player ... data [AI1?])";
      ]]
      playerGameData[1058239].someProperty = "this is some player 1058239 data";
      playerGameData[1058239].anotherProperty = "here is some more player 1058239 data";
      playerGameData[1058239].wantMore = "would you like some more? (player 1058239 ... data)";

      --playerGameData[4545454].wantMore = "just a random # and some text";

      print ("[player data]");
      --[[for key,data in pairs(playerGameData[0]) do
          print (key, data);
      end

      for key,data in pairs(playerGameData[1]) do
        print (key, data);
      end]]

      for key,data in pairs(playerGameData[1058239]) do
        print (key, data);
      end
end