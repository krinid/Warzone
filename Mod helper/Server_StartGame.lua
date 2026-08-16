function Server_StartGame (game, standing)
	--do some Mod Helper functionality here
	if (Mod.Settings.SimpleConfig ~= nil and Mod.Settings.SimpleConfig == 10) then
		--create a bunch of SUs for each player
		local playerReceivedSUalready = {};
		for terrID,v in pairs (standing.Territories) do
			--create the appropriate SUs (types and quantities) as specified by the config variables
			--target territory is the 1st territory found for each player on the map

			if (v.OwnerPlayerID > 0 and playerReceivedSUalready [v.OwnerPlayerID] == nil) then
				print ("[MOD HELPER] [START GAME] player " ..tostring (v.OwnerPlayerID).. ", terr " ..tostring (terrID).. "/" ..tostring (game.Map.Territories[terrID].Name));
				playerReceivedSUalready [v.OwnerPlayerID] = true;
				build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Worker", "hammer.png", 3, 3, nil, nil, 0, 0, 100, 3417, true, true, true, true, false, "Super Worker", true);
				-- build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Worker", "hammer.png", 3, 3, nil, nil, 3, 3, nil, 3417, true, true, true, true, false, "game start time auto-created Worker", true);
				build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Recruiter", "drum.png", 3, 3, nil, nil, 0, 0, 100, 3416, true, true, true, true, false, "Super Recruiter", true);
				-- build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Recruiter", "drum.png", 3, 3, nil, nil, 3, 3, nil, 3416, true, true, true, true, false, "game start time auto-created Recruiter", true);
				build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Tank", "Tank.png", 3, 3, nil, nil, 0, 0, 100, 3415, true, true, true, true, false, "Super Tank", true);
				build_specialUnit_StartGame (game, standing, terrID, v.OwnerPlayerID, "Phantom", "phantom_clearback.png", 0, 0, nil, nil, 0, 0, 100, 9500, true, true, true, true, false, "Super Phantom", true);
			end
		end
	end
end

--create a new special unit in Server_StartGame; this is done by directly modifying the parameter 'standing' instead of adding GameOrderEvent orders (orders can't be added during StartGame)
function build_specialUnit_StartGame (game, standing, targetTerritoryID, playerID, Name, ImageFilename, AttackPower, DefensePower, AttackPowerPercentage, DefensePowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, Health, CombatOrder, CanBeGiftedWithGiftCard, CanBeTransferredToTeammate, CanBeAirliftedToSelf, CanBeAirliftedToTeammate, IsVisibleToAllPlayers, ModData, boolAddSPtoTerritory)
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

	local specialUnit = builder.Build ();
	if (boolAddSPtoTerritory == true) then
		local armyObject = standing.Territories [targetTerritoryID].NumArmies;
		if (armyObject == nil) then armyObject = {}; end
		if (armyObject.SpecialUnits == nil) then armyObject.SpecialUnits = {}; end
		local intNumArmies = (armyObject.NumArmies or 0) + 10;
		local SUs = armyObject.SpecialUnits or {};
		table.insert (SUs, specialUnit);
		local newArmyObject = WL.Armies.Create (intNumArmies, SUs);
		standing.Territories [targetTerritoryID].NumArmies = newArmyObject;

		-- if (standing.Territories [targetTerritoryID].NumArmies == nil) then standing.Territories [targetTerritoryID].NumArmies = {}; end
		-- if (standing.Territories [targetTerritoryID].NumArmies.SpecialUnits == nil) then standing.Territories [targetTerritoryID].NumArmies.SpecialUnits = {}; end
		-- table.insert (standing.Territories [targetTerritoryID].NumArmies.SpecialUnits, specialUnit);
		-- local terrMod = WL.TerritoryModification.Create(targetTerritoryID)
		-- terrMod.AddSpecialUnits = {specialUnit}
		-- addOrder(WL.GameOrderEvent.Create(game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID, Name.." special unit created", {}, {terrMod}), false);
	end
	return (specialUnit);
end