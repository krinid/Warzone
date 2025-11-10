-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/placeOrderInCorrectPosition

function placeOrderInCorrectPosition(clientGame, newOrder)
	if not newOrder.OccursInPhase then
		local orders = clientGame.Orders;

		table.insert(orders, newOrder);
		clientGame.Orders = orders;
	else
		local orders = {};
		local addedNewOrder = false;

		for _, order in pairs(clientGame.Orders) do
			if order.OccursInPhase then
				if not addedNewOrder and order.OccursInPhase > newOrder.OccursInPhase then
					table.insert(orders, newOrder);
					addedNewOrder = true;
				end

				table.insert(orders, order);
			else
				table.insert(orders, order);
			end
		end

		if not addedNewOrder then
			table.insert(orders, newOrder);
		end

		clientGame.Orders = orders;
	end
end