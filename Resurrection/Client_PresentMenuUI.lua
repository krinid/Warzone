function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
    --newGame = game;
    UIcontainer = UI.CreateVerticalLayoutGroup (rootParent);
    UI.CreateLabel (UIcontainer).SetText ("Resurrection whole cards & pieces:");
    print ("---PresentMenu---");
    if (game.Us ~= nil) then game.SendGameCustomMessage ("[waiting for server response]", {action="do nothing_just force a refresh"}, PresentMenuUI_callBack); end

    for k,cardRecord in pairs (game.LatestStanding.Cards) do
        --UI.CreateLabel (UIcontainer).SetText ("Player "..k);
        if (#cardRecord.Pieces==0) then UI.CreateLabel (UIcontainer).SetText ("Player "..k.." -- no card pieces"); end
        for cardPieceID,numPieces in pairs (cardRecord.Pieces) do
            UI.CreateLabel (UIcontainer).SetText ("Player "..k .."; card pieces: "..cardPieceID.."/"..numPieces);
        end
        if (#cardRecord.WholeCards==0) then UI.CreateLabel (UIcontainer).SetText ("Player "..k.." -- no whole cards"); end
        for cardInstanceID,wholeCard in pairs (cardRecord.WholeCards) do
            UI.CreateLabel (UIcontainer).SetText ("Player "..k .."; whole cards: "..wholeCard.CardID);
            --UI.CreateLabel (UIcontainer).SetText ("Player "..k .."; whole cards: "..wholeCard.CardID.."/"..cardInstanceID); --.."/"..wholeCard.ID); --wholeCard.ID is the cardInstance ID which is the key of cardRecord.WholeCards to don't display it twice
            --print ("check "..newGame.LatestStanding.Cards[k].WholeCards[cardInstanceID].CardID);
            --newGame.LatestStanding.Cards[k].WholeCards[cardInstanceID]={};
            --print ("check "..newGame.LatestStanding.Cards[k].WholeCards[cardInstanceID].CardID);
            --print ("check2 "..#(newGame.LatestStanding.Cards[k].WholeCards));
            --table.remove (newGame.LatestStanding.Cards[k].WholeCards, 1);
            --print ("check2 "..#(newGame.LatestStanding.Cards[k].WholeCards));
            --print ("check "..newGame.LatestStanding.Cards[k].WholeCards[cardInstanceID].CardID);
        end
    end
    --game = newGame;

    UI.CreateLabel (UIcontainer).SetText ("\nCommander must die to use Resurrection: " .. tostring (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies));

    UI.CreateLabel (UIcontainer).SetText ("\nResurrection data:");
    if (Mod.PublicGameData.ResurrectionData ~= nil) then
        if (next(Mod.PublicGameData.ResurrectionData) == nil) then
            UI.CreateLabel (UIcontainer).SetText ("No resurrections pending");
            print ("[GAME REFRESH] Resurrection data next=nil; no resurrections pending");
        end

        for playerID,v in pairs (Mod.PublicGameData.ResurrectionData) do
            print ("[GAME REFRESH] Resurrecton pending;  player "..tostring (playerID).."/"..tostring (v));
            UI.CreateLabel (UIcontainer).SetText ("Resurrecton pending for "..tostring (playerID).."/"..tostring (v));
        end
    else
        UI.CreateLabel (UIcontainer).SetText ("No resurrections pending");
        print ("[GAME REFRESH] Resurrection data nil; no resurrections pending");
    end
end

function PresentMenuUI_callBack (table)
    for k,v in pairs (table) do
        print ("[C_PMUI_CB] "..k,v);
        CreateLabel (MenuWindow).SetText ("[C_PMUI] "..k.."/"..v);
    end
end