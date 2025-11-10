function Server_AdvanceTurn_Start (game, addOrder)
	--only need to do this in _Start on T1 b/c the SUs won't be present yet
	-- if (game.Game.TurnNumber == 1) then manage_CityFort_SUs (game, addOrder); end

	--actually maybe this is necessary each turn; b/c when cities are made via building cities/construction workers, etc, it's not possible to know when the orders to create the cities vs this routine will be executed (mod order is unknown)
	--this is necessary for cases where cities are acquired by means other than AttackTransfers (building cities, construction workers, etc) -- they'll be missed mid-turn but this will catch them at the end of the turn	
	manage_CityFort_SUs (game, addOrder);
end

function Server_AdvanceTurn_End (game, addOrder)
	manage_CityFort_SUs (game, addOrder); --this is necessary for cases where cities are acquired by means other than AttackTransfers (building cities, construction workers, etc) -- they'll be missed mid-turn but this will catch them at the end of the turn

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	local intHaltOnTurnNumber = 1;
	if (boolHaltCodeExecutionAtEndofTurn==true and game.Game.TurnNumber >= intHaltOnTurnNumber) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function manage_CityFort_SUs (game, addOrder)
	local modifiedTerritories = {};
	for ID,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if (terr.Structures and terr.Structures [WL.StructureType.City] and terr.Structures [WL.StructureType.City] > 0) then
			local oldSU = getSUonTerritory (terr, "CityFort");
			-- if (oldSU == nil or oldSU.Health ~= terr.Structures [WL.StructureType.City]) then
			if (oldSU == nil or oldSU.DamageToKill ~= terr.Structures [WL.StructureType.City]) then
			-- if (#terr.NumArmies.SpecialUnits == 0) then
				table.insert (modifiedTerritories, create_Monolithish_SU (game, 0, addOrder, ID, terr.Structures [WL.StructureType.City], (oldSU~=nil and oldSU.ID or nil)));
			end
		end
	end

	local event = WL.GameOrderEvent.Create (0, "CityForts", {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
	-- event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	-- event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	-- event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Monolith", 8, getColourInteger (0, 0, 255))}; --use Blue colour for Monolith
	addOrder (event);
end

function getSUonTerritory (territory, strSUname)
	for _,su in pairs (territory.NumArmies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == strSUname) then
			return (su);
		end
	end
	return (nil);
end

function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	--get values for Behemoth strength vs Neutrals & Invulnerability vs Neutrals; if not set, set to default values
	-- boolBehemothInvulnerableToNeutrals_default = true; --comment this out in Behemoth mod (it's set in behemoth.lua) but uncomment it in Airstrike mod
	-- intStrengthAgainstNeutrals_default = 2.0; --comment this out in Behemoth mod (it's set in behemoth.lua) but uncomment it in Airstrike mod
	-- local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;
	-- local boolBehemothInvulnerableToNeutrals = Mod.Settings.BehemothInvulnerableToNeutrals or boolBehemothInvulnerableToNeutrals_default;

	-- if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'Behemoth|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
	-- 	local orderComponents = split (order.Payload, '|');
	-- 	--reference: 	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothGoldSpent;
	-- 	local strOperation = orderComponents[2];
	-- 	local targetTerritoryID = tonumber (orderComponents[3]);
	-- 	local goldSpent = tonumber (orderComponents[4]);

	-- 	if (strOperation == "Purchase") then
	-- 		if (goldSpent > 0) then
	-- 			createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent);
	-- 		else
	-- 			skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
	-- 			addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Behemoth purchase failed --> invalid purchase price <=0 gold attempted! Shame on you, CHEATER DETECTED", {}, {}), false);
	-- 		end
	-- 	else
	-- 		print ("[BEHEMOTH] unsupported operation: " .. strOperation);
	-- 		return;
	-- 	end

	-- if (order.PlayerID < 100) then return; end --temporary measures for tesing, just process orders for players (not AIs)

	if (order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack == true) then
		--order is an attack (not a transfer)


		local terr = game.ServerGame.LatestTurnStanding.Territories [order.To];

		if (territoryHasActiveShield (terr) == true) then return; end --if target terr has active Shield SU, exit (shield protects the cities from damage)

		local intDamageAppliedToCities = math.max (0, math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5) - result.DefendingArmiesKilled.NumArmies); --factor in SUs here too; --how much damage to apply to cities on the target terr; this is the amount of damage left over from the AttackPower of the source terr after killing all the defending armies and SUs on the target terr
		local intCurrentCityCount = (terr.Structures and terr.Structures [WL.StructureType.City]) or 0;
		if (intCurrentCityCount <= 0) then return; end --if not cities on target terr, this mod has nothing to do, so just exit
		local intNewCityCount = math.max (0, intCurrentCityCount - intDamageAppliedToCities);
		local intAttackerDamageTakenFromCities = math.floor (intCurrentCityCount * game.Settings.DefenseKillRate + 0.5);
		-- result.AttackingArmiesKilled = WL.Armies.Create (result.AttackingArmiesKilled.NumArmies + intAttackerDamageTakenFromCities, result.AttackingArmiesKilled.SpecialUnits); --

		if (terr.Structures and terr.Structures[WL.StructureType.City] and terr.Structures[WL.StructureType.City] > 0) then intNumCities = terr.Structures[WL.StructureType.City]; end --get #cities on target terr
		print ("SOURCE " ..order.From.. "/" ..game.Map.Territories [order.From].Name.. ", attackPower " ..tostring (result.ActualArmies.AttackPower).. ", cityDamage " ..intDamageAppliedToCities.. ", TARGET " ..order.To.. "/" ..game.Map.Territories [order.To].Name.." , defensePower ..., #armies/[killed] " ..tostring (terr.NumArmies.NumArmies).. "/" ..tostring (result.DefendingArmiesKilled.NumArmies).. ", #SUs/[killed] " ..tostring (#terr.NumArmies.SpecialUnits).. "/" ..tostring (#result.DefendingArmiesKilled.SpecialUnits).. ", #cities " ..intNumCities.. ", newCityCount " ..intNewCityCount);

		--if cities have been damaged, update the city structures to reflect new city count
		if (intNewCityCount ~= intCurrentCityCount) then
			local structures = terr.Structures or {};
			structures [WL.StructureType.City] = intNewCityCount;


			-- local impactedTerritory = WL.TerritoryModification.Create (order.To);
			local oldSU = getSUonTerritory (terr, "CityFort");
			local impactedTerritory = (intNewCityCount >0 and create_Monolithish_SU (game, 0, addNewOrder, terr.ID, intNewCityCount, (oldSU~=nil and oldSU.ID or nil)) or WL.TerritoryModification.Create (order.To));
			impactedTerritory.SetStructuresOpt = structures;

			-- if (territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID]) == false) then impactedTerritory.AddArmies = -1 * Mod.Settings.TornadoStrength; end --reduce armies on territory iff not protected by Shield

			-- print (tostring (result.DefendingArmiesKilled.NumArmies >= terr.NumArmies.NumArmies), tostring (#result.DefendingArmiesKilled.SpecialUnits >= (#terr.NumArmies.SpecialUnits-1)));
			-- if (result.DefendingArmiesKilled.NumArmies >= terr.NumArmies.NumArmies and #result.DefendingArmiesKilled.SpecialUnits >= (#terr.NumArmies.SpecialUnits-1)) then --CityFort
			-- 	print ("ALL CITIES DESTROYED, remove CityFort");
			-- 	--all defending armies & SUs killed, so remove any CityFort special unit on the territory
			-- 	local newSpecialUnits = result.DefendingArmiesKilled.SpecialUnits;
			-- 	for _,su in pairs (terr.NumArmies.SpecialUnits) do
			-- 		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'CityFort') then
			-- 			table.insert (newSpecialUnits, su);
			-- 			result.DefendingArmiesKilled = WL.Armies.Create (result.DefendingArmiesKilled.NumArmies, newSpecialUnits);
			-- 		end
			-- 	end
			-- end

			local event = WL.GameOrderEvent.Create (order.PlayerID, math.min (intCurrentCityCount, intDamageAppliedToCities).. " cities destroyed", {}, {impactedTerritory});
			-- event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			-- event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Tornado", 8, getColourInteger (255, 0, 0))}; --use Red colour for Tornado
			--addAirLiftCardEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[airliftCardID] = game.Settings.Cards[airliftCardID].NumPieces}}; --add enough pieces to equal 1 whole card
			addNewOrder (event, true);
		end
	end
end

function create_Monolithish_SU (game, castingPlayerID, addOrder, targetTerritoryID, intSUhealth, oldSU)
		-- create territory object, assign special unit to it, add an order associated with the territory
		local impactedTerritoryOwnerID = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
		local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder

		-- create special unit for Isolation operations, place the special on the territory so it is visibly identifiable as being impacted by Isolation; destroy the unit when Isolation ends
		local builder = WL.CustomSpecialUnitBuilder.Create (WL.PlayerID.Neutral);  --assign unit to owner of the territory (not the caster of the Monolith action)
		builder.Name = 'CityFort';
		builder.IncludeABeforeName = false;
		-- builder.ImageFilename = 'empty_pic.png'; --max size of 60x100 pixels
		-- builder.ImageFilename = 'CityFort.png'; --max size of 60x100 pixels		
		-- builder.ImageFilename = 'CityFort_redBack.png'; --max size of 60x100 pixels		
		builder.ImageFilename = 'CityFort_redBack_v3.png'; --max size of 60x100 pixels		
		builder.AttackPower = 0;
		builder.AttackPowerPercentage = 0;
		builder.DefensePower = intSUhealth;
		--builder.DefensePowerPercentage = 0;
		builder.DamageToKill = intSUhealth;
		-- builder.DamageAbsorbedWhenAttacked = 9999999;
		-- builder.Health = intSUhealth;
		builder.CombatOrder = 99990; --doesn't protect Commander which is 10000; slightly less than Monolith which is 99999, so this still dies, cities can still be destroyed but the territory can't be captured (b/c of the Monolith -- no special action taken here)
		--builder.CanBeGiftedWithGiftCard = false;
		builder.CanBeGiftedWithGiftCard = false;
		builder.CanBeTransferredToTeammate = false;
		builder.CanBeAirliftedToSelf = false;
		builder.CanBeAirliftedToTeammate = false;
		builder.IsVisibleToAllPlayers = false;
		--builder.TextOverHeadOpt = "Monolith"; --don't need writing; the graphic is sufficient
		--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.MonolithDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.MonolithDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
		local strUnitDescription = tostring ("CityFort");
		builder.ModData = strUnitDescription;
		local specialUnit_Monolith = builder.Build (); --save this in a table somewhere to destroy later
		impactedTerritory.AddSpecialUnits = {specialUnit_Monolith}; --add special unit
		if (oldSU ~= nil) then impactedTerritory.RemoveSpecialUnitsOpt = {oldSU}; end --remove the prev FortCity SU from the territory if one exists
		return (impactedTerritory);

		-- local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Monolith action
		-- local event = WL.GameOrderEvent.Create(castingPlayerID, "CityForts", {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
		-- event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
		-- event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
		-- event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Monolith", 8, getColourInteger (0, 0, 255))}; --use Blue colour for Monolith

		-- addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function; this actually adds the game order that changes territory to neutral & adds the special unit
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

function reference ()
	if (true) then --
		local strSUtype = "Behemoth";
		for _,specialUnit in pairs (order.NumArmies.SpecialUnits) do
			--if SU name is 'Behemoth' or starts with 'Behemoth' (currently Behemoth names have power level appended to their names)
			if (specialUnit.proxyType == 'CustomSpecialUnit' and (specialUnit.Name == strSUtype or string.sub (specialUnit.Name, 1, string.len (strSUtype)) == strSUtype)) then
				--unit is a Behemoth, so if Mod.Settings.BehemothInvulnerableToNeutrals is set, ensure it neither dies nor takes any damage from the neutral
				if (boolBehemothInvulnerableToNeutrals == true) then
					--check if the Behemoth is slated to be killed & if so, remove it from the table result.AttackingArmiesKilled.SpecialUnits[specialunit]
					--result.AttackingArmiesKilled.SpecialUnits is an array of special unit objects, where one property is ID; write code to check the array to see if the ID property of an element == specialUnit.ID, and if so, remove it from the array
					local newAttackingArmiesKilled_SpecialUnits = result.AttackingArmiesKilled.SpecialUnits;
					for key = #newAttackingArmiesKilled_SpecialUnits, 1, -1 do
						if (newAttackingArmiesKilled_SpecialUnits[key].ID == specialUnit.ID) then
							table.remove (newAttackingArmiesKilled_SpecialUnits, key);
							-- print ("[BEHEMOTH] Killed attacking neutral -> nullify the kill; Name: ".. specialUnit.Name)
						end
					end
					result.AttackingArmiesKilled = WL.Armies.Create (result.AttackingArmiesKilled.NumArmies, newAttackingArmiesKilled_SpecialUnits);

					local newDamageToSpecialUnits = {}; --start with empty table, add the items to keep back into the table then reassign to result.DamageToSpecialUnits (this is the only way it works)
					--result.DamageToSpecialUnits is a table with key of the ID of a special unit; write code to check each element of the table to see if the ID matches specialUnit.ID and if so remove it from the table
					--check if the Behemoth is slated to take damage, and if so remove it from the table result.DamageToSpecialUnits[guid]
					for key, intDamage in pairs(result.DamageToSpecialUnits) do
						if (key == specialUnit.ID) then
							-- print ("[BEHEMOTH] Damaged while attacking neutral -> nullify the damage; Damage ".. tostring (intDamage).. ", Name: ".. specialUnit.Name);
						else
							newDamageToSpecialUnits[key] = result.DamageToSpecialUnits[key];
						end
					end
					result.DamageToSpecialUnits = newDamageToSpecialUnits;
				end

				local armiesBehemoth = WL.Armies.Create (0, {specialUnit}); --put Behemoth in armies object to get attack power & properly apply neutral damage factor intStrengthAgainstNeutrals

				--calc gap between damage inclusive of intStrengthAgainstNeutrals and the damage already included in the result w/o respect to intStrengthAgainstNeutrals, then add it to result.DefendingArmiesKilled
				--if ==1.0 -> no change in damage done to the neutrals; >1.0 -> increases damage done; <1.0 -> decreases damage done
				-- local intFullAttackPower = result.ActualArmies.AttackPower;
				local intFullSUdamage = math.floor (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate + 0.5); --full SU damage pre-modifier (which can increase or decrease the damage done to neutrals)
				local intNewSUdamage = math.floor (intFullSUdamage * intStrengthAgainstNeutrals + 0.5); --new damage done inclusive of the modifier
				local intOldTotalDamage = result.DefendingArmiesKilled.NumArmies; --the original damage done, which can be < damage done by SU if #defending armies < damage done by SU
				local intDamageGap = intNewSUdamage - intFullSUdamage; --the gap between current result.DefendingArmiesKilled.NumArmies and the new damage done by the SU with the modifier applied
				local intFullAttackDamage = math.floor (order.NumArmies.AttackPower * game.Settings.OffenseKillRate + 0.5); --this is the total damage done by all attacking armies, including the SU; this is used to identify if the SU is the only attacker or if there are other SUs/armies involved (calc 2 below requires this knowledge)

				-- assign new damage; if intStrengthAgainstNeutrals_default == 1.0, the value stays the same (no change); if >1.0, it increases (this is easy)
				-- but if <1.0 then it's tricky b/c result.DefendingArmiesKilled.NumArmies is received as min (damage done, actual # of defending armies) so can't just subtract full total damge of the SU and add the new damage, b/c it's possible for (full total damage) > (# defending armies) which makes subtracting full damage negative
				-- so in this case, if #defending amies < new SU damage (post modifier), then new result damage = # armies; if #defending armies >= new SU damage (post modifier) then new result damage = new SU damage (post modifier)
				local intNewTotalDamage = intOldTotalDamage; -- this covers case when intStrengthAgainstNeutrals_default == 1.0
				if (intStrengthAgainstNeutrals_default > 1.0) then
					--when >1.0, just add the additional damage to the total damage done -- no problems here, nothing to worry about
					intNewTotalDamage = intOldTotalDamage + intDamageGap;
				elseif (intStrengthAgainstNeutrals_default < 1.0) then
					--when <1.0, need to ensure we don't reduce the damage being done beyond what is the scope of the damage done by this particular SU
					--this depends on whether the damage done is more or less than each of the SU damage post modifier & SU damage pre-modifier
					if (intOldTotalDamage <= intNewSUdamage) then
						--the current damage done is < the damage done by the SU post modifier (reduced), so just leave the damage as its current value (don't decrease it b/c it may go below 0)
						--assumption is that the full pre-modifier (reduced) damage done contributed by this SU was sufficient to wipe all defending armies, and so is the post modifier (reduced) damage value
						intNewTotalDamage = intOldTotalDamage;
						-- print ("calc 1; DAM oldTot "..intOldTotalDamage.. ", newTot ".. intNewTotalDamage..", fullSU ".. intFullSUdamage.. ", newSU ".. intNewSUdamage);
					elseif (intOldTotalDamage > intNewSUdamage and intOldTotalDamage < intFullSUdamage) then
						--if SU is the only attacker (no other SUs, no armies) then reduce damage accordingly; but if ther are other SUs or armies, leave damage done at minimum of intOldTotalDamage in order to not risk reducing the damage done even though the other units are sufficient to do that damage even with the contribution from this SU
						if (intFullAttackDamage == intFullSUdamage) then --SU is the only attacker (or at least the only attacker contributing to damage), so reduce damage accordingly based solely on SU damage
							--damage done is > new SU damage post modifier (reduced) but < full SU damage pre-modifier, so just set it to intNewSUdamage
							intNewTotalDamage = intNewSUdamage;
							-- print ("calc 2A; DAM oldTot "..intOldTotalDamage.. ", newTot ".. intNewTotalDamage..", fullSU ".. intFullSUdamage.. ", newSU ".. intNewSUdamage);
						else --SU is not the only attacker, so just set it to intOldTotalDamage to avoid reducing it below the amount of damage done by the other SUs/armies
							--just keep the old damage to avoid reducing it below the amount of damage done by the other SUs/armies; b/c the intOldTotalDamage maxes out @ quantity of armies on target territory, in order to calculate this properly, would have to go through a full manual attack processing to see if the damage contributed from this SU is included in intOldTotalDamage
							--so just use intOldTotalDamage as a reasonable estimate of reducing the impact of the SU damage on the neutrals; it'll be slightly inaccurate in just this 2B case
							intNewTotalDamage = intOldTotalDamage;
							-- print ("calc 2B; DAM oldTot "..intOldTotalDamage.. ", newTot ".. intNewTotalDamage..", fullSU ".. intFullSUdamage.. ", newSU ".. intNewSUdamage);
						end
						-- print ("calc 2; DAM oldTot "..intOldTotalDamage.. ", newTot ".. intNewTotalDamage..", fullSU ".. intFullSUdamage.. ", newSU ".. intNewSUdamage);
					else
						--damage done is > new SU damage post modifier (reduced) and > full SU damage pre-modifier, so now subtract intFullSUdamage, add intNewSUdamage
						intNewTotalDamage = intOldTotalDamage + intDamageGap;
						-- print ("calc 3; DAM oldTot "..intOldTotalDamage.. ", newTot ".. intNewTotalDamage..", fullSU ".. intFullSUdamage.. ", newSU ".. intNewSUdamage);
					end
				end

				--this works for intStrengthAgainstNeutrals_default >=1.0 but not intStrengthAgainstNeutrals_default <1.0 b/c can't figure out how much of the damage done by the Behemoth is already included in intOldTotalDamage
				--sometimes #territories is < total damage capable to do, thus intOldTotalDamage < total damage capable to do, thus can't just subtract total capable to do and add the gap between that and the real amount -- this may make damage go negative

				result.DefendingArmiesKilled = WL.Armies.Create (math.floor (intNewTotalDamage + 0.5), result.DefendingArmiesKilled.SpecialUnits);
				-- print ("[BEHEMOTH] Attacking neutral -> apply damage factor " .. intStrengthAgainstNeutrals_default .. "x, orig dmg ".. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate).. ", new damage " .. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate * intStrengthAgainstNeutrals_default) ..", apply gap " .. intDamageGap.. ", old total damage "..intOldTotalDamage.. ", new total damage ".. intNewTotalDamage);
			end
		end
	end
end

function countSUinstances (armies)
	local ret = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'Tank') then
			ret = ret + 1;
		end
	end
	return ret;
end

function split(inputstr, sep)
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