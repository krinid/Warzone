--This code is used to process a manual attack when the built-in WZ attack mechanics can't be leveraged for the desired result
--3 use cases at this point are:
--          1) Limited Multimove - the transfers involved caused the WZ engine to leave units behind and not process attacks properly
--          2) Airstrike Card - this causes attacks on non-adjacent territories, which the WZ engine can't process
--          3) Warp Travel Card - this causes attacks on non-adjacent territories that don't happen in real-time & have repeated attacks until 1 side dies (instead of just 1 single attack), which the WZ engine can't process
--
-- still TODOs:
--      - incorporate luck (if used - there is a properties DefenseLuck & OffenseLuck in GameOrderResult
--      - ? anything else ?


--process a manual attack sequence from AttackOrder [type NumArmies] on DefendingTerritory [type Territory] with respect to Specials & armies
--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
--also treat Specials properly with respect to their specs, notably damage required to kill, health, attack/damage power & modifier properties, damage absorption, etc
--boolStandardAttackOrder
--     - [Limited Multimove] true indicates whether this is a standard WZ attack order and we're manipulating 'result' to let WZ handle the result of the battle
--     - [Airstrike]         false indicates that this isn't being done with an attack order, usually b/c the FROM and TO territories are not adjacent and the standard WZ engine can't process these attacks; in this case the result is handled by this code, either FROM/TO directly modified + optional airlift to visibly move units when attack is successful
--return value is the result with updated AttackingArmiesKilled, DefendingArmiesKilled values & a true/false AttackIsSuccessful indicator
function process_manual_attack (game, AttackingArmies, DefendingTerritory, result)
	--note armies have combat order of 0, Commanders 10,000, need to get the combat order of Specials from their properties
	local DefendingArmies = DefendingTerritory.NumArmies;

	local sortedAttackerSpecialUnits = {};
	local sortedDefenderSpecialUnits = {};
	local totalDefenderDefensePowerPercentage = 1.0;    --this is covered in defense power for an SU so don't actually need this
	--local totalAttackerDefensePowerPercentage = 1.0;  --this is covered in defense power for an SU so don't need this
	local totalAttackerAttackPowerPercentage = 1.0;     --this is covered in defense power for an SU so don't actually need this
	--local totalDefenderAttackPowerPercentage = 1.0;   --this is covered in attack power for an SU so don't actually need this

	printDebug ("[MANUAL ATTACK!] ATTACKER: #armies "..AttackingArmies.NumArmies..", #SUs "..#AttackingArmies.SpecialUnits..", AttackingArmiesPower "..AttackingArmies.AttackPower..
		"\nDEFENDER: #armies "..DefendingTerritory.NumArmies.NumArmies..", #SUs "..#DefendingTerritory.NumArmies.SpecialUnits..", DefendingTerritoryPower "..DefendingTerritory.NumArmies.DefensePower);

	--this doesn't work; the AttackingArmies.SpecialUnits table is likely not totally compliant; it needs to be a sequential array table, not a key-value table
	--table.sort(sortedAttackingArmies.SpecialUnits, function(a, b) printDebug ("COMPARE "..a.CombatOrder..", ".. b.CombatOrder..", "..tostring(a.CombatOrder < b.CombatOrder)); return (a.CombatOrder < b.CombatOrder); end);

	--instead, rebuild AttackingArmies.SpecialUnits into a new sequential array & sort this new table by ascending CombatOrder and process that instead
	for _, unit in pairs(AttackingArmies.SpecialUnits) do
		table.insert(sortedAttackerSpecialUnits, unit);
		-- if (unit.proxyType == "CustomSpecialUnit") then
			--if (unit.AttackPowerPercentage ~= nil) then totalAttackerAttackPowerPercentage = totalAttackerAttackPowerPercentage * unit.AttackPowerPercentage; end
			--if (unit.DefensePowerPercentage ~= nil) then totalAttackerDefensePowerPercentage = totalAttackerDefensePowerPercentage * unit.DefensePowerPercentage; end
			--do some math here; remember <0.0 is not possible, 0.0-1.0 is actually -100%-0%, 1.0-2.0 is 0%-100%, etc
				--printDebug ("SPECIAL ATTACKER "..unit.Name..", APower% "..unit.AttackPowerPercentage..", DPower% "..unit.DefensePowerPercentage..", DmgAbsorb "..unit.DamageAbsorbedWhenAttacked..", DmgToKill "..unit.DamageToKill..", Health "..unit.Health);
		-- end
	end
	table.sort(sortedAttackerSpecialUnits, function(a, b) return a.CombatOrder < b.CombatOrder; end)

	--instead, rebuild DefendingArmies.SpecialUnits into a new sequential array & sort this new table by ascending CombatOrder and process that instead
	for _, unit in pairs(DefendingArmies.SpecialUnits) do
		table.insert(sortedDefenderSpecialUnits, unit);
		-- if (unit.proxyType == "CustomSpecialUnit") then
			--if (unit.AttackPowerPercentage ~= nil) then printDebug ("APP "..unit.Name,totalDefenderAttackPowerPercentage,unit.AttackPowerPercentage); totalDefenderAttackPowerPercentage = totalDefenderAttackPowerPercentage * unit.AttackPowerPercentage; end
			--if (unit.DefensePowerPercentage ~= nil) then printDebug ("DPP "..unit.Name,totalDefenderDefensePowerPercentage,unit.DefensePowerPercentage); totalDefenderDefensePowerPercentage = totalDefenderDefensePowerPercentage * unit.DefensePowerPercentage; end
			--do some math here; remember <0.0 is not possible, 0.0-1.0 is actually -100%-0%, 1.0-2.0 is 0%-100%, etc
			--printDebug ("SPECIAL DEFENDER "..unit.Name..", APower% "..unit.AttackPowerPercentage..", DPower% "..unit.DefensePowerPercentage..", DmgAbsorb "..unit.DamageAbsorbedWhenAttacked..", DmgToKill "..unit.DamageToKill..", Health "..unit.Health);
		-- end
	end
	table.sort(sortedDefenderSpecialUnits, function(a, b) return a.CombatOrder < b.CombatOrder; end)

	local AttackPower = AttackingArmies.AttackPower;
	printDebug ("=========================="..AttackingArmies.AttackPower);
	local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	local AttackDamage = math.floor (AttackPower * game.Settings.OffenseKillRate * totalAttackerAttackPowerPercentage + 0.5);
	local DefenseDamage = math.floor (DefensePower * game.Settings.DefenseKillRate * totalDefenderDefensePowerPercentage + 0.5);
	--local remainingAttackDamage = AttackDamage; --apply attack damage to defending units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied
	--local remainingDefenseDamage = DefenseDamage; --apply defense damage to attacking units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied

	--aply damage to Specials & armies of each Defender & Attacker; 

	--process Defender damage 1st; if both players are eliminated by this order & they are the last 2 active players in the game, then Defender is eliminated 1st, Attacker wins
	-- print ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	printDebug ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	local defenderResult = apply_damage_to_specials_and_armies (sortedDefenderSpecialUnits, DefendingArmies.NumArmies, AttackDamage, boolStandardAttackOrder);
	-- print ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	printDebug ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	local attackerResult = apply_damage_to_specials_and_armies (sortedAttackerSpecialUnits, AttackingArmies.NumArmies, DefenseDamage, boolStandardAttackOrder);
	local boolAttackSuccessful = false; --indicates whether attacker is successful and should move units to target territory and take ownership of it
	-- print ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned]");
	printDebug ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned]");
	-- print ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned]");
	printDebug ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned]");
	if (defenderResult.RemainingArmies == 0 and #defenderResult.SurvivingSpecials == 0) then
		--defender is eliminated, attacker wins
		boolAttackSuccessful = true;
		printDebug ("[ATTACK SUCCESSFUL] attacker wins, defender is wiped out from target territory");
	else
		--defender survives, attacker may have lost some units
		printDebug ("[ATTACK UNSUCCESSFUL] attacker unsuccessful, defender survives in target territory");
	end
	return ({AttackerResult=attackerResult, DefenderResult=defenderResult, IsSuccessful=boolAttackSuccessful});
end

--process damage quantity 'totalDamage' to the Specials in table 'sortedSpecialUnits' and the armies in 'armyCount'
--Specials are already stored in table in order of their CombatOrder
--the combo of (sortedSpecialUnits+armyCount) is either the Attacker and totalDamage is damage from defender units, or the combo is the Defender and totalDamage is damage from attacker units
--this function will be called once for each case, once for the Attacker and once for the Defender
--boolStandardAttackOrder of true - return 
function apply_damage_to_specials_and_armies (sortedSpecialUnits, armyCount, totalDamage)
	local remainingDamage = totalDamage;
	local boolArmiesProcessed = false;
	local remainingArmies = armyCount;
	local survivingSpecials = {};
	local killedSpecials = {};
	local clonedSpecials = {};
    local damageToSpecialUnits = {};

	table.insert (sortedSpecialUnits, {CombatOrder=1, proxyType="|dummyPlaceholder|applyDamageToArmies"}); --add a dummy element to the end of the table to ensure armies are processed if they haven't been processed so far (if all specials have CombatOrder<0)

	--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
	printDebug ("_____________________APPLY DAMAGE "..totalDamage..", #armies "..armyCount..", #specials "..#sortedSpecialUnits);
	for k,v in ipairs (sortedSpecialUnits) do
		local newSpecialUnit_clone = nil;
        local intDamageAppliedToCurrentSU = 0;
		--Properties Exist for Commander: ID, guid, proxyType, CombatOrder <--- and that's it!
		--Properties DNE for Commander: AttackPower, AttackPowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, DefensePower, DefensePowerPercentage, Health
		printDebug ("[[[[SPECIAL]]]] "..k..", type "..v.proxyType.. ", combat order "..v.CombatOrder..", remaining damage "..remainingDamage);
		local boolCurrentSpecialSurvives = true;

		if (v.proxyType == "CustomSpecialUnit") then
			printDebug ("CUSTOM SPECIAL name '"..v.Name.."', ModID "..v.ModID..", combat order "..v.CombatOrder..", health "..tostring(v.Health)..", attack "..tostring(v.AttackPower)..", damage "..tostring(v.DefensePower)..", SPECIAL APower% "..tostring(v.AttackPowerPercentage)..
			", DPower% "..tostring(v.DefensePowerPercentage)..", SPECIAL DmgAbsorb "..tostring(v.DamageAbsorbedWhenAttacked)..", DmgToKill "..tostring(v.DamageToKill)..", Health "..tostring(v.Health)..", remaining damage "..remainingDamage);
		elseif (v.proxyType == "|dummyPlaceholder|applyDamageToArmies") then
			printDebug ("DUMMY PLACEHOLDER for armies, remaining damage "..remainingDamage..", armies damage processed already? "..tostring(boolArmiesProcessed));
			boolCurrentSpecialSurvives = false; --don't add this to the survivingSpecials table
			--don't do anything other than let the loop continue 1 last iteration to apply damage to the armies
			--this item has CombatOrder==0 but it is placed last into the table just to ensure that at least 1 element has >0 CombatOrder so that the loop will process damage on the armies if there is remainingDamage left
		end

		--if there's no more damage to apply, skip the code to apply any further damage; could also use 'break' to exit the loop		
		--first check if CombatOrder indicates that it's time to apply damage to armies, then apply damage to Specials thereafter if damage is remaining
		--1 iteration through loop can apply damage to both armies and then 1 Special (the current Special being iterated on in the loop representing the current element of the table being looped through)
		if (remainingDamage >0) then
			if (boolArmiesProcessed==false and v.CombatOrder >0) then --if armies haven't had damage applied yet and this Special has combat order of >0 then apply damage to armies
				--apply damage to armies
				if (remainingArmies == 0) then
					printDebug ("[[[[ARMY DAMAGE]]]] no remaining armies present, remaining damage "..remainingDamage);
				elseif (remainingDamage >= remainingArmies) then
					remainingDamage = math.max (0, remainingDamage - remainingArmies);
					remainingArmies = 0;
					printDebug ("[[[[ARMY DAMAGE]]]] all armies die, remaining damage "..remainingDamage);
				else
					--apply damage to armies of amount remainingDamage
					printDebug ("[[[[ARMY DAMAGE]]]] "..remainingDamage.." armies die, remaining armies "..remainingArmies-remainingDamage..", remaining damage 0");
					remainingArmies = math.max (0, remainingArmies - remainingDamage);
					remainingDamage = 0;
				end
				boolArmiesProcessed = true;
			end

			--damage to armies may have occurred already depending on CombatOrder value of current special, and this may have depleted all remaining damage
			--if there's still damage to apply, apply it to this Special
			if (remainingDamage > 0) then
				printDebug ("apply damage to Special");
				if (v.proxyType=="Commander") then
					if (remainingDamage >=7) then
						printDebug ("COMMANDER dies");
						remainingDamage = math.max (0, remainingDamage - 7);
						boolCurrentSpecialSurvives = false; --remove commander (don't stop processing; it might not be this player's commander, game needs to continue to cover all cases)
						--&&& add code here to:
						--    (A) check if Resurrection cards are in play and if owner of Commander has a whole card in hand
						--    (B) if Res cards aren't in play, manually eliminate the player
						--    (C) if Res cards are in play but Commander owner doesn't have a Res card, eliminate the player
						--    (D) if Res cards are in play and Commander owner has a Res card, remove the Commander, submit CustomGameOrder directed @ Resurrection mod indicating that Commander has died and should be Resurrected
						--reference: 	addNewOrder(WL.GameOrderEvent.Create(winnerId, 'Decided random winner', {}, eliminate(votes.players, game.ServerGame.LatestTurnStanding.Territories, true, game.Settings.SinglePlayer)));
					else
						printDebug ("COMMANDER survives, not enough damage done");
						remainingDamage = 0; --commander survives, no more attacks to occur
						boolCurrentSpecialSurvives = true; --add commander to survivingSpecials table
					end
				elseif (v.proxyType=="CustomSpecialUnit") then
					--absorb damage only applies to SUs that don't use Health; if they use Health, DamageAbsorbedWhenAttacked is ignored during regular WZ attacks; mimic that functionality here (even if both DamageAbsorbedWhenAttacked & Health are specified on an SU)
					--SUs use either (A) Health or (B) DamageToKill + DamageAbsorbedWhenAttacked; if Health is specified, the other 2 properties are ignored
					if (v.DamageAbsorbedWhenAttacked ~= nil and v.Health == nil) then remainingDamage = math.max (0, remainingDamage - v.DamageAbsorbedWhenAttacked); printDebug ("absorb damage "..v.DamageAbsorbedWhenAttacked..", remaining dmg "..remainingDamage); end
					if (v.Health ~= nil) then --SU uses Health (not DamageToKill + DamageAbsorbedWhenAttacked)
						if (v.Health == 0) then
							printDebug ("SPECIAL already dead w/0 health, kill it/remove it");
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table & add to killedSpecials table
						elseif (remainingDamage >= v.Health) then
							remainingDamage = remainingDamage - v.Health;
							printDebug ("SPECIAL dies, health "..v.Health.. ", remaining damage "..remainingDamage);
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table & add to killedSpecials table
						else
                            --apply damage to special of amount remainingDamage
                            --2 cases need to be handled here, as follows; provide information to handle both, and let the calling function handle the resulting actions appropriately
                            --     (case 1) [Limited Multimove] using standard WZ attack order - track damage to SUs and return in a table to be applied via the attack order
                            --     (case 2) [Airstrike] using totally manual attack order - must clone damaged SUs with the new remaining health and store the SUs in a table
							printDebug ("SPECIAL survives but health reduced by "..remainingDamage.." to "..v.Health-remainingDamage .. "[clone/remove old/add new]");
							--(case 1) track damage done to SU
                            intDamageAppliedToCurrentSU = v.Health-remainingDamage;
                            damageToSpecialUnits [v.ID] = v.Health-remainingDamage;
                            --reference: ---@field DamageToSpecialUnits table<GUID, integer> # The damage done to special units, only when they are not killed

							--(case 2) recreate the special with new health level
							local newSpecialUnitBuilder = WL.CustomSpecialUnitBuilder.CreateCopy(v);
							newSpecialUnitBuilder.Health = v.Health - remainingDamage;
							newSpecialUnitBuilder.Name = newSpecialUnitBuilder.Name .."(C)";
							newSpecialUnit_clone = newSpecialUnitBuilder.Build();
							boolCurrentSpecialSurvives = true; --add cloned special to survivingSpecials table
							remainingDamage = 0;
						end
					else   --SU uses DamageToKill + DamageAbsorbedWhenAttacked (not Health)
						if (remainingDamage > v.DamageToKill) then
							remainingDamage = math.max (0, remainingDamage - v.DamageToKill);
							printDebug ("SPECIAL dies, damage to kill "..v.DamageToKill..", remaining damage "..remainingDamage);
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table
							--printDebug ("boolCurrentSpecialSurvives "..tostring(boolCurrentSpecialSurvives));
						else
							--apply damage to special of amount remainingDamage
							printDebug ("SPECIAL survives b/c remaining damage "..remainingDamage.." < DamageToKill "..v.DamageToKill.."; remaining damage 0");
							boolCurrentSpecialSurvives = true; --add special to survivingSpecials table
							remainingDamage = 0;
						end
					end
				end
			end
		end
		if (remainingDamage<=0) then printDebug ("[damage remaining is "..remainingDamage.."]"); end

		--the Special being analyzed this iteration through loop has already DIED or SURVIVED by this opint, add to survivingSpecials table if it survived
		--printDebug ("boolCurrentSpecialSurvives "..tostring(boolCurrentSpecialSurvives));
		if (boolCurrentSpecialSurvives == true) then --the Special survived; but it may have (A) taken no damage, in which case just add it to the survivingSpecials table, or (B) taken damage (if so it has been cloned and need to replace it with the new cloned Special and add that to the table)
			printDebug ("SPECIAL survived");
			if (newSpecialUnit_clone == nil) then --the Special Unit survived the didn't need to be cloned, just add the original to the survivingSpecials table
				table.insert (survivingSpecials, v);
			else   --the Special Unit survived but needed to be cloned, add the new cloned Special to the survivingSpecials table & add the original to the killedSpecials table (this isn't totally accurate since it wasn't killed per se, 
			       --but this mechanism is used to remove it from the source territory & not add it to the target territory if the attack if successful)
				table.insert (survivingSpecials, newSpecialUnit_clone); --add the new cloned Special to the survivingSpecials table; SUs in this table will be added to the target territory if attack is successful
				table.insert (killedSpecials, v.ID); --add the original Special to the killedSpecials table
				table.insert (clonedSpecials, newSpecialUnit_clone); --add the new cloned Special to the clonedSpecials table; if attack is unsuccessful, attacking SUs in this table need to be added to the source territory & defending SUs in this table need to be added to the target territory
				--newSpecialUnit_clone = nil; --reset the clone to nil for next iteration through the loop --> actually don't need to b/c moved the declaration inside the loop
			end
		else
			printDebug ("SPECIAL died");
			if (v.proxyType ~= "|dummyPlaceholder|applyDamageToArmies") then table.insert (killedSpecials, v.ID); end --only add the Special to the killedSpecials table if it dies, ignore the dummy placeholder
		end
	end

	printDebug ("[FINAL RESULT] remaining damage "..remainingDamage..", killed armies " .. math.max (0, armyCount-remainingArmies) ..", remaining armies "..remainingArmies.. ", #killedSpecials ".. #killedSpecials ..", #survivingSpecials "..#survivingSpecials);
	local damageResult = {RemainingArmies=remainingArmies, KilledArmies=math.max (0, armyCount-remainingArmies), SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecials, ClonedSpecials=clonedSpecials, DamageToSpecialUnits=damageToSpecialUnits};
	return damageResult;

	--reference
	--[[local impactedTerritory = WL.TerritoryModification.Create(terrID);
	local modifiedTerritories = {};
	impactedTerritory.RemoveSpecialUnitsOpt = {shieldDataRecord.specialUnitID};
	table.insert(modifiedTerritories, impactedTerritory);]]

end

function applyDamageToSpecials (intDamage, Specials, result)
	local remainingDamage = intDamage;
	for k,v in pairs (Specials) do
		if (remainingDamage > 0) then
			--if the Special is still alive, apply damage to it
			local SpecialHealth = v.Health;
			if (SpecialHealth > 0) then
				local SpecialDamage = math.min (SpecialHealth, remainingDamage);
				remainingDamage = remainingDamage - SpecialDamage;
				result = WL.Armies.Create (result.NumArmies + SpecialDamage, result.SpecialUnits);
			end
		end
	end
	return result;

end