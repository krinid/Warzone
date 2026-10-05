require('Utilities')

--Called for every order as the turn is processed.  When the card's order comes up (in the phase the client asked for, WL.TurnPhase.Airlift), we move the armies by adding an event.
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType=='GameOrderCustom' and order.Payload == "[animation test]") then
		local event = WL.GameOrderEvent.Create (order.PlayerID, "[animation test]");
		event.Icon = "AirliftIcon";
		addNewOrder(event);
	end
end