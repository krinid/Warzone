function Server_GameCustomMessage(game,playerID,payload,setReturn)
	if (payload.action ~= nil) then
		if (payload.action == "unused") then

		elseif (payload.action == "trimdebugdata") then
			trimDebug (payload.lastReadKey);
		elseif (payload.action == "debugmodetoggle") then
			local publicGameData = Mod.PublicGameData;
			publicGameData.Debug.DebugMode = not publicGameData.Debug.DebugMode;
			Mod.PublicGameData = publicGameData;
			setReturn ({publicGameData.Debug.DebugMode});
		elseif (payload.action == "initializedebug") then
			if (Mod.PublicGameData.Debug == nil) then initialize_debug_data (); end --initialize data structures for outputting debug data from Server hooks to Client hooks for local client side display
		end
	end
	--initialize_debug_data ();

	--initialize_CardData (game); --no longer required here, it's done before the game starts (in Server_Created)
end

--[[    Server_GameCustomMessage (Server_GameCustomMessage.lua)
Called whenever your mod calls ClientGame.SendGameCustomMessage. This gives mods a way to communicate between the client and server outside of a turn advancing. Note that if a mod changes Mod.PublicGameData or Mod.PlayerGameData, the clients that can see those changes and have the game open will automatically receive a refresh event with the updated data, so this message can also be used to push data from the server to clients.
Mod security should be applied when working with this Hook
Arguments:
Game: Provides read-only information about the game.
PlayerID: The ID of the player who invoked this call.
payload: The data passed as the payload parameter to SendGameCustomMessage. Must be a lua table.
setReturn: Optionally, a function that sets what data will be returned back to the client. If you wish to return data, pass a table as the sole argument to this function. Not calling this function will result in an empty table being returned.]]

--initialize the Mod.PublicGameData.Debug structure and all member properties
function initialize_debug_data ()
	local publicGameData = Mod.PublicGameData;
	publicGameData.Debug = {};
	publicGameData.Debug.DebugMode = false;
	publicGameData.Debug.DebugUser = 1058239; --only output data for this user, to prevent other users from displaying & erasing the data so it's not available for me & disable abuse of this coding/debugging feature
	publicGameData.Debug.TrimData = true; --indicates whether to trim data (erase) it after viewing it or leave it in PublicGameData.Debug.OutputData for future perusal
    publicGameData.Debug.OutputData = {};
    publicGameData.Debug.OutputDataCounter = 0;  --the highest key# created so far
    publicGameData.Debug.OutputDataLastRead = 0; --the highest key# retrieved by client side
    Mod.PublicGameData = publicGameData;
end