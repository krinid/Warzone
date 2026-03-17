require ('utilities');

---Client_PresentMenuUI hook
---@param rootParent RootParent
---@param setMaxSize fun(width: number, height: number) # Sets the max size of the dialog
---@param setScrollable fun(horizontallyScrollable: boolean, verticallyScrollable: boolean) # Set whether the dialog is scrollable both horizontal and vertically
---@param game GameClientHook
---@param close fun() # Zero parameter function that closes the dialog
function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
    if (game.Us == nil) then return; end --player not in the game; spectator

    --initialize_CardData (game);
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.CardData == nil) then publicGameData.CardData = {}; end
    publicGameData.CardData.ResurrectionCardID = tostring(getCardID ("Resurrection", game));
    local CommanderOwner_ResurrectionCard = playerHasCard_client (game.Us.ID, publicGameData.CardData.ResurrectionCardID, game); --get card instance ID of player's Resurrection card

    print ("Res cardID " ..tostring (publicGameData.CardData.ResurrectionCardID)..", Res card instance ID ".. tostring (CommanderOwner_ResurrectionCard));
--[[     if (CommanderOwner_ResurrectionCard~=nil) then
        --event.RemoveWholeCardsOpt = {[playerID] = CommanderOwner_ResurrectionCard};
    else
        print ("[RESURRECTION PLACE ON MAP] failed to get card instance of Resurrection card, can't consume whole card piece");
    end ]]
end

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function playerHasCard_client (playerID, cardID, game)
	if (playerID<=0) then print ("playerID is neutral (has no cards)"); return nil; end
	if (cardID==nil) then print ("cardID is nil"); return nil; end
            --print ("check "..newGame.LatestStanding.Cards[k].WholeCards[cardInstanceID].CardID);

    -- if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
    if (game.LatestStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end

    for k,v in pairs (game.LatestStanding.Cards[playerID].WholeCards) do
		if (v.CardID == cardID) then return k; end
	end
	return nil;
end