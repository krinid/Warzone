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

	local eventOrder = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Portals swap units", nil, TerritoryModifications, nil);
	eventOrder.TerritoryAnnotationsOpt = { TerritoryModifications = WL.TerritoryAnnotation.Create ("Portal Swap", 3, getColourInteger (255, 0, 255)) }; --purple annotation for Portal Swap
			-- table.insert (modifiedTerritories, impactedTerritory); --add territory object to the table to be passed back to WZ to modify/add the order for all impacted territories
			-- annotations [terrID] = WL.TerritoryAnnotation.Create (".", 3, getColourInteger (255, 0, 0)); --add small sized Annotation in Red for Punishment
			-- terrID_somewhereInThePunishment = terrID;
	addNewOrder(eventOrder);
end

function terrModHelper(targetTerritory, sourceTerritory)
print ("::"..targetTerritory, sourceTerritory)
	local terrMod = WL.TerritoryModification.Create (targetTerritory)

	terrMod.SetArmiesTo = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].NumArmies.NumArmies
	terrMod.SetOwnerOpt = Game.ServerGame.LatestTurnStanding.Territories[sourceTerritory].OwnerPlayerID

	return terrMod
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end
