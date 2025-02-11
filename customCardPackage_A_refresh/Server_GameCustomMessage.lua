require("utilities");

function Server_GameCustomMessage(game,playerID,payload,setReturn)
--[[  if(payload.PestCardPlayer~=nil)then
    PGD=Mod.PublicGameData;
    PGD.PestilenceStadium[payload.PestCardPlayer]=1;
    PlGD=Mod.PlayerGameData;
    PlGD[playerID].PestCards=Mod.PlayerGameData[playerID].PestCards-1;
    Mod.PublicGameData=PGD;
    Mod.PlayerGameData=PlGD;
  end]]

  --[[for k,v in pairs(payload) do
    print ("[S_GCM] "..k,v);
    if (k=="action") then
      if (v=="initialize_CardData") then
        --initialize_CardData (game);
        print ("try to init");
        require ("Server_Created");
        --initialize_CardData (game);

        for cardID, cardConfig in pairs(game.Settings.Cards) do
          local strCardName = getCardName_fromObject(cardConfig);
          print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces.."::");
          --cards[cardID] = strCardName;
          --count = count +1
          --printObjectDetails (cardConfig, "cardConfig");
        end
    
      end
    end
  end]]

  initialize_CardData (game);

  z = Mod.PrivateGameData.IsolationData;
  Mod.PublicGameData.IsolationData = z;


end
