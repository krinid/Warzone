--TODOs:
--   - add description for invulnerability to neutrals & strength vs neutrals to ModDescription.txt & purchase dialog
require ("behemoth");

function Server_AdvanceTurn_End(game, addOrder)
	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	local intHaltOnTurnNumber = 1;
	if (boolHaltCodeExecutionAtEndofTurn==true and game.Game.TurnNumber >= intHaltOnTurnNumber) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	--get values for Behemoth strength vs Neutrals & Invulnerability vs Neutrals; if not set, set to default values
	-- boolBehemothInvulnerableToNeutrals_default = true; --comment this out in Behemoth mod (it's set in behemoth.lua) but uncomment it in Airstrike mod
	-- intStrengthAgainstNeutrals_default = 2.0; --comment this out in Behemoth mod (it's set in behemoth.lua) but uncomment it in Airstrike mod
	local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;
	local boolBehemothInvulnerableToNeutrals = Mod.Settings.BehemothInvulnerableToNeutrals or boolBehemothInvulnerableToNeutrals_default;

	if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'Behemoth|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		local orderComponents = split (order.Payload, '|');
		--reference: 	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothGoldSpent;
		local strOperation = orderComponents[2];
		local targetTerritoryID = tonumber (orderComponents[3]);
		local goldSpent = tonumber (orderComponents[4]);

		if (strOperation == "Purchase") then
			if (goldSpent > 0) then
				createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent);
			else
				skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
				addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Behemoth purchase failed --> invalid purchase price <=0 gold attempted! Shame on you, CHEATER DETECTED", {}, {}), false);
			end
		else
			print ("[BEHEMOTH] unsupported operation: " .. strOperation);
			return;
		end
	elseif (order.proxyType=='GameOrderAttackTransfer' and game.ServerGame.LatestTurnStanding.Territories [order.To].IsNeutral == true) then
		--order is an attack on a neutral territory (technically it's an Attack or a Transfer, but since the target is neutral, it can only be an attack; though I suppose it's possible that some mod could do 'neutral moves' of some sort?)
		--for any Behemoths in the order, do:
			--(A) check if Mod.Settings.BehemothInvulnerableToNeutrals == true and if so, ensure they take no damage (have to eliminate any damage and also ensure they weren't killed -- 2 totally different WZ mechanics to deal with)
			--(B) ensure damage against the neutral is calculated correctly as per intStrengthAgainstNeutrals

		local strSUtype = "Behemoth";
		local boolInvulnerableBehemothWasProtectedFromDeath = false; --used for OMS glitch detection; set to true if a B was killed but 'revived' due to being invulnerable to neutrals
		-- for _,specialUnit in pairs (order.NumArmies.SpecialUnits) do
		for _,specialUnit in pairs (result.ActualArmies.SpecialUnits) do
			--check if SU name is 'Behemoth' or starts with 'Behemoth' (currently Behemoth names have power level appended to their names)
			if (specialUnit.proxyType == 'CustomSpecialUnit' and (specialUnit.Name == strSUtype or string.sub (specialUnit.Name, 1, string.len (strSUtype)) == strSUtype)) then
				--part (A) above: unit is a Behemoth, so if Mod.Settings.BehemothInvulnerableToNeutrals is set, ensure it neither dies nor takes any damage from the neutral
				if (boolBehemothInvulnerableToNeutrals == true) then
					--check if the Behemoth is slated to be killed & if so, remove it from the table result.AttackingArmiesKilled.SpecialUnits[specialunit]
					--result.AttackingArmiesKilled.SpecialUnits is an array of special unit objects, where one property is ID; write code to check the array to see if the ID property of an element == specialUnit.ID, and if so, remove it from the array
					local newAttackingArmiesKilled_SpecialUnits = result.AttackingArmiesKilled.SpecialUnits;
					for key = #newAttackingArmiesKilled_SpecialUnits, 1, -1 do
						if (newAttackingArmiesKilled_SpecialUnits[key].ID == specialUnit.ID) then
							table.remove (newAttackingArmiesKilled_SpecialUnits, key);
							boolInvulnerableBehemothWasProtectedFromDeath = true;
							-- print ("[BEHEMOTH] Killed attacking neutral -> nullify the kill; Name: ".. specialUnit.Name)
						end
					end
					result.AttackingArmiesKilled = WL.Armies.Create (result.AttackingArmiesKilled.NumArmies, newAttackingArmiesKilled_SpecialUnits);

					--check if the Behemoth is slated to take damage, and if so remove it from the table result.DamageToSpecialUnits[guid]
					--result.DamageToSpecialUnits is a table with key of the ID of a special unit; write code to check each element of the table to see if the ID matches specialUnit.ID and if so remove it from the table
					local newDamageToSpecialUnits = {}; --start with empty table, add the items to keep back into the table then reassign to result.DamageToSpecialUnits (this is the only way it works)
					for key, intDamage in pairs(result.DamageToSpecialUnits) do
						if (key == specialUnit.ID) then
							-- print ("[BEHEMOTH] Damaged while attacking neutral -> nullify the damage; Damage ".. tostring (intDamage).. ", Name: ".. specialUnit.Name);
						else
							newDamageToSpecialUnits[key] = result.DamageToSpecialUnits[key];
						end
					end
					result.DamageToSpecialUnits = newDamageToSpecialUnits;
				end

				--part (B) above: ensure damage against the neutral is calculated correctly as per intStrengthAgainstNeutrals
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

				--check here for OMS glitch; this occurs when OMS is in play when a Behemoth that is invulnerable to neutrals attacks a neutral with enough damage to capture it but the Behemoth itself takes enough damage to die so WZ deems
				--the attack to have failed and thus reinstates the OMS army, but the mod stops the Behemoth from dying; thus the criteria for detecting the OMS glitch are:
				-- (A) OMS is in play
				-- (B) Behemoth Invulnerability to neutrals is in play
				-- (C) the Behemoth was killed during the attack (and revived by this mod)
				-- (D) there are is only 1 defending army left on the target territory (all SUs and other armies died) --> #armies at start of turn == #armies killed+1
				-- (E) either (i)  no defending SUs and AttackPower * killRate >= #defending armies or
				--            (ii) all defending SUs were killed
				--evaluate condition (E) above
				local boolOMSconditionApplies = false;
				local intOMSconditionAdjuster = 0;
				if (#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits == 0 and intFullAttackDamage >= game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies) then boolOMSconditionApplies = true; intOMSconditionAdjuster = 1;--condition (E)(i)
				elseif (#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits >0 and #game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits == #result.DefendingArmiesKilled.SpecialUnits) then boolOMSconditionApplies = true; intOMSconditionAdjuster = 1; --condition (E)(ii)
				end

				print ("- - - - - - Behemoth OMS glitch check");
				print ("OMS " .. tostring (game.Settings.OneArmyStandsGuard));
				print ("Neutral-invulnerable Behemoth revived: " ..tostring (boolInvulnerableBehemothWasProtectedFromDeath));
				print ("Target terr #armies " ..tostring (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies).. ", #SUs " ..tostring (#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits));
				print ("Target terr #armies killed " ..tostring (result.DefendingArmiesKilled.NumArmies) .. ", #SUs killed " ..tostring (#result.DefendingArmiesKilled.SpecialUnits));
				print ("Either of the following conditions are true: " ..tostring (boolOMSconditionApplies)); --condition (E)
				print ("  0 Defending SUs & Full Attack Damage >= #Defending armies: " .. tostring (#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits == 0 and intFullAttackDamage >= game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies)); --condition (E)(i)
				print ("  1+ Defending SUs & all Defending SUs killed: " ..tostring (#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits >0 and #game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits == #result.DefendingArmiesKilled.SpecialUnits)); --condition (E)(ii)

				local boolOMSglitchDetected = boolOMSconditionApplies and game.Settings.OneArmyStandsGuard == true and boolInvulnerableBehemothWasProtectedFromDeath == true and #game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits == #result.DefendingArmiesKilled.SpecialUnits and result.DefendingArmiesKilled.NumArmies == game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies - 1;
				print ("OMS glitch detected: " ..tostring (boolOMSglitchDetected).. ", OMS glitch adjuster value: " ..tostring (intOMSconditionAdjuster));

				-- if (boolOMSglitchDetected) then
				-- 	print ("INVOKING OMS GLITCH FIX");
				-- 	-- result.DefendingArmiesKilled = WL.Armies.Create (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies, result.DefendingArmiesKilled.SpecialUnits);
				-- else
				-- 	print ("NOT INVOKING OMS GLITCH FIX");
				-- end

				--this works for intStrengthAgainstNeutrals_default >=1.0 but not intStrengthAgainstNeutrals_default <1.0 b/c can't figure out how much of the damage done by the Behemoth is already included in intOldTotalDamage
				--sometimes #territories is < total damage capable to do, thus intOldTotalDamage < total damage capable to do, thus can't just subtract total capable to do and add the gap between that and the real amount -- this may make damage go negative

				result.DefendingArmiesKilled = WL.Armies.Create (math.floor (intNewTotalDamage + 0.5 + intOMSconditionAdjuster), result.DefendingArmiesKilled.SpecialUnits);
				print ("[BEHEMOTH] Attacking neutral -> apply damage factor " .. intStrengthAgainstNeutrals_default .. "x, orig dmg ".. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate).. ", new damage " .. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate * intStrengthAgainstNeutrals_default) ..", apply gap " .. intDamageGap.. ", old total damage "..intOldTotalDamage.. ", new total damage ".. intNewTotalDamage);
			end
		end
	end
end

function createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent)
	local targetTerritoryStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];

	if (targetTerritoryStanding.OwnerPlayerID ~= order.PlayerID) then
		return; --can only buy a tank onto a territory you control
	end

	if (order.CostOpt == nil) then
		return; --shouldn't ever happen, unless another mod interferes
	end

	local behemothPower = math.floor (getBehemothPower(goldSpent) + 0.5);
	local behemothPowerFactor = 1.0; --keep it simple
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);

	local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
	builder.Name = 'Behemoth (power '.. tostring (math.floor (behemothPower + 0.5)) ..')';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'Behemoth_clearback.png'; --max size of 60x100 pixels
	--builder.ImageFilename = 'monolith special unit_clearback.png'; --max size of 60x100 pixels
	builder.AttackPower = math.floor (behemothPower + 0.5); --keep it simple, attack power = power
	builder.DefensePower = math.floor (behemothPower / 4 + 0.5); --keep it simple, defense power = attack power / 4
	-- builder.AttackPower = behemothPower * (1+behemothPowerFactor); --adds to attack power, never reduces
	-- builder.DefensePower = behemothPower * behemothPowerFactor; --reduces defense power to the level of the behemothPowerFactor which ranges from 0 to 0.3; Behemoths are strong attackers, but weak defenders

	-- builder.AttackPowerPercentage = 0.9+behemothPowerFactor;  --increase (never reduce) attack power of self + accompanying units by behemothPowerFactor; 0.0 means -100% attack damage (the damage this unit does when attacking); 1.0=regular attack damage; >1.0 means bonus attack damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	-- builder.DefensePowerPercentage = 0.6+behemothPowerFactor; --weak attacker (starts @ 60% reduction of defense damage given) that scales to near normal (90%) as behemoth power increases --0.0 means -100% defense damage (the damage this unit does when attacking); 1.0=regular defense damage; >1.0 means bonus defense damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	builder.CombatOrder = -9000; --fights before armies
	--builder.CombatOrder = 50000; --fights after Commanders <--- for testing purposes only
	--builder.DamageToKill = behemothPower;
	builder.Health = behemothPower;
	-- builder.DamageAbsorbedWhenAttacked = behemothPower * behemothPowerFactor; --absorbs damage when attacked, scales with behemothPowerFactor which starts at 0 when behemothPower==0, scales to max of 0.3 for strong Behemoths
	builder.CanBeGiftedWithGiftCard = true;
	builder.CanBeTransferredToTeammate = true;
	builder.CanBeAirliftedToSelf = true;
	builder.CanBeAirliftedToTeammate = true;
	builder.IsVisibleToAllPlayers = false;
	--builder.TextOverHeadOpt = "Behemoth (power "..behemothPower..")";
	-- builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = "This unit's power scales with the amount of gold used to spawn it. [Cost: " ..tostring (goldSpent).. " gold, Health " ..tostring (behemothPower).. ", Power " ..tostring (behemothPower).. "]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
	builder.ModData = "This unit's power scales with the amount of gold used to spawn it. [Cost: " ..tostring (goldSpent).. " gold, Health " ..tostring (behemothPower).. ", Power " ..tostring (behemothPower).. ", Strength vs neutrals: " ..tostring (intStrengthAgainstNeutrals_default).. "x, Invulnerable vs neutrals: " ..tostring (boolBehemothInvulnerableToNeutrals_default).. "]";

	local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
	terrMod.AddSpecialUnits = {builder.Build()};

	addNewOrder (WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a Behemoth with power '..behemothPower, {}, {terrMod}));

	--increase count for total # Behemoths created this game for this player
	local playerGameData = Mod.PlayerGameData;
	local playerGameDataPlayer = playerGameData[order.PlayerID] or {}; --get PlayerGameData for this player, set to {} if nil
	print ("[BEHEMOTH] # Behemoths created this game before this purchase: " .. tostring (playerGameDataPlayer.TotalBehemothsCreatedThisGame or 0));
	playerGameDataPlayer.TotalBehemothsCreatedThisGame = 1 + (playerGameDataPlayer.TotalBehemothsCreatedThisGame or 0); --get # of Behemoths already created this game for this player, if nil then default to 0, then add 1 to reflect the Behemoth just created
	print ("[BEHEMOTH] # Behemoths created this game after this purchase: " .. tostring (playerGameDataPlayer.TotalBehemothsCreatedThisGame or 0));
	playerGameData[order.PlayerID] = playerGameDataPlayer;
	Mod.PlayerGameData = playerGameData; --save PlayerGameData
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