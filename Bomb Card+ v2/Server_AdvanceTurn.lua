function Server_AdvanceTurn_Start (game,addNewOrder)
end

function Server_AdvanceTurn_End(game,addNewOrder)
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	print ("!".. order.proxyType);
	if ((Mod.Settings.UseCustomCard == nil and order.proxyType == 'GameOrderPlayCardBomb') or (Mod.Settings.UseCustomCard == true and order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Bomb+|")==true)) then
		PlayBombCard(game, order, addNewOrder);
		if (Mod.Settings.UseCustomCard == nil) then skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); end --skip original order if using standard Bomb Card
	end
end

function PlayBombCard (game, order, addNewOrder)
	--there is no way to modify the damage of the existing Bomb Card order, so must skip that order, create a new order that mimics it but does the desired damage amount
	--New order moves the camera, shows the "Bomb" annotation, consumes the Bomb card

	local intTargetTerritoryID;
	--get target territory ID; if card is played from a standard Bomb cad, get it from order.PlayerID; if played from the custom Bomb+ card, get it from the order.ModData
	if (order.proxyType == 'GameOrderPlayCardBomb') then
		intTargetTerritoryID = order.TargetTerritoryID;
	else
		local modDataContent = split (order.ModData, "|");
		-- printDebug ("[GameOrderPlayCardCustom] modData=="..order.ModData.."::");
		--strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name --already captured in global variable 'strCardTypeBeingPlayed' from process_game_orders_CustomCards function
		intTargetTerritoryID = modDataContent[2]; --2nd component of ModData is the source territory ID
	end

	local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
	local armies;
	local strBombMsg = getPlayerName (game, order.PlayerID).. " bombs " ..game.Map.Territories[intTargetTerritoryID].Name;

	--if a territory with an active Shield is being Bombed, nullify the damage
	--also only process if Shield module is active (or if current game predates ActiveModule)
	-- if (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID])) then

	--if a shield is on the target territory, do not apply any damage
	if (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID])) then
		--don't need to do anything
		-- print ("SHIELD yes");
	else
		-- print ("SHIELD no");
		armies = game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID].NumArmies.NumArmies;
		armies = math.floor (armies * Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled + 0.5);

		-- print ("ARMIES DELTA "..armies);
		-- print ("terr Armies " .. tostring (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies));
		-- print ("% "..tostring (Mod.Settings.killPercentage/100));
		-- print ("fixed " .. tostring (Mod.Settings.armiesKilled));
		-- print ("total reduction " .. math.floor (armies * Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled + 0.5));
		terrMod.AddArmies = -armies;
		if (armies >= game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID].NumArmies.NumArmies and Mod.Settings.EmptyTerritoriesGoNeutral and (Mod.Settings.SpecialUnitsPreventNeutral == false or tablelength(game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID].NumArmies.SpecialUnits) == 0)) then
				terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
		end
	end

	local event = WL.GameOrderEvent.Create (order.PlayerID, strBombMsg, {}, {terrMod});
	event.RemoveWholeCardsOpt = {[order.PlayerID] = order.CardInstanceID}; --consume the Bomb card (must be done b/c we're skipping the original order that consumes the card)
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb+", 8, 0)}; --mimic the base "Bomb" annotation
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID); --move the camera to the target territory
	addNewOrder (event, false); --add new order that removes the played Bomb card + applies modified damage amount; use 'false' to not skip the order if orig order is skipped b/c this function will skip it every time
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

function split(inputstr, sep)
	if inputstr == nil then return {}; end
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end