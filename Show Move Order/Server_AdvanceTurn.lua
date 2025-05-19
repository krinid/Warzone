function Server_AdvanceTurn_Start (game,addOrder)
	-- local moveOrder = game.ServerGame.CyclicMoveOrder;
	-- for k,v in pairs (moveOrder) do
	-- 	-- print (v, getPlayerName (game, v));
	-- 	print ("[SATS MO] " .. v.."/"..game.Game.Players[v].DisplayName(nil, false));
	-- end

	print ("[SATS] NumberOfLogicalTurns ".. tostring (game.ServerGame.Game.NumberOfLogicalTurns).. ", NumberOfTurns ".. tostring (game.ServerGame.Game.NumberOfTurns));
	local pickOrder = game.ServerGame.PickOrder;
	if (game.ServerGame.PickOrder ~= nil) then --always nil for AutoDist; defined before start of T1 for ManualDist
		print ("[SATS] [Pick Order]");
		for k,v in pairs (pickOrder) do
			print (v.."/"..game.Game.Players[v].DisplayName(nil, false));
		end
	end

	local publicGameData = Mod.PublicGameData;
	if (game.ServerGame.CyclicMoveOrder ~= nil) then  --should never happen b/c it updates before turn advances but if ==nil then turn order hasn't been exposed to mods yet (happens once T1 advances to account for case of NLC), so can't access turn order yet
		local boolDefineMoveOrder = false;
		if (publicGameData.MoveOrder == nil) then publicGameData.MoveOrder = {}; boolDefineMoveOrder = true; end --only update it if it's not already defined (it will be defined on T1)
			print ("[SGCM] [Move Order]");
			for k,v in pairs (game.ServerGame.CyclicMoveOrder) do
			print (v.."/"..game.Game.Players[v].DisplayName(nil, false));
			if (boolDefineMoveOrder == true) then table.insert (publicGameData.MoveOrder, v); end --only update it if it's not already defined (it will be defined on T1)
		end
		if (boolDefineMoveOrder == true) then Mod.PublicGameData = publicGameData; end --only update it if it's not already defined (it will be defined on T1)
	end
end


function getPlayerName (game, playerid)
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
