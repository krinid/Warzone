local strTimeBombOrderFilename = "Time bomb order icon 40x40"; --icon for the Time Bomb order in the order list

function Server_AdvanceTurn_Start (game, addNewOrder)
	for terrID, timeBombDataRecord in pairs (Mod.PrivateGameData.TimeBombData or {}) do
		-- local timeBombDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber, turnTimeBombExplodes = game.Game.TurnNumber + tonumber (Mod.Settings.DurationForMaxPower or 3)};
		-- local territory = game.ServerGame.LatestTurnStanding.Territories [terrID];
		-- local terrMod = WL.TerritoryModification.Create (terrID);
		-- local structureMods = {};
		-- local intNumTurnsRemainingToExplode = tonumber(timeBombDataRecord.turnTimeBombExplodes) - game.Game.TurnNumber;

		print ("[Time Bomb] terr " ..terrID.. "/" ..tostring (game.Map.Territories [terrID].Name).. ", castingPlayer " ..timeBombDataRecord.castingPlayer.. ", owner " ..timeBombDataRecord.territoryOwner.. ", turn played " ..timeBombDataRecord.turnNumberPlayed.. ", turn explodes  " ..timeBombDataRecord.turnTimeBombExplodes.. ", currTurn " ..tostring (game.Game.TurnNumber).. ", timeLeft " ..tostring (tonumber(timeBombDataRecord.turnTimeBombExplodes) - game.Game.TurnNumber));
		print ("[Time Bomb CHECK] Mod.PrivateGameData.TimeBombData [terrID] == " ..tostring (Mod.PrivateGameData.TimeBombData [terrID]));
		print ("[Time Bomb 2nd check] " .. terrID .. ", " ..game.ServerGame.LatestTurnStanding.Territories [terrID].OwnerPlayerID.. ", " ..game.Map.Territories [terrID].Name);
		if (tonumber (game.Game.TurnNumber) >= tonumber (timeBombDataRecord.turnTimeBombExplodes)) then
			local strDisplayMsg = "Time Bomb explode prep; Time Bomb on " ..game.Map.Territories [terrID].Name .. " explodes";
			local strPayload = "ExplodeOrder-Time Bomb|".. terrID;
			local event = WL.GameOrderEvent.Create (game.ServerGame.LatestTurnStanding.Territories [terrID].OwnerPlayerID, strPayload, {}, {}, {}, {});
			event.Icon = strTimeBombOrderFilename;
			addNewOrder (event);
		end
	end
end

function Server_AdvanceTurn_End (game, addNewOrder)
	-- local annotations = {};
	-- for terrID, timeBombDataRecord in pairs (Mod.PrivateGameData.TimeBombData or {}) do
	-- 	print ("[Time Bomb] terr " ..terrID.. "/" ..tostring (game.Map.Territories [terrID].Name).. ", castingPlayer " ..timeBombDataRecord.castingPlayer.. ", owner " ..timeBombDataRecord.territoryOwner.. ", turn played " ..timeBombDataRecord.turnNumberPlayed.. ", turn explodes  " ..timeBombDataRecord.turnTimeBombExplodes);
	-- 	print ("[Time Bomb CHECK] Mod.PrivateGameData.TimeBombData [terrID] == " ..tostring (Mod.PrivateGameData.TimeBombData [terrID]));
		-- if (annotations [timeBombDataRecord.castingPlayer] == nil) then annotations [timeBombDataRecord.castingPlayer] = {}; end
		-- annotations [timeBombDataRecord.castingPlayer][terrID] = WL.TerritoryAnnotation.Create ("Landmine reminder", 4, 0);
		-- local timeBombDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber};
	-- end
	local territoryModifications = {};

	for terrID, timeBombDataRecord in pairs (Mod.PrivateGameData.TimeBombData or {}) do
		-- local timeBombDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber, turnTimeBombExplodes = game.Game.TurnNumber + tonumber (Mod.Settings.DurationForMaxPower or 3)};
		local territory = game.ServerGame.LatestTurnStanding.Territories [terrID];
		local terrMod = WL.TerritoryModification.Create (terrID);
		local structureMods = {};
		local intNumTurnsRemainingToExplode = tonumber(timeBombDataRecord.turnTimeBombExplodes) - game.Game.TurnNumber;

		print ("[Time Bomb] terr " ..terrID.. "/" ..tostring (game.Map.Territories [terrID].Name).. ", castingPlayer " ..timeBombDataRecord.castingPlayer.. ", owner " ..timeBombDataRecord.territoryOwner.. ", turn played " ..timeBombDataRecord.turnNumberPlayed.. ", turn explodes  " ..timeBombDataRecord.turnTimeBombExplodes.. ", currTurn " ..tostring (game.Game.TurnNumber).. ", timeLeft " ..tostring (tonumber(timeBombDataRecord.turnTimeBombExplodes) - game.Game.TurnNumber));
		print ("[Time Bomb CHECK] Mod.PrivateGameData.TimeBombData [terrID] == " ..tostring (Mod.PrivateGameData.TimeBombData [terrID]));
		print ("[Time Bomb 2nd check] " .. terrID .. ", " ..game.ServerGame.LatestTurnStanding.Territories [terrID].OwnerPlayerID.. ", " ..game.Map.Territories [terrID].Name);
		if (tonumber (game.Game.TurnNumber) >= tonumber (timeBombDataRecord.turnTimeBombExplodes)) then
			local strDisplayMsg = "Time Bomb explode prep; Time Bomb on " ..game.Map.Territories [terrID].Name .. " explodes";
			local strPayload = "ExplodeOrder-Time Bomb|".. terrID;
			local event = WL.GameOrderEvent.Create (game.ServerGame.LatestTurnStanding.Territories [terrID].OwnerPlayerID, strPayload, {}, {}, {}, {});
			event.Icon = strTimeBombOrderFilename;
			addNewOrder (event);
		else
			--replace structure timer with the proper Time Bomb structure showing the countdown timer showing how many turns left until explosion 
			-- if (tonumber (game.Game.TurnNumber) >= tonumber (timeBombDataRecord.turnTimeBombExplodes)) then
			--structure files are Time Bomb 00.png->Time Bomb 10.png and use Time Bomb 11+.png for anything 11 or higher
			-- local strStructureDelimiter_NEW = string.format("%02d", Mod.Settings.TimeBombDurationForMaxPower); --set to 2 digit number with leading zeroes if required
			local strStructureDelimiter_OLD = string.format("%02d", tonumber (timeBombDataRecord.turnTimeBombExplodes) - tonumber (game.Game.TurnNumber)); --set to 2 digit number with leading zeroes if required
			local strStructureDelimiter_NEW = string.format("%02d", math.max (0, tonumber (strStructureDelimiter_OLD) - 1)); --set to 2 digit number with leading zeroes if required
			-- local strStructureDelimiter_NEW = string.format("%02d", tonumber (timeBombDataRecord.turnTimeBombExplodes) - tonumber (game.Game.TurnNumber) - 1); --set to 2 digit number with leading zeroes if required
			-- local strStructureDelimiter_OLD = string.format("%02d", tonumber (strStructureDelimiter_NEW) + 1); --set to 2 digit number with leading zeroes if required
			if (tonumber (strStructureDelimiter_OLD) >= 11) then strStructureDelimiter_OLD = "11+"; end
			if (tonumber (strStructureDelimiter_NEW) >= 11) then strStructureDelimiter_NEW = "11+"; end
			local strStructureName_NEW = "Time Bomb " ..strStructureDelimiter_NEW; --Mod.Settings.TimeBombDurationForMaxPower
			local strStructureName_OLD = "Time Bomb " ..strStructureDelimiter_OLD; --Mod.Settings.TimeBombDurationForMaxPower
			local structureID_NEW = WL.StructureType.Custom (strStructureName_NEW);
			local structureID_OLD = WL.StructureType.Custom (strStructureName_OLD);
			print ("[TIME BOMB]   delimNEW " ..tostring (strStructureDelimiter_NEW).. ", delimOLD " ..tostring (strStructureDelimiter_OLD).. ", nameNEW " ..tostring (strStructureName_NEW).. ", nameOLD " ..tostring (strStructureName_OLD).. ", IDnew " ..tostring (structureID_NEW).. ", IDold " ..tostring (structureID_OLD));
			--decrease old structure count by 1
			--increase new structure count by 1

			-- if not territory then return false, nil; end --if territory is nil, just return false/nil
			local structures = territory.Structures;
			for structureID, structureCount in pairs (structures) do
				local strArrayStructureData = split (structureID, '|');
				print ("[TIME BOMB]    structure " ..tostring (structureID));
				--within 'structureID', 1st segment of "c" indicates custom structure, 2nd segment is mod ID#, 3rd segment is structure name
				--structureCount is integer of # of structures on the territory, and it may be 0, so only return true if there is >=1 remaining, else return false (for this ID -- there may be custom structures of the same name for other IDs, perhaps created from other mods/mod ID#'s)
				if (structureID == structureID_OLD and structureCount > 0) then
					--reduce count of prior structure by 1, increase count of new structure by 1
					if (structureMods [structureID_OLD] == nil) then structureMods [structureID_OLD] = 0; end
					if (structureMods [structureID_NEW] == nil) then structureMods [structureID_NEW] = 0; end
					structureMods [structureID_OLD] = structureMods [structureID_OLD] - 1;
					structureMods [structureID_NEW] = structureMods [structureID_NEW] + 1;
				end
			end
		end
		if (tablelength (structureMods) > 0) then
			terrMod.AddStructuresOpt = structureMods;
			table.insert (territoryModifications, terrMod);
		end
	end

	-- if (tablelength (territoryModifications) > 0) then addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Time passes", {}, territoryModifications, {}, {})); end
	addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Time passes", {}, territoryModifications, {}, {}));
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	if (order.PlayerID == 1058239) then
		if (order.proxyType == 'GameOrderCustom' and order.Payload ~= nil) then print ("[ORDER] " ..tostring (order.Payload)); end
		print ("[ORDER] " .. tablelength (Mod.PrivateGameData.TimeBombData or {}) .. " time bombs in play");
		for terrID, timeBombDataRecord in pairs (Mod.PrivateGameData.TimeBombData or {}) do
			print ("[Time Bomb] terr " ..terrID.. "/" ..tostring (game.Map.Territories[terrID].Name).. ", castingPlayer " ..timeBombDataRecord.castingPlayer.. ", owner " ..timeBombDataRecord.territoryOwner.. ", turn played " ..timeBombDataRecord.turnNumberPlayed);
			print ("[Time Bomb CHECK] Mod.PrivateGameData.TimeBombData [terrID] == " ..tostring (Mod.PrivateGameData.TimeBombData [terrID]));
		end
		print ("[ORDER] Mod.PrivateGameData.TimeBombData ~= nil --> " .. tostring (Mod.PrivateGameData.TimeBombData ~= nil));
		-- if (Mod.PrivateGameData.TimeBombData ~= nil ) then print ("[ORDER] Mod.PrivateGameData.TimeBombData ~= nil --> " ..tostring (Mod.PrivateGameData.TimeBombData ~= nil)); end
		if (order.proxyType == 'GameOrderAttackTransfer') then
			local a = Mod.PrivateGameData.TimeBombData == nil;
			local b = Mod.PrivateGameData.TimeBombData ~= nil and Mod.PrivateGameData.TimeBombData [order.To];
			print ("[ORDER] To " ..order.To.. "/" ..tostring (game.Map.Territories[order.To].Name).. ", TimeBombData == " ..tostring (a).. ", TimeBombData[terrID] == " .. tostring (b));
		end
	end

	if ((order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Time Bomb|") == true)) then
		local modDataContent = split (order.ModData, "|");
		local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID
		print ("[Time Bomb initial order] " .. tostring (order.ModData));
		local event = WL.GameOrderCustom.Create (order.PlayerID, "Time Bomb initial order; " ..getPlayerName (game, order.PlayerID).. " deploys a time bomb on " ..game.Map.Territories [intTargetTerritoryID].Name, "DeployOrder-Time Bomb|".. intTargetTerritoryID)
		event.Icon = strTimeBombOrderFilename;
		addNewOrder (event, true);
	elseif ((order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, "DeployOrder-Time Bomb|") == true)) then
		print ("[Time Bomb placement] " ..tostring (order.Payload));
		--skip the trigger order
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this custom game order, it's just a trigger for the real card that makes it properly blockable by Card Block
		placeTimeBomb (game, order, addNewOrder);
	elseif ((order.proxyType == 'GameOrderEvent' and startsWith (order.Message, "ExplodeOrder-Time Bomb|") == true)) then
		print ("[Time Bomb explode] " ..tostring (order.Message));
		local modDataContent = split (order.Message, "|");
		local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID
		--skip the trigger order
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this custom game order, it's just a trigger for the real card that makes it properly blockable by Card Block
		explode_TimeBomb (game, order, addNewOrder, intTargetTerritoryID);
	end
end

function placeTimeBomb (game, order, addNewOrder)
	--stuff
	local modDataContent = split (order.Payload, "|");
	-- print ("[GameOrderPlayCardCustom] modData=="..order.ModData.."::");
	-- strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name --already captured in global variable 'strCardTypeBeingPlayed' from process_game_orders_CustomCards function
	local intTargetTerritoryID = tonumber (modDataContent[2]); --2nd component of ModData is the target territory ID

	--check if terr is within range of X of own terrs
	--check if terr belongs to self or neutral
	--if self, arm it immediately; if neutral, arm at end of turn
    local impactedTerritory = WL.TerritoryModification.Create (intTargetTerritoryID);
	local structures = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].Structures;

	--structure files are Time Bomb 00.png->Time Bomb 10.png and use Time Bomb 11+.png for anything 11 or higher
	local strStructureDelimiter = string.format("%02d", Mod.Settings.TimeBombDurationForMaxPower or 3); --set to 2 digit number with leading zeroes if required
	if (Mod.Settings.TimeBombDurationForMaxPower or 3>= 11) then strStructureDelimiter = "11+"; end
	local strStructureName = "Time Bomb " ..strStructureDelimiter; --Mod.Settings.TimeBombDurationForMaxPower
	local structureID = WL.StructureType.Custom (strStructureName);
	-- local structureID = WL.StructureType.Custom ("Time Bomb");
	if (structures == nil) then structures = {}; end;
	if (structures [structureID] == nil) then structures [structureID] = 0; end;
	print ("[TIME BOMB] PRE - # time bombs on terr " ..game.Map.Territories [intTargetTerritoryID].Name.. " == "..tostring (structures [structureID]));
	structures [structureID] = structures [structureID] + 1;
	-- structures [WL.StructureType.Custom ("Portal")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 1")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 2")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 3")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 4")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 5")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 6")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 7")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 8")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 9")] = 1;
	-- structures [WL.StructureType.Custom ("Portal 10")] = 1;
	-- structures [WL.StructureType.Custom ("Poison")] = 1;
	-- structures [WL.StructureType.Custom ("earthquake")] = 1;
	-- structures [WL.StructureType.Custom ("isolation")] = 1;
	-- structures [WL.StructureType.Custom ("neutralized territory")] = 1;
	-- structures [WL.StructureType.Custom ("Beacon")] = 1;
	-- structures [WL.StructureType.Custom ("Fort")] = 1;
	-- structures [WL.StructureType.Custom ("")] = 1;
	impactedTerritory.SetStructuresOpt = structures;
	-- structures [structureID] = structures [structureID] ~= nil and structures [structureID] or 0 + 1;
	-- 	structures [WL.StructureType.Custom ("time bomb")] = 1;
	-- else
	-- 	structures [WL.StructureType.Custom ("time bomb")] = structures [WL.StructureType.Custom ("time bomb")] + 1;
	-- end

	local strTimeBombMsg = getPlayerName (game, order.PlayerID).. " places a time bomb on " ..game.Map.Territories [intTargetTerritoryID].Name;
	local event = WL.GameOrderEvent.Create (order.PlayerID, strTimeBombMsg, {}, {impactedTerritory}, {}, {});
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID);
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Time bomb deployed")};
	event.Icon = strTimeBombOrderFilename;
	addNewOrder (event, false);

	local timeBombDataRecord = {territory = intTargetTerritoryID, castingPlayer = order.PlayerID, territoryOwner = game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID].OwnerPlayerID, turnNumberPlayed = game.Game.TurnNumber, turnTimeBombExplodes = game.Game.TurnNumber + tonumber (Mod.Settings.TimeBombDurationForMaxPower or 3)};
	local privateGameData = Mod.PrivateGameData;
	privateGameData.TimeBombData = privateGameData.TimeBombData or {};
	privateGameData.TimeBombData [intTargetTerritoryID] = timeBombDataRecord;
	Mod.PrivateGameData = privateGameData;
	print ("[TIME BOMB] POST - # time bombs on terr " ..game.Map.Territories [intTargetTerritoryID].Name.. " == "..tostring (structures [structureID]));
	print ("[PLACE TIME BOMB FINISH] " .. tablelength (Mod.PrivateGameData.TimeBombData or {}) .. " time bombs in play");
end

function explode_TimeBomb (game, order, addNewOrder, intTargetTerritoryID)
	-- local modDataContent = split (order.ModData, "|");
	-- local intTargetTerritoryID = modDataContent[2]; --2nd component of ModData is the source territory ID
	local strFortStructureID = territoryHasFort (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local boolTerritoryHasShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
	local armies;
	local strTimeBombMsg = "Time Bomb explodes on " ..game.Map.Territories [intTargetTerritoryID].Name;
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
				eventDestroyFort = WL.GameOrderEvent.Create (order.PlayerID, "Destroyed fort", {}, {terrMod}, {}, {});
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

	-- local structureID = WL.StructureType.Custom ("Time Bomb");
	local structureID = WL.StructureType.Custom ("Time Bomb 00");
	local structures = {};
	structures [structureID] = -1;
	terrMod.AddStructuresOpt = structures;
	-- local structures = terr.Structures;
	-- if (structures == nil) then structures = {}; end;
	-- if (structures [structureID] == nil) then structures [structureID] = 0; end;
	print ("[TIME BOMB] PRE - # time bombs on terr " ..game.Map.Territories [intTargetTerritoryID].Name.. " == hard to count now (hmmm)"); --..tostring (structures [structureID]));

	local event = WL.GameOrderEvent.Create (order.PlayerID, strTimeBombMsg, {}, {terrMod}, {}, {});
	-- event.RemoveWholeCardsOpt = {[order.PlayerID] = order.CardInstanceID}; --consume the TimeBomb card (must be done b/c we're skipping the original order that consumes the card)
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Time Bomb", 4, 255)}; --mimic the base "Bomb" annotation
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID); --move the camera to the target territory
	event.Icon = strTimeBombOrderFilename;

	applySpecialUnitDamage (game, addNewOrder, event, terr, terrMod, order.PlayerID, terr.OwnerPlayerID, -Mod.Settings.SUdamagePercent/100, -Mod.Settings.SUdamageFixed, false); --last param 'false' indicates to not apply to all stats, only reduce Health/DTK

	if (eventDestroyFort ~= nil) then addNewOrder (eventDestroyFort, true); end -- if an event to destroy a Fort was created, add it here after the "TimeBomb" order

	--remove the time bomb from the private game data so it doesn't explode again
	print ("[POST CHECK 1] # time bombs deployed: " .. tablelength (Mod.PrivateGameData.TimeBombData or {}) ..", removing terr " ..intTargetTerritoryID.."/"..game.Map.Territories [intTargetTerritoryID].Name);
	local privateGameData = Mod.PrivateGameData;
	local TimeBombData = privateGameData.TimeBombData;
	TimeBombData [intTargetTerritoryID] = nil;
	privateGameData.TimeBombData = TimeBombData;
	Mod.PrivateGameData = privateGameData;
	print ("[POST CHECK 2] # time bombs deployed: " .. tablelength (Mod.PrivateGameData.TimeBombData or {}) ..", removing terr " ..intTargetTerritoryID.."/"..game.Map.Territories [intTargetTerritoryID].Name);
end

--reduce SU Health/DTK on taget territory owned by targetPlayerID by % specified by numSUreductionRate (-0.1 = 10% reduction)
function applySpecialUnitDamage (game, addNewOrder, event, terr, impactedTerritory, castingPlayerID, targetPlayerID, numSUreductionRate, numSUdamageFixed, boolSUpunishment_ApplyToAllStats)
	-- if (#terr.NumArmies.SpecialUnits > 0) then
		local targetTerritoryID = terr.ID;
		print ("[TIMEBOMB - SU Reduction] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", #SUs " ..#terr.NumArmies.SpecialUnits.. ", SU damage % ".. tostring (numSUreductionRate).. ", SU fixed damage " ..tostring (numSUdamageFixed).. ", affects all stats: " ..tostring (boolSUpunishment_ApplyToAllStats));

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
					print ("[TIMEBOMB - Health SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", Health " ..tostring (SU.Health) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
				elseif (builder.DamageToKill ~= nil) then
					intDamageToSU = math.min (-1, SU.DamageToKill * (numSUreductionRate)) + numSUdamageFixed;
					builder.DamageToKill = math.max (0, SU.DamageToKill + intDamageToSU);
					print ("[TIMEBOMB - DamageToKill SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", DamageToKill " ..tostring (SU.DamageToKill) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
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
		local strOrderDescription = "TIMEBOMB SU damage";
		if (impactedTerritory == nil) then impactedTerritory = WL.TerritoryModification.Create (terr.ID); end
		print ("[TIMEBOMB TEST3] " .. tostring (#SUsNewList) ..", " .. tostring (#SUsToRemove));
		if (#SUsNewList == 0 and #SUsToRemove == 0) then
			--no SUs to add or remove, just apply army damage --> for TimeBomb, this is handled in the main TimeBomb order, so no army damage is applied here (at least not right now)
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory}, {}, {});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Time Bomb (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strTimeBombOrderFilename;
			end
			print ("[TIMEBOMB] SUBMIT EVENT");
			addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
		elseif (#SUsNewList == 0 and #SUsToRemove > 0) then --no SUs to add, only SUs to remove (killed by poison)
			impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory}, {}, {});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Time Bomb (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strTimeBombOrderFilename;
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
					event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory}, {}, {});
					event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
					event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Time Bomb (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
					event.Icon = strTimeBombOrderFilename;
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