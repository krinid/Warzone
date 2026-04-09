function Server_StartGame (game,standing)
    local publicGameData = Mod.PublicGameData;
    print ("[START GAME - func START]");
    print ("turn#="..game.Game.TurnNumber.."::");

    --this runs just before going into T1
    --for AUTO-DIST games, prices will never be finalized b/c host never had a chance to set them until now
    --for MANUAL DIST games, host may have set the prices during Distribution; if so, finalize the prices now and permit users to buy cards on T1; if not finalized, give host until end of T1 to do so (like in AUTO-DIST games)
    --if not finalized by end of T1, auto-finalized them with default values
    print ("[START GAME] PRE check :: HostHasAdjustedPricing=="..tostring (publicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (publicGameData.CardData.CardPricesFinalized).."::");
    if (publicGameData.CardData.HostHasAdjustedPricing == true) then
        publicGameData.CardData.CardPricesFinalized = true; --flag to true so can add the order indicating that host finalized card prices at start of T1 in Server_TurnAdvance_Start
        --can't add an order here b/c the game hasn't actually begun yet, T1 isn't here yet, so there's no turn to add orders to; instead add it to start of T1 by checking value of publicGameData.CardData.CardPricesFinalized
        --addOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Game host has finalized card prices", {}, {},{}));
        Mod.PublicGameData = publicGameData;
    end
    print ("[START GAME] POST check :: HostHasAdjustedPricing=="..tostring (publicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (publicGameData.CardData.CardPricesFinalized).."::");

    print ("[START GAME - func END]");
end