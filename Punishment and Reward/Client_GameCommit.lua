function Client_GameCommit (game, skipCommit)
	-- skipCommit ();
	local boolSameOrderExistsAlready = false; --indicates whether an order for A->B already exists in the order list; if so, assume it's legit and skip this order

	--check to see if the order exists already; only add it if it doesn't already exist; this can happen if a user commits, uncommits, recommits, etc
	for k,existingGameOrder in pairs (game.Orders) do
		-- print (k..", "..existingGameOrder.proxyType);
		if (existingGameOrder.proxyType == "GameOrderCustom" and existingGameOrder.Payload == "PunishReward|Capture card state") then boolSameOrderExistsAlready = true; end
	end

	--only do this is an order for territory A->B doesn't exist yet; if it does, it'll throw an error on user client; each of the 4 Card Pack mods will try to recreate the order w/o Immovable Specials
	--leverage 'boolSameOrderExistsAlready' to ensure that only the 1st mod actually inserts the corrected order 
	if (boolSameOrderExistsAlready == false) then
		local newOrder = WL.GameOrderCustom.Create (game.Us.ID, "[Card state snapshot]", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards);
		--b/c this function has no addOrder callback parameter, need to manually add the order into the clientgame parameter 'game'
		local orders = game.Orders;
		table.insert(orders, newOrder);
		game.Orders = orders;
	end
end