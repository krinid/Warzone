function Server_AdvanceTurn_Start (game,addNewOrder)
	skippedBombs = {};
	-- memory = {};
	executed = false;
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)	
	if(executed == false)then
		if(order.proxyType == 'GameOrderPlayCardBomb')then
			-- addNewOrder(WL.GameOrderDiscard.Create(order.PlayerID, order.CardInstanceID));
			if (Mod.Settings.delayed) then
				skippedBombs[#skippedBombs+1] = order;
			else
				PlayBombCard(game, order, addNewOrder);
			end
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		end
	end
end

function Server_AdvanceTurn_End(game,addNewOrder)
	if(executed == false) then
		executed = true;
		for _, order in pairs(skippedBombs) do
			if (order.PlayerID~=nil) then
				bomber = game.ServerGame.Game.PlayingPlayers[order.PlayerID];
				if (bomber ~= nil) then
					bombedID = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID;
					if (bombedID == WL.PlayerID.Neutral or bombedID == nil or game.ServerGame.Game.PlayingPlayers[bombedID] == nil) then
						PlayBombCard(game, order, addNewOrder);
					else
						bombed = game.ServerGame.Game.PlayingPlayers[bombedID];
						if (bomber.Team~=bombed.Team or (bombed.Team == -1 and bombed.ID ~= order.PlayerID)) then
							PlayBombCard(game, order, addNewOrder);
						end
					end
				end
			end
		end
	end
end

function round (input)
	local wholePart = math.floor(input);
	local decimalPart = input - wholePart;
	if (decimalPart) >= 0.5 then
		return wholePart +1;
	else
		return wholePart;
	end
end

function PlayBombCard (game, order, addNewOrder)
	--there is no way to modify the damage of the existing Bomb Card order, so must skip that order, create a new order that mimics it but does the desired damage amount
	--New order moves the camera, shows the "Bomb" annotation, consumes the Bomb card
	local terrMod = WL.TerritoryModification.Create(order.TargetTerritoryID);
	local armies;
	local strBombMsg = getPlayerName (game, order.PlayerID).. " bombs " ..game.Map.Territories[order.TargetTerritoryID].Name;

	--if a territory with an active Shield is being Bombed, nullify the damage
	--also only process if Shield module is active (or if current game predates ActiveModule)
	-- if (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID])) then

	--if a shield is on the target territory, do not apply any damage
	-- print ("SHIELD == ".. tostring (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID])));
	if (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID])) then
		--don't need to do anything
		-- print ("SHIELD yes");
	else
		-- print ("SHIELD no");
		armies = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies;
		armies = math.floor (armies * Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled + 0.5);

		-- print ("ARMIES DELTA "..armies);
		-- print ("terr Armies " .. tostring (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies));
		-- print ("% "..tostring (Mod.Settings.killPercentage/100));
		-- print ("fixed " .. tostring (Mod.Settings.armiesKilled));
		-- print ("total reduction " .. math.floor (armies * Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled + 0.5));
		terrMod.AddArmies = -armies;
		if (armies >= game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies and Mod.Settings.EmptyTerritoriesGoNeutral and (Mod.Settings.SpecialUnitsPreventNeutral == false or tablelength(game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.SpecialUnits) == 0)) then
				terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
		end
	end

	local event = WL.GameOrderEvent.Create (order.PlayerID, strBombMsg, {}, {terrMod});
	event.RemoveWholeCardsOpt = {[order.PlayerID] = order.CardInstanceID}; --consume the Bomb card (must be done b/c we're skipping the original order that consumes the card)
	event.TerritoryAnnotationsOpt = {[order.TargetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb", 8, 0)}; --mimic the base "Bomb" annotation
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, order.TargetTerritoryID); --move the camera to the target territory
	addNewOrder (event, false); --add new order that removes the played Bomb card + applies modified damage amount; use 'false' to not skip the order if orig order is skipped b/c this function will skip it every time
	--skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip original Bomb order (b/c there's no way to modify the damage it does)
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<0) then return ("fogged");
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

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create(1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

function territoryHasActiveShield (territory)
	if not territory then return false; end

	for _, specialUnit in pairs (territory.NumArmies.SpecialUnits) do
		if (specialUnit.proxyType == 'CustomSpecialUnit' and specialUnit.Name == 'Shield') then
			return (true);
		end
	end

	return (false);
end