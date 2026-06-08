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
				table.insert (modifiedTerritories, create_SU (game, 0, addOrder, ID, terr.Structures [WL.StructureType.City], (oldSU~=nil and oldSU.ID or nil)));
			end
		end
	end

	local event = WL.GameOrderEvent.Create (0, "CityForts", {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
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
	if (order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack == true) then
		--order is an attack (not a transfer)

		local terr = game.ServerGame.LatestTurnStanding.Territories [order.To];

		if (territoryHasActiveShield (terr) == true) then return; end --if target terr has active Shield SU, exit (shield protects the cities from damage)

		--if there are defending armies or SUs other CityForts or Monoliths remaining, don't do any damage to the cities, b/c it means the damage wasn't enough to destroy all armies & SUs on the terr, so Cities should take no damage
		local boolDefenderHasOnlyNonCityBlockingSUsRemaining = compareSUtypes ({["CityFort"] = true, ["Monolith"] = true}, terr.NumArmies.SpecialUnits, result.DefendingArmiesKilled.SpecialUnits);
		print ("\n\n\n********compareSUtypes " ..tostring (boolDefenderHasOnlyNonCityBlockingSUsRemaining));
		if (result.DefendingArmiesKilled.NumArmies < terr.NumArmies.NumArmies or boolDefenderHasOnlyNonCityBlockingSUsRemaining == false) then return; end

		local intDamageAppliedToCities = math.max (0, math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5) - math.min (terr.NumArmies.NumArmies, result.DefendingArmiesKilled.NumArmies)); --factor in SUs here too; --how much damage to apply to cities on the target terr; this is the amount of damage left over from the AttackPower of the source terr after killing all the defending armies and SUs on the target terr
		local intCurrentCityCount = (terr.Structures and terr.Structures [WL.StructureType.City]) or 0;
		if (intCurrentCityCount <= 0) then return; end --if not cities on target terr, this mod has nothing to do, so just exit
		-- local intNumCities = 0;
		local intNewCityCount = math.max (0, intCurrentCityCount - intDamageAppliedToCities);
		local intAttackerDamageTakenFromCities = math.floor (intCurrentCityCount * game.Settings.DefenseKillRate + 0.5); --this is unused and isn't necessary b/c the CityFort is an SU which is involved in the attack and will do defensive damage to the attacker
		-- result.AttackingArmiesKilled = WL.Armies.Create (result.AttackingArmiesKilled.NumArmies + intAttackerDamageTakenFromCities, result.AttackingArmiesKilled.SpecialUnits); --

		-- if (terr.Structures and terr.Structures[WL.StructureType.City] and terr.Structures[WL.StructureType.City] > 0) then intNumCities = terr.Structures[WL.StructureType.City]; end --get #cities on target terr
		print ("SOURCE " ..order.From.. "/" ..game.Map.Territories [order.From].Name.. ", attackPower " ..tostring (result.ActualArmies.AttackPower).. ", cityDamage " ..intDamageAppliedToCities.. ", TARGET " ..order.To.. "/" ..game.Map.Territories [order.To].Name.." , defensePower ..., #armies/[killed] " ..tostring (terr.NumArmies.NumArmies).. "/" ..tostring (result.DefendingArmiesKilled.NumArmies).. ", #SUs/[killed] " ..tostring (#terr.NumArmies.SpecialUnits).. "/" ..tostring (#result.DefendingArmiesKilled.SpecialUnits).. ", #cities " ..intCurrentCityCount.. ", newCityCount " ..intNewCityCount);
		print ("--> DEF #armies/kill " ..tostring (terr.NumArmies.NumArmies).. "/" ..tostring (result.DefendingArmiesKilled.NumArmies).. " ==> #armies < #killed== " ..tostring (terr.NumArmies.NumArmies < result.DefendingArmiesKilled.NumArmies));
		--if cities have been damaged, update the city structures to reflect new city count
		if (intNewCityCount ~= intCurrentCityCount) then
			local structures = terr.Structures or {};
			structures [WL.StructureType.City] = intNewCityCount;

			-- local impactedTerritory = WL.TerritoryModification.Create (order.To);
			local oldSU = getSUonTerritory (terr, "CityFort");
			local impactedTerritory = (intNewCityCount >0 and create_SU (game, 0, addNewOrder, terr.ID, intNewCityCount, (oldSU~=nil and oldSU.ID or nil)) or WL.TerritoryModification.Create (order.To));
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

--return true if all SUs remaining on target terr are of type specified in arrSUnames; else return false (if there is at least 1 SU type not specified in the array)
--this is done by first assessing what SUs remain on the terr by removing killed SUs from the array of SUs on the target terr, and comparing those to the array of SU names
function compareSUtypes (arrSUnames, arrTerrSUs, resultSUsKilled)
	local killedGUIDs = {};
	local arrRemainingSUs = {};

	for _, SU in pairs (resultSUsKilled) do killedGUIDs [SU.ID] = true; end --build lookup of killed SUs

	--build array of surviving SUs
	for _, SU in pairs (arrTerrSUs) do
		if killedGUIDs [SU.ID] ~= true then table.insert (arrRemainingSUs, SU); end
	end

	-- Verify all surviving SUs are of permitted types
	for _, SU in pairs (arrRemainingSUs) do
		if (SU.proxyType ~= 'CustomSpecialUnit') then return false; end --if any surviving SU isn't a CustomSpecialUnit, treat as not matching (this makes all Commanders, Bosses, etc, always return false - which is fine for at least current purposes)
		if arrSUnames [SU.Name] == nil then
			-- print ("FAILED " ..tostring (SU.Name).. " not in " ..table.concat (arrSUnames, ","));
			return false;
		end
	end

	return true;
end

function compareSUtypes_OLD (arrSUnames, arrTerrSUs, resultSUsKilled)
	local arrRemainingSUs = {};
	for _,SU in pairs (arrTerrSUs) do
		table.insert (arrRemainingSUs, SU);
	end

	for _,SU in pairs (arrTerrSUs) do
		if (SU.proxyType == 'CustomSpecialUnit') then
			local boolMatchFound = false;
			for _,strName in pairs (arrSUnames) do
				if (SU.Name == strName) then
					boolMatchFound = true;
					break;
				end
			end

			if (boolMatchFound == false) then return (false); end --if any SU doesn't match the specified type(s), return false immediately
		end
	end
	return (true); --if we get here, all SUs match the specified type(s)
end

function create_SU (game, castingPlayerID, addOrder, targetTerritoryID, intSUhealth, oldSU)
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