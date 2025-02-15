--if host tries to Commit w/o setting card prices, send alert & force configuration
function Client_GameCommit (game, skipCommit)
    local publicGameData = Mod.PublicGameData;
    if (Mod.PublicGameData.CardData.HostHasAdjustedPricing==false) then
        UI.Alert ("You are the game host, but have not configured card prices. Please go to Game/Mod: Buy Cards v2, set the card prices, then click 'Update Prices' in order to finalize the prices and enabled players to begin purchasing cards.");
        skipCommit ();
    end
end