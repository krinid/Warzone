require ('utilities');

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
--boolWZattackTransferOrder
--     - [Limited Multimove] true indicates whether this is a standard WZ attack order and we're manipulating 'result' to let WZ handle the result of the battle
--     - [Airstrike]         false indicates that this isn't being done with an attack order, usually b/c the FROM and TO territories are not adjacent and the standard WZ engine can't process these attacks; in this case the result is handled by this code, either FROM/TO directly modified + optional airlift to visibly move units when attack is successful
--return value is the result with updated AttackingArmiesKilled, DefendingArmiesKilled values & a true/false AttackIsSuccessful indicator
function process_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder, boolWZattackTransferOrder)
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

	--assume order is an attack (otherwise don't call process_manual_attack)
	--if the target territory has an active shield, nullify all damage by zeroing out AttackDamage & DefenseDamage; this is required b/c WZ engine applies the damage nullifying property of the Shield SU only to accompanying allied armies involved in attack but not other SUs
	--thus, other SUs in the territory with the shield will still give out defense damage to attack units, which shouldn't be the case for a Shield; so nullify that damage here
	local boolTOterritoryHasActiveShield = territoryHasActiveShield (DefendingTerritory);
	if (boolTOterritoryHasActiveShield == true) then
		AttackDamage = 0;
		DefenseDamage = 0;
		print ("[ATTACK/TRANSFER] [SHIELD on TARGET TERRITORY] nullify all damage");
	end

	--process Defender damage 1st; if both players are eliminated by this order & they are the last 2 active players in the game, then Defender is eliminated 1st, Attacker wins
	-- print ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	printDebug ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	local defenderResult = apply_damage_to_specials_and_armies (sortedDefenderSpecialUnits, DefendingArmies.NumArmies, AttackDamage, game, addNewOrder, boolWZattackTransferOrder);
	-- print ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	printDebug ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	local attackerResult = apply_damage_to_specials_and_armies (sortedAttackerSpecialUnits, AttackingArmies.NumArmies, DefenseDamage, game, addNewOrder, boolWZattackTransferOrder);
	local boolAttackSuccessful = false; --indicates whether attacker is successful and should move units to target territory and take ownership of it
	-- print ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned]");
	printDebug ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned, "..tablelength (defenderResult.DamageToSpecialUnits).." damaged]");
	-- print ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned]");
	printDebug ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned, "..tablelength (attackerResult.DamageToSpecialUnits).." damaged]");
	local damageToAllSpecialUnits = concatenateArrays (attackerResult.DamageToSpecialUnits, defenderResult.DamageToSpecialUnits); --combine elements from each array for attacker/defender to get a single array
	printDebug ("[!DAMAGE SUs both DEFENDER & ATTACKER] #SUs "..tablelength (damageToAllSpecialUnits));
	for k,v in pairs (defenderResult.DamageToSpecialUnits) do print ("[SU Def damage] SU "..k..", damage "..v); end
	for k,v in pairs (attackerResult.DamageToSpecialUnits) do print ("[SU Att damage] SU "..k..", damage "..v); end
	for k,v in pairs (damageToAllSpecialUnits) do print ("[SU Both damage] SU "..k..", damage "..v); end

	--if all of defender's armies & SUs are killed & attacker still has at least 1 army or SU surviving, attack is successful, transfer the armies
	--note that both sides reduced to 0 means attack is unsuccessful, territory not captured
	if (defenderResult.RemainingArmies == 0 and #defenderResult.SurvivingSpecials == 0 and (attackerResult.RemainingArmies >0 or #attackerResult.SurvivingSpecials >0)) then
		--defender is eliminated, attacker wins
		boolAttackSuccessful = true;
		printDebug ("[ATTACK SUCCESSFUL] attacker wins, defender is wiped out from target territory");
	else
		--defender survives, attacker may have lost some units
		printDebug ("[ATTACK UNSUCCESSFUL] attacker unsuccessful, defender survives in target territory");
	end

	--if this battle is being processed as a WZ attackTransfer order, then update the result here to reflect the true results of the attack
	--if it is not an actual WZ attack/transfer order, then just pass the results back and let the calling function handle the details in a manner appropriately for whatever the use case is
	--result.IsSuccessful cannot be directly updated, but by updating the actual.AttackingArmies, actual.DefendingArmies, result.AttackingArmiesKilled & result.DefendingArmiesKilled, the result will be processed correctly by the WZ engine
	if (boolWZattackTransferOrder == true) then
		result.AttackingArmiesKilled = WL.Armies.Create (attackerResult.KilledArmies, attackerResult.KilledSpecialsObjects);
		result.DefendingArmiesKilled = WL.Armies.Create (defenderResult.KilledArmies, defenderResult.KilledSpecialsObjects);
		result.DamageToSpecialUnits = damageToAllSpecialUnits; --assign damage done to SUs for both attacker & defender
	end
	-- ^^ this doesn't work; the 'result' object isn't updating properly, so must leave it to the calling function to update itself
	-- the 'result' object received here is likely a Lua copy of the original object, so changes don't propagate back to the original object when _Order function ends

	return ({AttackerResult=attackerResult, DefenderResult=defenderResult, IsSuccessful=boolAttackSuccessful, DamageToSpecialUnits=damageToAllSpecialUnits, Result=result, AttackingArmiesKilled=WL.Armies.Create (attackerResult.KilledArmies, attackerResult.KilledSpecialsObjects), DefendingArmiesKilled=WL.Armies.Create (defenderResult.KilledArmies, defenderResult.KilledSpecialsObjects)});
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

--process damage quantity 'totalDamage' to the Specials in table 'sortedSpecialUnits' and the armies in 'armyCount'
--Specials are already stored in table in order of their CombatOrder
--the combo of (sortedSpecialUnits+armyCount) is either the Attacker and totalDamage is damage from defender units, or the combo is the Defender and totalDamage is damage from attacker units
--this function will be called once for each case, once for the Attacker and once for the Defender
--boolWZattackTransferOrder of true - ...document me...
function apply_damage_to_specials_and_armies (sortedSpecialUnits, armyCount, totalDamage, game, addNewOrder, boolWZattackTransferOrder)
	local remainingDamage = totalDamage;
	local boolArmiesProcessed = false;
	local remainingArmies = armyCount;
	local survivingSpecials = {};
	local killedSpecialsGUIDs = {};
	local killedSpecialsObjects = {};
	local clonedSpecials = {};
    local damageToSpecialUnits = {};
	local strDummyPlaceHolder = "|dummyPlaceholder|applyDamageToArmies";

	table.insert (sortedSpecialUnits, {CombatOrder=1, proxyType=strDummyPlaceHolder}); --add a dummy element to the end of the table to ensure armies are processed if they haven't been processed so far (if all specials have CombatOrder<0)

	--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
	printDebug ("_____________________APPLY DAMAGE "..totalDamage..", #armies "..armyCount..", #specials "..#sortedSpecialUnits);
	for k,v in ipairs (sortedSpecialUnits) do
		local newSpecialUnit_clone = nil;
        local boolCurrentSUdamaged = false;
		--Properties Exist for Commander: ID, guid, proxyType, CombatOrder <--- and that's it!
		--Properties DNE for Commander: AttackPower, AttackPowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, DefensePower, DefensePowerPercentage, Health
		printDebug ("[[[[SPECIAL]]]] "..k..", type "..v.proxyType.. ", combat order "..v.CombatOrder..", remaining damage "..remainingDamage);
		local boolCurrentSpecialSurvives = true;

		if (v.proxyType == "CustomSpecialUnit") then
			printDebug ("CUSTOM SPECIAL name '"..v.Name.."', ModID "..v.ModID..", combat order "..v.CombatOrder..", health "..tostring(v.Health)..", attackPower "..tostring(v.AttackPower)..", defensePower "..tostring(v.DefensePower)..", APower% "..tostring(v.AttackPowerPercentage)..
			", DPower% "..tostring(v.DefensePowerPercentage)..", DmgAbsorb "..tostring(v.DamageAbsorbedWhenAttacked)..", DmgToKill "..tostring(v.DamageToKill)..", Health "..tostring(v.Health)..", remaining damage "..remainingDamage);
		elseif (v.proxyType == strDummyPlaceHolder) then
			printDebug ("DUMMY PLACEHOLDER SU for armies, remaining damage "..remainingDamage..", armies damage processed already? "..tostring(boolArmiesProcessed));
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
						-- addOrder (addAirLiftCardEvent, false); --add the event to the game order list, ensure 'false' so this order isn't skipped when we skip the Airstrike order
						-- addOrder (gameOrder, false); --resubmit the Airstrike order as-is, so it can be processed once the Airlift card is added
						local publicGameData = Mod.PublicGameData;
						local commanderOwner = v.OwnerID;
						if (publicGameData.CardData == nil) then publicGameData.CardData = {}; end
						publicGameData.CardData.ResurrectionCardID = tostring(getCardID ("Resurrection", game));
						local CommanderOwner_ResurrectionCard = playerHasCard (commanderOwner, publicGameData.CardData.ResurrectionCardID, game); --get card instance ID of player's Resurrection card
						print ("[RESURRECTION CHECK] Res cardID " ..tostring (publicGameData.CardData.ResurrectionCardID)..", Res card instance ID ".. tostring (CommanderOwner_ResurrectionCard));

						if (CommanderOwner_ResurrectionCard~=nil) then
							--addNewOrder(WL.GameOrderEvent.Create(commanderOwner, "[Resurrection|Invoke]", {}, {}, {}, {}), true); --add event, use 'true' so this order is skipped if the order that kills the Commander is skipped
							-- addNewOrder(WL.GameOrderCustom.Create(commanderOwner, "a", "b"), false); --add order, use 'true' so this new order is skipped if the order that kills the Commander is skipped
							print ("[RESURRECTION CHECK RESULT] Commander dies, player "..commanderOwner .."/"..getPlayerName (game, commanderOwner) .." has Resurrection card, add order to inform Resurrection mod");
							--reference: WL.GameOrderCustom.Create(playerID PlayerID, message string, payload string, costOpt Table<ResourceType (enum),integer>) (static) returns GameOrderCustom:
							local strResurrectionInvoke = "Resurrection|Invoke|"..commanderOwner.."|"..tostring(CommanderOwner_ResurrectionCard);
							print ("[RESSURECTION-INVOKE] "..strResurrectionInvoke);
							addNewOrder(WL.GameOrderCustom.Create (commanderOwner, "Resurrection|Invoke", strResurrectionInvoke), true); --add order, use 'true' so this new order is skipped if the order that kills the Commander is skipped
							-- addNewOrder(WL.GameOrderCustom.Create(commanderOwner, "a", "b"), false); --add order, use 'true' so this new order is skipped if the order that kills the Commander is skipped
							--local airstrikeEvent = WL.GameOrderEvent.Create(gameOrder.PlayerID, strAirStrikeResultText, {}, {sourceTerritory, targetTerritory});

							--local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
						else
							print ("[RESURRECTION CHECK RESULT] Commander dies, player "..commanderOwner.."/"..getPlayerName (game, commanderOwner) .." does not have Resurrection card, eliminate player");
							--local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
							--ELIM player!
							local modifiedTerritories = eliminatePlayer (commanderOwner, game.ServerGame.LatestTurnStanding.Territories, true, game.Settings.SinglePlayer);
							addNewOrder(WL.GameOrderEvent.Create (commanderOwner, getPlayerName (game, commanderOwner).."'s Commander was killed", {}, modifiedTerritories, {}, {}), true); --add event, use 'true' so this order is skipped if the order that kills the Commander is skipped
							--reference: WL.GameOrderEvent.Create(playerID PlayerID, message string, visibleToOpt HashSet<PlayerID>, terrModsOpt Array<TerritoryModification>, setResourcesOpt Table<PlayerID,Table<ResourceType (enum),integer>>, incomeModsOpt Array<IncomeMod>) (static) returns GameOrderEvent:

							--reference: function eliminatePlayer (playerIds, territories, removeSpecialUnits, isSinglePlayer)
							--eliminatePlayer (commanderOwner, territories, removeSpecialUnits, isSinglePlayer);
							--addNewOrder(WL.GameOrderEvent.Create(winnerId, 'Decided random winner', {}, eliminate(votes.players, game.ServerGame.LatestTurnStanding.Territories, true, game.Settings.SinglePlayer)));
						end
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
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table & add to killedSpecialsGUIDs table
						elseif (remainingDamage >= v.Health) then
							remainingDamage = remainingDamage - v.Health;
							printDebug ("SPECIAL dies, health "..v.Health.. ", remaining damage "..remainingDamage);
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table & add to killedSpecialsGUIDs table
						else
                            --apply damage to special of amount remainingDamage
                            --2 cases need to be handled here, as follows; provide information to handle both, and let the calling function handle the resulting actions appropriately
                            --     (case 1) [Limited Multimove] using standard WZ attack order - track damage to SUs and return in a table to be applied via the attack order
                            --     (case 2) [Airstrike] using totally manual attack order - must clone damaged SUs with the new remaining health and store the SUs in a table
							printDebug ("SPECIAL survives but health reduced by "..remainingDamage.." to "..v.Health-remainingDamage .. "[clone/remove old/add new]");

							--(applies to both case 1 & case 2)
							boolCurrentSpecialSurvives = true; --add cloned special to survivingSpecials table
							--(case 1) track damage done to SU
                            local intNewSUhealthAfterDamage = v.Health-remainingDamage;
                            damageToSpecialUnits [v.ID] = remainingDamage; --assign damage done to damageToSpecialUnits table so it can be applied to the SU via the WZ engine as part of the attackTransfer order
							remainingDamage = 0; --no more damage left to process
                            --reference: ---@field DamageToSpecialUnits table<GUID, integer> # The damage done to special units, only when they are not killed

							--(case 2) clone/recreate the SU with new health level; only do this if not using WZ attackTransfer order to handle this attack
							if (boolWZattackTransferOrder == false) then
								local newSpecialUnitBuilder = WL.CustomSpecialUnitBuilder.CreateCopy(v);
								newSpecialUnitBuilder.Health = intNewSUhealthAfterDamage;
								newSpecialUnitBuilder.Name = newSpecialUnitBuilder.Name; -- .."(C)";
								newSpecialUnit_clone = newSpecialUnitBuilder.Build();
							end
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

		--cases to account for
		-- SAME ACTION:
			-- CASE: attackorder + survive + no damage = add to survivingSpecials
			-- CASE: non-attackorder + survive + no damage = add to survivingSpecials
		-- CASE: attackorder + survive + damage = add to survivingSpecials + damageToSpecialUnits
		-- CASE: non-attackorder + survive + damage = add clone to clonedSpecials + survivingSpecials + damageToSpecialUnits + add orig to killedSpecialsGUIDs & killedSpecialsObjects
		-- SAME ACTION:
			-- CASE: non-attackorder + dies = add to killedSpecialsGUIDs & killedSpecialsObjects
			-- CASE: attackorder + dies = add to killedSpecialsGUIDs & killedSpecialsObjects

		--the Special being analyzed this iteration through loop has already DIED or SURVIVED by this opint, add to survivingSpecials table if it survived
		--printDebug ("boolCurrentSpecialSurvives "..tostring(boolCurrentSpecialSurvives));
		if (boolCurrentSpecialSurvives == true) then --the Special survived; but it may have (A) taken no damage, in which case just add it to the survivingSpecials table, or (B) taken damage (if so it has been cloned and need to replace it with the new cloned Special and add that to the table)
			printDebug ("SPECIAL survived");
			if (boolCurrentSUdamaged == false) then
				-- SAME ACTION for both cases:
					-- CASE: attackorder + survive + no damage = add to survivingSpecials
					-- CASE: non-attackorder + survive + no damage = add to survivingSpecials
				table.insert (survivingSpecials, v);
			elseif (boolWZattackTransferOrder == true and boolCurrentSUdamaged == true) then
				--CASE: attackorder + survive + damage = add to survivingSpecials + damageToSpecialUnits
				table.insert (survivingSpecials, v);
				--damageToSpecialUnits modified earlier in code
			elseif (boolWZattackTransferOrder == false) then
				--CASE: non-attackorder + survive + damage = add clone to clonedSpecials + survivingSpecials + damageToSpecialUnits + add orig to killedSpecialsGUIDs & killedSpecialsObjects
				if (newSpecialUnit_clone == nil) then --the Special Unit survived & didn't need to be cloned, just add the original to the survivingSpecials table
					table.insert (survivingSpecials, v);
				else   --the Special Unit survived but needed to be cloned, add the new cloned Special to the survivingSpecials table & add the original to the killedSpecialsGUIDs table (this isn't totally accurate since it wasn't killed per se, 
					--but this mechanism is used to remove it from the source territory & not add it to the target territory if the attack if successful)
						-- CASE: non-attackorder + survive + damage = add clone to clonedSpecials + survivingSpecials + damageToSpecialUnits + add orig to killedSpecialsGUIDs & killedSpecialsObjects
						table.insert (survivingSpecials, newSpecialUnit_clone); --add the new cloned Special to the survivingSpecials table; SUs in this table will be added to the target territory if attack is successful
						table.insert (killedSpecialsGUIDs, v.ID); --add the GUID of the original Special to the killedSpecialsGUIDs table
print ("KSO+1 "..#killedSpecialsObjects);
						table.insert (killedSpecialsObjects, v);  --add the original Special object to the killedSpecialsGUIDs table
print ("KSO+1 "..#killedSpecialsObjects);
						table.insert (clonedSpecials, newSpecialUnit_clone); --add the new cloned Special to the clonedSpecials table; if attack is unsuccessful, attacking SUs in this table need to be added to the source territory & defending SUs in this table need to be added to the target territory
						--newSpecialUnit_clone = nil; --reset the clone to nil for next iteration through the loop --> actually don't need to b/c moved the declaration inside the loop
				end
			end
		else
			printDebug ("SPECIAL died");
			-- SAME ACTION:
				-- CASE: non-attackorder + dies = add to killedSpecialsGUIDs & killedSpecialsObjects
				-- CASE: attackorder + dies = add to killedSpecialsGUIDs & killedSpecialsObjects
			if (v.proxyType ~= strDummyPlaceHolder) then table.insert (killedSpecialsGUIDs, v.ID); table.insert (killedSpecialsObjects, v); end --only add the Special to the killedSpecialsGUIDs & killedSpecialsObjects table if it dies, ignore the dummy placeholder
		end
	end

	printDebug ("[FINAL RESULT] remaining damage "..remainingDamage..", killed armies " .. math.max (0, armyCount-remainingArmies) ..", remaining armies "..remainingArmies.. ", #killedSpecialsGUIDs ".. #killedSpecialsGUIDs ..", #killedSpecialsObjects ".. #killedSpecialsObjects..", #survivingSpecials "..#survivingSpecials..", #damagedSpecialUnits "..tablelength (damageToSpecialUnits));
	local damageResult = {RemainingArmies=remainingArmies, KilledArmies=math.max (0, armyCount-remainingArmies), SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecialsGUIDs, KilledSpecialsObjects=killedSpecialsObjects, ClonedSpecials=clonedSpecials, DamageToSpecialUnits=damageToSpecialUnits};
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

--concatenate elements of 2 arrays, return resulting array; elements do not need to be consecutive or numeric; if both arrays use the same keys, array2 will overwrite the values of array1 where the keys overlap
function concatenateArrays (array1, array2)
	local result = array1; --start with the first array, then add the elements of the 2nd array to it
	for k,v in pairs (array2) do
		result[k] = array2[k];
	end
	return result
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
function getDefinedCardList (game)
	local count = 0;
	local cards = {};
	local publicGameData = Mod.PublicGameData;

	--if CardData structure isn't defined (eg: from an ongoing game before this was done this way), then initialize the variable and populate the list here
	if (publicGameData.CardData==nil) then publicGameData.CardData = {}; publicGameData.CardData.DefinedCards = nil; end

	--if (false) then --publicGameData.CardData.DefinedCards ~= nil) then
	if (publicGameData.CardData.DefinedCards ~= nil) then
		return publicGameData.CardData.DefinedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
	else
		if (game==nil) then print ("game is nil"); return nil; end
		if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
		if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			cards[cardID] = strCardName;
			count = count +1
		end
		return cards;
	end
end

--given a card name, return it's cardID (not card instance ID), ie: represents the card type, not the instance of the card
function getCardID (strCardNameToMatch, game)
	--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
	local cards={};
	if (Mod.PublicGameData.CardData == nil or Mod.PublicGameData.CardData.DefinedCards == nil) then
		--print ("run function");
		cards = getDefinedCardList (game);
	else
		cards = Mod.PublicGameData.CardData.DefinedCards;
	end

	for cardID, strCardName in pairs(cards) do
		if (strCardName == strCardNameToMatch) then
			return cardID;
		end
	end
	return nil; --cardName not found
end

function initialize_CardData (game)
    local publicGameData = Mod.PublicGameData;

    publicGameData.CardData = {};
    publicGameData.CardData.DefinedCards = nil;
    publicGameData.CardData.CardPiecesCardID = nil;
	publicGameData.CardData.Resurrection = nil;
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    publicGameData.CardData.DefinedCards = getDefinedCardList (game);
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    if (game==nil) then print ("game is nil"); return nil; end
    if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
    if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

    publicGameData.CardData.CardPiecesCardID = tostring(getCardID ("Card Piece"));
	publicGameData.CardData.Resurrection = tostring(getCardID ("Resurrection"));
    Mod.PublicGameData = publicGameData;
end