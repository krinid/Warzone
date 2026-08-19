require ("utilities");

---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End (game, addOrder)
	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	-- local boolHaltCodeExecutionAtEndofTurn = true;
	local intHaltOnTurnNumber = 1;
	if (boolHaltCodeExecutionAtEndofTurn==true and game.Game.TurnNumber >= intHaltOnTurnNumber) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order (game, gameOrder, orderResult, skipThisOrder, addNewOrder)
	if (gameOrder.proxyType=='GameOrderPlayCardCustom') then
		local modDataContent = split (gameOrder.ModData, "|");
		--printObjectDetails (gameOrder, "gameOrder", "[TurnAdvance_Order]");
		print ("[GameOrderPlayCardCustom] modData=="..gameOrder.ModData.."::");
		strCardTypeBeingPlayed = nil;  --global variable referenced in other functions in this Server Hook
		cardOrderContentDetails = nil; --global variable referenced in other functions in this Server Hook
		strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type

		if (strCardTypeBeingPlayed == "Critters") then
			execute_Critters_operation (game, gameOrder, orderResult, skipThisOrder, addNewOrder, tonumber (cardOrderContentDetails));
		end
	elseif (gameOrder.proxyType == 'GameOrderCustom') then
		print ("[GameOrderCustom] modData=="..gameOrder.Payload.."::");
		local modDataContent = split (gameOrder.Payload, "|");
		print ("[GameOrderPlayCardCustom] Payload=="..gameOrder.Payload.."::");
		strCardTypeBeingPlayed = nil;  --global variable referenced in other functions in this Server Hook
		cardOrderContentDetails = nil; --global variable referenced in other functions in this Server Hook
		strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type

		print ("[S_AT_O] cardType=="..tostring (strCardTypeBeingPlayed).."::cardOrderContent=="..tostring (cardOrderContentDetails));
		if (strCardTypeBeingPlayed == "Pestilence_ExecuteOrder" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Pestilence == true)) then
			execute_Pestilence_operation (game, gameOrder, addOrder, tonumber (cardOrderContentDetails));
		end
	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
	for terrID, terr in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		local CritterSUs = {};
		for k, SU in pairs (terr.NumArmies.SpecialUnits) do
			if (SU.proxyType == 'CustomSpecialUnit' and (SU.Name == 'Critter' or SU.Name == 'Critters')) then
				table.insert (CritterSUs, SU);
			end
		end

		if (#CritterSUs > 0) then
			local targetTerrID = nil; --game.Map.Territories [terrID].ConnectedTo [1];
			for k,v in pairs (game.Map.Territories [terrID].ConnectedTo) do targetTerrID = k; break; end
			--reference: local strForcedOrder = "ForcedOrders|AttackTransfer|"..targetPlayer.."|"..gameOrder.From.."|"..gameOrder.To.."|"..tostring (gameOrder.AttackTransfer) .."|"..tostring (gameOrder.ByPercent) .."|"..gameOrder.NumArmies.NumArmies.."|".. tostring (gameOrder.AttackTeammates);
			--WL.GameOrderAttackTransfer.Create(playerID PlayerID, from TerritoryID, to TerritoryID, attackOrTransfer AttackTransferEnum (enum), byPercent boolean, numArmies Armies, attackTeammates boolean) (static) returns GameOrderAttackTransfer
			local Armies = WL.Armies.Create (0, CritterSUs);
			local critterAttackTransfer = WL.GameOrderAttackTransfer.Create (WL.PlayerID.Neutral, terrID, targetTerrID, WL.AttackTransferEnum.AttackTransfer, false, Armies, false);
			addNewOrder (critterAttackTransfer);
		end

	end
end

function execute_Critters_operation (game, gameOrder, result, skip, addOrder, targetTerritoryID)
	print ("[execute CRITTERS] terr=="..targetTerritoryID..":: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
	local currentTargetTerritory = game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID]; --current state of target territory, can check if it's already neutral, etc
	local currentTargetOwnerID = currentTargetTerritory.OwnerPlayerID;
	local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
	local targetTerritoryName = game.Map.Territories [targetTerritoryID].Name;
	local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
	local targetPlayerID = nil;   -- the player to be assigned the territory
	local targetTerritoryID = nil;
	local impactedTerritoryOwnerName = nil;
	local strArrayModData = split (gameOrder.ModData,'|');
	--1st element is Critters (don't need it, we already know, we're processing a Critters order)
	targetTerritoryID = tonumber (strArrayModData[2]); --2nd element is target territory ID; this overwrites the value passed in as the parameter; they should be the same value though
	targetPlayerID = tonumber (strArrayModData[3]);  --3rd element is targeted player (targetPlayerID)

	print ("[execute CRITTERS] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::terrOwner=="..currentTargetOwnerID.."::targetPlayer=="..targetPlayerID); --.."::canTargetNaturalNeutrals=="..tostring (Mod.Settings.CrittersCanUseOnNaturalNeutrals)); -- .."::CrittersCanUseOnNeutralizedTerritories=="..tostring(Mod.Settings.CrittersCanUseOnNeutralizedTerritories).."::");
	-- impactedTerritory.SetOwnerOpt = targetPlayerID;
	impactedTerritoryOwnerName = toPlayerName (targetPlayerID, game);

	local SPsToAdd = {};
	local strModDataFooter = tostring (targetTerritoryID).. "|" ..tostring (targetPlayerID).. "|other data here";
	table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critters", "Critters - 5 units_60x55.png", 15, 15, nil, nil, nil, nil, 15, -99000, true, true, true, true, false, "Critters|5 qty|" ..strModDataFooter, false));
	table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critters", "Critters - 4 units_60x55.png", 10, 10, nil, nil, nil, nil, 10, -99000, true, true, true, true, false, "Critters|4 qty|" ..strModDataFooter, false));
	-- table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critter", "Critters - 3 units_60x64.png", 6, 6, nil, nil, nil, nil, 6, -99000, true, true, true, true, false, "Critters|3 qty|" ..strModDataFooter, false));
	table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critters", "Critters - 2 units_60x46.png", 3, 3, nil, nil, nil, nil, 3, -99000, true, true, true, true, false, "Critters|2 qty|" ..strModDataFooter, false));
	-- table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critter", "Critters - 1A units_60x75.png", 1, 1, nil, nil, nil, nil, 1, -99000, true, true, true, true, false, "Critters|1 qty|" ..strModDataFooter, false));
	table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critter", "Critters - 1B units_60x58.png", 1, 1, nil, nil, nil, nil, 1, -99000, true, true, true, true, false, "Critters|1 qty|" ..strModDataFooter, false));
	-- table.insert (SPsToAdd, build_specialUnit (game, addOrder, targetTerritoryID, WL.PlayerID.Neutral, "Critter", "Critters - 1C units_60x62.png", 1, 1, nil, nil, nil, nil, 1, -99000, true, true, true, true, false, "Critters|1 qty|" ..strModDataFooter, false));
	impactedTerritory.AddSpecialUnits = SPsToAdd;

	local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Critters action
	local strCrittersOrderMessage = toPlayerName (castingPlayerID, game) ..' unleashed Critters on ' .. targetTerritoryName .. ', targeting terr owner ' ..impactedTerritoryOwnerName;
	local event = WL.GameOrderEvent.Create (castingPlayerID, strCrittersOrderMessage, {castingPlayerID}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
	-- event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Critters", 8, getColourInteger (0, 255, 0))}; --use Green colour for Critters
	event.Icon = "Critters_Order_40x40_clearBack";
	-- impactedTerritory.RemoveSpecialUnitsOpt = currentTargetTerritory.NumArmies.SpecialUnits; --remove SUs on the territory
	addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function

end

--create a new special unit
function build_specialUnit (game, addOrder, targetTerritoryID, playerID, Name, ImageFilename, AttackPower, DefensePower, AttackPowerPercentage, DefensePowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, Health, CombatOrder, CanBeGiftedWithGiftCard, CanBeTransferredToTeammate, CanBeAirliftedToSelf, CanBeAirliftedToTeammate, IsVisibleToAllPlayers, ModData, boolAddSPtoTerritory)
    -- local builder = WL.CustomSpecialUnitBuilder.Create (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID);
    local builder = WL.CustomSpecialUnitBuilder.Create (playerID);
	builder.Name = Name;
	builder.IncludeABeforeName = false;
	builder.ImageFilename = ImageFilename;
	if (AttackPower ~= nil) then builder.AttackPower = AttackPower; else builder.AttackPower = 0; end
	if (AttackPowerPercentage ~= nil) then builder.AttackPowerPercentage = AttackPowerPercentage; else --[[builder.AttackPowerPercentage = 1.0;]] end
	if (DefensePower ~= nil) then builder.DefensePower = DefensePower; else builder.DefensePower = 0; end
	if (DefensePowerPercentage ~= nil) then builder.DefensePowerPercentage = DefensePowerPercentage; else --[[builder.DefensePowerPercentage = 0;]] end
	if (DamageToKill ~= nil) then builder.DamageToKill = DamageToKill; else builder.DamageToKill = 0; end
	if (DamageAbsorbedWhenAttacked ~= nil) then builder.DamageAbsorbedWhenAttacked = DamageAbsorbedWhenAttacked; --[[else builder.DamageAbsorbedWhenAttacked = 0;]] end
	if (Health ~= nil) then builder.Health = Health; else builder.Health = nil; end
	if (CombatOrder ~= nil) then builder.CombatOrder = CombatOrder; else builder.CombatOrder = 0; end
	if (CanBeGiftedWithGiftCard ~= nil) then builder.CanBeGiftedWithGiftCard = CanBeGiftedWithGiftCard; else builder.CanBeGiftedWithGiftCard = false; end
	if (CanBeTransferredToTeammate ~= nil) then builder.CanBeTransferredToTeammate = CanBeTransferredToTeammate; else builder.CanBeTransferredToTeammate = false; end
	if (CanBeAirliftedToSelf ~= nil) then builder.CanBeAirliftedToSelf = CanBeAirliftedToSelf; else builder.CanBeAirliftedToSelf = false; end
	if (CanBeAirliftedToTeammate ~= nil) then builder.CanBeAirliftedToTeammate = CanBeAirliftedToTeammate; else builder.CanBeAirliftedToTeammate = false; end
	if (IsVisibleToAllPlayers ~= nil) then builder.IsVisibleToAllPlayers = IsVisibleToAllPlayers; else builder.IsVisibleToAllPlayers = false; end
	if (ModData ~= nil) then builder.ModData = ModData; else builder.ModData = ""; end

	local specialUnit = builder.Build();
	if (boolAddSPtoTerritory == true) then
		local terrMod = WL.TerritoryModification.Create(targetTerritoryID)
		terrMod.AddSpecialUnits = {specialUnit}
		addOrder(WL.GameOrderEvent.Create (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID, Name.." special unit created", {}, {terrMod}), false);
	end
	return (specialUnit);
end

function execute_Critters_operation_NOPE (game, gameOrder, result, skip, addOrder, targetTerritoryID)
	print ("[execute CRITTERS] terr=="..targetTerritoryID..":: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
	local currentTargetTerritory = game.ServerGame.LatestTurnStanding.Territories [targetTerritoryID]; --current state of target territory, can check if it's already neutral, etc
	local currentTargetOwnerID = currentTargetTerritory.OwnerPlayerID;
	local impactedTerritory = WL.TerritoryModification.Create (targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
	local targetTerritoryName = game.Map.Territories [targetTerritoryID].Name;
	local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
	local impactedTerritoryOwnerID = nil;   -- the player to be assigned the territory
	local targetTerritoryID = nil;
	local impactedTerritoryOwnerName = nil;
	local strArrayModData = split(gameOrder.ModData,'|');
		--1st element is Critters (don't need it, we already know, we're processing a Critters order)
	targetTerritoryID = tonumber (strArrayModData[2]); --2nd element is target territory ID; this overwrites the value passed in as the parameter; they should be the same value though
	impactedTerritoryOwnerID = tonumber (strArrayModData[3]);  --3rd element is new owner (impactedTerritoryOwnerID)

	print ("[execute CRITTERS] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::currentOwner=="..currentTargetOwnerID.."::newOwner=="..impactedTerritoryOwnerID.."::canTargetNaturalNeutrals=="..tostring (Mod.Settings.CrittersCanUseOnNaturalNeutrals) .."::CrittersCanUseOnNeutralizedTerritories=="..tostring(Mod.Settings.CrittersCanUseOnNeutralizedTerritories).."::");

	-- --check if the target territory is neutral, if so, assign it to specified player, otherwise do nothing
	-- if (currentTargetOwnerID ~= WL.PlayerID.Neutral) then
	-- --if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral) then
	-- 	print ("territory is not neutral -- do nothing"); --this could happen if another mod or WZ makes the territory neutral after the order as input on client side but before this order processes
	-- else

	--future: check settings for if can be cast on natural neutrals and/or Neutralized territories
	local privateGameData = Mod.PrivateGameData; 
	local neutralizeData = privateGameData.NeutralizeData;
	local neutralizeDataRecord = nil;
	-- local boolIsNeutralizedTerritory = false; --if ==true -> Neutralized territory; if ==false -> natural neutral
	local boolSettingsRuleViolation = false;  --abort if Mod settings for application on Natural Neutrals or Neutralized territories don't align to action taken
	local strSettingsRuleViolationMessage = "";
	local specialUnitID = nil;

	--if no violations, then process Deneutralization action
	if (boolSettingsRuleViolation == false) then
		-- --if target territory is a neutralized territory, then remove the data record from NeutralizeData & remove the 'Neutralized' special unit from the territory
		-- if (boolIsNeutralizedTerritory == true) then
		-- 	--this eliminates this element from the table
		-- 	neutralizeData [targetTerritoryID] = nil;
		-- 	impactedTerritory.RemoveSpecialUnitsOpt = {specialUnitID}; --remove the 'Neutralized' special unit from the territory

		-- 	print ("[CRITTERS] remove special " ..tostring (specialUnitID).. "::");

		-- 	--resave privateGameData
		-- 	privateGameData.NeutralizeData = neutralizeData;
		-- 	Mod.PrivateGameData = privateGameData;
		-- end

		--assign the target territory neutral to new owner
		-- print ("territory is neutral -- assign to new owner");
		-- impactedTerritory.SetOwnerOpt = impactedTerritoryOwnerID;
		impactedTerritoryOwnerName = toPlayerName (impactedTerritoryOwnerID, game);

		local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Critters action
		local strCrittersOrderMessage = toPlayerName(castingPlayerID, game) ..' unleashed Critters on ' .. targetTerritoryName .. ', targeting '..impactedTerritoryOwnerName;
		--print ("message=="..strCrittersOrderMessage);
		local event = WL.GameOrderEvent.Create (castingPlayerID, strCrittersOrderMessage, {castingPlayerID}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
		-- event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
		event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
		event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Critters", 8, getColourInteger (0, 255, 0))}; --use Green colour for Critters
		-- impactedTerritory.RemoveSpecialUnitsOpt = currentTargetTerritory.NumArmies.SpecialUnits; --remove SUs on the territory
		addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function
	else
		skip (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		-- addOrder (WL.GameOrderEvent.Create (gameOrder.PlayerID, strSettingsRuleViolationMessage, {}, {},{}));
		local addAirLiftCardEvent = WL.GameOrderEvent.Create (gameOrder.PlayerID, strSettingsRuleViolationMessage, {}, {},{});
		local crittersCardID = getCardID ("Critters", game); --get ID for card type 'Airlift'
		printDebug ("[CRITTERS] card execution failed, target not Neutral; assign 1 Whole Card to compensate for not being able to execute the Critters action");
		-- addAirLiftCardEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[crittersCardID] = game.Settings.Cards[crittersCardID].NumPieces}}; --add enough pieces to equal 1 whole card
		addAirLiftCardEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[crittersCardID] = game.Settings.Cards[crittersCardID].NumPieces}}; --add enough pieces to equal 1 whole card
		addOrder (addAirLiftCardEvent, false);
	end
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