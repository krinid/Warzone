require("Manual_Attack");

--[[
STILL TO DO:
- currently adding # of units moving into a territory to map3, and this is fine for transfers, but for attacks it will be too many units as some will die in the attack so need to subtract the # of attacks killed
	^^ maybe skip the order & create new order with appropriate #'s in place instead of doing funky math, b/c "result.armies killed" will be wrong in many cases b/c we're changing the ActualArmies involved thus # attackers killed will change too
	^^ if did this, would it put the order in the right spot? or would it append it to end of order list? for multimove orders to work, the order of the orders is key
- check the ResultantSetOfSpecials, to ensure that order entry time SUs and Server_TurnAdvance_Order time SUs don't mismatch due to GUID mismatches (uppercase/dashes) - do GUIDs come into play here?
]]

function Server_AdvanceTurn_End(game, addNewOrder)
	--uncomment the below line to forcibly halt execution for troubleshooting purposes
--	print ("[FORCIBLY HALTED EXEUCTION @ END OF TURN]"); toriaezu_stop_execution();
	print ("[GRACEFUL END OF TURN EXECUTION]");
end

--set the map1, map2, map3 values to prepare for the current turn
--this must occur not during Server_AdvanceTurn_Start but during Server_TurnAdvance_Order after all deployments have finished, b/c the true map2 values need to be inclusive of any deployments made; the deployments should be permitted to move forward off a territory even 
--if units transferred in have expended their move allocations; use boolAttackTransfersHaveBegun == false;
function initialize_map_counters (game)
	map1 = {}; --tracks the # of movement allocations units that moved onto a territory have left
	map2 = {}; --tracks the # of armies & specials were on a territory at the beginning of the turn (track separately from units that transfer into the territory)
	map3 = {}; --tracks the # of armies that transferred onto a territory that have run out of allocations and can't move anymore (so always subtract these from any moves going forward in this turn)

	-- potential future use:  (for now just implement MultiMove)
	-- Mod.Settings.UseMultimove == true --> indicates to use Multimove, not individual limits for MA & MT
	-- Mod.Settings.MoveLimit --> indicates no limit on the number of moves, -1 is unlimited, 0 is no moves allowed, 1 is standard Warzone behaviour
	-- Mod.Settings.AttackLimit --> indicates no limit on the number of attacks, -1 is unlimited, 0 is no attacks allowed, 1 is standard Warzone behaviour
	-- Mod.Settings.TransferLimit --> indicates no limit on the number of transfers, -1 is unlimited, 0 is no transfers allowed, 1 is standard Warzone behaviour

	for i, _ in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		map1[i] = Mod.Settings.MoveLimit;
		map2[i] = game.ServerGame.LatestTurnStanding.Territories[i].NumArmies;
		--set to the NumArmies table resident on each territory before any moves have been processed; set to nil once the units have been moved
		--ie: thus if map1 indicates that no moves are left but map2 indicates that the units haven't been moved, block the move for the entire amount currently on the territory, but allow
		--a move up to the quantities that were on the territory to begin with
		--NOTE: this actually must occur after all deployments have finished, b/c the true map2 values need to be inclusive of any deployments made; the deployments should be permitted to move forward off a territory even if units transferred in have expended their move allocations
		map3[i] = 0;
	end
end

function Server_AdvanceTurn_Start (game,addNewOrder)
	--[[ map1 = {}; --tracks the # of movement allocations units that moved onto a territory have left
	map2 = {}; --tracks the # of armies & specials were on a territory at the beginning of the turn (track separately from units that transfer into the territory)
	map3 = {}; --tracks the # of armies that transferred onto a territory that have run out of allocations and can't move anymore (so always subtract these from any moves going forward in this turn)

	-- potential future use:  (for now just implement MultiMove)
	-- Mod.Settings.UseMultimove == true --> indicates to use Multimove, not individual limits for MA & MT
	-- Mod.Settings.MoveLimit --> indicates no limit on the number of moves, -1 is unlimited, 0 is no moves allowed, 1 is standard Warzone behaviour
	-- Mod.Settings.AttackLimit --> indicates no limit on the number of attacks, -1 is unlimited, 0 is no attacks allowed, 1 is standard Warzone behaviour
	-- Mod.Settings.TransferLimit --> indicates no limit on the number of transfers, -1 is unlimited, 0 is no transfers allowed, 1 is standard Warzone behaviour

	for i, _ in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		map1[i] = Mod.Settings.MoveLimit;
		map2[i] = game.ServerGame.LatestTurnStanding.Territories[i].NumArmies;
		--set to the NumArmies table resident on each territory before any moves have been processed; set to nil once the units have been moved
		--ie: thus if map1 indicates that no moves are left but map2 indicates that the units haven't been moved, block the move for the entire amount currently on the territory, but allow
		--a move up to the quantities that were on the territory to begin with
		--NOTE: this actually must occur after all deployments have finished, b/c the true map2 values need to be inclusive of any deployments made; the deployments should be permitted to move forward off a territory even if units transferred in have expended their move allocations
		map3[i] = 0;
	end ]]
	print ("____________________Turn #"..game.ServerGame.Game.TurnNumber.."________ move limit "..Mod.Settings.MoveLimit);
	boolAttackTransfersHaveBegun = false; --global variable; signals the completion of Deployments and the start of the Attack/Transfer phase; this is used to save the true map2 values for the territories inclusive of any deployments made (which are permitted to move even if units transferred in have expended their move allocations)
	boolMapValuesInitialized = false; --indicates whether the map values (map1, map2, map3) have been initialized; this happens are all deployments are complete (when the first attack/transfer is made)
end

--[[ function checkForForcedOrder (game, order, result, skip, addNewOrder)
	local strArrayOrderData = split(order.Payload,'|');

	--for reference:
	--local strForcedOrder = "ForceOrder|AttackTransfer|"..targetPlayer.."|"..gameOrder.From.."|"..gameOrder.To.."|"..gameOrder.NumArmies.NumArmies;

	if (strArrayOrderData[1] ~= "ForceOrder") then return; end

	if (strArrayOrderData[2] == "AttackTransfer") then
		print ("[FORCE ORDER] prep - "..order.Payload);
		local numArmies = WL.Armies.Create(strArrayOrderData[8], {});
		print ("[FORCE ORDER] start - "..order.Payload);
		local forcedAttackTransfer = WL.GameOrderAttackTransfer.Create(strArrayOrderData[3], strArrayOrderData[4], strArrayOrderData[5], tonumber (strArrayOrderData[6]), toboolean (strArrayOrderData[7]), numArmies, toboolean (strArrayOrderData[9]));
		--replacementOrder = WL.GameOrderAttackTransfer.Create(targetPlayer, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, gameOrder.NumArmies, gameOrder.AttackTeammates);
		print ("[FORCE ORDER] pre - "..order.Payload);
		--addNewOrder(WL.GameOrderEvent.Create(strArrayOrderData[3], order.Payload, {}, {},{}));
		addNewOrder (forcedAttackTransfer);
		print ("[FORCE ORDER] post - "..order.Payload);
	end
end ]]

function toboolean (value)
    if value == nil or value == false or value == "false" then
        return false
    else
        return true
    end
end

function Server_AdvanceTurn_Order(game, order, result, skip, addNewOrder)
	--print ("PROXY "..order.proxyType);
	--if (order.proxyType == "GameOrderCustom") then checkForForcedOrder (game, order, result, skip, addNewOrder); end
	--    if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'BuyTank_')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI

	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	if (order.PlayerID < 50) then skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); return; end
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 


	--game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits[1].ID
-- 	if (order.proxyType ~= "GameOrderAttackTransfer") then return; end --if order isn't an Attack or Transfer, nothing to do here, just skip to end of function
-- 	dtsu = {};
-- 	dtsu [game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits[1].ID] = 5;
-- 	result.DamageToSpecialUnits = dtsu;
-- 	--result.DamageToSpecialUnits = {game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits[1].ID, 5};
-- 	return;
-- end

-- function temp ()




	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 

	if (order.proxyType ~= "GameOrderAttackTransfer") then return; end --if order isn't an Attack or Transfer, nothing to do here, just skip to end of function
	--order is an AttackTransfer

	--as the order is an Attack/Transfer, if the map values haven't been initialized yet, do that now before processing any Attack/Transfer orders
	--doing this here ensures that the map2 values are inclusive of any deployments made, thus permitting them to move off a territory where all the units transferred in have expended their move allocations
	if (boolMapValuesInitialized == false) then
		print ("[INITIALIZE MAP VALUES] deployments finished, first attack/transfer order in processing, initializing map values");
		initialize_map_counters (game);
		boolMapValuesInitialized = true; --don't reinitialize map values again
	end

	local map2message = "map2FROM Armies (nil)/SU# (nil)";

	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	--[[ if (order.To == 24 and boolThisTestingFunctionActive == nil) then
		--do something
			-- 846: <1> CustomSpecialUnit, owner 1058239/krinid, ID=7b190e13-048d-4e7d-ae78-9e0674536853 --NS Behemoth
			-- 846: <1> CustomSpecialUnit, owner 1058239/krinid, ID=2f4d5ff8-75a5-4473-9046-58ce51ce41a9 --Rocky reddy
			-- 846: <1> CustomSpecialUnit, owner 1058239/krinid, ID=68d4ee40-a404-4b92-ba10-4309bbf50f2d --Florida bluey
			-- 846: <1> CustomSpecialUnit, owner 1/AI 1, ID=33620572-24fe-427f-a2b0-a9d60071ef34         --Azores recruiter
			-- 846: <1> Commander, owner 1058239/krinid, ID=e043282f-737d-48fb-b444-fa45fbd98c24
			-- 846: <2> CustomSpecialUnit, owner 1058239/krinid, ID=0ebe0225-595f-41bd-b8b8-2c75c3f8e21a
			-- 846: <1> Commander, owner 1/AI 1, ID=020092b9-b01d-4dd5-bd58-bf4f54913e81
			-- 846: <1> CustomSpecialUnit, owner 1058239/krinid, ID=92234e16-6176-4bed-bbe0-daa13cc9773c		
		local damageToSpecialUnits = {};
		damageToSpecialUnits["7b190e13-048d-4e7d-ae78-9e0674536853"] = 1;
		result.DamageToSpecialUnits = damageToSpecialUnits; return;
	elseif (boolThisTestingFunctionActive == nil) then
		addNewOrder (WL.GameOrderAttackTransfer.Create (1, 65, 24, 3, false, WL.Armies.Create (1, {}), true));
		boolThisTestingFunctionActive = false;
	end ]]
	--ref: local forcedAttackTransfer = WL.GameOrderAttackTransfer.Create(strArrayOrderData[3], strArrayOrderData[4], strArrayOrderData[5], tonumber (strArrayOrderData[6]), toboolean (strArrayOrderData[7]), numArmies, toboolean (strArrayOrderData[9]));
	--ref: ---@field Create fun(playerID: PlayerID, from: TerritoryID, to: TerritoryID, attackOrTransfer: EnumAttackTransfer, byPercent: boolean, numArmies: Armies, attackTeammates: boolean): GameOrderAttackTransfer # Creates a GameOrderAttackTransfer object
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 
	-- DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME DELME 

	local map1FROM = map1[order.From];
	local map1TO = map1[order.To];
	local map2FROMarmies = nil;
	local map2FROMspecials = nil;
	local map2TOarmies = nil;
	local map2TOspecials = nil;
	local map3FROM = map3[order.From];
	local map3TO = map3[order.To];

	if (map2[order.From] ~= nil) then map2FROMarmies = map2[order.From].NumArmies; map2FROMspecials = map2[order.From].SpecialUnits; end
	if (map2[order.To] ~= nil) then map2TOarmies = map2[order.To].NumArmies; map2TOspecials = map2[order.To].SpecialUnits; end

	if (map2[order.From]) ~= nil then map2message = "map2FROM Armies "..tostring (map2[order.From].NumArmies).."/SU# "..tostring (#map2[order.From].SpecialUnits)..", "; end
	if (map2[order.To]) ~= nil then map2message = map2message .. "map2TO Armies "..tostring (map2[order.To].NumArmies).."/SU# "..tostring (#map2[order.To].SpecialUnits);
	else map2message = map2message .. ", map2TO Armies (nil)/SU# (nil)";
	end

	local TOowner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
	local FROMowner = game.ServerGame.LatestTurnStanding.Territories[order.From].OwnerPlayerID;
	local TOownerTeam = -1;
	local FROMownerTeam = -1;
	if (TOowner ~= nil and TOowner ~= WL.PlayerID.Neutral) then TOownerTeam = game.ServerGame.Game.Players[TOowner].Team; end
	if (FROMowner ~= nil and FROMowner ~= WL.PlayerID.Neutral) then FROMownerTeam = game.ServerGame.Game.Players[FROMowner].Team; end
	print ("\n\n\n\n"..game.ServerGame.Game.Players[1].Team)

	local boolUnitsPresentOnTOterritory = false;
	local boolUnitsPresentOnFROMterritory = false;

	-- set boolUnitsPresentOnTOterritory to true if there are units on the TO territory, could be either armies or Specials; this is relevant b/c if there are no units on the TO territory and it is a Transfer, then the map1 value for the TO territory is irrelevant, 
	-- and we should just use the map1 from the FROM territory -1; if there are units on the TO territory, then we need to use the min of the two map1 values of the FROM & TO territories
	if (game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.NumArmies > 0 or #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits > 0) then boolUnitsPresentOnTOterritory = true; end

	-- set boolUnitsPresentOnFROMterritory to true if there are units on the FROM territory, could be either armies or Specials; this is relevant b/c if there are no units on the FROM territory but there are no move allocations left (map1 value) for the 
	-- FROM territory but there are units here that started on this territory at start of this turn but haven't moved yet (map2 value), then we need to exclude the units that transferred to the FROM territory throughout this turn, but allow a move up to
	-- the quantities that were on the territory to begin with
	if (game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies > 0 or #game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits > 0) then boolUnitsPresentOnFROMterritory = true; end

	--get real # of armies to move; if % then need to calc it from the actual # of armies on the territory; ideally this matches result.ActualArmies.NumArmies but WZ might reduce the 'actual' count if it deems they aren't eligible to continue attacking/transferring, and we need to override this
	local numArmies = 0;
	local intNumArmies_specifiedInOrder = order.NumArmies.NumArmies; --this is the # of the player actually entered into the order (regardless as to whether it was a %, a fixed amount, and whether that # of armies is actually available on the territory or not)
	local intNumArmies_actualOriginal = 0;   --this is the initial actual # of armies on the territory at time or order; it could be lower than intNumArmies_specifiedInOrder in some armies died, moved off, etc; this value is actually present on the territory (but may not be able to move if they've exceeded their move allocations)
	local intNumSUs_specifiedInOrder = #order.NumArmies.SpecialUnits; --this is the # of specials the player actually entered into the order (regardless as to whether it was a %, a fixed amount, and whether that # of specials is actually available on the territory or not)

	if (not order.ByPercent) then
		--order is a straight fixed # of armies
		numArmies = math.min (order.NumArmies.NumArmies, game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies); --take minimum of what was specified or what's currently on the territory; if specified>present then use present; if specified<present then use specified
	else
		--order is a %, need to calculate the true # of armies this % represents
		numArmies = math.min (math.floor (game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies / 100 * order.NumArmies.NumArmies + 0.5), game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies); --round to nearest int, then take the
		--minimum of this amount and what's actually present on the territory
	end
	intNumArmies_actualOriginal = numArmies;

	print ("- - - - - - - - - - - - - - - - - - - - - PRE");
	print ("FROM "..order.From.."/"..game.Map.Territories[order.From].Name..", TO "..order.To.."/"..game.Map.Territories[order.To].Name..", IsAttack "..tostring (result.IsAttack)..", IsSuccessful "..tostring(result.IsSuccessful) ..
		", AttackTransfer "..tostring(order.AttackTransfer).." [".. tostring(WL.AttackTransferEnum.ToString (order.AttackTransfer)) .."], AttackTeammates "..tostring (order.AttackTeammates)..", by% "..tostring (order.ByPercent));
	print ("FROM owner "..FROMowner.." [team "..tostring (FROMownerTeam) .. "], TO owner "..TOowner.." [team ".. tostring (TOownerTeam) .."], AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies..", AttackingSpecialsKilled "..#result.AttackingArmiesKilled.SpecialUnits..", DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", DefendingSpecialsKilled "..#result.DefendingArmiesKilled.SpecialUnits);
	print ("ORDER #armies "..order.NumArmies.NumArmies..", ORDER #SUs "..#order.NumArmies.SpecialUnits ..", ActualSpecials "..#result.ActualArmies.SpecialUnits..", ActualArmies "..result.ActualArmies.NumArmies..
		", #ArmiesOnTerritory "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies..", #specialsOnTerritory "..#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits);
	print ("map1FROM "..tostring (map1[order.From])..", map1TO "..tostring (map1[order.To])..", " ..map2message..", map3FROM "..map3[order.From]..", map3TO "..map3[order.To]);
	print ("FROM attack power "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.AttackPower.. ", FROM defense power "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.DefensePower..", TO attack power "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.AttackPower..", TO defense power "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower);
	print ("Order attack power "..order.NumArmies.AttackPower..", Order defense power "..order.NumArmies.DefensePower..", Actual attack power "..result.ActualArmies.AttackPower..", Actual defense power "..result.ActualArmies.DefensePower..", Kill rates: att "..game.Settings.OffenseKillRate.."/def "..game.Settings.DefenseKillRate);
	for k,v in pairs (result.DamageToSpecialUnits) do print ("Damage to SU: "..k..", "..v); end

	--ensure that order.AttackTransfer settings align with the ownership of the FROM/TO territories
	--NOTE: don't need to check anything if order.AttackTransfer == WL.AttackTransferEnum.AttackTransfer b/c this means anything is acceptable; just let the order proceed, no action required
	--		but if            order.AttackTransfer==WL.AttackTransferEnum.Transfer and owner of FROM != owner of TO (or from same team), then skip the order b/c it would be an Attack
	--		and similarly if  order.AttackTransfer==WL.AttackTransferEnum.Attack and owner of FROM == owner of TO, then skip the order b/c it would be a Transfer
	--		BUT for teams: if order.AttackTransfer==WL.AttackTransferEnum.Attack and owner of FROM is from same team as owner of TO and order.AttackTeammates==false, then skip the order b/c it would be a Transfer
	--		BUT if            order.AttackTransfer==WL.AttackTransferEnum.Attack and owner of FROM is from same team as owner of TO and order.AttackTeammates==true, then allow it b/c they have opted to treat the teammate as enemy
	--      NOTE: team of -1 = no teams defined; actual team #'s start from 0
	--this IF structure will identify the above cases to be handled and skip these orders & execute a 'return' to avoid any further processing, and let everything else process normally
	local boolSkipOrderDueToAttackTransfer = false;
	local strSkipOrderDueToAttackTransfer = nil;
	--print ("\n\n\n"..order.AttackTransfer.."/"..WL.AttackTransferEnum.ToString (order.AttackTransfer),FROMowner,FROMownerTeam,TOowner,TOownerTeam);
	--print (tostring (order.AttackTransfer == WL.AttackTransferEnum.AttackTransfer), tostring (order.AttackTransfer == WL.AttackTransferEnum.Attack), tostring (order.AttackTransfer == WL.AttackTransferEnum.Transfer));
	if (order.AttackTransfer==WL.AttackTransferEnum.Transfer and FROMowner == TOowner) then --order is Transfer to self - always permit this; this is here to override the priority of this being a Success over the other types of transfers
		boolSkipOrderDueToAttackTransfer = false; --permit this order
	elseif (order.AttackTransfer==WL.AttackTransferEnum.Transfer and FROMowner ~= TOowner and FROMownerTeam >= 0 and FROMownerTeam == TOownerTeam) then --order is Transfer to teammate - always permit this; this is here to override the priority of this being a Success over the other types of transfers
		boolSkipOrderDueToAttackTransfer = false; --permit this order
	elseif (order.AttackTransfer==WL.AttackTransferEnum.Transfer and FROMowner ~= TOowner and FROMownerTeam >= 0) then --transfer to enemy w/teams enabled - skip the order
		boolSkipOrderDueToAttackTransfer = true; strSkipOrderDueToAttackTransfer = "Transfer to enemy or neutral (teams in play)";
	elseif (order.AttackTransfer==WL.AttackTransferEnum.Transfer and FROMowner ~= TOowner) then --transfer to enemy w/o teams enabled - skip the order
		boolSkipOrderDueToAttackTransfer = true; strSkipOrderDueToAttackTransfer = "Transfer to enemy or neutral (no teams)";
	elseif (order.AttackTransfer==WL.AttackTransferEnum.Attack and FROMowner == TOowner) then --order is Attack on self
		boolSkipOrderDueToAttackTransfer = true; strSkipOrderDueToAttackTransfer = "Attack on self";
	elseif (order.AttackTransfer==WL.AttackTransferEnum.Attack and FROMownerTeam >= 0 and FROMownerTeam == TOownerTeam and order.AttackTeammates==false) then --order is Attack on teammate but 'Treat teammates as enemies' is not enabled
		boolSkipOrderDueToAttackTransfer = true; strSkipOrderDueToAttackTransfer = "Attack on teammates but 'Treat teammates as enemies' is not set";
	end
	if (boolSkipOrderDueToAttackTransfer == true) then --if one of the AttackTransfer check criteria above is met, skip the order
		skip (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		strSkipOrderDueToAttackTransfer = "Order skipped, reason: ".. strSkipOrderDueToAttackTransfer .. "; Original order: " ..generateSkipMessage (order, game);
		addNewOrder (WL.GameOrderEvent.Create (order.PlayerID, strSkipOrderDueToAttackTransfer, {}, {},{}));
		return; --don't process any further, just skip the order and return in order to process the next order
	end
	--print ("&&&&&&&&&&"..tostring (strSkipOrderDueToAttackTransfer));

	-- print (WL.AttackTransferEnum.Attack);
	-- print (WL.AttackTransferEnum.Transfer);
	-- print (WL.AttackTransferEnum.AttackTransfer);


	--[[ - - - - - - - - - - - - - - - - - - - - - - - - - START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- - - - - - - - - - - - - - - - - - - - - - - - - - START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- - - - - - - - - - - - - - - - - - - - - - - - - - START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Confirm: this isn't required anymore; Fizz updated WZ so this doesn't occur any longer; leave in anyway just in case? Or remove it?

	--check for case of FROM=order player, TO=another player (not same team) but IsAttack=false; this causes either a WZ error (if TO territory is neutral) or a transfer to the enemy (if TO territory is owned by an enemy player)
	if (result.IsAttack==false and FROMowner == order.PlayerID and TOowner ~= order.PlayerID) then
		if (problematicOrderCount==nil) then problematicOrderCount = 0; end
		problematicOrderCount = problematicOrderCount + 1;
		--print ("PROBLEMATIC ... FizzGlitch conditions detected; we need a WZ bug fix for this"); --; count=="..problematicOrderCount);  <-- recreating the order had no impact, IsAttack==false every time  :(  ... we need Fizz to fix this
		print ("PROBLEMATIC ... FizzGlitch conditions detected; we need a WZ bug fix for this; count=="..problematicOrderCount);  --<-- recreating the order had no impact, IsAttack==false every time  :(  ... we need Fizz to fix this

		--result.ActualArmies = WL.Armies.Create(newNumArmies, newSpecials); --technically this sends all Special Units that were on the territory to begin with regardless of what the order was
		--^^this doesn't work for this condition

		--try recreating the order from current state, see if it becomes a proper Attack
		local newNumArmiesCountFG = order.NumArmies.NumArmies;
		local newSpecialsFG = order.NumArmies.SpecialUnits;
		local newArmiesStructureFG = WL.Armies.Create(newNumArmiesCountFG, newSpecialsFG);]]

		--[[if (not order.ByPercent) then
			--order is a straight fixed # of armies
			newNumArmiesCountFG = order.NumArmies.NumArmies;
		else
			--order is a %, need to calculate the true # of armies this % represents
			newNumArmiesCountFG = math.floor (game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies / 100 * order.NumArmies.NumArmies + 0.5); --round to nearest int
		end]]

		--[[ --don't do this for now -- it doesn't work, WZ overrides the attempt and just makes it a Transfer again regardless, so just SKIP all FizzGlitch orders for now
		--recreate the order, forcingg it to be an Attack order (Attack Only, no transfer)
		if (false) then --(problematicOrderCount==1) then
		--if (problematicOrderCount==1) then
			--local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack, order.ByPercent, order.NumArmies, order.AttackTeammates);
			--local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack, order.ByPercent, newArmiesStructureFG, order.AttackTeammates);
			local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack, false, newArmiesStructureFG, false);
			addNewOrder (replacementOrder);
			print ("[RECREATE & SKIP ORDER]");
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
			return; --skip rest of this function, skip this order b/c it can't be implemented until the WZ bug is fixed
		end

		--FizzGlitch order can't be worked around by anything I've tried so far, so just skip it, wait for the WZ fix
		if (true) then
		--if (problematicOrderCount==2) then
			--toriaezu_stop_execution();  --forcibly halt execution for troubleshooting purposes
			local strSkipOrderMessage = "[FizzGlitch condition] Order skipped to avoid WZ error or transfer to enemy [requires WZ bug fix]; Original order: " ..generateSkipMessage (order, game);
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
			process_manual_attack (game, newArmiesStructureFG, game.ServerGame.LatestTurnStanding.Territories[order.To], result);
			--skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			--print ("[SKIP ORDER]");
			return; --skip rest of this function, skip this order b/c it can't be implemented until the WZ bug is fixed
		end
		--toriaezu_stop_execution();
	end
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ]]

	--only process the order if the FROM territory is owned by the order player
	if (FROMowner == order.PlayerID and Mod.Settings.MoveLimit ~= 0 and boolUnitsPresentOnFROMterritory) then --if MoveLimit == 0, no moves are allowed, just skip the order
		-- if order player owns FROM territory, there are units on the territory and MoveLimit isn't set to 0, inspect the order details to see if it can be processed

		local boolMoveUnitsTransferredIn = false; --indicates whether the full army count available on FROM territory should be moved, including both units on the territory from start of turn & units that transferred onto the territory during the turn; if false, then don't move the transferred in units, but possibly move the units resident since start of turn (boolMoveUnitsOnTerritoryAtStartOfTurn decides whether they can move)
		local boolMoveUnitsOnTerritoryAtStartOfTurn = false; --indicates whether the units that were on the territory at the beginning of the turn (ie: haven't moved yet, have move allocations left) should be moved independently from any units that transferred onto the territory this turn that have consumed their move allocations
		local boolProcessOrder = false; --indicates whether the order should be processed (true) or skipped (false)
		local boolSkipOrder = false; --indicates whether the order should be skipped (true) or not (false)
		local boolactualIsSuccessful = false; --indicates the true success result of the order; this is important for Attacks, which may change from false to true after recalcing ActualArmies figures and thus determine whether the territory is captured or not and thus whether to update the map1 value or not

		if (map1FROM > 0 or map1FROM <= -1) then boolMoveUnitsTransferredIn = true; end
		if ((map2FROMarmies ~= nil and map2FROMarmies > 0) or (map2FROMspecials ~= nil and #map2FROMspecials > 0)) then boolMoveUnitsOnTerritoryAtStartOfTurn = true; end
		print ("boolMoveUnitsTransferredIn "..tostring(boolMoveUnitsTransferredIn)..", boolMoveUnitsOnTerritoryAtStartOfTurn "..tostring (boolMoveUnitsOnTerritoryAtStartOfTurn));

		--if units transferred into the FROM territory have move allocations left, move all units specified in numArmies
		if boolMoveUnitsTransferredIn == true then
			--if units have transferred into the FROM territory, then the map1 value for the FROM territory is irrelevant, it's only important when groups of armies mix that we use the lowest of the two map1 values
			boolProcessOrder = true;
			result.ActualArmies = WL.Armies.Create(numArmies, order.NumArmies.SpecialUnits);
			print ("[ATTACK/TRANSFER TYPE 1 -- boolMoveUnitsTransferredIn == true]");
			print ("[ACTUAL ARMIES] result.ActualArmies "..result.ActualArmies.NumArmies..", numArmies "..numArmies..", #SUs "..#order.NumArmies.SpecialUnits..", APow "..result.ActualArmies.AttackPower);
			--the 'result' structure auto-updates to reflect proper AttackPower & DefensePower values, so use these below for attacks!

			--&&& manually modify the # of attackers and defenders killed until Fizzer fixes WZ engine to account for this (requires exposing 'Used Armies' counter structure to mods); internal WZ engine used marks moved armies as 'Used Armies' once they have transferred and prevents them from making further moves
			--rather than relying on WZ to calculate the damage to defender & attacker based on Attack/Defense power of # of quantity of armies & specials that haven't been 'used', manually calc the damage and apply it to the .AttackingArmiesKilled & .DefendingArmiesKilled fields
			if (result.IsAttack==true) then
				print ("[ATTACK TYPE 1 -- boolMoveUnitsTransferredIn == true]");
				print ("[ADJUSTED KILL COUNTS] [full] TO #armies "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.NumArmies..", TO DPow "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower..", ORDER ACTUAL #armies "..result.ActualArmies.NumArmies..", #SUs "..#result.ActualArmies.SpecialUnits ..", APow "..result.ActualArmies.AttackPower..", kill rates "..game.Settings.OffenseKillRate.."/"..game.Settings.DefenseKillRate);
				--orig (current public mod published code):
				-- result.AttackingArmiesKilled = WL.Armies.Create (math.floor (game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5), result.AttackingArmiesKilled.SpecialUnits);
				-- result.DefendingArmiesKilled = WL.Armies.Create (math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5), result.DefendingArmiesKilled.SpecialUnits);
				--&&& need to include the Special damage/killing algorithm here, for now just include whatever Specials were killed in the original result (which may be too low)
				--new code utilizing Manual Attack routine:

				print ("======================================Manual Attack; boolMoveUnitsTransferredIn == true [use full armies on territory]");
				local manualAttackResult = process_manual_attack (game, result.ActualArmies, game.ServerGame.LatestTurnStanding.Territories[order.To], result, addNewOrder, true);
				--reference: function process_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder, boolWZattackTransferOrder)
				print ("MAR.DR.KA type/# ".. type(manualAttackResult.DefenderResult.KilledArmies).."/"..tostring (manualAttackResult.DefenderResult.KilledArmies)..", MAR.DR.KS type/# "..type (manualAttackResult.DefenderResult.KilledSpecials).."/".. tablelength (manualAttackResult.DefenderResult.KilledSpecialsObjects)..", #MAR.DR.DTSU "..tablelength (manualAttackResult.DefenderResult.DamageToSpecialUnits));
				print ("MAR.AR.KA type/# ".. type(manualAttackResult.AttackerResult.KilledArmies).."/"..tostring (manualAttackResult.AttackerResult.KilledArmies)..", MAR.AR.KS type/# "..type (manualAttackResult.AttackerResult.KilledSpecials).."/".. tablelength (manualAttackResult.AttackerResult.KilledSpecialsObjects)..", #MAR.AR.DTSU "..tablelength (manualAttackResult.AttackerResult.DamageToSpecialUnits));
				for k,v in pairs (manualAttackResult.AttackerResult.KilledSpecials) do print ("AR.KS "..k,v); end
				for k,v in pairs (manualAttackResult.AttackerResult.KilledSpecialsObjects) do print ("AR.KSO.ID "..k,v.ID); end
				for k,v in pairs (manualAttackResult.AttackerResult.DamageToSpecialUnits) do print ("AR.DSU "..k,v); end
				for k,v in pairs (manualAttackResult.DefenderResult.KilledSpecials) do print ("DR.KS "..k,v); end
				for k,v in pairs (manualAttackResult.DefenderResult.KilledSpecialsObjects) do print ("DR.KSO.ID "..k,v.ID); end
				for k,v in pairs (manualAttackResult.DefenderResult.DamageToSpecialUnits) do print ("DR.DSU "..k,v); end
				-- result.AttackingArmiesKilled = WL.Armies.Create (manualAttackResult.AttackerResult.KilledArmies, manualAttackResult.AttackerResult.KilledSpecialsObjects); --%^&* --&&&
				-- result.DefendingArmiesKilled = WL.Armies.Create (manualAttackResult.DefenderResult.KilledArmies, manualAttackResult.DefenderResult.KilledSpecialsObjects);
				-- result.AttackingArmiesKilled = WL.Armies.Create (manualAttackResult.AttackerResult.KilledArmies, manualAttackResult.AttackerResult.KilledSpecialsObjects); --%^&* --&&&
				-- result.DefendingArmiesKilled = WL.Armies.Create (manualAttackResult.DefenderResult.KilledArmies, manualAttackResult.DefenderResult.KilledSpecialsObjects);
				result.AttackingArmiesKilled = manualAttackResult.AttackingArmiesKilled;
				result.DefendingArmiesKilled = manualAttackResult.DefendingArmiesKilled;
				result.DamageToSpecialUnits = manualAttackResult.DamageToSpecialUnits; --assign array of tables {GUIDs & damage integers} to apply damge to the SUs as part of the WZ attack order
				-- result = manualAttackResult.Result;

				--result.DamageToSpecialUnits = 
				--reference: 	local damageResult = {RemainingArmies=remainingArmies, KilledArmies=math.max (0, armyCount-remainingArmies), SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecials, ClonedSpecials=clonedSpecials, DamageToSpecialUnits=damageToSpecialUnits};
				--reference: GameOrderResult
					--[[ ---@field ActualArmies Armies # The actual armies that participated in the attack / transfer
					---@field AttackingArmiesKilled Armies # The armies that are killed on the attacking side
					---@field DamageToSpecialUnits table<GUID, integer> # The damage done to special units, only when they are not killed
					---@field DefendingArmieskilled Armies # The armies that are killed on the defending side
					---@field DefenseLuck number | nil # The luck attribute for the defending player
					---@field IsAttack boolean # True if the attack / transfer was an attack
					---@field IsNullified boolean # True if the attack is nullified, essentially skipping the order
					---@field IsSuccessful boolean # True if the attack / transfer was able to reach the other territory, if IsAttack is also true the order successfully took the defending territory
					---@field OffenseLuck number | nil # The luck attribute for the attacking player]]

				--if all defending armies & specials died, mark the attack as successful
				--if (result.DefendingArmiesKilled.NumArmies >= game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower and #result.DefendingArmiesKilled.SpecialUnits >= #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits) then boolactualIsSuccessful = true; end
				if (manualAttackResult.IsSuccessful == true) then boolactualIsSuccessful = true; end
				--if damage down >= DefensePower of TO territory, it will be captured; result.IsSuccessful may not accurate reflect this b/c the # of armies may have been too low b/c WZ removed "Used Armies"/specials from the Attack/DefensePower values; boolactualIsSuccessful is the
				--true result, inclusive of the values of the post adjusted Off/Def kill counts
				print ("[ADJUSTED KILL COUNTS] [full] result.AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies..", result.DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", IsSuccessful "..tostring (result.IsSuccessful)..", Actual IsSuccessful "..tostring (boolactualIsSuccessful));
			end

			---if Transfer, use min Map1 value of FROM & TO territories, b/c order player owns To and it might already have less move allocations less than From-1
			---if Attack, ignore TO territory map value b/c that's the value for another player (or a neutral)
			if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer and there are units on the TO territory (so must use the min map1 value of the FROM and TO territories)
				map1[order.To] = math.min(map1FROM - 1, map1TO); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
				print ("[ORDER] process Transfer [full], TO has units already, reduce TO map1 [min calc] to "..map1[order.To]);
			else --order is an Attack or a Transfer to a territory with 0 units (in which case the map1 value for those units is no longer relevant, it's only important when groups of armies mix that we use the lowest of the two map1 values)

				if (boolactualIsSuccessful==true or result.IsAttack==false) then --only set map1 for TO territory iff order is a transfer or a successful attack; if an unsuccessful attack, leave TO map1 value as-is
				--if (result.IsSuccessful==true or result.IsAttack==false) then --only set map1 for TO territory iff order is a transfer or a successful attack; if an unsuccessful attack, leave TO map1 value as-is
					map1[order.To] = map1FROM - 1; --subtract one from the map1 table, representing 1 less movement available for the units on this territory; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
					if (result.IsAttack==false) then print ("[ORDER] process Transfer, TO has 0 units, reduce TO map1 [straight] to "..map1[order.To]);
					elseif (boolactualIsSuccessful==true) then print ("[ORDER] process successful Attack [full], reduce TO map1 [straight] to "..map1[order.To]);
					end
				else
					if (result.IsAttack) then print ("[ORDER] process failed Attack [full], don't reduce TO map1, remains at "..map1[order.To]); end
				end
			end
			map2[order.From] = nil; --indicate that the units on the FROM territory have been moved

			--if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
			if (result.IsAttack==true and boolactualIsSuccessful==true) then map2[order.To] = nil; end
			--if (result.IsAttack==true and result.IsSuccessful==true) then map2[order.To] = nil; end

			--COMMENT FOR BELOW: map3 isn't used at this point; perhaps it could be but I think the current state is likely the best while keeping it simple (ie: not tracking the # of moves for every separate group of units and then having the user indicate which groups are moving where)
			--if there are no movement allocations left on the TO territory, add them to map3 to indicate that they can't move anymore
			if (map1TO == 0) then map3[order.To] = map3[order.To]-(numArmies-result.AttackingArmiesKilled.NumArmies); end --simplified for now, need to do for both armies & specials

		--units transferred into FROM territory so far have no move allocations left, so check if units on the territory at start of turn have moved yet, if not, move them; if they have moved, skip the order
		elseif boolMoveUnitsOnTerritoryAtStartOfTurn == true then --units that were present on the territory haven't moved yet, so don't stop them from moving during this order
			print ("[ATTACK/TRANSFER TYPE 2 -- boolMoveUnitsTransferredIn == false, use map2 values]");
			boolProcessOrder = true;
			local newNumArmies = math.min (numArmies, map2[order.From].NumArmies); --use the lesser of the # of armies the player entered or the quantity present at start of turn (b/c all other units have no movement allocations left)
			local newSpecials = resultantSetOfSpecials (map2[order.From].SpecialUnits, order.NumArmies.SpecialUnits); --create new list of Specials that is the intersection of what's included in the list of Specials originally on the territory & what's included in the order (anything else was either killed or not included in the order)
			result.ActualArmies = WL.Armies.Create(newNumArmies, newSpecials);

			--add an order indicating that the #armies/SUs participating has decreased due to exceeding move allocations, but the order is still valid, some units will still be able to move
			local strReduceArmiesMessage = "[units that transferred in have exceeded their move allocations and were excluded from the order; only units present on the territory at start of turn or via deployments could execute the order] (specified: #armies "
				..intNumArmies_specifiedInOrder.. (order.ByPercent and "%" or "") .. ", #specials "..#order.NumArmies.SpecialUnits.."; actually present: #armies "..numArmies..", #specials ".. intNumSUs_specifiedInOrder.."; able to move: #armies "..newNumArmies..", #specials "..#newSpecials..")";
			local numArmies = 0;
			local intNumArmies_specifiedInOrder = order.NumArmies.NumArmies; --this is the # of the player actually entered into the order (regardless as to whether it was a %, a fixed amount, and whether that # of armies is actually available on the territory or not)
			local intNumArmies_actualOriginal = 0;   --this is the initial actual # of armies on the territory at time or order; it could be lower than intNumArmies_specifiedInOrder in some armies died, moved off, etc; this value is actually present on the territory (but may not be able to move if they've exceeded their move allocations)
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strReduceArmiesMessage, {}, {},{}));

			--similar to the same block for the case where TransferringUnits also participate in the Attack/Transfer, calc the true kill counts for Defend/Offense armies; technically don't need to do this, WZ will calc it correctly in this case, however in order to get the true 
			--success/failure result of an Attack, need to calc the # of Attackers and Defenders that die & assign boolactualIsSuccessful to true when all defenders die (attacker captures territory) & update TO map1 values appropriately based on success of attack
			--
			--&&& manually modify the # of attackers and defenders killed until Fizzer fixes WZ engine to account for this (requires exposing 'Used Armies' counter structure to mods); internal WZ engine used marks moved armies as 'Used Armies' once they have transferred and prevents them from making further moves
			--rather than relying on WZ to calculate the damage to defender & attacker based on Attack/Defense power of # of quantity of armies & specials that haven't been 'used', manually calc the damage and apply it to the .AttackingArmiesKilled & .DefendingArmiesKilled fields
			if (result.IsAttack==true) then
				print ("[ATTACK TYPE 2 -- boolMoveUnitsTransferredIn == false, use map2 values]");
				print ("[ADJUSTED KILL COUNTS] [map2 only] TO #armies "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.NumArmies..", TO DPow "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower..", Order #actual armies "..result.ActualArmies.NumArmies..", Order #SUs "..#result.ActualArmies.SpecialUnits ..", Order APow "..result.ActualArmies.AttackPower..", att "..game.Settings.OffenseKillRate.."/"..game.Settings.DefenseKillRate);

				--orig (current public mod published code):
				-- result.AttackingArmiesKilled = WL.Armies.Create (math.floor (game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower * game.Settings.DefenseKillRate + 0.5), result.AttackingArmiesKilled.SpecialUnits);
				-- result.DefendingArmiesKilled = WL.Armies.Create (math.floor (result.ActualArmies.AttackPower * game.Settings.OffenseKillRate + 0.5), result.DefendingArmiesKilled.SpecialUnits);
				--&&& need to include the Special damage/killing algorithm here, for now just include whatever Specials were killed in the original result (which may be too low)

				--new code utilizing Manual Attack routine:
				print ("======================================Manual Attack; boolMoveUnitsTransferredIn == false [utilize map2 values]");
				local manualAttackResult = process_manual_attack (game, result.ActualArmies, game.ServerGame.LatestTurnStanding.Territories[order.To], result, addNewOrder, true);
				print ("MAR.DR.KA type/# ".. type(manualAttackResult.DefenderResult.KilledArmies).."/"..tostring (manualAttackResult.DefenderResult.KilledArmies)..", MAR.DR.KS type/# "..type (manualAttackResult.DefenderResult.KilledSpecials).."/".. tablelength (manualAttackResult.DefenderResult.KilledSpecialsObjects)..", #MAR.DR.DTSU "..tablelength (manualAttackResult.DefenderResult.DamageToSpecialUnits));
				print ("MAR.AR.KA type/# ".. type(manualAttackResult.AttackerResult.KilledArmies).."/"..tostring (manualAttackResult.AttackerResult.KilledArmies)..", MAR.AR.KS type/# "..type (manualAttackResult.AttackerResult.KilledSpecials).."/".. tablelength (manualAttackResult.AttackerResult.KilledSpecialsObjects)..", #MAR.AR.DTSU "..tablelength (manualAttackResult.AttackerResult.DamageToSpecialUnits));
				for k,v in pairs (manualAttackResult.AttackerResult.KilledSpecials) do print ("AR.KS "..k,v); end
				for k,v in pairs (manualAttackResult.AttackerResult.KilledSpecialsObjects) do print ("AR.KSO.ID "..k,v.ID); end
				for k,v in pairs (manualAttackResult.AttackerResult.DamageToSpecialUnits) do print ("AR.DSU "..k,v); end
				for k,v in pairs (manualAttackResult.DefenderResult.KilledSpecials) do print ("DR.KS "..k,v); end
				for k,v in pairs (manualAttackResult.DefenderResult.KilledSpecialsObjects) do print ("DR.KSO.ID "..k,v.ID); end
				for k,v in pairs (manualAttackResult.DefenderResult.DamageToSpecialUnits) do print ("DR.DSU "..k,v); end
				-- result.AttackingArmiesKilled = WL.Armies.Create (manualAttackResult.AttackerResult.KilledArmies, manualAttackResult.AttackerResult.KilledSpecialsObjects); --%^&* --&&&
				-- result.DefendingArmiesKilled = WL.Armies.Create (manualAttackResult.DefenderResult.KilledArmies, manualAttackResult.DefenderResult.KilledSpecialsObjects);
				-- result.DamageToSpecialUnits = manualAttackResult.DamageToSpecialUnits; --assign array of tables {GUIDs & damage integers} to apply damge to the SUs as part of the WZ attack order
				-- result = manualAttackResult.Result;
				result.AttackingArmiesKilled = manualAttackResult.AttackingArmiesKilled;
				result.DefendingArmiesKilled = manualAttackResult.DefendingArmiesKilled;
				result.DamageToSpecialUnits = manualAttackResult.DamageToSpecialUnits; --assign array of tables {GUIDs & damage integers} to apply damge to the SUs as part of the WZ attack order

				--if all defending armies & specials died, mark the attack as successful
				-- if (result.DefendingArmiesKilled.NumArmies >= game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower and #result.DefendingArmiesKilled.SpecialUnits >= #game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.SpecialUnits) then boolactualIsSuccessful = true; end
				if (manualAttackResult.IsSuccessful == true) then boolactualIsSuccessful = true; end
				--if damage down >= DefensePower of TO territory, it will be captured; result.IsSuccessful may not accurate reflect this b/c the # of armies may have been too low b/c WZ removed "Used Armies"/specials from the Attack/DefensePower values; boolactualIsSuccessful is the
				--true result, inclusive of the values of the post adjusted Off/Def kill counts
				print ("[ADJUSTED KILL COUNTS] [map2 only] result.AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies..", result.DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", IsSuccessful "..tostring (result.IsSuccessful)..", Actual IsSuccessful "..tostring (boolactualIsSuccessful));
			end

			--if map2 value==nil, the units on this territory have moved already, and the map1 calc already down above indicates that these units can't move any farther, so skip the order (go down to the ELSE clause)
			--if map2 value==0 for both NumArmies & Specials then there are no units on the territory to be moved; in both cases, skip the order, there's nothing to do here (go down to the ELSE clause)

			--adjust map1, map2 values; WZ processes the adjusted army counts correctly in this case so don't need to adjust army counts, special 
			if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer with units on the TO territory, so use min of Mod.Settings.MoveLimit (b/c these FROM units haven't moved yet this turn) & Map1 value of TO territory
				map1[order.To] = math.min(Mod.Settings.MoveLimit - 1, map1TO); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
				print ("[ORDER] process Transfer [map2 only], reduce TO map1 to "..map1[order.To]..", TO map2 no change, FROM map2 set to nil");
			else --order is an Attack or a Transfer with no units on the TO territory, so just use Mod.Settings.MoveLimit - 1
				if (boolactualIsSuccessful==true or result.IsAttack==false) then --only set map1 for TO territory iff order is a transfer or a successful attack; if an unsuccessful attack, leave TO map1 value as-is
				--if (result.IsSuccessful==true or result.IsAttack==false) then --only set map1 for TO territory iff order is a transfer or a successful attack; if an unsuccessful attack, leave TO map1 value as-is
					map1[order.To] = Mod.Settings.MoveLimit - 1; --subtract one from Mod.Settings.MoveLimit b/c these units haven't moved yet; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
					if (result.IsAttack==true) then
						print ("[ORDER] process successful Attack [map2 only], reduce TO map1 to "..map1[order.To]..", TO map2 set to nil, FROM map2 set to nil"); end
						map2[order.To] = nil; --if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
					else
						print ("[ORDER] process Transfer [map2 only], reduce TO map1 to "..map1[order.To]..", TO map2 no change, FROM map2 set to nil");
					end
			end

			map2[order.From] = nil; --indicate that the units on the FROM territory have been moved and any units that arrive should be moved according to their regular movement allocation
			map3[order.To] = map3[order.To]-newNumArmies; --simplified for now, need to do for both armies & specials

		else --skip the order
			--no movement allocation remaining for the units on FROM territory, and the units that were on this territory have already moved or their quantity is 0, in any cases, no units can move, so skip the order
			boolSkipOrder = true;
			local strSkipOrderMessage = "Order skipped, units have no movement allocations remaining; Original order: " ..generateSkipMessage (order, game);
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
		end
	else
		--skip the order, order player does not own the FROM territory or Mod.Settings.MoveLimit == 0 which means no Attack/Transfer orders are possible (captures/etc must be done by other means, cards/mods/etc)
		--skip (WL.ModOrderControl.Skip); --skip this order
		--message:: skipped b/c you don't own the territory; is this required? at least indicate which move is being skipped
		boolSkipOrder = true;
		local strSkipOrderMessage = "Order skipped, you do not own source territory; Original order: ";
		if (boolUnitsPresentOnFROMterritory == false) then strSkipOrderMessage = "Order skipped, no units present on territory; Original order: "; end
		if (Mod.Settings.MoveLimit == 0) then strSkipOrderMessage = "Order skipped, Move Limit is set to 0, standard Attack/Transfers are disabled; Original order: "; end
		strSkipOrderMessage = strSkipOrderMessage .. generateSkipMessage (order, game);
		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
		skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
	end

	local map2message = "map2FROM Armies (nil)/SU# (nil)";
	if (map2[order.From]) ~= nil then map2message = "map2FROM Armies "..tostring (map2[order.From].NumArmies).."/SU# "..tostring (#map2[order.From].SpecialUnits)..", ";
	end
	if (map2[order.To]) ~= nil then map2message = map2message .. "map2TO Armies "..tostring (map2[order.To].NumArmies).."/SU# "..tostring (#map2[order.To].SpecialUnits);
	else map2message = map2message .. ", map2TO Armies (nil)/SU# (nil)";
	end

	print ("- - - - - - - - - - - - - - - - - - - - - POST");
	print ("FROM "..order.From.."/"..game.Map.Territories[order.From].Name..", TO "..order.To.."/"..game.Map.Territories[order.To].Name..", IsAttack "..tostring (result.IsAttack)..", IsSuccessful "..tostring(result.IsSuccessful) ..
		", AttackTransfer "..tostring(order.AttackTransfer)..", AttackTeammates "..tostring (order.AttackTeammates)..", by% "..tostring (order.ByPercent));
	print ("FROM owner "..FROMowner.." [team "..tostring (FROMownerTeam) .. "], TO owner "..TOowner.."[".. tostring (TOownerteam) .."], AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies..", AttackingSpecialsKilled "..#result.AttackingArmiesKilled.SpecialUnits..", DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", DefendingSpecialsKilled "..#result.DefendingArmiesKilled.SpecialUnits);
	print ("ORDER #armies "..order.NumArmies.NumArmies..", ORDER #SUs "..#order.NumArmies.SpecialUnits ..", ActualSpecials "..#result.ActualArmies.SpecialUnits..", ActualArmies "..result.ActualArmies.NumArmies..
		", #ArmiesOnTerritory "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies..", #specialsOnTerritory "..#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits);
	print ("map1FROM "..tostring (map1[order.From])..", map1TO "..tostring (map1[order.To])..", " ..map2message..", map3FROM "..map3[order.From]..", map3TO "..map3[order.To]);
	print ("FROM attack power "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.AttackPower.. ", FROM defense power "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.DefensePower..", TO attack power "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.AttackPower..", TO defense power "..game.ServerGame.LatestTurnStanding.Territories[order.To].NumArmies.DefensePower);
	print ("Order attack power "..order.NumArmies.AttackPower..", Order defense power "..order.NumArmies.DefensePower..", Actual attack power "..result.ActualArmies.AttackPower..", Actual defense power "..result.ActualArmies.DefensePower..", Kill rates: att "..game.Settings.OffenseKillRate.."/def "..game.Settings.DefenseKillRate);
	for k,v in pairs (result.DamageToSpecialUnits) do print ("Damage to SU: "..k..", "..v); end
end

function process_entire_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder)
	local manualAttackResult = process_manual_attack (game, AttackingArmies, DefendingTerritory, result, addNewOrder, true);
	--local manualAttackResult = process_manual_attack (game, result.ActualArmies, game.ServerGame.LatestTurnStanding.Territories[order.To], result, addNewOrder, true);

--&&&
	--manualAttackResult.AttackerResult is armies object for attacker
	--manualAttackResult.DefenderResult is armies object for defender
	--manualAttackResult.IsSuccessful is boolean indicating if the attack was successful, and thus whether:
		--(A) attacker wins, defender units are wiped out, the attacker should move into the target territory and take ownership of it
		--(B) attacker loses, attacker units are reduced or wiped out and source territory is updated, the defender units may be reduced but remain in the target territory and retain ownership of it

	--adjust attacker results, so # of killed armies is increased by quantity of intArmiesDieDuringAttack
	airstrikeResult.AttackerResult.KilledArmies = math.min (airstrikeResult.AttackerResult.KilledArmies + intArmiesDieDuringAttack, intActualArmies); --#armies killed are those from regular battle damage + loss due to Deployment Yield but not to exceed the actual # included in the Airstrike operation (if exceeds this amount, it would subtract units from the FROM territory even if they didn't participate in the Airstrike -- don't do that)
	airstrikeResult.AttackerResult.RemainingArmies = math.max (0, attackingArmies.NumArmies - airstrikeResult.AttackerResult.KilledArmies);
end

--process a manual attack sequence from AttackOrder [type NumArmies] on DefendingTerritory [type Territory] with respect to Specials & armies
--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
--also treat Specials properly with respect to their specs, notably damage required to kill, health, attack/damage properties, etc
--return value is the result with updated AttackingArmiesKilled & DefendingArmiesKilled values
--also need some way of indicating overall success separately b/c can't change some properties of the result object directly
function process_manual_attack_NOPE_seeUpdatedRoutine_canProbablyDeleteThisNow (game, AttackingArmies, DefendingTerritory, result)
	--note armies have combat order of 0, Commanders 10,000, need to get the combat order of Specials from their properties
	local newResult = result;
	local AttackPower = AttackingArmies.AttackPower;
	local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	local AttackDamage = AttackPower * game.Settings.OffenseKillRate;
	local DefenseDamage = DefensePower * game.Settings.DefenseKillRate;
	local remainingAttackDamage = AttackDamage; --apply attack damage to defending units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied
	local remainingDefenseDamage = DefenseDamage; --apply defense damage to attacking units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied

	local boolArmiesProcessed = false;

	print ("[MANUAL ATTACK] #armies "..AttackingArmies.NumArmies..", #SUs "..#AttackingArmies.SpecialUnits);
	--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
	for k,v in pairs (AttackingArmies.SpecialUnits) do
		--Properties Exist for Commander: ID, guid, proxyType, CombatOrder <--- and that's it!
		--Properties DNE for Commander: AttackPower, AttackPowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, DefensePower, DefensePowerPercentage, Health
		print ("SPECIAL type "..v.proxyType.. ", combat order "..v.CombatOrder);

		if (v.proxyType == "CustomSpecialUnit") then
			print ("SPECIAL name "..v.Name..", combat order "..v.CombatOrder..", health "..v.Health..", attack "..v.AttackPower..", damage "..v.DamagePower);
			print ("SPECIAL APower "..v.AttackPower..", DPower "..v.DamagePower);
			print ("SPECIAL health "..v.Health);
			print ("SPECIAL APower% "..v.AttackPowerPercentage..", DPower% "..v.DamagePowerP);
			print ("SPECIAL DmgAbsorb "..v.DamageAbsorbedWhenAttacked..", DmgToKill "..v.DamageToKill..", Health "..v.Health);
		end

		--apply damage to this Special b/c combat order is <0 or armies have been processed already
		if (boolArmiesProcessed==true or v.CombatOrder <0) then
			print ("damage applied to Special");
		else
			--apply damage to armies
			print ("damage applied to Armies");
			boolArmiesProcessed = true;
		end

		--if (boolArmiesProcessed==false) then
		--v.Name..", combat order "..v.CombatOrder..", health "..v.Health..", attack "..v.AttackPower..", damage "..v.DamagePower);
		--[[if (v.proxyType == "Commander") then
			--Commanders have a combat order of 10,000, so process them first
			if (remainingDefenseDamage > 0) then
				--if the Commander is still alive, apply damage to it
				local CommanderHealth = v.Health;
				if (CommanderHealth > 0) then
					local CommanderDamage = math.min (CommanderHealth, remainingDefenseDamage);
					remainingDefenseDamage = remainingDefenseDamage - CommanderDamage;
					newResult.DefendingArmiesKilled = WL.Armies.Create (newResult.DefendingArmiesKilled.NumArmies + CommanderDamage, newResult.DefendingArmiesKilled.SpecialUnits);
				end
			end
		elseif (v.proxyType == "CustomSpecialUnit") then
			--CustomSpecialUnits have a combat order of 0, so process them after Commanders
			if (remainingDefenseDamage > 0) then
				--if the CustomSpecialUnit is still alive, apply damage to it
				local SpecialHealth = v.Health;
				if (SpecialHealth > 0) then
					local SpecialDamage = math.min (SpecialHealth, remainingDefenseDamage);
					remainingDefenseDamage = remainingDefenseDamage - SpecialDamage;
					newResult.DefendingArmiesKilled = WL.Armies.Create (newResult.DefendingArmiesKilled.NumArmies + SpecialDamage, newResult.DefendingArmiesKilled.SpecialUnits);
				end
			end
		end]]
	end
end

function applyDamageToSpecials (intDamage, Specials, result)
	local remainingDamage = intDamage;
	for k,v in pairs (Specials) do
		if (remainingDamage > 0) then
			--if the Special is still alive, apply damage to it
			local SpecialHealth = v.Health;
			if (SpecialHealth > 0) then
				local SpecialDamage = math.min (SpecialHealth, remainingDamage);
				remainingDamage = remainingDamage - SpecialDamage;
				result = WL.Armies.Create (result.NumArmies + SpecialDamage, result.SpecialUnits);
			end
		end
	end
	return result;
end

function generateSkipMessage (order, game)
	local strPercentInPlay = "% of";
	if (not order.ByPercent) then strPercentInPlay = ""; end
	local generateSkipMessage = "Original order: "..order.NumArmies.NumArmies.. strPercentInPlay .." armies";
	for _,v in pairs(order.NumArmies.SpecialUnits) do
		if (v.proxyType == "Commander") then
			generateSkipMessage = generateSkipMessage..", ".. v.proxyType;
		elseif (v.proxyType == "CustomSpecialUnit") then
			generateSkipMessage = generateSkipMessage..", ".. v.Name;
		end
	end
	generateSkipMessage = generateSkipMessage..", FROM ".. game.Map.Territories[order.From].Name..", TO "..game.Map.Territories[order.To].Name;
	return generateSkipMessage;
end

function resultantSetOfSpecials (origSpecials, currentOrderSpecials)
	local resultantSpecials = {};
	for _,v in pairs(origSpecials) do
		for _,v2 in pairs(currentOrderSpecials) do
			if (v2.proxyType == v.proxyType and v2.ID == v.ID) then
				table.insert(resultantSpecials, v);
				break;
			end
		end
	end
	return resultantSpecials;
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

function printDebug (strText)
	print (strText);
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end