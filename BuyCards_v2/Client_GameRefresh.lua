function Client_GameRefresh(clientGame)
    if (clientGame == nil) then print ("[CLIENTGAME is nil]"); return; end
    if (clientGame.Us == nil) then print ("[CLIENTGAME.Us is nil]"); return; end --player is probably a spectator, do nothing, just return

    local localPlayerIsHost = clientGame.Us.ID == clientGame.Settings.StartedBy;
    if (boolHostToSetPrices_AntiNag == nil) then boolHostToSetPrices_AntiNag = false; end --when set to true, host has already been nagged about setting prices this session, so don't nag again

    --if not Commerce game, do nothing; if not host, do nothing; if Commercer game & local player is host & prices have not been set, send alert to advise player to set card prices, but only if they haven't been nagged already
    if (clientGame.Settings.CommerceGame == true and localPlayerIsHost==true and Mod.PublicGameData.CardData.HostHasAdjustedPricing==false and boolHostToSetPrices_AntiNag == false) then
        UI.Alert ("You are the game host.\n\nPlease go to Game/Mod: Buy Cards v2, set the card prices, then click 'Update Prices'.");
        boolHostToSetPrices_AntiNag = true;
    end
end