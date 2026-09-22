require('Utilities');

function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'BuyRecruiter_')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		--in Client_PresentMenuUI, we stuck the territory ID after BuyRecruiter_.  Break it out and parse it to a number.
		local targetTerritoryID = tonumber(string.sub(order.Payload, 14));
		local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];
		if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
			return; --can only buy a priest onto a territory you control
		end
		
		if (order.CostOpt == nil) then
			return; --shouldn't ever happen, unless another mod interferes
		end

		local costFromOrder = order.CostOpt[WL.ResourceType.Gold]; --this is the cost from the order.  We can't trust this is accurate, as someone could hack their client and put whatever cost they want in there.  Therefore, we must calculate it ourselves, and only do the purchase if they match
		local realCost = Mod.Settings.CostToBuyRecruiter;

		if (realCost > costFromOrder) then
			return; --don't do the purchase if their cost didn't line up.  This would only really happen if they hacked their client or another mod interfered
		end

		local numRecruitersAlreadyHave = 0;
		for _,ts in pairs(game.ServerGame.LatestTurnStanding.Territories) do
			if (ts.OwnerPlayerID == order.PlayerID) then
				numRecruitersAlreadyHave = numRecruitersAlreadyHave + NumRecruitersIn(ts.NumArmies);
			end
		end

		if (numRecruitersAlreadyHave >= Mod.Settings.MaxRecruiters) then
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Skipping Recruiter purchase since max is ' .. Mod.Settings.MaxRecruiters .. ' and you have ' .. numRecruitersAlreadyHave));
			return; --this player already has the maximum number of Recruiters possible, so skip adding a new one.
		end

		local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
		builder.Name = 'Recruiter';
		builder.IncludeABeforeName = true;
		builder.ImageFilename = 'drum.png';
		builder.AttackPower = 3;
		builder.DefensePower = 3;
		builder.CombatOrder = 3416; --defends commanders
		builder.DamageToKill = 3;
		builder.DamageAbsorbedWhenAttacked = 3;
		builder.CanBeGiftedWithGiftCard = true;
		builder.CanBeTransferredToTeammate = true;
		builder.CanBeAirliftedToSelf = true;
		builder.CanBeAirliftedToTeammate = true;
		builder.IsVisibleToAllPlayers = false;
	
		local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
		terrMod.AddSpecialUnits = {builder.Build()};
		
		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a Recruiter', {}, {terrMod}));
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	
for terrID, territory in pairs(game.ServerGame.LatestTurnStanding.Territories) do

local numRecruiters = NumRecruitersIn(territory.NumArmies);
		
if numRecruiters > 0 then
    local terrMod = WL.TerritoryModification.Create(terrID);
    terrMod.AddArmies = (Mod.Settings.NumArmies * numRecruiters);
    addNewOrder(WL.GameOrderEvent.Create(territory.OwnerPlayerID, "New armies recruited", {}, {terrMod}));
end
			
end 	
	
end

function NumRecruitersIn(armies)
	local ret = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'Recruiter') then
			ret = ret + 1;
		end
	end
	return ret;
end
	
function hasNoRecruiter(armies)
    for _, sp in pairs(armies.SpecialUnits) do
        if (sp.proxyType == 'CustomSpecialUnit' and sp.Name == "Recruiter") then
            return true;
        end
    end
    return false;
end
