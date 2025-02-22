require("utilities");
require("DataConverter");

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E]::func start");

	Pestilence_processEndOfTurn (game, addOrder); --check for pending Pestilence orders, execute them if they start this turn or are already ongoing
	Tornado_processEndOfTurn (game, addOrder);
	Earthquake_processEndOfTurn (game, addOrder);
    Shield_processEndOfTurn(game, addOrder);
	Monolith_processEndOfTurn (game, addOrder);
	CardBlock_processEndOfTurn (game, addOrder);
    Quicksand_processEndOfTurn(game, addOrder);

	print ("[S_AT_E]::func END");

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	if (boolHaltCodeExecutionAtEndofTurn==true) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Order(game,gameOrder,result,skip,addOrder)
	--print ("[S_AdvanceTurn_Order - func start] ::ORDER.proxyType="..gameOrder.proxyType.."::");
	--skip order if this order is a card play by a player impacted by Card Block
	if (execute_CardBlock_skip_affected_player_card_plays (game, gameOrder, skip, addOrder) == true) then
		print ("[ORDER] skipped due to CardBlock");
		--skip order is actually done within the function above; the true/false return value is just a signal as to whether to proceed further execution in this function (if false) or not (if true)
		return; --don't process the rest of the function, else it will still process card plays
	end

	--[[local strCardTypeBeingPlayed = nil;
	local cardOrderContentDetails = nil;
	local publicGameData = Mod.PublicGameData;]]

	--process game orders, separated into Immovable Special Units (don't let Isolation/Quicksand/Shield/Monolith special units move), playing Regular Cards, playing Custom Cards, AttackTransfers; in future, may need an Other section afterward for anything else?
	process_game_orders_ImmovableSpecialUnits (game,gameOrder,result,skip,addOrder);
	process_game_orders_RegularCards (game,gameOrder,result,skip,addOrder);
	process_game_orders_CustomCards (game,gameOrder,result,skip,addOrder);
	process_game_orders_AttackTransfers (game,gameOrder,result,skip,addOrder);

--if (gameOrder.proxyType=='GameOrderAttackTransfer') then
--	print ("[[  ATTACK // TRANSFER ]] PREFACE  player "..gameOrder.PlayerID..", FROM "..gameOrder.From.."/"..getTerritoryName (gameOrder.From, game)..", TO "..gameOrder.To.."/"..getTerritoryName (gameOrder.To, game) ..
--[[	", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
	", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies.."::");
	print ("[SPECIALS:]");
	for k,v in pairs (result.DamageToSpecialUnits) do print ("damage to special "..k..", amount "..v.."::"); end

	--result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5));
	--result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5));
	result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5), result.AttackingArmiesKilled.SpecialUnits);
	result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5), result.DefendingArmiesKilled.SpecialUnits);

	print ("  ATTACK // TRANSFER  FINAL player "..gameOrder.PlayerID..", FROM "..gameOrder.From.."/"..getTerritoryName (gameOrder.From, game)..", TO "..gameOrder.To.."/"..getTerritoryName (gameOrder.To, game) ..
	", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
	", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies.."::");
	print ("[SPECIALS:]");
	for k,v in pairs (result.DamageToSpecialUnits) do print ("damage to special "..k..", amount "..v.."::"); end
end]]
end

function Server_AdvanceTurn_Start(game,addOrder)
	strArrayModData = {};
	local strCardTypeBeingPlayed = "";
	local publicGameData = Mod.PublicGameData;
	local privateGameData = Mod.PrivateGameData;
	turnNumber = game.Game.TurnNumber;

	print ("[Server_AdvanceTurn_Start] -----------------------------------------------------------------");
	print ("[Server_AdvanceTurn_Start] START; turn#=="..turnNumber.."::WZturn#=="..game.Game.TurnNumber);

	process_Neutralize_expirations (game, addOrder); --if there are pending Neutralize orders, check if any expire this turn and if so execute those actions
	process_Isolation_expirations (game, addOrder);  --if there are pending Isolation orders, check if any expire this turn and if so execute those actions (delete the special unit to identify the Isolated territory)

	--change this FROM: loop through all players then loop through all orders they have
	--              TO: just loop through all orders and check playerID against various conditions
	--   also: why ignore ID<=49, do AI orders not show up here?
	--[[for _,playerID in pairs(game.ServerGame.Game.PlayingPlayers) do
      	if(playerID.ID>50)then
			for _,order in pairs(game.ServerGame.ActiveTurnOrders[playerID.ID]) do
				--print ("[S_AT_S] ORDER="..order.proxyType.."::");

				if(order.proxyType=='GameOrderPlayCardCustom') then
					--print ("[S_AT_S] ORDER=GameOrderPlayCardCustom::");
					print ("[S_AT_S] ORDER=GameOrderPlayCardCustom::modData="..order.ModData.."::");
					local strArrayModData = split(order.ModData,'|');
					local strCardTypeBeingPlayed = strArrayModData[1];
					print ("[S_AT_S] CUSTOM CARD PLAY, type="..strCardTypeBeingPlayed..":: BUT IGNORE THIS - handle it in TurnAdvance_Order");
				end
			end
		end
	end]]
	print ("[Server_AdvanceTurn_Start] END; turn#=="..turnNumber.."::WZturn#=="..game.Game.TurnNumber);
end

--return true if this order is a card play by a player impacted by Card Block
function execute_CardBlock_skip_affected_player_card_plays (game, gameOrder, skip, addOrder)
	local publicGameData = Mod.PublicGameData;
	local targetPlayerID = gameOrder.PlayerID;

	--if CardBlock isn't in use, just return false
	if (Mod.Settings.CardBlockEnabled == false) then return false; end

	--if there is no CardBlock data, just return false
	local numCardBlockDataRecords = tablelength (publicGameData.CardBlockData);
	if (numCardBlockDataRecords == 0) then return false; end

	--check if order is a card play (could be regular or custom card play)
	if (string.find (gameOrder.proxyType, "GameOrderPlayCard") ~= nil) then
		--printObjectDetails (gameOrder, "[ORDER] card play", "[Server_TurnAdvance_Order]");
		print ("[ORDER::CARD PLAY] player=="..gameOrder.PlayerID..", proxyType=="..gameOrder.proxyType.."::_____________________");

		--check if player this order is for is impacted by Card Block
		if (publicGameData.CardBlockData[targetPlayerID] == nil) then
			--no CardBlock data exists, so don't check, just return with don't block result (return value of false)
			print ("[CARD BLOCK DATA dne]");
			return false;
		else
			--CardBlock data exists, this user is being CardBlocked! Check if the order is a card play, and if so (and it's not a Reinf card), skip the order
			print ("[CARD BLOCK DATA exists]");

			if (gameOrder.proxyType == "GameOrderPlayCardReinforcement") then
				--don't block Reinfs b/c the armies are already deployed, so blocking the card just gives the card back and the armies stay deployed
				--ie: do nothing, let it process normally
					print ("[CARD] Reinf card play - don't block");
					return false;
			else
				--skip order, as it is a card play (that isn't Reinf) by a player impacted by CardBlock
				printObjectDetails (publicGameData.CardBlockData, "CardBlockData", "in skip routine");

				--block all other card plays (skip the order)
				local strCardType = tostring (gameOrder.proxyType:match ("^GameOrderPlayCard(.*)"));
				local strCardName = strCardType; --this will be accurate for regular cards; for custom cards this will show as "custom", and need to get the card name from ModData (and hope all modders do this?)

				--display appropriate output message based on whether card is a regular card or a custom card
				if (strCardType=="Custom") then
					print ("[CARD PLAY BLOCKED] custom card=="..gameOrder.ModData.."::");
					local modDataContent = split(gameOrder.ModData, "|");
					cardOrderContentDetails = nil;
					strCardName = modDataContent[1]; --1st component of ModData up to "|" is the card name
				else
					--regular card, nothing special to do, just skip the card
					print ("[CARD PLAY BLOCKED] regular card==" .. strCardName);
				end
				
				--
				strCardBlockSkipOrder_Message = "Skipping order to play ".. strCardName.. " card as "..toPlayerName (gameOrder.PlayerID, game).." is impacted by Card Block.";
				print ("[CARD BLOCK] - skipOrder - playerID="..gameOrder.PlayerID.. ", "..strCardBlockSkipOrder_Message);
				addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strCardBlockSkipOrder_Message, {}, {},{}));
				skip (WL.ModOrderControl.Skip); --skip this order
				return true;
			end
		end
	end
	return false; --if it wasn't flagged by anything above, then it's either not a card play or the player this order is for isn't affected by a CardBlock operation
end

function process_game_orders_ImmovableSpecialUnits (game,gameOrder,result,skip,addOrder);
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
				print ("Immovable Special==true --> numArmies=="..numArmies.NumArmies);

				if (gameOrder.proxyType=='GameOrderAttackTransfer') then replacementOrder = WL.GameOrderAttackTransfer.Create(gameOrder.PlayerID, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, numArmies, gameOrder.AttackTeammates); end
				if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then replacementOrder = WL.GameOrderPlayCardAirlift.Create(gameOrder.CardInstanceID, gameOrder.PlayerID, gameOrder.FromTerritoryID, gameOrder.ToTerritoryID, numArmies); end
				addOrder (replacementOrder);
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
			end
		end
	end
end

function process_game_orders_RegularCards (game,gameOrder,result,skip,addOrder)
	--check for regular card plays
	if (gameOrder.proxyType == 'GameOrderPlayCardAirlift') then
		--check if Airlift is going in/out of Isolated territory or out of a Quicksanded territory; if so, cancel the move

		print ("[AIRLIFT PLAYED] FROM "..gameOrder.FromTerritoryID.."/"..getTerritoryName (gameOrder.FromTerritoryID, game)..", TO "..gameOrder.ToTerritoryID.."/"..getTerritoryName (gameOrder.ToTerritoryID, game)..", #armies=="..gameOrder.Armies.NumArmies.."::");

		--if there's no QuicksandData, do nothing (b/c there's nothing to check)
		local boolQuicksandAirliftViolation = false;
		local strAirliftSkipOrder_Message="";
		if (Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] == nil)) then
			--do nothing, there are no Quicksand operations in place, permit these orders
			--weed out the cases above, then what's left are Airlifts to or from Isolated territories
		else
			--block airlifts IN/OUT of the quicksand as per the mod settings
			if (Mod.Settings.QuicksandBlockAirliftsIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] ~= nil and Mod.Settings.QuicksandBlockAirliftsFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift failed since source and target territories have quicksand, and quicksand is configured so you can neither airlift in or out of quicksand";
				boolQuicksandAirliftViolation = true;
			elseif (Mod.Settings.QuicksandBlockAirliftsIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.ToTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift failed since target territory has quicksand, and quicksand is configured so you cannot airlift into quicksand";
				boolQuicksandAirliftViolation = true;
			elseif (Mod.Settings.QuicksandBlockAirliftsFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift failed since source territory has quicksand, and quicksand is configured so you cannot airlift out of quicksand";
				boolQuicksandAirliftViolation = true;
			else
				--arriving here means there are no conditions where the airlift direction is being blocked, so let it proceed
				boolQuicksandAirliftViolation = false; --this is the default but restating it here for clarity
			end
			
			--skip the order if a violation was flagged in the IF structure above
			if (boolQuicksandAirliftViolation==true) then
				strAirliftSkipOrder_Message=strAirliftSkipOrder_Message..". Original order was an Airlift from "..getTerritoryName (gameOrder.FromTerritoryID, game).." to "..getTerritoryName(gameOrder.ToTerritoryID, game);
				print ("[AIRLIFT/QUICKSAND] skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.FromTerritoryID .."/"..getTerritoryName (gameOrder.FromTerritoryID, game).."::, to="..gameOrder.ToTerritoryID .."/"..getTerritoryName(gameOrder.ToTerritoryID, game).."::"..strAirliftSkipOrder_Message.."::");
				addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strAirliftSkipOrder_Message, {}, {},{}));
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
			end
		end

		--if there's no IsolationData, do nothing (b/c there's nothing to check)
		if (Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] == nil)) then
			--do nothing, there are no Isolation operations in place, permit these orders
			--weed out the cases above, then what's left are Airlifts to or from Isolated territories
		else
			--block airlifts IN/OUT of the isolated territory as per the mod settings
			strAirliftSkipOrder_Message="";
			if (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift failed since source and target territories are isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] == nil) then
				strAirliftSkipOrder_Message="Airlift failed since target territory is isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.ToTerritoryID] == nil and Mod.PublicGameData.IsolationData[gameOrder.FromTerritoryID] ~= nil) then
				strAirliftSkipOrder_Message="Airlift failed since source territory is isolated";
			else
				strAirliftSkipOrder_Message="Airlift failed due to unknown isolation conditions";
			end
			strAirliftSkipOrder_Message=strAirliftSkipOrder_Message..". Original order was an Airlift from "..getTerritoryName (gameOrder.FromTerritoryID, game).." to "..getTerritoryName(gameOrder.ToTerritoryID, game);
			print ("[AIRLIFT/ISOLATION] skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.FromTerritoryID .."/"..getTerritoryName (gameOrder.FromTerritoryID, game).."::, to="..gameOrder.ToTerritoryID .."/"..getTerritoryName(gameOrder.ToTerritoryID, game).."::"..strAirliftSkipOrder_Message.."::");
			addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strAirliftSkipOrder_Message, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
		end
	end
end

function process_game_orders_CustomCards (game,gameOrder,result,skip,addOrder)
	--check for Custom Card plays
	--NOTE: proxyType=='GameOrderPlayCardCustom' indicates that a custom card played; but these can't be placed in the order list at a specific point, it just applies in the position according to regular move order
	--so for now, ignore this; re-implement this when Fizz updates so these can placed at the proper execution point, eg: start of turn, after deployments, after attacks, etc
	if (gameOrder.proxyType=='GameOrderPlayCardCustom') then
		local modDataContent = split(gameOrder.ModData, "|");
		--printObjectDetails (gameOrder, "gameOrder", "[TurnAdvance_Order]");
		print ("[GameOrderPlayCardCustom] modData=="..gameOrder.ModData.."::");
		strCardTypeBeingPlayed = nil;  --global variable referenced in other functions in this Server Hook
		cardOrderContentDetails = nil; --global variable referenced in other functions in this Server Hook
		strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name
		cardOrderContentDetails = modDataContent[2]; --2nd component of ModData after "|" is the territory ID or player ID depending on the card type
		
		print ("[S_AT_O] cardType=="..strCardTypeBeingPlayed.."::cardOrderContent=="..tostring(cardOrderContentDetails));
		if (strCardTypeBeingPlayed == "Nuke") then
			execute_Nuke_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Isolation" then
			execute_Isolation_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Pestilence" then
			execute_Pestilence_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Shield") then
			execute_Shield_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Monolith" then
			execute_Monolith_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails))
		elseif strCardTypeBeingPlayed == "Neutralize" then
			execute_Neutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Deneutralize" then
			execute_Deneutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Airstrike" then
			--Airstrike details go here
		elseif strCardTypeBeingPlayed == "Card Piece" then
			execute_CardPiece_operation(game, gameOrder, skip, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Forest Fire" then
			--Forest Fire details go here
		elseif strCardTypeBeingPlayed == "Card Block" then
			execute_CardBlock_play_a_CardBlock_Card_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Earthquake" then
			execute_Earthquake_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Tornado" then
			execute_Tornado_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif strCardTypeBeingPlayed == "Quicksand" then
			execute_Quicksand_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		else
			--custom card play not handled by this mod; could be an error, or a card from another mod
			--do nothing
		end
	end
end

function process_game_orders_AttackTransfers (game,gameOrder,result,skip,addOrder)
	--check ATTACK/TRANSFER orders to see if any rules are broken and need intervention, eg: moving TO/FROM an Isolated territory or OUT of Quicksanded territory
	if (gameOrder.proxyType=='GameOrderAttackTransfer') then
		print ("[[  ATTACK // TRANSFER ]] PRE  player "..gameOrder.PlayerID..", FROM "..gameOrder.From.."/"..getTerritoryName (gameOrder.From, game)..", TO "..gameOrder.To.."/"..getTerritoryName (gameOrder.To, game) ..
			", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
			
		--print ("...Mod.PublicGameData.IsolationData == nil -->".. tostring (Mod.PublicGameData.IsolationData == nil));
		--if Mod.PublicGameData.IsolationData ~= nil then print (".....Mod.PublicGameData.IsolationData[gameOrder.To] == nil -->".. tostring (Mod.PublicGameData.IsolationData[gameOrder.To] == nil)); end;
		--if Mod.PublicGameData.IsolationData ~= nil then print (".....Mod.PublicGameData.IsolationData[gameOrder.From] == nil -->".. tostring (Mod.PublicGameData.IsolationData[gameOrder.From] == nil)); end;

		--result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5));
		--result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5));
		--print ("[QUICKSAND] TEMP POST attack/transfer into Quicksand! AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..", IsSuccessful=="..tostring(result.IsSuccessful).."::");
		--return;

		--if there's no QuicksandData, do nothing (b/c there's nothing to check)
		if (Mod.PublicGameData.QuicksandData == nil or (Mod.PublicGameData.QuicksandData[gameOrder.To] == nil and Mod.PublicGameData.QuicksandData[gameOrder.From] == nil)) then
			--do nothing, permit these orders
			--weed out the cases above, then what's left are moves to or from Isolated territories
		else
			local strQuicksandSkipOrder_Message="";
			local boolQuicksandMovementViolation = false;
			--block moves IN/OUT of the quicksand as per the mod settings
			if (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil and Mod.Settings.QuicksandBlockExitFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
				strQuicksandSkipOrder_Message="Order failed since source and target territories have quicksand, and quicksand is configured so you can neither move in or out of quicksand";
				boolQuicksandMovementViolation = true;
			elseif (Mod.Settings.QuicksandBlockEntryIntoTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil) then
				strQuicksandSkipOrder_Message="Order failed since target territory has quicksand, and quicksand is configured so you cannot move into quicksand";
				boolQuicksandMovementViolation = true;
			elseif (Mod.Settings.QuicksandBlockExitFromTerritory==true and Mod.PublicGameData.QuicksandData[gameOrder.From] ~= nil) then
				strQuicksandSkipOrder_Message="Order failed since source territory has quicksand, and quicksand is configured so you cannot move out of quicksand";
				boolQuicksandMovementViolation = true;
			else
				--arriving here means there are no conditions where the attack/transfer direction is being blocked, so let it proceed
				boolQuicksandMovementViolation = false; --this is the default but restating it here for clarity
			end
			if (boolQuicksandMovementViolation==true) then
				strQuicksandSkipOrder_Message=strQuicksandSkipOrder_Message..". Original order was an Attack/Transfer from "..game.Map.Territories[gameOrder.From].Name.." to "..game.Map.Territories[gameOrder.To].Name;
				print ("QUICKSAND - skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.From .."/"..game.Map.Territories[gameOrder.From].Name.."::,to="..gameOrder.To .."/"..game.Map.Territories[gameOrder.To].Name.."::"..strQuicksandSkipOrder_Message.."::");
				addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strQuicksandSkipOrder_Message, {}, {},{}));
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
			else
				--order is not a quicksand violation; it may not have anything to do with quicksand; check if order is a legit attack on a quicksanded territory
				--if legit attack into quicksand then apply damage factors to attacking & defending armies killed
				if (Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil) then
					print ("[QUICKSAND] ATTACK INTO QUICKSAND _ _ _ _ _ _ _ _ _ _ _ _ ");
					print ("[QUICKSAND] PRE  attack/transfer into Quicksand! AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..", IsSuccessful=="..tostring(result.IsSuccessful).."::");
					print ("[QUICKSAND] AttackerDamageTakenModifier=="..Mod.Settings.QuicksandAttackerDamageTakenModifier..", AttackerDamageTakenModifier=="..Mod.Settings.QuicksandDefenderDamageTakenModifier.."::");
					print ("[QUICKSAND] AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
					print ("[QUICKSAND] result.DamageToSpecialUnits==nil --> ".. tostring (result.DamageToSpecialUnits==nil)..", size=="..tostring(#result.DamageToSpecialUnits)..", type==".. type(result.DamageToSpecialUnits).."::");
					if (result.DamageToSpecialUnits==nil) then print ("[QUICKSAND] PRE nil: 0 damage to specials"); end
					if (result.DamageToSpecialUnits=={}) then print ("[QUICKSAND] PRE  {}: 0 damage to specials"); end
					if (#result.DamageToSpecialUnits==0) then print ("[QUICKSAND] PRE  #==0 : 0 damage to specials"); end
					print ("[QUICKSAND] PRE killed defending specials; size== "..#result.DefendingArmiesKilled.SpecialUnits.."::");
					for k,v in pairs (result.DefendingArmiesKilled.SpecialUnits) do print ("[QUICKSAND] PRE killed defending specials "..k..","..v.Name.."/"..v.ID.."::"); end
					print ("[QUICKSAND] PRE damage to special");
					for k,v in pairs (result.DamageToSpecialUnits) do print ("[QUICKSAND] PRE damage to special "..k..", amount "..v.."::"); end
					print ("[QUICKSAND] PRE __fin__");

					local newAttackingArmiesKilled = math.floor(result.AttackingArmiesKilled.NumArmies*Mod.Settings.QuicksandAttackerDamageTakenModifier+0.5);
					local newDefendingArmiesKilled = math.floor(result.DefendingArmiesKilled.NumArmies*Mod.Settings.QuicksandDefenderDamageTakenModifier+0.5);
					--calc damage above and beyond what's required to kill armies on the target territory, and apply that to specials on the territory
					--minimally, destroy the Quicksand special if all armies reach 0 so that won't be what stops the territory from being captured (but another special might)
					local intAdditionalDamageToSpecials = newDefendingArmiesKilled - game.ServerGame.LatestTurnStanding.Territories[gameOrder.To].NumArmies.NumArmies;
					local newAttackingSpecialsKilled = result.AttackingArmiesKilled.SpecialUnits; --no adjustment here yet; it's a bit complicated, perhaps come back to this later; for now leave the Specials alone exept for the Quicksand Special
					local newDefendingSpecialsKilled = result.DefendingArmiesKilled.SpecialUnits;

					print ("[QUICKSAND] MID AdditionalDamageToSpecials "..intAdditionalDamageToSpecials .."::");
					if (intAdditionalDamageToSpecials>=0) then -- >0 indicates that more damage was done than there are armies on the territory, so destroy the Quicksand special; perhaps other Specials will hold the territory, but ensure that the Quicksand Special doesn't stop it from being captured
						for k,v in pairs (game.ServerGame.LatestTurnStanding.Territories[gameOrder.To].NumArmies.SpecialUnits) do
							print ("....special ",k,v.Name,v.ID);
							--table.insert (result.DamageToSpecialUnits, {k, intAdditionalDamageToSpecials});
							--table.insert (result.DefendingArmiesKilled.SpecialUnits, v.ID);
							print ("....#size=="..#result.DamageToSpecialUnits.."::");
							if (v.Name == "Quicksand") then print ("----removed Quicksand special"); table.insert (newDefendingSpecialsKilled, v); end
						end
					end
					--&&& change me back to the 1st two lines! this is for THE TESTING GAME ONLY b/c the original values are 0's!

					result.AttackingArmiesKilled = WL.Armies.Create(newAttackingArmiesKilled, newAttackingSpecialsKilled); --decrease # of attackers killed but leave Specials as-is (that gets trickier; and the game is kind of built around just impacting armies and ignoring specials for additional damage items like this)
					result.DefendingArmiesKilled = WL.Armies.Create(newDefendingArmiesKilled, newDefendingSpecialsKilled); --increase # of defenders killed but leave Specials as-is (that gets trickier; and the game is kind of built around just impacting armies and ignoring specials for additional damage items like this)

					--[[
					--check if the Quicksand visual helper special unit was destroyed (killed)
					for k,v in pairs (result.DefendingArmiesKilled.SpecialUnits) do
						print ("[QUICKSAND] special "..k..", "..v.Name..", "..v.ID..", matches QuickSU=="..tostring(v.ID == Mod.PublicGameData.QuicksandData[gameOrder.To].specialUnitID));
						if (v.ID == Mod.PublicGameData.QuicksandData[gameOrder.To].specialUnitID) then
							print ("[QUICKSAND] matches - recreate the special");
						end
						--for reference: publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};
					end]]

					print ("[QUICKSAND] POST attack/transfer into Quicksand! AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..", IsSuccessful=="..tostring(result.IsSuccessful)..", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
				end
				--for reference, default settings are:
				--Mod.Settings.QuicksandDefenderDamageTakenModifier = 1.5; --increase damage taken by defender 50% while in quicksand
				--Mod.Settings.QuicksandAttackerDamageTakenModifier = 0.5; --reduce damage given by defender 50% while in quicksand
				--*** rename these to QuicksandDefenderDamageTakenModifier & QuicksandAttackerDamageGivenModifier so it's clear how it applies to the 'result' of an order
				
			end
		end
		
		--if there's no IsolationData, do nothing (b/c there's nothing to check)
		if (Mod.PublicGameData.IsolationData == nil or (Mod.PublicGameData.IsolationData[gameOrder.To] == nil and Mod.PublicGameData.IsolationData[gameOrder.From] == nil)) then
			--do nothing, permit these orders
			--weed out the cases above, then what's left are moves to or from Isolated territories
		else
			local strIsolationSkipOrder_Message="";

			if (Mod.PublicGameData.IsolationData[gameOrder.To] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.From] ~= nil) then
				strIsolationSkipOrder_Message="Order failed since source and target territories are isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.To] ~= nil and Mod.PublicGameData.IsolationData[gameOrder.From] == nil) then
				strIsolationSkipOrder_Message="Order failed since target territory is isolated";
			elseif (Mod.PublicGameData.IsolationData[gameOrder.To] == nil and Mod.PublicGameData.IsolationData[gameOrder.From] ~= nil) then
				strIsolationSkipOrder_Message="Order failed since source territory is isolated";
			end
			strIsolationSkipOrder_Message=strIsolationSkipOrder_Message..". Original order was an Attack/Transfer from "..game.Map.Territories[gameOrder.From].Name.." to "..game.Map.Territories[gameOrder.To].Name;
			print ("ISOLATION - skipOrder - playerID="..gameOrder.PlayerID.. "::from="..gameOrder.From .."/"..game.Map.Territories[gameOrder.From].Name.."::,to="..gameOrder.To .."/"..game.Map.Territories[gameOrder.To].Name.."::"..strIsolationSkipOrder_Message.."::");
			addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strIsolationSkipOrder_Message, {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
		end
		print ("[[  ATTACK // TRANSFER ]] POST  player "..gameOrder.PlayerID..", FROM "..gameOrder.From.."/"..getTerritoryName (gameOrder.From, game)..", TO "..gameOrder.To.."/"..getTerritoryName (gameOrder.To, game) ..
			", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
			for k,v in pairs (result.DamageToSpecialUnits) do print ("[QUICKSAND] POST damage to special "..k..", amount "..v.."::"); end
			print ("[QUICKSAND] result.DamageToSpecialUnits==nil --> ".. tostring (result.DamageToSpecialUnits==nil)..", size=="..tostring(#result.DamageToSpecialUnits)..", type==".. type(result.DamageToSpecialUnits).."::");
			if (result.DamageToSpecialUnits==nil) then print ("[QUICKSAND] POST nil: 0 damage to specials"); end
			if (result.DamageToSpecialUnits=={}) then print ("[QUICKSAND] POST  {}: 0 damage to specials"); end
			if (#result.DamageToSpecialUnits==0) then print ("[QUICKSAND] POST  #==0 : 0 damage to specials"); end
			print ("[QUICKSAND] POST damage to special "); 
			for k,v in pairs (result.DamageToSpecialUnits) do print ("[QUICKSAND] POST damage to special "..k..", amount "..v.."::"); end
			print ("[QUICKSAND] POST __fin__");

		--[[
			--check if Quicksand visual Special Unit was destroyed (killed); if the TO territory in the attack has a QuicksandData record & isAttack & isSuccessful are both true, then recreate the special unit, and replace the Quicksand record for this territoryID
		if (Mod.PublicGameData.QuicksandData[gameOrder.To] ~= nil and result.IsAttack==true and result.IsSuccessful==true) then
			print ("[QUICKSAND] special unit killed / recreate it - - - - TRIPPING TIME - - - - - - - - - - ");
			--create new Quicksand special unit & apply to the territory
			local impactedTerritory = WL.TerritoryModification.Create(gameOrder.To);
			local specialUnit_Quicksand = build_Quicksand_specialUnit (game, gameOrder.To);
			impactedTerritory.AddSpecialUnits = {specialUnit_Quicksand};
			local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, gameOrder.Description, {}, {impactedTerritory});
			addOrder(event, false); --important to use 'false' here b/c the Quicksand attack itself
			--update QuicksandData record to reflect the new special unit ID#
			local publicGameData = Mod.PublicGameData;
			local oldQuicksandDataRecord = publicGameData.QuicksandData [gameOrder.To];
			local newQuicksandDataRecord = {territory = oldQuicksandDataRecord.territory, castingplayer = oldQuicksandDataRecord.castingPlayer, territoryOwner = oldQuicksandDataRecord.territoryOwner, turnNumberQuicksandEnds = oldQuicksandDataRecord.turnNumberQuicksand, specialUnitID = specialUnit_Quicksand.ID}; --recreate QuicksandData record with ID# of the new special unit
			publicGameData.QuicksandData[gameOrder.To] = newQuicksandDataRecord;
			--for reference: publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};
			Mod.PublicGameData = publicGameData; --resave public game data
			print ("[QUICKSAND] special unit killed / OLD    = "..oldQuicksandDataRecord.specialUnitID);
			print ("[QUICKSAND] special unit killed / NEW    = "..newQuicksandDataRecord.specialUnitID);
			print ("[QUICKSAND] special unit killed / NEWpub = "..Mod.PublicGameData.QuicksandData[gameOrder.To].specialUnitID);
		end]]

	end
end

--process order to redeem Card Piece card for cards/pieces of card specified in targetCardID
function execute_CardPiece_operation(game, gameOrder, skip, addOrder, targetCardID)
	local strTargetCardName = getCardName_fromID (targetCardID, game);
	local targetCardConfigNumPieces = game.Settings.Cards[targetCardID].NumPieces;
	local targetCardNumPiecesToGrant = Mod.Settings.CardPiecesNumCardPiecesToGrant;       --# of card pieces to grant as configured in Mod.Settings by game host
	local targetCardNumWholeCardsToGrant = Mod.Settings.CardPiecesNumWholeCardsToGrant;   --# of whole cards to grant as configured in Mod.Settings by game host
	local numTotalCardPiecesToGrant = targetCardNumWholeCardsToGrant * targetCardConfigNumPieces + targetCardNumPiecesToGrant; --can't add Whole Cards directly, instead must add the appropriate # of pieces to comprise a whole card + the # of card pieces as specified by game host

	--disallow using Card Pieces card to get more Card Pieces cards/pieces
	if (Mod.PublicGameData.CardData.CardPiecesCardID == targetCardID) then
		print ("[CARD PIECE] SKIP ORDER, tried to use Card Piece to get Card Piece cards/pieces");
		addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, "Skipped order to play Card Pieces card to get more cards/pieces of Card Pieces card", {}, {},{}));
		skip (WL.ModOrderControl.Skip); --skip this order
	else
		--assign new cards/pieces of the selected card type

		local strCardPieceMsg = "Redeem Card Pieces card for " .. strTargetCardName .." resources: " ..targetCardNumWholeCardsToGrant .. " whole card"..plural (targetCardNumWholeCardsToGrant)..", "..targetCardNumPiecesToGrant.." card piece"..plural(targetCardNumPiecesToGrant);
		print ("[CARD PIECE] played; redeem for cards/pieces of card type "..targetCardID.."/"..strTargetCardName..":: ".. strCardPieceMsg);
		local event = WL.GameOrderEvent.Create (gameOrder.PlayerID, strCardPieceMsg, {});
		event.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[targetCardID] = numTotalCardPiecesToGrant}};
		addOrder(event, true);
	end
end

function execute_CardBlock_play_a_CardBlock_Card_operation (game, gameOrder, addOrder, targetPlayerID)
    print("[PROCESS CARD BLOCK] playerID="..gameOrder.PlayerID.." :: playerID="..targetPlayerID);
	--get player
	local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, gameOrder.Description, {});
    addOrder(event, true);
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.CardBlockData == nil) then publicGameData.CardBlockData = {}; end
    local turnNumber_CardBlockExpires = (Mod.Settings.CardBlockDuration > 0) and (game.Game.TurnNumber + Mod.Settings.CardBlockDuration) or -1;
	local record = {targetPlayer = targetPlayerID, castingPlayer = gameOrder.PlayerID, turnNumberBlockEnds = turnNumber_CardBlockExpires}; --create record to save data on impacted player, casting player & end turn of Card Block impact
    publicGameData.CardBlockData[targetPlayerID] = record;
    Mod.PublicGameData = publicGameData;
	printObjectDetails (Mod.PublicGameData, "Mod.PublicGameData", "full");
	printObjectDetails (Mod.PublicGameData.CardBlockData[targetPlayerID], "Mod.PublicGameData.CardBlockData[targetPlayerID]", "player record");
	print ("Mod.PublicGameData.CardBlockData[targetPlayerID]==nil-->"..tostring (Mod.PublicGameData.CardBlockData[targetPlayerID]==nil));
end

function execute_Earthquake_operation(game, gameOrder, addOrder, targetBonusID)
	--add record to EarthquakeData to process the earthquake operation @ turn end	
	print("[PROCESS EARTHQUAKE] invoked on bonus " .. targetBonusID.."/".. getBonusName(targetBonusID, game));
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.EarthquakeData == nil) then publicGameData.EarthquakeData = {}; end --if no EarthquakeData, then initialize it
    local turnNumber_EarthquakeExpires = (Mod.Settings.EarthquakeDuration > 0) and (game.Game.TurnNumber + Mod.Settings.EarthquakeDuration) or -1;
    publicGameData.EarthquakeData[targetBonusID] = {targetBonus = targetBonusID, castingPlayer = gameOrder.PlayerID, turnNumberEarthquakeEnds = turnNumber_EarthquakeExpires};
    Mod.PublicGameData = publicGameData;
end

function execute_Tornado_operation(game, gameOrder, addOrder, targetTerritoryID)
    print("[PROCESS TORNADO] on territory " .. targetTerritoryID);
    local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);

	--add an Idle "power up" structure to the territory to signify a Tornado; add 1 to the Idle "power" structure on the target territory
	--local structures = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures;
	local structures = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures;

	print ("[TORNADO] structure Idle power=="..WL.StructureType.Power.."::");
	--print ("[TORNADO] PRE - structures[WL.StructureType.Power]=="..tostring (structures[WL.StructureType.Power]).."::");
	--print ("[TORNADO] PRE - game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures[WL.StructureType.Power]=="..tostring (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures[WL.StructureType.Power]).."::");
	if (structures == nil) then structures = {}; end;
	print ("[TORNADO] PRE - structures[WL.StructureType.Power]=="..tostring (structures[WL.StructureType.Power]).."::");
	if (structures[WL.StructureType.Power] == nil) then
		structures[WL.StructureType.Power] = 1;
	else
		structures[WL.StructureType.Power] = structures[WL.StructureType.Power] + 1;
	end

	impactedTerritory.SetStructuresOpt = structures;
    impactedTerritory.AddArmies = -1 * Mod.Settings.TornadoStrength;
    local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, gameOrder.Description, {}, {impactedTerritory});
    event.JumpToActionSpotOpt = WL.RectangleVM.Create(
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY,
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY);
    addOrder(event, true);
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.TornadoData == nil) then publicGameData.TornadoData = {}; end
    local turnNumber_TornadoExpires = (Mod.Settings.TornadoDuration > 0) and (game.Game.TurnNumber + Mod.Settings.TornadoDuration) or -1;
    publicGameData.TornadoData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, turnNumberTornadoEnds = turnNumber_TornadoExpires};
    Mod.PublicGameData = publicGameData;
	print ("[TORNADO] POST - structures[WL.StructureType.Power]=="..tostring (structures[WL.StructureType.Power]).."::");
	--print ("[TORNADO] POST - structures[WL.StructureType.Power]=="..tostring (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].Structures[WL.StructureType.Power]).."::");
end

--create a new special unit for Quicksand visiblity; used for both initial creation and for recreation if it gets killed by incoming attack
function build_Quicksand_specialUnit (game, targetTerritoryID)
    local builder = WL.CustomSpecialUnitBuilder.Create(game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID);
    builder.Name = 'Quicksand';
    builder.IncludeABeforeName = false;
    builder.ImageFilename = 'quicksand_v3_specialunit.png';
    builder.AttackPower = 0;
    --builder.AttackPowerPercentage = 0.5;  --0.0 means -100% attack damage (the damage this unit does when attacking); 1.0=regular attack damage; >1.0 means bonus attack damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
    builder.DefensePower = 0;
	--builder.DefensePowerPercentage = 0.5; --0.0 means -100% defense damage (the damage this unit does when attacking); 1.0=regular defense damage; >1.0 means bonus defense damage --> don't do this here, it is handled when processing the actual AttackTransfer orders in process_game_orders_AttackTransfers
    builder.DamageToKill = 0;
    builder.DamageAbsorbedWhenAttacked = 0;
    --builder.Health = 0;
    builder.CombatOrder = 10001;
    builder.CanBeGiftedWithGiftCard = false;
    builder.CanBeTransferredToTeammate = false;
    builder.CanBeAirliftedToSelf = false;
    builder.CanBeAirliftedToTeammate = false;
    builder.IsVisibleToAllPlayers = false;
	builder.ModData = "CCPA|Immovable|Quicksand";
	local specialUnit_Quicksand = builder.Build();
	return specialUnit_Quicksand;
end

function execute_Quicksand_operation(game, gameOrder, addOrder, targetTerritoryID)
    print("[PROCESS QUICKSAND] on territory " .. targetTerritoryID);
    local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);
	local impactedTerritoryOwnerID = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
	--print ("[QUICKSAND]     _ _ _ _ _ _ _ _ _ _ ");
    local specialUnit_Quicksand = build_Quicksand_specialUnit (game, targetTerritoryID);
	
    impactedTerritory.AddSpecialUnits = {specialUnit_Quicksand};
    local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, gameOrder.Description, {}, {impactedTerritory});
    event.JumpToActionSpotOpt = WL.RectangleVM.Create(
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY,
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY);
    addOrder(event, true);
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.QuicksandData == nil) then publicGameData.QuicksandData = {}; end
    local turnNumber_QuicksandExpires = (Mod.Settings.QuicksandDuration > 0) and (game.Game.TurnNumber + Mod.Settings.QuicksandDuration) or -1;
    publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};
    Mod.PublicGameData = publicGameData;
end

function execute_Shield_operation(game, gameOrder, addOrder, targetTerritoryID)
	print("[PROCESS SHIELD START] playerID="..gameOrder.PlayerID.."::terr="..targetTerritoryID.."::description="..gameOrder.Description.."::");

    local impactedTerritoryOwnerID = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
    local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);

    local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);
    builder.Name = 'Shield';
    builder.IncludeABeforeName = false;
    builder.ImageFilename = 'shield_special unit_clearback.png';
    builder.AttackPower = 0;
    builder.DefensePower = 0;
	builder.DefensePowerPercentage = 0;
    builder.DamageToKill = 9999999;
    builder.DamageAbsorbedWhenAttacked = 9999999;
    builder.CombatOrder = -10000; --before armies (which are 0)
    builder.CanBeGiftedWithGiftCard = false;
	builder.CanBeGiftedWithGiftCard = true;
    builder.CanBeTransferredToTeammate = false;
    builder.CanBeAirliftedToSelf = false;
    builder.CanBeAirliftedToTeammate = false;
    builder.IsVisibleToAllPlayers = false;

	print ("Mod.Settings.ShieldDescription=="..tostring (Mod.Settings.ShieldDescription));
	local strShieldDesc = tostring (Mod.Settings.ShieldDescription);
	local recordUnitDesc = {UnitDescription = strShieldDesc};
	local recordEssentials = {Essentials = recordUnitDesc};
	--builder.ModData = strShieldDesc;
	--builder.ModData = DataConverter.DataToString(recordEssentials); --use Dutch's library code to store unit description in a special "Essentials" table construct which is then stored in ModData
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = "The medic does not like standing on the front lines, but rather wants to stay back to heal up any wounded soldiers. Any time the player owning this unit loses armies on a territory connected to this medic, it will recover " .. Mod.Settings.Percentage .. "% of the armies lost\n\nThis unit can be bought for " .. Mod.Settings.Cost .. " gold in the purchase menu (same place where you buy cities)\n\nEach player can have up to " .. Mod.Settings.MaxUnits .. " Medic(s), so you can't have an army of Medics unfortunately"}});

    local specialUnit_Shield = builder.Build();
    impactedTerritory.AddSpecialUnits = {specialUnit_Shield};

    local castingPlayerID = gameOrder.PlayerID;
    local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory});
    event.JumpToActionSpotOpt = WL.RectangleVM.Create(
        game.Map.Territories[targetTerritoryID].MiddlePointX,
        game.Map.Territories[targetTerritoryID].MiddlePointY,
        game.Map.Territories[targetTerritoryID].MiddlePointX,
        game.Map.Territories[targetTerritoryID].MiddlePointY
    );
    addOrder(event, true);

    local privateGameData = Mod.PrivateGameData;
    local turnNumber_ShieldExpires = -1;
    if (Mod.Settings.ShieldDuration > 0) then
        turnNumber_ShieldExpires = game.Game.TurnNumber + Mod.Settings.ShieldDuration;
    end
    local ShieldDataRecord = {
        territory = targetTerritoryID,
        castingPlayer = castingPlayerID,
        territoryOwner = impactedTerritoryOwnerID,
        turnNumberShieldEnds = turnNumber_ShieldExpires,
        specialUnitID = specialUnit_Shield.ID
    };
    table.insert(privateGameData.ShieldData, ShieldDataRecord);
    Mod.PrivateGameData = privateGameData;
end

function execute_Monolith_operation (game, gameOrder, addOrder, targetTerritoryID)
		print ("[PROCESS MONOLITH START] playerID="..gameOrder.PlayerID.."::terr="..targetTerritoryID.."::".."description="..gameOrder.Description.."::");
	
		-- create territory object, assign special unit to it, add an order associated with the territory
		local impactedTerritoryOwnerID = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
		local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
	
		-- create special unit for Isolation operations, place the special on the territory so it is visibly identifiable as being impacted by Isolation; destroy the unit when Isolation ends
		local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);  --assign unit to owner of the territory (not the caster of the Neutralize action)
		builder.Name = 'Monolith';
		builder.IncludeABeforeName = false;
		builder.ImageFilename = 'monolith special unit_clearback.png'; --max size of 60x100 pixels
		builder.AttackPower = 0;
		builder.DefensePower = 0;
		builder.DamageToKill = 9999999;
		builder.DamageAbsorbedWhenAttacked = 9999999;
		--builder.Health = 99999999999999;
		builder.CombatOrder = 10011; --doesn't protect Commander
		builder.CanBeGiftedWithGiftCard = false;
		builder.CanBeGiftedWithGiftCard = true;
		builder.CanBeTransferredToTeammate = false;
		builder.CanBeAirliftedToSelf = false;
		builder.CanBeAirliftedToTeammate = false;
		builder.IsVisibleToAllPlayers = false;
		--builder.TextOverHeadOpt = "Monolith"; --don't need writing; the graphic is sufficient
		--builder.ModDate - ""; store some info in here? Not sure it's wise; unit could be killed, etc -- best to just store it in a table in privategatedata
		local specialUnit_Monolith = builder.Build(); --save this in a table somewhere to destroy later
	
		--modify impactedTerritory object to change to neutral + add the special unit for visibility purposes			
		impactedTerritory.AddSpecialUnits = {specialUnit_Monolith}; --add special unit
		--table.insert (modifiedTerritories, impactedTerritory);
		--printObjectDetails (specialUnit_Monolith, "Monolith specialUnit", "Monolith"); --show contents of the Monolith special unit
		
		local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Monolith action
		--need WL.GameOrderEvent.Create to modify territories (add special units) + jump to location + card/piece changes, and need WL.GameOrderCustom.Create for occursInPhase modifier (is this it?)
		local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
		event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
		addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function; this actually adds the game order that changes territory to neutral & adds the special unit
	
		--save data in Mod.PublicGameData so the special unit can be destroyed later
		local privateGameData = Mod.PrivateGameData;
		local turnNumber_MonolithExpires = -1;
		printObjectDetails (privateGameData.MonolithData, "[PRE  Monolith data]", "Execute Monolith operation");
		
		if (Mod.Settings.MonolithDuration==0) then  --if Monolith duration is Permanent (don't auto-revert), set expiration turn to -1
			turnNumber_MonolithExpires = -1; 
		else --otherwise, set expire turn as current turn # + card Duration
			turnNumber_MonolithExpires = game.Game.TurnNumber + Mod.Settings.MonolithDuration; 
		end
		print ("expire turn#="..turnNumber_MonolithExpires.."::duration=="..Mod.Settings.MonolithDuration.."::gameTurn#="..game.Game.TurnNumber.."::calcExpireTurn=="..game.Game.TurnNumber + Mod.Settings.MonolithDuration.."::");
		--even if Monolith duration==0, still make a note of the details of the Monolith action - probably not required though
		local MonolithDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberMonolithEnds=turnNumber_MonolithExpires, specialUnitID=specialUnit_Monolith.ID};---&&&
		table.insert (privateGameData.MonolithData, MonolithDataRecord);
		Mod.PrivateGameData = privateGameData;
		--printObjectDetails (MonolithDataRecord, "[POST Monolith data record]");
		--printObjectDetails (Mod.PrivateGameData.MonolithData, "[POST actual Mod.PrivateGame.MonolithData]");
		print ("POST Monolith#items="..tablelength(Mod.PrivateGameData.MonolithData));
		print ("[PROCESS Monolith END] playerID="..gameOrder.PlayerID.."::terr="..targetTerritoryID.."::".."description="..gameOrder.Description.."::");
end

function execute_Isolation_operation (game, gameOrder, addOrder, targetTerritoryID)
	print ("[PROCESS ISOLATION START] playerID="..gameOrder.PlayerID.."::terr="..targetTerritoryID.."::".."description="..gameOrder.Description.."::");

	-- create territory object, assign special unit to it, add an order associated with the territory
	--local targetTerritoryID = tonumber(strArrayModData[2]); --don't need this b/c we get it as a function parameter
	local impactedTerritoryOwnerID = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
	local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder

	-- create special unit for Isolation operations, place the special on the territory so it is visibly identifiable as being impacted by Isolation; destroy the unit when Isolation ends
	local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);  --assign unit to owner of the territory (not the caster of the Neutralize action)
	builder.Name = 'Isolated territory';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'isolatedTerritory.png'; --max size of 60x100 pixels
	builder.AttackPower = 0;
	builder.DefensePower = 0;
	builder.DamageToKill = 0;
	builder.DamageAbsorbedWhenAttacked = 0;
	builder.Health = 0;
	builder.CombatOrder = 10001; --doesn't protect Commander
	builder.CanBeGiftedWithGiftCard = false;
	builder.CanBeTransferredToTeammate = false;
	builder.CanBeAirliftedToSelf = false;
	builder.CanBeAirliftedToTeammate = false;
	builder.IsVisibleToAllPlayers = false;
	builder.TextOverHeadOpt = "Isolated";
	--builder.ModDate - ""; store some info in here? Not sure it's wise; unit could be killed, etc -- best to just store it in a table in privategatedata
	local specialUnit_Isolation = builder.Build(); --save this in a table somewhere to destroy later

	--modify impactedTerritory object to change to neutral + add the special unit for visibility purposes			
	impactedTerritory.AddSpecialUnits = {specialUnit_Isolation}; --add special unit
	--table.insert (modifiedTerritories, impactedTerritory);
	printObjectDetails (specialUnit_Isolation, "Isolation specialUnit", "Isolation"); --show contents of the Isolation special unit
	
	local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Neutralize action
	--need WL.GameOrderEvent.Create to modify territories (add special units) + jump to location + card/piece changes, and need WL.GameOrderCustom.Create for occursInPhase modifier (is this it?)
	--actually think we can get away with just Event
	local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
	event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function; this actually adds the game order that changes territory to neutral & adds the special unit

	--save data in Mod.PublicGameData so the special unit can be destroyed later
	local publicGameData = Mod.PublicGameData;
	local turnNumber_IsolationExpires = -1;
	--print ("PRE  Isolation#items="..tablelength(publicGameData.IsolationData));
	printObjectDetails (publicGameData.IsolationData, "[PRE  Isolation data]", "Execute Isolation operation");
	
	if (Mod.Settings.IsolationDuration==0) then  --if Isolation duration is Permanent (don't auto-revert), set expiration turn to -1
		turnNumber_IsolationExpires = -1; 
	else --otherwise, set expire turn as current turn # + card Duration
		turnNumber_IsolationExpires = game.Game.TurnNumber + Mod.Settings.IsolationDuration; 
	end
	print ("expire turn#="..turnNumber_IsolationExpires.."::duration=="..Mod.Settings.IsolationDuration.."::gameTurn#="..game.Game.TurnNumber.."::calcExpireTurn=="..game.Game.TurnNumber + Mod.Settings.IsolationDuration.."::");
	--even if Isolation duration==0, still make a note of the details of the Isolation action - probably not required though
	local IsolationDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberIsolationEnds=turnNumber_IsolationExpires, specialUnitID=specialUnit_Isolation.ID};---&&&
	publicGameData.IsolationData [targetTerritoryID] = IsolationDataRecord; --do it as a non-contiguous array so can be referenced later as (publicGameData.IsolationData [targetTerritoryID] ~= nil) to identify if Isolation impacts a given territory
	--table.insert (publicGameData.IsolationData, IsolationDataRecord);  --don't use this method, as it wastes the key by making it an auto-incrementing integer, rather than something meaningful like the territory ID
	Mod.PublicGameData = publicGameData;
	printObjectDetails (publicGameData.IsolationData, "[POST Isolation data]");
	printObjectDetails (IsolationDataRecord, "[POST Isolation data record]");
	print ("POST Isolation#items="..tablelength(publicGameData.IsolationData));
	print ("[PROCESS ISOLATION END] playerID="..gameOrder.PlayerID.."::terr="..targetTerritoryID.."::".."description="..gameOrder.Description.."::");
end

--set game data here, actual Pestilence application is done in Server_TurnAdvance_End
function execute_Pestilence_operation (game, gameOrder, addOrder, pestilenceTarget_playerID)
	print ("[PESTILENCE CARD USED] on player "..pestilenceTarget_playerID.."/".. toPlayerName (pestilenceTarget_playerID, game) .." by ".. gameOrder.PlayerID .. "/" ..  toPlayerName (gameOrder.PlayerID, game).."::");
	local publicGameData = Mod.PublicGameData;
    local PestilenceWarningTurn = game.Game.TurnNumber+1; --for now, make PestilenceWarningTurn = current turn +1 turn from now (next turn)
    local PestilenceStartTurn = game.Game.TurnNumber+2;   --for now, make PestilenceStartTurn = current turn +2 turns from now 
	local PestilenceEndTurn = PestilenceStartTurn + Mod.Settings.PestilenceDuration -1;  --sets end turn appropriately to align with specified duration for Pestilence

	print ("[PESTILENCE] creating event for target "..pestilenceTarget_playerID.."/".. toPlayerName (pestilenceTarget_playerID, game) .." by ".. gameOrder.PlayerID .. "/" ..  toPlayerName (gameOrder.PlayerID, game)..", warningTurn=="..PestilenceWarningTurn..", startTurn=="..PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");
    --fields are Pestilence|playerID target|player ID caster|turn# Pestilence warning|turn# Pestilence begins|turn# Pestilence ends
	publicGameData.PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.PlayerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};
	Mod.PublicGameData=publicGameData;
end

function execute_Deneutralize_operation (game, gameOrder, result, skip, addOrder, targetTerritoryID)
	print ("[execute DENEUTRALIZE] terr=="..targetTerritoryID..":: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
	local currentTargetTerritory = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID]; --current state of target territory, can check if it's already neutral, etc
	local currentTargetOwnerID = currentTargetTerritory.OwnerPlayerID;
	local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
	local targetTerritoryName = game.Map.Territories[targetTerritoryID].Name;
	local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
	local impactedTerritoryOwnerID = nil;   -- the player to be assigned the territory
	local targetTerritoryID = nil;
	local impactedTerritoryOwnerName = nil;
	local strArrayModData = split(gameOrder.ModData,'|');
		--1st element is Deneutralize (don't need it, we already know, we're processing a Deneutralize order)
	targetTerritoryID = tonumber (strArrayModData[2]); --2nd element is target territory ID; this overwrites the value passed in as the parameter; they should be the same value though
	impactedTerritoryOwnerID = tonumber (strArrayModData[3]);  --3rd element is new owner (impactedTerritoryOwnerID)

	print ("[execute DENEUTRALIZE] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::currentOwner=="..currentTargetOwnerID.."::newOwner=="..impactedTerritoryOwnerID.."::canTargetNaturalNeutrals=="..tostring(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals) .."::DeneutralizeCanUseOnNeutralizedTerritories=="..tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories).."::");

	--check if the target territory is neutral, if so, assign it to specified player, otherwise do nothing
	if (currentTargetOwnerID ~= WL.PlayerID.Neutral) then
	--if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral) then
		print ("territory is not neutral -- do nothing"); --this could happen if another mod or WZ makes the territory neutral after the order as input on client side but before this order processes
	else
		--future: check settings for if can be cast on natural neutrals and/or Neutralized territories
		local privateGameData = Mod.PrivateGameData; 
		local neutralizeData = privateGameData.NeutralizeData;
		print ("[DENEUTRALIZE] @@@--------------------------------------");
		print ("[DENEUTRALIZE] neutralizeData [targetTerritoryID] == nil) --> ".. tostring (Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil)..", type "..type (targetTerritoryID).."::");
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil));
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [tonumber(targetTerritoryID)]==nil));
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [93]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [93]==nil));

		--[[local frak = Mod.PrivateGameData.NeutralizeData [targetTerritoryID];
		for k,v in pairs (frak) do
			print ("     "..k,v);
		end]]
		local neutralizeDataRecord = nil;
		local boolIsNeutralizedTerritory = false; --if ==true -> Neutralized territory; if ==false -> natural neutral
		local boolSettingsRuleViolation = false;  --abort if Mod settings for application on Natural Neutrals or Neutralized territories don't align to action taken
		local strSettingsRuleViolationMessage = "";
		local specialUnitID = nil;

		print ("[DENEUTRALIZE] Neutralization data:");
		for k,v in pairs (Mod.PrivateGameData.NeutralizeData) do
			print ("[DENEUTRALIZE] ###--------------------------------------");
			printObjectDetails (v, "record", "NeutralizeData");
			print ("[DENEUTRALIZE] $$$--------------------------------------");
			print (tostring(k)..", " ..tostring(v.territory)..", " ..tostring(v.castingPlayer)..", "..tostring(v.impactedTerritoryOwnerID)..", " .. tostring(v.turnNumber_NeutralizationExpires) .. ", ".. tostring(v.specialUnitID));
		end
		--for reference: local neutralizeDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberToRevert=turnNumber_NeutralizationExpires, specialUnitID=specialUnit_Neutralize.ID};

		if (neutralizeData [targetTerritoryID] ~= nil) then
			print ("[DENEUTRALIZE] Neutralized territory target")
			--Neutralized territory; abort if Mod settings don't permit this
			neutralizeDataRecord = neutralizeData [targetTerritoryID];
			specialUnitID = neutralizeDataRecord.specialUnitID; --grab ID# of 'Neutralize' special unit so it can be removed from the territory (but not here, we're just checking if it's a Neutralized territory, not changing anything yet)
			--for reference: local neutralizeDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberToRevert=turnNumber_NeutralizationExpires, specialUnitID=specialUnit_Neutralize.ID};
			boolIsNeutralizedTerritory = true;
			if (Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == false) then
				boolSettingsRuleViolation = true;
				print ("[DENEUTRALIZE] Neutralized territory targets not permitted");
				strSettingsRuleViolationMessage = "Target "..targetTerritoryName.." is a Neutralized territory, which is not permitted as per the mod settings for the Deneutralize card.";
			end
		else
			print ("[DENEUTRALIZE] Natural neutral territory target")
			--Natural neutral; abort if Mod settings don't permit this
			if Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == false then
				boolSettingsRuleViolation = true;
				print ("[DENEUTRALIZE] Natural neutral territory targets not permitted");
				strSettingsRuleViolationMessage = "Target "..targetTerritoryName.." is a natural neutral territory, which is not permitted as per the mod settings for the Deneutralize card.";
			end
		end

		--if no violations, then process Deneutralization action
		if (boolSettingsRuleViolation == false) then
			--if target territory is a neutralized territory, then remove the data record from NeutralizeData & remove the 'Neutralized' special unit from the territory
			if (boolIsNeutralizedTerritory == true) then
				--this eliminates this element from the table
				neutralizeData[targetTerritoryID] = nil;
				impactedTerritory.RemoveSpecialUnitsOpt = {specialUnitID}; --remove the 'Neutralized' special unit from the territory

				print ("[DENEUTRALIZE] remove special "..specialUnitID.."::");
				--print ("[DENEUTRALIZE] #specials on target territory: "..#impactedTerritory.NumArmies.SpecialUnits.."::]");
				--for k,sp in pairs (currentTargetTerritory.NumAries.SpecialUnits) do
				--	print ("[DENEUTRALIZE] "..k..", special Name: "..sp.Name..", proxyType "..sp.proxyType..", ID "..sp.ID.."::");
				--end
					
				--resave privateGameData
				privateGameData.NeutralizeData = neutralizeData;
				Mod.PrivateGameData = privateGameData;
			end

			--assign the target territory neutral to new owner
			print ("territory is neutral -- assign to new owner");
			impactedTerritory.SetOwnerOpt=impactedTerritoryOwnerID;
			impactedTerritoryOwnerName = toPlayerName (impactedTerritoryOwnerID, game);

			table.insert (modifiedTerritories, impactedTerritory);

			local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Deneutralize action
			local strDeneutralizeOrderMessage = toPlayerName(gameOrder.PlayerID, game) ..' deneutralized ' .. targetTerritoryName .. ', assigned to '..impactedTerritoryOwnerName;
			--print ("message=="..strDeneutralizeOrderMessage);
			local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, strDeneutralizeOrderMessage, {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
			addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function
		else
			addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strSettingsRuleViolationMessage, {}, {},{}));
			skip(WL.ModOrderControl.Skip);
		end		
	end
end

function execute_Neutralize_operation (game, gameOrder, result, skip, addOrder, targetTerritoryID)
	local currentTargetTerritory = nil;
	print ("[execute NEUTRALIZE] terr=="..targetTerritoryID.."::");
	currentTargetTerritory = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID]; --current state of target territory, can check if it's already neutral, etc
	local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
	local targetTerritoryName = game.Map.Territories[targetTerritoryID].Name;
	local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
	local impactedTerritoryOwnerID = nil;

	impactedTerritoryOwnerID = currentTargetTerritory.OwnerPlayerID;
	print ("[execute NEUTRALIZE] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::currentOwner=="..impactedTerritoryOwnerID);

	--check if the target territory is neutral already, and if so, do nothing
	if (impactedTerritoryOwnerID == WL.PlayerID.Neutral) then
	--if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID == WL.PlayerID.Neutral) then
		print ("territory already neutral -- do nothing"); --this could happen if another mod or WZ makes the territory neutral after the order as input on client side but before this order processes
	else
		-- if Neutralize applicability for Commanders or Specal Units is set to False, check for special units
		local AbortDueToSettingsScope = false;
		local CommandersPresent = false;
		local SpecialUnitsPresent = false;
		local CommandersViolation = false;
		local SpecialUnitsViolation = false;

		local impactedTerritoryLastStanding = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID];

		if (Mod.Settings.NeutralizeCanUseOnCommander == false or Mod.Settings.NeutralizeCanUseOnSpecials == false) then
			--NeutralizeCanUseOnSpecials = CreateCheckBox(NeutralizeDetailsline2).SetIsChecked(Mod.Settings.NeutralizeCanUseOnSpecials).SetInteractable(true).SetText("Can use on Special Units");
			print ("[Neutralization special unit inspection]--------------------- ");
			--printObjectDetails (impactedTerritoryLastStanding, "[impactedTerritory]", "[Neutralization special unit inspection]");
			--printObjectDetails (impactedTerritoryLastStanding.NumArmies.SpecialUnits, "[NumArmies.SpecialUnits]", "[Neutralization special unit inspection]");
			
			--check for specials
			print ("[#impactedTerritoryLastStanding.NumArmies.SpecialUnits=="..#impactedTerritoryLastStanding.NumArmies.SpecialUnits.."::]");
			if (#impactedTerritoryLastStanding.NumArmies.SpecialUnits >= 1) then --territory has 1+ special units
				for key, sp in pairs(impactedTerritoryLastStanding.NumArmies.SpecialUnits) do
					print ("-----new special unit; ID=="..sp.ID..":: proxyType=="..sp.proxyType.."::"); --tostring(spModID));
					if sp.proxyType == "Commander" then 
						CommandersPresent = true;
					else
						SpecialUnitsPresent = true;
					end
					--spModID = nil; 
					--if sp.ModID ~= nil then spModID=sp.ModID; end
					--print ("-----new special unit; ID=="..tostring(spModID));
					--printObjectDetails (sp, "special unit; key=="..key, "[Neutralization special unit inspection]");
					--printObjectDetails (sp.CombatOrder, "special unit CombatOrder", "[Neutralization special unit inspection]");
					--print  ("sp.CombatOrder=="..sp.CombatOrder.."::");
					--[[printObjectDetails (sp.ID, "special unit ID", "[Neutralization special unit inspection]");
					printObjectDetails (sp.OwnerID, "special unit OwnerID", "[Neutralization special unit inspection]");
					printObjectDetails (sp.proxyType, "special unit proxyType", "[Neutralization special unit inspection]");
					printObjectDetails (sp.readonly, "special unit readonly", "[Neutralization special unit inspection]");
					printObjectDetails (sp.readableKeys, "special unit readableKeys", "[Neutralization special unit inspection]");
					printObjectDetails (sp.writableKeys, "special unit writableKeys", "[Neutralization special unit inspection]");]]
				end

				-- check if Commanders or other Specials are in play, and if so if they are permitted by Mod.Settings
				strNeutralizeSkipOrderMessage = "";
				if (Mod.Settings.NeutralizeCanUseOnSpecials  == false and SpecialUnitsPresent == true) then
					--don't permit the action, settings prohibit it
					SpecialUnitsViolation = true;
					AbortDueToSettingsScope = true;
				end
				if (Mod.Settings.NeutralizeCanUseOnCommander == false and CommandersPresent == true) then
					CommandersViolation = true;
					AbortDueToSettingsScope = true;
				end

				--don't permit the action, settings prohibit it
			end
		end

		if (AbortDueToSettingsScope == true) then
			print ("SKIP THIS Neutralize -- specials/Commanders are in play & prohibited");
			if (CommandersViolation == true and SpecialUnitsViolation == true) then
				strNeutralizeSkipOrderMessage = "Commander and another Special Unit";
			elseif (CommandersViolation == false and SpecialUnitsViolation == true) then
				strNeutralizeSkipOrderMessage = "Special Unit";
			elseif (CommandersViolation == true and SpecialUnitsViolation == false) then
				strNeutralizeSkipOrderMessage = "Commander";
			else
				--no cases left
				strNeutralizeSkipOrderMessage = "[Unknown condition]";
			end

			strNeutralizeSkipOrderMessage = "Neutralize action skipped due to presence of a " .. strNeutralizeSkipOrderMessage .. " on target territory "..targetTerritoryName;
			
			print ("NEUTRALIZATION - skipOrder - playerID="..gameOrder.PlayerID.. "::territory="..targetTerritoryID .."/"..targetTerritoryName.."::"..strNeutralizeSkipOrderMessage.."::");
			addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strNeutralizeSkipOrderMessage, {}, {},{}));
			skip(WL.ModOrderControl.Skip);
	
		else
			print ("PROCESS THIS Neutralize");

			-- create special unit for Neutralize operations, place the special on the territory so it is visibly identifiable as being impacted by Neutralize; destroy the unit once captured or Deneutralized
			local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);  --assign unit to owner of the territory (not the caster of the Neutralize action)
			builder.Name = 'Neutralized territory';
			builder.IncludeABeforeName = false;
			builder.ImageFilename = 'neutralizedTerritory.png'; --max size of 60x100 pixels
			builder.AttackPower = 0;
			builder.DefensePower = 0;
			builder.DamageToKill = 0;
			builder.DamageAbsorbedWhenAttacked = 0;
			builder.Health = 0;
			builder.CombatOrder = 10001; --doesn't protect Commander
			builder.CanBeGiftedWithGiftCard = false;
			builder.CanBeTransferredToTeammate = false;
			builder.CanBeAirliftedToSelf = false;
			builder.CanBeAirliftedToTeammate = false;
			builder.IsVisibleToAllPlayers = false;
			builder.TextOverHeadOpt = "Neutralized";
			--builder.ModDate - ""; store some info in here? Not sure it's wise; unit could be killed, etc -- best to just store it in a table in privategatedata
			local specialUnit_Neutralize = builder.Build(); --save this in a table somewhere to destroy later

			--[[all SpecialUnit properties:
			AttackPower integer:
			AttackPowerPercentage number:
			CanBeAirliftedToSelf boolean:
			CanBeAirliftedToTeammate boolean:
			CanBeGiftedWithGiftCard boolean:
			CanBeTransferredToTeammate boolean:
			CombatOrder integer:
			DamageAbsorbedWhenAttacked integer:
			DamageToKill integer:
			DefensePower integer:
			DefensePowerPercentage number:
			Health Nullable<integer>: Added in v5.22.2
			ImageFilename string:
			IncludeABeforeName boolean:
			IsVisibleToAllPlayers boolean:
			ModData string:
			Name string:
			OwnerID PlayerID:
			TextOverHeadOpt string:]]

			--modify impactedTerritory object to change to neutral + add the special unit for visibility purposes			
			impactedTerritory.SetOwnerOpt=WL.PlayerID.Neutral; --make the target territory neutral
			impactedTerritory.AddSpecialUnits = {specialUnit_Neutralize}; --add special unit
			table.insert (modifiedTerritories, impactedTerritory);
			printObjectDetails (specialUnit_Neutralize, "Neutralize specialUnit", "Neutralize"); --show contents of the Neutralize special unit -- &&&
			
			local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Neutralize action
			local strNeutralizeOrderMessage = toPlayerName(gameOrder.PlayerID, game) ..' neutralized ' .. targetTerritoryName;
			local event = WL.GameOrderEvent.Create(gameOrder.PlayerID, strNeutralizeOrderMessage, {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
			addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function; this actually adds the game order that changes territory to neutral & adds the special unit
			
			--save data in Mod.PublicGameData so the territory can be reverted to normal state later
			local privateGameData = Mod.PrivateGameData;
			--local neutralizeData = privateGameData.NeutralizeData;
			local turnNumber_NeutralizationExpires = -1;
			print ("PRE  Neutralize#items="..tablelength(privateGameData.NeutralizeData));
			printObjectDetails (privateGameData.NeutralizeData, "[PRE  neutralize data]", "Execute neutralize operation");
			
			if (Mod.Settings.NeutralizeDuration==0) then  --if Neutralization duration is Permanent (don't auto-revert), set expiration turn to -1
				turnNumber_NeutralizationExpires = -1; 
			else --otherwise, set expire turn as current turn # + card Duration
				turnNumber_NeutralizationExpires = game.Game.TurnNumber + Mod.Settings.NeutralizeDuration; 
			end
			print ("expire turn#="..turnNumber_NeutralizationExpires.."::duration=="..Mod.Settings.NeutralizeDuration.."::gameTurn#="..game.Game.TurnNumber.."::calcExpireTurn=="..game.Game.TurnNumber + Mod.Settings.NeutralizeDuration.."::");
			--even if Neutralization duration==0, still make a note of the details of the Neutralization action, in case Deneutralization is used to revive the territory, it's key to know who it's assigned to
			--consider making a special "Neutralization" special unit as a visual indifier that the territory was Neutralized and thus can be Deneutralized, or will auto-revive if that setting is in play
			local neutralizeDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberToRevert=turnNumber_NeutralizationExpires, specialUnitID=specialUnit_Neutralize.ID};
			--table.insert (privateGameData.NeutralizeData, neutralizeDataRecord);   --adds new record to table privateGameData.NeutralizeData, but table.insert auto-uses incremental integers for the keys, ie: wasted opportunity, instead assign it directly to the object @ element of the territory ID, then can access it via privateGameData.NeutralizeData[terrID] to get the record back instead of looping through the entire table to find it
			privateGameData.NeutralizeData [targetTerritoryID] = neutralizeDataRecord;  --save record to privateGameData.NeutralizeData @ element of territory ID, so can reference it later via privateGameData.NeutralizeData[terrID] for easy use

			Mod.PrivateGameData = privateGameData;
			printObjectDetails (privateGameData.NeutralizeData, "[POST neutralize data]");
			printObjectDetails (neutralizeDataRecord, "[POST neutralize data record]");
			print ("POST Neutralize#items="..tablelength(privateGameData.NeutralizeData));
			print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil));

		end		
	end
end

function process_Isolation_expirations (game,addOrder)
	local publicGameData = Mod.PublicGameData; 
	local IsolationData = publicGameData.IsolationData;
	print ("[ISOLATION EXPIRATIONS] START");
	print ("[process_Isolation_expirations]# of Isolation data records=="..tablelength(IsolationData)..", IsolationData==nil -->"..tostring(publicGameData.IsolationData==nil).."::");
	--print ("IsolationData==nil -->"..tostring(publicGameData.IsolationData==nil).."::");
	--print ("IsolationData=={} -->"..tostring(publicGameData.IsolationData=={}).."::");

	--if there are pending Isolation orders, check if any expire this turn and if so execute those actions (delete the special unit to identify the Isolated territory)
	if (tablelength (IsolationData)==0) then
	--if (#IsolationData==0) then
		print ("[ISOLATION EXPIRATIONS] no pending Isolation data");
		return;
	end
	
	--Duration==-1 means permanently Isolated, just leave the special unit there forever -- exit function, do nothing
	if (Mod.Settings.IsolationDuration == -1) then
		print ("ISOLATION is Permanent! Do not expire, do not delete the Special Unit");
		return;
	end
	
	print ("tablelength (IsolationData)=="..tablelength (IsolationData));
	if (tablelength (Mod.PublicGameData.IsolationData)) == 0 then print ("IsolationData is empty"); return; end

	for _,IsolationDataRecord in pairs(Mod.PublicGameData.IsolationData) do
		if (IsolationDataRecord.turnNumberIsolationEnds <= game.Game.TurnNumber) then   --do this for ease of testing temporarily; revert later to the line below that is commented out
			local castingPlayerID = IsolationDataRecord.castingPlayer;     --the player who cast the Isolation action
			local targetTerritoryID = IsolationDataRecord.territory;       --target territory ID that was Isolationd and now potentially reverting to ownership by a player
			local targetTerritoryName = game.Map.Territories[targetTerritoryID].Name;
			local targetTerritory = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID]; --current state of target territory, can check if it's already owned by someone else, etc
			local territoryOwnerID_former = IsolationDataRecord.territoryOwner;  --owner of the territory @ time of Isolation invocation (may be different now); if territory is neutral, revert owner back to this player
			local territoryOwnerID_current = targetTerritory.OwnerPlayerID;  --actual current owner of the territory; ==0 indicate neutral (ok to revive), ~=0 indicates someone else owns it now (don't revive it)
			local specialUnitID = IsolationDataRecord.specialUnitID;
			print ("[check ENDING Isolation] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::currentOwner=="..territoryOwnerID_current.."::formerOwner=="..territoryOwnerID_former);

			print ("[EXECUTE Isolation revert]");
			local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
			local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
			
			impactedTerritory.RemoveSpecialUnitsOpt = {specialUnitID}; --remove the special unit from the territory
			local strRevertIsolationOrderMessage = "Isolation ends";
	
			local event = WL.GameOrderEvent.Create(territoryOwnerID_current, strRevertIsolationOrderMessage, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
			addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function

			--pop off this item from the Isolation table!
			publicGameData.IsolationData [targetTerritoryID] = nil;
			Mod.PublicGameData = publicGameData;
		else
			print ("expiry not yet");
		end
		printObjectDetails (IsolationDataRecord, "IsolationDataRecord", "[S_AT_S_PNE]");
	end
	print ("[ISOLATION EXPIRATIONS] END");
end

function process_Neutralize_expirations (game,addOrder)
	local privateGameData = Mod.PrivateGameData; 
	local neutralizeData = privateGameData.NeutralizeData;
	local neutralizeDataRecord = nil;
	local numNeutralizeActionsPending = tablelength(privateGameData.NeutralizeData);
	
	print ("[process_Neutralize_expirations]# of neutralize data records=="..numNeutralizeActionsPending..", neutralizeData==nil -->"..tostring(privateGameData.NeutralizeData==nil).."::");
	--print ("neutralizeData==nil -->"..tostring(privateGameData.NeutralizeData==nil).."::");
	--print ("neutralizeData=={} -->"..tostring(privateGameData.NeutralizeData=={}).."::");

	if (numNeutralizeActionsPending==0) then
		print ("no pending Neutralize data")
		return;
	end

	--Duration==-1 means permanently Neutralized, just leave the special unit there forever -- exit function, do nothing
	if (Mod.Settings.NeutralizeDuration == -1) then
	--if (NeuralizeDataRecord.turnToRevert == -1) then
		print ("NEUTRALIZE is Permanent! Do not expire, do not delete the Special Unit");
		return;
	end
	
	for _,neutralizeDataRecord in pairs(neutralizeData) do
		if (neutralizeDataRecord.turnNumberToRevert <= game.Game.TurnNumber) then   --if expires this turn or earlier (and was somehow missed [this shouldn't happen]), process the expiry
			local castingPlayerID = neutralizeDataRecord.castingPlayer;     --the player who cast the Neutralize action
			local targetTerritoryID = neutralizeDataRecord.territory;       --target territory ID that was neutralized and now potentially reverting to ownership by a player
			local targetTerritoryName = game.Map.Territories[targetTerritoryID].Name;
			local targetTerritory = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID]; --current state of target territory, can check if it's already owned by someone else, etc
			local territoryOwnerID_former = neutralizeDataRecord.territoryOwner;  --owner of the territory @ time of Neutralize invocation (may be different now); if territory is neutral, revert owner back to this player
			local territoryOwnerID_current = targetTerritory.OwnerPlayerID;  --actual current owner of the territory; ==0 indicate neutral (ok to revive), ~=0 indicates someone else owns it now (don't revive it)
	
			print ("[check REVERT NEUTRALIZE] terr=="..targetTerritoryID.."::terrName=="..targetTerritoryName.."::currentOwner=="..territoryOwnerID_current.."::formerOwner=="..territoryOwnerID_former);

			if (territoryOwnerID_current ~= WL.PlayerID.Neutral) then
				--owned by another player, zannen munen
				print ("owned by another player, zannen munen");
				-- cancel the order, pop off the Neutralize record
				neutralizeData[targetTerritoryID] = nil; --this eliminates this element from the table
			else
				--territory is still neutral, so okay to revert it to original owner
				print ("[EXECUTE Neutralize revert]");
				local impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
				local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
				
				--contents of neutralizeDataRecord are: {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberToRevert=turnNumber_NeutralizationExpires, specialUnitID=specialUnit_Neutralize.ID};
				impactedTerritory.RemoveSpecialUnitsOpt = {neutralizeDataRecord.specialUnitID}; --remove the Neutralize special unit from the territory; no error occurs if object is already destroyed

				--[[  --get Neutralize special ---&&&
				print ("#targetTerritory.NumArmies.SpecialUnits==".. #targetTerritory.NumArmies.SpecialUnits.."::");
				if (#targetTerritory.NumArmies.SpecialUnits >= 1) then --territory has 1+ special units
					for key, sp in pairs(targetTerritory.NumArmies.SpecialUnits) do
				--if (#impactedTerritory.NumArmies.SpecialUnits >= 1) then --territory has 1+ special units
					--for key, sp in (impactedTerritory.NumArmies.SpecialUnits) do
						print ("-----new special unit; ID=="..sp.ID..":: proxyType=="..sp.proxyType.."::"); --tostring(spModID));
						if sp.proxyType == "CustomSpecialUnit" then
							print ("[CustomSpecialUnit] name=="..sp.Name.."::");
						end
						printObjectDetails (sp, "Neutralize special unit", "Neutralize Expire revive");
						if (sp.Name == "Neutralized territory") then
							impactedTerritory.RemoveSpecialUnitsOpt = {sp.ID};
							print ("[kill special] ID="..sp.ID..":: name="..sp.Name.."::");
						else
							print ("[DON'T kill special] ID="..sp.ID..":: name="..sp.Name.."::");
						end
					end
				end]]
				
				impactedTerritory.SetOwnerOpt=territoryOwnerID_former;
				table.insert (modifiedTerritories, impactedTerritory);
		
				local territoryOwnerName_former = toPlayerName (territoryOwnerID_current);
				local strRevertNeutralizeOrderMessage = targetTerritoryName ..' reverted from neutral to owned by ' .. territoryOwnerName_former;
				local event = WL.GameOrderEvent.Create(territoryOwnerID_former, strRevertNeutralizeOrderMessage, {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
				event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
				addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function
				
				--pop off this item from the Neutralize table!
				neutralizeData[targetTerritoryID] = nil; --this eliminates this element from the table
			
			end
		else
			print ("expiry not yet");
		end
		printObjectDetails (neutralizeDataRecord, "neutralizeDataRecord", "[S_AT_S_PNE]");
	end

	--resave privateGameData
	privateGameData.NeutralizeData = neutralizeData;
	Mod.PrivateGameData = privateGameData;
end

function execute_Nuke_operation(game, order, addOrder, targetTerritoryID)
	local modifiedTerritories = {}; --create table of modified territories to pass back to WZ to update the territories and associate with the order
	local impactedTerritory;
	--local targetTerritoryID = tonumber(split(order.ModData,'|')[2]);
	local targetTerritory;
	local targetTerritoryName = game.Map.Territories[targetTerritoryID].Name;
	
	--print ("[newstyle]EXECUTE NUKE on "..targetTerritoryName.."//"..targetTerritoryID.."::");--" blastRadius=="..Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo.."::");
	print ("[EXECUTE NUKE] on "..targetTerritoryName.."//"..targetTerritoryID..":: blastRadius=="..Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo.."::");
	print ("[EXECUTE NUKE] maindam%=="..Mod.Settings.NukeCardMainTerritoryDamage..", maindamFix=="..Mod.Settings.NukeCardMainTerritoryFixedDamage..", conndam%=="..Mod.Settings.NukeCardConnectedTerritoryDamage.. ", conndamFix="..Mod.Settings.NukeCardConnectedTerritoryFixedDamage..", connTerrSpreadDelta==".. Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta .."::");

	--apply damage to main territory
	if (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID ~= order.PlayerID or Mod.Settings.NukeFriendlyfire == true) then
		print ("NUKE PRE  main territory="..targetTerritoryName.."//"..targetTerritoryID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies.."::");
		impactedTerritory = WL.TerritoryModification.Create(targetTerritoryID); --create territory object
		impactedTerritory.AddArmies = math.floor (game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies * (-1 * (Mod.Settings.NukeCardMainTerritoryDamage / 100)) -Mod.Settings.NukeCardMainTerritoryFixedDamage);
		table.insert (modifiedTerritories, impactedTerritory); --add territory object to the table to be passed back to WZ to modify/add the order
		print ("NUKE POST main territory="..targetTerritoryName.."//"..targetTerritoryID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies.."::#armiesKilled=="..game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies * (-1 * (Mod.Settings.NukeCardMainTerritoryDamage / 100)) - Mod.Settings.NukeCardMainTerritoryFixedDamage);
	end

	--ORIG code
	--apply damage to connected territories; FUTURE: to increase blast radius, must keep list of already impacted territories so they're not hit 2+ times since A->B which connects back to A (etc) but A is already impacted
	--[[for _, conn in pairs(game.Map.Territories[targetTerritoryID].ConnectedTo) do
		if game.ServerGame.LatestTurnStanding.Territories[conn.ID].OwnerPlayerID ~= order.PlayerID or Mod.Settings.NukeFriendlyfire == true then
			print ("NUKE PRE  conn territory="..game.Map.Territories[conn.ID].Name.."//"..conn.ID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies.."::");
			impactedTerritory = nil;
			impactedTerritory = WL.TerritoryModification.Create(conn.ID);
			impactedTerritory.AddArmies = math.floor (game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies * (-1 * (Mod.Settings.NukeCardConnectedTerritoryDamage / 100)));
			table.insert (modifiedTerritories, impactedTerritory);
			print ("NUKE POST conn territory="..game.Map.Territories[conn.ID].Name.."//"..conn.ID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies.."::#armiesKilled=="..game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies.NumArmies * (-1 * (Mod.Settings.NukeCardConnectedTerritoryDamage / 100)));
		end
	end]]

	local nuke_alreadyProcessed = {};              -- track territories whose connected territories have already been processed (looped through), so don't waste processing territories that have already been cycled through
	local nuke_territoriesAlreadyNuked = {};       -- track territories already nuked, so territories are only applied damage once for the entire nuke action
	local nuke_territoriesInThisSpreadPhase = {};  -- track territories in the current spread phase (# of territories from epicenter), apply damage to each connected territory in this list excepting those already nuked
	nuke_territoriesAlreadyNuked [targetTerritoryID] = true;      -- add main territory so it doesn't get nuked again
	nuke_territoriesInThisSpreadPhase [targetTerritoryID] = true; -- add main territory so can start processing connected territories from here
	--table.insert (nuke_territoriesAlreadyNuked, targetTerritoryID);      -- add main territory
	--table.insert (nuke_territoriesInThisSpreadPhase, targetTerritoryID); -- add main territory
	print ("next(nuke_territoriesInThisSpreadPhase)=="..next(nuke_territoriesInThisSpreadPhase).."----------------------1");
	print ("next(nuke_territoriesInThisSpreadPhase)=="..tostring(next(nuke_territoriesInThisSpreadPhase)==nil).."----------------------1");
	print ("next(nuke_territoriesInThisSpreadPhase)=="..next(nuke_territoriesInThisSpreadPhase).."----------------------1");
	print ("next(nuke_territoriesInThisSpreadPhase)=="..tostring(next(nuke_territoriesInThisSpreadPhase)==nil).."----------------------1");
	print ("next(nuke_territoriesInThisSpreadPhase)=="..next(nuke_territoriesInThisSpreadPhase).."----------------------1");
	print ("next(nuke_territoriesInThisSpreadPhase)=="..tostring(next(nuke_territoriesInThisSpreadPhase)==nil).."----------------------1");

	local damageFactor = 1;
	local cycleCount = 0; -- 1 cycle = processing 1 layer of territory connections out from the epicenter

	-- loop while (A) damage is still being, (B) there are still territories that haven't been nuked yet, (C) still within blast range
	while (damageFactor > 0 and next(nuke_territoriesInThisSpreadPhase) ~= nil and cycleCount < Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo) do
		print ("[CYCLE START]");
		for k,v in pairs (nuke_territoriesInThisSpreadPhase) do
			print ("[member] terr="..k.."/".. game.Map.Territories[k].Name)
		end
		cycleCount = cycleCount + 1;
		if (cycleCount==1) then
			damageFactor = 1; --for 1st iteration, use the Connected Territory damage stats as-is specified in the Mod.Settings; reduce the values for the further outward spreads
		else
			damageFactor = math.max(0, 1 - (Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta/100 * cycleCount)); --use max with 0 so it never goes below 0 and starts multiplying by negative values which would alternate healing/damaging with each cycle
		end
		print ("\n\n\nNUKE SPREAD cycleCount=="..cycleCount..":: damageFactor=="..damageFactor.."::, #nuke_territoriesInThisSpreadPhase=="..#nuke_territoriesInThisSpreadPhase.."----------------------2");

		local nuke_territoriesInNextSpreadPhase = {};

		--remove items from nuke_territoriesInThisSpreadPhase that have been processed already; this speeds up processing, rather than reprocessing them, their connections, and skipping each one
		local count = 0;
		for terrID,_ in pairs (nuke_territoriesInThisSpreadPhase) do --loop through each territory in the current spreadphase; for phase 1, this will always be the target territory (epicenter)
			count = count + 1;
			if (nuke_alreadyProcessed[terrID] ~= nil) then --if ==nil then territory is not in table and thus not processed  yet; if==true then it's in table and already processed
				-- has been processed already, don't process it again
				print ("[next cycle dupe] remove id="..terrID.."/"..game.Map.Territories[terrID].Name);
				--table.remove (nuke_territoriesInThisSpreadPhase, [terrID]);   <--- this only works with consecutive integers, else it needs to be a [string] key
				nuke_territoriesInThisSpreadPhase[terrID] = nil; -- this eliminates this element from the table
			else
				print ("[next cycle keep] keep   id="..terrID.."/"..game.Map.Territories[terrID].Name);
			end
		end
		print ("nextCycle #elements="..count);

		if ((next(nuke_territoriesInThisSpreadPhase) ~= nil) and damageFactor > 0) then
		--if there's no unprocessed territories left in the next cycle to process, it means all territories connected to the epicenter have been processed, and any further
		--alternatively, if the damageFactor has reached 0, stop processing as there's no point in assigning 0 damage to territories
		--don't check (#nuke_territoriesInThisSpreadPhase > 0) b/c #table only evaluates arrays, ie: tables with numeric indeces that have no gaps! So if the table has assigned values for keys 2,5,10 but not 1,3,4,6,7,8,9 then it will return erattic results
			
			for terrID,_ in pairs (nuke_territoriesInThisSpreadPhase) do --loop through each territory in the current spreadphase; for phase 1, this will always be the target territory (epicenter)
				print ("___loop on terr=".. game.Map.Territories[terrID].Name.."//"..terrID..", alreadyProcessed==" .. tostring(nuke_alreadyProcessed[terrID]~=nil) .. ", alreadyNuked==".. tostring(nuke_territoriesAlreadyNuked[terrID]~=nil).."::");

				-- skip the territory if it's been processed already
				if (nuke_alreadyProcessed[terrID]==nil) then
					nuke_alreadyProcessed [terrID] = true; -- don't process this territory again
					for _, conn in pairs(game.Map.Territories[terrID].ConnectedTo) do
						print ("","_spread from terrID "..terrID.." to conn.ID "..conn.ID.."/".. game.Map.Territories[conn.ID].Name..":: alreadyNuked==".. tostring(nuke_territoriesAlreadyNuked[conn.ID]~=nil).."::");
						if (nuke_territoriesAlreadyNuked[conn.ID] == nil) then --if ==nil then territory is not in table and thus not nuked yet; if==true then it's in table and already nuked yet
							print ("","","__apply damage [not nuked yet]");
							nuke_territoriesAlreadyNuked [conn.ID] = true;        --add to list so only gets nuked this one time
							nuke_territoriesInNextSpreadPhase [conn.ID] = true;   --add to list to loop through next cycle to nuke connected territories
							if (game.ServerGame.LatestTurnStanding.Territories[conn.ID].OwnerPlayerID ~= order.PlayerID or Mod.Settings.NukeFriendlyfire == true) then
								print ("","","","NUKE PRE  conn territory="..game.Map.Territories[conn.ID].Name.."//"..conn.ID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies.."::");
								impactedTerritory = nil;
								impactedTerritory = WL.TerritoryModification.Create(conn.ID);

								local numArmies = game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies;
								local percentageDamage = Mod.Settings.NukeCardConnectedTerritoryDamage / 100;
								local fixedDamage = Mod.Settings.NukeCardConnectedTerritoryFixedDamage;
								local percentageBasedDamage = numArmies * percentageDamage;
								local totalDamageBeforeFactor = percentageBasedDamage + fixedDamage;
								local totalDamageWithFactor = totalDamageBeforeFactor * damageFactor;
								local roundedDamage = math.floor(totalDamageWithFactor);
								local damageActuallyTaken = -1 * roundedDamage;
								
								-- Print intermediate results
								print ("---===---===---");
								print("numArmies:", numArmies ..":: factor=="..damageFactor);
								print("percentageDamage:", percentageDamage);
								print("fixedDamage:", fixedDamage);
								print("damageFactor:", damageFactor);
								print("percentageBasedDamage:", percentageBasedDamage);
								print("totalDamageBeforeFactor:", totalDamageBeforeFactor);
								print("totalDamageWithFactor:", totalDamageWithFactor);
								--print("roundedDamage:", roundedDamage);
								print("damageActuallyTaken:", damageActuallyTaken);
								--local damageActuallyTaken = -1 * (math.floor ((game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies * (Mod.Settings.NukeCardConnectedTerritoryDamage/100) + Mod.Settings.NukeCardConnectedTerritoryFixedDamage) * damageFactor));

								--local damageActuallyTaken = -1 * (math.floor ((game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies * (Mod.Settings.NukeCardConnectedTerritoryDamage/100) + Mod.Settings.NukeCardConnectedTerritoryFixedDamage) * damageFactor));

								impactedTerritory.AddArmies = (damageActuallyTaken);
								table.insert (modifiedTerritories, impactedTerritory);
								print ("NUKE POST conn territory="..game.Map.Territories[conn.ID].Name.."//"..conn.ID.."::".."armies="..game.ServerGame.LatestTurnStanding.Territories[conn.ID].NumArmies.NumArmies.."::#armiesKilled=="..damageActuallyTaken);
							end
						else
							print ("[SKIP - already nuked]");
						end
					end
				else
					print ("[SKIP - already processed]");
				end
			end
		else
			print ("[NUKE END] due to damageFactor==0 or no more territories left unevalated");
		end
		nuke_territoriesInThisSpreadPhase = nuke_territoriesInNextSpreadPhase; -- finished with current cycle, now loop on the next cycle
		nuke_territoriesInNextSpreadPhase = {};

		print ("[CYCLE END] nuke_territoriesInThisSpreadPhase==nil=="..tostring(nuke_territoriesInThisSpreadPhase==nil));
	end
	print ("#territories impacted=="..tablelength(modifiedTerritories)..", cycles complete="..cycleCount);
	--printObjectDetails (order, "gameOrder");
	print ("playerID=="..order.PlayerID	.."::playerName=="..toPlayerName(order.PlayerID, game));
	--create a table of WL.GameOrderEvent.Create (...) or WL.GameOrderEvent.Create (...) objects, then pass this to addOrder (table, boolean) -- 2nd param is an optional boolean, if "true" then this order you're getting gets skipped if the gameOrder ends up being skipped (perhaps by something outside of your mod, by WZ iself, another mod, etc)

		--problem 1 --- check for {} empty next cycle ... for high territory spread but no territories left to spread to
		--problem 2 --- full reduction of damageFactor goes negative and heals

	local strNukeOrderMessage = toPlayerName(order.PlayerID, game) ..' nuked ' .. game.Map.Territories[targetTerritoryID].Name;
	local event = WL.GameOrderEvent.Create(order.PlayerID, strNukeOrderMessage, {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
	event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function
-- GameOrderEventWL Create (playerID: PlayerID, message: string, visibleToOpt: HashSet<PlayerID> | nil, terrModsOpt?: TerritoryModification[], setResoucesOpt: table<PlayerID, table<EnumResourceType, integer>> | nil, incomeModsOpt: IncomeMod[] | nil): GameOrderEvent # Creates a GameOrderEvent object
-- Create (playerID, message, visibileToOppenets - nil is ok, terrMods OPTIONAL, resources OPTIONAL - nil is ok, incomeMods OPTIONAL - nil is ok)
						--Fizz code START
						--[[ 
						local terrMod = WL.TerritoryModification.Create(targetTerritoryID);
						terrMod.AddSpecialUnits = {builder.Build()};
						addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Purchased a tank', {}, {terrMod}));]]
end

function CardBlock_processEndOfTurn(game, addOrder)
    local publicGameData = Mod.PublicGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);
    print("[CARD BLOCK] processEndOfTurn START");
    if (publicGameData.CardBlockData == nil) then print("[CARD BLOCK] no data"); return; end
    for key, record in pairs(publicGameData.CardBlockData) do
         if (record.turnNumberBlockEnds > 0 and turnNumber >= record.turnNumberBlockEnds) then
            local event = WL.GameOrderEvent.Create(record.castingPlayer, "Card Block expired", {}, {});
			addOrder(event, true);
			publicGameData.CardBlockData[key] = nil;
        end
    end
    Mod.PublicGameData = publicGameData;
    print("[CARD BLOCK] processEndOfTurn END");
end

--process actions that occur @ end of turn for various card types
function processEndOfTurn_Actions(game, addOrder)
    local publicGameData = Mod.PublicGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);
	for _,record in pairs (publicGameData.EndOfTurnData) do
		--sampleRecord = {turnNumber where action occurs, specials {specialUnitID, terrID where the special exists} table of special units that correlate to the event, card/event name/code for the event, ID# - the index# within the native table for that card/event that this relates to, any other data?}
		--do something with the data here
		
	end 
end 

function Tornado_processEndOfTurn(game, addOrder)
    local publicGameData = Mod.PublicGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);
    print("[TORNADO] processEndOfTurn START");
    if (publicGameData.TornadoData == nil) then print("[TORNADO] no data"); return; end
    for terrID, record in pairs(publicGameData.TornadoData) do
		local strTerritoryName = tostring(getTerritoryName(terrID, game));
		print ("[TORNADO] " ..terrID .."/".. strTerritoryName .." takes "..Mod.Settings.EarthquakeStrength.." damage");
		local impactedTerritory = WL.TerritoryModification.Create(terrID);
		impactedTerritory.AddArmies = -1 * Mod.Settings.TornadoStrength;
		local event = WL.GameOrderEvent.Create(record.castingPlayer, "Tornado ravages "..strTerritoryName, {}, {impactedTerritory});
		event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
		addOrder(event, true);
		--put a special unit here ... but can't at the moment b/c already have 5 special units in this mod! doh

         if (record.turnNumberTornadoEnds > 0 and turnNumber >= record.turnNumberTornadoEnds) then
            local impactedTerritory = WL.TerritoryModification.Create(terrID);
            print ("[TORNADO] effect ends on "..terrID.."/"..getTerritoryName (terrID, game).."::");
			
			--remove an Idle "power" structure from the territory
			local structures = game.ServerGame.LatestTurnStanding.Territories[terrID].Structures;
			if (structures == nil) then structures = {}; end; --this shouldn't happen, there should a 'power' structure on the territory
			if (structures[WL.StructureType.Power] == nil) then
				structures[WL.StructureType.Power] = 0;
			else
				structures[WL.StructureType.Power] = structures[WL.StructureType.Power] - 1;
			end

			impactedTerritory.SetStructuresOpt = structures;
            local event = WL.GameOrderEvent.Create(record.castingPlayer, "Tornado effect ends on "..getTerritoryName (terrID, game), {}, {impactedTerritory});
            event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
            addOrder(event, true);
            publicGameData.TornadoData[terrID] = nil;
         end
    end
    Mod.PublicGameData = publicGameData;
    print("[TORNADO] processEndOfTurn END");
end

function Earthquake_processEndOfTurn(game, addOrder)
	local publicGameData = Mod.PublicGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);
    print("[EARTHQUAKE] processEndOfTurn START");
    if (publicGameData.EarthquakeData == nil) then print("[EARTHQUAKE] no data"); return; end --if no Earthquake data, skip everything, just return

	for bonusID, record in pairs(publicGameData.EarthquakeData) do
		--implement earthquake action (damge to bonus territories)
		local modifiedTerritories = {};
		local strBonusName = nil;
		strBonusName = getBonusName (bonusID, game);
		print ("[EARTHQUAKE] An earthquake ravages bonus " ..bonusID .."/".. strBonusName);
		for _, terrID in pairs(game.Map.Bonuses[bonusID].Territories) do
			print ("[EARTHQUAKE] " ..terrID .."/".. tostring(getTerritoryName(terrID, game)) .." takes "..Mod.Settings.EarthquakeStrength.." damage");
			local impactedTerritory = WL.TerritoryModification.Create(terrID);
			impactedTerritory.AddArmies = -1 * Mod.Settings.EarthquakeStrength;
			table.insert(modifiedTerritories, impactedTerritory);
		end

		--get XY coordinates of the bonus; note this is estimated since it's based on the midpoints of the territories in the bonus (that's all WZ provides)
		local XYbonusCoords = getXYcoordsForBonus (bonusID, game);
		--# of map units to add as buffer to min/max X values to zoom/pan on the bonus; do this to increase chance of territories being on screen, since the X/Y calcs WZ provides are midpoints of the territories (and thus the bonuses), not the actual left/right/top/bottom coordiantes
		local X_buffer = 25; 
		local Y_buffer = 25;

		local event = WL.GameOrderEvent.Create(record.castingPlayer, "Earthquake ravages bonus "..strBonusName, {}, modifiedTerritories);
		event.JumpToActionSpotOpt = WL.RectangleVM.Create (XYbonusCoords.min_X-X_buffer, XYbonusCoords.min_Y-Y_buffer, XYbonusCoords.max_X+X_buffer, XYbonusCoords.max_Y+Y_buffer); --add/subtract 25's to add buffer on each side of bonus b/c it's calc'd from the midpoints of each territory, not the actual edges, so some territories can still get cut off when using their midpoints to zoom to
		addOrder(event, true);

		--publicGameData.EarthquakeData[targetBonusID] = {targetBonus = targetBonusID, castingPlayer = gameOrder.PlayerID, turnNumberEarthquakeEnds = turnNumber_EarthquakeExpires};
         if (record.turnNumberEarthquakeEnds > 0 and turnNumber >= record.turnNumberEarthquakeEnds) then
            local event = WL.GameOrderEvent.Create(record.castingPlayer, "Earthquake ended on bonus " .. getBonusName (bonusID, game), {}, {});
			--event.JumpToActionSpotOpt = WL.RectangleVM.Create (XYbonusCoords.average_X, XYbonusCoords.average_Y, XYbonusCoords.average_X, XYbonusCoords.average_Y);
			event.JumpToActionSpotOpt = WL.RectangleVM.Create (XYbonusCoords.min_X-X_buffer, XYbonusCoords.min_Y-Y_buffer, XYbonusCoords.max_X+X_buffer, XYbonusCoords.max_Y+Y_buffer); --add/subtract 25's to add buffer on each side of bonus b/c it's calc'd from the midpoints of each territory, not the actual edges, so some territories can still get cut off when using their midpoints to zoom to
			--[[game.Map.Bonuses[bonusID].MiddlePointX,
				game.Map.Bonuses[bonusID].MiddlePointY,
				game.Map.Bonuses[bonusID].MiddlePointX,
				game.Map.Bonuses[bonusID].MiddlePointY);]]
			addOrder(event, true);
            publicGameData.EarthquakeData[bonusID] = nil;
        end
    end

	Mod.PublicGameData = publicGameData;
    print("[EARTHQUAKE] processEndOfTurn END");
end

function Quicksand_processEndOfTurn(game, addOrder)
    local publicGameData = Mod.PublicGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);
    print("[QUICKSAND] processEndOfTurn START");
    if (publicGameData.QuicksandData == nil) then print("[QUICKSAND] no data"); return; end
    for terrID, record in pairs(publicGameData.QuicksandData) do
        --check if quicksand ends this turn (or earlier but was somehow missed) and if so, pop up the record from QuicksandData & remove the visual Special Unit
		if (record.turnNumberQuicksandEnds > 0 and turnNumber >= record.turnNumberQuicksandEnds) then
			local impactedTerritory = WL.TerritoryModification.Create(terrID);
			impactedTerritory.RemoveSpecialUnitsOpt = {record.specialUnitID};  -- adjust as needed to remove the Quicksand indicator
			local event = WL.GameOrderEvent.Create(record.castingPlayer, "Quicksand effect ends on "..getTerritoryName  (terrID, game), {}, {impactedTerritory});
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(
				game.Map.Territories[terrID].MiddlePointX,
				game.Map.Territories[terrID].MiddlePointY,
				game.Map.Territories[terrID].MiddlePointX,
				game.Map.Territories[terrID].MiddlePointY);
			addOrder(event, true);
			publicGameData.QuicksandData[terrID] = nil;
			--for reference: publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};

			--[[strQuicksandEndsMessage = "Quicksand ends on "..getTerritoryName  (terrID, game);
			local event = WL.GameOrderEvent.Create(record.castingPlayer, strQuicksandEndsMessage, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
			event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
			addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function]]
		else
			--Quicksand is active but not ending; check if the visual Special Unit is missing (killed); if so, recreate it
			local targetTerritory = game.ServerGame.LatestTurnStanding.Territories[terrID];
			print ("[QUICKSAND_PEOT] check special unit; terr.ID=="..terrID..", #specials==".. (#targetTerritory.NumArmies.SpecialUnits)..", seeking "..record.specialUnitID.."::");
			local boolQuicksandSpecialUnitFound = false;
			if (#targetTerritory.NumArmies.SpecialUnits >= 1) then
				for _,specialUnit in pairs (targetTerritory.NumArmies.SpecialUnits) do
					boolQuicksandSpecialUnitFound = (specialUnit.ID==record.specialUnitID);
					print ("----special on "..terrID.. "/"..	game.Map.Territories[terrID].Name..", matches seek item=="..tostring(specialUnit.ID==record.specialUnitID).."/"..tostring (boolQuicksandSpecialUnitFound)..", ID "..specialUnit.ID.."::"); --, ", isAttack=="..", isSuccessful=="..);
					--printObjectDetails (specialUnit, "[QPEOT]", "specialUnit details");
				end
			end
			
			--if the Quicksand special unit wasn't found, recreate it
			if (boolQuicksandSpecialUnitFound == false) then
				print ("[QUICKSAND] special unit killed / recreate it - - - - TRIPPING TIME - - - - - - - - - - ");
				--create new Quicksand special unit & apply to the territory
				local impactedTerritory = WL.TerritoryModification.Create(terrID);
				local specialUnit_Quicksand = build_Quicksand_specialUnit (game, terrID);
				impactedTerritory.AddSpecialUnits = {specialUnit_Quicksand};
				local event = WL.GameOrderEvent.Create(record.territoryOwner, "[Quicksand visual recreated]", {}, {impactedTerritory});
				addOrder(event);
				--update QuicksandData record to reflect the new special unit ID#
				publicGameData = Mod.PublicGameData; --don't redefine this as a local variable; it's already defined @ top of function, and saves Mod.PublicGameData again just before ending function; so if this is set to local, it'll override the function-wide variable, and get overwritten at end of function by the functin-wide variable that doesn't reflect the changes made inside of this IF structure
				local oldQuicksandDataRecord = publicGameData.QuicksandData [terrID];
				local newQuicksandDataRecord = {territory = oldQuicksandDataRecord.territory, castingPlayer = oldQuicksandDataRecord.castingPlayer, territoryOwner = oldQuicksandDataRecord.territoryOwner, turnNumberQuicksandEnds = oldQuicksandDataRecord.turnNumberQuicksandEnds, specialUnitID = specialUnit_Quicksand.ID}; --recreate QuicksandData record with ID# of the new special unit
				--publicGameData.QuicksandData[terrID] = nil;
				publicGameData.QuicksandData[terrID] = newQuicksandDataRecord;
				--for reference: publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};
				--Mod.PublicGameData = publicGameData; --resave public game data
				print ("[QUICKSAND] special unit killed / OLD    = "..oldQuicksandDataRecord.specialUnitID);
				print ("[QUICKSAND] special unit killed / NEW    = "..newQuicksandDataRecord.specialUnitID);
				print ("[QUICKSAND] special unit killed / NEWpub = "..Mod.PublicGameData.QuicksandData[terrID].specialUnitID);
			end
		end
    end
    Mod.PublicGameData = publicGameData;
    print("[QUICKSAND] processEndOfTurn END");
end

function Shield_processEndOfTurn(game, addOrder)
    local privateGameData = Mod.PrivateGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);

    print("[SHIELD] processEndOfTurn START");
    if (privateGameData.ShieldData == nil) then print("[SHIELD] no Shield data"); return; end

    for key, shieldDataRecord in pairs(privateGameData.ShieldData) do
        print("[SHIELD] 1 record");
        printObjectDetails(shieldDataRecord, "Shield data record", "Shield processEOT");
        print("[SHIELD] record, player=="..shieldDataRecord.castingPlayer.."/"..toPlayerName(shieldDataRecord.castingPlayer, game)..", expiryTurn="..shieldDataRecord.turnNumberShieldEnds..", specialUnitID=="..shieldDataRecord.specialUnitID.."::");
        if (shieldDataRecord.turnNumberShieldEnds > 0 and turnNumber >= shieldDataRecord.turnNumberShieldEnds) then
            print("[SHIELD] expire turn, time to remove");

            local terrID = findSpecialUnit(shieldDataRecord.specialUnitID, game);

            if (terrID ~= nil) then
                print("found special on "..terrID.."/"..game.Map.Territories[terrID].Name);
                local impactedTerritory = WL.TerritoryModification.Create(terrID);
                local modifiedTerritories = {};
                impactedTerritory.RemoveSpecialUnitsOpt = {shieldDataRecord.specialUnitID};
                table.insert(modifiedTerritories, impactedTerritory);
                local strShieldExpires = "Shield expired";
                local event = WL.GameOrderEvent.Create(shieldDataRecord.castingPlayer, strShieldExpires, {}, modifiedTerritories);
                event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
                addOrder(event, true);
                print("[SHIELD] "..strShieldExpires.."; delete special=="..shieldDataRecord.specialUnitID..", from "..terrID.."/"..game.Map.Territories[terrID].Name.."::");
                privateGameData.ShieldData[key] = nil;
                Mod.PrivateGameData = privateGameData;
                print("[SHIELD] POST tablelength=="..tablelength(Mod.PrivateGameData.ShieldData))
                print("[SHIELD] processEndOfTurn END");
                return;
            end
        end
    end

    print("[SHIELD] POST tablelength=="..tablelength(Mod.PrivateGameData.ShieldData))
    print("[SHIELD] processEndOfTurn END");
    Mod.PrivateGameData = privateGameData;
end

function Monolith_processEndOfTurn (game, addOrder)
	local privateGameData = Mod.PrivateGameData;
	local turnNumber = tonumber (game.Game.TurnNumber);

	print ("[MONOLITH] processEndOfTurn START");
	if (privateGameData.MonolithData == nil) then print ("[MONOLIGHT] no Monolith data"); return; end

	for key,monolithDataRecord in pairs (privateGameData.MonolithData) do
		print ("[MONOLITH] 1 record");
		printObjectDetails (monolithDataRecord, "Monolith data record", "Monolith processEOT");
		print ("[MONOLITH] record, player=="..monolithDataRecord.castingPlayer.."/"..toPlayerName (monolithDataRecord.castingPlayer, game) ..", expiryTurn="..monolithDataRecord.turnNumberMonolithEnds..", specialUnitID=="..monolithDataRecord.specialUnitID.."::");
		if (monolithDataRecord.turnNumberMonolithEnds > 0 and turnNumber >= monolithDataRecord.turnNumberMonolithEnds) then --check if this is the expiry turn for the monolith; ignore if duration=-1 which indicates permanence
			print ("[MONOLITH] expire turn, time to kill");

			local terrID = findSpecialUnit (monolithDataRecord.specialUnitID, game);

			if (terrID ~= nil) then
				--print ("found special on "..terrID);--.."/".. game.Map.Territories[terrID].Name);
				print ("found special on "..terrID.."/".. game.Map.Territories[terrID].Name);
				local impactedTerritory = WL.TerritoryModification.Create (terrID);  --object used to manipulate state of the territory (make it neutral) & save back to addOrder
				local modifiedTerritories = {}; --array of modified territories to pass into addOrder (in this case, just the 1 target territory)
				--local impactedTerritoryLastStanding = game.ServerGame.LatestTurnStanding.Territories[terrID];
				impactedTerritory.RemoveSpecialUnitsOpt = {monolithDataRecord.specialUnitID}; --remove the special unit from the territory
				table.insert (modifiedTerritories, impactedTerritory);
				local strMonolithExpires = "Monolith expired";
				local event = WL.GameOrderEvent.Create(monolithDataRecord.castingPlayer, strMonolithExpires, {}, modifiedTerritories); -- create Event object to send back to addOrder function parameter
				event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY, game.Map.Territories[terrID].MiddlePointX, game.Map.Territories[terrID].MiddlePointY);
				addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function
				print ("[MONOLITH] "..strMonolithExpires.."; delete special=="..monolithDataRecord.specialUnitID ..", from "..terrID.."/".. game.Map.Territories[terrID].Name.."::");	
				--pop off this item from the Monolith table!
				privateGameData.MonolithData[key] = nil; --this eliminates this element from the table
				Mod.PrivateGameData = privateGameData;   --save data back to WZ object
				print ("[MONOLITH] POST tablelength=="..tablelength (Mod.PrivateGameData.MonolithData))
				print ("[MONOLITH] processEndOfTurn END");
				return;
			end
		end
	end

	print ("[MONOLITH] POST tablelength=="..tablelength (Mod.PrivateGameData.MonolithData))
	print ("[MONOLITH] processEndOfTurn END");
	Mod.PrivateGameData = privateGameData;

end

--find & return the territory ID where a given special unit is
function findSpecialUnit (specialUnitID, game)
	print ("fsu, find=="..specialUnitID);
	for _,terr in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		print ("terr.ID=="..terr.ID..", #specials==".. (#terr.NumArmies.SpecialUnits));
		if (#terr.NumArmies.SpecialUnits >= 1) then
			for _,specialUnit in pairs (terr.NumArmies.SpecialUnits) do
				print ("1 special on "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
				printObjectDetails (specialUnit, "[FSU]", "specialUnit details");
				if (specialUnitID == specialUnit.ID) then
					print ("FOUND @ "..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name);
					return terr.ID;
				end
			end
		end
	end
	return nil;
end

function Pestilence_processEndOfTurn (game, addOrder)
	local publicGameData = Mod.PublicGameData;

	--print ("(game.ServerGame.Game.PlayingPlayers) ~= nil =="..tostring(((game.ServerGame.Game.PlayingPlayers) ~= nil)));

	--loop through list of active players (game.ServerGame.Game.PlayingPlayers includes only active remaining players; game.ServerGame.Game.Players contains all players associated with the game including those eliminated, booted, surrendered, invited, removed by host, etc)
	--for playerID in pairs(game.ServerGame.Game.PlayingPlayers) do
	for ID,player in pairs (game.ServerGame.Game.PlayingPlayers) do
		print ("==================================================================\nID="..tostring(ID));
		--printObjectDetails (player, "a", "b");
		--local targetPlayerID = player.PlayerID; --same content as pestilenceDataRecord[pestilenceTarget_playerID];
		local targetPlayerID = ID;

		print ("[PESTILENCE CHECK] for player "..targetPlayerID); --.."/"..toPlayerName(playerID), game);
		--print ("[PESTILENCE CHECK] for player "..playerID.."/"..toPlayerName(playerID), game);

		--check if current player in loop is scheduled to be impacted by Pestilence
		if (publicGameData.PestilenceData[targetPlayerID] ~= nil) then
			print ("[PESTILENCE] records exists for "..targetPlayerID); --.."/"..toPlayerName(playerID), game);
			--printObjectDetails (publicGameData.PestilenceData[targetPlayerID], "Pestilence record", "Pestilence execute");
			--get the Pestilence record for that player
			--fields are: Pestilence|playerID target|player ID caster|turn# Pestilence warning|turn# Pestilence begins|turn# Pestilence ends
			--            publicGameData.PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.playerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};
			local pestilenceDataRecord = publicGameData.PestilenceData[targetPlayerID];
			local castingPlayerID = pestilenceDataRecord.castingPlayer;
			local PestilenceWarningTurn = pestilenceDataRecord.PestilenceWarningTurn; --for now, make PestilenceWarningTurn = current turn +1 turn from now (next turn)
			local PestilenceStartTurn = pestilenceDataRecord.PestilenceStartTurn;   --for now, make PestilenceStartTurn = current turn +2 turns from now 
			local PestilenceEndTurn = pestilenceDataRecord.PestilenceEndTurn;     --for now, make PestilenceEndTurn = current turn +2 turns from now (starts and ends on same turn, only impacts a player once)
			local turnNumber = tonumber (game.Game.TurnNumber);

			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 
			--PestilenceEndTurn = turnNumber + 2; --this will make Pestilence last 3 turns!
			-- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only -- DELETE ME -- testing only 

			--print ("[PESTILENCE PENDING] on player "..tostring(targetPlayerID)..", by "..tostring(castingPlayerID)..", damage=="..Mod.Settings.PestilenceStrength .."::warningTurn=="..PestilenceWarningTurn..", startTurn==".. PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");
			print ("[PESTILENCE PENDING] on player "..targetPlayerID.."/"..toPlayerName(targetPlayerID, game)..", by "..castingPlayerID.."/"..toPlayerName(castingPlayerID, game)..", damage=="..Mod.Settings.PestilenceStrength ..", currTurn=="..turnNumber..", warningTurn=="..PestilenceWarningTurn..", startTurn=="..PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");

			--if current turn is the Pestilence start turn, make it happen
			print ("currTurn=="..turnNumber..", startTurn=="..PestilenceStartTurn..", (PestilenceStartTurn >= turnNumber)", tostring (PestilenceStartTurn >= turnNumber));
			if (turnNumber >= PestilenceStartTurn) then
				print ("[PESTILENCE EXECUTE START] on player "..targetPlayerID.."/"..toPlayerName(targetPlayerID, game)..", by "..castingPlayerID.."/"..toPlayerName(castingPlayerID, game)..", damage=="..Mod.Settings.PestilenceStrength ..", currTurn=="..turnNumber..", "..PestilenceWarningTurn..", startTurn=="..PestilenceStartTurn..", endTurn=="..PestilenceEndTurn.."::");

				--fields are Pestilence|playerID target|player ID caster|turn# Pestilence warning|turn# Pestilence begins|turn# Pestilence ends
				--publicGameData.PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.playerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};
			
				local pestilenceModifiedTerritories={}; --table of all territories being modified by the Pestilence operation

				local numTerritoriesImpacted = 0;

				--loop through territories to see if owned by current player, if so, apply Pestilence damage
				for _,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
					if (terr.OwnerPlayerID == targetPlayerID) then
						local numArmies = terr.NumArmies.NumArmies;
						local impactedTerritory = WL.TerritoryModification.Create (terr.ID);

						--reduce armies by amount of Pestilence strength
						impactedTerritory.AddArmies = (-1 * Mod.Settings.PestilenceStrength);   --current territory being modified
						numTerritoriesImpacted = numTerritoriesImpacted + 1; --don't actually need this, just use it for debugging/checking
				
						--Special Units are unaffected by Pestilence - if territory has Special Units (commander or otherwise), do not turn to neutral
						--if no Special Units are present, check if territory now has 0 armies, and if so turn it neutral
						if (#terr.NumArmies.SpecialUnits <= 0 and numArmies <= Mod.Settings.PestilenceStrength) then
							impactedTerritory.SetOwnerOpt = WL.PlayerID.Neutral;
						end

						table.insert (pestilenceModifiedTerritories, impactedTerritory); --add territory object to the table to be passed back to WZ to modify/add the order for all impacted territories
					end
				end

				local strPestilenceMsg = "Pestilence ravages " .. toPlayerName(targetPlayerID, game)..", invoked by "..toPlayerName(castingPlayerID, game);

				addOrder (WL.GameOrderEvent.Create(targetPlayerID, strPestilenceMsg, nil, pestilenceModifiedTerritories));
				print ("[PESTILENCE EVENT] "..strPestilenceMsg);
				print ("[PESTILENCE SUMMARY] #terr impacted=="..numTerritoriesImpacted..", tablelength(pestilenceModifiedTerritories)=="..tablelength(pestilenceModifiedTerritories));

				--if this is final turn of pestilence, pop the record off the table; else leave the record in to be reevalauated and applied next turn
				if (turnNumber >= PestilenceEndTurn) then
					print ("[PESTILENCE] duration complete for "..targetPlayerID.."/"..toPlayerName(targetPlayerID, game));
					publicGameData.PestilenceData [targetPlayerID] = nil;
				else
					print ("[PESTILENCE] not finished yet! more to come "..targetPlayerID.."/"..toPlayerName(targetPlayerID, game));
				end
				print ("[PESTILENCE EXECUTE END]");
			else
				print ("[PESTILENCE - not yet]");
			end
		else
			print ("[PESTILENCE - no actions pending] for player " ..targetPlayerID.."/"..toPlayerName(targetPlayerID, game));
		end
	end
	Mod.PublicGameData=publicGameData;

	printObjectDetails (Mod.PublicGameData.PestilenceData, "Pestilence data", "full publicgamedata.Pestilence");
end