local strBombOrderFilename = "Landmine order icon 40x40_clearBack"; --icon for the Landmine order in the order list

-- function Server_AdvanceTurn_Start (game, addNewOrder)
-- end

function Server_AdvanceTurn_End(game, addNewOrder)
	local annotations = {};
	for terrID, landmineDataRecord in pairs (Mod.PrivateGameData.LandmineData or {}) do
		-- print ("[Landmine] terr " ..terrID.. "/" ..tostring (game.Map.Territories[terrID].Name).. ", castingPlayer " ..landmineDataRecord.castingPlayer.. ", owner " ..landmineDataRecord.territoryOwner.. ", turn played " ..landmineDataRecord.turnNumberPlayed);
		-- print ("[Landmine CHECK] Mod.PrivateGameData.LandmineData [terrID] == " ..tostring (Mod.PrivateGameData.LandmineData [terrID]));
		if (annotations [landmineDataRecord.castingPlayer] == nil) then annotations [landmineDataRecord.castingPlayer] = {}; end
		annotations [landmineDataRecord.castingPlayer][terrID] = WL.TerritoryAnnotation.Create ("Landmine reminder", 4, 0);
		-- local landmineDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber};
	end
	for playerID, playerAnnotations in pairs (annotations) do
		local event = WL.GameOrderEvent.Create (playerID, "Landmine deployment reminder", {}, {});
		event.TerritoryAnnotationsOpt = playerAnnotations;
		event.Icon = strBombOrderFilename;
		addNewOrder (event, false);
	end
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	if (order.PlayerID == 1058239) then
		if (order.proxyType == 'GameOrderCustom' and order.Payload ~= nil) then print ("[ORDER] " ..tostring (order.Payload)); end
		print ("[ORDER] " .. tablelength (Mod.PrivateGameData.LandmineData or {}) .. " landmines in play");
		for terrID, landmineDataRecord in pairs (Mod.PrivateGameData.LandmineData or {}) do
			print ("[Landmine] terr " ..terrID.. "/" ..tostring (game.Map.Territories[terrID].Name).. ", castingPlayer " ..landmineDataRecord.castingPlayer.. ", owner " ..landmineDataRecord.territoryOwner.. ", turn played " ..landmineDataRecord.turnNumberPlayed);
			print ("[Landmine CHECK] Mod.PrivateGameData.LandmineData [terrID] == " ..tostring (Mod.PrivateGameData.LandmineData [terrID]));
		end
		print ("[ORDER] Mod.PrivateGameData.LandmineData ~= nil --> " .. tostring (Mod.PrivateGameData.LandmineData ~= nil));
		-- if (Mod.PrivateGameData.LandmineData ~= nil ) then print ("[ORDER] Mod.PrivateGameData.LandmineData ~= nil --> " ..tostring (Mod.PrivateGameData.LandmineData ~= nil)); end
		if (order.proxyType == 'GameOrderAttackTransfer') then
			local a = Mod.PrivateGameData.LandmineData == nil;
			local b = Mod.PrivateGameData.LandmineData ~= nil and Mod.PrivateGameData.LandmineData [order.To];
			print ("[ORDER] To " ..order.To.. "/" ..tostring (game.Map.Territories[order.To].Name).. ", LandmineData == " ..tostring (a).. ", LandmineData[terrID] == " .. tostring (b));
		end
	end

	--make Recon+/Recon/Spy/Surveil/Beacon reveal Landmines

	if ((order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Landmine|") == true)) then
		local modDataContent = split (order.ModData, "|");
		local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID
		print ("[Landmine initial order] " .. tostring (order.ModData));
		local event = WL.GameOrderCustom.Create (order.PlayerID, "Landmine initial order; " .. getPlayerName (game, order.PlayerID).. " deploys a landmine on " ..game.Map.Territories [intTargetTerritoryID].Name, "DeployOrder-Landmine|".. intTargetTerritoryID)
		event.Icon = strBombOrderFilename;
		addNewOrder (event, true);
	elseif ((order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, "DeployOrder-Landmine|") == true)) then
		print ("[Landmine placement] " ..tostring (order.Payload));
		--skip the trigger order
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this custom game order, it's just a trigger for the real card that makes it properly blockable by Card Block
		placeLandmine (game, order, addNewOrder);
	elseif ((order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack == true and result.IsSuccessful == true and Mod.PrivateGameData.LandmineData ~= nil and Mod.PrivateGameData.LandmineData [order.To] ~= nil)) then
		print ("[Landmine explode order]");
		-- local modDataContent = split (order.ModData, "|");
		-- local intTargetTerritoryID = modDataContent[2]; --2nd component of ModData is the target territory ID
		local event = WL.GameOrderCustom.Create (order.PlayerID, "Landmine explode prep; " .. getPlayerName (game, order.PlayerID).. " triggers a landmine on " ..game.Map.Territories [order.To].Name, "ExplodeOrder-Landmine|".. order.To)
		event.Icon = strBombOrderFilename;
		addNewOrder (event, true);
		-- explode_Landmine (game, order, addNewOrder, order.To);
	elseif ((order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, "ExplodeOrder-Landmine|") == true)) then
		print ("[Landmine explode] " ..tostring (order.Payload));
		local modDataContent = split (order.Payload, "|");
		local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID
		--skip the trigger order
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this custom game order, it's just a trigger for the real card that makes it properly blockable by Card Block
		explode_Landmine (game, order, addNewOrder, intTargetTerritoryID);
	end
end

function placeLandmine (game, order, addNewOrder)
	--stuff
	local modDataContent = split (order.Payload, "|");
	-- print ("[GameOrderPlayCardCustom] modData=="..order.ModData.."::");
	-- strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name --already captured in global variable 'strCardTypeBeingPlayed' from process_game_orders_CustomCards function
	local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID

	--check if terr is within range of X of own terrs
	--check if terr belongs to self or neutral
	--if self, arm it immediately; if neutral, arm at end of turn
	local event = WL.GameOrderEvent.Create (order.PlayerID,  getPlayerName (game, order.PlayerID).. " places a landmine on " ..game.Map.Territories [intTargetTerritoryID].Name);
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID);
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine deployed")};
	event.Icon = strBombOrderFilename;
	addNewOrder (event, false);

	local landmineDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber};
	local privateGameData = Mod.PrivateGameData;
	privateGameData.LandmineData = privateGameData.LandmineData or {};
	privateGameData.LandmineData [intTargetTerritoryID] = landmineDataRecord;
	Mod.PrivateGameData = privateGameData;
	print ("[PLACE LANDMINE FINISH] " .. tablelength (Mod.PrivateGameData.LandmineData or {}) .. " landmines in play");
end

function explode_Landmine (game, order, addNewOrder, intTargetTerritoryID)
	-- local modDataContent = split (order.ModData, "|");
	-- local intTargetTerritoryID = modDataContent[2]; --2nd component of ModData is the source territory ID
	local strFortStructureID = territoryHasFort (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local boolTerritoryHasShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
	local armies;
	local strBombMsg = getPlayerName (game, order.PlayerID).. " triggered a landmine on " ..game.Map.Territories [intTargetTerritoryID].Name;
	local terr = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]; --target territory
	local eventDestroyFort = nil; --if a Fort is to be destroyed, use this to create the separate order so it can be submitted after the "Bomb+" order occurs, so the Fort destruction occurs after the bomb hits so it is visually clear in the order list

	--if a shield is on the target territory, do not apply any damage
	if (boolTerritoryHasShield == true or strFortStructureID ~= nil) then
		--terr protected by Shield or Fort, no damage is applied, no cities destroyed
		--if terr is protected by Shield, no Forts are destroyed; if terr is not protected by Shield but has Forts, 1 Fort is destroyed
		print ("[SHIELD or FORT]");

		--destroy 1 fort on the territory iff there are any forts on the territory and no Shield is active
		if (boolTerritoryHasShield == false and strFortStructureID ~= nil) then
			-- local fortStructureID = WL.StructureType.Custom ("Fort"); --matches to StructureImages/Fort.png  <--- this only works if this structure was created by the current mod (else StructureImages/Fort.png doesn't exist)
			local structures = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].Structures;
			local intNumForts = structures [strFortStructureID] ~= nil and structures [strFortStructureID] or 0;
			print ("[NO SHIELD + YES FORT] # forts: " ..intNumForts);

			if (intNumForts >= 1) then
				structures [strFortStructureID] = structures [strFortStructureID] - 1;
				local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
				terrMod.SetStructuresOpt = structures;
				eventDestroyFort = WL.GameOrderEvent.Create (order.PlayerID, "Destroyed fort", {}, {terrMod});
				eventDestroyFort.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID);
				eventDestroyFort.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Destroy Fort")};
			end
		end
	else
		--terr not protected by Shield or Fort
		armies = terr.NumArmies.NumArmies;
		armies = math.floor (armies * Mod.Settings.ArmyDamagePercent / 100 + Mod.Settings.ArmyDamageFixed + 0.5);

		local intCurrentCityCount = (terr.Structures and terr.Structures [WL.StructureType.City]) or 0;
		local intNumCitiesToDestroy = Mod.Settings.NumCitiesDestroyedByBombPlay or 0;
		if (intCurrentCityCount > 0 and intNumCitiesToDestroy > 0) then
			local intNewCityCount = math.max (0, intCurrentCityCount - intNumCitiesToDestroy);
			local structures = terr.Structures or {};
			structures [WL.StructureType.City] = intNewCityCount;
			terrMod.SetStructuresOpt = structures;
		end

		terrMod.AddArmies = -armies;
		if (armies >= game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].NumArmies.NumArmies and Mod.Settings.EmptyTerritoriesGoNeutral and (Mod.Settings.SpecialUnitsPreventNeutral == false or tablelength (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].NumArmies.SpecialUnits) == 0)) then
			terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
		end
	end

	local event = WL.GameOrderEvent.Create (order.PlayerID, strBombMsg, {}, {terrMod});
	-- event.RemoveWholeCardsOpt = {[order.PlayerID] = order.CardInstanceID}; --consume the Bomb card (must be done b/c we're skipping the original order that consumes the card)
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine triggered", 4, 255)}; --mimic the base "Bomb" annotation
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID); --move the camera to the target territory
	event.Icon = strBombOrderFilename;

	applySpecialUnitDamage (game, addNewOrder, event, terr, terrMod, order.PlayerID, terr.OwnerPlayerID, -Mod.Settings.SUdamagePercent/100, -Mod.Settings.SUdamageFixed, false); --last param 'false' indicates to not apply to all stats, only reduce Health/DTK

	--2nd param indicates whether to skip this order if the original order is skipped (by this or any other mod)
	--if using regular bomb card, original order will be skipped (elsewhere in code) so it doesn't apply default damage of 50%, so must use 'false' when calling addNewOrder
	--but if using the new custom Bomb+ card, use 'true' here so it is correctly tied to orig order and if that is skipped (via Card Block, etc), then this order is also skipped
	-- addNewOrder (event, true);
	if (eventDestroyFort ~= nil) then addNewOrder (eventDestroyFort, true); end -- if an event to destroy a Fort was created, add it here after the "Bomb+" order

	--remove the landmine from the private game data so it doesn't explode again
	print ("[POST CHECK 1] # landmines deployed: " .. tablelength (Mod.PrivateGameData.LandmineData or {}) ..", removing terr " ..intTargetTerritoryID.."/"..game.Map.Territories [intTargetTerritoryID].Name);
	local privateGameData = Mod.PrivateGameData;
	local LandmineData = privateGameData.LandmineData;
	LandmineData [intTargetTerritoryID] = nil;
	privateGameData.LandmineData = LandmineData;
	Mod.PrivateGameData = privateGameData;
	print ("[POST CHECK 2] # landmines deployed: " .. tablelength (Mod.PrivateGameData.LandmineData or {}) ..", removing terr " ..intTargetTerritoryID.."/"..game.Map.Territories [intTargetTerritoryID].Name);
end

--reduce SU Health/DTK on taget territory owned by targetPlayerID by % specified by numSUreductionRate (-0.1 = 10% reduction)
function applySpecialUnitDamage (game, addNewOrder, event, terr, impactedTerritory, castingPlayerID, targetPlayerID, numSUreductionRate, numSUdamageFixed, boolSUpunishment_ApplyToAllStats)
	-- if (#terr.NumArmies.SpecialUnits > 0) then
		local targetTerritoryID = terr.ID;
		print ("[BOMB+ - SU Reduction] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", #SUs " ..#terr.NumArmies.SpecialUnits.. ", SU damage % ".. tostring (numSUreductionRate).. ", SU fixed damage " ..tostring (numSUdamageFixed).. ", affects all stats: " ..tostring (boolSUpunishment_ApplyToAllStats));

		-- SU damage defined by: SUpunishmentRate & boolSUpunishment_AffectsAllStats set in punishReward.lua -- eventually to be Mod.Settings.xyz values
		local SUsNewList = {}; --new list of SUs after applying Punishment SU damage
		local SUsToRemove = {}; --list of SUs to remove after applying Punishment SU damage (b/c they are replaced by the ones in SUsNewList)
		for _,SU in pairs (terr.NumArmies.SpecialUnits) do
			--if SU is Commander or Boss, handle it separately  (must create a Custom SU to mimic these built-in SUs) --> actually just ignore these for now, need to figure out how to handle these special SUs
			--if SU has Health, reduce the Health by the appropriate amount (must clone the SU and remove the current one)
			--if SU is DamageToKill type, reduce the DamageToKill value by the appropriate amount (must clone the SU and remove the current one)
			if (SU.proxyType == "Commander" or SU.proxyType == "Boss" or SU.proxyType == "Boss1" or SU.proxyType == "Boss2" or SU.proxyType == "Boss3" or SU.proxyType == "Boss4") then
				--handle Commander/Boss SUs here
				--but don't do anything for now; how should these special Built-In units be handled? They have fixed properties and can't be "weakened"; would have to recreate as a Custom SU which make break other aspects of the game related to those units
				--so just do nothing until I can come up with a good idea for this case
			elseif (SU.proxyType == "CustomSpecialUnit") then
				local builder = WL.CustomSpecialUnitBuilder.CreateCopy (SU);
				-- if (terrID_somewhereInThePunishment == nil) then terrID_somewhereInThePunishment = targetTerritoryID; end --set this to one of the territories in the Punishment to write the "Punishment" annotation (as opposed to the "." ones for the other impacted areas)
				-- print ("[PRE]  Health " ..tostring (builder.Health).. ", DamageToKill " ..tostring (builder.DamageToKill).. ", Name " ..tostring (builder.Name));
				local intDamageToSU = 0;
				if (builder.Health ~= nil) then
					intDamageToSU = math.min (-1, SU.Health * (numSUreductionRate)) + numSUdamageFixed;
					builder.Health = math.max (0, builder.Health + intDamageToSU);
					print ("[BOMB+ - Health SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", Health " ..tostring (SU.Health) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
				elseif (builder.DamageToKill ~= nil) then
					intDamageToSU = math.min (-1, SU.DamageToKill * (numSUreductionRate)) + numSUdamageFixed;
					builder.DamageToKill = math.max (0, SU.DamageToKill + intDamageToSU);
					print ("[BOMB+ - DamageToKill SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", DamageToKill " ..tostring (SU.DamageToKill) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
				end

				--if setting to apply to all abilities is true, modify AttackPower, DefensePower, AttackPowerPercent, DefensePowerPercent, DamageAbsorption; ignores the SU Fixed Damage amount, reduce using only SU Percent Damage modifier
				if (boolSUpunishment_ApplyToAllStats == true) then
					if (builder.AttackPower ~= nil) then builder.AttackPower = math.max (0, SU.AttackPower + math.min (-1, SU.AttackPower * numSUreductionRate)); end
					if (builder.DefensePower ~= nil) then builder.DefensePower = math.max (0, SU.DefensePower + math.min (-1, SU.DefensePower * numSUreductionRate)); end
					if (builder.DamageAbsorbedWhenAttacked ~= nil) then builder.DamageAbsorbedWhenAttacked = math.min (0, SU.DamageAbsorbedWhenAttacked + math.max (-1, SU.DamageAbsorbedWhenAttacked * (1+numSUreductionRate))); end
					--DamageAbsorbedWhenAttacked is also ignored for Health based SUs, but not really relevant here
				end
				-- print ("[POST] Health " ..tostring (builder.Health).. ", DamageToKill " ..tostring (builder.DamageToKill).. ", Name " ..tostring (builder.Name));

				local newSU = nil;
				--if SU.Health is defined, SU.DamageToKill is ignored even if defined
				-- if (builder.Health == nil and builder.DamageToKill ~= nil and builder.DamageToKill >= 0 or builder.Health ~= nil and builder.Health >= 0) then --this version of the IF creates SUs with 0 Health or 0 DTK when they have been reduced to 0 instead of killing them
				if (builder.Health == nil and builder.DamageToKill ~= nil and builder.DamageToKill > 0 or builder.Health ~= nil and builder.Health > 0) then --this version of the IF kills SUs that have been reduced to 0 Health or 0 DTK
					--SU is still alive, either DTK>0 or Health>0, so remove existing SU + add cloned/reduced SU to territory
					newSU = builder.Build (); --create newSU
					table.insert (SUsNewList, newSU);
					-- print ("[SU survives - reduce & replace it]")
				else
					--SU died b/c either DTK==0 or Health==0, so just remove existing SU from territory and don't add a new SU
					-- print ("[SU dies - just remove it]")
				end
				table.insert (SUsToRemove, SU.ID);
			end
		end

		--if SUs were modified by Punishment, add the SU Removals/Additions to the event order
		--if no SUs were modified and no army damage was done, don't add an event order
		local strOrderDescription = "Bomb+ SU damage";
		if (impactedTerritory == nil) then impactedTerritory = WL.TerritoryModification.Create (terr.ID); end
		-- print ("[BOMB TEST1] " .. tostring (#SUsNewList));
		-- print ("[BOMB TEST2] " .. tostring (#SUsToRemove));
		print ("[BOMB TEST3] " .. tostring (#SUsNewList) ..", " .. tostring (#SUsToRemove));
		if (#SUsNewList == 0 and #SUsToRemove == 0) then
			--no SUs to add or remove, just apply army damage --> for Bomb+ v3, this is handled in the main Bomb+ order, so no army damage is applied here (at least not right now)
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strBombOrderFilename;
			end
			print ("[BOMB] SUBMIT EVENT");
			addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
		elseif (#SUsNewList == 0 and #SUsToRemove > 0) then --no SUs to add, only SUs to remove (killed by poison)
			impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strBombOrderFilename;
			end
			addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
		else
			--SUs to add/remove
			--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
			local specialsToAdd = split_table_into_blocks (SUsNewList, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders

			--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
			for k,SUlistBlock in pairs (specialsToAdd) do
				impactedTerritory.AddSpecialUnits = SUlistBlock; --add Specials to target territory

				if (k == 1) then
					impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
				end
				if (event == nil) then
					event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
					event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
					event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Landmine (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
					event.Icon = strBombOrderFilename;
				end
				addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
				event = nil;
			end
		end
	-- end
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

--if territory has 1+ Forts, return the structure ID of the Forts, else return nil
function territoryHasFort (territory)
	local structures = territory.Structures or {};
	local strFortStructureID = nil;

	for key, _ in pairs (structures) do
		local structureData = split (key, "|");
		if (structureData [1] == "c" and structureData [3] == "Fort") then strFortStructureID = key; end
	end

	return strFortStructureID;
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

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end

function split_table_into_blocks (data, blockSize)
	local blocks = {};
	for i = 1, #data, blockSize do
		local block = {};
		for j = i, math.min(i + blockSize - 1, #data) do
			table.insert(block, data[j]);
		end
		table.insert(blocks, block);
	end
	return blocks;
end