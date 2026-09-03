function Client_GameCommit (game, skipCommit)
	local strPayload = "Late Airlifts|Execute airlifts";

	local boolSameOrderExistsAlready = false; --indicates whether an order for A->B already exists in the order list; if so, assume it's legit and skip this order

	--if game state isn't "Playing" then skip this; it is likely 'DistributingTerritories', in which case trying to a custom order will fail b/c only Pick orders are accepted here
	if (game.Game.State ~= WL.GameState.Playing) then return; end

	--check to see if the order exists already; only add it if it doesn't already exist; this can happen if a user commits, uncommits, recommits, etc
	for k,existingGameOrder in pairs (game.Orders) do
		-- print (k..", "..existingGameOrder.proxyType);
		if (existingGameOrder.proxyType == "GameOrderCustom" and existingGameOrder.Payload == strPayload) then boolSameOrderExistsAlready = true; end
	end

	--only do this if the order doesn't exist in the queue already, leverage 'boolSameOrderExistsAlready' to facilitate
	if (boolSameOrderExistsAlready == false) then
		-- UI.Alert ("game state: " ..game.Game.State.."/".. tostring (WL.GameState.ToString (game.Game.State)));
		-- local newOrder = WL.GameOrderCustom.Create (game.Us.ID, "[End of orders]", "Portals|Portal swap", {}, WL.TurnPhase.ReceiveGold);
		local newOrder = WL.GameOrderCustom.Create (game.Us.ID, "[Late Airfifts]", strPayload, {}, WL.TurnPhase.ReceiveCards);
		--b/c this function has no addOrder callback parameter, need to manually add the order into the clientgame parameter 'game'

		local orders = game.Orders;
		game.Orders = insertOrder (game, newOrder, orders);
		-- Game.Orders = orders;
		-- table.insert(orders, newOrder);
		-- game.Orders = orders;
	end
end

--find correct spot in order list to add new order based on its phase # so that all orders remain in proper sequence
--if orders are written back the game.Orders out of sequence according to the OccursInPhase property, a runtime error is thrown
function insertOrder (Game, newOrder, orderList)
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