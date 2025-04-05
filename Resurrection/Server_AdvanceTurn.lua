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

	print ("[RESURRECTION PLACE ON MAP] player "..tostring(playerID).."/"..game.Game.Players[playerID].DisplayName(nil, false)..", terr "..tostring(territoryID).."/"..game.Map.Territories[territoryID].Name.."::");
	local strResurrectionMsg = game.Game.Players[playerID].DisplayName(nil, false) .. " resurrects a Commander to " .. game.Map.Territories[territoryID].Name;
	print (strResurrectionMsg);
	local event = WL.GameOrderEvent.Create (playerID, strResurrectionMsg, {}, {impactedTerritory});
	--addOrder (WL.GameOrderEvent.Create (playerID, strResurrectionMsg, {}, {impactedTerritory}));

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

	addOrder(event, false); --add the order containing the placement of the Commander on the map & if appropriate consumption of the Resurrection card (if player didn't play it himself and it is being played on their behalf automatically)

	--update ResurrectionData
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
	for k,sp in pairs (ArmiesKilled_SpecialUnits) do
		if (sp.proxyType == "Commander") then --if not a Commander, don't do anything
			local Commander_OwnerID = sp.OwnerID; --check owner of Commander, not the territory -- in case a foreign Commander is being killed on someone else's territory (don't check or consume the Resurrection card of the territory owner)
			local CommanderOwner_ResurrectionCard = playerHasCard (Commander_OwnerID, Mod.Settings.ResurrectionCardID, game);
			-- check if Commander_OwnerID holds a Resurrection card; note: don't check for owner of order.To just in case the Commander of another player exists on the territory
			print ("Defender -- SP killed: "..k, sp.proxyType.."; SP owner ResCard=="..tostring(CommanderOwner_ResurrectionCard).."::");
			if (CommanderOwner_ResurrectionCard ~= nil) then
				print ("[RESURRECTION CHECK & PREP] player has Res card - process Resurrection prep");
				local targetTerritory = WL.TerritoryModification.Create(targetTerritoryID);
				targetTerritory.RemoveSpecialUnitsOpt = {sp.ID}; --remove the C special unit from the territory
				table.remove (ArmiesKilled_SpecialUnits, k); --remove the Commander from the list of specials being killed
				local event = WL.GameOrderEvent.Create (playerID, "Commander on "..game.Map.Territories[targetTerritoryID].Name.." was killed, but their spirit was whisked away", {}, {targetTerritory}); -- create Event object to send back to addOrder function parameter
				event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
				addOrder (event, false); --add order to remove the Commander from the TO territory & jump to location
				replacementOrderRequired = true; --rewrite the original order without the dying Commander in place @ end of function

				--save data in PublicGameData to be retrieved in Client_GameRefresh & Client_GameCommit so player can place Commander on the board
				local publicGameData = Mod.PublicGameData;
				if (publicGameData.ResurrectionData == nil) then publicGameData.ResurrectionData = {}; end
				--publicGameData.ResurrectionData[playerID] = true;
				publicGameData.ResurrectionData[playerID] = game.Game.TurnNumber+1; --assign the turn# where the Resurrection card must be played (1 turn directly following death of Commander)
				Mod.PublicGameData = publicGameData;
			else
				print ("[RESURRECTION] player doesn't have Resurrection card - let the Commander die");
			end
		end
	end
end

--check if Resurrection conditions are in place (Commander died & Commander owner has Resurrection card), and if so remove the dying Commanders to be replaced (resurrected) to the map next turn & replace the original order with one w/o the dying commanders on the map
function check_for_Resurrection_conditions_and_execute_preparation (game,order,result,skip,addOrder)
	replacementOrderRequired = false; -- not local, so can be accessed in process_resurrection_Checks_and_Preparation

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
		process_resurrection_Checks_and_Preparation (game, playerID_Defender, result.DefendingArmiesKilled.SpecialUnits, order.To, addOrder);
		process_resurrection_Checks_and_Preparation (game, playerID_Attacker, result.AttackingArmiesKilled.SpecialUnits, order.From, addOrder);

		--if Resurrection applies, create replica of original order without the dying command involved; otherwise do nothing (which covers cases of no dying Commanders involved but also dying Commanders whose players didn't hold Resurrection cards)
		if (replacementOrderRequired == true) then
			local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, order.AttackTransfer, order.ByPercent, order.NumArmies, order.AttackTeammates);
			addOrder (replacementOrder);
			--skip (WL.ModOrderControl.Skip);
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		end

		print ("[CFRCAEP] proxyType==" ..order.proxyType.. " IsAttack ".. tostring (result.IsAttack).." #specials ".. #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits .." #specialKilled ".. #result.DefendingArmiesKilled.SpecialUnits.."::");
	end
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
