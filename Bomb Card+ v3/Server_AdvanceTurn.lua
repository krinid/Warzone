require ("SU_replacer common");
local strBombOrderFilename = "Bomb card+ v3 40x40"; --icon for the Explosives order in the order list

function Server_AdvanceTurn_Start (game, addNewOrder)
	local pgd = Mod.PrivateGameData or {};
	pgd.SUreplacementMapping = nil;
	pgd.SUreplacementMapping_Reverse = nil;
	Mod.PrivateGameData = pgd;

	decide_SU_replacer_MasterMod (addNewOrder);
end

function Server_AdvanceTurn_End (game, addNewOrder)
	--intentional crash
	-- crash_me_now ();
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	if ((order.proxyType == 'GameOrderPlayCardCustom' and startsWith (order.ModData, "Bomb+|") == true)) then
		PlayBombCard (game, order, addNewOrder);
	end

	process_SU_replacer_MasterMod_orders (game, order, skipThisOrder, addNewOrder);
end

function PlayBombCard (game, order, addNewOrder)
	local modDataContent = split (order.ModData, "|");
	local intTargetTerritoryID = modDataContent[2]; --2nd component of ModData is the source territory ID
	local strFortStructureID = territoryHasFort (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local boolTerritoryHasShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories [intTargetTerritoryID]);
	local terrMod = WL.TerritoryModification.Create (intTargetTerritoryID);
	local armies;
	local strBombMsg = getPlayerName (game, order.PlayerID).. " bombs " ..game.Map.Territories [intTargetTerritoryID].Name;
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
	event.TerritoryAnnotationsOpt = {[intTargetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb+", 8, 0)}; --mimic the base "Bomb" annotation
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, intTargetTerritoryID); --move the camera to the target territory
	event.Icon = strBombOrderFilename;

	applySpecialUnitDamage (game, addNewOrder, event, terr, terrMod, order.PlayerID, terr.OwnerPlayerID, -Mod.Settings.SUdamagePercent/100, -Mod.Settings.SUdamageFixed, false, "Bomb+", strBombOrderFilename); --3rd last param 'false' indicates to not apply to all stats, only reduce Health/DTK

	--2nd param indicates whether to skip this order if the original order is skipped (by this or any other mod)
	--if using regular bomb card, original order will be skipped (elsewhere in code) so it doesn't apply default damage of 50%, so must use 'false' when calling addNewOrder
	--but if using the new custom Bomb+ card, use 'true' here so it is correctly tied to orig order and if that is skipped (via Card Block, etc), then this order is also skipped
	-- addNewOrder (event, true);
	if (eventDestroyFort ~= nil) then addNewOrder (eventDestroyFort, true); end -- if an event to destroy a Fort was created, add it here after the "Bomb+" order
end

--reduce SU Health/DTK on taget territory owned by targetPlayerID by % specified by numSUreductionRate (-0.1 = 10% reduction)
function applySpecialUnitDamage_OLD (game, addNewOrder, event, terr, impactedTerritory, castingPlayerID, targetPlayerID, numSUreductionRate, numSUdamageFixed, boolSUpunishment_ApplyToAllStats)
	-- if (#terr.NumArmies.SpecialUnits > 0) then
		local targetTerritoryID = terr.ID;
		local SUreplacementMapping = Mod.PrivateGameData.SUreplacementMapping or {}; --initialize to {} is not set yet

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
		local strOrderDescription = "Bomb+ SU damage";
		if (impactedTerritory == nil) then impactedTerritory = WL.TerritoryModification.Create (terr.ID); end
		-- print ("[BOMB TEST1] " .. tostring (#SUsNewList));
		-- print ("[BOMB TEST2] " .. tostring (#SUsToRemove));
		-- print ("[BOMB TEST3] " .. tostring (#SUsNewList) ..", " .. tostring (#SUsToRemove));
		if (#SUsNewList == 0 and #SUsToRemove == 0) then
			--no SUs to add or remove, just apply army damage --> for Bomb+ v3, this is handled in the main Bomb+ order, so no army damage is applied here (at least not right now)
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb+ (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
				event.Icon = strBombOrderFilename;
			end
			-- print ("[BOMB] SUBMIT EVENT");
			addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
		elseif (#SUsNewList == 0 and #SUsToRemove > 0) then --no SUs to add, only SUs to remove (killed by poison)
			impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
			if (event == nil) then
				local event = WL.GameOrderEvent.Create (castingPlayerID, strOrderDescription, {}, {impactedTerritory});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb+ (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
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
					event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Bomb+ (SU)", 4, 0)}; --mimic the base "Bomb" annotation)};
					event.Icon = strBombOrderFilename;
				end
				addNewOrder (event, false); --needs 'false' b/c this is triggered by a GameOrderEvent that is skipped <---- is it?
				event = nil;
			end
		end
	-- end
	local privateGameData = Mod.PrivateGameData;
	privateGameData.SUreplacementMapping = SUreplacementMapping;
	Mod.PrivateGameData = privateGameData;
end