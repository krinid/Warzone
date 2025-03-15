function Server_AdvanceTurn_End(game, addNewOrder)
	--uncomment the below line to forcibly halt execution for troubleshooting purposes
	--print ("[FORCIBLY HALTED EXEUCTION @ END OF TURN]"); toriaezu_stop_execution();
	print ("[GRACEFUL END OF TURN EXECUTION]");
end

function Server_AdvanceTurn_Start (game,addNewOrder)
	--delete all AI orders
end

function Server_AdvanceTurn_Order(game, order, result, skip, addNewOrder)
	local strArrayOrderData = split(order.Payload,'|');

	--for reference:
	--local strForcedOrder = "ForceOrder|AttackTransfer|"..targetPlayer.."|"..gameOrder.From.."|"..gameOrder.To.."|"..gameOrder.NumArmies.NumArmies;

	if (strArrayOrderData[1] ~= "ForcedOrders") then return; end --if this isn't an order for ForcedOrders, don't process anything, just exit

	--currently only process AttackTransfers; only handles raw armies, no Special Units, which will be removed from any orders
	if (strArrayOrderData[2] == "AttackTransfer") then
		print ("[FORCE ORDER] prep - "..order.Payload);
		local numArmies = WL.Armies.Create(strArrayOrderData[8], {});
		print ("[FORCE ORDER] start - "..order.Payload);
		local forcedAttackTransfer = WL.GameOrderAttackTransfer.Create(strArrayOrderData[3], strArrayOrderData[4], strArrayOrderData[5], tonumber (strArrayOrderData[6]), toboolean (strArrayOrderData[7]), numArmies, toboolean (strArrayOrderData[9]));
		--reference: replacementOrder = WL.GameOrderAttackTransfer.Create(targetPlayer, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, gameOrder.NumArmies, gameOrder.AttackTeammates);
		print ("[FORCE ORDER] pre - "..order.Payload);
		addNewOrder (forcedAttackTransfer);
		print ("[FORCE ORDER] post - "..order.Payload);
	end
end

function toboolean (value)
    if value == nil or value == false or value == "false" then
        return false
    else
        return true
    end
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