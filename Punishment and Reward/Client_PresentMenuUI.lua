--used to display Punishment and Reward stats for the local client player
function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
	Game = game; --global variable to use in other functions in this code 

	if game == nil then 		print('ClientGame is nil'); 	end
	if game.LatestStanding == nil then 		print('ClientGame.LatestStanding is nil'); 	end
	if game.LatestStanding.Cards == nil then 		print('ClientGame.LatestStanding.Cards is nil'); 	end
	if game.Us == nil then 		print('ClientGame.Us is nil'); 	end
	if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end

	MenuWindow = rootParent;
	TopLabel = CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText (""); --future use?
	CreateLabel (MenuWindow).SetText ("Punishments: [none]");
	CreateLabel (MenuWindow).SetText ("Rewards: [none]");
	CreateLabel (MenuWindow).SetText ("\nAfter approx 10 turns, you will be assigned Punishments for having successive turns where you don't make attacks and increase your territory count from previous turns, and will be granted rewards for those you do");

	--only display if Cities can be built or if Workers are in use (but how to check for workers? see if any are on the map already? that's the only way to know for sure b/c can't check the mods in play)
	CreateLabel (MenuWindow).SetText ("\nCITIES: Rewards of 1% of total city income value will be granted for each territory you possess where the cities # of territories will also be given for");

	--[[    Server_GameCustomMessage (Server_GameCustomMessage.lua)
Called whenever your mod calls ClientGame.SendGameCustomMessage. This gives mods a way to communicate between the client and server outside of a turn advancing. Note that if a mod changes Mod.PublicGameData or Mod.PlayerGameData, the clients that can see those changes and have the game open will automatically receive a refresh event with the updated data, so this message can also be used to push data from the server to clients.
Mod security should be applied when working with this Hook
Arguments:
Game: Provides read-only information about the game.
PlayerID: The ID of the player who invoked this call.
payload: The data passed as the payload parameter to SendGameCustomMessage. Must be a lua table.
setReturn: Optionally, a function that sets what data will be returned back to the client. If you wish to return data, pass a table as the sole argument to this function. Not calling this function will result in an empty table being returned.]]

	--this shows all Global Functions! wow
	--[[for i, v in pairs(_G) do
		print(i, v);
	end]]

end