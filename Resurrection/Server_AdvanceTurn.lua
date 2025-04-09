--[[
WORKING:
- identify Commander kills, prevent death for both ATTACKER & DEFENDER
- use Card play to redeploy C; choose territory
- only save Commander if player holds a Resurrection card
- redeploy C on TurnAdvance
- player still loses when Commander is saved (killed but has Res card) but he has no territories left (regular elimination) - nowhere to Resurrect to, so this is logical
- auto-popup in Game_Refresh & Game_Commit
- if player doesn't deploy or boots - auto-deploy to first player owned territory on the map; if no territories left, then Eliminated
- ^^ in this case, consume Resurrection card when complete
- enforce card play only when a Commander dies
- ^^ unless this setting is enabled

STILL TO DO:
- indicate what territory the C died only
- adjust popup & suppressor (# of clicks) to be turn based; 1 client session continuing = keeps counting the clicks and never shows alert again (oops) -- do for pesti too?
- also don't popup if committed already
]]

--nothing is done in this function
function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E] START");

	if (Mod.PublicGameData.ResurrectionData ~= nil) then
		if (next (Mod.PublicGameData.ResurrectionData) ==nil) then print ("[S_AT_E] 0 length table - no Pending Resurrections"); end
		for k,v in pairs (Mod.PublicGameData.ResurrectionData) do
			print ("[S_AT_E] Resurrection DATA: "..k,v);
		end
	else
		print ("[S_AT_E] No pending Resurrections (nil)");
	end
	print ("[S_AT_E] END");
	--crashHereNowPlease ();
end

--actual Resurrections are executed here
function Server_AdvanceTurn_Start(game,addOrder)
	print ("[S_AT_S] START - - - - - - - - - - - - - - Turn #"..game.Game.TurnNumber.."::");
	--[[for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		print ("____"..k.."/"..game.Map.Territories[k].Name..", "..v.OwnerPlayerID);
	end]]

	--print ("player 1 :: "..game.Game.Players[1].DisplayName(nil, false).."::");
	process_pending_Resurrections (game, addOrder);
	print ("[S_AT_S] END".."::");
end

--killed Commanders by players with Resurrection cards are detected & handled here (to set up to a player can play the Resurrection card & resurrect the Commander on the following turn)
function Server_AdvanceTurn_Order (game,order,result,skip,addOrder)
	--print ("[S_AT_O] proxyType==" ..order.proxyType.."::");
	check_for_Resurrection_conditions_and_execute_preparation (game,order,result,skip,addOrder);
end

function process_pending_Resurrections (game, addOrder)
	--perform actual resurrections here, ie: bring the killed Commanders to be resurrected back into the game at this point
	--if at end of this function any player still has a pending Resurrection, they didn't play the card and place their Commander, so just pick a territory of theirs and place it there

	--implement the user planned Resurrections, ie: user played a card this turn and placed their Commander on a territory of their choosing
	if (game.ServerGame.ActiveTurnOrders==nil) then
		print ("[PPR1] No orders");
	else
		--note: processing orders here from Server_AdvancedTurn_Start is different than from Server_AdvancedTurn_Order
		--instead of each order from all players intermingled in the resulting execution order, the orders are the full set of orders of each player in a separate table (array) each
		--the game.ServerGame.ActiveTurnOrders table is: (key) playerID & (value) array of orders for that player
		for k,orderArray in pairs (game.ServerGame.ActiveTurnOrders) do
			print ("[PPR1] ORDERS for player "..k.."/"..tostring(orderArray.proxyType) .." qty "..#orderArray);
			for k2,order in pairs (orderArray) do
				print ("[PPR1] ORDERS "..k.."/"..k2.."/"..tostring(order.proxyType));
				execute_userImplemented_Resurrections (game, order,addOrder);
			end
		end
	end

	--any still pending Resurrections indicate that the player didn't playt the Resurrection card to generate the Resurrection order; maybe they just didn't play the card despite the warnings, maybe they booted, maybe it's an AI, etc
	--so just pick a territory and place the Commander there
	if (Mod.PublicGameData.ResurrectionData ~= nil) then
		for playerID,v in pairs (Mod.PublicGameData.ResurrectionData) do
			print ("[PPR2] user didn't play Resurrection card but has pending Resurrection order;  player "..playerID.."/"..tostring (v));
			local territoryID = getTerritoryBelongToPlayer (game, playerID);
			print ("[PPR2] Resurrect Commander for player "..playerID.." to territory "..tostring(territoryID).."/"..game.Map.Territories[territoryID].Name);
			replace_Commander_on_map (game, playerID, territoryID, addOrder, true); --last param indictes to consume a Resurrection card, b/c the user didn't play one during turn input, and this is being played automatically for the player
		end
	end
end

--return first territoryID belong to playerID; if none exist, return nil
function getTerritoryBelongToPlayer (game, playerID)
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		if (v.OwnerPlayerID==playerID) then return k; end
	end
	return nil;
end

--this function places a Resurrected Commander back on the map
function execute_userImplemented_Resurrections (game, order, addOrder)
	--ModData for GameOrderPlayCardCustom, Payload for GameOrderCustom
	if ((order.proxyType == "GameOrderPlayCardCustom") and (startsWith(order.ModData, 'Resurrection|'))) then
		print ("[RESURRECTION EXECUTE] place Commander");
		local payloadContent = split(order.ModData, "|");
		local playerID = tonumber (payloadContent [2]);
		local territoryID = tonumber (payloadContent [3]);
		replace_Commander_on_map (game, playerID, territoryID, addOrder, false); --last param indicates to NOT consume a Resurrection card (b/c it was already consumed when the player played it during turn input)

		if (Mod.PublicGameData.ResurrectionData ~= nil) then
			for playerID,v in pairs (Mod.PublicGameData.ResurrectionData) do
				print ("[RESURRECTION EXECUTE] POST user didn't play Resurrection card but has pending Resurrection order;  player "..playerID.."/"..tostring (v));
			end
		end
	end
end

--this function is called from (A) execute_userImplemented_Resurrections when players correctly played a Resurrection card this turn and chose themselves which territory to resurrect to
-- or (B) from process_pending_Resurrections when players didn't play a Resurrection card and a territory to resurrect to was picked for them
function replace_Commander_on_map (game, playerID, territoryID, addOrder, boolConsumeResurrectionCard)
	local specialUnit = WL.Commander.Create(playerID);
	local impactedTerritory = WL.TerritoryModification.Create(territoryID);
	impactedTerritory.AddSpecialUnits = {specialUnit};

	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- if (playerID == nil or playerID <= 0) then playerID = 1552145; end
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 

	print ("[RESURRECTION PLACE ON MAP] player "..tostring(playerID).."/".. getPlayerName (game, playerID)..", terr "..tostring(territoryID).."/"..game.Map.Territories[territoryID].Name.."::");
	local strResurrectionMsg = getPlayerName (game, playerID) .. " resurrects a Commander to " .. game.Map.Territories[territoryID].Name;
	print (strResurrectionMsg);
	local event = WL.GameOrderEvent.Create (playerID, strResurrectionMsg, {}, {impactedTerritory});

	--consume 1 wholecard of Resurrection iff boolConsumeResurrectionCard is set to true
	if (boolConsumeResurrectionCard) then
		print ("[RESURRECTION PLACE ON MAP] consume Resurrection wholecard b/c auto-playing card for player");
		local CommanderOwner_ResurrectionCard = playerHasCard (playerID, Mod.Settings.ResurrectionCardID, game); --get card instance ID of player's Resurrection card
		if (CommanderOwner_ResurrectionCard~=nil) then
			event.RemoveWholeCardsOpt = {[playerID] = CommanderOwner_ResurrectionCard};
		else
			print ("[RESURRECTION PLACE ON MAP] failed to get card instance of Resurrection card, can't consume whole card piece");
		end
	else
		print ("[RESURRECTION PLACE ON MAP] do not consume Resurrection wholecard b/c player played card themselves");
	end

	addOrder (event, false); --add the order containing the placement of the Commander on the map & if appropriate consumption of the Resurrection card (if player didn't play it himself and it is being played on their behalf automatically)

	--update ResurrectionData (remove the pending Resurrection for this player from the table)
	local publicGameData = Mod.PublicGameData;
	if (publicGameData.ResurrectionData==nil) then publicGameData.ResurrectionData = {}; end
	publicGameData.ResurrectionData[playerID] = nil; --clear the Resurrection data for this player
	Mod.PublicGameData = publicGameData;
end

--this function handles the check to see (A) if a Commander has died, and (B) if the player has a resurrection card
--if (A) and (B) then save the Commander so can be Resurrected next turn
--if (A) but not (B) then let the Commander die
--this function is called once for the Defending special units killed & once for the Attacking special units killed
function process_resurrection_Checks_and_Preparation (game, playerID, ArmiesKilled_SpecialUnits, targetTerritoryID, addOrder)
	local placeholderCommanderUnits = {};
	for k,sp in pairs (ArmiesKilled_SpecialUnits) do
		if (sp.proxyType == "Commander") then --if not a Commander, don't do anything
			local Commander_OwnerID = sp.OwnerID; --check owner of Commander, not the territory -- in case a foreign Commander is being killed on someone else's territory (don't check or consume the Resurrection card of the territory owner)
			local CommanderOwner_ResurrectionCard = playerHasCard (Commander_OwnerID, Mod.Settings.ResurrectionCardID, game);
			-- check if Commander_OwnerID holds a Resurrection card; note: don't check for owner of order.To just in case the Commander of another player exists on the territory
			print ("Defender -- SP killed: "..k, sp.proxyType.."; on territory "..targetTerritoryID.."/"..game.Map.Territories[targetTerritoryID].Name..", territory owner "..tostring (playerID).."/"..getPlayerName (game, playerID) ..", SP owner "..Commander_OwnerID.. "/".. getPlayerName (game, Commander_OwnerID)..", SP owner ResCard=="..tostring(CommanderOwner_ResurrectionCard).."::");
			if (CommanderOwner_ResurrectionCard ~= nil) then
				--Commander dies during this order, but we can't be sure that the order won't be canceled by another mod (eg: Quicksand, Isolation, etc), but if order isn't canceled, must remove Commander from the territory else the player will be eliminated despite have a Resurrection
				--card in hand. SOLUTION: remove the true Commander, add a placeholder Commander, add a custom order that checks if the placeholder Commander has been killed or not; if so, order wasn't canceled, Commander really died, need to resurrect the Commander; 
				--if order was canceled, Commander doesn't die, remove the placeholder Commander, replace the real Commander and do not resurrect the Commander
				print ("[RESURRECTION CHECK & PREP] player has Res card - process Resurrection prep");
				local targetTerritory = WL.TerritoryModification.Create(targetTerritoryID);
				targetTerritory.RemoveSpecialUnitsOpt = {sp.ID}; --remove the C special unit from the territory
				table.remove (ArmiesKilled_SpecialUnits, k); --remove the Commander from the list of specials being killed
				replacementOrderRequired = true; --rewrite the original order without the dying Commander in place @ end of function
				local replacementCommander = build_specialUnit (game, addOrder, targetTerritoryID, "Placeholder Commander", "resurrection_commander.png", 7, 7, nil, nil, nil, 7, nil, 10000, false, false, true, false, false, "Placeholder Commander for Resurrection requirement confirmation");
				targetTerritory.AddSpecialUnits = {replacementCommander}; --add placeholder Commander to the territory; if this unit dies, then Resurrection occurs; if this unit is still alive next order, cancel Resurrection & replace the original Commander
				--local event = WL.GameOrderEvent.Create (Commander_OwnerID, "Commander on "..game.Map.Territories[targetTerritoryID].Name.." may have been killed", {}, {targetTerritory}); -- create Event object to send back to addOrder function parameter
				local event = WL.GameOrderEvent.Create (Commander_OwnerID, "[spirits are restless]", {}, {targetTerritory}); -- create Event object to send back to addOrder function parameter
				--local event = WL.GameOrderEvent.Create (Commander_OwnerID, "Commander on "..game.Map.Territories[targetTerritoryID].Name.." was killed, but their spirit was whisked away", {}, {targetTerritory}); -- create Event object to send back to addOrder function parameter
				event.JumpToActionSpotOpt = WL.RectangleVM.Create (game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
				--addOrder (event, false); --add order to remove the Commander from the TO territory & jump to location
				--GLOBAL_order_swapPlaceholderIn = event;
				table.insert (GLOBAL_table_orders_swapPlaceholderIn, event);
				local strPlaceholderCommanderMsg = "Resurrection|Placeholder-Check|"..Commander_OwnerID.."|"..targetTerritoryID.."|"..replacementCommander.ID.."|"..CommanderOwner_ResurrectionCard;
				--&&& if this placeholder belongs to the attacker, must add it to the attacking armies to be included in the replacement order

				table.insert (GLOBAL_table_orders_checkPlaceholder, WL.GameOrderCustom.Create (Commander_OwnerID, "Resurrection|Placeholder-Check", strPlaceholderCommanderMsg));
				table.insert (placeholderCommanderUnits, replacementCommander);

				--&&& technically here could be multiple orders of this kind if multiple Commanders die in this single order; actually need to create a table or orders and submit them all in sequence to check against the placeholder Commanders for each actual Commander
				--but these placeholder-check orders need to be submitted after the replacement order is placed; and the replacement order must have the placeholder included in the attacks in place of the original commanders

				--addOrder (GLOBAL_order_replacementOrder, false); --create custom order to check for placeholder Commander
				--addOrder (WL.GameOrderCustom.Create (Commander_OwnerID, "Resurrection|Placeholder-Check", strPlaceholderCommanderMsg), false); --create custom order to check for placeholder Commander
				print ("\n\n\n[PRCAP] ".. strPlaceholderCommanderMsg);

				--save data in PublicGameData to be retrieved in Client_GameRefresh & Client_GameCommit so player can place Commander on the board
				-- local publicGameData = Mod.PublicGameData;
				-- if (publicGameData.ResurrectionData == nil) then publicGameData.ResurrectionData = {}; end
				-- publicGameData.ResurrectionData[Commander_OwnerID] = game.Game.TurnNumber+1; --assign the turn# where the Resurrection card must be played (1 turn directly following death of Commander)
				-- Mod.PublicGameData = publicGameData;
			else
				print ("[RESURRECTION] player doesn't have Resurrection card - let the Commander die");
			end
		end
	end
	return (placeholderCommanderUnits);
end

--create a new special unit
function build_specialUnit (game, addOrder, targetTerritoryID, Name, ImageFilename, AttackPower, DefensePower, AttackPowerPercentage, DefensePowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, Health, CombatOrder, CanBeGiftedWithGiftCard, CanBeTransferredToTeammate, CanBeAirliftedToSelf, CanBeAirliftedToTeammate, IsVisibleToAllPlayers, ModData)
    local builder = WL.CustomSpecialUnitBuilder.Create (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID);
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
	-- local terrMod = WL.TerritoryModification.Create(targetTerritoryID)
	-- terrMod.AddSpecialUnits = {specialUnit}
	-- addOrder(WL.GameOrderEvent.Create(game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID, Name.." special unit created", {}, {terrMod}), false);
	return specialUnit;
end

--this function handles receiving notifications from other mods (eg: Airstrike) indicating that a Commander has died in an attack while the Commander owner player holds a Resurrection card
--thus, that player should be prepped for the Resurrection sequence
function process_resurrection_InvokeFromAnotherMod (game, playerID, addOrder)
	local Commander_OwnerID = playerID; --this is owner of Commander, not the territory -- in case a foreign Commander is being killed on someone else's territory (don't check or consume the Resurrection card of the territory owner)
	local CommanderOwner_ResurrectionCard = playerHasCard (Commander_OwnerID, Mod.Settings.ResurrectionCardID, game);

	-- print ("[RESURRECTION INVOCATION FROM OTHER MOD] player "..playerID.."/"..getPlayerName (game, playerID)..", territory "..targetTerritoryID.."/"..game.Map.Territories[targetTerritoryID].Name..", Commander owner ResCard "..tostring (CommanderOwner_ResurrectionCard));
	print ("[RESURRECTION INVOCATION FROM OTHER MOD] player "..tostring (playerID));
	print ("[RESURRECTION INVOCATION FROM OTHER MOD] player "..tostring (playerID).."/"..getPlayerName (game, playerID)..", Commander owner ResCard "..tostring (CommanderOwner_ResurrectionCard));

	-- check if Commander_OwnerID holds a Resurrection card; note: don't check for owner of order.To just in case the Commander of another player exists on the territory
	if (CommanderOwner_ResurrectionCard ~= nil) then
		print ("[RESURRECTION INVOCATION FROM OTHER MOD] player has Res card - process Resurrection prep");
		-- local event = WL.GameOrderEvent.Create (Commander_OwnerID, "Commander on "..game.Map.Territories[targetTerritoryID].Name.." was killed, but their spirit was whisked away", {}, {targetTerritory}); -- create Event object to send back to addOrder function parameter
		local event = WL.GameOrderEvent.Create (Commander_OwnerID, getPlayerName (game, playerID).. "'s Commander was killed, but their spirit was whisked away"); -- create Event object to send back to addOrder function parameter
		-- event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
		addOrder (event, false); --add order to remove the Commander from the TO territory & jump to location
		replacementOrderRequired = false; --don't need to rewrite the original order without the dying Commander in place @ end of function, b/c the mod invoking this order is responsible for handling with the Commander
		initiateResurrectionSequence (game, playerID); --initiate Resurrection sequence for this player; they must play the Resurrection card on the following turn

	else
		print ("[RESURRECTION] player doesn't have Resurrection card - let the Commander die");
	end
end

--check if Resurrection conditions are in place (Commander died & Commander owner has Resurrection card), and if so remove the dying Commanders to be replaced (resurrected) to the map next turn & replace the original order with one w/o the dying commanders on the map
--NOTE: order sequene is critical, proper sequence is: original order, skip original order, swap Commander w/Placeholder [spirits are restless], replacement order (w/Placeholders not Commanders), check for Placeholder, then either (A) replace Commanders (glitch in the matrix) [replacement order was skipped, Commander not dead] or (B) initiate Resurrection sequence [replacement order not skipped, Commander died]
function check_for_Resurrection_conditions_and_execute_preparation (game,order,result,skip,addOrder)
	replacementOrderRequired = false; -- not local, so can be accessed in process_resurrection_Checks_and_Preparation
	GLOBAL_table_orders_swapPlaceholderIn = {}; --table of orders, each 1 swaps out a Commander and swaps in a Placeholder Commander for each Commander involved in the order
	GLOBAL_table_orders_revertCommander = {}; --table of orders to replace Commanders after the Placeholder check is complete
	GLOBAL_table_orders_checkPlaceholder = {}; --table of orders to check if Placeholder Commanders are still alive, 1 order for each Placeholder
	GLOBAL_order_replacementOrder = nil; --to be assigned a single order (not a table)
	GLOBAL_table_orders_whiskedAway = {}; --table of orders to indicate that a Commander has died/whisked away and will be Resurrected
	--&&& when replacing C w/PH C for the attacker, need to ensure it's participating in the attack! else it just stays behind and never dies, never Resurrects

    --if order is an attack on a territory with special units and >0 is set to die, check if a Commander is about to die; if so, check if they have a Resurrection card in hand
    --don't check for and result.IsSuccessful b/c it's possible there are >=1 Commanders and/or other units (Monolith, etc) with higher combat order whereby Commander still dies even if the territory isn't captured
    if (order.proxyType=='GameOrderAttackTransfer' and result.IsAttack and 
	   ((#game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits >0 and #result.DefendingArmiesKilled.SpecialUnits >0) or (#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits >0 and #result.AttackingArmiesKilled.SpecialUnits >0))) then
        print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." DEFENDER -- #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #result.DefendingArmiesKilled.SpecialUnits.."::");
        print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." ATTACKER -- #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits .." #specialKilled ".. #result.AttackingArmiesKilled.SpecialUnits.."::");

		local playerID_Attacker = order.PlayerID;
		local playerID_Defender = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;

		--the following 2 values aren't relevant; they indicate whether the territory owners have Resurrection cards as opposed to the owners of the Specials that are dying (which can be different from the territory owners, notably the Defending territory)
		--local DefenderResurrectionCard = playerHasCard (playerID_Defender, Mod.Settings.ResurrectionCardID, game);
		--local AttackerResurrectionCard = playerHasCard (playerID_Attacker, Mod.Settings.ResurrectionCardID, game);

		print ("Res card ID=="..Mod.Settings.ResurrectionCardID.."; DefenderResCard=="..tostring (DefenderResurrectionCard).."; AttackerResCard=="..tostring (AttackerResurrectionCard).."::");

		--process check & implement Resurrections measures for DEFENDING Commanders (on territory order.To)
		local placeholderCommanders_Defender = process_resurrection_Checks_and_Preparation (game, playerID_Defender, result.DefendingArmiesKilled.SpecialUnits, order.To, addOrder); --actually don't need this return value since they are being attacked (stationary) on TO territory
		local placeholderCommanders_Attacker = process_resurrection_Checks_and_Preparation (game, playerID_Attacker, result.AttackingArmiesKilled.SpecialUnits, order.From, addOrder); --the Commanders in this return value must be added to the attacking armies in the replacement order
		local newAttackingSUs = concatenateTables (order.NumArmies.SpecialUnits, placeholderCommanders_Attacker); --table of new attacking special units to be added to the replacement order
		print ("[###\n###\n###] #placeholderCommanders_Defender "..#placeholderCommanders_Defender..", #placeholderCommanders_Attacker "..#placeholderCommanders_Attacker.. ", #newAttackingSUs ".. #newAttackingSUs);
		local newNumArmies = WL.Armies.Create (order.NumArmies.NumArmies, newAttackingSUs); --create new NumArmies object to be used in the replacement order

		--if Resurrection applies, create replica of original order without the dying command involved; otherwise do nothing (which covers cases of no dying Commanders involved but also dying Commanders whose players didn't hold Resurrection cards)
		if (replacementOrderRequired == true) then
			--local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, order.NumArmies, order.AttackTeammates);
			local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, newNumArmies, order.AttackTeammates);
			--skip (WL.ModOrderControl.Skip);
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
			--addOrder (replacementOrder);
			GLOBAL_order_replacementOrder = replacementOrder;
		end

		print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #result.DefendingArmiesKilled.SpecialUnits.."::");
	elseif ((order.proxyType == "GameOrderCustom") and (startsWith(order.Payload, 'Resurrection|Invoke|'))) then
		--&&& addNewOrder(WL.GameOrderCustom.Create(commanderOwner, "Resurrection - spirit whisked away - commander died", "Resurrection-Invoke|"..commanderOwner.."|"..tostring(CommanderOwner_ResurrectionCard), nil), true); --add order, use 'true' so this new order is skipped if the order that kills the Commander is skipped
		local payloadContent = split(order.Payload, "|");
		--payloadContent [1] is "Resurrection"
		--payloadContent [2] is "Invoke"
		local playerID = tonumber (payloadContent [3]);
		local cardIDinstance = payloadContent [4];
		-- print ("[CFRCAEP] Resurrection-Invoke| playerID "..tostring(playerID).."/"..getPlayerName (game, playerID)..", territoryID "..tostring(territoryID).."/"..tostring (getTerritoryName (territoryID))..", cardIDinstance "..tostring(cardIDinstance).."::");
		print ("[CFRCAEP] Resurrection-Invoke| playerID "..tostring(playerID).."/"..getPlayerName (game, playerID)..", cardIDinstance "..tostring(cardIDinstance).."::");
		process_resurrection_InvokeFromAnotherMod (game, playerID, addOrder);
	elseif ((order.proxyType == "GameOrderCustom") and (startsWith(order.Payload, 'Resurrection|Placeholder-Check|'))) then
		--reference: addOrder (WL.GameOrderCustom.Create (Commander_OwnerID, "Resurrection|Placeholder-Check|"..Commander_OwnerID.."|"..targetTerritoryID.."|"..replacementCommander.ID.."|"..CommanderOwner_ResurrectionCard), false); --create custom order to check for placeholder Commander
		local payloadContent = split(order.Payload, "|");
		--payloadContent [1] is "Resurrection"
		--payloadContent [2] is "Placeholder-Check"
		local playerID = tonumber (payloadContent [3]);
		local targetTerritoryID = tonumber (payloadContent [4]);
		local replacementCommanderID = payloadContent [5];
		local resurrectionCardIDinstance = payloadContent [6];
		print ("\n\n\n[CFRCAEP] Resurrection|Placeholder-Check| playerID "..tostring(playerID).."/"..getPlayerName (game, playerID)..", territoryID "..tostring(targetTerritoryID).."/"..tostring (getTerritoryName (targetTerritoryID, game))..", replacementCommanderID "..tostring(replacementCommanderID)..", resurrectionCardIDinstance "..tostring(resurrectionCardIDinstance));
		skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip the "Resurrection|Placeholder-Check|" message; its purpose was to kick off this code cycle, the order itself has no need to be in the order list

		local placeholderCommander = getSpecialUnitOnTerritory (game, targetTerritoryID, replacementCommanderID);
		if (placeholderCommander ~= nil) then
			print ("[CFRCAEP] Placeholder Commander is present on territory -- Commander-killing-order was skipped -> remove placeholder & replace original Commander");
			local targetTerritory = WL.TerritoryModification.Create(targetTerritoryID);
			targetTerritory.RemoveSpecialUnitsOpt = {placeholderCommander.ID}; --remove the Placeholder Commander from the territory
			local specialUnit = WL.Commander.Create(playerID);
			targetTerritory.AddSpecialUnits = {specialUnit};

			local event = WL.GameOrderEvent.Create (playerID, "[spiritual glitch in the matrix]", {}, {targetTerritory}); -- create Event object to remove Placeholder Commander & re-add original Commander to target territory
			event.JumpToActionSpotOpt = WL.RectangleVM.Create (game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
			print ("[CFRCAEP] [spiritual glitch in the matrix]"); -- create Event object to remove Placeholder Commander & re-add original Commander to target territory
			--GLOBAL_order_revertCommander = event;
			--addOrder (event, false);
			table.insert (GLOBAL_table_orders_revertCommander, event);

		else
			print ("[CFRCAEP] Placeholder Commander is absent from territory -- Commander-killing-order was executed -> Commander died -> process Resurrection");
			local event = WL.GameOrderEvent.Create (playerID, "Commander on "..game.Map.Territories[targetTerritoryID].Name.." was killed, but their spirit was whisked away"); -- create Event object to send back to addOrder function parameter
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
			table.insert (GLOBAL_table_orders_whiskedAway, event);
			--addOrder (event, false); --add order to remove the Commander from the TO territory & jump to location

			--save data in PublicGameData to be retrieved in Client_GameRefresh & Client_GameCommit so player can place Commander on the board
			initiateResurrectionSequence (game, playerID);
			-- local publicGameData = Mod.PublicGameData;
			-- if (publicGameData.ResurrectionData == nil) then publicGameData.ResurrectionData = {}; end
			-- publicGameData.ResurrectionData[playerID] = game.Game.TurnNumber+1; --assign the turn# where the Resurrection card must be played (1 turn directly following death of Commander)
			-- Mod.PublicGameData = publicGameData;
		end
	end

	if (#GLOBAL_table_orders_swapPlaceholderIn >0) then for _,v in pairs (GLOBAL_table_orders_swapPlaceholderIn) do addOrder (v, false); print ("[GLOBAL_table_orders_swapPlaceholderIn]________________===============________"); end end
	if (GLOBAL_order_replacementOrder ~= nil) then addOrder (GLOBAL_order_replacementOrder, false); print ("[GLOBAL_order_replacementOrder]________________===============________"); end
	if (#GLOBAL_table_orders_checkPlaceholder >0) then for _,v in pairs (GLOBAL_table_orders_checkPlaceholder) do addOrder (v, false); print ("[GLOBAL_table_orders_checkPlaceholder]________________===============________"); end end
	if (#GLOBAL_table_orders_revertCommander >0) then for _,v in pairs (GLOBAL_table_orders_revertCommander) do addOrder (v, false); print ("[GLOBAL_table_orders_revertCommander]________________===============________"); end end
	if (#GLOBAL_table_orders_whiskedAway >0) then for _,v in pairs (GLOBAL_table_orders_whiskedAway) do addOrder (v, false); print ("[GLOBAL_table_orders_whiskedAway]________________===============________"); end end
end

--initiative Resurrection sequence on the following turn for the specified playerID
function initiateResurrectionSequence (game, playerID)
	--save data in PublicGameData to be retrieved in Client_GameRefresh & Client_GameCommit so player can place Commander on the board
	local publicGameData = Mod.PublicGameData;
	if (publicGameData.ResurrectionData == nil) then publicGameData.ResurrectionData = {}; end
	publicGameData.ResurrectionData[playerID] = game.Game.TurnNumber+1; --assign the turn# where the Resurrection card must be played (1 turn directly following death of Commander)
	Mod.PublicGameData = publicGameData;
end

function getSpecialUnitOnTerritory (game, territoryID, specialUnitID)
	if (game.ServerGame.LatestTurnStanding.Territories[territoryID].NumArmies.SpecialUnits == nil) then return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories[territoryID].NumArmies.SpecialUnits) do
		if (v.ID == specialUnitID) then return v; end
	end
	return nil;
end

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function playerHasCard (playerID, cardID, game)
	print ("player "..playerID);
	if (playerID==0) then print ("playerID is neutral (has no cards)"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards) do
		if (v.CardID == cardID) then return k; end
	end
	return nil;
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function split(inputstr, sep)
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

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	return (game.Map.Territories[intTerrID].Name);
end

--concatenate elements of 2 tables, return resulting table -- use table.insert
function concatenateTables (array1, array2)
	local result = array1; --start with the first array, then add the elements of the 2nd array to it
	for k,v in pairs (array2) do
		table.insert (result, v);
	end
	return result
end