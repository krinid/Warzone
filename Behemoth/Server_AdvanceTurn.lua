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
    if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'Behemoth|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		local orderComponents = split(order.Payload, '|');
		--reference: 	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothGoldSpent;
		local strOperation = orderComponents[2];
		local targetTerritoryID = tonumber(orderComponents[3]);
		local goldSpent = tonumber(orderComponents[4]);

		if (strOperation == "Purchase") then
			-- if (goldSpent > 0) then
				createBehemoth (game, order, addNewOrder, targetTerritoryID, goldSpent);
			-- else
			-- 	skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the 'Mod skipped order' message, since an order with details will be added below
			-- 	addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, "Behemoth purchase failed --> invalid purchase price <=0 gold attempted! Shame on you, CHEATER DETECTED", {}, {}), false);
			-- end
		else
			print ("[BEHEMOTH] unsupported operation: " .. strOperation);
			return;
		end
	elseif (order.proxyType=='GameOrderAttackTransfer' and game.ServerGame.LatestTurnStanding.Territories [order.To].IsNeutral == true) then
		--order is an attack on a neutral territory (technically it's an Attack or a Transfer, but since the target is neutral, it can only be an attack; though I suppose it's possible that some mod could do 'neutral moves' of some sort?)
		--for any Behemoths in the order, do:
			--(A) check if Mod.Settings.BehemothInvulnerableToNeutrals == true and if so, ensure they take no damage
			--(B) ensure damage against the neutral is calculated correctly as per Mod.Settings.BehemothStrengthAgainstNeutrals


		local strSUtype = "Behemoth";
		for _,specialUnit in pairs (order.NumArmies.SpecialUnits) do
			--if SU name is 'Behemoth' or starts with 'Behemoth' (currently Behemoth names have power level appended to their names)
			if (specialUnit.proxyType == 'CustomSpecialUnit' and (specialUnit.Name == strSUtype or string.sub(specialUnit.Name, 1, string.len(strSUtype)) == strSUtype)) then
				print ("\n\n\n result.DefendingArmiesKilled.NumArmies == ".. tostring (result.DefendingArmiesKilled.NumArmies));

				--unit is a Behemoth, so if Mod.Settings.BehemothInvulnerableToNeutrals is set, ensure it neither dies nor takes any damage from the neutral
				if Mod.Settings.BehemothInvulnerableToNeutrals == true then
					--check if the Behemoth is slated to be killed & if so, remove it from the table result.AttackingArmiesKilled.SpecialUnits[specialunit]
					--result.AttackingArmiesKilled.SpecialUnits is an array of special unit objects, where one property is ID; write code to check the array to see if the ID property of an element == specialUnit.ID, and if so, remove it from the array
					local newAttackingArmiesKilled_SpecialUnits = result.AttackingArmiesKilled.SpecialUnits;
					for key = #newAttackingArmiesKilled_SpecialUnits, 1, -1 do
						if (newAttackingArmiesKilled_SpecialUnits[key].ID == specialUnit.ID) then
							table.remove(newAttackingArmiesKilled_SpecialUnits, key);
							print ("[BEHEMOTH] Killed attacking neutral -> nullify the kill; Name: ".. specialUnit.Name)
						end
					end
					result.AttackingArmiesKilled = WL.Armies.Create (result.AttackingArmiesKilled.NumArmies, newAttackingArmiesKilled_SpecialUnits);

					local newDamageToSpecialUnits = result.DamageToSpecialUnits;
					--result.DamageToSpecialUnits is a table with key of the ID of a special unit; write code to check each element of the table to see if the ID matches specialUnit.ID and if so remove it from the table
					--check if the Behemoth is slated to take damage, and if so remove it from the table result.DamageToSpecialUnits[guid]
					for key, intDamage in pairs(result.DamageToSpecialUnits) do
						if (key == specialUnit.ID) then
							result.DamageToSpecialUnits[key] = nil;
							print ("[BEHEMOTH] Damaged while attacking neutral -> nullify the damage; Damage ".. tostring (intDamage).. ", Name: ".. specialUnit.Name);
						end
					end
					result.DamageToSpecialUnits = newDamageToSpecialUnits;
				end

				local armiesBehemoth = WL.Armies.Create (0, {specialUnit}); --put Behemoth in armies object to get attack power & properly apply neutral damage factor Mod.Settings.BehemothStrengthAgainstNeutrals

				-- print ("\n\n\n result.DefendingArmiesKilled.NumArmies == ".. tostring (result.DefendingArmiesKilled.NumArmies));
				--calc gap between damage inclusive of Mod.Settings.BehemothStrengthAgainstNeutrals and the damage already included in the result w/o respect to Mod.Settings.BehemothStrengthAgainstNeutrals, then add it to result.DefendingArmiesKilled
				--if ==1.0 -> no change in damage done to the neutrals; >1.0 -> increases damage done; <1.0 -> decreases damage done
				-- local intFullAttackPower = result.ActualArmies.AttackPower;
				local intFullSUdamage = math.floor (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate + 0.5); --full SU damage pre-modifier (which can increase or decrease the damage done to neutrals)
				local intNewSUdamage = math.floor (intFullSUdamage * Mod.Settings.BehemothStrengthAgainstNeutrals + 0.5); --new damage done inclusive of the modifier
				local intOldTotalDamage = result.DefendingArmiesKilled.NumArmies; --the original damage done, which can be < damage done by SU if #defending armies < damage done by SU
				local intDamageGap = intNewSUdamage - intFullSUdamage; --the gap between current result.DefendingArmiesKilled.NumArmies and the new damage done by the SU with the modifier applied
				local intFullAttackDamage = math.floor (order.NumArmies.AttackPower * game.Settings.OffenseKillRate + 0.5); --this is the total damage done by all attacking armies, including the SU; this is used to identify if the SU is the only attacker or if there are other SUs/armies involved (calc 2 below requires this knowledge)

				-- assign new damage; if Mod.Settings.BehemothStrengthAgainstNeutrals == 1.0, the value stays the same (no change); if >1.0, it increases (this is easy)
				-- but if <1.0 then it's tricky b/c result.DefendingArmiesKilled.NumArmies is received as min (damage done, actual # of defending armies) so can't just subtract full total damge of the SU and add the new damage, b/c it's possible for (full total damage) > (# defending armies) which makes subtracting full damage negative
				-- so in this case, if #defending amies < new SU damage (post modifier), then new result damage = # armies; if #defending armies >= new SU damage (post modifier) then new result damage = new SU damage (post modifier)
				local intNewTotalDamage = intOldTotalDamage; -- this covers case when Mod.Settings.BehemothStrengthAgainstNeutrals == 1.0
				if (Mod.Settings.BehemothStrengthAgainstNeutrals > 1.0) then
					--when >1.0, just add the additional damage to the total damage done -- no problems here, nothing to worry about
					intNewTotalDamage = intOldTotalDamage + intDamageGap;
				elseif (Mod.Settings.BehemothStrengthAgainstNeutrals < 1.0) then
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

				--this works for Mod.Settings.BehemothStrengthAgainstNeutrals >=1.0 but not Mod.Settings.BehemothStrengthAgainstNeutrals <1.0 b/c can't figure out how much of the damage done by the Behemoth is already included in intOldTotalDamage
				--sometimes #territories is < total damage capable to do, thus intOldTotalDamage < total damage capable to do, thus can't just subtract total capable to do and add the gap between that and the real amount -- this may make damage go negative

				result.DefendingArmiesKilled = WL.Armies.Create (math.floor (intNewTotalDamage + 0.5), result.DefendingArmiesKilled.SpecialUnits);
				print ("[BEHEMOTH] Attacking neutral -> apply damage factor " .. Mod.Settings.BehemothStrengthAgainstNeutrals .. "x, orig dmg ".. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate).. ", new damage " .. tostring (armiesBehemoth.AttackPower * game.Settings.OffenseKillRate * Mod.Settings.BehemothStrengthAgainstNeutrals) ..", apply gap " .. intDamageGap.. ", old total damage "..intOldTotalDamage.. ", new total damage ".. intNewTotalDamage);
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

	--local behemothPower = math.max (behemothPowerFactor * (goldSpent^3) + behemothPowerFactor * (goldSpent^2) + behemothPowerFactor * goldSpent, 0);
	--local behemothPower = math.max (behemothPowerFactor * (goldSpent^2), 1);
	local behemothPower = getBehemothPower(goldSpent);
	local behemothPowerFactor = getBehemothPowerFactor(behemothPower); --math.min (behemothPower/100, 0.1) + math.min (behemothPower/1000, 0.1) + math.min (behemothPower/10000, 0.1); --max factor of 0.3

	local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
	builder.Name = 'Behemoth (power '.. tostring (math.floor (behemothPower*10)/10) ..')';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'Behemoth_clearback.png'; --max size of 60x100 pixels
	--builder.ImageFilename = 'monolith special unit_clearback.png'; --max size of 60x100 pixels
	builder.AttackPower = behemothPower * (1+behemothPowerFactor); --adds to attack power, never reduces
	builder.DefensePower = behemothPower * behemothPowerFactor; --reduces defense power to the level of the behemothPowerFactor which ranges from 0 to 0.3; Behemoths are strong attackers, but weak defenders
	builder.AttackPowerPercentage = 0.9+behemothPowerFactor;  --increase (never reduce) attack power of self + accompanying units by behemothPowerFactor; 0.0 means -100% attack damage (the damage this unit does when attacking); 1.0=regular attack damage; >1.0 means bonus attack damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	builder.DefensePowerPercentage = 0.6+behemothPowerFactor; --weak attacker (starts @ 60% reduction of defense damage given) that scales to near normal (90%) as behemoth power increases --0.0 means -100% defense damage (the damage this unit does when attacking); 1.0=regular defense damage; >1.0 means bonus defense damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
	builder.CombatOrder = -1; --fights before armies
	--builder.CombatOrder = 50000; --fights after Commanders <--- for testing purposes only
	--builder.DamageToKill = behemothPower;
	builder.Health = behemothPower;
	builder.DamageAbsorbedWhenAttacked = behemothPower * behemothPowerFactor; --absorbs damage when attacked, scales with behemothPowerFactor which starts at 0 when behemothPower==0, scales to max of 0.3 for strong Behemoths
	builder.CanBeGiftedWithGiftCard = true;
	builder.CanBeTransferredToTeammate = true;
	builder.CanBeAirliftedToSelf = true;
	builder.CanBeAirliftedToTeammate = true;
	builder.IsVisibleToAllPlayers = false;
	--builder.TextOverHeadOpt = "Behemoth (power "..behemothPower..")";
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = "This unit's power scales with the amount of resources uses to spawn it."}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector

	local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
	terrMod.AddSpecialUnits = {builder.Build()};

	addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a Behemoth with power '..behemothPower, {}, {terrMod}));
end

-- function getBehemothPowerFactor (behemothPower)
-- 	return (math.min (behemothPower/100, 0.1) + math.min (behemothPower/1000, 0.1) + math.min (behemothPower/10000, 0.1)); --max factor of 0.3
-- end

-- function getBehemothPower (goldSpent)
-- 	local power = 0;
-- 	if (goldSpent <= 0) then return 0; end
-- 	--if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
-- 	power = power + math.min ((goldSpent/50)*goldSpent, 25);
-- 	if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
-- 	if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
-- 	if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
-- 	if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
-- 	if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
-- 	power = math.floor (math.max (1, power)+0.5);

-- 	power = 0;
-- 	--[[power = power + math.min ((goldSpent/75)*goldSpent, 50);
-- 	power = power + math.min ((goldSpent/150)*goldSpent, 100);
-- 	power = power + math.min ((goldSpent/600)*goldSpent, 500);
-- 	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
-- 	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
-- 	power = power + (goldSpent/10000)*goldSpent;
-- 	power = math.floor (math.max (1, power)+0.5);]]

-- 	local a = 50;  --while goldSpent < a, power < goldSpent
-- 	local b = 100; --while a < goldSpent < b, power >= b and grows slowly/linearly
-- 	local c = 1000; --while b < goldSpent < c, power grows faster/quadratically
-- 	               --while c < goldSpent, power grows even faster/exponentially
-- 	--power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) + math.max(0, math.exp(goldSpent - c) - (c - b)^2);
-- 	--print  (goldSpent ..", "..math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) ..", ".. math.max(0, math.exp(goldSpent - c) - (c - b)^2));

-- 	power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, ((goldSpent - b)) * 1.0)^1 + math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5);
-- 	print  (goldSpent ..", ".. math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, ((goldSpent - b)) * 1.0)^1 ..", ".. math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5));

-- 	return power;
-- end

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