function Server_GameCustomMessage(game,playerID,payload,setReturn)

	-- for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories) do
	-- 	print (k,v.ID);
	-- end

	print ("[SCGM] NumberOfLogicalTurns ".. tostring (game.ServerGame.Game.NumberOfLogicalTurns).. ", NumberOfTurns ".. tostring (game.ServerGame.Game.NumberOfTurns));

	if (game.ServerGame.PickOrder ~= nil) then --if ==nil then turn order hasn't been exposed to mods yet (happens once T1 advances to account for case of NLC), so can't access turn order yet, so just leave it as a nil value
		print ("[SGCM] [Pick Order]");
		for k,v in pairs (game.ServerGame.PickOrder) do
			print (v.."/"..game.Game.Players[v].DisplayName(nil, false));
		end
	end

	local publicGameData = Mod.PublicGameData;
	if (game.ServerGame.CyclicMoveOrder ~= nil) then --if ==nil then turn order hasn't been exposed to mods yet (happens once T1 advances to account for case of NLC), so can't access turn order yet, so just leave it as a nil value
		publicGameData.MoveOrder = {};
		print ("[SGCM] [Move Order]");
		for k,v in pairs (game.ServerGame.CyclicMoveOrder) do
			print (v.."/"..game.Game.Players[v].DisplayName(nil, false));
			table.insert (publicGameData.MoveOrder, v);
		end
		Mod.PublicGameData = publicGameData;
	end
	setReturn ({publicGameData.MoveOrder});
end

--[[    Server_GameCustomMessage (Server_GameCustomMessage.lua)
Called whenever your mod calls ClientGame.SendGameCustomMessage. This gives mods a way to communicate between the client and server outside of a turn advancing. Note that if a mod changes Mod.PublicGameData or Mod.PlayerGameData, the clients that can see those changes and have the game open will automatically receive a refresh event with the updated data, so this message can also be used to push data from the server to clients.
Mod security should be applied when working with this Hook
Arguments:
Game: Provides read-only information about the game.
PlayerID: The ID of the player who invoked this call.
payload: The data passed as the payload parameter to SendGameCustomMessage. Must be a lua table.
setReturn: Optionally, a function that sets what data will be returned back to the client. If you wish to return data, pass a table as the sole argument to this function. Not calling this function will result in an empty table being returned.]]