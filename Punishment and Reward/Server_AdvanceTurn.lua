--[[
TODO:
- implement territory count punishment/rewards
- implement tracking territory count for X turns (default 10) apply rolling increasing pun/rew for increases/decreases in the past 10 turns; decrease = nerf, increase = buff, no change = small nerf
- implement Sanction/Reverse Sanction casting limitations; on self YES/NO, on teammate YES/NO
- anti-card farming
]]

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E]::func start");

	--move these initializations to Server_Create or somewhere else
	--these are used to track the past 10 (make configurable) turns to apply cumulative averages, not just immediate data from the current turn
	if (historicalAttacks==nil) then historicalAttacks = {}; end;
	if (historicalCaptures==nil) then historicalCaptures = {}; end;
	if (historicalTerritoryCount==nil) then historicalTerritoryCount = {}; end;
	numTurnsToTrack = 10; --track average values over 10 turns (make configurable)

	for ID,player in pairs (game.ServerGame.Game.PlayingPlayers) do
		local reward = 0;
        local punishment = 0;
		local rewardIncrement = 0.1;
		local punishmentIncrement = -0.05;

		reward = (Attacks[ID]~=nil and 1 or 0)*rewardIncrement + (Captures[ID]~=nil and 1 or 0)*rewardIncrement + (TerritoryIncrease[ID]~=nil and 1 or 0)*rewardIncrement;
        punishment = (Attacks[ID]==nil and 1 or 0)*punishmentIncrement + (Captures[ID]==nil and 1 or 0)*punishmentIncrement + (TerritoryIncrease[ID]==nil and 1 or 0)*punishmentIncrement;
        local income = player.Income(0, game.ServerGame.LatestTurnStanding, false, false).Total;

		print ("ID "..ID..", income="..income..", punishment="..punishment..", reward="..reward..", isAttack=="..tostring (Attacks[ID]~=nil)..", isCapture==".. tostring (Captures[ID])..", terrInc=="..tostring (TerritoryIncrease[ID]).."::");
		addOrder (WL.GameOrderEvent.Create (ID, "Punishment!", {}, {}, {}, {WL.IncomeMod.Create(ID, math.floor(income*punishment), "Punishment" .. math.floor(income*punishment))})); --floor = round down when negative (punishment)
		addOrder (WL.GameOrderEvent.Create (ID, "Reward!", {}, {}, {}, {WL.IncomeMod.Create(ID, math.ceil(income*reward), "Reward" .. math.ceil(income*reward))})); --ceiling = round up (positive #'s)
	end

	table.insert (historicalTerritoryCount, territoryCountAnalysis (game));
	print ("count "..#historicalTerritoryCount); --if length surpasses numTurnsToTrack, pop off a record (or just keep it all and just average over numTurnsToTrack? yea do that for now; actually that means have to count from end to end-numTurnsToTrack = not ideal)
    --crashNow ();
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
	--print ("proxyType=="..order.proxyType);
    if (order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack) then Attacks[playerID] = true; end
	if (order.proxyType == 'GameOrderAttackTransfer' and result.IsAttack and result.IsSuccessful) then Captures[playerID] = true; end

	if (order.proxyType=='GameOrderAttackTransfer') then
		--AttackTeammates boolean:, AttackTransfer AttackTransferEnum (enum):, ByPercent boolean:, From TerritoryID:, NumArmies Armies:, Result GameOrderAttackTransferResult:, To TerritoryID:
		--Result = ActualArmies Armies: The number of armies from the source territory that actually participated in the attack or transfer, AttackingArmiesKilled Armies:, DamageToSpecialUnits Table<Guid,integer>:, DefendingArmiesKilled Armies:, DefenseLuck Nullable<number>:, 
		--         IsAttack boolean: True if this was an attack, false if it was a transfer., IsNullified boolean:, IsSuccessful boolean: If IsAttack is true and IsSuccessful is true, the territory was captured. If IsAttack is true and IsSuccessful was false, the territory was not captured.
		--         OffenseLuck Nullable<number>:

		--result.DefendingArmiesKilled.NumArmies=0;
		print ("[ATTACK/TRANSFER] PRE  from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
			", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");

		result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5));
		result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5));
			
			print ("[ATTACK/TRANSFER] POST from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
			", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");

	end

    if (order.proxyType == 'GameOrderPlayCardSanctions') then
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