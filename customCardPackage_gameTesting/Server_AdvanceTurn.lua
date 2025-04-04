require("utilities");
require("DataConverter");
local strEssentialDescription_header = '[V1.1#JAD]{"Essentials"={"UnitDescription"="';
local strEssentialDescription_footer = '";"__key"="garbage";};}[V1.1#JAD]';

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E]::func start");

	Pestilence_processEndOfTurn (game, addOrder); --check for pending Pestilence orders, execute them if they start this turn or are already ongoing
	Tornado_processEndOfTurn (game, addOrder);
	Earthquake_processEndOfTurn (game, addOrder);
    Shield_processEndOfTurn(game, addOrder);
	Monolith_processEndOfTurn (game, addOrder);
	CardBlock_processEndOfTurn (game, addOrder);
    Quicksand_processEndOfTurn(game, addOrder);
	process_Neutralize_expirations (game, addOrder); --if there are pending Neutralize orders, check if any expire this turn and if so execute those actions
	process_Isolation_expirations (game, addOrder);  --if there are pending Isolation orders, check if any expire this turn and if so execute those actions (delete the special unit to identify the Isolated territory)

	print ("[S_AT_E]::func END");

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	local intHaltOnTurnNumber = 1;
	if (boolHaltCodeExecutionAtEndofTurn==true and game.Game.TurnNumber >= intHaltOnTurnNumber) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Order(game,gameOrder,result,skip,addOrder)
	--print ("[S_AdvanceTurn_Order - func start] ::ORDER.proxyType="..gameOrder.proxyType.."::");  -- <---- only for debugging; it results in too much output, clutters the debug window
	--skip order if this order is a card play by a player impacted by Card Block

	if (execute_CardBlock_skip_affected_player_card_plays (game, gameOrder, skip, addOrder) == true) then
		print ("[ORDER] skipped due to CardBlock");
		--skip order is actually done within the function above; the true/false return value is just a signal as to whether to proceed further execution in this function (if false) or not (if true)
		return; --don't process the rest of the function, else it will still process card plays
	end

	--process game orders, separated into Immovable Special Units (don't let Isolation/Quicksand/Shield/Monolith special units move), playing Regular Cards, playing Custom Cards, AttackTransfers; in future, may need an Other section afterward for anything else?
	boolSkipOrder = false;
	process_game_orders_ImmovableSpecialUnits (game,gameOrder,result,skip,addOrder);
	if (boolSkipOrder == true) then return; end
	process_game_orders_RegularCards (game,gameOrder,result,skip,addOrder);
	process_game_orders_CustomCards (game,gameOrder,result,skip,addOrder);
	process_game_orders_AttackTransfers (game,gameOrder,result,skip,addOrder);
end

function Server_AdvanceTurn_Start(game,addOrder)
	strArrayModData = {};
	local strCardTypeBeingPlayed = "";
	local publicGameData = Mod.PublicGameData;
	local privateGameData = Mod.PrivateGameData;
	turnNumber = game.Game.TurnNumber;

	printDebug ("------------SERVER TURN ".. game.Game.TurnNumber.." ADVANCE------------");

	print ("[Server_AdvanceTurn_Start] -----------------------------------------------------------------");
	print ("[Server_AdvanceTurn_Start] START; turn#=="..turnNumber);

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
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardBlock ~= true) then return false; end --if module is not active, just return false
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

				strCardBlockSkipOrder_Message = "Skipping order to play ".. strCardName.. " card as "..toPlayerName (gameOrder.PlayerID, game).." is impacted by Card Block.";
				print ("[CARD BLOCK] - skipOrder - playerID="..gameOrder.PlayerID.. ", "..strCardBlockSkipOrder_Message);
				addOrder(WL.GameOrderEvent.Create(gameOrder.PlayerID, strCardBlockSkipOrder_Message, {}, {},{}));
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since in order with details has been added above
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
				local newNumArmies = orderArmies.Subtract(WL.Armies.Create(0, specialUnitsToRemoveFromOrder));
				local newNumArmies = WL.Armies.Create(gameOrder.NumArmies.NumArmies, {});
				print ("Immovable Specials present==true --> numArmies=="..newNumArmies.NumArmies);

				if (gameOrder.proxyType=='GameOrderAttackTransfer') then replacementOrder = WL.GameOrderAttackTransfer.Create(gameOrder.PlayerID, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, newNumArmies, gameOrder.AttackTeammates); end
				if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then replacementOrder = WL.GameOrderPlayCardAirlift.Create(gameOrder.CardInstanceID, gameOrder.PlayerID, gameOrder.FromTerritoryID, gameOrder.ToTerritoryID, newNumArmies); end
				addOrder (replacementOrder);
				skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
				print ("------------jinx---------------------------");
				boolSkipOrder = true;
				return false;
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
		
		print ("[S_AT_O] cardType=="..tostring (strCardTypeBeingPlayed).."::cardOrderContent=="..tostring(cardOrderContentDetails));
		if (strCardTypeBeingPlayed == "Nuke" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Nuke == true)) then
			execute_Nuke_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Isolation" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Isolation == true)) then
			execute_Isolation_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Pestilence" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Pestilence == true)) then
			execute_Pestilence_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Shield" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Shield == true)) then
			execute_Shield_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Monolith" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Monolith == true)) then
			execute_Monolith_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails))
		elseif (strCardTypeBeingPlayed == "Neutralize" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Neutralize == true)) then
			execute_Neutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Deneutralize" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Deneutralize == true)) then
			execute_Deneutralize_operation (game,gameOrder,result,skip,addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Airstrike" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Airstrike == true)) then
			execute_Airstrike_operation (game, gameOrder, result, skip, addOrder, cardOrderContentDetails);
		elseif (strCardTypeBeingPlayed == "Card Piece" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.CardPieces == true)) then
			execute_CardPiece_operation(game, gameOrder, skip, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Forest Fire" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.ForestFire == true)) then
			--Forest Fire details go here
		elseif (strCardTypeBeingPlayed == "Card Block" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.CardBlock == true)) then
			execute_CardBlock_play_a_CardBlock_Card_operation (game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Earthquake" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Earthquake == true)) then
			execute_Earthquake_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Tornado" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Tornado == true)) then
			execute_Tornado_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		elseif (strCardTypeBeingPlayed == "Quicksand" and (Mod.Settings.ActiveModules == nil or Mod.Settings.ActiveModules.Quicksand == true)) then
			execute_Quicksand_operation(game, gameOrder, addOrder, tonumber(cardOrderContentDetails));
		else
			--custom card play not handled by this mod; could be an error, or a card from another mod
			--do nothing
		end
	end
end

--airstrike TODOs:
--enforce FROM must be owned by order player
--if TO is no longer an enemy, it becomes a transfer (regular airlift, just replace it with an airlift? w/o need a card)
--if attack successful, elim all armies+units in FROM and then do airlift of surviving units to TO? that way we get the arrow animation
--add options for ability to target Commander, Specials, fogged territories, neutrals
--add effect for Deployment yield % -- enforced only when FROM is enemy; if FROM is neutral, then don't reduce units b/c there's no military enemy shooting back; or maybe just let it apply to neutrals too? To avoid just targeting bordering neutrals and attacking normally to avoid penalty?
--add option to enable ability to send Commander/Specials or exclude them (similar ability to target them) -- and structures? option to enable/disable targeting territories with them? like Forts ... it gets tricky (impossible) to accurately handle them
--add UI option to select which units to send to TO territory for both #armies & Specials
--handle case when a Commander is killed! how to handle? can't just elim player b/c Resurrection could be in play; maybe just remove the Commander from the game for now? enter custom order to flag Resurrection that Commander died? need to check for card?
--      or just flag airstrike as not being compatible with Commanders?
--      or just make Commander invulnerable to Airstrike? kill everything else regardless of combat order but never the Commander?
--check for Immovables inside AIRSTRIKE maneuvers! don't like Airstrike override Immovables; can this be done easily with existing code? No ... b/c it's not a normal order
--      but probably can be done reasonably easily still
--on successful attack, ensure that only the remainder of the attacking army is ever sent to TO territory
--      eg: so if 500 armies+3 specials are present and airstrike of 400 armies+2 specials is sent and 350 armies+1 special is killed, then only 50+1 special is sent to TO territory, not the entie remaining 150 armies+2 specials
--for transfers (to self or teammate), just do a normal airlift (or manual move) of the units from FROM to TO territory
--make Airstrike compatible with Quicksand/Isolation (any others?)
--when doing transfers, currently it takes owner the territory & assigns to owner player -- should this permit? makes it distinctive from Airlift, hmmm
--      problematic for Commanders ... but leave that to host/players to manage?\
--      make sender take it over unless there's an allied Commander there, in which case leave it as orig owner? or just let them settle it themselves? esp case of sending a C to territory where allied C exists already - 2 C's of diff players on same territory, lol
--      can fix by sending own C somewhere and gifting back to orig player; OR just don't send own C in this case? but then it might die b/c everything else goes and leaves the C vulnerable, hmmm
--during transfer, ensure Immovable specials are not moved
--during transfer, take care of ownership of SUs already on the target territory (else they become unmovable)
--if Commander is killed during Airstrike -- how to handle? Currently it just removes it; but ... need to trigger Resurrection/player elimination/etc
--      solution: check if Resurrection card is in play! if card exists & onwer of C has a card, then send customorder to treat as a killed Commander; else (Resurrection not used or player has no card) eliminate the player
--auto-enable Airlift if not enabled already & make it weight 0, # pieces=999, # assigned per turn 0
--make Airstrike obey Shield, Monolith, Quicksand, Isolation rules (any others?)
--max # armies that can participate in the Airstrike doesn't include deployments b/c they're not in LatestStanding; but could load the orders so far, look @ deployments and use that figure -- but it's a bit of work, a bit of a pain
--for use with Quicksand/Isolation -- they should be aborted depending on the card settings for each but even if permitted, the Airlift maneuver will get canceled (but the attack damage still happens to each territory)
--SUs should abide by "canAirlift" properties of the SU; minimally they'll get rejected during actualy Airlift operation if the properties are set to False even if they participate in the attack
function execute_Airstrike_operation (game, gameOrder, result, skipOrder, addOrder, cardOrderContentDetails)
	local modDataContent = split(gameOrder.ModData, "|");
	printDebug ("[GameOrderPlayCardCustom] modData=="..gameOrder.ModData.."::");
	--strCardTypeBeingPlayed = modDataContent[1]; --1st component of ModData up to "|" is the card name --already captured in global variable 'strCardTypeBeingPlayed' from process_game_orders_CustomCards function
	local sourceTerritoryID = modDataContent[2]; --2nd component of ModData after "|" is the source territory ID
	local targetTerritoryID = modDataContent[3]; --3rd component of ModData after "|" is the target territory ID
	local intNumArmiesSpecified = tonumber (modDataContent[4]); --4th component of ModData after "|" is the # of armies to include in the Airstrike
	local strSelectedSUsGUIDs = modDataContent[5]; --5th component of ModData after "|" is the CSV GUIDs of all SUs selected to include in Airstrike (not necessarily all SUs on the territory)
	local intActualArmies = math.min (intNumArmiesSpecified, game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies.NumArmies); --actual #armies to include in Airstrike is lesser of specified units and currently present on the territory
	--local SpecialUnitsSpecified = game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies.SpecialUnits; --make this user specifiable in future; for now use all SUs on FROM territory
	local SpecialUnitsSpecified = generateSelectedSUtable (game, strSelectedSUsGUIDs, sourceTerritoryID);
	local sourceOwner = game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].OwnerPlayerID;
	local targetOwner = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID;
	local sourceOwnerTeam = -1; --indicates no team alignment
	local targetOwnerTeam = -1; --indicates no team alignment
	local orderPlayerTeam = game.ServerGame.Game.Players[gameOrder.PlayerID].Team;
	local boolIsAttack = true; --default to attack; if TO is owned by order player or member of same team, then it's a transfer
	local intDeploymentYield = 0.75; --default to 75% yield, overwrite with mod setting if specified; this is % units that attack the TO territory; the remainder are lost in the attack

	--global variable; used to not gift 2x Airlift cards while not unnecessarily increasing # of orders; only gift card initially if player doesn't have one in hand
	--if player has one, use it, and replenish it as part of the territory adjustment; if not, assign it as a separate order, resubmit/skip Airstrike, then don't gift one during territory adjustment
	if (boolAirliftCardGiftedAlready == nil) then boolAirliftCardGiftedAlready = false; end

	if (Mod.Settings.AirstrikeDeploymentYield ~= nil) then intDeploymentYield = Mod.Settings.AirstrikeDeploymentYield/100; end --if mod setting is set, use that value instead of the default

	if (sourceOwner ~= WL.PlayerID.Neutral) then sourceOwnerTeam = game.ServerGame.Game.Players[sourceOwner].Team; end
	if (targetOwner ~= WL.PlayerID.Neutral) then targetOwnerTeam = game.ServerGame.Game.Players[targetOwner].Team; end

	if (sourceOwner ~= gameOrder.PlayerID) then
		printDebug ("[AIRSTRIKE] sourceOwner ~= orderPlayer, cancel Airstrike");
		addOrder (WL.GameOrderEvent.Create(gameOrder.PlayerID, "Airstrike from "..getTerritoryName(sourceTerritoryID, game) .." to ".. getTerritoryName(targetTerritoryID, game) .." skipped; player does not own source territory", {}, {}, {}), false);
		skipOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
		return; --don't process anything more; the order is invalid, skip it entirely
	end

		--check if the order player is attacking an enemy territory; if not, then it's a transfer
	if ((targetOwner == gameOrder.PlayerID) or (targetOwnerTeam >= 0 and targetOwnerTeam == orderPlayerTeam)) then
		boolIsAttack = false; --if TO is owned by order player or member of same team, then it's a transfer
		intDeploymentYield = 1.0; --if it's a transfer, then the yield is 100% (ie: all units are sent to TO territory)
		printDebug ("[AIRSTRIKE] treat as transfer to self or teammate; teamID=="..targetOwnerTeam);
	end

	--&&& assign these to a user-specified subselection of units on TO territory; for now just send everything present
	--local attackingArmies = game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies;
	local attackingArmies = WL.Armies.Create (intActualArmies, SpecialUnitsSpecified); --create attacking armies structure comprised of actual # of armies being sent & actual table of Specials included
	local defendingArmies = game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].NumArmies; --defending armies are straight-up what's present on TO territory
	local sourceAttackPower = attackingArmies.AttackPower;
	local targetDefensePower = defendingArmies.DefensePower;
	local intArmiesToSend = math.floor (attackingArmies.NumArmies * intDeploymentYield + 0.5); --this is the number of armies that will be sent to the target territory
	if (boolIsAttack == false) then intArmiesToSend = attackingArmies.NumArmies; end --if it's a transfer, then all armies are sent to the target territory
	local intArmiesDieDuringAttack = attackingArmies.NumArmies - intArmiesToSend; --units that die during the Airstrike (not as part of the attack)
	--actually I'm TBD whether intArmiesToSend dictates the damage done by the Airstrike, ie: only 75% (default) do damage or not
	--for now, I'm going to set it so that 100% of units do damage, but killed armies = regular counts from the attack + intArmiesDieDuringAttack
	--     ie: Airstrike does regular damage, but takes heavier casualties than a regular attack would

	printDebug ("[AIRSTRIKE]   -=-=-=-=-=-=-=-=-=-=-=-=-"..
		"\nFROM "..sourceTerritoryID.."/"..getTerritoryName (sourceTerritoryID, game)..", [ATTACKING ARMIES ACTUAL] attackPower "..sourceAttackPower..", #armies ".. attackingArmies.NumArmies.. ", #specials "..#attackingArmies.SpecialUnits..
		"\nTO "..targetTerritoryID.."/"..getTerritoryName (targetTerritoryID, game)..", defensePower "..targetDefensePower..", #armies ".. defendingArmies.NumArmies..", #specials "..#defendingArmies.SpecialUnits..
		"\nFROM SPECIFIED: #armies "..intNumArmiesSpecified.. ", #SUs "..tostring (#SpecialUnitsSpecified) .. " // FROM TERRITORY ITSELF: #armies "..game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies.NumArmies ..", #SUs "..#game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies.SpecialUnits..
		"\norderPlayer "..gameOrder.PlayerID.." [team "..orderPlayerTeam.."], sourceOwner "..sourceOwner.." [team "..sourceOwnerTeam.."], targetOwner "..targetOwner.." [team "..targetOwnerTeam.."]"..
		"\nisAttack "..tostring (boolIsAttack)..", deployment yield "..intDeploymentYield..", #armies to attack "..intArmiesToSend ..", #armies die before attack ".. intArmiesDieDuringAttack);

	--used for debugging/testing purposes
	--local strWhatToDo = "SU_prep";
	local strWhatToDo = "do_airstrike"; --not an actual action, it's just simply different from "SU_prep"
	if (strWhatToDo == "SU_prep" and game.Game.TurnNumber==1) then createSpecialUnitsForTesting (game, addOrder, sourceTerritoryID, targetTerritoryID); end --for testing purposes only

	--if set to true, use the manual move method to do the Airlift, even if Airlift card is available; this may be advisable when using Late Airlifts or Transport Only Airlift mods
	--import the value from a Mod setting, set by host in PresentConfigUI
	local boolUseManualMoveMode = false;
	--local boolUseManualMoveMode = true;

	local airliftCardID = getCardID ("Airlift", game); --get ID for card type 'Airlift'
	local airliftCardInstanceID = getCardInstanceID_fromName (gameOrder.PlayerID, "Airlift", game); --get specific card instance ID from specific player for card of type 'Airlift'
	if (boolUseManualMoveMode == true) then airliftCardID = nil; airliftCardInstanceID = nil; end --if using manual move mode, set airliftCardID & airliftCardInstanceID to nil so it doesn't try to use the Airlift card
	--if airliftCardID == nil, then Airlift Card is not enabled, so can't draw the airlift line, so must do the moves manually (original method)
	--if airliftCardID ~= nil then let Airlift do the move for successful attacks & draw a "0 unit airlift" arrow for unsuccessful attacks
	printDebug ("[AIRSTRIKE/AIRLIFT] manual move mode=="..tostring (boolUseManualMoveMode)..", airliftCardID=="..tostring (airliftCardID).."::airliftCardInstanceID=="..tostring (airliftCardInstanceID));

	--if Airlift card is in play but player has no whole Airlift cards, then add a whole Airlift card to the player + add the order, skip this Airstrike order & resubmit it to be able to use the Airlift card
	if (airliftCardID ~= nil and airliftCardInstanceID == nil) then
		local addAirLiftCardEvent = WL.GameOrderEvent.Create(gameOrder.PlayerID, "[grant Airlift card to use for Airstrike]", {}, {}, {}); --create a new event to add the Airlift card to the player
		printDebug ("[AIRLIFT CARD MISSING] add order to grant Airlift card, resubmit Airstrike order, skip current order");
		addAirLiftCardEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[airliftCardID] = game.Settings.Cards[airliftCardID].NumPieces}}; --add enough pieces to equal 1 whole card
		addOrder (addAirLiftCardEvent, false); --add the event to the game order list, ensure 'false' so this order isn't skipped when we skip the Airstrike order
		addOrder (gameOrder, false); --resubmit the Airstrike order as-is, so it can be processed once the Airlift card is added
		--skipOrder (WL.ModOrderControl.Skip); --switch to Suppress after testing
		boolAirliftCardGiftedAlready = true;
		skipOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the above message provides the details
		return;
	end

	local airstrikeResult = nil;
	if (boolIsAttack == true) then --Airstrike order is an attack
		airstrikeResult = process_manual_attack (game, attackingArmies, game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID], result);
		--airstrikeResult = process_manual_attack (game, game.ServerGame.LatestTurnStanding.Territories[sourceTerritoryID].NumArmies, game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID], result);
		--airstrikeResult.AttackerResult is armies object for attacker
		--airstrikeResult.DefenderResult is armies object for defender
		--airstrikeResult.IsSuccessful is boolean indicating if the attack was successful, and thus whether:
			--(A) attacker wins, defender units are wiped out, the attacker should move into the target territory and take ownership of it
			--(B) attacker loses, attacker units are reduced or wiped out and source territory is updated, the defender units may be reduced but remain in the target territory and retain ownership of it

		--adjust attacker results, so # of killed armies is increased by quantity of intArmiesDieDuringAttack
		airstrikeResult.AttackerResult.KilledArmies = math.min (airstrikeResult.AttackerResult.KilledArmies + intArmiesDieDuringAttack, intActualArmies); --#armies killed are those from regular battle damage + loss due to Deployment Yield but not to exceed the actual # included in the Airstrike operation (if exceeds this amount, it would subtract units from the FROM territory even if they didn't participate in the Airstrike -- don't do that)
		airstrikeResult.AttackerResult.RemainingArmies = math.max (0, attackingArmies.NumArmies - airstrikeResult.AttackerResult.KilledArmies);
	else
		--if not an attack, then it's a transfer; so just do a normal airlift of the units from the source territory to the target territory
		local AttackerResult = {RemainingArmies=intArmiesToSend, KilledArmies=0, SurvivingSpecials=attackingArmies.SpecialUnits, KilledSpecials={}, ClonedSpecials={}}; --all units survive, nothing dies, nothing clones b/c this is a transfer
		local DefenderResult = {RemainingArmies=defendingArmies.NumArmies, KilledArmies=0, SurvivingSpecials=defendingArmies.SpecialUnits, KilledSpecials={}, ClonedSpecials={}}; --all units survive, nothing dies, nothing clones b/c this is a transfer
		airstrikeResult = {AttackerResult=AttackerResult, DefenderResult=DefenderResult, IsSuccessful=true}; --transfer is always successful
		-- reference: APPLY DAMAGE  -- local damageResult = {RemainingArmies=remainingArmies, KilledArmies=math.max (0, armyCount-remainingArmies), SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecials, ClonedSpecials=clonedSpecials};
		-- reference: MANUAL ATTACK -- return ({AttackerResult=attackerResult, DefenderResult=defenderResult, IsSuccessful=boolAttackSuccessful});
	end

	local sourceTerritory = WL.TerritoryModification.Create(sourceTerritoryID);
	local targetTerritory = WL.TerritoryModification.Create(targetTerritoryID);
	local strAirStrikeResultText = "";
	local attackingArmiesToAirlift = nil; --if attack in unsuccessful, leave as nil, this indicates to send 0 armies and no specials, just draw the "0" airlift line

	if (airstrikeResult.IsSuccessful == true) then
		targetTerritory.SetOwnerOpt = gameOrder.PlayerID; --territory ownership changes to attacker, b/c attack was successful
		strAirStrikeResultText = "Airstrike successful";
		attackingArmiesToAirlift = WL.Armies.Create (airstrikeResult.AttackerResult.RemainingArmies, airstrikeResult.AttackerResult.SurvivingSpecials);
	else
		strAirStrikeResultText = "Airstrike unsuccessful";
		--leave target territory owned by defender, leave airlift army structure as nil to just draw an empty "0" airlift line
	end
	printDebug ("[AIRSTRIKE RESULT] "..strAirStrikeResultText);
	--reference: 	local damageResult = {RemainingArmies=remainingArmies, SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecials, ClonedSpecials=clonedSpecials};
	printDebug ("ATTACKER #armies "..airstrikeResult.AttackerResult.RemainingArmies .." ("..airstrikeResult.AttackerResult.KilledArmies.." died), "..
		"#specials "..#airstrikeResult.AttackerResult.SurvivingSpecials.." ("..#airstrikeResult.AttackerResult.KilledSpecials.." died, #clonedSUs "..#airstrikeResult.AttackerResult.ClonedSpecials..")");
	printDebug ("DEFENDER #armies "..airstrikeResult.DefenderResult.RemainingArmies .." ("..airstrikeResult.DefenderResult.KilledArmies.." died), "..
		"#specials "..#airstrikeResult.DefenderResult.SurvivingSpecials.." ("..#airstrikeResult.DefenderResult.KilledSpecials.." died, #clonedSUs "..#airstrikeResult.DefenderResult.ClonedSpecials..")");

	--adjust armies & SUs on TO territory, including cloned SUs which took damage
	sourceTerritory.AddArmies = -1 * airstrikeResult.AttackerResult.KilledArmies; -- reduce source territory armies by the number of killed armies
	sourceTerritory.RemoveSpecialUnitsOpt = airstrikeResult.AttackerResult.KilledSpecials; --remove killed Specials from source territory
	if (#airstrikeResult.AttackerResult.ClonedSpecials > 0) then sourceTerritory.AddSpecialUnits = airstrikeResult.AttackerResult.ClonedSpecials; end --add surviving cloned Specials to source territory; this is at max 1 SU, so no need to break it up into multiple orders

	--adjust armies & SUs on TO territory, including cloned SUs which took damage
	targetTerritory.AddArmies = -1 * airstrikeResult.DefenderResult.KilledArmies; -- reduce target territory armies by the number of killed armies; for successful attacks, this should be all armies present
	targetTerritory.RemoveSpecialUnitsOpt = airstrikeResult.DefenderResult.KilledSpecials; --remove Defender killed Specials from the target territory; for successful attacks, this should be all SUs present
	if (#airstrikeResult.DefenderResult.ClonedSpecials > 0) then targetTerritory.AddSpecialUnits = airstrikeResult.DefenderResult.ClonedSpecials; end --add surviving cloned Specials to target territory; this is at max 1 SU, so no need to break it up into multiple orders

	--prep the event; if Airlift card will be used to transfer units for successful attack, add the Airlift card pieces as part of this order
	local airstrikeEvent = WL.GameOrderEvent.Create(gameOrder.PlayerID, strAirStrikeResultText, {}, {sourceTerritory, targetTerritory});

	--if Airlift is in game, add granting of airlift whole card here; how to handle Late Airlifts & Transport Only Airlifts? or Card Block? <-- actually this would have stopped the Airstrike itself so not a concern
	--add Airlift card to player hand if it is in the game; this is done here so that the player can use it to move armies from the source territory to the target territory
	if (airliftCardID ~= nil and boolAirliftCardGiftedAlready == false) then airstrikeEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[airliftCardID] = game.Settings.Cards[airliftCardID].NumPieces}}; end --add enough pieces to equal 1 whole card

	airstrikeEvent.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	addOrder (airstrikeEvent, true);
	--this order needs to happen before the Airlift (if it is to occur) to the Airlift whole card can be guaranteed to be avaiable for game order player

	--FOR SUCCESS ATTACKS, need to move surviving units among those included in the Airstrike to target territory:
	--     if Airlift is in play, submit Airlift order, let the Airlift arrow/transfer occur normally
	--     if Airlift is NOT in play, move them manually, no Airlift line appears
	--FOR UNSUCCESSFUL ATTACKS, units on both territories are accurate as they stand
	--     if Airlift is in play, submit Airlift order to draw the empty "0" Airlift line

	--if airlift card is in play, execute the Airlift operation for both successful (units will Airlift) & unsuccessful attacks (just draw the "0" line)
	if (airliftCardID ~= nil and airliftCardInstanceID ~= nil) then
		airstrike_doAirliftOperation (game, addOrder, gameOrder.PlayerID, sourceTerritoryID, targetTerritoryID, attackingArmiesToAirlift, airliftCardInstanceID); --draw arrow from source to target territory; if armies are specified, move those armies; if nil, just move 0 armies + {} Specials
	--if Airlift is not in play, must do the move of surviving units manually
	elseif (airstrikeResult.IsSuccessful == true) then
		manual_move_units (addOrder, gameOrder.PlayerID, sourceTerritory, targetTerritory, attackingArmiesToAirlift);
	end
	boolAirliftCardGiftedAlready = false; --reset value to false for next iteration
end

--manually move units from one territory to another
function manual_move_units (addOrder, playerID, sourceTerritory, targetTerritory, units)
	--adjust armies & SUs on FROM territory
	sourceTerritory.AddArmies = -1 * units.NumArmies; --reduce source territory armies by the number of armies moving to target territory
	sourceTerritory.RemoveSpecialUnitsOpt = convert_SUobjects_to_SUguids (units.SpecialUnits); --remove Specials from source territory that are moving to target territory
	--need to convert the table to get the SU GUIDs (needed to remove from Source territory) b/c it is stored as a table of SU objects (used to add to Target territory)

	--adjust armies on TO territory
	targetTerritory.AddArmies = units.NumArmies; --increase target territory armies by the number of armies moving from source territory
	targetTerritory.RemoveSpecialUnitsOpt = {}; --reset the Specials to an empty table, so it's not constantly sending a list of SUs to remove that have already been removed

	--add SUs to TO territory in blocks of max 4 SUs at a time per WZ order (WZ limitation)
	local specialsToAdd = split_table_into_blocks (units.SpecialUnits, 4); --split the Specials into blocks of 4, so that they can be added to the target territory in multiple orders
	local territoriesToModify = {sourceTerritory, targetTerritory}; --on 1st iteration, modify source & territory, on 2nd and after just do target territory with Special Units
	if (#specialsToAdd == 0) then addOrder (WL.GameOrderEvent.Create (playerID, "[manual move]", {}, territoriesToModify), true); end --if there are no Specials to add, do the order once for both territories

	--iterate through the SU tables (up to 4 SUs per element due to WZ limitation) to add them to the target territory 4 SUs per order at a time
	for _,v in pairs (specialsToAdd) do
		targetTerritory.AddSpecialUnits = v; --add Specials to target territory that are moving from source territory
		addOrder (WL.GameOrderEvent.Create (playerID, "[manual move]", {}, territoriesToModify), true);
		targetTerritory.AddArmies = 0; --reset the armies to 0 after 1st iteration, so that the next order doesn't add more armies to the target territory
		territoriesToModify = {targetTerritory}; --on 2nd and after iterations, just modify target territory with Special Units
	end
end

--given a CSV list of SU GUIDs & a territory ID, return a table of the actual SU objects present on the territory that match the specified GUIDs
function generateSelectedSUtable (game, strSelectedSUsGUIDs, territoryID)
	local GUIDsContiguous = split (strSelectedSUsGUIDs, ","); --split CSV string containing SU GUIDs into different elements
	local GUIDs = {};
	local selectedSUs = {};

	--print ("######################");
	for k,GUID in pairs (GUIDsContiguous) do
		local GUID_upperCaseNoDashes = string.upper(GUID):gsub("-", "")
		printDebug ("GUID orig "..GUID..", uppercase+nodashes: ".. GUID_upperCaseNoDashes);
		GUIDs[GUID_upperCaseNoDashes]=true;
	end --create array where elements are the GUIDs themselves
	printDebug (tablelength (GUIDs) .." GUIDs specified");

	for k,SP in pairs (game.ServerGame.LatestTurnStanding.Territories[territoryID].NumArmies.SpecialUnits) do
		local GUID_upperCaseNoDashes = string.upper(SP.ID):gsub("-", "")
		if (GUIDs [GUID_upperCaseNoDashes] ~= nil) then table.insert (selectedSUs, SP); end
		printDebug ("SP.ID orig "..tostring (SP.ID)..", SP.ID "..GUID_upperCaseNoDashes..", GUIDs [SP.ID] "..tostring (GUID_upperCaseNoDashes)..", count "..#selectedSUs);
	end
	printDebug (#selectedSUs .." SUs matched");
	return (selectedSUs);
end

--given a table of SU objects, return a table containing their GUIDs
--this is used to remove Specials from the source territory (which is done by SU GUIDs) and add them to the target territory (which is done using SU objects)
function convert_SUobjects_to_SUguids (SUobjects)
	local SUguids = {};
	for _,v in pairs (SUobjects) do table.insert (SUguids, v.ID); end
	return (SUguids);
end

function split_table_into_blocks (data, blockSize)
	local blocks = {};
	for i = 1, #data, blockSize do
		local block = {};
		for j = i, math.min(i + blockSize - 1, #data) do
			table.insert(block, data[j]);
		end
		table.insert(blocks, block);
	end
	return blocks;
end

--create special units for testing purposes
--NOTE: this is a test function, not used in the mod for normal games; it was/is used to test the special unit creation and combat order processing
function createSpecialUnitsForTesting (game, addOrder, sourceTerritoryID, targetTerritoryID)
	--filenames: monolith special unit_clearback.png, quicksand_v3_specialunit.png, shield_special unit_clearback.png, neutralizedTerritory.png, isolatedTerritory.png
	--for reference: function build_specialUnit (game, addOrder, targetTerritoryID, Name, ImageFilename, AttackPower, DefensePower, AttackPowerPercentage, DefensePowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, Health, CombatOrder, CanBeGiftedWithGiftCard, CanBeTransferredToTeammate, CanBeAirliftedToSelf, CanBeAirliftedToTeammate, IsVisibleToAllPlayers, ModData)
	build_specialUnit (game, addOrder, sourceTerritoryID, "1a pre 10 health", "shield_special unit_clearback.png",    10, 10, 1.0, 1.0, 0, 0, 100, -4000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, sourceTerritoryID, "2a pre 0h 10kill", "shield_special unit_clearback.png",    10, 10, nil, nil, 0, 10, 0, -5000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, sourceTerritoryID, "3a with 0h 10kill", "quicksand_v3_specialunit.png",        10, 10, 1.0, 1.0, 0, 10, 0, 0000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, sourceTerritoryID, "4a with 10 health", "quicksand_v3_specialunit.png",        10, 10, nil, nil, 0, 0, 100, 0000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, sourceTerritoryID, "5a 10 health", "monolith special unit_clearback.png",      10, 10, nil, nil, 0, 0, 100, 15000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, sourceTerritoryID, "6a 0h 10kill", "monolith special unit_clearback.png",      10, 10, nil, nil, 0, 10, 0, 4000, true, true, true, true, true, nil);

	--filenames: monolith special unit_clearback.png, quicksand_v3_specialunit.png, shield_special unit_clearback.png, neutralizedTerritory.png, isolatedTerritory.png
	build_specialUnit (game, addOrder, targetTerritoryID, "1b pre 0h 10kill", "shield_special unit_clearback.png",    0, 0, nil, nil, 5, 10, 0, -5000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, targetTerritoryID, "2b pre 10 health", "shield_special unit_clearback.png",    0, 0, 1.0, 1.0, 5, 0, 10, -4000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, targetTerritoryID, "3b with 0h 10kill", "quicksand_v3_specialunit.png",        0, 0, 1.0, 1.0, 5, 10, 0, 0000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, targetTerritoryID, "4b with 10 health", "quicksand_v3_specialunit.png",        0, 0, nil, nil, 5, 0, 10, 0000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, targetTerritoryID, "5b post 0h 10kill", "monolith special unit_clearback.png", 0, 0, 1.0, 1.0, 5, 10, 0, 4000, true, true, true, true, true, nil);
	build_specialUnit (game, addOrder, targetTerritoryID, "6b post 10 health", "monolith special unit_clearback.png", 0, 0, 1.0, 1.0, 5, 0, 10, 15000, true, true, true, true, true, nil);
end

--add Airlift whole card to a player, to be consumed to make the airlift operation to show the airlift arrow
function airstrike_doAirliftOperation_EDIT_JUST_TO_ADD_THE_WHOLE_CARD (game, order, PlayerID)
	--add Airlift 1 whole card to the player, to be consumed to make the airlift operation to show the airlift arrow
	local airliftCardID = getCardID ("Airlift", game); --get ID for card type 'Airlift'
	local targetCardConfigNumPieces = game.Settings.Cards[airliftCardID].NumPieces; --add enough pieces to equal 1 whole card
	local event = WL.GameOrderEvent.Create (PlayerID, "airlift arrow +piece +use it", {});
	local actualNumArmies = WL.Armies.Create (0, {}); --create empty armies object
	if (numArmies ~= nil) then actualNumArmies = numArmies; end --use parameter if it was specified
	event.AddCardPiecesOpt = {[PlayerID] = {[airliftCardID] = targetCardConfigNumPieces}};
	addOrder(event, true); --add the card pieces to the player; need to save this to update that player's card counts so can be sure there is an Airlift card available to use

	--consume 1 whole card Airlift card; we know this player has at least 1 Airlift card b/c we just added it above
	local airliftCardInstanceID = getCardInstanceID_fromName (PlayerID, "Airlift", game); --get specific card instance ID from specific player for card of type 'Airlift'
	print ("[AIRLIFT] airliftCardInstance="..tostring(airliftCardInstanceID));
	addOrder (WL.GameOrderPlayCardAirlift.Create (airliftCardInstanceID, PlayerID, sourceTerritoryID, targetTerritoryID, actualNumArmies), true); --draw arrow from source to target territory
end

--draw arrow from source to target territory; if armies are specified, move those armies; if nil, just move 0 armies + {} Specials
function airstrike_doAirliftOperation (game, addOrder, PlayerID, sourceTerritoryID, targetTerritoryID, numArmies, airliftCardInstanceID)
	--[[--add Airlift 1 whole card to the player, to be consumed to make the airlift operation to show the airlift arrow
	local airliftCardID = getCardID ("Airlift", game); --get ID for card type 'Airlift'
	local targetCardConfigNumPieces = game.Settings.Cards[airliftCardID].NumPieces; --add enough pieces to equal 1 whole card
	local event = WL.GameOrderEvent.Create (PlayerID, "airlift arrow +piece +use it", {});
	event.AddCardPiecesOpt = {[PlayerID] = {[airliftCardID] = targetCardConfigNumPieces}};
	addOrder(event, true);]] --add the card pieces to the player; need to save this to update that player's card counts so can be sure there is an Airlift card available to use

	--consume 1 whole card Airlift card; we know this player has at least 1 Airlift card b/c we just added it above
	print ("[AIRLIFT] airliftCardInstance="..tostring(airliftCardInstanceID));
	local actualNumArmies = WL.Armies.Create (0, {}); --create empty armies object
	if (numArmies ~= nil) then actualNumArmies = numArmies; end --use parameter if it was specified
	addOrder (WL.GameOrderPlayCardAirlift.Create (airliftCardInstanceID, PlayerID, sourceTerritoryID, targetTerritoryID, actualNumArmies), true); --draw arrow from source to target territory
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
	if (Health ~= nil) then builder.Health = Health; else builder.Health = 0; end
	if (CombatOrder ~= nil) then builder.CombatOrder = CombatOrder; else builder.CombatOrder = 0; end
	if (CanBeGiftedWithGiftCard ~= nil) then builder.CanBeGiftedWithGiftCard = CanBeGiftedWithGiftCard; else builder.CanBeGiftedWithGiftCard = false; end
	if (CanBeTransferredToTeammate ~= nil) then builder.CanBeTransferredToTeammate = CanBeTransferredToTeammate; else builder.CanBeTransferredToTeammate = false; end
	if (CanBeAirliftedToSelf ~= nil) then builder.CanBeAirliftedToSelf = CanBeAirliftedToSelf; else builder.CanBeAirliftedToSelf = false; end
	if (CanBeAirliftedToTeammate ~= nil) then builder.CanBeAirliftedToTeammate = CanBeAirliftedToTeammate; else builder.CanBeAirliftedToTeammate = false; end
	if (IsVisibleToAllPlayers ~= nil) then builder.IsVisibleToAllPlayers = IsVisibleToAllPlayers; else builder.IsVisibleToAllPlayers = false; end
	if (ModData ~= nil) then builder.ModData = ModData; else builder.ModData = ""; end

	local specialUnit = builder.Build();
	local terrMod = WL.TerritoryModification.Create(targetTerritoryID)
	terrMod.AddSpecialUnits = {specialUnit}
	addOrder(WL.GameOrderEvent.Create(game.ServerGame.LatestTurnStanding.Territories[targetTerritoryID].OwnerPlayerID, Name.." special unit created", {}, {terrMod}), false);
	return specialUnit;
end

--process a manual attack sequence from AttackOrder [type NumArmies] on DefendingTerritory [type Territory] with respect to Specials & armies
--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
--also treat Specials properly with respect to their specs, notably damage required to kill, health, attack/damage properties, etc
--return value is the result with updated AttackingArmiesKilled & DefendingArmiesKilled values
--also need some way of indicating overall success separately b/c can't change some properties of the result object directly
function process_manual_attack (game, AttackingArmies, DefendingTerritory, result)
	--note armies have combat order of 0, Commanders 10,000, need to get the combat order of Specials from their properties
	local DefendingArmies = DefendingTerritory.NumArmies;

	local sortedAttackerSpecialUnits = {};
	local sortedDefenderSpecialUnits = {};
	local totalDefenderDefensePowerPercentage = 1.0;    --this is covered in defense power for an SU so don't actually need this
	--local totalAttackerDefensePowerPercentage = 1.0;  --this is covered in defense power for an SU so don't need this
	local totalAttackerAttackPowerPercentage = 1.0;     --this is covered in defense power for an SU so don't actually need this
	--local totalDefenderAttackPowerPercentage = 1.0;   --this is covered in attack power for an SU so don't actually need this

	printDebug ("[MANUAL ATTACK!] ATTACKER: #armies "..AttackingArmies.NumArmies..", #SUs "..#AttackingArmies.SpecialUnits..", AttackingArmiesPower "..AttackingArmies.AttackPower..
		"\nDEFENDER: #armies "..DefendingTerritory.NumArmies.NumArmies..", #SUs "..#DefendingTerritory.NumArmies.SpecialUnits..", DefendingTerritoryPower "..DefendingTerritory.NumArmies.DefensePower);

	--this doesn't work; the AttackingArmies.SpecialUnits table is likely not totally compliant; it needs to be a sequential array table, not a key-value table
	--table.sort(sortedAttackingArmies.SpecialUnits, function(a, b) printDebug ("COMPARE "..a.CombatOrder..", ".. b.CombatOrder..", "..tostring(a.CombatOrder < b.CombatOrder)); return (a.CombatOrder < b.CombatOrder); end);

	--instead, rebuild AttackingArmies.SpecialUnits into a new sequential array & sort this new table by ascending CombatOrder and process that instead
	for _, unit in pairs(AttackingArmies.SpecialUnits) do
		table.insert(sortedAttackerSpecialUnits, unit);
		-- if (unit.proxyType == "CustomSpecialUnit") then
			--if (unit.AttackPowerPercentage ~= nil) then totalAttackerAttackPowerPercentage = totalAttackerAttackPowerPercentage * unit.AttackPowerPercentage; end
			--if (unit.DefensePowerPercentage ~= nil) then totalAttackerDefensePowerPercentage = totalAttackerDefensePowerPercentage * unit.DefensePowerPercentage; end
			--do some math here; remember <0.0 is not possible, 0.0-1.0 is actually -100%-0%, 1.0-2.0 is 0%-100%, etc
				--printDebug ("SPECIAL ATTACKER "..unit.Name..", APower% "..unit.AttackPowerPercentage..", DPower% "..unit.DefensePowerPercentage..", DmgAbsorb "..unit.DamageAbsorbedWhenAttacked..", DmgToKill "..unit.DamageToKill..", Health "..unit.Health);
		-- end
	end
	table.sort(sortedAttackerSpecialUnits, function(a, b) return a.CombatOrder < b.CombatOrder; end)

	--instead, rebuild DefendingArmies.SpecialUnits into a new sequential array & sort this new table by ascending CombatOrder and process that instead
	for _, unit in pairs(DefendingArmies.SpecialUnits) do
		table.insert(sortedDefenderSpecialUnits, unit);
		-- if (unit.proxyType == "CustomSpecialUnit") then
			--if (unit.AttackPowerPercentage ~= nil) then printDebug ("APP "..unit.Name,totalDefenderAttackPowerPercentage,unit.AttackPowerPercentage); totalDefenderAttackPowerPercentage = totalDefenderAttackPowerPercentage * unit.AttackPowerPercentage; end
			--if (unit.DefensePowerPercentage ~= nil) then printDebug ("DPP "..unit.Name,totalDefenderDefensePowerPercentage,unit.DefensePowerPercentage); totalDefenderDefensePowerPercentage = totalDefenderDefensePowerPercentage * unit.DefensePowerPercentage; end
			--do some math here; remember <0.0 is not possible, 0.0-1.0 is actually -100%-0%, 1.0-2.0 is 0%-100%, etc
			--printDebug ("SPECIAL DEFENDER "..unit.Name..", APower% "..unit.AttackPowerPercentage..", DPower% "..unit.DefensePowerPercentage..", DmgAbsorb "..unit.DamageAbsorbedWhenAttacked..", DmgToKill "..unit.DamageToKill..", Health "..unit.Health);
		-- end
	end
	table.sort(sortedDefenderSpecialUnits, function(a, b) return a.CombatOrder < b.CombatOrder; end)

	local AttackPower = AttackingArmies.AttackPower;
	printDebug ("=========================="..AttackingArmies.AttackPower);
	local DefensePower = DefendingTerritory.NumArmies.DefensePower;
	local AttackDamage = math.floor (AttackPower * game.Settings.OffenseKillRate * totalAttackerAttackPowerPercentage + 0.5);
	local DefenseDamage = math.floor (DefensePower * game.Settings.DefenseKillRate * totalDefenderDefensePowerPercentage + 0.5);
	--local remainingAttackDamage = AttackDamage; --apply attack damage to defending units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied
	--local remainingDefenseDamage = DefenseDamage; --apply defense damage to attacking units in order of their combat order, reduce this value as damage is applied and continue through the stack until all damage is applied

	--aply damage to Specials & armies of each Defender & Attacker; 

	--process Defender damage 1st; if both players are eliminated by this order & they are the last 2 active players in the game, then Defender is eliminated 1st, Attacker wins
	-- print ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	printDebug ("[DEFENDER TAKES DAMAGE] "..AttackDamage..", AttackPower "..AttackPower..", AttackerAttackPower% ".. totalAttackerAttackPowerPercentage..", Off kill rate "..game.Settings.OffenseKillRate.." _________________");
	local defenderResult = apply_damage_to_specials_and_armies (sortedDefenderSpecialUnits, DefendingArmies.NumArmies, AttackDamage);
	-- print ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	printDebug ("[ATTACKER TAKES DAMAGE] "..DefenseDamage..", DefensePower "..DefensePower..", DefenderDefensePower% ".. totalDefenderDefensePowerPercentage..", Def kill rate "..game.Settings.DefenseKillRate.." _________________");
	local attackerResult = apply_damage_to_specials_and_armies (sortedAttackerSpecialUnits, AttackingArmies.NumArmies, DefenseDamage);
	local boolAttackSuccessful = false; --indicates whether attacker is successful and should move units to target territory and take ownership of it
	-- print ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned]");
	printDebug ("[DEFENDER RESULT] #armies "..defenderResult.RemainingArmies .." ["..defenderResult.KilledArmies.. " died], #specials "..#defenderResult.SurvivingSpecials.." ["..#defenderResult.KilledSpecials.. " died, ".. #defenderResult.ClonedSpecials .." cloned]");
	-- print ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned]");
	printDebug ("[ATTACKER RESULT] #armies "..attackerResult.RemainingArmies .." ["..attackerResult.KilledArmies.. " died], #specials "..#attackerResult.SurvivingSpecials.." ["..#attackerResult.KilledSpecials.. " died, ".. #attackerResult.ClonedSpecials .." cloned]");
	if (defenderResult.RemainingArmies == 0 and #defenderResult.SurvivingSpecials == 0) then
		--defender is eliminated, attacker wins
		boolAttackSuccessful = true;
		printDebug ("[ATTACK SUCCESSFUL] attacker wins, defender is wiped out from target territory");
	else
		--defender survives, attacker may have lost some units
		printDebug ("[ATTACK UNSUCCESSFUL] attacker unsuccessful, defender survives in target territory");
	end
	return ({AttackerResult=attackerResult, DefenderResult=defenderResult, IsSuccessful=boolAttackSuccessful});
end

--process damage quantity 'totalDamage' to the Specials in table 'sortedSpecialUnits' and the armies in 'armyCount'
--Specials are already stored in table in order of their CombatOrder
--the combo of (sortedSpecialUnits+armyCount) is either the Attacker and totalDamage is damage from defender units, or the combo is the Defender and totalDamage is damage from attacker units
--this function will be called once for each case, once for the Attacker and once for the Defender
function apply_damage_to_specials_and_armies (sortedSpecialUnits, armyCount, totalDamage)
	local remainingDamage = totalDamage;
	local boolArmiesProcessed = false;
	local remainingArmies = armyCount;
	local survivingSpecials = {};
	local killedSpecials = {};
	local clonedSpecials = {};

	table.insert (sortedSpecialUnits, {CombatOrder=1, proxyType="|dummyPlaceholder|applyDamageToArmies"}); --add a dummy element to the end of the table to ensure armies are processed if they haven't been processed so far (if all specials have CombatOrder<0)

	--process Specials with combat orders below armies first, then process the armies, then process the remaining Specials
	printDebug ("_____________________APPLY DAMAGE "..totalDamage..", #armies "..armyCount..", #specials "..#sortedSpecialUnits);
	for k,v in ipairs (sortedSpecialUnits) do
		local newSpecialUnit_clone = nil;
		--Properties Exist for Commander: ID, guid, proxyType, CombatOrder <--- and that's it!
		--Properties DNE for Commander: AttackPower, AttackPowerPercentage, DamageAbsorbedWhenAttacked, DamageToKill, DefensePower, DefensePowerPercentage, Health
		printDebug ("[[[[SPECIAL]]]] "..k..", type "..v.proxyType.. ", combat order "..v.CombatOrder..", remaining damage "..remainingDamage);
		local boolCurrentSpecialSurvives = true;

		if (v.proxyType == "CustomSpecialUnit") then
			printDebug ("CUSTOM SPECIAL name '"..v.Name.."', ModID "..v.ModID..", combat order "..v.CombatOrder..", health "..tostring(v.Health)..", attack "..tostring(v.AttackPower)..", damage "..tostring(v.DefensePower)..", SPECIAL APower% "..tostring(v.AttackPowerPercentage)..
			", DPower% "..tostring(v.DefensePowerPercentage)..", SPECIAL DmgAbsorb "..tostring(v.DamageAbsorbedWhenAttacked)..", DmgToKill "..tostring(v.DamageToKill)..", Health "..tostring(v.Health)..", remaining damage "..remainingDamage);
		elseif (v.proxyType == "|dummyPlaceholder|applyDamageToArmies") then
			printDebug ("DUMMY PLACEHOLDER for armies, remaining damage "..remainingDamage..", armies damage processed already? "..tostring(boolArmiesProcessed));
			boolCurrentSpecialSurvives = false; --don't add this to the survivingSpecials table
			--don't do anything other than let the loop continue 1 last iteration to apply damage to the armies
			--this item has CombatOrder==0 but it is placed last into the table just to ensure that at least 1 element has >0 CombatOrder so that the loop will process damage on the armies if there is remainingDamage left
		end

		--if there's no more damage to apply, skip the code to apply any further damage; could also use 'break' to exit the loop		
		--first check if CombatOrder indicates that it's time to apply damage to armies, then apply damage to Specials thereafter if damage is remaining
		--1 iteration through loop can apply damage to both armies and then 1 Special (the current Special being iterated on in the loop representing the current element of the table being looped through)
		if (remainingDamage >0) then
			if (boolArmiesProcessed==false and v.CombatOrder >0) then --if armies haven't had damage applied yet and this Special has combat order of >0 then apply damage to armies
				--apply damage to armies
				if (remainingArmies == 0) then
					printDebug ("[[[[ARMY DAMAGE]]]] no remaining armies present, remaining damage "..remainingDamage);
				elseif (remainingDamage >= remainingArmies) then
					remainingDamage = math.max (0, remainingDamage - remainingArmies);
					remainingArmies = 0;
					printDebug ("[[[[ARMY DAMAGE]]]] all armies die, remaining damage "..remainingDamage);
				else
					--apply damage to armies of amount remainingDamage
					printDebug ("[[[[ARMY DAMAGE]]]] "..remainingDamage.." armies die, remaining armies "..remainingArmies-remainingDamage..", remaining damage 0");
					remainingArmies = math.max (0, remainingArmies - remainingDamage);
					remainingDamage = 0;
				end
				boolArmiesProcessed = true;
			end

			--damage to armies may have occurred already depending on CombatOrder value of current special, and this may have depleted all remaining damage
			--if there's still damage to apply, apply it to this Special
			if (remainingDamage > 0) then
				printDebug ("apply damage to Special");
				if (v.proxyType=="Commander") then
					if (remainingDamage >=7) then
						printDebug ("COMMANDER dies");
						remainingDamage = math.max (0, remainingDamage - 7);
						boolCurrentSpecialSurvives = false; --remove commander (don't stop processing; it might not be this player's commander, game needs to continue to cover all cases)
					else
						printDebug ("COMMANDER survives, not enough damage done");
						remainingDamage = 0; --commander survives, no more attacks to occur
						boolCurrentSpecialSurvives = true; --add commander to survivingSpecials table
					end
				elseif (v.proxyType=="CustomSpecialUnit") then
					--absorb damage only applies to SUs that don't use Health; if they use Health, DamageAbsorbedWhenAttacked is ignored during regular WZ attacks; mimic that functionality here (even if both DamageAbsorbedWhenAttacked & Health are specified on an SU)
					--SUs use either (A) Health or (B) DamageToKill + DamageAbsorbedWhenAttacked; if Health is specified, the other 2 properties are ignored
					if (v.DamageAbsorbedWhenAttacked ~= nil and v.Health == nil) then remainingDamage = math.max (0, remainingDamage - v.DamageAbsorbedWhenAttacked); printDebug ("absorb damage "..v.DamageAbsorbedWhenAttacked..", remaining dmg "..remainingDamage); end
					if (v.Health ~= nil) then --SU uses Health (not DamageToKill + DamageAbsorbedWhenAttacked)
						if (v.Health == 0) then
							printDebug ("SPECIAL already dead w/0 health, kill it/remove it");
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table
						elseif (remainingDamage >= v.Health) then
							remainingDamage = remainingDamage - v.Health;
							printDebug ("SPECIAL dies, health "..v.Health.. ", remaining damage "..remainingDamage);
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table
						else
							--apply damage to special of amount remainingDamage
							printDebug ("SPECIAL survives but health reduced by "..remainingDamage.." to "..v.Health-remainingDamage .. "[clone/remove old/add new]");
							--recreate the special with new health level
							local newSpecialUnitBuilder = WL.CustomSpecialUnitBuilder.CreateCopy(v);
							newSpecialUnitBuilder.Health = v.Health - remainingDamage;
							newSpecialUnitBuilder.Name = newSpecialUnitBuilder.Name .."(C)";
							newSpecialUnit_clone = newSpecialUnitBuilder.Build();
							boolCurrentSpecialSurvives = true; --add cloned special to survivingSpecials table
							remainingDamage = 0;
						end
					else   --SU uses DamageToKill + DamageAbsorbedWhenAttacked (not Health)
						if (remainingDamage > v.DamageToKill) then
							remainingDamage = math.max (0, remainingDamage - v.DamageToKill);
							printDebug ("SPECIAL dies, damage to kill "..v.DamageToKill..", remaining damage "..remainingDamage);
							boolCurrentSpecialSurvives = false; --remove special from survivingSpecials table
							--printDebug ("boolCurrentSpecialSurvives "..tostring(boolCurrentSpecialSurvives));
						else
							--apply damage to special of amount remainingDamage
							printDebug ("SPECIAL survives b/c remaining damage "..remainingDamage.." < DamageToKill "..v.DamageToKill.."; remaining damage 0");
							boolCurrentSpecialSurvives = true; --add special to survivingSpecials table
							remainingDamage = 0;
						end
					end
				end
			end
		end
		if (remainingDamage<=0) then printDebug ("[damage remaining is "..remainingDamage.."]"); end

		--the Special being analyzed this iteration through loop has already DIED or SURVIVED by this opint, add to survivingSpecials table if it survived
		--printDebug ("boolCurrentSpecialSurvives "..tostring(boolCurrentSpecialSurvives));
		if (boolCurrentSpecialSurvives == true) then --the Special survived; but it may have (A) taken no damage, in which case just add it to the survivingSpecials table, or (B) taken damage (if so it has been cloned and need to replace it with the new cloned Special and add that to the table)
			printDebug ("SPECIAL survived");
			if (newSpecialUnit_clone == nil) then --the Special Unit survived the didn't need to be cloned, just add the original to the survivingSpecials table
				table.insert (survivingSpecials, v);
			else   --the Special Unit survived but needed to be cloned, add the new cloned Special to the survivingSpecials table & add the original to the killedSpecials table (this isn't totally accurate since it wasn't killed per se, 
			       --but this mechanism is used to remove it from the source territory & not add it to the target territory if the attack if successful)
				table.insert (survivingSpecials, newSpecialUnit_clone); --add the new cloned Special to the survivingSpecials table; SUs in this table will be added to the target territory if attack is successful
				table.insert (killedSpecials, v.ID); --add the original Special to the killedSpecials table
				table.insert (clonedSpecials, newSpecialUnit_clone); --add the new cloned Special to the clonedSpecials table; if airstrike is unsuccessful, attacking SUs in this table need to be added to the source territory & defending SUs in this table need to be added to the target territory
				--newSpecialUnit_clone = nil; --reset the clone to nil for next iteration through the loop --> actually don't need to b/c moved the declaration inside the loop
			end
		else
			printDebug ("SPECIAL died");
			if (v.proxyType ~= "|dummyPlaceholder|applyDamageToArmies") then table.insert (killedSpecials, v.ID); end --only add the Special to the killedSpecials table if it dies, ignore the dummy placeholder
		end
	end

	printDebug ("[FINAL RESULT] remaining damage "..remainingDamage..", killed armies " .. math.max (0, armyCount-remainingArmies) ..", remaining armies "..remainingArmies.. ", #killedSpecials ".. #killedSpecials ..", #survivingSpecials "..#survivingSpecials);
	local damageResult = {RemainingArmies=remainingArmies, KilledArmies=math.max (0, armyCount-remainingArmies), SurvivingSpecials=survivingSpecials, KilledSpecials=killedSpecials, ClonedSpecials=clonedSpecials};
	return damageResult;

	--reference
	--[[local impactedTerritory = WL.TerritoryModification.Create(terrID);
	local modifiedTerritories = {};
	impactedTerritory.RemoveSpecialUnitsOpt = {shieldDataRecord.specialUnitID};
	table.insert(modifiedTerritories, impactedTerritory);]]

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

function process_game_orders_AttackTransfers (game,gameOrder,result,skip,addOrder)
	--check ATTACK/TRANSFER orders to see if any rules are broken and need intervention, eg: moving TO/FROM an Isolated territory or OUT of Quicksanded territory
	if (gameOrder.proxyType=='GameOrderAttackTransfer') then
		print ("[[  ATTACK // TRANSFER ]] PRE  player "..gameOrder.PlayerID..", FROM "..gameOrder.From.."/"..getTerritoryName (gameOrder.From, game)..", TO "..gameOrder.To.."/"..getTerritoryName (gameOrder.To, game) ..
			", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", ByPercent "..tostring (gameOrder.ByPercent)..", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", #SUs attacking "..#gameOrder.NumArmies.SpecialUnits..", Actual #SUs attacking "..#result.ActualArmies.SpecialUnits..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies..
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
			--weed out the cases above, then what's left are moves to or from territories impacted by Quicksand
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
					print ("[QUICKSAND] ATTACK/TRANSFER INTO QUICKSAND _ _ _ _ _ _ _ _ _ _ _ _ ");
					print ("[QUICKSAND] PRE  attack/transfer into Quicksand! AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmesKilled=="..result.DefendingArmiesKilled.NumArmies..", IsSuccessful=="..tostring(result.IsSuccessful).."::");
					print ("[QUICKSAND] AttackerDamageTakenModifier=="..Mod.Settings.QuicksandAttackerDamageTakenModifier..", AttackerDamageTakenModifier=="..Mod.Settings.QuicksandDefenderDamageTakenModifier.."::");
					print ("[QUICKSAND] AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
					print ("[QUICKSAND] result.DamageToSpecialUnits==nil --> ".. tostring (result.DamageToSpecialUnits==nil)..", size=="..tostring(#result.DamageToSpecialUnits)..", type==".. type(result.DamageToSpecialUnits).."::");
					if (result.DamageToSpecialUnits==nil) then print ("[QUICKSAND] PRE nil: 0 damage to specials"); end
					if (result.DamageToSpecialUnits=={}) then print ("[QUICKSAND] PRE  {}: 0 damage to specials"); end
					if (#result.DamageToSpecialUnits==0) then print ("[QUICKSAND] PRE  #==0 : 0 damage to specials"); end
					print ("[QUICKSAND] PRE killed defending specials; size== "..#result.DefendingArmiesKilled.SpecialUnits.."::");
					for k,v in pairs (result.DefendingArmiesKilled.SpecialUnits) do
						if (v.proxyType == "CustomSpecialUnit") then print ("[QUICKSAND] PRE killed defending specials "..k..","..v.Name.."/"..v.ID.."::");
						else print ("[QUICKSAND] PRE killed defending specials "..k..","..v.proxyType.."/".. v.ID.."::");
						end
					end
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
							--if print ("....special ",k,v.Name,v.ID);
							--table.insert (result.DamageToSpecialUnits, {k, intAdditionalDamageToSpecials});
							--table.insert (result.DefendingArmiesKilled.SpecialUnits, v.ID);
							print ("....#size=="..#result.DamageToSpecialUnits.."::");
							if (v.proxyType == "CustomSpecialUnit" and v.Name == "Quicksand") then print ("----removed Quicksand special"); table.insert (newDefendingSpecialsKilled, v); end
						end
					end

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
			", numArmies "..gameOrder.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", ByPercent "..tostring (gameOrder.ByPercent)..", isAttack "..tostring(result.IsAttack)..", isSuccessful "..tostring(result.IsSuccessful)..
			", AttackingArmiesKilled=="..result.AttackingArmiesKilled.NumArmies..", DefendingArmiesKilled=="..result.DefendingArmiesKilled.NumArmies..
			", AttackingSpecialsKilled=="..#result.AttackingArmiesKilled.SpecialUnits..", DefendingSpecialsKilled=="..#result.DefendingArmiesKilled.SpecialUnits.."::");
			--[[for k,v in pairs (result.DamageToSpecialUnits) do print ("[QUICKSAND] POST damage to special "..k..", amount "..v.."::"); end
			print ("[QUICKSAND] result.DamageToSpecialUnits==nil --> ".. tostring (result.DamageToSpecialUnits==nil)..", size=="..tostring(#result.DamageToSpecialUnits)..", type==".. type(result.DamageToSpecialUnits).."::");
			if (result.DamageToSpecialUnits==nil) then print ("[QUICKSAND] POST nil: 0 damage to specials"); end
			if (result.DamageToSpecialUnits=={}) then print ("[QUICKSAND] POST  {}: 0 damage to specials"); end
			if (#result.DamageToSpecialUnits==0) then print ("[QUICKSAND] POST  #==0 : 0 damage to specials"); end
			print ("[QUICKSAND] POST damage to special "); 
			for k,v in pairs (result.DamageToSpecialUnits) do print ("[QUICKSAND] POST damage to special "..k..", amount "..v.."::"); end
			print ("[QUICKSAND] POST __fin__");]]
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
    event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	--[[WL.RectangleVM.Create(
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY,
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY);]]
	--event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Tornado", 10, 0)};
	--addAirLiftCardEvent.AddCardPiecesOpt = {[gameOrder.PlayerID] = {[airliftCardID] = game.Settings.Cards[airliftCardID].NumPieces}}; --add enough pieces to equal 1 whole card
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
    builder.Name = 'Quicksand impacted territory';
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
	local strUnitDescription = tostring (Mod.Settings.QuicksandDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.QuicksandDuration.."]";
	builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = strUnitDescription}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
	--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]';
	--builder.ModData = strEssentialDescription_header ..strUnitDescription.. strEssentialDescription_footer;
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
    event.JumpToActionSpotOpt = createJumpToLocationObject (game, targetTerritoryID);
	--[[WL.RectangleVM.Create(
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY,
         game.Map.Territories[targetTerritoryID].MiddlePointX,
         game.Map.Territories[targetTerritoryID].MiddlePointY);]]
	--event.TerritoryAnnotationsOpt = {[targetTerritoryID] = WL.TerritoryAnnotation.Create ("Quicksand", 10, 10)};
	addOrder(event, true);
    local publicGameData = Mod.PublicGameData;
    if (publicGameData.QuicksandData == nil) then publicGameData.QuicksandData = {}; end
    local turnNumber_QuicksandExpires = (Mod.Settings.QuicksandDuration > 0) and (game.Game.TurnNumber + Mod.Settings.QuicksandDuration) or -1;
    publicGameData.QuicksandData[targetTerritoryID] = {territory = targetTerritoryID, castingPlayer = gameOrder.PlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds = turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};
    Mod.PublicGameData = publicGameData;
end

function createUnitDescriptionCode (strDescription)
	return (DataConverter.DataToString({Essentials = {UnitDescription = strDescription}}, Mod)); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
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
	builder.AttackPowerPercentage = 0;
	builder.DefensePower = 0;
	builder.DefensePowerPercentage = 0;
    builder.DamageToKill = 9999999;
    builder.DamageAbsorbedWhenAttacked = 9999999;
    builder.CombatOrder = -99999; --before armies (which are 0); make this is a significantly low # (high negative #) to reasonably be the first unit in combat order (lowest #) on a territory to protect all units
    --builder.CanBeGiftedWithGiftCard = false;
	builder.CanBeGiftedWithGiftCard = true;
    builder.CanBeTransferredToTeammate = false;
    builder.CanBeAirliftedToSelf = false;
    builder.CanBeAirliftedToTeammate = false;
    builder.IsVisibleToAllPlayers = false;
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.ShieldDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.ShieldDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
	local strUnitDescription = tostring (Mod.Settings.ShieldDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.ShieldDuration.."]";
	--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]';
	builder.ModData = createUnitDescriptionCode (strUnitDescription);
	--builder.ModData = strEssentialDescription_header ..strUnitDescription.. strEssentialDescription_footer;
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.ShieldDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.ShieldDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
	--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="garbage";};}[V1.1#JAD]';
	--result of using DataConverter: [V1.1#JAD]{"Essentials"={"UnitDescription"="A special immovable unit deployed to a territory that does no damage but can't be killed and absorbs all incoming regular damage to the territory it resides on. A territory cannot be captured while a Shield unit resides on it. Shields last 1 turn before expiring. [Created on turn 2, expires on turn 3]";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]
	print ("[SHIELD] ModData=="..tostring (builder.ModData));
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
		local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);  --assign unit to owner of the territory (not the caster of the Monolith action)
		builder.Name = 'Monolith';
		builder.IncludeABeforeName = false;
		builder.ImageFilename = 'monolith special unit_clearback.png'; --max size of 60x100 pixels
		builder.AttackPower = 0;
		builder.AttackPowerPercentage = 0;
		builder.DefensePower = 0;
		--builder.DefensePowerPercentage = 0;
		builder.DamageToKill = 9999999;
		builder.DamageAbsorbedWhenAttacked = 9999999;
		--builder.Health = 99999999999999;
		builder.CombatOrder = 99999; --doesn't protect Commander which is 10000; make a significantly high # to reasonably be 'the last unit' in combat order (highest #) on a territory so it does not protect any units
		--builder.CanBeGiftedWithGiftCard = false;
		builder.CanBeGiftedWithGiftCard = true;
		builder.CanBeTransferredToTeammate = false;
		builder.CanBeAirliftedToSelf = false;
		builder.CanBeAirliftedToTeammate = false;
		builder.IsVisibleToAllPlayers = false;
		--builder.TextOverHeadOpt = "Monolith"; --don't need writing; the graphic is sufficient
		--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.MonolithDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.MonolithDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
		local strUnitDescription = tostring (Mod.Settings.MonolithDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.MonolithDuration.."]";
		--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]';
		builder.ModData = strEssentialDescription_header ..strUnitDescription.. strEssentialDescription_footer;
	
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
		local MonolithDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberMonolithEnds=turnNumber_MonolithExpires, specialUnitID=specialUnit_Monolith.ID};
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
	local builder = WL.CustomSpecialUnitBuilder.Create(impactedTerritoryOwnerID);  --assign unit to owner of the territory (not the caster of the Isolation action)
	builder.Name = 'Isolated territory';
	builder.IncludeABeforeName = false;
	builder.ImageFilename = 'isolatedTerritory.png'; --max size of 60x100 pixels
	builder.AttackPower = 0;
	builder.DefensePower = 0;
	builder.DamageToKill = 0;
	builder.DamageAbsorbedWhenAttacked = 0;
	--builder.Health = 0;
	builder.CombatOrder = 10001; --doesn't protect Commander
	builder.CanBeGiftedWithGiftCard = false;
	builder.CanBeTransferredToTeammate = false;
	builder.CanBeAirliftedToSelf = false;
	builder.CanBeAirliftedToTeammate = false;
	builder.IsVisibleToAllPlayers = false;
	builder.TextOverHeadOpt = "Isolated";
	--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.IsolationDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.IsolationDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
	local strUnitDescription = tostring (Mod.Settings.IsolationDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.IsolationDuration.."]";
	--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]';
	builder.ModData = strEssentialDescription_header ..strUnitDescription.. strEssentialDescription_footer;
	local specialUnit_Isolation = builder.Build(); --save this in a table somewhere to destroy later

	--modify impactedTerritory object to change to neutral + add the special unit for visibility purposes			
	impactedTerritory.AddSpecialUnits = {specialUnit_Isolation}; --add special unit
	--table.insert (modifiedTerritories, impactedTerritory);
	--printObjectDetails (specialUnit_Isolation, "Isolation specialUnit", "Isolation"); --show contents of the Isolation special unit

	local castingPlayerID = gameOrder.PlayerID; --playerID of player who casts the Isolation action
	--need WL.GameOrderEvent.Create to modify territories (add special units) + jump to location + card/piece changes, and need WL.GameOrderCustom.Create for occursInPhase modifier (is this it?)
	--actually think we can get away with just Event
	local event = WL.GameOrderEvent.Create(castingPlayerID, gameOrder.Description, {}, {impactedTerritory}); -- create Event object to send back to addOrder function parameter
	event.JumpToActionSpotOpt = WL.RectangleVM.Create(game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY, game.Map.Territories[targetTerritoryID].MiddlePointX, game.Map.Territories[targetTerritoryID].MiddlePointY);
	addOrder (event, true); --add a new order; call the addOrder parameter (which is in itself a function) of this function; this actually adds the game order that changes territory to neutral & adds the special unit

	--save data in Mod.PublicGameData so the special unit can be destroyed later
	local publicGameData = Mod.PublicGameData;
	local turnNumber_IsolationExpires = -1;
	--print ("PRE  Isolation#items="..tablelength(publicGameData.IsolationData));
	--printObjectDetails (publicGameData.IsolationData, "[PRE  Isolation data]", "Execute Isolation operation");

	if (Mod.Settings.IsolationDuration==0) then  --if Isolation duration is Permanent (don't auto-revert), set expiration turn to -1
		turnNumber_IsolationExpires = -1; 
	else --otherwise, set expire turn as current turn # + card Duration
		turnNumber_IsolationExpires = game.Game.TurnNumber + Mod.Settings.IsolationDuration;
	end
	print ("expire turn#="..turnNumber_IsolationExpires.."::duration=="..Mod.Settings.IsolationDuration.."::gameTurn#="..game.Game.TurnNumber.."::calcExpireTurn=="..game.Game.TurnNumber + Mod.Settings.IsolationDuration.."::");
	--even if Isolation duration==0, still make a note of the details of the Isolation action - probably not required though
	local IsolationDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberIsolationEnds=turnNumber_IsolationExpires, specialUnitID=specialUnit_Isolation.ID};
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
		--[[print ("[DENEUTRALIZE] --------------------------------------");
		print ("[DENEUTRALIZE] neutralizeData [targetTerritoryID] == nil) --> ".. tostring (Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil)..", type "..type (targetTerritoryID).."::");
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil));
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [targetTerritoryID]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [tonumber(targetTerritoryID)]==nil));
		print ("[NEUTRALIZE] ************ tostring(Mod.PrivateGameData.NeutralizeData [93]==nil) --> ".. tostring(Mod.PrivateGameData.NeutralizeData [93]==nil));]]

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
			--builder.Health = 0;
			builder.CombatOrder = 10001; --doesn't protect Commander
			builder.CanBeGiftedWithGiftCard = false;
			builder.CanBeTransferredToTeammate = false;
			builder.CanBeAirliftedToSelf = false;
			builder.CanBeAirliftedToTeammate = false;
			builder.IsVisibleToAllPlayers = false;
			builder.TextOverHeadOpt = "Neutralized";
			--builder.ModData = DataConverter.DataToString({Essentials = {UnitDescription = tostring (Mod.Settings.NeutralizeDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.NeutralizeDuration.."]"}}, Mod); --add description to ModData field using Dutch's DataConverter, so it shows up in Essentials Unit Inspector
			local strUnitDescription = tostring (Mod.Settings.NeutralizeDescription).." [Created on turn "..game.Game.TurnNumber..", expires on turn "..game.Game.TurnNumber + Mod.Settings.NeutralizeDuration.."]";
			--builder.ModData = '[V1.1#JAD]{"Essentials"={"UnitDescription"="' ..strUnitDescription.. '";"__key"="fb52144e-6db8-47e6-be98-5ee606e3499f";};}[V1.1#JAD]';
			builder.ModData = strEssentialDescription_header ..strUnitDescription.. strEssentialDescription_footer;
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
			printObjectDetails (specialUnit_Neutralize, "Neutralize specialUnit", "Neutralize"); --show contents of the Neutralize special unit

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

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Isolation ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.IsolationEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	--case of Isolation Duration==-1 (permanent) is handled below, don't exit function here

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

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Neutralize ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.NeutralizeEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	--neutralize duration -1 (permanent) case is handled below, don't exit function here

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

				--[[  --get Neutralize special ---
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

				local territoryOwnerName_former = toPlayerName (territoryOwnerID_former, game);
				--local territoryOwnerName_former = game.Game.Players[territoryOwnerID_former].DisplayName(nil, false);
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
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardBlock ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.CardBlockEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.CardBlockDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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

--process actions that occur @ end of turn for various card types   <--- unfinished
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
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Tornado ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.TornadoEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.TornadoDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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
	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Earthquake ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.EarthquakeEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.EarthquakeDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Quicksand ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.QuicksandEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.QuicksandDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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
					if (specialUnit.ID==record.specialUnitID) then boolQuicksandSpecialUnitFound = true; end
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

--remove expired Shield Specials
function Shield_processEndOfTurn(game, addOrder)
    local privateGameData = Mod.PrivateGameData;
    local turnNumber = tonumber(game.Game.TurnNumber);

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Shield ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.ShieldEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.ShieldDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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

--remove expired Monolith Specials
function Monolith_processEndOfTurn (game, addOrder)
	local privateGameData = Mod.PrivateGameData;
	local turnNumber = tonumber (game.Game.TurnNumber);

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Monolith ~= true) then return; end --if module is not active, skip everything, just return
	if (Mod.Settings.MonolithEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.MonolithDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return
	
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

	if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Pestilence ~= true) then return; end --if Pestilence module is not active, skip everything, just return
	if (Mod.Settings.PestilenceEnabled ~= true) then return; end --if card is not enabled, skip everything, just return
	if (Mod.Settings.PestilenceDuration == -1) then return; end --if duration is set to -1, then it's permanent and doesn't expire, so skip everything, just return

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
					print ("[PESTILENCE] duration complete, pestilence ends for "..targetPlayerID.."/"..toPlayerName(targetPlayerID, game));
					addOrder (WL.GameOrderEvent.Create(targetPlayerID, "Pestilence ends for "..toPlayerName(targetPlayerID, game), nil, nil));
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