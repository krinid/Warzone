require ("punishReward");

--[[
TODO:
- implement territory count punishment/rewards
- punished 1PU for not attacking each enemy you border -- ensure to not punish for teammates (in case this is used in team games)
- implement tracking territory count for X turns (default 10) apply rolling increasing pun/rew for increases/decreases in the past 10 turns; decrease = nerf, increase = buff, no change = small nerf
- implement Sanction/Reverse Sanction casting limitations; on self YES/NO, on teammate YES/NO
- anti-card farming --> if own territory @ start of turn, doesn't count as a cap; check if was that player's territory in any of the last 10 turns? maybe this is too punishing? and too compute intensive to check for all captures?
- punishments = 1PU punishment unit = -5% or -10%?
- rewards = 1RU reward unit = +10%
- punishments - each turn w/o attacks = 1 PU, each turn w/o a capture = 1 PU, each turn w/o going up in territories = 1 PU (too punishing?)
- for each additional in the last 10 turns it's another 0.3 PU
- >5PU causes -1 from all territories
- >8PU causes -2 from all territories
- >10PU causes -5 from all territories
- >15PU causes -10 from all territories
- territories won't go from >=1 to neutral, but if already at 0 when the punishment hits, they go will neutral; confirm if using OMS that they will still go to 0 then neutral
- any kill rate impacts?
- city spread - if # of cities on territory == #cities/#terrs (within 10%?) - bonus; if >10% punish?
- reduce (or eliminate) cities when captured?
- allow cities to be sold?
- allow cities to be moved?
- give buff to city growth on territories where bordering territories have <= (not >) city quantity; specifically how? tbd
]]

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E]::func start");

	--move these initializations to Server_Create or somewhere else
	--these are used to track the past 10 (make configurable) turns to apply cumulative averages, not just immediate data from the current turn
	if (historicalAttacks==nil) then historicalAttacks = {}; end;
	if (historicalCaptures==nil) then historicalCaptures = {}; end;
	if (historicalTerritoryCount==nil) then historicalTerritoryCount = {}; end;
	local turnNumber = game.Game.TurnNumber;
	local playerList = game.ServerGame.Game.PlayingPlayers;

	--set any nil elements to 0; only elements (playerID) which had attacks/captures have values set; players with no attacks/captures are nil; to them to 0 so can do math with any element
	-- Attacks = cleanElements (Attacks);
	-- Captures = cleanElements (Captures);
	-- Attacks = cleanElements (Attacks, turnNumber, playerList);
	-- Captures = cleanElements (Captures, turnNumber, playerList);

	local publicGameData = Mod.PublicGameData;
	if (publicGameData.PRdataByTurn == nil) then publicGameData.PRdataByTurn = {}; end
	if (publicGameData.PRdataByTurn[turnNumber] == nil) then publicGameData.PRdataByTurn[turnNumber] = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].Attacks == nil) then publicGameData.PRdataByTurn[turnNumber].Attacks = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].Captures == nil) then publicGameData.PRdataByTurn[turnNumber].Captures = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].TerritoryCount == nil) then publicGameData.PRdataByTurn[turnNumber].TerritoryCount = {}; end
	publicGameData.PRdataByTurn[turnNumber].Attacks = Attacks; --store Attacks for this turn; this is easily retrievable by turn#, then by playerID
	publicGameData.PRdataByTurn[turnNumber].Captures = Captures; --store Captures for this turn; this is easily retrievable by turn#, then by playerID

	local intarrTerritoryCount_currentTurn = territoryCountAnalysis (game);

	for ID,player in pairs (game.ServerGame.Game.PlayingPlayers) do
		local intTerritoryCount_lastTurn = 0;
		local intTerritoryCount_currentTurn = intarrTerritoryCount_currentTurn [ID];
		local intPunishment_territoryCount = 0;
		local intReward_territoryCount = 0;
		local intPunishment_attack = 0;
		local intReward_attack = 0;
		local intPunishment_capture = 0;
		local intReward_capture = 0;
		local intPunishmentTotalUnits = 0;
		local intRewardTotalUnits = 0;
		local intPunishmentIncome = 0;
		local intRewardIncome = 0;

		--assign value to intTerritoryCount_lastTurn; if turn ==1 then ignore b/c there is no previous value; if turn >1 then get territory count of previous turn; else leave as default value (0)
		if (turnNumber >1 and publicGameData.PRdataByID ~= nil and publicGameData.PRdataByID[ID] ~= nil and publicGameData.PRdataByID[ID].TerritoryCount ~= nil and publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1] ~= nil) then intTerritoryCount_lastTurn = publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1]; end
		-- if (turnNumber >1 and publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1] ~= nil) then intTerritoryCount_lastTurn = publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1]; end

		--identify if territory count has gone up, stayed flat or reduced; if flat, use the values of 0 for both Punishment/Reward (these are the defaults, no action required)
		if (intTerritoryCount_currentTurn <= intTerritoryCount_lastTurn) then intPunishment_territoryCount = 1; --territory count reduced, add 1 unit of Punishment
		else intReward_territoryCount = 1; --territory count increase, add 1 unit of Reward
		end

		if (publicGameData.PRdataByID == nil) then publicGameData.PRdataByID = {}; end
		if (publicGameData.PRdataByID[ID] == nil) then publicGameData.PRdataByID[ID] = {}; end
		if (publicGameData.PRdataByID[ID].Attacks == nil) then publicGameData.PRdataByID[ID].Attacks = {}; end
		if (publicGameData.PRdataByID[ID].Captures == nil) then publicGameData.PRdataByID[ID].Captures = {}; end
		if (publicGameData.PRdataByID[ID].TerritoryCount == nil) then publicGameData.PRdataByID[ID].TerritoryCount = {}; end
		publicGameData.PRdataByID[ID].Attacks[turnNumber] = Attacks[ID]; --store Attacks for this turn; this is easily retrievable by playerID, then by turn#
		publicGameData.PRdataByID[ID].Captures[turnNumber] = Captures[ID]; --store Captures for this turn; this is easily retrievable by playerID, then by turn#
		-- print (ID,turnNumber,Attacks[ID],publicGameData.PRdataByID[ID].Attacks[turnNumber]);

		historicalTerritoryCount[ID] = intTerritoryCount_currentTurn;
		publicGameData.PRdataByID[ID].TerritoryCount[turnNumber] = intTerritoryCount_currentTurn; -- store TerritoryCount for this turn; this is easily retrievable by playerID, then by turn#

		intReward_attack = Attacks[ID] or 0; --Attacks[ID]~=nil and 1 or 0; --assign 0 Reward units for no attacks made, assign 1 unit for 1+ attacks made
		intPunishment_attack = 1 - intReward_attack; --assign 0 Punishment units for attacks made, assign 1 unit for no attacks made
		intReward_capture = Captures[ID] or 0; --Captures[ID]==nil and 1 or 0; --assign 0 Reward units for no captures made, assign 1 unit for 1+ captures made
		intPunishment_capture = 1 - intReward_attack; --assign 0 Punishment units for captures made, assign 1 unit for no attacks made

		-- reward = (Attacks[ID]~=nil and 1 or 0)*rewardIncrement + (Captures[ID]~=nil and 1 or 0)*rewardIncrement + intReward_territoryCount*rewardIncrement;
		-- punishment = (Attacks[ID]==nil and 1 or 0)*punishmentIncrement + (Captures[ID]==nil and 1 or 0)*punishmentIncrement + (TerritoryIncrease[ID]==nil and 1 or 0)*punishmentIncrement;
		local intIncome = player.Income (0, game.ServerGame.LatestTurnStanding, false, false).Total; --get player's income w/o respect to reinf cards, and wrt current turn & any applicable army cap + sanctions
-- 		intRewardTotalUnits = intReward_attack + intReward_capture + intReward_territoryCount;
-- 		intPunishmentTotalUnits = intPunishment_attack + intPunishment_capture + intPunishment_territoryCount;
-- 		intRewardIncome = math.floor (intRewardTotalUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
-- 		intPunishmentIncome = math.ceil (intPunishmentTotalUnits * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
-- print ("!"..intReward_attack, intReward_capture, intReward_territoryCount, intTerritoryCount_lastTurn, intTerritoryCount_currentTurn);
-- print ("!"..intPunishmentTotalUnits, punishmentIncrement, intPunishmentIncome, intPunishment_attack, intPunishment_capture, intPunishment_territoryCount);
		-- reward = (intReward_attack + intReward_capture + intReward_territoryCount) * rewardIncrement;
		-- punishment = (intPunishment_attack + intPunishment_capture + intPunishment_territoryCount) * punishmentIncrement;
		--for reference: Income(armiesFromReinforcementCards integer, standing GameStanding, bypassArmyCap boolean, ignoreSanctionCards boolean) returns PlayerIncome: Determine's a player's income (number of armies they receive per turn)

		--calculate Punishments and Rewards
		local incomeAdjustments = assessLongTermPunishment (publicGameData.PRdataByID [ID], game.Game.TurnNumber); --use actual current turn # b/c it just finished and should be included in the calculations
		intRewardIncome = math.floor (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
		intPunishmentIncome = math.ceil ((incomeAdjustments.LongTermPenalty + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
		local intNewIncome = intIncome + intRewardIncome + intPunishmentIncome;
		print ("LONG-TERM [ID " ..ID.. "] income penalty " ..incomeAdjustments.LongTermPenalty.. "PU, army reduction " ..incomeAdjustments.ArmyReduction.. "x, terr reduction " ..incomeAdjustments.TerritoryReduction.. "x, 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
		print ("CURR TURN [ID " ..ID.. "] income "..intIncome.." [new " ..intNewIncome.. "], punishment "..intPunishmentIncome.. " [" ..incomeAdjustments.CurrTurn.PunishmentUnits.. "PU], reward " ..intRewardIncome.. " [" ..incomeAdjustments.CurrTurn.RewardUnits.. "RU], isAttack "..tostring (incomeAdjustments.CurrTurn.Attacks)..", isCapture ".. tostring (incomeAdjustments.CurrTurn.Captures)..", terrInc "..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));

		addOrder (WL.GameOrderEvent.Create (ID, "Punishment!", {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome, "Punishment" .. intPunishmentIncome)})); --floor = round down for punishment
		addOrder (WL.GameOrderEvent.Create (ID, "Reward!",     {}, {}, {}, {WL.IncomeMod.Create(ID, intRewardIncome,     "Reward"     .. intRewardIncome)})); --ceiling = round up for reward
	end

	publicGameData.PRdataByTurn[turnNumber].TerritoryCount = historicalTerritoryCount; --store Captures for this turn; this is easily retrievable by turn#, then by playerID
	print ("htc count "..#historicalTerritoryCount);
	Mod.PublicGameData = publicGameData;

	--crashNow ();
end

--remove nil elements, set them to 0
function cleanElements (arrayToClean)
print ("PRE  CLEAN count ".. tablelength (arrayToClean));
	for k,v in pairs (arrayToClean) do
print ("PRE  CLEAN "..k, tostring (arrayToClean[k]));
		if arrayToClean[k]==nil then arrayToClean[k] = 0; end
print ("POST CLEAN "..k, tostring (arrayToClean[k]));
	end
	return arrayToClean;
end

function territoryCountAnalysis (game)
	local territoryCount = {};
	for ID,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if (terr.OwnerPlayerID>0) then
			if (territoryCount [terr.OwnerPlayerID] == nil) then territoryCount [terr.OwnerPlayerID] = 0; end
			territoryCount [terr.OwnerPlayerID] = territoryCount [terr.OwnerPlayerID] + 1;
			print ("playerID "..terr.OwnerPlayerID..", terr "..ID.."/"..getTerritoryName (ID, game)..", count "..territoryCount [terr.OwnerPlayerID]);
		end
	end
	return territoryCount;
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	return (game.Map.Territories[intTerrID].Name);
end

function Server_AdvanceTurn_Start(game,addOrder)
	--move these to PublicGameData
	disallowReverseSanctionsOnOthers = true;
	disallowNormalSanctionsOnSelf = true;

	--structure used for this turn order, initialize them to {} for each iteration
	Attacks = {};
	Captures = {};
	TerritoryIncrease = {};
end

function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)
	local playerID = order.PlayerID;
	if (order.proxyType~='GameOrderAttackTransfer') then
		if (order.proxyType ~= 'GameOrderEvent' or order.Message ~= "Mod skipped attack/transfer order") then
			print ("proxyType=="..order.proxyType.. ", player ".. order.PlayerID);
		end
	end

	if (order.proxyType=='GameOrderAttackTransfer') then
		--AttackTeammates boolean:, AttackTransfer AttackTransferEnum (enum):, ByPercent boolean:, From TerritoryID:, NumArmies Armies:, Result GameOrderAttackTransferResult:, To TerritoryID:
		--Result = ActualArmies Armies: The number of armies from the source territory that actually participated in the attack or transfer, AttackingArmiesKilled Armies:, DamageToSpecialUnits Table<Guid,integer>:, DefendingArmiesKilled Armies:, DefenseLuck Nullable<number>:, 
		--         IsAttack boolean: True if this was an attack, false if it was a transfer., IsNullified boolean:, IsSuccessful boolean: If IsAttack is true and IsSuccessful is true, the territory was captured. If IsAttack is true and IsSuccessful was false, the territory was not captured.
		--         OffenseLuck Nullable<number>:

		-- temp only; skip AI orders
		if (order.PlayerID<50) then skip(WL.ModOrderControl.Skip); return; end

		print ("[ATTACK/TRANSFER] PRE  from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
		", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");


		--track when a player has made an attack or capture
		if (result.IsAttack) then Attacks[playerID] = 1; end
		if (result.IsAttack and result.IsSuccessful) then Captures[playerID] = 1; end

		--&&& TODO: track damage done, in terms of # armies killed & amount of damage done to SUs (reduced health amount + damage-required-to-kill for killed SUs w/o health)

		print ("[ATTACK/TRANSFER] POST from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
		", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");

	elseif (order.proxyType == 'GameOrderEvent') then
		if (order.Message ~= "Mod skipped attack/transfer order") then print ("[EVENT] " ..order.Message); end
		if (order.AddCardPiecesOpt ~= nil) then print ("[-----card pieces]"); end
		-- if (order.Result.CardInstancesCreated ~= nil) then print ("[-----CardInstancesCreated card pieces]"); end
	elseif (order.proxyType == 'GameOrderPlayCardSanctions') then
		print ("[Sanction card] cast "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage);
		--print ("[game.Settings.Cards[WL.CardID.Sanctions] "..WL.CardID.Sanctions);
		--printObjectDetails (game.Settings.Cards[WL.CardID.Sanctions], "WL.CardGameSanctions", "WZ def obj");
		--for k,v in pairs(WL.CardGameSanctions) do print ("**"..k,v); end
		--printObjectDetails (order, "Sanction cards", "played card");
		--printObjectDetails (game.Settings.Cards[WL.CardID.Sanctions], "Sanction config", "Card settings");
		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage>=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
			print ("[Sanction card] self-sanction for +ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self for positive sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage<0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning other for reverse sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
			print ("[Sanction card] permitted sanction type");
		end
	end
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Helper function to convert a table to a string representation
local function tableToString(tbl, indent)
	if type(tbl) ~= "table" then
		return tostring(tbl)  -- Return the value as-is if it's not a table
	end
	indent = indent or ""  -- Indentation for nested tables
	indent = "";
	local result = "{" --"{\n"
	for k, v in pairs(tbl) do
		result = result .. indent .. "  " .. tostring(k) .. " = " .. tableToString(v, indent .. "  ") .. ","; --\n"
	end
	result = result .. indent .. "}"
	return result
end

-- Main function to print object details
function printObjectDetails(object, strObjectName, strLocationHeader)
	strObjectName = strObjectName or ""  -- Default blank value if not provided
	strLocationHeader = strLocationHeader or ""  -- Default blank value if not provided
	print("[" .. strLocationHeader .. "] object=" .. strObjectName .. ", tablelength==".. tablelength (object).."::");
	print("[proactive display attempt] value==" .. tostring(object));

	-- Early return if object is nil or an empty table
	if object == nil then
		print("[invalid/empty object] object==nil")
		return
	elseif type(object) == "table" and next(object) == nil then
		print("[invalid/empty object] object=={}  [empty table]")
		return
	end

	-- Handle tables
	if type(object) == "table" then
		-- Check and display readableKeys
		if object.readableKeys then
			for key, value in pairs(object.readableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [readablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
				else
					print("  [readablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[R]**readableKeys DNE")
		end

		-- Check and display writableKeys
		if object.writableKeys then
			for key, value in pairs(object.writableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [writablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
				else
					print("  [writablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[W]**writableKeys DNE")
		end

		-- Display all base properties of the table
		for key, value in pairs(object) do
			if key ~= "readableKeys" and key ~= "writableKeys" then  -- Skip already processed keys
				if type(value) == "table" then
					print("[base_table] key==" .. tostring(key) .. ":: value==" .. tableToString(value))
				else
					print("[base_value] key==" .. tostring(key) .. ":: value==" .. tostring(value))
				end
			end
		end
	else
		-- Handle non-table objects
		print("[not table] value==" .. tostring(object))
	end
end