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

	if (order.proxyType=='GameOrderAttackTransfer') then
		--AttackTeammates boolean:, AttackTransfer AttackTransferEnum (enum):, ByPercent boolean:, From TerritoryID:, NumArmies Armies:, Result GameOrderAttackTransferResult:, To TerritoryID:
		--Result = ActualArmies Armies: The number of armies from the source territory that actually participated in the attack or transfer, AttackingArmiesKilled Armies:, DamageToSpecialUnits Table<Guid,integer>:, DefendingArmiesKilled Armies:, DefenseLuck Nullable<number>:, 
		--         IsAttack boolean: True if this was an attack, false if it was a transfer., IsNullified boolean:, IsSuccessful boolean: If IsAttack is true and IsSuccessful is true, the territory was captured. If IsAttack is true and IsSuccessful was false, the territory was not captured.
		--         OffenseLuck Nullable<number>:

		-- temp only; skip AI orders
		if (order.PlayerID<50) then skip(WL.ModOrderControl.Skip); return; end

		print ("[ATTACK/TRANSFER] PRE  from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
		", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");

		--if Limited MultiAttack is enabled & move is a transfer, cancel the order & magically move the units to the destination - this should overrule the built-in WZ rule to halt transfers
		if (order.proxyType=='GameOrderAttackTransfer' and result.IsAttack == false and game.ServerGame.LatestTurnStanding.Territories[order.From].OwnerPlayerID == order.PlayerID) then --this is not an attack -> it's a transfer
			--worry about specials later, just do armies right now
			local intNumArmiesToTransfer = result.ActualArmies.NumArmies;
			local fromTerritory = WL.TerritoryModification.Create(order.From);
			local toTerritory = WL.TerritoryModification.Create(order.To);
			local modifiedTerritories = {};
			fromTerritory.AddArmies = -1 * intNumArmiesToTransfer; --remove armies from FROM territory
			toTerritory.AddArmies   =      intNumArmiesToTransfer; --add armies to TO territory
			table.insert (modifiedTerritories, fromTerritory);
			table.insert (modifiedTerritories, toTerritory);
			local event = WL.GameOrderEvent.Create(order.PlayerID, "code moved "..intNumArmiesToTransfer.." armies from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game), {}, modifiedTerritories);
			addOrder(event, false);
			skip(WL.ModOrderControl.Skip); --cancel orig attack, b/c it'd stop the MA operations; hopefully this will let it continue indefinitely
		end

		--testing order adjustment/replacement; replace an attack order of 10 armies with one for 5 armies
		--[[if (order.NumArmies.NumArmies==10) then
			--local numArmies = orderArmies.Subtract(WL.Armies.Create(0, commanders));
			local newOrder = nil;
			print ("[TRIP!] "); --..order.ByPercent);
			--newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(3), order.AttackTeammates);
			newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(5), order.AttackTeammates);
			addOrder(newOrder);
			skip(WL.ModOrderControl.Skip);
			return;
	
			--if isAttackTransfer then
			--	newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, numArmies, order.AttackTeammates);
			--elseif isAirlift then
			--	newOrder = WL.GameOrderPlayCardAirlift.Create(order.CardInstanceID, order.PlayerID, order.FromTerritoryID, order.ToTerritoryID, numArmies);
			--end
		end]]

		if (#order.NumArmies.SpecialUnits>0) then
			--local numArmies = orderArmies.Subtract(WL.Armies.Create(0, commanders));
			local newOrder = nil;
			print ("[TRIP!] _________________________________"); --..order.ByPercent);
			--newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(3), order.AttackTeammates);
			--newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, WL.Armies.Create(order.NumArmies.NumArmies), order.AttackTeammates);
			--addOrder(newOrder);
			--skip(WL.ModOrderControl.Skip);

			--remove commander = dies?
			local impactedTerritory = WL.TerritoryModification.Create(order.From);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
			local specialUnitID = nil;
			specialUnitID = order.NumArmies.SpecialUnits[1].ID;
			print ("terr=="..order.From..", SUID=="..specialUnitID);
			impactedTerritory.RemoveSpecialUnitsOpt = {specialUnitID}; --remove the C special unit from the territory
			--impactedTerritory.SetOwnerOpt=impactedTerritoryOwnerID;
			--local strDeneutralizeOrderMessage = toPlayerName(gameOrder.PlayerID, game) ..' deneutralized ' .. targetTerritoryName .. ', assigned to '..impactedTerritoryOwnerName;
			--print ("message=="..strDeneutralizeOrderMessage);
			local event = WL.GameOrderEvent.Create(order.PlayerID, "remove C", {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
			addOrder (event, false); --add a new order; call the addOrder parameter (which is in itself a function) of this function
			print ("[END]");
			skip(WL.ModOrderControl.Skip);

			return;
	
			--if isAttackTransfer then
			--	newOrder = WL.GameOrderAttackTransfer.Create(order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, numArmies, order.AttackTeammates);
			--elseif isAirlift then
			--	newOrder = WL.GameOrderPlayCardAirlift.Create(order.CardInstanceID, order.PlayerID, order.FromTerritoryID, order.ToTerritoryID, numArmies);
			--end
		end

		if (result.IsAttack) then Attacks[playerID] = true; end
		if (result.IsAttack and result.IsSuccessful) then Captures[playerID] = true; end

		--just for testing (actually for CCPA Quicksand)
		--result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5), result.AttackingArmiesKilled.SpecialUnits);
		--result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5), result.DefendingArmiesKilled.SpecialUnits);
			
			print ("[ATTACK/TRANSFER] POST from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
			", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");
			print ("[SPECIALS:]");
			for k,v in pairs (result.DamageToSpecialUnits) do print ("damage to special "..k..", amount "..v.."::"); end
		
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