function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addNewOrder) 
	--Encirclement:
	if Mod.Settings.DoNotAllowDeployments and order.proxyType == "GameOrderDeploy" and game.Game.TurnNumber > 1 then
        local t = {order.PlayerID, WL.PlayerID.Neutral};
        for connID, _ in pairs(game.Map.Territories[order.DeployOn].ConnectedTo) do
            if valueInTable(t, game.ServerGame.LatestTurnStanding.Territories[connID].OwnerPlayerID) then
                return;
            end
        end
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
        addNewOrder(WL.GameOrderCustom.Create(order.PlayerID, "Deploying armies to encircled territories is not permitted - " ..game.Map.Territories[order.DeployOn].Name, "_"))
    end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	--Encirclement:
	if Mod.Settings.RemoveArmiesFromEncircledTerrs then
        local evaluated = {};
        for terrID, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
            if not valueInTable(evaluated, terrID) and terr.OwnerPlayerID ~= WL.PlayerID.Neutral then
                local owner = terr.OwnerPlayerID;
                local b = false;
                for connID, _ in pairs(game.Map.Territories[terrID].ConnectedTo) do
                    if owner == game.ServerGame.LatestTurnStanding.Territories[connID].OwnerPlayerID then
                        table.insert(evaluated, terrID);
                        b = true;
                        break;
                    elseif game.ServerGame.LatestTurnStanding.Territories[connID].OwnerPlayerID == WL.PlayerID.Neutral then
                        b = true;
                        break;
                    end
                end
                if not b then
                    local mod = WL.TerritoryModification.Create(terrID);
                    if Mod.Settings.TerritoriesTurnNeutral then
                        mod.SetOwnerOpt = WL.PlayerID.Neutral;
                    else
                        print(Mod.Settings.PercentageLost);
                        mod.AddArmies = -math.ceil(terr.NumArmies.NumArmies * (Mod.Settings.PercentageLost / 100));
                        if terr.NumArmies.NumArmies + mod.AddArmies <= 0 then
                            mod.SetOwnerOpt = WL.PlayerID.Neutral;
                        end
                    end
                    local event = WL.GameOrderEvent.Create(owner, "Encircled player on " .. game.Map.Territories[terrID].Name, {}, {mod});
                    event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
					event.TerritoryAnnotationsOpt = {[terrID] = WL.TerritoryAnnotation.Create ("Encircled player", 8, getColourInteger (200, 0, 0))};
                    addNewOrder(event);
                end
            end
        end
    end

	--Weaken Blockades:
	local territories = game.ServerGame.LatestTurnStanding.Territories 
	local alreadyChecked = {}			-- To avoid checking territories twice in the advanced version
	WB = Mod.Settings.WeakenBlockades
	--tblprint(game.ServerGame.Game.Players)

	function baseVersion(tid, nterritory)
		connectedTerritories = game.Map.Territories[tid].ConnectedTo
		connectedTerritoriesOwners = {}
		for ID, _ in pairs(connectedTerritories) do		-- checks who are all the owners of the bordering territories
			if not connectedTerritoriesOwners[territories[ID].OwnerPlayerID] then
				connectedTerritoriesOwners[territories[ID].OwnerPlayerID] = true
			end
		end
		local length = 0
		for _ in pairs(connectedTerritoriesOwners) do
			length = length + 1
		end			-- counts how many owners there are  (It's a bit inefficent and could be optimized, but it shouldn't be that heavy anyway)
		if(length == 1 and ( next(connectedTerritoriesOwners) ~= WL.PlayerID.Neutral))then			-- if there is only one owner and they're a player
			local negArmies			-- the armies that'll be removed

			if(WB.percentualOrFixed)then
				if(WB.fixedArmiesRemoved > nterritory.NumArmies.NumArmies)then		-- if the armies removed are more than the armies on the territory 
					negArmies = -nterritory.NumArmies.NumArmies						-- remove a total of armies equal to the armies on the territory
				else																-- else
					negArmies = -WB.fixedArmiesRemoved								-- remove the presetted amount of armies
				end
			else
				negArmies = -math.max (math.floor ((nterritory.NumArmies.NumArmies * WB.percentualArmiesRemoved) / 100 + 0.5), 1); --round to nearest army and minimum 1 army reduction
			end

			if (territories[tid].NumArmies.NumArmies > 0 and negArmies ~= 0) then --don't submit order when no reduction is actually made
				local decrement = WL.TerritoryModification.Create(tid);
				decrement.AddArmies = negArmies;
				local reduction = WL.GameOrderEvent.Create(next(connectedTerritoriesOwners), "Encircled neutrals on " .. game.Map.Territories[tid].Name, {}, {decrement});
				reduction.TerritoryAnnotationsOpt = {[id] = WL.TerritoryAnnotation.Create ("Encircled neutrals", 8, getColourInteger (200, 0, 0))};
				local terr = game.Map.Territories[tid];
				reduction.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY)
				addNewOrder(reduction)			-- all the creating order and whatnot
			end
		end
	end

	function advancedVersion(tid, nterritory)
		if not alreadyChecked[tid] then
			groupNeutrals = {[tid] = true}
			terrToCheck = {}
			pbg = nil  	-- the player bordering the chunk of territories
			local result = thaSearch(tid, 0)
			if(result ~= 0 and terrToCheck ~= nil and terrToCheck ~= {})then
				for id, _ in pairs(terrToCheck) do
					if not groupNeutrals[id] then
						result = -1;
						break;
					end
				end
			end
			if(result ~= 0 and result ~= -1)then
				result = 1
			end
			if(result == 1)then
				for id, _ in pairs(groupNeutrals) do
					if(WB.percentualOrFixed)then
						if(WB.fixedArmiesRemoved > territories[id].NumArmies.NumArmies)then
							negArmies = -territories[id].NumArmies.NumArmies;
						else
							negArmies = -WB.fixedArmiesRemoved;
						end
					else
						negArmies = -math.max (math.floor ((territories[id].NumArmies.NumArmies * WB.percentualArmiesRemoved) / 100 + 0.5), 1); --round to nearest army and minimum 1 army reduction
					end

					if (territories[id].NumArmies.NumArmies > 0 and negArmies ~= 0) then --don't submit order when no reduction is actually made
						local decrement = WL.TerritoryModification.Create(id);
						decrement.AddArmies = negArmies;
						local intPlayerID = pbg or WL.PlayerID.Neutral;
						local reduction = WL.GameOrderEvent.Create(intPlayerID, "Encircled neutrals on " .. game.Map.Territories[id].Name, {}, {decrement});
						reduction.TerritoryAnnotationsOpt = {[id] = WL.TerritoryAnnotation.Create ("Encircled", 8, getColourInteger (200, 0, 0))};

						-- if pbg == nil then
						-- 	reduction = WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Decrease armies in " .. game.Map.Territories[id].Name, {}, {decrement});
						-- else
						-- 	reduction = WL.GameOrderEvent.Create(pbg, "Decrease armies in " .. game.Map.Territories[id].Name, {}, {decrement});
						-- end
						local terr = game.Map.Territories[tid];
						reduction.JumpToActionSpotOpt = WL.RectangleVM.Create(terr.MiddlePointX, terr.MiddlePointY, terr.MiddlePointX, terr.MiddlePointY)
						addNewOrder(reduction);
						alreadyChecked[id] = true
					end
				end
			elseif(result == 0)then
				if(terrToCheck ~= nil and terrToCheck ~= {})then
					for id, _ in pairs(terrToCheck) do
						alreadyChecked[id] = true
					end
				end
				for id, _ in pairs(groupNeutrals) do
					alreadyChecked[id] = true
				end
			end
		end
	end

	function thaSearch(tid, depth)
		if(depth >= 3)then
			terrToCheck[tid] = true
		else
			groupNeutrals[tid] = true
			local connectedTerritories = game.Map.Territories[tid].ConnectedTo
			for ID, cterritory in pairs(connectedTerritories) do
				if territories[ID].OwnerPlayerID == WL.PlayerID.Neutral then		-- if neutral
					if not alreadyChecked[ID] then-- and we haven't seen him yet
						if(WB.appliesToAllNeutrals or WB.appliesToMinArmies <= territories[ID].NumArmies.NumArmies)then
							local result = thaSearch(ID, depth+1)
							if(result == 0)then
								return 0;
							end
						else
							return 0;
						end
					else
						return 0
					end
				elseif pbg == territories[ID].OwnerPlayerID then	-- if we already saw them
																		-- then just keep going	
				elseif pbg ~= nil then								-- if there is someone else we already saw (that isn't the dude from the previous if)
					return 0;											-- then fuck everything 
				else												-- else
					pbg = territories[ID].OwnerPlayerID					-- they'll be the one we "already saw" in the future
				end
			end
		end
	end

	if game.ServerGame.Game.TurnNumber > WB.delayFromStart then	-- just a good load of checking if the territory meets the mod's criterias
		for tid, nterritory in pairs(territories) do	
			if(nterritory.IsNeutral)then
				if(WB.appliesToAllNeutrals or WB.appliesToMinArmies <= nterritory.NumArmies.NumArmies)then
					if(WB.ADVANCEDVERSION)then
						advancedVersion(tid, nterritory)
					else
						baseVersion(tid, nterritory)
					end
				end
			end
		end
	end
end

--Encirclement functions:
function valueInTable(t, v)
    for _, v2 in pairs(t) do
        if v == v2 then return true; end
    end
    return false;
end

--krinid functions
--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end
