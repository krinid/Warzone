--this code exists in multiple mods that damage & recreate SUs, in order to avoid multiple mods manipulating and skipping the same orders (eg: when an SU is damaged by Bomb+, the same or another SU is damaged by Landmine, another by Poison, etc), have the
--mods arrange among themselves via order submission & analysis which single mod shall be the master for this current game, and going forward that single mod will handle the order adjustment for replaced SUs
--secondary (non-master) mods will submit orders indicating the GUID mapping their mod is responsible for, but leave the actual order adjustment to the master mod
--to decide the master mod, each mod will submit an order indicating that it's an SU replacing mod, and the 1st order into the order list becomes the mod master, all other become secondary mods for this functionality
--the order list is the same for all mods, so they can all make the same decision on which mod the master is (and more importantly whether they are the master or not)
function decide_SU_replacer_MasterMod (addNewOrder)
	--if Master hasn't been decided yet, submit an order indicating that this is an SU replacing mod
	--while we're submitting this order, snag the actual ModID for this mod so it doesn't have to be manually hardcoded
	if (Mod.PrivateGameData == nil or Mod.PrivateGameData.MasterMod == nil) then
		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "SU_replacer_mod|DecideMasterMod");
		local pgd = Mod.PrivateGameData or {};
		pgd.ModID = event.ModID;
		Mod.PrivateGameData = pgd;
		print ("[SU REPLACER] [DecideMasterMod order submitted] This Mod ID " ..Mod.PrivateGameData.ModID);
		addNewOrder (event);
	elseif (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod == true) then
		--if this mod is Master, set global variables used in multiple functions to empty at start of each turn
		SUreplacementMapping = {};
		SUreplacementMapping_Reverse = {};
	end
end

--process SU_replacer mod orders for deciding MasterMod and if this mod is the MasterMod, accept and save Old SU to New SUI GUID mappings
function process_SU_replacer_MasterMod_orders (game, order, skipThisOrder, addNewOrder)
	-- if (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod ~= nil) then return; end --master already decided, don't process any more of these orders
	if (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod == nil and order.proxyType == "GameOrderEvent" and order.Message == "SU_replacer_mod|DecideMasterMod") then
		--if MasterMod hasn't been determined yet, and this is an order to determine the MasterMod, process it; if MasterMod has been determined already, then don't bother procesing any more of these, they are superfluous
		print ("[SU REPLACER] [MasterMod Decision] Master Mod ID " ..order.ModID.. ", This mod ID " ..Mod.PrivateGameData.ModID.. ", Master: " .. tostring (order.ModID == Mod.PrivateGameData.ModID));
		local pgd = Mod.PrivateGameData or {};
		if (order.ModID == Mod.PrivateGameData.ModID) then --this mod is MasterMod
			pgd.MasterMod = true;
			SUreplacementMapping = {}; --initialize these global variables; this will be necessary do to here b/c the code executed in _Start will only initialize these variables if the mod was designated the Master before the turn started
			SUreplacementMapping_Reverse = {};
		else --this mod is not MasterMod, it is a secondary mod
			pgd.MasterMod = false;
		end
		Mod.PrivateGameData = pgd;
	elseif (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod == true and order.proxyType == "GameOrderEvent" and startsWith (order.Message, "SU_replacer_mod|SU_replacement|") == true) then
		--this is an order from a secondary mod containing the mapping for a replaced Old SU GUID to a New SU GUID - save the mapping in the private game data within this mod
		print ("[SU Replacer] [Master Mod] [Receive Mapping] " ..tostring (order.Message));
		local modDataContent = split (order.Message, "|");
		-- local SUreplacementMapping = Mod.PrivateGameData.SUreplacementMapping or {}; --initialize to {} is not set yet
		-- local SUreplacementMapping_Reverse = Mod.PrivateGameData.SUreplacementMapping_Reverse or {}; --initialize to {} is not set yet
		-- modDataContent [3] is the oldGUID, modDataContent [4] is the newGUID
		local strOldGUID = modDataContent [3];
		local strNewGUID = modDataContent [4];
		if (SUreplacementMapping == nil) then SUreplacementMapping = {}; end --initialize these global variables; this will be necessary do to here b/c the code executed in _Start will only initialize these variables if the mod was designated the Master before the turn started
		if (SUreplacementMapping_Reverse == nil) then SUreplacementMapping_Reverse = {}; end
		local strReverseSearchGUID = SUreplacementMapping_Reverse [modDataContent [3]];

		if (strReverseSearchGUID == nil) then
			SUreplacementMapping [strOldGUID] = strNewGUID;
			SUreplacementMapping_Reverse [strNewGUID] = strOldGUID;
		else
			SUreplacementMapping [strOldGUID] = strNewGUID;
			SUreplacementMapping [strReverseSearchGUID] = strNewGUID;
			SUreplacementMapping_Reverse [strNewGUID] = strReverseSearchGUID;
		end
		if (strReverseSearchGUID ~= nil) then SUreplacementMapping [strReverseSearchGUID] = strNewGUID; SUreplacementMapping_Reverse [strNewGUID] = strReverseSearchGUID; end
		print ("___[SU REPLACER] Old " ..strOldGUID.. ", New " ..strNewGUID.. ", Reverse " ..tostring (strReverseSearchGUID));

		-- SUreplacementMapping [modDataContent [3]] = modDataContent [4]; --store the GUID mapping
		-- SUreplacementMapping_Reverse [modDataContent [4]] = modDataContent [3]; --store the reverse GUID mapping
		-- if (SUreplacementMapping_Reverse [modDataContent [3]] ~= nil) then SUreplacementMapping [SUreplacementMapping_Reverse [modDataContent [3]]] = modDataContent [4]; end
		print ("[SU replacer] [MasterMod] [Save Mapping] " ..order.Message);
		-- local pgd = Mod.PrivateGameData;
		-- pgd.SUreplacementMapping = SUreplacementMapping;
		-- pgd.SUreplacementMapping_Reverse = SUreplacementMapping_Reverse;
		-- Mod.PrivateGameData = pgd;
	elseif (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod == true and order.proxyType == "GameOrderAttackTransfer" and #order.NumArmies.SpecialUnits > 0 and SUreplacementMapping ~= nil) then
		--if this mod is the MasterMod, check if the order contains SUs that have been replaced due to taking damage, if so, need to replace references to the old SUs (old GUIDs) with the new SUs (match by GUID), else the orders will fail b/c the old SUs no longer exist
		--skip this code if no SUs have been replaced yet (Mod.PrivateGameData.SUreplacementMapping == nil)
		local boolSwapWasMade, newSUlist = swap_out_replaced_SUs (game, order, SUreplacementMapping);

		-- local newSUlist = {};
		-- local boolSwapWasMade = false;
		-- for k,v in pairs (SUreplacementMapping) do print ("[MAP TABLE] " .. k.. ", " ..v); end
		-- print ("[SU DUMP ON TERR] terr " ..order.From.. "/" ..game.Map.Territories [order.From].Name);
		-- for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories [order.From].NumArmies.SpecialUnits) do print ("[SU DUMP ON TERR] " .. k.. ", " ..v.proxyType..", " ..v.ID); end --.."/"..v.Name); end
		-- for _,SU in pairs (order.NumArmies.SpecialUnits) do
		-- 	local newSUguid = SUreplacementMapping [SU.ID]; --will result in nil if the current SU wasn't replaced with a new SU
		-- 	if (newSUguid ~= nil) then --SU was replaced with a new SU, need to swap out the old for the new and resubmit the order
		-- 		local newSU = getSpecialUnitWithinArmies (game.ServerGame.LatestTurnStanding.Territories [order.From].NumArmies, newSUguid);
		-- 		print ("[SU REPLACER] [ORDER CHECK] Old GUID found " .. SU.ID..", replace with New SU " ..newSUguid.. "/" ..tostring (newSU).. " on terr " ..order.From.. "/" ..game.Map.Territories [order.From].Name);
		-- 		table.insert (newSUlist, newSU);
		-- 		print ("[SU REPLACER] [ORDER CHECK] Old GUID found " .. SU.ID..", replace with New SU " ..newSU.ID.."/"..newSU.Name);
		-- 		boolSwapWasMade = true; --need to resubmit the order with the old SUs replaced with the new SUs
		-- 	else
		-- 		--if current SU in the loop iteration isn't a replaced SU, just add it back into the Armies structure as-is
		-- 		table.insert (newSUlist, SU);
		-- 	end
		-- end
		if (boolSwapWasMade == true) then
			local newArmies = WL.Armies.Create (order.NumArmies.NumArmies, newSUlist);
			--WL.GameOrderAttackTransfer.Create(playerID PlayerID, from TerritoryID, to TerritoryID, attackOrTransfer AttackTransferEnum (enum), byPercent boolean, numArmies Armies, attackTeammates boolean) (static) returns GameOrderAttackTransfer:
			addNewOrder (WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates));
			skipThisOrder (WL.ModOrderControl.Skip);
			-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		end
	elseif (Mod.PrivateGameData ~= nil and Mod.PrivateGameData.MasterMod == true and order.proxyType == "GameOrderPlayCardAirlift" and #order.Armies.SpecialUnits > 0 and SUreplacementMapping ~= nil) then
		local boolSwapWasMade, newSUlist = swap_out_replaced_SUs (game, order, SUreplacementMapping);
		if (boolSwapWasMade == true) then
			local newArmies = WL.Armies.Create (order.Armies.NumArmies, newSUlist);
			--WL.GameOrderPlayCardAirlift.Create(cardInstanceID CardInstanceID, playerID PlayerID, fromTerritoryID TerritoryID, toTerritoryID TerritoryID, numArmies Armies) (static) returns GameOrderPlayCardAirlift
			addNewOrder (WL.GameOrderPlayCardAirlift.Create (order.CardInstanceID, order.PlayerID, order.FromTerritoryID, order.ToTerritoryID, newArmies));
			skipThisOrder (WL.ModOrderControl.Skip);
			-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		end
	end
end

--process the SU swap of old stale SUs for their new replacement SUs; if a replaced SU GUID is being referenced, get the new SU GUID, find that SU on the territory, rebuild the Armies structure
--return boolean indicating whether a swap was made and the actual Armies structure containing the final/actual list of SUs to be included in the order
function swap_out_replaced_SUs (game, order, SUreplacementMapping)
	local newSUlist = {};
	local boolSwapWasMade = false;
	--if order is Airlift, source territory is order.FromTerritoryID, Armies structure is order.Armies
	--if order is AttackTransfer, source territory is order.From, Armies structure is order.NumArmies
	local intFromTerritoryID = order.proxyType == "GameOrderAttackTransfer" and order.From or order.proxyType == "GameOrderPlayCardAirlift" and order.FromTerritoryID or nil;
	local Armies = order.proxyType == "GameOrderAttackTransfer" and order.NumArmies or order.proxyType == "GameOrderPlayCardAirlift" and order.Armies or nil;
	-- local intFromTerritoryID = nil;
	-- local Armies = nil;
	-- if (order.proxyType == "GameOrderAttackTransfer") then intFromTerritoryID = order.From; Armies = order.NumArmies;
	-- elseif (order.proxyType == "GameOrderPlayCardAirlift") then intFromTerritoryID = order.FromTerritoryID; Armies = order.Armies;
	-- end
	-- local Armies = order.proxyType == "GameOrderAttackTransfer" and order.NumArmies or order.proxyType == "GameOrderPlayCardAirlift" and order.Armies or nil;
	if (intFromTerritoryID == nil or Armies == nil) then return; end --if the From terr or the Armies structure couldn't be acquired, can't continue so do nothign and return

	for k,v in pairs (SUreplacementMapping) do print ("[MAP TABLE] " .. k.. ", " ..v); end
	print ("[SU DUMP ON TERR] terr " ..intFromTerritoryID.. "/" ..game.Map.Territories [intFromTerritoryID].Name);
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories [intFromTerritoryID].NumArmies.SpecialUnits) do print ("[SU DUMP ON TERR] " .. k.. ", " ..v.proxyType..", " ..v.ID); end --.."/"..v.Name); end
	for _,SU in pairs (Armies.SpecialUnits) do
		local newSUguid = SUreplacementMapping [SU.ID]; --will result in nil if the current SU wasn't replaced with a new SU
		if (newSUguid ~= nil) then --SU was replaced with a new SU, need to swap out the old for the new and resubmit the order
			print ("[SU REPLACER] [ORDER CHECK] Old GUID found " .. SU.ID..", replace with New SU " ..newSUguid.. " on terr " ..intFromTerritoryID.. "/" ..game.Map.Territories [intFromTerritoryID].Name);
			local newSU = getSpecialUnitWithinArmies (game.ServerGame.LatestTurnStanding.Territories [intFromTerritoryID].NumArmies, newSUguid);
			print ("[SU REPLACER] [ORDER CHECK] Old GUID found " .. SU.ID..", replace with New SU " ..newSUguid.. "/" ..tostring (newSU).. " on terr " ..intFromTerritoryID.. "/" ..game.Map.Territories [intFromTerritoryID].Name);
			table.insert (newSUlist, newSU);
			print ("[SU REPLACER] [ORDER CHECK] Old GUID found " .. SU.ID..", replace with New SU " ..newSU.ID.."/"..newSU.Name);
			boolSwapWasMade = true; --need to resubmit the order with the old SUs replaced with the new SUs
		else
			--if current SU in the loop iteration isn't a replaced SU, just add it back into the Armies structure as-is
			table.insert (newSUlist, SU);
		end
	end
	return boolSwapWasMade, newSUlist;
end

--if current mod is a secondary mod, not the MasterMod, send the Old SU to New SU GUID mapping out so the MasterMod can save it
function submit_SU_replacer_GUID_mapping (addNewOrder, strOldGUID, strNewGUID)
	-- SUreplacementMapping [SU.ID] = newSU.ID; --preserve a mapping of the old SU to the new SU so future orders can inspect and replace SU references from the old to the new (so orders entered with the old GUID can be replaced with the new GUID, thus the orders won't skip the inclusion of the SU b/c a non-existent old GUID is being referenced)
	-- print ("[ATTACK PROCESSING - SU replacement] Old GUID " ..SU.ID.."/" ..SU.Name.. ", replace with New SU " ..newSU.ID.."/"..newSU.Name);
	-- print ("[ATTACK PROCESSING - SU replacement] Old GUID " ..strOldGUID.. ", replace with New SU " ..strNewGUID);
	if (Mod.PrivateGameData.MasterMod == false) then
		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "SU_replacer_mod|SU_replacement|" ..strOldGUID.. "|" ..strNewGUID);
		addNewOrder (event);
		print ("[SU replacer] [Secondary Mod] [Send Mapping] " ..event.Message);
	else
		local event = WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "SU_replacer_mod|SU_replacement|" ..strOldGUID.. "|" ..strNewGUID);
		addNewOrder (event);
		print ("[SU replacer] This mod is master, sending mapping anyhow (to pick up by self)");
	end
end

--reduce SU Health/DTK on taget territory owned by targetPlayerID by % specified by numSUreductionRate (-0.1 = 10% reduction)
function applySpecialUnitDamage (game, addNewOrder, event, terr, impactedTerritory, castingPlayerID, targetPlayerID, numSUreductionRate, numSUdamageFixed, boolSUpunishment_ApplyToAllStats, strAbilityDisplayName, strOrderIconFilename)
	local targetTerritoryID = terr.ID;
	-- local SUreplacementMapping = Mod.PrivateGameData.SUreplacementMapping or {}; --initialize to {} is not set yet

	print ("[" ..string.upper (strAbilityDisplayName).. " - SU Reduction] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", #SUs " ..#terr.NumArmies.SpecialUnits.. ", SU damage % ".. tostring (numSUreductionRate).. ", SU fixed damage " ..tostring (numSUdamageFixed).. ", affects all stats: " ..tostring (boolSUpunishment_ApplyToAllStats));

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
				print ("[" ..string.upper (strAbilityDisplayName).. " - Health SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", Health " ..tostring (SU.Health) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
			elseif (builder.DamageToKill ~= nil) then
				intDamageToSU = math.min (-1, SU.DamageToKill * (numSUreductionRate)) + numSUdamageFixed;
				builder.DamageToKill = math.max (0, SU.DamageToKill + intDamageToSU);
				print ("[" ..string.upper (strAbilityDisplayName).. " - DamageToKill SU damage] terr " ..targetTerritoryID.. "/" ..getTerritoryName (targetTerritoryID, game).. ", DamageToKill " ..tostring (SU.DamageToKill) ..", fixed damage " ..tostring (intDamageToSU) ..", damage rate ".. numSUreductionRate);
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
			--if SU.Health is defined, SU.DamageToKill is ignored even if defined; if the SU dies, remove it; if the SU is damaged but still alive, replace it with a new SU that possesses the new reduced specs
			-- if (builder.Health == nil and builder.DamageToKill ~= nil and builder.DamageToKill >= 0 or builder.Health ~= nil and builder.Health >= 0) then --this version of the IF creates SUs with 0 Health or 0 DTK when they have been reduced to 0 instead of killing them
			if (builder.Health == nil and builder.DamageToKill ~= nil and builder.DamageToKill > 0 or builder.Health ~= nil and builder.Health > 0) then --this version of the IF kills SUs that have been reduced to 0 Health or 0 DTK
				--SU is still alive, either DTK>0 or Health>0, so remove existing SU + add cloned/reduced SU to territory
				newSU = builder.Build (); --create newSU
				table.insert (SUsNewList, newSU);
				submit_SU_replacer_GUID_mapping (addNewOrder, SU.ID, newSU.ID); --if this mod is a Secondary mod, send the mapping to the MasterMod
				print ("[ATTACK PROCESSING - SU replacement] Old GUID " ..SU.ID.."/" ..SU.Name.. ", replace with New SU " ..newSU.ID.."/"..newSU.Name);
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
	local strOrderDescription = strAbilityDisplayName.. " SU damage";
	if (impactedTerritory == nil) then impactedTerritory = WL.TerritoryModification.Create (terr.ID); end
	-- print ("[BOMB TEST1] " .. tostring (#SUsNewList));
	-- print ("[BOMB TEST2] " .. tostring (#SUsToRemove));
	-- print ("[BOMB TEST3] " .. tostring (#SUsNewList) ..", " .. tostring (#SUsToRemove));
	if (#SUsNewList == 0 and #SUsToRemove == 0) then
		--no SUs to add or remove, just apply army damage --> for Bomb+ v3, this is handled in the main Bomb+ order, so no army damage is applied here (at least not right now)
		if (event == nil) then
			local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strAbilityDisplayName.. " (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
			event.Icon = strOrderIconFilename;
		end
		-- print ("[BOMB] SUBMIT EVENT");
		addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
	elseif (#SUsNewList == 0 and #SUsToRemove > 0) then --no SUs to add, only SUs to remove (killed by poison)
		impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
		if (event == nil) then
			local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strAbilityDisplayName.. " (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
			event.Icon = strOrderIconFilename;
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
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strAbilityDisplayName.. " (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strOrderIconFilename;
			end
			addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
			event = nil;
		end
	end
	-- local privateGameData = Mod.PrivateGameData;
	-- privateGameData.SUreplacementMapping = SUreplacementMapping;
	-- Mod.PrivateGameData = privateGameData;
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

--given WL.Armies structure 'armies', return nil if the target SU GUID does not exist in armies, or return the actual SU if it does exist within it
function getSpecialUnitWithinArmies (armies, strSUguid)
	if (armies == nil) then return nil; end
	if (#armies.SpecialUnits == 0) then return nil; end

	for _,specialUnit in pairs (armies.SpecialUnits) do
		if (specialUnit.ID == strSUguid) then return (specialUnit); end
	end
	return nil;
end