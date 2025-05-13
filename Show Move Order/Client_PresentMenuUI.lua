function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

	setMaxSize (800, 600);
	Game = game; --global variable to use in other functions in this code 

	if game == nil then print('ClientGame is nil'); return; end
	if game.LatestStanding == nil then print('ClientGame.LatestStanding is nil'); end
	if game.LatestStanding.Cards == nil then print('ClientGame.LatestStanding.Cards is nil'); end
	if game.Us == nil then print('ClientGame.Us is nil'); return; end
	-- if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	-- if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end

	local clientPlayerID = game.Us.ID;
	local playerData = {};
	MenuWindow = rootParent;
	TopLabel = UI.CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText (""); --required?
	-- UI.CreateLabel (MenuWindow).SetText ("Punishments: [none]");
	-- UI.CreateLabel (MenuWindow).SetText ("Rewards: [none]");
	cboxShowActivePlayersOnly = UI.CreateCheckBox (UI.CreateHorizontalLayoutGroup(MenuWindow)).SetIsChecked (true).SetInteractable(true).SetText("Show active players only");

	vertMoveOrder = UI.CreateVerticalLayoutGroup (MenuWindow); --show move order details in this control
	showMoveOrderDetails ();
end

function showMoveOrderDetails ()
	local vertMoveOrderDetails = UI.CreateVerticalLayoutGroup (vertMoveOrder);
	UI.CreateLabel (vertMoveOrderDetails).SetText ("Move order for this turn:");

	-- print (tostring (Mod.PublicGameData));
	-- print (tostring (Mod.PublicGameData.MoveOrder));
	-- if (Mod.PublicGameData == nil) then Mod.PublicGameData = {}; end
	if (Mod.PublicGameData.MoveOrder == nil) then Game.SendGameCustomMessage ("[getting move order]", {action="getmoveorder"}, function () end); end

	for k,v in pairs (Mod.PublicGameData.MoveOrder) do
		if (cboxShowActivePlayersOnly == false or isPlayerActive (v.PlayerID) == true) then
			--game.ServerGame.Game.PlayingPlayers
			UI.CreateLabel (vertMoveOrderDetails).SetText (k..". " ..getPlayerName (game, v.PlayerID));
		end
	end
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
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

--accept player object, return result true is player active in game; false is player is eliminated, booted, surrendered, etc
function isPlayerActive (playerID, game)
	--if (playerid<=50) then

	local player = game.Game.Players[playerID];

	--if VTE, player was removed by host or decline the game, then player is not Active
	if player.State ~= WL.GamePlayerState.EndedByVote and player.State ~= WL.GamePlayerState.RemovedByHost and player.State ~= WL.GamePlayerState.Declined then
		return (false);
	--if eliminated or booted (and not AI), then player is not active
	elseif ((player.State == WL.GamePlayerState.Eliminated) or (player.State == WL.GamePlayerState.Booted and not game.Settings.BootedPlayersTurnIntoAIs) or (player.State == WL.GamePlayerState.SurrenderAccepted and not game.Settings.SurrenderedPlayersTurnIntoAIs)) then
	--elseif ((player.State == WL.GamePlayerState.Eliminated) or (player.State == WL.GamePlayerState.Booted and not game.Settings.BootedPlayersTurnIntoAIs) or (player.State == WL.GamePlayerState.SurrenderAccepted and not game.Settings.SurrenderedPlayersTurnIntoAIs)) then
		return (false);
	else
		-- all other cases, user is active
		return (true);
	end
end