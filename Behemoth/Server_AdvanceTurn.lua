--require('Utilities');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
    if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'Behemoth|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		local orderComponents = split(order.Payload, '|');
		--reference: 	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothGoldSpent;
		local strOperation = orderComponents[2];
		local targetTerritoryID = tonumber(orderComponents[3]);
		local goldSpent = tonumber(orderComponents[4]);

		if (strOperation == "Purchase") then
			createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent);
		else
			print ("[BEHEMOTH] unsupported operation: " .. strOperation);
			return;
		end
	end
end

function createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent)
	--in Client_PresentMenuUI, we stuck the territory ID after BuyTank_.  Break it out and parse it to a number.

	local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];

	if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
		return; --can only buy a tank onto a territory you control
	end

	if (order.CostOpt == nil) then
		return; --shouldn't ever happen, unless another mod interferes
	end

	--[[local costFromOrder = order.CostOpt[WL.ResourceType.Gold]; --this is the cost from the order.  We can't trust this is accurate, as someone could hack their client and put whatever cost they want in there.  Therefore, we must calculate it ourselves, and only do the purchase if they match
	local realCost = Mod.Settings.CostToBuyTank;
	if (realCost > costFromOrder) then
		return; --don't do the purchase if their cost didn't line up.  This would only really happen if they hacked their client or another mod interfered
	end]]

	--[[local numTanksAlreadyHave = 0;
	for _,ts in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if (ts.OwnerPlayerID == order.PlayerID) then
			numTanksAlreadyHave = numTanksAlreadyHave + NumTanksIn(ts.NumArmies);
		end
	end

	if (numTanksAlreadyHave >= Mod.Settings.MaxTanks) then
		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Skipping tank purchase since max is ' .. Mod.Settings.MaxTanks .. ' and you have ' .. numTanksAlreadyHave));
		return; --this player already has the maximum number of tanks possible, so skip adding a new one.
	end]]

	local behemothPowerFactor = 0.01;
	--local behemothPower = math.max (behemothPowerFactor * (goldSpent^3) + behemothPowerFactor * (goldSpent^2) + behemothPowerFactor * goldSpent, 0);
	local behemothPower = math.max (behemothPowerFactor * (goldSpent^2), 1);

	local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
	builder.Name = 'Behemoth (power '.. behemothPower ..')';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'Behemoth_clearback.png'; --max size of 60x100 pixels
	--builder.ImageFilename = 'monolith special unit_clearback.png'; --max size of 60x100 pixels
	builder.AttackPower = behemothPower;
	builder.DefensePower = behemothPower*0.1;
	builder.AttackPowerPercentage = 1.1;  --0.0 means -100% attack damage (the damage this unit does when attacking); 1.0=regular attack damage; >1.0 means bonus attack damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	builder.DefensePowerPercentage = 0.9; --0.0 means -100% defense damage (the damage this unit does when attacking); 1.0=regular defense damage; >1.0 means bonus defense damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	builder.CombatOrder = -1; --fights before armies
	--builder.DamageToKill = behemothPower;
	builder.Health = behemothPower;
	builder.DamageAbsorbedWhenAttacked = behemothPower*0.1;
	builder.CanBeGiftedWithGiftCard = true;
	builder.CanBeTransferredToTeammate = true;
	builder.CanBeAirliftedToSelf = true;
	builder.CanBeAirliftedToTeammate = true;
	builder.IsVisibleToAllPlayers = false;
	--builder.TextOverHeadOpt = "Behemoth (power "..behemothPower..")";
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = "This unit's power scales with the amount of resources uses to spawn it."}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector

	local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
	terrMod.AddSpecialUnits = {builder.Build()};

	addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a Behemoth with power '..behemothPower, {}, {terrMod}));
end

function getBehemothPower (goldSpent)
	local power = 0;
	if (goldSpent <= 0) then return 0; end
	--if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
	power = power + math.min ((goldSpent/50)*goldSpent, 25);
	if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
	if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
	if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
	if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
	if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
	power = math.floor (math.max (1, power)+0.5);

	power = 0;
	power = power + math.min ((goldSpent/75)*goldSpent, 50);
	power = power + math.min ((goldSpent/150)*goldSpent, 100);
	power = power + math.min ((goldSpent/600)*goldSpent, 500);
	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
	power = power + (goldSpent/10000)*goldSpent;
	power = math.floor (math.max (1, power)+0.5);
	return power;
end

function NumTanksIn(armies)
	local ret = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'Tank') then
			ret = ret + 1;
		end
	end
	return ret;
end

function split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end