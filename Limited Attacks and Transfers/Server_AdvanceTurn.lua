numAttacksTable = {};
numTransfersTable = {};
limitSurpassedAttacks = {}; --array element = playerID; value indicates whether that user has been informed that they surpassed the attack limit; if so, don't inform them again
limitSurpassedTransfers = {}; --array element = playerID; value indicates whether that user has been informed that they surpassed the transfer limit; if so, don't inform them again

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderAttackTransfer') then
		if (result.IsAttack == true) then
			--this is an attack order
			local numAttacks = numAttacksTable[order.PlayerID];
			if numAttacks == nil then numAttacks = 0; end
			if (numAttacks >= Mod.Settings.AttackLimit) then
				if (limitSurpassedAttacks [order.PlayerID] == nil) then
						addNewOrder (WL.GameOrderEvent.Create(order.PlayerID, "Remaining Attack orders skipped; surpassed Attack limit"));
						limitSurpassedAttacks [order.PlayerID] = true; --don't notify player again this turn for each remaining order that they have surpassed the attack limit
				end
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			else
				numAttacksTable[order.PlayerID] = numAttacks + 1;
			end
		else
			--this is a transfer order
			local numTransfers = numTransfersTable[order.PlayerID];
			if numTransfers == nil then numTransfers = 0; end
			if (numTransfers >= Mod.Settings.TransferLimit) then
				if (limitSurpassedTransfers [order.PlayerID] == nil) then
					addNewOrder (WL.GameOrderEvent.Create(order.PlayerID, "Remaining Transfer orders skipped; surpassed Transfer limit"));
					limitSurpassedTransfers [order.PlayerID] = true; --don't notify player again this turn for each remaining order that they have surpassed the transfer limit
				end
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			else
				numTransfersTable[order.PlayerID] = numTransfers + 1;
			end
		end
	end
end
