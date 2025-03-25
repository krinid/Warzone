--if host tries to Commit w/o setting card prices, send alert & force configuration
function Client_GameCommit (game, skipCommit)
	local localPlayerIsHost = game.Us.ID == game.Settings.StartedBy;

    --if not Commerce game, do nothing; if not host, do nothing; if Commercer game & this is host & prices have not been set, send alert to advise player to set card prices & cancel commit 
    if (game.Settings.CommerceGame == true and localPlayerIsHost==true and Mod.PublicGameData.CardData.HostHasAdjustedPricing==false) then
        UI.Alert ("You are the game host, but have not configured card prices. Please go to Game/Mod: Buy Cards v2, set the card prices, then click 'Update Prices' in order to finalize the prices and enabled players to begin purchasing cards.");
        skipCommit ();
    end
end