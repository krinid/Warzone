require("utilities");
require("Client_PresentMenuUI");

function Client_GameOrderCreated (game, gameOrder, skip)
    --local strCardTypeBeingPlayed = nil;
	--local cardOrderContentDetails = nil;
	--local publicGameData = Mod.PublicGameData;

    print ("[C_GOC] START");
	print ("[C_GOC] gameOrder proxyType=="..gameOrder.proxyType.."::");
    --UI.Alert ("Checking orders");
	--printObjectDetails (gameOrder, "gameOrder", "C_GOC"); --*** this LOC causes the WZ generic error when the order passed in is an Airlift order

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires submitting an order, which they can't do b/c they're not in the game)

	process_game_order_ImmovableSpecialUnits (game,gameOrder,skip);
	process_game_order_entry_CardBlock (game,gameOrder,skip);
	process_game_order_entry_RegularCards (game,gameOrder,skip);
	process_game_order_entry_CustomCards (game,gameOrder,skip);
	process_game_order_entry_AttackTransfers (game,gameOrder,skip);

    print ("[C_GOC] END");
end

function process_game_order_ImmovableSpecialUnits (game,gameOrder,skip);
	--check if an AttackTransfer or an Airlift contains an immovable piece (ie: Special Units for Isolation, Quicksand, Shield, Monolith, any others?) and if so, remove the special but leave the rest of the order as-is
	if (gameOrder.proxyType=='GameOrderAttackTransfer' or gameOrder.proxyType == 'GameOrderPlayCardAirlift') then
		--check any Special Units in the armies include in the AttackTransfer or Airlift operation
		local orderArmies = nil;
		if (gameOrder.proxyType=='GameOrderAttackTransfer') then orderArmies = gameOrder.NumArmies; end
		if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then orderArmies = gameOrder.Armies; end
		if (#orderArmies.SpecialUnits >= 1) then --if there are no specials, take no further action, let the order proceed; if there are specials, check if they are one of the immovable types
			local specialUnitsToRemoveFromOrder = {};
			for _, unit in pairs(orderArmies.SpecialUnits) do
				if (unit.proxyType == "CustomSpecialUnit") then --ignore non-custom special units (which I think is just Commanders? Actually maybe the Boss units are non-custom specials too)
					local strModData = tostring(unit.ModData);
					print ("[___________special] ModData=="..strModData..", Name=="..unit.Name..", numArmies=="..orderArmies.NumArmies.."::");
					--print ("ModData contains 'CCPA|Immovable'=="..tostring (startsWith (strModData, "CCPA|Immovable")));
					if (unit.Name == "Monolith") or (unit.Name == "Shield") or (unit.Name == "Neutralize") or (unit.Name == "Quicksand") or (unit.Name == "Isolation") or (unit.Name == "Tornado") or (unit.Name == "Earthquake") or (unit.Name == "Nuke") or (unit.Name == "Pestilence") or (unit.Name == "Forest Fire") then
						--some of these cards don't currently have special units, but including them here so if they do, this code is already in place
						print ("Immovable Special==true --> block movement of this unit! (but let everything else go forward)");
						table.insert(specialUnitsToRemoveFromOrder, unit);
					end
				end
			end
			if (#specialUnitsToRemoveFromOrder > 0) then --tablelength>0 indicates that CCPA Immovable specials were found
				local replacementOrder = nil;

				--create new Armies structure with 0 regular armies & the Immovable Specials identified in the specialUnitsToRemoveFromOrder table, then "subtract" it from the Armies structure from the original order (orderArmies)
				--then assign it to numArmies, then make a new order using newArmies and keep all other aspects of the order the same; handle cases for both Attack/Transfer & Airlift; then skip the original order; result is same order minus the Immovable Specials
				local numArmies = orderArmies.Subtract(WL.Armies.Create(0, specialUnitsToRemoveFromOrder));
				print ("Immovable Specials present==true --> numArmies=="..numArmies.NumArmies);

				if (gameOrder.proxyType=='GameOrderAttackTransfer') then replacementOrder = WL.GameOrderAttackTransfer.Create(gameOrder.PlayerID, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, numArmies, gameOrder.AttackTeammates); end
				if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then replacementOrder = WL.GameOrderPlayCardAirlift.Create(gameOrder.CardInstanceID, gameOrder.PlayerID, gameOrder.FromTerritoryID, gameOrder.ToTerritoryID, numArmies); end

				--can't figure out how to have this code in 4 mods all acting on the same order; they all receive and process the original order, then try to add the newly created order sans immovable SUs
				--and the 2nd mod to try fails and throws an error
				--until I can figure out & implement a fix for this, don't re-add the corrected order, just display an alert and let the user do it manually
				--UI.Alert ("Please unselect all immovable Special Units in your order (Monolith, ,Shield, Neutralize, Quicksand, Isolation)");
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)

				print ("ORDERS:");
				local boolSameOrderExistsAlready = false; --indicates whether an order for A->B already exists in the order list; if so, assume it's legit and skip this order
				--need to do this b/c each of he 4 CardPack mods tries to process the original order and recreate it as an order with no Immovable Specials, generating an error due to inserting multiple A->B orders
				for k,existingGameOrder in pairs (game.Orders) do
					print (k..", "..existingGameOrder.proxyType);
					if (existingGameOrder.proxyType == "GameOrderAttackTransfer") then
						print ("player "..existingGameOrder.PlayerID..", FROM "..existingGameOrder.From..", TO "..existingGameOrder.To..", AttackTransfer "..tostring (existingGameOrder.AttackTransfer)..", ByPercent "..tostring(existingGameOrder.ByPercent).. ", #armies"..existingGameOrder.NumArmies.NumArmies..", #SUs "..#existingGameOrder.NumArmies.SpecialUnits..", AttackTeammates "..tostring (existingGameOrder.AttackTeammates));
						if (gameOrder.From == existingGameOrder.From and gameOrder.To == existingGameOrder.To) then print ("**********ORDER EXISTS ALREADY, don't re-add**********"); boolSameOrderExistsAlready = true; end
					end
				end

				--only do this is an order for territory A->B doesn't exist yet; if it does, it'll throw an error on user client; each of the 4 Card Pack mods will try to recreate the order w/o Immovable Specials
				--leverage 'boolSameOrderExistsAlready' to ensure that only the 1st mod actually inserts the corrected order 
				if (boolSameOrderExistsAlready == false) then
					--b/c this function has no addOrder callback parameter, need to manually add the order into the clientgame parameter 'game'
					local orders = game.Orders;
					table.insert(orders, replacementOrder);
					game.Orders = orders;
					skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
					--skip (WL.ModOrderControl.Skip, false); --skip the original order with an Immovable Special Unit
				end
			end
		end
	end
end

--check if player is playing a card and is impacted by CardBlock; skip the order if so
function process_game_order_entry_CardBlock (game,gameOrder,skip)
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardBlock ~= true) then return; end --if module isn't active for this mod, do nothing, just return

	--check if order is a card play (could be regular or custom card)
    if startsWith (gameOrder.proxyType, 'GameOrderPlayCard') == true then
        print ("[CARD PLAY]");
        --check for card plays by players impacted by CardBlock, and skip the order if so; include Reinforcements card in the block b/c this is client order entry time, so can stop it entirely
        if (Mod.PublicGameData.CardBlockData[game.Us.ID] ~= nil) then
            print ("[CARD BLOCK] true");
            --if (check_for_CardBlock == true) then
            --player has played a card but is impacted by CardBlock, skip this order
            UI.Alert ("You cannot play a card, because a Card Block has been used against you and is still active.");
            skip (WL.ModOrderControl.SkipAndSupressSkippedMessage);
        else
            print ("[CARD BLOCK] false");
        end
    end
end

function process_game_order_entry_CustomCards (game,gameOrder,skip)
    --check for Custom Card plays
	--NOTE: proxyType=='GameOrderPlayCardCustom' indicates that a custom card played; but these can't be placed in the order list at a specific point, it just applies in the position according to regular move order
	--so for now, ignore this; re-implement this when Fizz updates so these can placed at the proper execution point, eg: start of turn, after deployments, after attacks, etc
	if (gameOrder.proxyType=='GameOrderPlayCardCustom') then
		local modDataContent = split(gameOrder.ModData, "|");
		--printObjectDetails (gameOrder, "gameOrder", "[TurnAdvance_Order]");
		print ("[GameOrderPlayCardCustom] modData=="..gameOrder.ModData.."::");
		strCardTypeBeingPlayed = nil;
		cardOrderContentDetails = nil;
		strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type
		
		print ("[C_GOC] cardType=="..tostring (strCardTypeBeingPlayed).."::cardOrderContent=="..tostring(cardOrderContentDetails));
		if (strCardTypeBeingPlayed == "Nuke") then
			--execute_Nuke_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Isolation" then
			--execute_Isolation_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Pestilence" then
			--execute_Pestilence_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Shield") then
			--execute_Shield_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Monolith" then
			--execute_Monolith_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails))
		elseif strCardTypeBeingPlayed == "Neutralize" then
			--execute_Neutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Deneutralize" then
			--execute_Deneutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Airstrike" then
			--Airstrike details go here
		elseif strCardTypeBeingPlayed == "Card Piece" then
			--execute_CardPiece_operation(game, gameOrder, skip, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Forest Fire" then
			--Forest Fire details go here
		elseif strCardTypeBeingPlayed == "Card Block" then
			--execute_CardBlock_play_a_CardBlock_Card_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Earthquake" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Earthquake == true)) then
			--execute_Earthquake_order_input(game,gameOrder,skip, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Tornado" then
			--execute_Tornado_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Quicksand" then
			--execute_Quicksand_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		else
			--custom card play not handled by this mod; could be an error, or a card from another mod
			--do nothing
		end
	end
end

function process_game_order_entry_RegularCards (game,gameOrder,skip)
    --if there's no QuicksandData, do nothing (b/c there's nothing to check)
    local boolQuicksandAirliftViolation = false;
    local strAirliftSkipOrder_Message="";

    --check for regular card plays
	if (gameOrder.proxyType == 'GameOrderPlayCardAirlift') then
		--check if Airlift is going in/out of Isolated territory or out of a Quicksanded territory; if so, cancel the move
		print ("[AIRLIFT PLAYED] FROM "..gameOrder.FromTerritoryID.."/"..getTerritoryName (gameOrder.FromTerritoryID, game)..", TO "..gameOrder.ToTerritoryID.."/"..getTerritoryName (gameOrder.ToTerritoryID, game)..", #armies=="..gameOrder.Armies.NumArmies.."::");

        if ((Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Quicksand ~= true) or Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] == nil)) then
            --do nothing, there are no Quicksand operations in place, permit these orders
            --weed out the cases above, then what's left are Airlifts to or from Isolated territories
        else
            --block airlifts IN/OUT of the quicksand as per the mod settings
            if (Mod.Settings.QuicksandBlockAirliftsIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] ~= nil and Mod.Settings.QuicksandBlockAirliftsFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] ~= nil) then
                strAirliftSkipOrder_Message="Airlift cannot be executed because source and target territories have quicksand, and quicksand is configured so you can neither airlift in or out of quicksand";
                boolQuicksandAirliftViolation = true;
            elseif (Mod.Settings.QuicksandBlockAirliftsIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] ~= nil) then
                strAirliftSkipOrder_Message="Airlift cannot be executed because target territory has quicksand, and quicksand is configured so you cannot airlift into quicksand";
                boolQuicksandAirliftViolation = true;
            elseif (Mod.Settings.QuicksandBlockAirliftsFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] ~= nil) then
                strAirliftSkipOrder_Message="Airlift cannot be executed because source territory has quicksand, and quicksand is configured so you cannot airlift out of quicksand";
                boolQuicksandAirliftViolation = true;
            else
                --arriving here means there are no conditions where the airlift direction is being blocked, so let it proceed
                --strAirliftSkipOrder_Message="Airlift failed due to unknown quicksand conditions";
                boolQuicksandAirliftViolation = false; --this is the default but restating it here for clarity
            end
            
            --skip the order if a violation was flagged in the IF structure above
            if (boolQuicksandAirliftViolation==true) then
                strAirliftSkipOrder_Message=strAirliftSkipOrder_Message..".\n\nOriginal order was an Airlift from "..getTerritoryName (gameOrder.FromTerritoryID, game).." to "..getTerritoryName(gameOrder.ToTerritoryID, game)..".";
                print ("[AIRLIFT/QUICKSAND] skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.FromTerritoryID .."/"..getTerritoryName (gameOrder.FromTerritoryID, game).."::, to="..gameOrder.ToTerritoryID .."/"..getTerritoryName(gameOrder.ToTerritoryID, game).."::"..strAirliftSkipOrder_Message.."::");
                UI.Alert (strAirliftSkipOrder_Message);
                skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
            end
        end

		--if there's no IsolationData, do nothing (b/c there's nothing to check)
		if ((Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Isolation ~= true) or Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] == nil)) then
			--do nothing, there are no Isolation operations in place, permit these orders
			--weed out the cases above, then what's left are Airlifts to or from Isolated territories
		else
			local strAirliftSkipOrder_Message="";
			if (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift cannot be executed because source and target territories are isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] == nil) then
				strAirliftSkipOrder_Message="Airlift cannot be executed because target territory is isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift cannot be executed because source territory is isolated";
			else
				strAirliftSkipOrder_Message="Airlift cannot be executed due to unknown isolation conditions";
			end
			strAirliftSkipOrder_Message=strAirliftSkipOrder_Message..".\n\nOriginal order was an Airlift from "..getTerritoryName (gameOrder.FromTerritoryID, game).." to "..getTerritoryName(gameOrder.ToTerritoryID, game)..".";
			print ("[AIRLIFT/ISOLATION] skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.FromTerritoryID .."/"..getTerritoryName (gameOrder.FromTerritoryID, game).."::, to="..gameOrder.ToTerritoryID .."/"..getTerritoryName(gameOrder.ToTerritoryID, game).."::"..strAirliftSkipOrder_Message.."::");
            UI.Alert (strAirliftSkipOrder_Message);
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage);
		end
	end
end

function process_game_order_entry_AttackTransfers (game,gameOrder,skip)
	--check ATTACK/TRANSFER orders to see if any rules are broken and need intervention, eg: moving TO/FROM an Isolated territory or OUT of Quicksanded territory
	if (gameOrder.proxyType=='GameOrderAttackTransfer') then
		--print ("[[  ATTACK // TRANSFER ]] check for Isolation, player "..gameOrder.PlayerID..", TO "..gameOrder.To..", FROM "..gameOrder.From.."::");

    --check for Attack/Transfers into/out of quicksand that violate the rules configured in Mod.Settings.QuicksandBlockEntryIntoTerritory & Mod.Settings.QuicksandBlockExitFromTerritory
    --if there's no QuicksandData, do nothing (b/c there's nothing to check)
        if ((Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Quicksand ~= true) or Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.To] == nil and Mod.PublicGameData.QuicksandData[gameOrder.From] == nil)) then
            --do nothing, permit these orders
            --weed out the cases above, then what's left are moves to or from Isolated territories
        else
            local strQuicksandSkipOrder_Message="";
            local boolQuicksandAttackTransferViolation = false;
            --block moves IN/OUT of the quicksand as per the mod settings
            if (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil and Mod.Settings.QuicksandBlockExitFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since source and target territories have quicksand, and quicksand is configured so you can neither move in or out of quicksand";
				boolQuicksandAttackTransferViolation = true;
            elseif (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since target territory has quicksand, and quicksand is configured so you cannot move into quicksand";
				boolQuicksandAttackTransferViolation = true;
            elseif (Mod.Settings.QuicksandBlockExitFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since source territory has quicksand, and quicksand is configured so you cannot move out of quicksand";
				boolQuicksandAttackTransferViolation = true;
            else
				--arriving here means there are no conditions where the AttackTransfer direction is being blocked, so let it proceed
				--strAttackTransferSkipOrder_Message="AttackTransfer failed due to unknown quicksand conditions";
				boolQuicksandAttackTransferViolation = false; --this is the default but restating it here for clarity
            end
            
			--skip the order if a violation was flagged in the IF structure above
			if (boolQuicksandAttackTransferViolation==true) then
                strQuicksandSkipOrder_Message=strQuicksandSkipOrder_Message..".\n\nOriginal order was an Attack/Transfer from "..game.Map.Territories[gameOrder.From].Name.." to "..game.Map.Territories[gameOrder.To].Name..".";
                print ("QUICKSAND - skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.From .."/"..game.Map.Territories[gameOrder.From].Name.."::,to="..gameOrder.To .."/"..game.Map.Territories[gameOrder.To].Name.."::"..strQuicksandSkipOrder_Message.."::");
                UI.Alert (strQuicksandSkipOrder_Message);
                skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
            end
        end

		--if there's no IsolationData, do nothing (b/c there's nothing to check)
		if ((Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Isolation ~= true) or Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.To] == nil and Mod.PublicGameData.IsolationData[gameOrder.From] == nil)) then
			--do nothing, permit these orders
			--weed out the cases above, then what's left are moves to or from Isolated territories
		else
			local strIsolationSkipOrder_Message="";

			if (Mod.PublicGameData.IsolationData[gameOrder.To] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.From] ~= nil) then
				strIsolationSkipOrder_Message="Cannot execute this order because source and target territories are isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.To] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.From] == nil) then
				strIsolationSkipOrder_Message="Cannot execute this order because target territory is isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.To] == nil and Mod.PublicGameData.IsolationData[gameOrder.From] ~= nil) then
				strIsolationSkipOrder_Message="Cannot execute this order because source territory is isolated";
			end
			strIsolationSkipOrder_Message=strIsolationSkipOrder_Message..".\n\nOriginal order was an Attack/Transfer from "..game.Map.Territories[gameOrder.From].Name.." to "..game.Map.Territories[gameOrder.To].Name..".";
            UI.Alert (strIsolationSkipOrder_Message);
			print ("ISOLATION - skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.From .."/"..game.Map.Territories[gameOrder.From].Name.."::,to="..gameOrder.To .."/"..game.Map.Territories[gameOrder.To].Name.."::"..strIsolationSkipOrder_Message.."::");
			--addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strIsolationSkipOrder_Message, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
		end
	end
end

--return true if this order is a card play by a player impacted by Card Block; include block on Reinforcement cards b/c it's @ client order time, so can stop it entirely!
function check_for_CardBlock ()
    local publicGameData = Mod.PublicGameData;
    local targetPlayerID = game.Us.ID;

    --if CardBlock isn't in use, just return false
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardBlock ~= true) then return false; end
	if (Mod.Settings.CardBlockEnabled == false) then return false; end

    --if there is no CardBlock data, just return false
    local numCardBlockDataRecords = tablelength (publicGameData.CardBlockData);
    if (numCardBlockDataRecords == 0) then return false; end

    --check if order is a card play (could be regular or custom card play)
    if (string.find (gameOrder.proxyType, "GameOrderPlayCard") ~= nil) then
        print ("[ORDER::CARD PLAY] player=="..gameOrder.PlayerID..", proxyType=="..gameOrder.proxyType.."::_____________________");

        --check if player this order is for is impacted by Card Block
        if (publicGameData.CardBlockData[targetPlayerID] == nil) then
            --no CardBlock data exists, so don't check, just return with don't block result (return value of false)
            print ("[CARD BLOCK DATA dne] don't skip this order");
            return false;
        else
            --CardBlock data exists, this user is being CardBlocked! Check if the order is a card play, and if so (and it's not a Reinf card), skip the order
            print ("[CARD BLOCK DATA exists] skip this order");
            UI.Alert ("You cannot play a card, because a Card Block has been used against and is still active.");
            return true;
        end
    end
end

function execute_Earthquake_order_input (game, gameOrder, skip, bonusID)
	--print ("[EARTHQUAKE] target bonus=="..bonusID.. "::");--..getBonusName (tonumber(bonusID), game).."::");
	--print ("[EARTHQUAKE] target bonus=="..bonusID.. "/"..getBonusName (tonumber(bonusID), game).."::");
	print ("[EARTHQUAKE] target bonus=="..bonusID.. "/"..game.Map.Bonuses[bonusID].Name.."::");

	if (game==nil) then print ("!!game is nil"); end
	if (game.Map==nil) then print ("!!game.Map is nil"); end
	if (game.Map.Bonuses==nil) then print ("!!game.Map.Bonuses is nil"); end

	--originally intended to add a 'JumpToActionSpotOpt' event to the order but there's no avenue to add an order, it's just skip or not
	--sooooo, this function does nothing now, lol

	--local event = WL.GameOrderEvent.Create(game.Us.ID, "[EARTHQUAKE] target bonus=="..bonusID.. "/"..getBonusName (bonusID, game), {}, {});
	local XYbonusCoords = getXYcoordsForBonus (tonumber(bonusID), game);
	--print ("ave X,Y=="..XYbonusCoords.average_X..","..XYbonusCoords.average_Y);
	--print ("min/max X/Y=="..XYbonusCoords.min_X..","..XYbonusCoords.max_X .."/"..XYbonusCoords.min_Y..","..XYbonusCoords.max_Y);

	--event.JumpToActionSpotOpt = WL.RectangleVM.Create (XYbonusCoords.X, XYbonusCoords.Y, XYbonusCoords.X, XYbonusCoords.Y);
end