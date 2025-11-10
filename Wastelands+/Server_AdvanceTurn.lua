require 'runtimeWastelands';

local payload = 'Wastelands+_ServerAdvanceTurnEnd';
local executed = false;

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if order.proxyType == 'GameOrderCustom' and order.Payload == payload then
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		if not executed then
			makeRuntimeWastelands(game, addNewOrder);
			executed = true;
		end
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	addNewOrder(WL.GameOrderCustom.Create(getFirstPlayer(game), '', payload));
end

function getFirstPlayer(game)
	-- neutral isn't allowed for game order custom
	for playerId in pairs(game.ServerGame.Game.Players) do
		return playerId;
	end
end
