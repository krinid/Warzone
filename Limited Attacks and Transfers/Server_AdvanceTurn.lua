numAttacksTable = {};
numTransfersTable = {};

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderAttackTransfer') then
		if (order.IsAttack == true) then
			--this is an attack order
			local numAttacks = numAttacksTable[order.PlayerID];
			if numAttacks == nil then numAttacks = 0; end
			if (numAttacks >= Mod.Settings.AttackLimit) then
				addNewOrder (WL.GameOrderEvent.Create(order.PlayerID, "Order skipped; surpassed Attack limit"));
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			else
				numAttacksTable[order.PlayerID] = numAttacks + 1;
			end
		else
			--this is a transfer order
			local numTransfers = numTransfersTable[order.PlayerID];
			if numTransfers == nil then numTransfers = 0; end
			if (numTransfers >= Mod.Settings.TransferLimit) then
				addNewOrder (WL.GameOrderEvent.Create(order.PlayerID, "Order skipped; surpassed Transfer limit"));
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			else
				numTransfersTable[order.PlayerID] = numTransfers + 1;
			end
		end
	end
end
