require("utilities");
require("Client_PresentMenuUI");

function Client_GameOrderCreated (game, gameOrder, skip)

    local strCardTypeBeingPlayed = nil;
	local cardOrderContentDetails = nil;
	local publicGameData = Mod.PublicGameData;

    print ("[C_GOC] START");
    --UI.Alert ("Checking orders");

	process_game_order_entry_CardBlock (game,gameOrder,result,skip,addOrder);
	process_game_order_entry_RegularCards (game,gameOrder,result,skip,addOrder);
	process_game_order_entry_CustomCards (game,gameOrder,result,skip,addOrder);
	process_game_order_entry_AttackTransfers (game,gameOrder,result,skip,addOrder);

    print ("[C_GOC] END");
end

--check if player is playing a card and is impacted by CardBlock; skip the order if so
function process_game_order_entry_CardBlock (game,gameOrder,result,skip,addOrder)
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

function process_game_order_entry_CustomCards (game,gameOrder,result,skip,addOrder)
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
		
		print ("[C_GOC] cardType=="..strCardTypeBeingPlayed.."::cardOrderContent=="..tostring(cardOrderContentDetails));
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
		elseif strCardTypeBeingPlayed == "Earthquake" then
			--execute_Earthquake_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
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

function process_game_order_entry_RegularCards (game,gameOrder,result,skip,addOrder)
    --if there's no QuicksandData, do nothing (b/c there's nothing to check)
    local boolQuicksandAirliftViolation = false;
    local strAirliftSkipOrder_Message="";

    --check for regular card plays
	if (gameOrder.proxyType == 'GameOrderPlayCardAirlift') then
		--check if Airlift is going in/out of Isolated territory or out of a Quicksanded territory; if so, cancel the move
		print ("[AIRLIFT PLAYED] FROM "..gameOrder.FromTerritoryID.."/"..getTerritoryName (gameOrder.FromTerritoryID, game)..", TO "..gameOrder.ToTerritoryID.."/"..getTerritoryName (gameOrder.ToTerritoryID, game)..", #armies=="..gameOrder.Armies.NumArmies.."::");

        if (Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] == nil)) then
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
		if (Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] == nil)) then
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

function process_game_order_entry_AttackTransfers (game,gameOrder,result,skip,addOrder)
	--check ATTACK/TRANSFER orders to see if any rules are broken and need intervention, eg: moving TO/FROM an Isolated territory or OUT of Quicksanded territory
	if (gameOrder.proxyType=='GameOrderAttackTransfer') then
		--print ("[[  ATTACK // TRANSFER ]] check for Isolation, player "..gameOrder.PlayerID..", TO "..gameOrder.To..", FROM "..gameOrder.From.."::");

    --check for Attack/Transfers into/out of quicksand that violate the rules configured in Mod.Settings.QuicksandBlockEntryIntoTerritory & Mod.Settings.QuicksandBlockExitFromTerritory
    --if there's no QuicksandData, do nothing (b/c there's nothing to check)
        if (Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.To] == nil and Mod.PublicGameData.QuicksandData[gameOrder.From] == nil)) then
            --do nothing, permit these orders
            --weed out the cases above, then what's left are moves to or from Isolated territories
        else
            local strQuicksandSkipOrder_Message="";
            local boolQuicksandAirliftViolation = false;
            --block moves IN/OUT of the quicksand as per the mod settings
            if (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil and Mod.Settings.QuicksandBlockExitFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since source and target territories have quicksand, and quicksand is configured so you can neither move in or out of quicksand";
				boolQuicksandAirliftViolation = true;
            elseif (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since target territory has quicksand, and quicksand is configured so you cannot move into quicksand";
				boolQuicksandAirliftViolation = true;
            elseif (Mod.Settings.QuicksandBlockAirliftsFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
                strQuicksandSkipOrder_Message="Order failed since source territory has quicksand, and quicksand is configured so you cannot move out of quicksand";
				boolQuicksandAirliftViolation = true;
            else
				--arriving here means there are no conditions where the airlift direction is being blocked, so let it proceed
				--strAirliftSkipOrder_Message="Airlift failed due to unknown quicksand conditions";
				boolQuicksandAirliftViolation = false; --this is the default but restating it here for clarity
            end
            
			--skip the order if a violation was flagged in the IF structure above
			if (boolQuicksandAirliftViolation==true) then
                strQuicksandSkipOrder_Message=strQuicksandSkipOrder_Message..".\n\nOriginal order was an Attack/Transfer from "..game.Map.Territories[gameOrder.From].Name.." to "..game.Map.Territories[gameOrder.To].Name..".";
                print ("QUICKSAND - skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.From .."/"..game.Map.Territories[gameOrder.From].Name.."::,to="..gameOrder.To .."/"..game.Map.Territories[gameOrder.To].Name.."::"..strQuicksandSkipOrder_Message.."::");
                UI.Alert (strQuicksandSkipOrder_Message);
                skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
            end
        end

		--if there's no IsolationData, do nothing (b/c there's nothing to check)
		if (Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.To] == nil and Mod.PublicGameData.IsolationData[gameOrder.From] == nil)) then
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

    CreateLabel (TopLabel).SetText (tostring ("Mod.Settings.CardBlockEnabled == false --> "..tostring(Mod.Settings.CardBlockEnabled == false)));
    --if CardBlock isn't in use, just return false
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