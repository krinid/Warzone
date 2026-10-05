function Client_GameCommit (game, skipCommit)
	-- skipCommit ();
	-- local newOrder = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "animation test");
	local newOrder = WL.GameOrderCustom.Create (game.Us.ID, "[animation test]", "[animation test]");
	local orders = game.Orders;
	table.insert (orders, newOrder);
	game.Orders = orders;
	-- game.Orders = insertOrder (newOrder, orders);
end

--find correct spot in order list to add new order based on its phase # so that all orders remain in proper sequence
--if orders are written back the game.Orders out of sequence according to the OccursInPhase property, a runtime error is thrown
function insertOrder (newOrder, orderList)
	local intNewOrderPhase = newOrder.OccursInPhase or -1;
	for i, existingOrder in pairs (orderList) do
		local intExistingOrderPhase = existingOrder.OccursInPhase or -1;
		if (intNewOrderPhase < intExistingOrderPhase) then
			table.insert (orderList, i, newOrder);
			return orderList;
		end
	end
	table.insert (orderList, newOrder); --if we reach here then new order occurs in phase after all existing orders, so add to end of list
	-- Game.Orders = orderList;
	return orderList;
end