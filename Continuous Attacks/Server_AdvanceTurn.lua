require("Manual_Attack");

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
function Server_AdvanceTurn_Order (game, order, result, skipThisOrder, addNewOrder)
	--check for dummy order; it triggers processing of the actual next iteration of the continous attack order
	--this is necessary for SU damage to correctly apply, b/c the only way to apply damage is to pass the damage in via result.DamageToSpecialUnits on a WZ attack order
	--however, the damage applies after the iteration of Server_AdvanceTurn_Order completes, and it updates the SU; if we use the SU to submit the next iteration of the continuous attack order, the SU will retain its pre-damage health value
	--thus the solution is:
		-- (A) process current iteration of continuous attack order --> SU damage can be seen and calculated, but it hasn't actually applied to the SU yet
		-- (B) insert dummy order + save actual order (includes SUs without any damage taken) and let Server_AdvanceTurn_Order complete --> SU damage is applied at this point
		-- (C) detect dummy order
		-- (D) rebuild the actual next iteration of the continuous attack order using the updated SU from the territory, skip the dummy order
		-- (E) let the actual next iteration of the continuous attack process normally & repeat until the continuous attack ends
	if (objSendForwardOrder ~= nil and order.proxyType == "GameOrderCustom" and order.Payload == "Continuous Attacks placeholder") then
		local newSUlist = {};
		local intNumNewSUs = 0;
		for k,v in pairs (objSendForwardOrder.NumArmies.SpecialUnits) do
			-- print ("@@@@@@@@@@1 "..k,v.ID,v.Name,v.Health)
			local getNewSU = findSpecialUnitOnTerritory (v.ID, game, objSendForwardOrder.From);
			-- table.insert (newSUlist, getNewSU);
			if (getNewSU ~= nil) then
				intNumNewSUs = intNumNewSUs + 1;
				newSUlist [intNumNewSUs] = getNewSU;
				-- print ("@@@@@@@@@@2 "..k,getNewSU.ID,getNewSU.Name,getNewSU.Health);
				-- objSendForwardOrder.NumArmies.SpecialUnits [k] = getNewSU;
				-- print ("@@@@@@@@@@3 "..k,objSendForwardOrder.NumArmies.SpecialUnits [k].ID,objSendForwardOrder.NumArmies.SpecialUnits [k].Name,objSendForwardOrder.NumArmies.SpecialUnits [k].Health);
				-- print ("@@@@@@@@@@4 "..intNumNewSUs,newSUlist [intNumNewSUs].ID, newSUlist [intNumNewSUs].Name, newSUlist [intNumNewSUs].Health);
				-- replaceSUwithAnotherSU 
			else
				-- print ("@@@@@@@@@@2/3/4 #" ..k.." == nil! [dead]");;
			end
		end
		-- objSendForwardOrder.NumArmies.SpecialUnits = newSUlist;
		-- objSendForwardOrder.NumArmies = WL.Armies.Create (objSendForwardOrder.NumArmies.NumArmies, newSUlist);
		-- print ("@@@@@@@@@@ RESULT #SUs "..#newSUlist);
		local newArmies = WL.Armies.Create (objSendForwardOrder.NumArmies.NumArmies, newSUlist);
		addNewOrder (WL.GameOrderAttackTransfer.Create (objSendForwardOrder.PlayerID, objSendForwardOrder.From, objSendForwardOrder.To, objSendForwardOrder.AttackTransfer, objSendForwardOrder.ByPercent, newArmies, objSendForwardOrder.AttackTeammates));
		-- addNewOrder (objSendForwardOrder);
		-- addNewOrder (order);
		-- skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		objSendForwardOrder = nil;
		return;
	end

	--boolProcessingContinuousAttackOrders is global variable to persist between orders; if nil set to false; if true then override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
	if (boolProcessingContinuousAttackOrders == nil) then boolProcessingContinuousAttackOrders = false; end

	-- local AttackPower = AttackingArmies.AttackPower;
	-- local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	-- local AttackDamage = math.floor (AttackPower * game.Settings.OffenseKillRate * totalAttackerAttackPowerPercentage + 0.5);
	-- local DefenseDamage = math.floor (DefensePower * game.Settings.DefenseKillRate * totalDefenderDefensePowerPercentage + 0.5);

	if (order.proxyType == 'GameOrderAttackTransfer') then
		if (boolProcessingContinuousAttackOrders == true) then
			print ("[[[[CONTINUOUS ATTACK]]]] order.NumArmies.NumArmies");
			result.ActualArmies = order.NumArmies; --override the ActualArmies with what was specified as the attacking ones (b/c WZ will prevent them from double moving otherwise)
			-- result.AttackingArmiesKilled = WL.Armies.Create (math.floor (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5), {});
			-- result.DefendingArmiesKilled = WL.Armies.Create (math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5), {});

			local manualAttackResult = process_manual_attack (game, result.ActualArmies, game.ServerGame.LatestTurnStanding.Territories[order.To], result, addNewOrder, true);
			--reference: function process_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder, boolWZattackTransferOrder)
			result.AttackingArmiesKilled = manualAttackResult.AttackingArmiesKilled;
			result.DefendingArmiesKilled = manualAttackResult.DefendingArmiesKilled;
			result.DamageToSpecialUnits = manualAttackResult.DamageToSpecialUnits; --assign array of tables {GUIDs & damage integers} to apply damge to the SUs as part of the WZ attack order
			-- print ("_____SU damage: # " ..#result.DamageToSpecialUnits.. ", GUID " ..result.DamageToSpecialUnits[1].GUID.. ", damage to #1: " ..result.DamageToSpecialUnits[1].)
			for k,v in pairs (result.DamageToSpecialUnits) do print ("___________[SU damage] SU "..k..", damage "..v); end
			-- if (#result.ActualArmies.SpecialUnits > 0) then print ("[[SU count " ..#result.ActualArmies.SpecialUnits, result.ActualArmies.SpecialUnits[1].ID,result.ActualArmies.SpecialUnits[1].Name,result.ActualArmies.SpecialUnits[1].Health.. "]]"); end
			boolProcessingContinuousAttackOrders = false;
		end

		local intRemainingAttackingArmies = result.ActualArmies.NumArmies - result.AttackingArmiesKilled.NumArmies;
		local intRemainingDefendingArmies = game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies - result.DefendingArmiesKilled.NumArmies;
		local intRemainingAttackingSUs = #result.ActualArmies.SpecialUnits - #result.AttackingArmiesKilled.SpecialUnits;
		local intRemainingDefendingSUs = #game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits - #result.DefendingArmiesKilled.SpecialUnits;

		print ("\n[[  ATTACK // TRANSFER ]] PRE  player " ..order.PlayerID.. "/" ..getPlayerName (game, order.PlayerID).. ", FROM "..order.From.."/"..getTerritoryName (order.From, game)..", TO "..order.To.."/"..getTerritoryName (order.To, game) ..
			", numArmies " ..order.NumArmies.NumArmies.. ", actualArmies " ..result.ActualArmies.NumArmies.. ", ByPercent " ..tostring (order.ByPercent).. ", isAttack " ..tostring(result.IsAttack).. ", isSuccessful " ..tostring(result.IsSuccessful)..
			", #SUs attacking " ..#order.NumArmies.SpecialUnits..", Actual #SUs attacking "..#result.ActualArmies.SpecialUnits..
			", #defenderArmies " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.NumArmies.. ", #defenderSUs " ..#game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.SpecialUnits..
			", attackPower " ..result.ActualArmies.AttackPower.. ", defensePower " ..game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower..
			", attackDamage " ..(result.ActualArmies.AttackPower * game.Settings.OffenseKillRate).. ", defenseDamage " ..(math.floor (game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5)).. "/"  ..(game.ServerGame.LatestTurnStanding.Territories [order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate)..
			", AttackingArmiesKilled " ..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled " ..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled "..#result.DefendingArmiesKilled.SpecialUnits..
			", Remaining attacking armies " ..intRemainingAttackingArmies.. ", Remaining defending armies " ..intRemainingDefendingArmies.. 
			", Remaining attacking SUs " ..intRemainingAttackingSUs.. ", Remaining defending SUs " ..intRemainingDefendingSUs);
		local newArmies = WL.Armies.Create (intRemainingAttackingArmies, result.ActualArmies.SpecialUnits);

		--this value being >0 determines whether any damage was done during the attack to attackers defenders or both; value ==0 indicates no damage was sustained by either side
		--if any armies died, any SUs died or any SUs took any damage, continue the continuous attacks
		local intDamageTakenIndicator = result.AttackingArmiesKilled.NumArmies + result.DefendingArmiesKilled.NumArmies + #result.AttackingArmiesKilled.SpecialUnits + #result.DefendingArmiesKilled.SpecialUnits + #result.DamageToSpecialUnits;

		--if damage was done AND there are remaing attackers (armies or SUs) AND there are remaining defenders (armies or SUs), continue the continuous attack
		--if no damage was done -- stalemate, don't loop infinitely; if no attacks remain -- attack failed, can't continue attacking; if no defenders remain -- attack succeeded, territory is captured
		if ((intDamageTakenIndicator > 0) and (intRemainingAttackingArmies + intRemainingAttackingSUs > 0) and (intRemainingDefendingArmies + intRemainingDefendingSUs > 0)) then
		-- if ((result.AttackingArmiesKilled.NumArmies + result.DefendingArmiesKilled.NumArmies + #result.AttackingArmiesKilled.SpecialUnits + #result.DefendingArmiesKilled.SpecialUnits > 0) and (intRemainingAttackingArmies + intRemainingAttackingSUs > 0) and (intRemainingDefendingArmies + intRemainingDefendingSUs > 0)) then
			print ("---> !! CONTINUE THE ATTACK ---> ---> ---> ---> ---> armies " ..newArmies.NumArmies.. ", #SUs " ..#newArmies.SpecialUnits);
			-- addNewOrder (WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates));
			objSendForwardOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newArmies, order.AttackTeammates);

			--check for infinite loop condition - this can happen when a turn that causes a continuous attack condition is repeatedly skipped, eg: when using Forced Orders which cancels the orders, thus making it appear like it can repeat the attack
			if intInfiniteLoopStopper == nil then intInfiniteLoopStopper = 0; end
			intInfiniteLoopStopper = intInfiniteLoopStopper + 1;
			if (intInfiniteLoopStopper > 100) then
				-- addNewOrder (WL.GameOrderCustom.Create ({order.PlayerID, "Continuous Attack - potential infinite loop; ending this attack cycle", {}));
				addNewOrder (WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Continuous Attack - potential infinite loop; ending this attack cycle"));
				print ("#################### Continuous Attack - potential infinite loop; ending this attack cycle");
				-- crashMe.Now(); end
				intInfiniteLoopStopper = 0; --reset for the next continuous attack cycle; only abort the current cycle, not all going forward for this turn
				return; --don't process this continuous attack stream any further
			else
				--if not in an infinite loop, continue the continuous attack cycle
				addNewOrder (WL.GameOrderCustom.Create (order.PlayerID, "Continuous Attacks placeholder", "Continuous Attacks placeholder")); --insert dummy order to trigger processing of the actual next iteration of the continous attack order
				boolProcessingContinuousAttackOrders = true;
			end
		else
			print ("---> __ END THE ATTACK\n");
		end
	end
end

---Server_AdvanceTurn_Start hook
---@param game GameServerHook
---@param addNewOrder fun(order: GameOrder) # Adds a game order, will be processed before any of the rest of the orders
function Server_AdvanceTurn_Start (game, addNewOrder)
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<0) then return ("fogged");
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

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

function printDebug (strText)
	-- print (strText);
end

function replaceSUwithAnotherSU (SUlist, SUtoAdd, SUtoReplace)
	for k,v in pairs (SUlist) do
		if (v.ID == SUtoReplace.ID) then
			SUlist[k] = SUtoAdd;
			return SUlist;
		end
	end
	return SUlist;
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
function getDefinedCardList (game)
    local count = 0;
    local cards = {};
	local publicGameData = Mod.PublicGameData;

	--if CardData structure isn't defined (eg: from an ongoing game before this was done this way), then initialize the variable and populate the list here
	if (publicGameData.CardData==nil) then publicGameData.CardData = {}; publicGameData.CardData.DefinedCards = nil; end

	--if (false) then --publicGameData.CardData.DefinedCards ~= nil) then
	if (publicGameData.CardData.DefinedCards ~= nil) then
		return publicGameData.CardData.DefinedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
	else
		if (game==nil) then print ("game is nil"); return nil; end
		if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
		if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			cards[cardID] = strCardName;
			count = count +1
		end
		return cards;
	end
end

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function playerHasCard (playerID, cardID, game)
	if (playerID<=0) then print ("playerID is neutral (has no cards)"); return nil; end
	if (cardID==nil) then print ("cardID is nil"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID]==nil) then print ("PLAYER CARDS nil"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards) do
		if (v.CardID == tonumber(cardID)) then print (k); return k; end
	end
	return nil;
end

function getCardName_fromObject(cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
    if cardConfig.proxyType == 'CardGameCustom' then
        return cardConfig.Name;
    end

    if cardConfig.proxyType == 'CardGameAbandon' then
        -- Abandon card was the original name of the Emergency Blockade card
        return 'Emergency Blockade card';
    end
    return cardConfig.proxyType:match("^CardGame(.*)");
end

--find & return an SU object given its GUID and territory location
function findSpecialUnitOnTerritory (specialUnitID, game, terrID)
	print ("fsu, find=="..specialUnitID);
	terr = game.ServerGame.LatestTurnStanding.Territories [terrID];
	--print ("terr.ID=="..terr.ID..", #specials==".. (#terr.NumArmies.SpecialUnits));
	if (#terr.NumArmies.SpecialUnits >= 1) then
		for _,specialUnit in pairs (terr.NumArmies.SpecialUnits) do
			--print ("1 special on "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
			--printObjectDetails (specialUnit, "[FSU]", "specialUnit details");
			if (specialUnitID == specialUnit.ID) then
				-- print ("FOUND @ "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
				-- print ("FOUND -- "..specialUnit.ID, specialUnit.Name, specialUnit.Health);
				return (specialUnit);
			end
		end
	end
	return nil;
end