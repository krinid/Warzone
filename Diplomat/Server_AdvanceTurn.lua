require('Utilities');

function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'BuyDiplomat_')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		--in Client_PresentMenuUI, we stuck the territory ID after BuyDiplomat_.  Break it out and parse it to a number.
		local targetTerritoryID = tonumber(string.sub(order.Payload, 13));
		print(string.sub(order.Payload, 13));
		print(targetTerritoryID);
		local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];
		if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
			return; --can only buy a priest onto a territory you control
		end
		
		if (order.CostOpt == nil) then
			return; --shouldn't ever happen, unless another mod interferes
		end

		local costFromOrder = order.CostOpt[WL.ResourceType.Gold]; --this is the cost from the order.  We can't trust this is accurate, as someone could hack their client and put whatever cost they want in there.  Therefore, we must calculate it ourselves, and only do the purchase if they match
		local realCost = Mod.Settings.CostToBuyDiplomat;

		if (realCost > costFromOrder) then
			return; --don't do the purchase if their cost didn't line up.  This would only really happen if they hacked their client or another mod interfered
		end

		local numDiplomatsAlreadyHave = 0;
		for _,ts in pairs(game.ServerGame.LatestTurnStanding.Territories) do
			if (ts.OwnerPlayerID == order.PlayerID) then
				numDiplomatsAlreadyHave = numDiplomatsAlreadyHave + NumDiplomatsIn(ts.NumArmies);
			end
		end

		if (numDiplomatsAlreadyHave >= Mod.Settings.MaxDiplomats) then
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Skipping Diplomat purchase since max is ' .. Mod.Settings.MaxDiplomats .. ' and you have ' .. numDiplomatsAlreadyHave));
			return; --this player already has the maximum number of Diplomats possible, so skip adding a new one.
		end

		local DiplomatPower = Mod.Settings.DiplomatPower;

		local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
		builder.Name = 'Diplomat';
		builder.IncludeABeforeName = true;
		builder.ImageFilename = 'truce.png';
		builder.AttackPower = 1;
		builder.DefensePower = 1;
		builder.CombatOrder = 3415; --defends commanders
		builder.DamageToKill = 1;
		builder.DamageAbsorbedWhenAttacked = 1;
		builder.CanBeGiftedWithGiftCard = true;
		builder.CanBeTransferredToTeammate = true;
		builder.CanBeAirliftedToSelf = true;
		builder.CanBeAirliftedToTeammate = true;
		builder.IsVisibleToAllPlayers = false;
	
		local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
		terrMod.AddSpecialUnits = {builder.Build()};
		
		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a Diplomat', {}, {terrMod}));
	end
    if order.proxyType == "GameOrderAttackTransfer" then
		if orderResult.IsAttack and hasNoDiplomat(game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies) then
			local p2 = deadDiplomat(orderResult.DefendingArmiesKilled); --returns nil if no Diplomats killed, returns playerID of owner of the 1st Diplomat killed if 1+ Diplomats are killed
			if (p2 ~= nil) then
				local p = order.PlayerID; -- the attacker
				-- local p2 = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID; --player that was attacked
				if game.Settings.Cards ~= nil then
					if game.Settings.Cards[WL.CardID.Diplomacy] ~= nil then
							local instance = WL.NoParameterCardInstance.Create(WL.CardID.Diplomacy);
							addNewOrder(WL.GameOrderReceiveCard.Create(p, {instance}));
							addNewOrder(WL.GameOrderPlayCardDiplomacy.Create(instance.ID, p, p, p2));
					end
				end
			end
		end
    end
end

function NumDiplomatsIn(armies)
	local ret = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'Diplomat') then
			ret = ret + 1;
		end
	end
	return ret;
end

function hasNoDiplomat(armies)
    for _, sp in pairs(armies.SpecialUnits) do
        if sp.proxyType == "CustomSpecialUnit" and sp.Name == "Diplomat" then
            return true;
        end
    end
    return false;
end

function deadDiplomat(army)
    for _, sp in pairs(army.SpecialUnits) do
        if sp.proxyType == "CustomSpecialUnit" and sp.Name == "Diplomat" then
            return sp.OwnerID;
            -- return true;
        end
    end
    return nil;
end

function round(n)
    return math.floor(n + 0.5);
end
