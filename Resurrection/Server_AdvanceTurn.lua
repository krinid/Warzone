function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)

    --if order is an attack on a territory with special units and >0 is set to die, check if a Commander is about to die; if so, check if they have a Resurrection card in hand
    --don't check for and result.IsSuccessful b/c it's possible there are >=1 Commanders and/or other units (Monolith, etc) with higher combat order whereby Commander still dies even if the territory isn't captured
    if (order.proxyType=='GameOrderAttackTransfer' and result.IsAttack and #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits >0 and #result.DefendingArmiesKilled.SpecialUnits >0) then
        print ("proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #result.DefendingArmiesKilled.SpecialUnits.."::");
        local targetTerritory = WL.TerritoryModification.Create(order.To);
        local modifiedTerritories = {};
        --table.insert (modifiedTerritories, toTerritory);
        --local event = WL.GameOrderEvent.Create(order.PlayerID, "code moved "..intNumArmiesToTransfer.." armies from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game), {}, modifiedTerritories);
        --addOrder(event, false);
        --skip(WL.ModOrderControl.Skip); --cancel orig attack, b/c it'd stop the MA operations; hopefully this will let it continue indefinitely

        for k,sp in pairs (result.DefendingArmiesKilled.SpecialUnits) do
            local Commander_OwnerID = sp.OwnerID;
            -- &&& check if Commander_OwnerID holds a Resurrection card; note: don't check for owner of order.To just in case the Commander of another player exists on the territory
            print ("SP killed: "..k, sp.proxyType);
            targetTerritory.RemoveSpecialUnitsOpt = {sp.ID}; --remove the C special unit from the territory
            table.remove (result.DefendingArmiesKilled.SpecialUnits, k); --remove the Commander from the list of specials being killed
            table.insert (modifiedTerritories, targetTerritory); --add territory manipulation to modifiedTerritories table to be added to the Event
            local event = WL.GameOrderEvent.Create(order.PlayerID, "Commander was killed, but somehow he returned", {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
            addOrder (event, false); --add a new order; call the addOrder parameter (which is in itself a function) of this function

			local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, order.NumArmies, order.AttackTeammates);
			addOrder (replacementOrder);

			print ("proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #result.DefendingArmiesKilled.SpecialUnits.."::");
	        skip(WL.ModOrderControl.Skip);
            --write some data in PublicGameData to be retrieved in Client_GameRefresh so player can place Commander on board
        end
    end

    --[[if (#order.NumArmies.SpecialUnits>0) then
        --local numArmies = orderArmies.Subtract(WL.Armies.Create(0, commanders));
        local newOrder = nil;
        print ("[TRIP!] _________________________________"); --..order.ByPercent);
        --newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(3), order.AttackTeammates);
        --newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(order.NumArmies.NumArmies), order.AttackTeammates);
        --addOrder(newOrder);
        --skip(WL.ModOrderControl.Skip);

        --remove commander = dies?
        local impactedTerritory = WL.TerritoryModification.Create(order.From);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
        local specialUnitID = nil;
        specialUnitID = order.NumArmies.SpecialUnits[1].ID;
        print ("terr=="..order.From..", SUID=="..specialUnitID);
        impactedTerritory.RemoveSpecialUnitsOpt = {specialUnitID}; --remove the C special unit from the territory
        --impactedTerritory.SetOwnerOpt=impactedTerritoryOwnerID;
        --local strDeneutralizeOrderMessage = toPlayerName(gameOrder.PlayerID, game) ..' deneutralized ' .. targetTerritoryName .. ', assigned to '..impactedTerritoryOwnerName;
        --print ("message=="..strDeneutralizeOrderMessage);
        local event = WL.GameOrderEvent.Create(order.PlayerID, "remove C", {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
        addOrder (event, false); --add a new order; call the addOrder parameter (which is in itself a function) of this function
        print ("[END]");
        skip(WL.ModOrderControl.Skip);

        return;

        --if isAttackTransfer then
        --	newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, numArmies, order.AttackTeammates);
        --elseif isAirlift then
        --	newOrder = WL.GameOrderPlayCardAirlift.Create(order.CardInstanceID, order.PlayerID, order.FromTerritoryID, order.ToTerritoryID, numArmies);
        --end]]

end

