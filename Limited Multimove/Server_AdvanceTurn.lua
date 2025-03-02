--[[
STILL TO DO:
- test with various specials, notably along the path, not included from beginning of a movement changing
- test with fixed # inputs
- test with %'s other than 100%
- currently adding # of units moving into a territory to map3, and this is fine for transfers, but for attacks it will be too many units as some will die in the attack so need to subtract the # of attacks killed
	^^ maybe skip the order & create new order with appropriate #'s in place instead of doing funky math, b/c "result.armies killed" will be wrong in many cases b/c we're changing the ActualArmies involved thus # attackers killed will change too
	^^ if did this, would it put the order in the right spot? or would it append it to end of order list? for multimove orders to work, the order of the orders is key
]]

function Server_AdvanceTurn_End(game, addNewOrder)
	--uncomment the below line to forcibly halt execution for troubleshooting purposes
	--print ("[FORCIBLY HALTED EXEUCTION @ END OF TURN]"); toriaezu_stop_execution();
	print ("[GRACEFUL END OF TURN EXECUTION]");
end

function Server_AdvanceTurn_Start (game,addNewOrder)
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
		map3[i] = 0;
	end
	print ("____________________Turn #"..game.ServerGame.Game.TurnNumber.."________ move limit "..Mod.Settings.MoveLimit);
end

function Server_AdvanceTurn_Order(game, order, result, skip, addNewOrder)
	if order.proxyType ~= "GameOrderAttackTransfer" then return; end --if order isn't an Attack or Transfer, nothing to do here, just skip to end of function

	local map2message = "map2FROM Armies (nil)/SU# (nil)";

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
	local numArmies;
	if (not order.ByPercent) then
		--order is a straight fixed # of armies
		numArmies = order.NumArmies.NumArmies;
	else
		--order is a %, need to calculate the true # of armies this % represents
		numArmies = math.floor (game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies / 100 * order.NumArmies.NumArmies + 0.5); --round to nearest int
	end

	print ("- - - - - - - - - - - - - - - - - - - - - PRE");
	print ("FROM "..order.From.."/"..game.Map.Territories[order.From].Name..", TO "..order.To.."/"..game.Map.Territories[order.To].Name..", IsAttack "..tostring (result.IsAttack)..", IsSuccessful "..tostring(result.IsSuccessful) ..", AttackTransfer "..tostring(order.AttackTransfer));
	print ("FROM owner "..FROMowner..", TO owner "..TOowner..", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies..", AttackingSpecialsKilled "..#result.AttackingArmiesKilled.SpecialUnits..", DefendingArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", DefendingSpecialsKilled "..#result.DefendingArmiesKilled.SpecialUnits);
	print ("NumArmies "..order.NumArmies.NumArmies..", #specials "..#order.NumArmies.SpecialUnits ..", ActualSpecials "..#result.ActualArmies.SpecialUnits..", ActualArmies "..result.ActualArmies.NumArmies..
	", ArmiesOnTerritory "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies..", specialsOnTerritory "..#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits);
	print ("map1FROM "..tostring (map1[order.From])..", map1TO "..tostring (map1[order.To])..", " ..map2message..", map3FROM "..map3[order.From]..", map3TO "..map3[order.To]);

	-- START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- START OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- So far ... I can detect the case when the glitch will happen but can't fix it, even by recreating the order with the same # of armies & specials, even if forcing it to an Attack Only setting

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
		local newNewArmiesStructureFG = WL.Armies.Create(newNumArmiesCountFG, newSpecialsFG);

		--[[if (not order.ByPercent) then
			--order is a straight fixed # of armies
			newNumArmiesCountFG = order.NumArmies.NumArmies;
		else
			--order is a %, need to calculate the true # of armies this % represents
			newNumArmiesCountFG = math.floor (game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies / 100 * order.NumArmies.NumArmies + 0.5); --round to nearest int
		end]]

		--don't do this for now -- it doesn't work, WZ overrides the attempt and just makes it a Transfer again regardless, so just SKIP all FizzGlitch orders for now
		--recreate the order, forcingg it to be an Attack order (Attack Only, no transfer)
		if (false) then --(problematicOrderCount==1) then
		--if (problematicOrderCount==1) then
				--local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack --[[order.AttackTransfer]], order.ByPercent, order.NumArmies, order.AttackTeammates);
			--local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack --[[order.AttackTransfer]], order.ByPercent, newNewArmiesStructureFG, order.AttackTeammates);
			local replacementOrder = WL.GameOrderAttackTransfer.Create (order.PlayerID, order.From, order.To, WL.AttackTransferEnum.Attack --[[order.AttackTransfer]], false, newNewArmiesStructureFG, false);
			addNewOrder (replacementOrder);
			print ("[RECREATE & SKIP ORDER]");
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
			return; --skip rest of this function, skip this order b/c it can't be implemented until the WZ bug is fixed
		end

		--FizzGlitch order can't be worked around by anything I've tried so far, so just skip it, wait for the WZ fix
		if (true) then
		--if (problematicOrderCount==2) then
			--toriaezu_stop_execution();  --forcibly halt execution for troubleshooting purposes
			local strSkipOrderMessage = "[FizzGlitch condition] Order skipped to avoid WZ error or transfer to enemy [requires WZ bug fix]; Original order: " ..genereateSkipMessage (order, game);
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			print ("[SKIP ORDER]");
			return; --skip rest of this function, skip this order b/c it can't be implemented until the WZ bug is fixed
		end
		--toriaezu_stop_execution();
	end
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- END OF FIZZ TRANSFER GLITCH TROUBLESHOOTING -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	--only process the order if the FROM territory is owned by the order player
	if (FROMowner == order.PlayerID and Mod.Settings.MoveLimit ~= 0 and boolUnitsPresentOnFROMterritory) then --if MoveLimit == 0, no moves are allowed, just skip the order
		-- if order player owns FROM territory, there are units on the territory and MoveLimit isn't set to 0, inspect the order details to see if it can be processed

		local boolMoveUnitsTransferredIn = false;
		local boolMoveUnitsOnTerritoryAtStartOfTurn = false;
		local boolProcessOrder = false;
		local boolSkipOrder = false;
		if (map1FROM > 0 or map1FROM <= -1) then boolMoveUnitsTransferredIn = true; end
		if ((map2FROMarmies ~= nil and map2FROMarmies > 0) or (map2FROMspecials ~= nil and #map2FROMspecials > 0)) then boolMoveUnitsOnTerritoryAtStartOfTurn = true; end

		--if units transferred into the FROM territory have move allocations left, move all units specified in numArmies
		if boolMoveUnitsTransferredIn == true then
			--if units have transferred into the FROM territory, then the map1 value for the FROM territory is irrelevant, it's only important when groups of armies mix that we use the lowest of the two map1 values
			boolProcessOrder = true;
			result.ActualArmies = WL.Armies.Create(numArmies, order.NumArmies.SpecialUnits);

			---if Transfer, use min Map1 value of FROM & TO territories, b/c order player owns To and it might already have less move allocations less than From-1
			---if Attack, ignore TO territory map value b/c that's the value for another player (or a neutral)
			if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer and there are units on the TO territory (so must use the min map1 value of the FROM and TO territories)
				map1[order.To] = math.min(map1FROM - 1, map1TO); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
			else --order is an Attack or a Transfer to a territory with 0 units (in which case the map1 value for those units is no longer relevant, it's only important when groups of armies mix that we use the lowest of the two map1 values)
				map1[order.To] = map1FROM - 1; --subtract one from the map1 table, representing 1 less movement available for the units on this territory; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
			end
			map2[order.From] = nil; --indicate that the units on the FROM territory have been moved

			--if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
			if (result.IsAttack==true and result.IsSuccessful==true) then map2[order.To] = nil; end

			--COMMENT FOR BELOW: map3 isn't used at this point; perhaps it could be but I think the current state is likely the best while keeping it simple (ie: not tracking the # of moves for every separate group of units and then having the user indicate which groups are moving where)
			--if there are no movement allocations left on the TO territory, add them to map3 to indicate that they can't move anymore
			if (map1TO == 0) then map3[order.To] = map3[order.To]-(numArmies-result.AttackingArmiesKilled.NumArmies); end --simplified for now, need to do for both armies & specials

		--units transferred into FROM territory so far have no move allocations left, so check if units on the territory at start of turn have moved yet, if not, move them; if they have moved, skip the order
		elseif boolMoveUnitsOnTerritoryAtStartOfTurn == true then
			boolProcessOrder = true;
			local newNumArmies = math.min (numArmies, map2[order.From].NumArmies); --use the lesser of the # of armies the player entered or the quantity present at start of turn (b/c all other units have no movement allocations left)
			local newSpecials = resultantSetOfSpecials (map2[order.From].SpecialUnits, order.NumArmies.SpecialUnits); --create new list of Specials that is the intersection of what's included in the list of Specials originally on the territory & what's included in the order (anything else was either killed or not included in the order)
			result.ActualArmies = WL.Armies.Create(newNumArmies, newSpecials);

			--if map2 value==nil, the units on this territory have moved already, and the map1 calc already down above indicates that these units can't move any farther, so skip the order (go down to the ELSE clause)
			--if map2 value==0 for both NumArmies & Specials then there are no units on the territory to be moved; in both cases, skip the order, there's nothing to do here (go down to the ELSE clause)

			--adjust map1, map2 values
			if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer with units on the TO territory, so use min of Mod.Settings.MoveLimit (b/c these FROM units haven't moved yet this turn) & Map1 value of TO territory
				map1[order.To] = math.min(Mod.Settings.MoveLimit - 1, map1TO); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
			else --order is an Attack or a Transfer with no units on the TO territory, so just use Mod.Settings.MoveLimit - 1
				map1[order.To] = Mod.Settings.MoveLimit - 1; --subtract one from Mod.Settings.MoveLimit b/c these units haven't moved yet; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
			end

			map2[order.From] = nil; --indicate that the units on the FROM territory have been moved and any units that arrive should be moved according to their regular movement allocation
			map3[order.To] = map3[order.To]-newNumArmies; --simplified for now, need to do for both armies & specials

			--if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
			if (result.IsAttack==true and result.IsSuccessful==true) then map2[order.To] = nil; end

		else --skip the order
			--no movement allocation remaining for the units on FROM territory, and the units that were on this territory have already moved or their quantity is 0, in any cases, no units can move, so skip the order
			local strSkipOrderMessage = "Order skipped, units have no movement allocations remaining; Original order: " ..genereateSkipMessage (order, game);
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
		end

	------------------------------------ end of new coding ------------------------------------
	---------------------OLD CODE--------------------------


	--only process the order if the FROM territory is owned by the order player
	--[[if (game.ServerGame.LatestTurnStanding.Territories[order.From].OwnerPlayerID == order.PlayerID and Mod.Settings.MoveLimit ~= 0) then --if MoveLimit == 0, no moves are allowed, just skip the order
		-- if FROM territory (?for this specific order player?) has transfers left, process the order
		--FOR TROUBLESHOOTING ONLY!!! --> if (map1[order.From] >= 0 or map1[order.From] <= -1) then --if value is <=-1, this means unlimited so always permit; orig set to -1, and then -1 for each move done; could just keep it constant @ -1 but this might be useful some time later (not sure though)
		if (map1[order.From] > 0 or map1[order.From] <= -1) then --if value is <=-1, this means unlimited so always permit; orig set to -1, and then -1 for each move done; could just keep it constant @ -1 but this might be useful some time later (not sure though)
			--result.ActualArmies represents the # of armies & the specials that the WZ engine deems correct to move with this order; for attacks, they'll all continue attacking forever
			--but for transfers, they'll stop after the first transfer; by overriding this and setting the #armies & the table of SpecialUnits moving within result.ActualArmies, we can
			--force transfers to occur
			result.ActualArmies = WL.Armies.Create(numArmies, order.NumArmies.SpecialUnits);
			--result.ActualArmies = WL.Armies.Create(numArmies, order.NumArmies.SpecialUnits);

			---if Transfer, use min Map1 value of FROM & TO territories, b/c order player owns To and it might already have less move allocations less than From-1
			---if Attack, ignore TO territory map value b/c that's the value for another player (or a neutral)
			if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer and there are units on the TO territory (so must use the min map1 value of the FROM and TO territories)
				map1[order.To] = math.min(map1[order.From] - 1, map1[order.To]); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
			else --order is an Attack or a Transfer to a territory with 0 units (in which case the map1 value for those units is no longer relevant, it's only important when groups of armies mix that we use the lowest of the two map1 values)
				map1[order.To] = map1[order.From] - 1; --subtract one from the map1 table, representing 1 less movement available for the units on this territory; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
			end
			map2[order.From] = nil; --indicate that the units on the FROM territory have been moved

			--COMMENT FOR BELOW: map3 isn't used at this point; perhaps it could be but I think the current state is likely the best while keeping it simple (ie: not tracking the # of moves for every separate group of units and then having the user indicate which groups are moving where)
			--if there are no movement allocations left on the TO territory, add them to map3 to indicate that they can't move anymore
			if (map1[order.To] == 0) then map3[order.To] = map3[order.To]-(numArmies-result.AttackingArmiesKilled.NumArmies); end --simplified for now, need to do for both armies & specials

			--if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
			if (result.IsAttack==true and result.IsSuccessful==true) then map2[order.To] = nil; end

		else
			--map1 value indicates that the FROM territory does not have any transfers left, so the units that transferred into the FROM territory cannot move anymore
			--check map2 value, if nil it indicates that the units that were on the FROM territory at start of turn have moved already, so just use map1 to decide if movement is permitted or not
			--if map2 value ~= nil then those armies & specials can move (but the order still may not include all the armies or specials)

			--if order is a successful attack, then clear map2 for the TO territory b/c this count represents units belonging to another player or a neutral territory, so don't include them in any calculations
			if (result.IsAttack==true and result.IsSuccessful==true) then map2[order.To] = nil; end

			--local newNumArmies = math.max (0, math.min (numArmies, map2[order.From].NumArmies), numArmies + map3[order.From]); --map3 holds the negative #'s of armies that should not be moved, so add them to numArmies to get the real moving army count
			local newNumArmies = math.min (numArmies, map2[order.From].NumArmies); --use the lesser of the # of armies the player entered or the quantity present at start of turn (b/c all other units have no movement allocations left)
			local newSpecials = resultantSetOfSpecials (map2[order.From].SpecialUnits, order.NumArmies.SpecialUnits); --create new list of Specials that is the intersection of what's included in the list of Specials originally on the territory & what's included in the order (anything else was either killed or not included in the order)
			if (map2[order.From]~=nil and boolUnitsPresentOnFROMterritory == true) then
				--if map2 value==nil, the units on this territory have moved already, and the map1 calc already down above indicates that these units can't move any farther, so skip the order (go down to the ELSE clause)
				--if map2 value==0 for both NumArmies & Specials then there are no units on the territory to be moved; in both cases, skip the order, there's nothing to do here (go down to the ELSE clause)
				--for transfers, technically could do nothing (but we won't) and let the units go as-is, WZ native engine handles this as we need it here
				--for attacks, need to adjust b/c WZ would let attacks continue indefinitely

				result.ActualArmies = WL.Armies.Create(newNumArmies, newSpecials); --technically this sends all Special Units that were on the territory to begin with regardless of what the order was

				-- the units moving have movement allocations == Mod.Settings.MoveLimit - 1 after this order is completed, b/c they haven't moved yet (they were on the territory from start of turn)
				-- if Transfer, use min of Mod.Settings.MoveLimit & Map1 value of TO territory, b/c order player owns TO and it might already have less move allocations less than Mod.Settings.MoveLimit
				-- if Attack, ignore TO territory map1 value b/c that's the value for another player (or a neutral) so just use Mod.Settings.MoveLimit - 1
				if (result.IsAttack==false and boolUnitsPresentOnTOterritory==true) then --order is a Transfer with units on the TO territory, so use min of Mod.Settings.MoveLimit (b/c these FROM units haven't moved yet this turn) & Map1 value of TO territory
					map1[order.To] = math.min(Mod.Settings.MoveLimit - 1, map1[order.To]); --subtract one from the map1 table, representing 1 less movement available for the units on this territory; if the TO map value is lower, use that instead
				else --order is an Attack or a Transfer with no units on the TO territory, so just use Mod.Settings.MoveLimit - 1
					map1[order.To] = Mod.Settings.MoveLimit - 1; --subtract one from Mod.Settings.MoveLimit b/c these units haven't moved yet; ignore TO territory map value b/c it relates to another player or a neutral territory or it's a Transfer and those units have already moved and thus their map1 value is irrelevant
				end

				map2[order.From] = nil; --indicate that the units on the FROM territory have been moved and any units that arrive should be moved according to their regular movement allocation
				map3[order.To] = map3[order.To]-numArmies; --simplified for now, need to do for both armies & specials
			else
				--no movement allocation remaining for the units on FROM territory, and the units that were on this territory have already moved or their quantity is 0, in any cases, no units can move, so skip the order
				--skip (WL.ModOrderControl.Skip); --skip this order
				--message: skipped b/c you are out of allocations
				local strSkipOrderMessage = "Order skipped, units have no movement allocations remaining; Original order: " ..genereateSkipMessage (order, game);
				addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, strSkipOrderMessage, {}, {},{}));
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
			end
		end]]
	else
		--skip the order, order player does not own the FROM territory or Mod.Settings.MoveLimit == 0 which means no Attack/Transfer orders are possible (captures/etc must be done by other means, cards/mods/etc)
		--skip (WL.ModOrderControl.Skip); --skip this order
		--message:: skipped b/c you don't own the territory; is this required? at least indicate which move is being skipped
		local strSkipOrderMessage = "Order skipped, you do not own source territory; Original order: ";
		if (Mod.Settings.MoveLimit == 0) then strSkipOrderMessage = "Order skipped, Move Limit is set to 0, standard Attack/Transfers are disabled; Original order: "; end
		strSkipOrderMessage = strSkipOrderMessage .. genereateSkipMessage (order, game);
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
	print ("FROM "..order.From.."/"..game.Map.Territories[order.From].Name..", TO "..order.To.."/"..game.Map.Territories[order.To].Name..", IsAttack "..tostring (result.IsAttack)..", IsSuccessful "..tostring(result.IsSuccessful));
	print ("NumArmies "..order.NumArmies.NumArmies..", #specials "..#order.NumArmies.SpecialUnits ..", ActualSpecials "..#result.ActualArmies.SpecialUnits..", ActualArmies "..result.ActualArmies.NumArmies..
	", ArmiesOnTerritory "..game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.NumArmies..", specialsOnTerritory "..#game.ServerGame.LatestTurnStanding.Territories[order.From].NumArmies.SpecialUnits);
	print ("map1FROM "..tostring (map1[order.From])..", map1TO "..tostring (map1[order.To])..", " ..map2message..", map3FROM "..map3[order.From]..", map3TO "..map3[order.To]);
end

function genereateSkipMessage (order, game)
	local strPercentInPlay = "% of";
	if (not order.ByPercent) then strPercentInPlay = ""; end
	local genereateSkipMessage = "Original order: "..order.NumArmies.NumArmies.. strPercentInPlay .." armies";
	for _,v in pairs(order.NumArmies.SpecialUnits) do
		if (v.proxyType == "Commander") then
			genereateSkipMessage = genereateSkipMessage..", ".. v.proxyType;
		elseif (v.proxyType == "CustomSpecialUnit") then
			genereateSkipMessage = genereateSkipMessage..", ".. v.Name;
		end
	end
	genereateSkipMessage = genereateSkipMessage..", FROM ".. game.Map.Territories[order.From].Name..", TO "..game.Map.Territories[order.To].Name;
	return genereateSkipMessage;
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