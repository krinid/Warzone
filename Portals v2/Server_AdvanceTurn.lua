function Server_AdvanceTurn_End(game, addNewOrder)
	Game = game
	TerritoryModifications = {}
	local intNumPortals = Mod.Settings.NumPortals;

	--Swap the standing (owner, armies) of the connected portals
	for i = 1, #Mod.PrivateGameData.Portals do
		if (i <= intNumPortals) then -- for 3 portals: 1, 2, 3 swap with 4, 5, 6
print ("@@1 " ..i, i+intNumPortals, intNumPortals);
			TerritoryModifications[i] = terrModHelper (Mod.PrivateGameData.Portals[i], Mod.PrivateGameData.Portals [tonumber (i + intNumPortals)])
		else
print ("@@2 " ..i, i-intNumPortals, intNumPortals);
			TerritoryModifications[i] = terrModHelper (Mod.PrivateGameData.Portals[i], Mod.PrivateGameData.Portals [tonumber (i - intNumPortals)])
		end
	end

	addNewOrder(WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Portals swap units", nil, TerritoryModifications, nil))
end

function terrModHelper(targetTerritory, sourceTerritory)
print ("::"..targetTerritory, sourceTerritory)
	local terrMod = WL.TerritoryModification.Create (targetTerritory)

	terrMod.SetArmiesTo = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].NumArmies.NumArmies
	terrMod.SetOwnerOpt = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].OwnerPlayerID

	return terrMod
end