function Server_Created (game, settings)
    local publicGameData = Mod.PublicGameData;
	publicGameData.MoveOrder = {};

	--this shows move order on ODD TURN #'s -- must invert it for EVEN TURN #'s
	local moveOrder = game.ServerGame.CyclicMoveOrder; --Game.GetTurn (1);
	for k,v in pairs (moveOrder) do
		publicGameData.MoveOrder.PlayerID [k] = v;
	end

    Mod.PublicGameData = publicGameData;
end