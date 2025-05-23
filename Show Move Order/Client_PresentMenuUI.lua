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
	cboxShowActivePlayersOnly = UI.CreateCheckBox (UI.CreateHorizontalLayoutGroup(MenuWindow)).SetIsChecked (true).SetInteractable(true).SetText("Show active players only").SetOnValueChanged (showMoveOrderDetails);

	vertMoveOrder = UI.CreateVerticalLayoutGroup (MenuWindow); --show move order details in this control
	showMoveOrderDetails ();
end

function showMoveOrderDetails ()
	--if turn order isn't defined in Mod.PublicGameData.MoveOrder, try to get it from a server hook, but if it's still nil after attempting to get it, then it's not exposed to mods yet, and the turn needs to advance to access it; thus it's not available going into T1
	if (Mod.PublicGameData.MoveOrder == nil) then Game.SendGameCustomMessage ("[getting move order]", {action="getmoveorder"}, populateMoveOrderControl_CallBack); --function () end);
	else
		populateMoveOrderControl (Mod.PublicGameData.MoveOrder);
	end


end

function populateMoveOrderControl_CallBack (moveOrder)
	populateMoveOrderControl (moveOrder[1]);
end

function populateMoveOrderControl (moveOrderData)
	UI.Destroy (vertMoveOrder);
	vertMoveOrder = UI.CreateVerticalLayoutGroup (MenuWindow); --show move order details in this control
	local vertMoveOrderDetails = UI.CreateVerticalLayoutGroup (vertMoveOrder);
	local boolReverseTurnOrder = false; --if true then turn order is in the order stored in Mod.PublicGameData.MoveOrder (taken from game.ServerGame.CyclicMoveOrder); if false, then reverse the order, start from highest element and go to lowest
	--this is governed by Game.Game.NumberOfLogicalTurns, which treats picking phase in Manual Dist games as a turn thus reversing the move order cycle for T1 if Manual Dist is in play and leaving it as-is for Auto Dist
	if (Game.Game.NumberOfLogicalTurns % 2 ~= 0) then boolReverseTurnOrder = true; end

	print ("[CPMUI] NumberOfLogicalTurns ".. tostring (Game.Game.NumberOfLogicalTurns).. ", NumberOfTurns ".. tostring (Game.Game.NumberOfTurns).. ", NOLT % 2==".. tostring (Game.Game.NumberOfLogicalTurns % 2).. ", reverseOrder ".. tostring (boolReverseTurnOrder));
	UI.CreateLabel (vertMoveOrderDetails).SetText ("Move order for Turn #" ..tostring (Game.Game.TurnNumber)..":");
	if (moveOrderData == nil) then
		UI.CreateLabel (vertMoveOrderDetails).SetText ("Turn order not exposed yet; need to advance turn to view\n\nThis happens in Auto-Dist on T1; move order will show properly starting from T2");
	else
		local startIndex = 1;
		local endIndex = #moveOrderData;
		local increment = 1;
		if (boolReverseTurnOrder == true) then
			startIndex = #moveOrderData
			endIndex = 1;
			increment = -1;
		end

		local playerID;
		local numItemsDisplayed = 0;
		for k=startIndex, endIndex, increment do
		-- for k,playerID in pairs (moveOrderData) do
			playerID = moveOrderData [k];
			print ("[CPMUI MO] ".. tostring(k),tostring(playerID),getPlayerName (Game, playerID),tostring(isPlayerActive (Game, playerID)).. ", cbox ".. tostring(cboxShowActivePlayersOnly.GetIsChecked()));
			if (cboxShowActivePlayersOnly.GetIsChecked() == false or isPlayerActive (Game, playerID) == true) then
				--game.ServerGame.Game.PlayingPlayers
				numItemsDisplayed = numItemsDisplayed + 1;
				UI.CreateLabel (vertMoveOrderDetails).SetText (numItemsDisplayed..". " ..getPlayerName (Game, playerID));
			end
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
	-- elseif (tonumber(playerid)<50) then return ("AI "..playerid);
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
function isPlayerActive (game, playerID)
	--if (playerid<=50) then

	local player = game.Game.Players[playerID];
	-- print ("STATE " ..player.State, WL.GamePlayerState.ToString(player.State));

	--if VTE, player was removed by host or decline the game, then player is not Active
	if player.State == WL.GamePlayerState.EndedByVote or player.State == WL.GamePlayerState.RemovedByHost or player.State == WL.GamePlayerState.Declined then
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