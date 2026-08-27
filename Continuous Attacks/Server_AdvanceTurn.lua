require("Manual_Attack");

---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addOrder)
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
	--this would only ever be required in SP as in MP these variables would be cleared in between turns
	--these global variables are used to carry over data in between orders within a single turn; if the turn advances, ensure these are cleared out so no stale data is processed
	objSendForwardOrder = nil;
	objSendForwardOrder_replica = nil;
	intInfiniteLoopStopper = nil;
	boolProcessingContinuousAttackOrders = nil;
	strSUreplacement_SUremoved_GUID = nil;
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	--check for dummy order; it triggers processing of the actual next iteration of the continous attack order
	--this is necessary for SU damage to correctly apply, b/c the only way to apply damage is to pass the damage in via result.DamageToSpecialUnits on a WZ attack order
	--however, the damage applies after the iteration of Server_AdvanceTurn_Order completes, and it updates the SU; if we use the SU to submit the next iteration of the continuous attack order, the SU will retain its pre-damage health value
	--thus the solution is:
		-- (A) process current iteration of continuous attack order --> SU damage can be seen and calculated, but it hasn't actually applied to the SU yet
		-- (B) insert dummy order + save actual order (includes SUs without any damage taken) and let Server_AdvanceTurn_Order complete --> SU damage is applied at this point
		-- (C) detect dummy order
		-- (D) rebuild the actual next iteration of the continuous attack order using the updated SU from the territory, skip the dummy order
		-- (E) let the actual next iteration of the continuous attack process normally & repeat until the continuous attack ends
	if (objSendForwardOrder ~= nil and order.proxyType == "GameOrderCustom" and order.Payload == "Continuous Attacks|Placeholder") then
		local newSUlist = {};
		local intNumNewSUs = 0;
		for k,v in pairs (objSendForwardOrder.NumArmies.SpecialUnits) do
			-- print ("@@@@@@@@@@1 "..k,v.ID,v.Name,v.Health)
			local getNewSU = findSpecialUnitOnTerritory (v.ID, game, objSendForwardOrder.From);
			-- table.insert (newSUlist, getNewSU);
			if (getNewSU ~= nil) then
				intNumNewSUs = intNumNewSUs + 1;
				newSUlist [intNumNewSUs] = getNewSU;
				-- print ("@@@@@@@@@@2 "..k,getNewSU.ID,getNewSU.Name,getNewSU.Health);
				-- objSendForwardOrder.NumArmies.SpecialUnits [k] = getNewSU;
				-- print ("@@@@@@@@@@3 "..k,objSendForwardOrder.NumArmies.SpecialUnits [k].ID,objSendForwardOrder.NumArmies.SpecialUnits [k].Name,objSendForwardOrder.NumArmies.SpecialUnits [k].Health);
				-- print ("@@@@@@@@@@4 "..intNumNewSUs,newSUlist [intNumNewSUs].ID, newSUlist [intNumNewSUs].Name, newSUlist [intNumNewSUs].Health);
				-- replaceSUwithAnotherSU 
			else
				-- print ("@@@@@@@@@@2/3/4 #" ..k.." == nil! [dead]");;
			end
		end

		if (boolSUreplaced ~= nil) then
			table.insert (newSUlist, objSUreplacement_SUadded); 
			print ("    [CONT ATTACK - SU REPLACEMENT - RE-ADDED] GUID " ..tostring (objSUreplacement_SUadded.ID));
			boolSUreplaced = nil;
		end

		-- objSendForwardOrder.NumArmies.SpecialUnits = newSUlist;
		-- objSendForwardOrder.NumArmies = WL.Armies.Create (objSendForwardOrder.NumArmies.NumArmies, newSUlist);
		-- print ("@@@@@@@@@@ RESULT #SUs "..#newSUlist);
		local newArmies = WL.Armies.Create (objSendForwardOrder.NumArmies.NumArmies, newSUlist);
		addNewOrder (WL.GameOrderAttackTransfer.Create (objSendForwardOrder.PlayerID, objSendForwardOrder.From, objSendForwardOrder.To, objSendForwardOrder.AttackTransfer, objSendForwardOrder.ByPercent, newArmies, objSendForwardOrder.AttackTeammates));
		-- addNewOrder (objSendForwardOrder);
		-- addNewOrder (order);
		-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		objSendForwardOrder = nil;
		boolSUreplaced = nil;
		return;
	end

	--boolProcessingContinuousAttackOrders is global variable to persist between orders; if nil set to false; if true then override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
	if (boolProcessingContinuousAttackOrders == nil) then boolProcessingContinuousAttackOrders = false; end

	-- local AttackPower = AttackingArmies.AttackPower;
	-- local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	-- local AttackDamage = math.floor (AttackPower * game.Settings.OffenseKillRate * totalAttackerAttackPowerPercentage + 0.5);
	-- local DefenseDamage = math.floor (DefensePower * game.Settings.DefenseKillRate * totalDefenderDefensePowerPercentage + 0.5);

	if (order.proxyType == 'GameOrderAttackTransfer') then
		if (boolProcessingContinuousAttackOrders == true) then
			print ("[[[[CONTINUOUS ATTACK]]]] order.NumArmies.NumArmies");
			result.ActualArmies = order.NumArmies; --override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
			-- result.AttackingArmiesKilled = WL.Armies.Create (math.floor (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5), {});
			-- result.DefendingArmiesKilled = WL.Armies.Create (math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5), {});

			-- for k,SU in pairs (result.ActualArmies.SpecialUnits) do print ("[DRAGON BREATH PREP]" ..SU.proxyType..", " ..tostring (SU.Name).. ", ModData: " ..tostring (SU.ModData)); end
			-- processDragonBreathAttacks (game, addNewOrder, result.ActualArmies, order.To); --process Dragon Breath attacks if a Dragon with the ability is present in attackingArmies
			-- airstrikeResult = process_manual_attack (game, attackingArmies, game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID], result, addOrder, false);
			local manualAttackResult = process_manual_attack (game, result.ActualArmies, game.ServerGame.LatestTurnStanding.Territories[order.To], result, addNewOrder, true);
			--reference: function process_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder, boolWZattackTransferOrder)
			result.AttackingArmiesKilled = manualAttackResult.AttackingArmiesKilled;
			result.DefendingArmiesKilled = manualAttackResult.DefendingArmiesKilled;
			result.DamageToSpecialUnits = manualAttackResult.DamageToSpecialUnits; --assign array of tables {GUIDs & damage integers} to apply damge to the SUs as part of the WZ attack order
			-- print ("_____SU damage: # " ..#result.DamageToSpecialUnits.. ", GUID " ..result.DamageToSpecialUnits[1].GUID.. ", damage to #1: " ..result.DamageToSpecialUnits[1].)
			for k,v in pairs (result.DamageToSpecialUnits) do print ("___________[SU damage] SU "..k..", damage "..v); end
			-- if (#result.ActualArmies.SpecialUnits > 0) then print ("[[SU count " ..#result.ActualArmies.SpecialUnits, result.ActualArmies.SpecialUnits[1].ID,result.ActualArmies.SpecialUnits[1].Name,result.ActualArmies.SpecialUnits[1].Health.. "]]"); end
			boolProcessingContinuousAttackOrders = false;
		end

		local newSUlist = result.ActualArmies.SpecialUnits;
		local intRemainingAttackingArmies = result.ActualArmies.NumArmies - result.AttackingArmiesKilled.NumArmies;
		local intRemainingDefendingArmies = game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies - result.DefendingArmiesKilled.NumArmies;
		-- local intRemainingAttackingSUs = #result.ActualArmies.SpecialUnits - #result.AttackingArmiesKilled.SpecialUnits;
		local intRemainingAttackingSUs = #newSUlist - #result.AttackingArmiesKilled.SpecialUnits;
		local intRemainingDefendingSUs = #game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits - #result.DefendingArmiesKilled.SpecialUnits;
		local boolTerritoryHasFort, strStructureID = territoryHasCustomStructure (game.ServerGame.LatestTurnStanding.Territories [order.To], "Fort"); --if target territory has a Fort and there is an attacking force (ie: not 0 armies & 0 SUs) then 1 Fort will be destroyed, and make sure the continous attack cycle continues

		print ("\n[[  ATTACK // TRANSFER ]] PRE  player " ..order.PlayerID.. "/" ..getPlayerName (game, order.PlayerID).. ", FROM "..order.From.."/"..getTerritoryName (order.From, game)..", TO "..order.To.."/"..getTerritoryName (order.To, game) ..
			", numArmies " ..order.NumArmies.NumArmies.. ", actualArmies " ..result.ActualArmies.NumArmies.. ", ByPercent " ..tostring (order.ByPercent).. ", isAttack " ..tostring(result.IsAttack).. ", isSuccessful " ..tostring(result.IsSuccessful)..
			", #SUs attacking " ..#order.NumArmies.SpecialUnits..", Actual #SUs attacking "..#result.ActualArmies.SpecialUnits.. ", Actual #SUs attacking including Replaced SUs " ..tostring (#newSUlist)..
			", #defenderArmies " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies.. ", #defenderSUs " ..#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits..
			", attackPower " ..result.ActualArmies.AttackPower.. ", defensePower " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower..
			", attackDamage " ..(result.ActualArmies.AttackPower * game.Settings.OffenseKillRate).. ", defenseDamage " ..(math.floor (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5)).. "/"  ..(game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate)..
			", AttackingArmiesKilled " ..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled " ..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled "..#result.DefendingArmiesKilled.SpecialUnits..
			", Remaining attacking armies " ..intRemainingAttackingArmies.. ", Remaining defending armies " ..intRemainingDefendingArmies.. 
			", Remaining attacking SUs " ..intRemainingAttackingSUs.. ", Remaining defending SUs " ..intRemainingDefendingSUs.. ", terrHasFort " ..tostring(boolTerritoryHasFort).. ", structureID " ..tostring(strStructureID));

		-- local newArmies = WL.Armies.Create (intRemainingAttackingArmies, result.ActualArmies.SpecialUnits);
		local newArmies = WL.Armies.Create (intRemainingAttackingArmies, newSUlist);

		--this value being >0 determines whether any damage was done during the attack to attackers defenders or both; value ==0 indicates no damage was sustained by either side
		--if any armies died, any SUs died or any SUs took any damage, continue the continuous attacks
		local intDamageTakenIndicator = result.AttackingArmiesKilled.NumArmies + result.DefendingArmiesKilled.NumArmies + #result.AttackingArmiesKilled.SpecialUnits + #result.DefendingArmiesKilled.SpecialUnits + #result.DamageToSpecialUnits;

		--if (target terr has a Fort or damage was done) AND there are remaing attackers (armies or SUs) AND there are remaining defenders (armies or SUs), continue the continuous attack
		--if no damage was done -- stalemate, don't loop infinitely; if no attacks remain -- attack failed, can't continue attacking; if no defenders remain -- attack succeeded, territory is captured
		if ((boolTerritoryHasFort == true or intDamageTakenIndicator > 0) and (intRemainingAttackingArmies + intRemainingAttackingSUs > 0) and ((intRemainingDefendingArmies + intRemainingDefendingSUs > 0) or boolTerritoryHasFort == true)) then
		-- if ((result.AttackingArmiesKilled.NumArmies + result.DefendingArmiesKilled.NumArmies + #result.AttackingArmiesKilled.SpecialUnits + #result.DefendingArmiesKilled.SpecialUnits > 0) and (intRemainingAttackingArmies + intRemainingAttackingSUs > 0) and (intRemainingDefendingArmies + intRemainingDefendingSUs > 0)) then
			print ("---> !! CONTINUE THE ATTACK ---> ---> ---> ---> ---> armies " ..newArmies.NumArmies.. ", #SUs " ..#newArmies.SpecialUnits);
			-- addNewOrder (WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates));
			objSendForwardOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates);
			objSendForwardOrder_replica = objSendForwardOrder; --create a replica to reference for 'Update Dragons' purposes (b/c objSendForwardOrder having an assigned value indicates action must be taken, but the replica is just used for referencing the values as required)

			--check for infinite loop condition - this can happen when a turn that causes a continuous attack condition is repeatedly skipped, eg: when using Forced Orders which cancels the orders, thus making it appear like it can repeat the attack
			if intInfiniteLoopStopper == nil then intInfiniteLoopStopper = 0; end
			intInfiniteLoopStopper = intInfiniteLoopStopper + 1;
			if (intInfiniteLoopStopper > 100) then
				-- addNewOrder (WL.GameOrderCustom.Create ({order.PlayerID, "Continuous Attack - potential infinite loop; ending this attack cycle", {}));
				addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Continuous Attack - potential infinite loop; ending this attack cycle"));
				print ("#################### Continuous Attack - potential infinite loop; ending this attack cycle");
				-- crashMe.Now(); end
				intInfiniteLoopStopper = 0; --reset for the next continuous attack cycle; only abort the current cycle, not all going forward for this turn
				return; --don't process this continuous attack stream any further
			else
				--if not in an infinite loop, continue the continuous attack cycle
				addNewOrder (WL.GameOrderCustom.Create (order.PlayerID, "Continuous Attacks placeholder - players should never see this", "Continuous Attacks|Placeholder"), false); --insert dummy order to trigger processing of the actual next iteration of the continous attack order
				boolProcessingContinuousAttackOrders = true;
			end
		else
			print ("---> __ END THE ATTACK\n");
			objSendForwardOrder_replica = order; --assign current order to the replica b/c there will not be any future adjusted continuous attacks - this is the last order, so if there is an SU that is modified (Dragon Dynamic Health, etc) then the check on the Event that changes the SUs requires this to correctly adjust the potentially incorrect Event order
		end
	elseif (order.proxyType == 'GameOrderEvent') then -- and order.TerritoryModifications ~= nil and order.TerritoryModifications.RemoveSpecialUnitsOpt ~= nil and order.TerritoryModifications.AddSpecialUnits ~= nil) then
		print ("[CONT ATTACK] Message: " ..tostring (order.Message));
		print ("[CONT ATTACK] order.TerritoryModifications == " ..tostring (order.TerritoryModifications));
		local boolSUreplacement = false;
		local boolSUreplacement_SUremoved = false;
		local boolSUreplacement_SUadded = false;
		for k,terrMod in pairs (order.TerritoryModifications) do
			print ("  [CONT ATTACK]   terrMod " ..tostring (terrMod.TerritoryID).. "/" ..tostring (game.Map.Territories [terrMod.TerritoryID].Name));
			print ("  [CONT ATTACK]   terrMod.RemoveSpecialUnitsOpt == " ..tostring (terrMod.RemoveSpecialUnitsOpt));
			print ("  [CONT ATTACK]   terrMod.AddSpecialUnits == " ..tostring (terrMod.AddSpecialUnits));
			-- print ("[CONT ATTACK] order.TerritoryModifications ~= nil --> " ..tostring (order.TerritoryModifications ~= nil));
			-- print ("[CONT ATTACK] order.TerritoryModifications.RemoveSpecialUnitsOpt ~= nil --> " ..tostring (order.TerritoryModifications.RemoveSpecialUnitsOpt ~= nil));
			-- print ("[CONT ATTACK] and order.TerritoryModifications.AddSpecialUnits ~= nil --> " ..tostring (order.TerritoryModifications.AddSpecialUnits ~= nil));
			if (terrMod.RemoveSpecialUnitsOpt ~= nil) then for _, v in pairs (terrMod.RemoveSpecialUnitsOpt) do print ("    [CONT ATTACK - SU REPLACEMENT - REMOVAL] GUID " ..tostring (v)); strSUreplacement_SUremoved_GUID = v; end end
			if (terrMod.AddSpecialUnits ~= nil) then for _, v in pairs (terrMod.AddSpecialUnits) do print ("    [CONT ATTACK - SU REPLACEMENT - ADD] GUID " ..tostring (v.ID).. ", Name: " ..tostring (v.Name)); objSUreplacement_SUadded = v; end end
			if (strSUreplacement_SUremoved_GUID ~= nil and objSUreplacement_SUadded ~= nil) then
				print ("    [CONT ATTACK - SU REPLACEMENT - PRESERVED] GUID " ..tostring (objSUreplacement_SUadded.ID));
				SUonFrom = findSpecialUnitOnTerritory (strSUreplacement_SUremoved_GUID, game, objSendForwardOrder_replica.From);
				SUonTo = findSpecialUnitOnTerritory (strSUreplacement_SUremoved_GUID, game, objSendForwardOrder_replica.To);
				local boolConflict_MustResendDragonUpdateOrder = terrMod.TerritoryID == objSendForwardOrder_replica.From and SUonFrom == nil and SUonTo ~= nil; --if terrMod for 'Update Dragons' is modifying the From terr and the SU DNE on From but does exist on To, Dragon Update will be incorrect (it thinks the SU is still on the From terr despite it being on the To terr, and will create a dupe SU on the From while the real SU has moved to To already and continues to exist there) and must be fixed and resubmitted
				print ("    [CONT ATTACK - SU REPLACEMENT - REMOVE/ADD CHECK] GUID " ..tostring (strSUreplacement_SUremoved_GUID).. ", FOUND ON TERR [From] " ..tostring (SUonFrom).. ", [To] Name: " ..tostring (SUonTo).. ", Redo Update Dragon order: " ..tostring (boolConflict_MustResendDragonUpdateOrder));
				if (boolConflict_MustResendDragonUpdateOrder == true) then
					local terrModFix = WL.TerritoryModification.Create (objSendForwardOrder_replica.To); --create new terrMod for the TO terr; 'Update Dragons' created an incorrect one for the FROM terr, need to shift it to the TO terr
					if (terrMod.AddSpecialUnits ~= nil) then terrModFix.AddSpecialUnits = terrMod.AddSpecialUnits; end
					if (terrMod.SetArmiesTo ~= nil) then terrModFix.SetArmiesTo = terrMod.SetArmiesTo; end
					if (terrMod.AddArmies ~= nil) then terrModFix.AddArmies = terrMod.AddArmies; end
					if (terrMod.SetOwnerOpt ~= nil) then terrModFix.SetOwnerOpt = terrMod.SetOwnerOpt; end
					if (terrMod.SetStructuresOpt ~= nil) then terrModFix.SetStructuresOpt = terrMod.SetStructuresOpt; end
					if (terrMod.AddStructuresOpt ~= nil) then terrModFix.AddStructuresOpt = terrMod.AddStructuresOpt; end
					if (terrMod.RemoveSpecialUnitsOpt ~= nil) then terrModFix.RemoveSpecialUnitsOpt = terrMod.RemoveSpecialUnitsOpt; end
					local eventSUswap = WL.GameOrderEvent.Create (order.PlayerID, order.Message .." [fix]", order.VisibleToOpt, {terrModFix}, order.SetResourceOpt, order.IncomeMods);
					addNewOrder (eventSUswap); --add the adjustment Event order with the fixed terrMod
					skipThisOrder (WL.ModOrderControl.Skip); --skip the current Event order that contains the incorrect terrMod
					print ("    [CONT ATTACK - SU REPLACEMENT - RE-SUBMIT EVENT] Submitted");
					-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
					--WL.GameOrderEvent.Create(playerID PlayerID, message string, visibleToOpt HashSet<PlayerID>, terrModsOpt Array<TerritoryModification>, setResourcesOpt Table<PlayerID,Table<ResourceType (enum),integer>>, incomeModsOpt Array<IncomeMod>) (static) returns GameOrderEvent:
				end
				boolSUreplaced = true;
			end
			--&&& check if SU being replaced is really on the terr it's being removed from; if not, need to skip the order and add replace it with a modified 'Update Dragons' order that adds the Dragon to the proper target
			--this happens b/c the # armies attacking as per result.NumArmies.NumArmies and result.NumArmies.SpecialUnits must be set by this function to ensure the proper # of armies attacks and this can change result.IsSuccessful from false to true
			--so Dragons mod sees result.IsSuccessful==false and submits the 'Update Dragons' order as if the attack failed (Dragon being replaced is still on the FROM territory), when in reality it was successful and the Dragon is now on the TO territory
			--in order to do this, must keep track of the FROM and TO terrs from the previous Cont Attack to detect from 'Update Dragons' placement
		end
	end
end

function isDragon (sp)
    return sp.proxyType == "CustomSpecialUnit" and string.sub(sp.ImageFilename, 1, #"Dragon") ~= nil;
end

function processDragonBreathAttacks (game, addNewOrder, attackingArmies, terrID)
	local dragonData = {};
	dragonData.IsDragonBreathAttack = false; --default to false; if a Dragon with Dragon Breath attack is present in attackingArmies, then set this to true and process the Dragon Breath attack (separately from the main Continuous Attack)
	dragonData.DragonBreathDamage = nil; --set to the real value if a Dragon with Dragon Breath attack is participating in the Continuous Attack

	local targetTerritory = game.Map.Territories[terrID];

	for k,SP in pairs (attackingArmies.SpecialUnits) do
		local SPowner = SP.OwnerID;
		local modID = nil; --initialize to nil and let this represent non-Custom SUs, ie: Commander, Boss, etc; for Custom SUs, set to the mod# the SU was created by
		if (SP.proxyType == "CustomSpecialUnit") then modID = SP.ModID; end
		printDebug ("[CONT ATTACKS - DRAGON BREATH CHECK] ModID "..tostring (modID));
		if (isDragon (SP) == true) then --unit is a Dragon; next analyze the ModData to see if it has a 'Dragon Attack'
			--grab Dragon Breath values from SU.ModData; if ModData isn't defined, assign value of 1
			--ModData currently reads (where XX = dragon breath damage value): 'Dragon Attack' ability%. Whenever this unit attacks another territory, it will deal XX damage to all the connected territories
			--but account for a future wher 'Dragon Attack' is fixed to read 'Dragon Breath' as it is called in actual WZ orders
			local intDragonBreathDamage = nil;
			if (SP.ModData ~= nil) then
				intDragonBreathDamage = tonumber (SP.ModData:match ("'Dragon Attack' ability%. Whenever this unit attacks another territory, it will deal (%d+) damage to all the connected territories"));
				if (intDragonBreathDamage == nil) then intDragonBreathDamage = tonumber (SP.ModData:match ("'Dragon Breath' ability%. Whenever this unit attacks another territory, it will deal (%d+) damage to all the connected territories")); end
			else
				intDragonBreathDamage = 1;
			end

			if (intDragonBreathDamage ~= nil) then --if damage value was found, this Dragon has a Dragon Breath attack; if no damage value was found, this Dragon does not have Dragon Breath, so do nothing
				dragonData.IsDragonBreathAttack = true;
				dragonData.DragonBreathDamage = tonumber (intDragonBreathDamage);
				local SUname = SP.Name and ("'" .. SP.Name .. "' ") or ""; --assign "" is Name is nil, else assign the name with quotes & space afterward so can be used in the line below by appending it regardless of whether it's nil or contains a Dragon's name
				printDebug ("[CONT ATTACKS - DRAGON BREATH] Found Dragon ".. tostring (SUname) .."w/Dragon Breath attack with damage " .. tostring (dragonData.DragonBreathDamage)..", apply to territories connected to ".. tostring (terrID).."/".. getTerritoryName (terrID, game));
				local annotations = {}; --initialize annotations array, used to display "Dragon Breath" on attacked territory and "." on the connected territories that actually take damage
				annotations [terrID] = WL.TerritoryAnnotation.Create ("Dragon Breath", 3, getColourInteger (175, 0, 0)); --Annotation in medium Red for Dragon Breath territory being attacked

				if (intDragonBreathDamage) > 0 then
					local modifiedTerritories = {};
					for connID, _ in pairs (targetTerritory.ConnectedTo) do
						local connTerr = game.ServerGame.LatestTurnStanding.Territories[connID]; --get the connected territory object
						local boolDragonBreathAppliesToThisTerritory = true; --if this territory is owned by the owner of the Dragon or a teammate, change to false and don't apply damage
						local SPownerTeam = (connTerr.OwnerPlayerID ~= WL.PlayerID.Neutral) and game.ServerGame.Game.Players[SPowner].Team or -1; --assign -1 if territory is neutral, otherwise get the team ID of the territory owner (which can still be -1 if teams aren't in play) --> Dragon owner should never be Neutral as this would imply that a Dragon owned by Neutral has somehow been involved in an Continuous Attack - but check for it to be safe
						local connTerrOwnerTeam = (connTerr.OwnerPlayerID ~= WL.PlayerID.Neutral) and game.ServerGame.Game.Players[connTerr.OwnerPlayerID].Team or -1; --assign -1 if territory is neutral, otherwise get the team ID of the territory owner (which can still be -1 if teams aren't in play)
						if (SPowner == connTerr.OwnerPlayerID or SPownerTeam >=0 and SPownerTeam == connTerrOwnerTeam) then boolDragonBreathAppliesToThisTerritory = false; end --if connected territory is owned by the Dragon owner or a teammate, don't apply damage

						if (boolDragonBreathAppliesToThisTerritory == true) then
							local impactedTerritory = WL.TerritoryModification.Create(connID);
							impactedTerritory.AddArmies = -1 * math.min (game.ServerGame.LatestTurnStanding.Territories[connID].NumArmies.NumArmies, intDragonBreathDamage);
							if impactedTerritory.AddArmies ~= 0 then
								table.insert(modifiedTerritories, impactedTerritory);
								annotations [connID] = WL.TerritoryAnnotation.Create (".", 2, getColourInteger (255, 0, 0)); --add Annotation in Red for "." for Dragon Breath
							end
						end
					end
					local event = WL.GameOrderEvent.Create (SPowner, "Dragon breath [".. SUname .."]", {}, modifiedTerritories);
					event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY)
					event.TerritoryAnnotationsOpt = annotations; --use Medium Red & Red colour for Dragon Breath annotations
					addNewOrder(event, true);
				end

			else
				printDebug ("[CONT ATTACKS - DRAGON BREATH] Found Dragon with 0 or nil Dragon Breath damage");
				dragonData.IsDragonBreathAttack = false;
				dragonData.DragonBreathDamage = 0;
			end
		--reference: ModData for a Dragon with Dragon Breath:
			--[[ 		"This unit can be identified by it's White dragon icon. It also has the powerful 'Dragon Attack' ability. Whenever this unit attacks another territory, it will deal 25 damage to all the connected territories. Be aware of this!

			This unit can be bought with 5 gold in the purchase menu (that is the same place where you buy cities)

			Each player can have up to 5 of this particular unit type. Keep this in mind to gain an advantage over your enemies!"]]
		--[[ Here is the description for a dragon that does not have Dragon Breath attacks:
			"This unit can be identified by it's Red dragon icon. It does not have the 'Dragon Attack' ability, but still might be a powerful unit!

			This unit can be bought with 3 gold in the purchase menu (that is the same place where you buy cities)

			Each player can have up to 5 of this particular unit type. Keep this in mind to gain an advantage over your enemies!"]]
		end
	end
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
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

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

function split (inputstr, sep)
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

function printDebug (strText)
	-- print (strText);
end

function replaceSUwithAnotherSU (SUlist, SUtoAdd, SUtoReplace)
	for k,v in pairs (SUlist) do
		if (v.ID == SUtoReplace.ID) then
			SUlist[k] = SUtoAdd;
			return SUlist;
		end
	end
	return SUlist;
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

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function playerHasCard (playerID, cardID, game)
	if (playerID<=0) then print ("playerID is neutral (has no cards)"); return nil; end
	if (cardID==nil) then print ("cardID is nil"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID]==nil) then print ("PLAYER CARDS nil"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards) do
		if (v.CardID == tonumber(cardID)) then print (k); return k; end
	end
	return nil;
end

function getCardName_fromObject(cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
    if cardConfig.proxyType == 'CardGameCustom' then
        return cardConfig.Name;
    end

    if cardConfig.proxyType == 'CardGameAbandon' then
        -- Abandon card was the original name of the Emergency Blockade card
        return 'Emergency Blockade card';
    end
    return cardConfig.proxyType:match("^CardGame(.*)");
end

--find & return an SU object given its GUID and territory location
function findSpecialUnitOnTerritory (specialUnitID, game, terrID)
	print ("fsu, find=="..specialUnitID);
	local terr = game.ServerGame.LatestTurnStanding.Territories [terrID];
	--print ("terr.ID=="..terr.ID..", #specials==".. (#terr.NumArmies.SpecialUnits));
	if (#terr.NumArmies.SpecialUnits >= 1) then
		for _,specialUnit in pairs (terr.NumArmies.SpecialUnits) do
			--print ("1 special on "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
			--printObjectDetails (specialUnit, "[FSU]", "specialUnit details");
			if (specialUnitID == specialUnit.ID) then
				-- print ("FOUND @ "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
				-- print ("FOUND -- "..specialUnit.ID, specialUnit.Name, specialUnit.Health);
				return (specialUnit);
			end
		end
	end
	return nil;
end

function territoryHasCustomStructure (territory, strStructureName)
	if not territory then return false, nil; end --if territory is nil, just return false/nil
	local structures = territory.Structures;
	if not structures then return false, nil; end --if territory is nil, there's are no structures (and thus no forts) so return false/nil

	if (territory.Structures ~= nil) then print ("# Structure types " ..tostring (#territory.Structures)); end
	if (structures ~= nil) then print ("# Structure types " ..tostring (structures)); end

	for structureID, structureCount in pairs (structures) do
		local strArrayStructureData = split (structureID, '|');

		--within 'structureID', 1st segment of "c" indicates custom structure, 2nd segment is mod ID#, 3rd segment is structure name
		--structureCount is integer of # of structures on the territory, and it may be 0, so only return true if there is >=1 remaining, else return false (for this ID -- there may be custom structures of the same name for other IDs, perhaps created from other mods/mod ID#'s)
		if (strArrayStructureData[1] == "c" and strArrayStructureData[3] == strStructureName and structureCount > 0) then
			return true, structureID;
		end
	end
	return false, nil;
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end