--TODOs:
--create list of SUs to exclude -- all the Immovables, Phantoms, anything else?
--don't clone any unit that relies on the ID being the same to expire
--also add Phantom support to dynamically add expiry to all FogMods that have no FogMod records -- just make them expire in either 1 or X turns (X=Phantom duration)
--but first ensure fix "local fogModList = privateGameData.PhantomData [specialUnit.ID].FogMods;" b/c cloned Phantoms have new IDs which won't be in the table and throws an error

---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E]::func start");


	print ("[S_AT_E]::func END");

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
function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addNewOrder)
	--print ("[S_AdvanceTurn_Order - func start] ::ORDER.proxyType="..order.proxyType.."::");  -- <---- only for debugging; it results in too much output, clutters the debug window
	-- print ("[S_AdvanceTurn_Order - func start] ::ORDER.PlayerID="..order.PlayerID.."::");  -- <---- 

	if (order.proxyType=='GameOrderPlayCardBlockade' or order.proxyType=='GameOrderPlayCardAbandon') then
		print ("blockade -- multiply amount ".. tostring (game.Settings.Cards [order.CardID].MultiplyAmount).. ", multipy % " ..tostring (game.Settings.Cards [order.CardID].MultiplyPercentage));
		print (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID, order.PlayerID);

		if (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID == order.PlayerID) then
			local terrMod = WL.TerritoryModification.Create (order.TargetTerritoryID);
			-- local newArmyCount = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies * game.Settings.Cards [order.CardID].MultiplyAmount;

			terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
			terrMod.AddArmies = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies * game.Settings.Cards [order.CardID].MultiplyAmount - game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].NumArmies.NumArmies; --add the armies to the territory
			local event = WL.GameOrderEvent.Create (order.PlayerID, getPlayerName (game, order.PlayerID).. " blockades " ..getTerritoryName (game, order.TargetTerritoryID), nil, {terrMod});
			addNewOrder (event, false);
			skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip the original Blockade order
		end

		-- --((#game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits >0 and #orderResult.DefendingArmiesKilled.SpecialUnits >0) or (#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits >0 and #orderResult.AttackingArmiesKilled.SpecialUnits >0))) then
	-- 	print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (orderResult.IsAttack).." DEFENDER -- #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #orderResult.DefendingArmiesKilled.SpecialUnits);
	-- 	print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (orderResult.IsAttack).." ATTACKER -- #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits .." #specialKilled ".. #orderResult.AttackingArmiesKilled.SpecialUnits);

	-- 	local playerID_Attacker = order.PlayerID;
	-- 	local playerID_Defender = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;

	-- 	--if orderResult.IsSuccessful==true then attackers move to TO territory; killed defender SUs are captured by attacker and placed on TO territory, killed attacker SUs are retained (they don't die) by attacker and travel to TO territory
	-- 	--if orderResult.IsSuccessful==false then killed defender SUs are captured by attacker and plaed on order.From territory, killed attacker SUs are captured by defender and placed on TO territory
	-- 	if (orderResult.IsSuccessful == true) then
	-- 		orderResult.AttackingArmiesKilled = WL.Armies.Create (orderResult.AttackingArmiesKilled.NumArmies, {}); --killed armies still die, but killed SUs do not die, and they shall move to the TO territory
	-- 		process_killed_SUs (game, playerID_Attacker, orderResult.DefendingArmiesKilled.SpecialUnits, order.To, addNewOrder); --put the cloned & ownership reassigned dead defender SUs on the TO territory
	-- 	else
	-- 		--clone dead attackers & give to defender, clone dead defenders & give to attacker
	-- 		process_killed_SUs (game, playerID_Attacker, orderResult.DefendingArmiesKilled.SpecialUnits, order.From, addNewOrder); --assign cloned & ownership reassigned dead defender SUs to attacker on the FROM territory
	-- 		process_killed_SUs (game, playerID_Defender, orderResult.AttackingArmiesKilled.SpecialUnits, order.To, addNewOrder); --assign cloned & ownership reassigned dead attacker SUs to defender on the TO territory
	-- 	end

	-- for cardID, cardConfig in pairs(game.Settings.Cards) do
	-- 	local strCardName = getCardName_fromObject(cardConfig);
	-- 	cards[cardID] = strCardName;
	-- 	count = count +1
	-- end
	-- return cards;

	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
	-- if (game.Game.TurnNumber ~= 1) then return; end --only create SUs on T1
	-- local SPsToCreate = {};
	-- local modifiedTerritories = {};
	-- for terrID,v in pairs (game.ServerGame.LatestTurnStanding.Territories) do
	-- 	--create a bunch of SUs on T1 to start the action
	-- 	if (v.OwnerPlayerID > 0) then
	-- 		local SP1 = build_specialUnit (game, addNewOrder, terrID, v.OwnerPlayerID, "Recruiter ["..v.OwnerPlayerID.."]", "drum.png", 3, 3, nil, nil, 3, 3, nil, 3416, true, true, true, true, false, "game start time auto-created Recruiter", false);
	-- 		local SP2 = build_specialUnit (game, addNewOrder, terrID, v.OwnerPlayerID, "Recruiter ["..v.OwnerPlayerID.."]", "drum.png", 3, 3, nil, nil, 3, 3, nil, 3416, true, true, true, true, false, "game start time auto-created Recruiter", false);
	-- 		local SP3 = build_specialUnit (game, addNewOrder, terrID, v.OwnerPlayerID, "Recruiter ["..v.OwnerPlayerID.."]", "drum.png", 3, 3, nil, nil, 3, 3, nil, 3416, true, true, true, true, false, "game start time auto-created Recruiter", false);
	-- 		local terrMod = WL.TerritoryModification.Create (terrID);
	-- 		terrMod.AddSpecialUnits = {SP1, SP2, SP3};
	-- 		table.insert (modifiedTerritories, terrMod);
	-- 	end
		--for reference:
			-- local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
			-- builder.Name = 'Recruiter';
			-- builder.IncludeABeforeName = true;
			-- builder.ImageFilename = 'drum.png';
			-- builder.AttackPower = 3;
			-- builder.DefensePower = 3;
			-- builder.CombatOrder = 3416; --defends commanders
			-- builder.DamageToKill = 3;
			-- builder.DamageAbsorbedWhenAttacked = 3;
			-- builder.CanBeGiftedWithGiftCard = true;
			-- builder.CanBeTransferredToTeammate = true;
			-- builder.CanBeAirliftedToSelf = true;
			-- builder.CanBeAirliftedToTeammate = true;
			-- builder.IsVisibleToAllPlayers = false;
	-- end

	-- addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "SUs created", {}, modifiedTerritories));

	--this shows move order on ODD TURN #'s -- must invert it for EVEN TURN #'s
	-- local moveOrder = game.ServerGame.CyclicMoveOrder; --Game.GetTurn (1);
	-- for k,v in pairs (moveOrder) do
	-- 	print (v, getPlayerName (game, v));
	-- end
end

--for each killed SU, clone it, assign to otherPlayerID & add to targetTerritoryID (up to 4 at a time)
function process_killed_SUs (game, otherPlayerID, ArmiesKilled_SpecialUnits, targetTerritoryID, addOrder)
	print ("\n\n\n[pkSUs] START");
	local clonedSUs = {};
	for k,sp in pairs (ArmiesKilled_SpecialUnits) do
		--don't capture Commanders/Bosses/other built-in SUs - just let them die normally, only capture Custom SUs (CustomSpecialUnits)
		if (sp.proxyType == "CustomSpecialUnit") then
			local sp_OwnerID = sp.OwnerID;
			--this code is to recreate a new SP of the same type with same properties -- not good b/c it needs all the PNG image files (which is limited to 5)
			-- local newSP = build_specialUnit (game, addOrder, targetTerritoryID, otherPlayerID, sp.Name, sp.ImageFilename, sp.AttackPower, sp.DefensePower, sp.AttackPowerPercentage, sp.DefensePowerPercentage, sp.DamageAbsorbedWhenAttacked, sp.DamageToKill, sp.Health, sp.CombatOrder, sp.CanBeGiftedWithGiftCard, sp.CanBeTransferredToTeammate, sp.CanBeAirliftedToSelf, sp.CanBeAirliftedToTeammate, sp.IsVisibleToAllPlayers, sp.ModData, false);

			--this code is to clone an SU & change the owner -- a much nicer solution, don't need to recreate the SU, don't need to worry about PNG image files, works with all custom SUs
			local builder = WL.CustomSpecialUnitBuilder.CreateCopy(sp);
			builder.OwnerID = otherPlayerID;
			local newSP = builder.Build();
			print ("SP killed: "..k, sp.proxyType.."; , SP owner "..sp_OwnerID.. "/".. getPlayerName (game, sp_OwnerID)..", clone to " ..newSP.OwnerID.. "/".. getPlayerName (game, newSP.OwnerID));
			table.insert (clonedSUs, newSP);
		end
	end

	if (#clonedSUs == 0) then print ("[pkSUs] No SUs to clone"); return; --no SUs to clone, do nothing, just exit the function; possibly there were Commanders/Bosses/non-CustomSpecialUnits that were involved/killed - ignore them
	else print ("[pkSUs] ".. #clonedSUs.. " SUs cloned");
	end

	--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
	local specialsToAdd = split_table_into_blocks (clonedSUs, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders
	local targetTerritory = WL.TerritoryModification.Create (targetTerritoryID)

	--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
	for _,v in pairs (specialsToAdd) do
		targetTerritory.AddSpecialUnits = v; --add Specials to target territory
		local event = WL.GameOrderEvent.Create (otherPlayerID, "[Special Units are captured]", {}, {targetTerritory});
		-- local annotations = {};
		-- annotations [sourceTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [SOURCE]", 30, getColourInteger (0, 255, 0)); --show source territory in Green annotation
		-- annotations [targetTerritoryID] = WL.TerritoryAnnotation.Create ("Airstrike [TARGET]", 30, getColourInteger (255, 0, 0)); --show target territory in Red annotation
		-- event.TerritoryAnnotationsOpt = annotations; --use Red colour for Airstrike target, Green for source
		-- event.TerritoryAnnotationsOpt = {[targetTerritory] = WL.TerritoryAnnotation.Create ("Airstrike", 10, getColourInteger (255, 0, 0))}; --use Red colour for Airstrike
		addOrder (event, true); --skip the order if the original attack order gets skipped
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
		addOrder(WL.GameOrderEvent.Create(game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID, Name.." special unit created", {}, {terrMod}), false);
	end
	return (specialUnit);
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
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

function getTerritoryName (game, intTerrID)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end