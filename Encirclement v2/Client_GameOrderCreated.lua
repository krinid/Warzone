function Client_GameOrderCreated(game, order, skipOrder)
    if Mod.Settings.DoNotAllowDeployments and order.proxyType == "GameOrderDeploy" then
        local p = game.Us.ID;
        local terrID = order.DeployOn;
        local isEncircled = true;
        for connID, _ in pairs(game.Map.Territories[terrID].ConnectedTo) do
            local terr = game.LatestStanding.Territories[connID];
            if terr.OwnerPlayerID == p or terr.OwnerPlayerID == WL.PlayerID.Neutral then
                isEncircled = false;
                break;
            end
        end
        if isEncircled then
            UI.Alert("You cannot deploy armies to '" .. game.Map.Territories[terrID].Name .. "' because it is encircled\n\nUnless required to do so, you should deploy armies elsewhere");
        end
    end
end