function Server_StartGame (game, standing)
		for _,playerinfo in pairs(game.Game.Players) do
			print (playerinfo.ID, playerinfo.DisplayName(nil, false));
		end

	-- local moveOrder = game.ServerGame.CyclicMoveOrder; --Game.GetTurn (1);
	-- for k,v in pairs (moveOrder) do
	-- 	print (v, getPlayerName (game, v));
	-- end
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<50) then return ("AI "..playerid);
	else
		for _,playerinfo in pairs(game.Game.Players) do
			if(tonumber(playerid) == tonumber(playerinfo.ID))then
				return (playerinfo.DisplayName(nil, false));
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found but playerID >50 was provided
end
