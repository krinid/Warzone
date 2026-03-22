--TODO:
-- - restrict Poison to activate on bordering territories
-- - remove Range option
-- - add effects for Commander & Bosses
-- - add Duration handling
-- - add impacts - @ cast time does 50% damage, start of turn does 50% damage, end of turn does 50% damage (or cast time 100%, start 50%, end 50%)
-- 		- round up @ cast time & end of turn; round down @ start of turn
-- - add spread impact - when armies or SUs move from Poison terrs, they carry 50% of the poison effect with them to the new terr; exemptions: Castles, CityForts, anything else?
-- 		- airlifts out also impacted?
-- - copy Dragons and kill the check for modID==594 ? yea do it
-- - import into PunRew (just Server_TurnAdvance.lua content for the the poison application part, don't need the client side stuff) to apply to terrs with 10+ Punishment
-- 		- actually just have PunRew check for presence of the Poison/Affects Other Mods card and if present, enter a custom order to apply Poison with specific properties and duration 1 to the Punished territory
-- 		- or just have PunRew remove 1 SU each turn for 11+ turns of Punishment?
--		- add to Encirclement/Weaken Blockades too?
-- - add a "Strong Poison" card? Which is just a 2nd poison card for host to modify the properties (1 could affect armies more, the other SUs more; or just 1 is stronger version of the other)
-- - add a "Poison Affects Other Mods" card that other mods can check for in order to apply poison damage to their own mod effects (eg: Pestilence, Nuke, Bomb+, etc); this is needed in order to have the Poison damage apply to the Special Units added by these other mods; this card would just be a placeholder card that isn't actually played but just exists so that other mods can check for its existence

strPoisonNameText = "Poison"; --use this to display "Poison" in annotations, etc

---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addNewOrder)
	execute_Recurring_Poison_Damage (game, addNewOrder);
	expire_Poison (game, addNewOrder);
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order (game, order, orderResult, skipThisOrder, addNewOrder)
	--ModData doesn't exist for all order types so only check if GameOrderPlayCardCustom
	if (order.proxyType == 'GameOrderPlayCardCustom') then
		local modDataContent = split (order.ModData, "|");
		local strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		local cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type

		if (strCardTypeBeingPlayed == "Poison") then
			execute_Poison_operation (game, order, addNewOrder, skipThisOrder, tonumber (cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Strong Poison") then
			execute_Poison_operation (game, order, addNewOrder, skipThisOrder, tonumber (cardOrderContentDetails));
		end
	elseif (order.proxyType == 'GameOrderAttackTransfer' and (orderResult.IsAttack == true or orderResult.IsSuccessful == true)) then
		local targetTerritory = game.ServerGame.LatestTurnStanding.Territories [order.To];
		local impactedTerritory = WL.TerritoryModification.Create (order.To);
		apply_Poison_to_Territory (game, order, addNewOrder, skipThisOrder, targetTerritory, impactedTerritory, 0.5);
	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
	execute_Recurring_Poison_Damage (game, addNewOrder, false);
end

--expire poison if appropriate duration has passed
function expire_Poison (game, addNewOrder)
	--read Poison data, expire poison if duration has passed
	local publicGameData = Mod.PublicGameData or {};
	local poisonData = publicGameData.PoisonData or {};
	local poisonDataNew = {};

	print ("[POISON] Expire check; table length " ..tonumber (tablelength (poisonData)));

	for k,poisonRecord in pairs (poisonData) do
		-- ref: poisonRecord = {targetTerritoryID = targetTerritory.ID, turnApplied = game.Game.TurnNumber, expiresOnTurn = game.Game.TurnNumber + Mod.Settings.Duration, cardPlayerID = order.PlayerID, strength = floatPoisonStrength};
		if (tonumber (poisonRecord.expiresOnTurn) <= game.Game.TurnNumber) then
			print ("[POISON] expire!")
			local impactedTerritory_RemoveStructure = WL.TerritoryModification.Create (poisonRecord.targetTerritoryID);
			local structures = game.ServerGame.LatestTurnStanding.Territories [poisonRecord.targetTerritoryID].Structures or {};
			local strStructureName = strPoisonNameText;
			structures [WL.StructureType.Custom (strStructureName)] = 0; --remove Poison structure
			impactedTerritory_RemoveStructure.SetStructuresOpt = structures;
			local event = WL.GameOrderEvent.Create (poisonRecord.cardPlayerID, strPoisonNameText.. " expires on " ..getTerritoryName (poisonRecord.targetTerritoryID, game), {}, {impactedTerritory_RemoveStructure});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, poisonRecord.targetTerritoryID);
			-- event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strPoisonNameText, 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
			addNewOrder (event, true);
		else
			poisonDataNew [k] = poisonRecord;
		end

	end
	publicGameData.PoisonData = poisonDataNew;
	Mod.PublicGameData = publicGameData;
end

--apply Poison to all territories that are currently impacted by Poison
function execute_Recurring_Poison_Damage (game, addNewOrder, boolExpirePoison)
	--read Poison data, apply poison damage
	local publicGameData = Mod.PublicGameData or {};
	local poisonData = publicGameData.PoisonData or {};

	print ("[POISON] Recurring damage; expire==" ..tostring (boolExpirePoison).. ", table length " ..tonumber (tablelength (poisonData)));

	for _,poisonRecord in pairs (poisonData) do
		local impactedTerritory = WL.TerritoryModification.Create (poisonRecord.targetTerritoryID);
		print ("0, Poison impact,terr " ..poisonRecord.targetTerritoryID.. ", 0.5, expires T" ..poisonRecord.expiresOnTurn.. ", currTurn T".. game.Game.TurnNumber);
		apply_Poison_Damage_to_Territory (game, 0, "Poison impact", addNewOrder, game.ServerGame.LatestTurnStanding.Territories [poisonRecord.targetTerritoryID], impactedTerritory, poisonRecord.strength/0.5); --apply 50% damage at start of turn, 50% at end of turn (in addition to the 100% when the poison hits)
	end
end

--apply Poison to targetTerritory (get structures from here), add apply the effects to impactedTerritory (used to create the custom event order)
--floatPoisonStrength is a multiplier for poison damage; original target gets 1.0, poison spread gets 0.5, each successive spread further multiplies by 0.5
function apply_Poison_to_Territory (game, order, addNewOrder, skipThisOrder, targetTerritory, impactedTerritory, floatPoisonStrength)
	local structures = targetTerritory.Structures or {};
	local strStructureName = strPoisonNameText;

	if (structures [WL.StructureType.Custom (strStructureName)] == nil) then structures [WL.StructureType.Custom (strStructureName)] = 1; end; --don't add a 2nd structure, there is no recurring "double poison" effect but each poison play will do poison damage at time of play, just extend the Duration
	impactedTerritory.SetStructuresOpt = structures;

	--add Poison record to PoisonData to track to apply Poison appropriately at Start/End of turns and expire the Poison effect when duration comes to fruition
	local publicGameData = Mod.PublicGameData or {};
	local poisonData = publicGameData.PoisonData or {};
	local poisonRecord = poisonData [targetTerritory.ID];
	if (poisonRecord == nil) then
		--territory is not currently impacted by poison, create a new record
		poisonRecord = {targetTerritoryID = targetTerritory.ID, turnApplied = game.Game.TurnNumber, expiresOnTurn = tonumber (game.Game.TurnNumber) + tonumber (Mod.Settings.PoisonDuration), cardPlayerID = order.PlayerID, strength = floatPoisonStrength};
	else
		--territory is already impacted by poison, overwrite existing record, extend duration of poison,
		poisonRecord = {targetTerritoryID = targetTerritory.ID, turnApplied = poisonData [targetTerritory.ID].turnAplied, expiresOnTurn = poisonData [targetTerritory.ID].expiresOnTurn + tonumber (Mod.Settings.PoisonDuration), cardPlayerID = order.PlayerID, strength = math.max (floatPoisonStrength, poisonData [targetTerritory.ID].strength)};
	end

	poisonData [targetTerritory.ID] = poisonRecord;
	publicGameData.PoisonData = poisonData;
	Mod.PublicGameData = publicGameData;
	return (impactedTerritory);
end

--apply Poison damage to targetTerritory (get armies/SUs from here), add apply the effects to impactedTerritory (used to create the custom event order)
function apply_Poison_Damage_to_Territory (game, intPoisonPlayerID, strOrderDescription, addNewOrder, targetTerritory, impactedTerritory, floatPoisonStrength)
	local targetTerritoryID = targetTerritory.ID;
	impactedTerritory.AddArmies = -1 * Mod.Settings.PoisonDamagePercentArmies - Mod.Settings.PoisonDamageFixedArmies; --apply damage %'s -- gets weaker for poison spread away from actual hit location (ground zero/epicenter)

	-- SU damage defined by: Mod.Settings.PoisonDamageFixedSpecialUnits & Mod.Settings.PoisonDamagePercentSpecialUnits
	-- Spread to bordering territories quantity Mod.Settings.PoisonDamageRange
	local SUsNewList = {}; --new list of SUs after applying Poison damage
	local SUsToRemove = {}; --list of SUs to remove after applying Poison damage (b/c they are replaced by the ones in SUsNewList)
	for _,SU in pairs (targetTerritory.NumArmies.SpecialUnits) do
		--if SU is Commander or Boss, handle it separately  (must create a Custom SU to mimic these built-in SUs)
		--if SU has Health, reduce the Health by the appropriate amount (must clone the SU and remove the current one)
		--if SU is DamageToKill type, reduce the DamageToKill value by the appropriate amount (must clone the SU and remove the current one)
		if (SU.proxyType == "Commander" or SU.proxyType == "Boss" or SU.proxyType == "Boss1" or SU.proxyType == "Boss2" or SU.proxyType == "Boss3" or SU.proxyType == "Boss4") then
			--handle Commander/Boss SUs here
			--but don't do anything for now; how should these special Built-In units be handled? They have fixed properties and can't be "weakened"; would have to recreate as a Custom SU which make break other aspects of the game related to those units
		elseif (SU.proxyType == "CustomSpecialUnit") then
			local builder = WL.CustomSpecialUnitBuilder.CreateCopy (SU);
			-- print ("[PRE]  Health " ..tostring (builder.Health).. ", DamageToKill " ..tostring (builder.DamageToKill).. ", Name " ..tostring (builder.Name));
			if (builder.Health ~= nil) then builder.Health = math.max (0, SU.Health * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100) - Mod.Settings.PoisonDamageFixedSpecialUnits*floatPoisonStrength); end
			if (builder.DamageToKill ~= nil) then builder.DamageToKill = math.max (0, SU.DamageToKill * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100) - Mod.Settings.PoisonDamageFixedSpecialUnits*floatPoisonStrength); end

			--if setting to apply to all abilities is true, modify AttackPower, DefensePower, AttackPowerPercent, DefensePowerPercent, DamageAbsorption; ignores the SU Fixed Damage amount, reduce using only SU Percent Damage modifier
			if (Mod.Settings.PoisonDamageAffectsAllAbilities == true) then
				if (builder.AttackPower ~= nil) then builder.AttackPower = math.max (0, SU.AttackPower * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100)); end
				if (builder.DefensePower ~= nil) then builder.DefensePower = math.max (0, SU.DefensePower * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100)); end
				-- if (builder.AttackPowerPercentage ~= nil) then builder.AttackPowerPercentage = math.max (0, SU.AttackPowerPercentage * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100)); end
				-- if (builder.DefensePowerPercentage ~= nil) then builder.DefensePowerPercentage = math.max (0, SU.DefensePowerPercentage * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100)); end
				if (builder.DamageAbsorbedWhenAttacked ~= nil) then builder.DamageAbsorbedWhenAttacked = math.max (0, SU.DamageAbsorbedWhenAttacked * (1-Mod.Settings.PoisonDamagePercentSpecialUnits*floatPoisonStrength/100)); end
				--DamageAbsorbedWhenAttacked is also ignored for Health based SUs, but not really relevant here
			end
			-- print ("[POST] Health " ..tostring (builder.Health).. ", DamageToKill " ..tostring (builder.DamageToKill).. ", Name " ..tostring (builder.Name));

			local newSU = nil;
			--if SU.Health is defined, SU.DamageToKill is ignored even if defined
			if (builder.Health == nil and builder.DamageToKill ~= nil and builder.DamageToKill > 0 or builder.Health ~= nil and builder.Health > 0) then
				--SU is still alive, either DTK>0 or Health>0, so remove existing SU + add cloned/reduced SU to territory
				newSU = builder.Build(); --create newSU
				table.insert (SUsNewList, newSU);
				-- print ("[SU survives - reduce & replace it]")
			else
				--SU died b/c either DTK==0 or Health==0, so just remove existing SU from territory and don't add a new SU
				-- print ("[SU dies - just remove it]")
			end
			table.insert (SUsToRemove, SU.ID);
		end
	end

	--if SUs were modified by Poison, add the SU Removals/Additions to the event order
	if (#SUsNewList == 0) then
		local event = WL.GameOrderEvent.Create (intPoisonPlayerID, strOrderDescription, {}, {impactedTerritory});
		event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
		event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strPoisonNameText, 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
		addNewOrder (event, true);
	else
		--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
		local specialsToAdd = split_table_into_blocks (SUsNewList, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders

		--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
		for k,SUlistBlock in pairs (specialsToAdd) do
			-- if (impactedTerritory == nil) then 
			impactedTerritory.AddSpecialUnits = SUlistBlock; --add Specials to target territory
			local event = nil;
			local strPoisonMsg = strOrderDescription;

			if (k == 1) then
				impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
				-- event = WL.GameOrderEvent.Create (order.PlayerID, order.Description, {}, {impactedTerritory});
			else
				strPoisonMsg = "[Special Unit poison]";
			end
			event = WL.GameOrderEvent.Create (intPoisonPlayerID, strPoisonMsg, {}, {impactedTerritory});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strPoisonNameText, 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
			addNewOrder (event, true);
		end
	end
end

--throw Poison on terr intTargetTerritoryID
function execute_Poison_operation (game, order, addNewOrder, skipThisOrder, targetTerritoryID)
	local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);

	--Poison only causes impact iff not protected by Shield
	local boolBlockedByShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID]);
	if (boolBlockedByShield == false) then
		impactedTerritory = apply_Poison_to_Territory (game, order, addNewOrder, skipThisOrder, game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID], impactedTerritory, 1.0); --add Poison custom structure to target terr
		apply_Poison_Damage_to_Territory (game, order.PlayerID, order.Description, addNewOrder, game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID], impactedTerritory, 1.0); --apply damage to armies & SUs on the target terr, with strength 1.0 (full strength)
	else
		--Poison was blocked by Shield, so no damage is down; enter an order indicating what happened
		local event = WL.GameOrderEvent.Create (order.PlayerID, order.Description .. " (blocked by Shield)", {}, {impactedTerritory});
		event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
		event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create (strPoisonNameText .. " (blocked by Shield)", 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
		addNewOrder (event, true);
	end
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

function territoryHasActiveShield (territory)
	if not territory then return false; end

	for _, specialUnit in pairs (territory.NumArmies.SpecialUnits) do
		if (specialUnit.proxyType == 'CustomSpecialUnit' and specialUnit.Name == 'Shield') then return (true); end
	end

	return (false);
end

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create (1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

--create a new special unit and provide the created SU as the return value
function build_specialUnit (OwnerPlayerID, Name, ImageFilename, AttackPower, DefensePower, AttackPowerPercentage, DefensePowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, Health, CombatOrder, CanBeGiftedWithGiftCard, CanBeTransferredToTeammate, CanBeAirliftedToSelf, CanBeAirliftedToTeammate, IsVisibleToAllPlayers, ModData)
    local builder = WL.CustomSpecialUnitBuilder.Create (OwnerPlayerID);
	builder.Name = Name;
	builder.IncludeABeforeName = false;
	builder.ImageFilename = ImageFilename;
	if (AttackPower ~= nil) then builder.AttackPower = AttackPower; else builder.AttackPower = 0; end
	if (AttackPowerPercentage ~= nil) then builder.AttackPowerPercentage = AttackPowerPercentage; end
	if (DefensePower ~= nil) then builder.DefensePower = DefensePower; else builder.DefensePower = 0; end
	if (DefensePowerPercentage ~= nil) then builder.DefensePowerPercentage = DefensePowerPercentage; end
	if (DamageToKill ~= nil) then builder.DamageToKill = DamageToKill; else builder.DamageToKill = 0; end
	if (DamageAbsorbedWhenAttacked ~= nil) then builder.DamageAbsorbedWhenAttacked = DamageAbsorbedWhenAttacked; end
	if (Health ~= nil) then builder.Health = Health; else builder.Health = nil; end
	if (CombatOrder ~= nil) then builder.CombatOrder = CombatOrder; else builder.CombatOrder = 0; end
	if (CanBeGiftedWithGiftCard ~= nil) then builder.CanBeGiftedWithGiftCard = CanBeGiftedWithGiftCard; else builder.CanBeGiftedWithGiftCard = false; end
	if (CanBeTransferredToTeammate ~= nil) then builder.CanBeTransferredToTeammate = CanBeTransferredToTeammate; else builder.CanBeTransferredToTeammate = false; end
	if (CanBeAirliftedToSelf ~= nil) then builder.CanBeAirliftedToSelf = CanBeAirliftedToSelf; else builder.CanBeAirliftedToSelf = false; end
	if (CanBeAirliftedToTeammate ~= nil) then builder.CanBeAirliftedToTeammate = CanBeAirliftedToTeammate; else builder.CanBeAirliftedToTeammate = false; end
	if (IsVisibleToAllPlayers ~= nil) then builder.IsVisibleToAllPlayers = IsVisibleToAllPlayers; else builder.IsVisibleToAllPlayers = false; end
	if (ModData ~= nil) then builder.ModData = ModData; else builder.ModData = ""; end

	local specialUnit = builder.Build ();
	return (specialUnit);
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

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end

function tablelength (T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type (T) ~= "table") then return 0; end
	for _ in pairs (T) do count = count + 1 end
	return count
end