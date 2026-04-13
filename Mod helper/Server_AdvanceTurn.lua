---Server_AdvanceTurn_End hook
---@param game GameServerHook
---@param addOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_End(game, addOrder)
	--nothing yet
end

--Server_AdvanceTurn_Order
---@param game GameServerHook
---@param order GameOrder
---@param orderResult GameOrderResult
---@param skipThisOrder fun(modOrderControl: EnumModOrderControl) # Allows you to skip the current order
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Order(game, order, orderResult, skipThisOrder, addNewOrder)
	--nothing yet
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)

	local intGameStyle = 1; --default to game style 1
	--game styles:
	--1: create 1 new Worker SU on the 1st territory found for each player on T1 (used for 'Workers FTW' mod where Workers are only form of income)
	--2: create 1 new Recruiter SU on the 1st territory found for each player on T1~T5 (used for 'Special Disaster Battle' mod where Recruiters are only form of income)
	--3: tbd

	--game ID 44004985 is Special Disaster Battle v2, set it to use game style 2; game ID 3004 is an SP test game
	--anything else uses default of game style 1 at this point (used in the mod tourney framework)
	if (game.Game.GameID == 44004985 or game.Game.GameID == 3004) then intGameStyle = 2;
	--other checks for other games to manually set here until the game style can be set by the user in the UI and saved in Mod.Settings
	end

	--configure these variables to set up how Mod Helper will the specified game
	local intNumTurnsToHelp = 1; --number of turns that Mod Helper shouild perform some action for
	local intNumWorkersToCreateEachTurn = 0; --# of Worker SUs to create each turn
	local intNumRecruitersToCreateEachTurn = 0; --# of Recruiter SUs to create each turn

	if (intGameStyle == 1) then
		intNumTurnsToHelp = 1;
		intNumWorkersToCreateEachTurn = 1;
	elseif (intGameStyle == 2) then
		intNumTurnsToHelp = 5;
		intNumRecruitersToCreateEachTurn = 1;
	end

	-- if (game.Game.TurnNumber >=6) then return; end --only create SUs on T1~T5   <--- used for 'Special Disaster Battle' (with Recruiters as only form of income)
	-- if (game.Game.TurnNumber >= 2) then return; end --only create SUs on T1   <--- used for 'Workers FTW' (with Workers as only form of income)
	if (game.Game.TurnNumber > intNumTurnsToHelp) then return; end --Mod Helper only helps for as many turns as specified

	--create 1 new SU on the 1st territory found for each player
	local modifiedTerritories = {};
	local playerReceivedSUalready = {};
	for terrID,v in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		--create the appropriate SUs (types and quantities) as specified by the config variables
		--target territory is the 1st territory found for each player on the map
		local SPsToAdd = {}; --list of SUs to be added to the territory; this can't exceed 4 else the add operation will fail -- for now just assume it will be <4

		if (v.OwnerPlayerID > 0 and playerReceivedSUalready [v.OwnerPlayerID] == nil) then
			playerReceivedSUalready [v.OwnerPlayerID] = true;

			for i=1, intNumWorkersToCreateEachTurn do
				table.insert (SPsToAdd, build_specialUnit (game, addNewOrder, terrID, v.OwnerPlayerID, "Worker", "hammer.png", 3, 3, nil, nil, 3, 3, nil, 3417, true, true, true, true, false, "game start time auto-created Worker", false));
			end
			for i=1, intNumRecruitersToCreateEachTurn do
				table.insert (SPsToAdd, build_specialUnit (game, addNewOrder, terrID, v.OwnerPlayerID, "Recruiter", "drum.png", 3, 3, nil, nil, 3, 3, nil, 3416, true, true, true, true, false, "game start time auto-created Recruiter", false));
			end
			local terrMod = WL.TerritoryModification.Create (terrID);
			-- terrMod.AddSpecialUnits = {SP1, SP2, SP3, SP4, SP5}; --use to create multiple SUs on a single turn
			terrMod.AddSpecialUnits = SPsToAdd; --use to create just 1 SU on a single turn
			table.insert (modifiedTerritories, terrMod);
		end
		--for reference - RECRUITER SU:
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

		--for reference - WORKER SU:
			-- local builder = WL.CustomSpecialUnitBuilder.Create(order.PlayerID);
			-- builder.Name = 'Worker';
			-- builder.IncludeABeforeName = true;
			-- builder.ImageFilename = 'hammer.png';
			-- builder.AttackPower = 3;
			-- builder.DefensePower = 3;
			-- builder.CombatOrder = 3417; --defends commanders
			-- builder.DamageToKill = 3;
			-- builder.DamageAbsorbedWhenAttacked = 3;
			-- builder.CanBeGiftedWithGiftCard = true;
			-- builder.CanBeTransferredToTeammate = true;
			-- builder.CanBeAirliftedToSelf = true;
			-- builder.CanBeAirliftedToTeammate = true;
			-- builder.IsVisibleToAllPlayers = false;
	end

	addNewOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "SUs created", {}, modifiedTerritories));
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