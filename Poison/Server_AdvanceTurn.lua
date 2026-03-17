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

---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addOrder)
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order (game, order, orderResult, skipThisOrder, addNewOrder)
	--ModData doesn't exist for all order types so only check if GameOrderPlayCardCustom
	if (order.proxyType=='GameOrderPlayCardCustom') then
		local modDataContent = split (order.ModData, "|");
		local strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		local cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type

		if (strCardTypeBeingPlayed == "Poison") then
			execute_Poison_operation (game, order, addNewOrder, skipThisOrder, tonumber (cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Strong Poison") then
			execute_Poison_operation (game, order, addNewOrder, skipThisOrder, tonumber (cardOrderContentDetails));
		end
	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
end

--throw Poison on terr intTargetTerritoryID
function execute_Poison_operation (game, order, addNewOrder, skipThisOrder, targetTerritoryID)
    local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);

	--Poison only causes impact iff not protected by Shield
	local boolBlockedByShield = territoryHasActiveShield (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID]);
	if (boolBlockedByShield == false) then
		local structures = game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].Structures or {};
		local strStructureName = "Poison";

		if (structures [WL.StructureType.Custom (strStructureName)] == nil) then structures [WL.StructureType.Custom (strStructureName)] = 1;
		-- else structures [WL.StructureType.Custom (strStructureName)] = structures [WL.StructureType.Custom (strStructureName)] + 1; --don't add a 2nd structure; damage can still apply for the initial hit but turn START/END damage doesn't apply with additional Poisons
		end

		impactedTerritory.SetStructuresOpt = structures;
		impactedTerritory.AddArmies = -1 * Mod.Settings.PoisonDamagePercentArmies - Mod.Settings.PoisonDamageFixedArmies;

		-- SU damage defined by: Mod.Settings.PoisonDamageFixedSpecialUnits & Mod.Settings.PoisonDamagePercentSpecialUnits
		-- Spread to bordering territories quantity Mod.Settings.PoisonDamageRange
		local SUsNewList = {}; --new list of SUs after applying Poison damage
		local SUsToRemove = {}; --list of SUs to remove after applying Poison damage (b/c they are replaced by the ones in SUsNewList)
		for _,SU in pairs (game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID].NumArmies.SpecialUnits) do
			--if SU is Commander or Boss, handle it separately  (must create a Custom SU to mimic these built-in SUs)
			--if SU has Health, reduce the Health by the appropriate amount (must clone the SU and remove the current one)
			--if SU is DamageToKill type, reduce the DamageToKill value by the appropriate amount (must clone the SU and remove the current one)
			if (SU.proxyType == "Commander" or SU.proxyType == "Boss" or SU.proxyType == "Boss1" or SU.proxyType == "Boss2" or SU.proxyType == "Boss3" or SU.proxyType == "Boss4") then
				--handle Commander/Boss SUs here
			elseif (SU.proxyType == "CustomSpecialUnit") then
				local builder = WL.CustomSpecialUnitBuilder.CreateCopy (SU);
				-- print ("[PRE]  Health " ..tostring (builder.Health).. ", DamageToKill " ..tostring (builder.DamageToKill).. ", Name " ..tostring (builder.Name));
				if (builder.Health ~= nil) then builder.Health = math.max (0, SU.Health * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100) - Mod.Settings.PoisonDamageFixedSpecialUnits); end
				if (builder.DamageToKill ~= nil) then builder.DamageToKill = math.max (0, SU.DamageToKill * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100) - Mod.Settings.PoisonDamageFixedSpecialUnits); end

				--if setting to apply to all abilitie is true, modify AttackPower, DefensePower, AttackPowerPercent, DefensePowerPercent, DamageAbsorption; ignores the SU Fixed Damage amount, reduce using only SU Percent Damage modifier
				if (Mod.Settings.PoisonDamageAffectsAllAbilities == true) then
					if (builder.AttackPower ~= nil) then builder.AttackPower = math.max (0, SU.AttackPower * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100)); end
					if (builder.DefensePower ~= nil) then builder.DefensePower = math.max (0, SU.DefensePower * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100)); end
					-- if (builder.AttackPowerPercentage ~= nil) then builder.AttackPowerPercentage = math.max (0, SU.AttackPowerPercentage * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100)); end
					-- if (builder.DefensePowerPercentage ~= nil) then builder.DefensePowerPercentage = math.max (0, SU.DefensePowerPercentage * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100)); end
					if (builder.DamageAbsorbedWhenAttacked ~= nil) then builder.DamageAbsorbedWhenAttacked = math.max (0, SU.DamageAbsorbedWhenAttacked * (1-Mod.Settings.PoisonDamagePercentSpecialUnits/100)); end
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
			local event = WL.GameOrderEvent.Create (order.PlayerID, order.Description, {}, {impactedTerritory});
			event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
			event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Poison", 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
			addNewOrder (event, true);
		else
			--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
			local specialsToAdd = split_table_into_blocks (SUsNewList, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders


			--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
			for k,SUlistBlock in pairs (specialsToAdd) do
				-- if (impactedTerritory == nil) then 
				impactedTerritory.AddSpecialUnits = SUlistBlock; --add Specials to target territory
				local event = nil;
				local strPoisonMsg = order.Description;

				if (k == 1) then
					impactedTerritory.RemoveSpecialUnitsOpt = SUsToRemove; --remove the cloned/converted SUs
					-- event = WL.GameOrderEvent.Create (order.PlayerID, order.Description, {}, {impactedTerritory});
				else
					strPoisonMsg = "[Special Unit poison]";
				end
				event = WL.GameOrderEvent.Create (order.PlayerID, strPoisonMsg, {}, {impactedTerritory});
				event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
				event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Poison", 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
				addNewOrder (event, true);
				-- local annotations = {};
				-- annotations [sourceTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [SOURCE]", 30, getColourInteger (0, 255, 0)); --show source territory in Green annotation
				-- annotations [targetTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [TARGET]", 30, getColourInteger (255, 0, 0)); --show target territory in Red annotation
				-- event.TerritoryAnnotationsOpt = annotations; --use Red colour for Airstrike target, Green for source
				-- event.TerritoryAnnotationsOpt = {[targetTerritory] = WL.TerritoryAnnotation.Create ("Airstrike", 10, getColourInteger (255, 0, 0))}; --use Red colour for Airstrike
			end
		end
	else
		--Poison was blocked by Shield, so no damage is down; enter an order indicating what happened
		local event = WL.GameOrderEvent.Create (order.PlayerID, order.Description .. " (blocked by Shield)", {}, {impactedTerritory});
		event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
		event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Poison (blocked by Shield)", 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
		addNewOrder (event, true);
	end

	-- local event = WL.GameOrderEvent.Create (order.PlayerID, order.Description .. (boolBlockedByShield and " (Blocked by Shield)" or ""), {}, {impactedTerritory});
    -- event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	-- event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Poison" .. (boolBlockedByShield and " (Blocked by Shield)" or ""), 8, getColourInteger(50, 175, 0))}; --use Sickly Green for Poison
	-- addNewOrder(event, true);

	-- local publicGameData = Mod.PublicGameData;
    -- if (publicGameData.TornadoData == nil) then publicGameData.TornadoData = {}; end
    -- local turnNumber_TornadoExpires = (Mod.Settings.TornadoDuration > 0) and (game.Game.TurnNumber + Mod.Settings.TornadoDuration) or -1;
    -- publicGameData.TornadoData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, turnNumberTornadoEnds = turnNumber_TornadoExpires};
    -- Mod.PublicGameData = publicGameData;
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