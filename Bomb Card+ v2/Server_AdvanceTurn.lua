-- function Server_AdvanceTurn_Start (game,addNewOrder)
-- end

-- function Server_AdvanceTurn_End(game,addNewOrder)
-- end

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

	local intFortStructureID = territoryHasFort (game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID]);
	local boolTerritoryHasShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID]);
	local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
	local armies;
	local strBombMsg = getPlayerName (game, order.PlayerID).. " bombs " ..game.Map.Territories[intTargetTerritoryID].Name;
	local terr = game.ServerGame.LatestTurnStanding.Territories[intTargetTerritoryID]; --target territory

	--if a shield is on the target territory, do not apply any damage
	if (boolTerritoryHasShield == true or boolTerritoryHasFort == true) then
		--terr protected by Shield or Fort, no damage is applied, no cities destroyed
		--if terr is protected by Shield, no Forts are destroyed; if terr is not protected by Shield but has Forts, 1 Fort is destroyed

		--destroy 1 fort on the territory iff there are any forts on the territory and no Shield is active
		if (boolTerritoryHasShield == false and boolTerritoryHasFort == true) then
			-- local fortStructureID = WL.StructureType.Custom ("Fort"); --matches to StructureImages/Fort.png  <--- this only works if this structure was created by the current mod (else StructureImages/Fort.png doesn't exist)
			local structures = game.ServerGame.LatestTurnStanding.Territories[order.To].Structures;
			local intNumForts = structures[fortStructureID] ~= nil and structures [fortStructureID] or 0;

			if (intNumForts >= 1) then
				structures [fortStructureID] = structures [fortStructureID] - 1;
				local terrMod = WL.TerritoryModification.Create (order.To);
				terrMod.SetStructuresOpt = structures;
				local event = WL.GameOrderEvent.Create (order.PlayerID, "Destroyed fort", {}, {terrMod});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, order.To);
				event.TerritoryAnnotationsOpt = {[order.To] = WL.TerritoryAnnotation.Create("Destroy Fort")};
				addNewOrder (event, true); --The second argument makes sure this order isn't processed when the initial attack is skipped
			end
		end
	else
		--terr not protected by Shield or Fort
		armies = terr.NumArmies.NumArmies;
		armies = math.floor (armies * Mod.Settings.killPercentage / 100 + Mod.Settings.armiesKilled + 0.5);

		local intCurrentCityCount = (terr.Structures and terr.Structures [WL.StructureType.City]) or 0;
		local intNumCitiesToDestroy = Mod.Settings.NumCitiesDestroyedByBombPlay or 0;
		if (intCurrentCityCount > 0 and intNumCitiesToDestroy > 0) then
			local intNewCityCount = math.max (0, intCurrentCityCount - intNumCitiesToDestroy);
			local structures = terr.Structures or {};
			structures [WL.StructureType.City] = intNewCityCount;
			terrMod.SetStructuresOpt = structures;
		end

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

function territoryHasFort (territory)
	local structures = territory.Structures or {};

	for k,v in pairs (structures) do
		print (k,v);
	end


	local intNumForts = structures[fortStructureID] ~= nil and structures [fortStructureID] or 0;

	if (intNumForts >= 1) then
		structures [fortStructureID] = structures [fortStructureID] - 1;
		local terrMod = WL.TerritoryModification.Create (order.To);
		terrMod.SetStructuresOpt = structures;
		local event = WL.GameOrderEvent.Create (order.PlayerID, "Destroyed fort", {}, {terrMod});
		event.JumpToActionSpotOpt = createJumpToLocationObject (game, order.To);
		event.TerritoryAnnotationsOpt = {[order.To] = WL.TerritoryAnnotation.Create("Destroy Fort")};
		addNewOrder (event, true); --The second argument makes sure this order isn't processed when the initial attack is skipped
	end

	if not territory then return false; end

	for _, specialUnit in pairs (territory.NumArmies.SpecialUnits) do
		if (specialUnit.proxyType == 'CustomSpecialUnit' and specialUnit.Name == 'Fort') then
			return (true);
		end
	end

	return 0, 0; --return fortID as 0 (indicates DNE) and 0 forts present
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