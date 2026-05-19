function Server_AdvanceTurn_Start (game, addNewOrder)
	--this is necessary to catch any players that have just gone AI at the start of the turn before they can enter any orders
	local pgd = Mod.PublicGameData;
	local arrPlayersGoneAI = pgd.PlayersGoneAIdata or {};

	print ("==============TURN ADVANCE " ..tostring (game.Game.TurnNumber).. "==============");
	for k,v in pairs (game.ServerGame.PendingStateTransitions) do
		print ("[TRANSITION] PlayerID ".. tostring (k) .. ", New state " ..tostring (v.NewState).. ", TakingOverForAI ".. tostring (v.TakingOverForAI) .. ", TurningInto AI: ".. tostring (v.TurningIntoAI));
	end

	if (arrPlayersGoneAI == nil) then arrPlayersGoneAI = {}; end --only works in SP for now
	for _, player in pairs (game.Game.Players) do
		print ("[CHECK PRE] Player " ..tostring (player.ID).. " wentAI " ..tostring (arrPlayersGoneAI [player.ID] ~= nil).. " [" ..tostring (arrPlayersGoneAI [player.ID]).. "]");
		if (player.IsAI == true and arrPlayersGoneAI [player.ID] == nil) then
			arrPlayersGoneAI [player.ID] = game.Game.TurnNumber;
			print ("[CHECK - WENT AI] Player " ..tostring (player.ID).. " went AI on T" ..tostring (game.Game.TurnNumber).. " [" ..tostring (arrPlayersGoneAI [player.ID]).. "]");
		elseif (player.IsAI == false and arrPlayersGoneAI [player.ID] ~= nil) then
			print ("[CHECK - RECLAIMED] Player " ..tostring (player.ID).. " reclaimed control on T" ..tostring (game.Game.TurnNumber).. " [was AI since T" ..tostring (arrPlayersGoneAI [player.ID]).. "]");
			arrPlayersGoneAI [player.ID] = nil;
		end
	end

	pgd.PlayersGoneAIdata = arrPlayersGoneAI;
	Mod.PublicGameData = pgd;
end

function Server_AdvanceTurn_Order (game, order, result, skip, addNewOrder)
	local boolPermissableAction = isPermissableAction (game, order, result);
	print ("ORDER RESULT player " .. tostring (order.PlayerID).. ", type " .. tostring (order.proxyType) .. ", permissable? " .. tostring (boolPermissableAction));
	if (boolPermissableAction == false) then
		skip (WL.ModOrderControl.SkipAndSupressSkippedMessage);
	end
end

function isPermissableAction (game, order, result)
	local arrPlayersGoneAI = Mod.PublicGameData.PlayersGoneAIdata or {};
	print ("...order player ID " .. tostring (order.PlayerID).. ", type " .. tostring (order.proxyType).. ", arrPlayersGoneAI " ..tostring (arrPlayersGoneAI [order.PlayerID]));
	if (order.PlayerID == 0) then return true; end --if order player is Neutral, just return true; it's likely an Event order (not an AI order)

	local boolOrderIsPureAI = game.Game.Players [order.PlayerID].IsAI and not game.Game.Players [order.PlayerID].HumanTurnedIntoAI;
	local boolOrderIsHumanAI = game.Game.Players [order.PlayerID].HumanTurnedIntoAI;
	local boolOrderAttackTOplayerID = 0; --if an attack, populate with player ID of the player being attacked
	local boolOrderAttackTOisPlayer = false; --if an attack, populate with true if target player is human (ie: not AI including Human AI as result of boot or surrender)
	local boolPermissableAction = false;

	if (boolOrderIsPureAI == false and boolOrderIsHumanAI == false) then return true; end --order belongs to a non-AI fully human player, so permit the order

	if (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true) then
		boolOrderAttackTOplayerID = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
		boolOrderAttackTOisPlayer = boolOrderAttackTOplayerID > 0 and game.Game.Players[boolOrderAttackTOplayerID].IsAI == false or false;
	end

	--check if order belongs to Human AI and the appropriate duration hasn't passed yet
	if (boolOrderIsHumanAI == true and Mod.Settings.AIdelayBeforeOrders > 0 and arrPlayersGoneAI [order.PlayerID] ~= nil and (game.Game.TurnNumber - arrPlayersGoneAI [order.PlayerID] < Mod.Settings.AIdelayBeforeOrders)) then
		--player went AI and the required # of turns hasn't passed yet, check if order is permissable
		print ("[HUMAN AI WITHIN DELAY DURATION] Suppress Attacks " .. tostring (Mod.Settings.AIdelay_Attacks).. ", Suppress Deploys " .. tostring (Mod.Settings.AIdelay_Deploys).. ", Suppress Card Plays " .. tostring (Mod.Settings.AIdelay_CardPlays));
		if (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and Mod.Settings.AIdelay_Attacks == false) then return true;
		elseif (order.proxyType == "GameOrderDeploy" and Mod.Settings.AIdelay_Deploys == false) then return true;
		elseif (startsWith (order.proxyType, "GameOrderPlayCard") == true and Mod.Settings.AIdelay_CardPlays == false) then return true;
		end
		print ("[HUMAN AI WITHIN DELAY DURATION] Suppressed!");
		return false; --if Human AI & appropriate duration hasn't passed and the order wasn't permissable via the above, cancel it
	end

	if (order.PlayerID == 1) then
		print ("- - -\nORDER DECISION player " .. tostring (order.PlayerID).. ", type " .. tostring (order.proxyType) .. ", boolOrderIsPureAI " .. tostring (boolOrderIsPureAI).. ", boolOrderIsHumanAI " .. tostring (boolOrderIsHumanAI).. ", boolOrderAttackTOplayerID " .. tostring (boolOrderAttackTOplayerID).. ", boolOrderAttackTOisPlayer " .. tostring (boolOrderAttackTOisPlayer));
		print ("ORDER SETTINGS DistinguishPureHumanAI " .. tostring (Mod.Settings.DistinguishPureHumanAI));
		-- print ("ORDER SETTINGS Pure  AI -- AttackPlayers_PureAI " .. tostring (Mod.Settings.AttackPlayers_PureAI).. ", AttackAIs_PureAI " .. tostring (Mod.Settings.AttackAIs_PureAI).. ", AttackNeutrals_PureAI " .. tostring (Mod.Settings.AttackNeutrals_PureAI).. ", Transfers_PureAI " .. tostring (Mod.Settings.Transfers_PureAI).. ", Deployments_PureAI " .. tostring (Mod.Settings.Deployments_PureAI).. ", BuildCities_PureAI " .. tostring (Mod.Settings.BuildCities_PureAI).. ", Diplomacy_PureAI " .. tostring (Mod.Settings.Diplomacy_PureAI).. ", Blockade_PureAI " .. tostring (Mod.Settings.Blockade_PureAI).. ", EmergencyBlockade_PureAI " .. tostring (Mod.Settings.EmergencyBlockade_PureAI).. ", Reinforcements_PureAI " .. tostring (Mod.Settings.Reinforcements_PureAI).. ", Bomb_PureAI " .. tostring (Mod.Settings.Bomb_PureAI).. ", Sanction_PureAI " .. tostring (Mod.Settings.Sanction_PureAI));
		-- print ("ORDER SETTINGS Human AI -- AttackPlayers " .. tostring (Mod.Settings.AttackPlayers).. ", AttackAIs " .. tostring (Mod.Settings.AttackAIs).. ", AttackNeutrals " .. tostring (Mod.Settings.AttackNeutrals).. ", Transfers " .. tostring (Mod.Settings.Transfers).. ", Deployments " .. tostring (Mod.Settings.Deployments).. ", BuildCities " .. tostring (Mod.Settings.BuildCities).. ", Diplomacy " .. tostring (Mod.Settings.Diplomacy).. ", Blockade " .. tostring (Mod.Settings.Blockade).. ", EmergencyBlockade " .. tostring (Mod.Settings.EmergencyBlockade).. ", Reinforcements " .. tostring (Mod.Settings.Reinforcements).. ", Bomb " .. tostring (Mod.Settings.Bomb).. ", Sanction " .. tostring (Mod.Settings.Sanction));
	end

	if (boolOrderIsPureAI == true and Mod.Settings.DistinguishPureHumanAI == true) then
		--order belongs to Pure AI and we're distinguishing between Pure & Human AI, check if action is permissable using Pure AI settings
		print ("[PURE AI RULES]");
		if (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOisPlayer == true and Mod.Settings.AttackPlayers_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOplayerID == 0 and Mod.Settings.AttackNeutrals_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOisPlayer == false and Mod.Settings.AttackAIs_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == false and Mod.Settings.Transfers_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderDeploy" and Mod.Settings.Deployments_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPurchase" and Mod.Settings.BuildCities_PureAI == true) then return true; -- technically this could be any purchase, but cities are the only purchase that AIs are capable of
		elseif (order.proxyType == "GameOrderPlayCardDiplomacy" and Mod.Settings.Diplomacy_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardBlockade" and Mod.Settings.Blockade_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardAbandon" and Mod.Settings.EmergencyBlockade_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardReinforcement" and Mod.Settings.Reinforcements_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardBomb" and Mod.Settings.Bomb_PureAI == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardSanctions" and Mod.Settings.Sanction_PureAI == true) then return true;
		end
	elseif (boolOrderIsPureAI == true or boolOrderIsHumanAI == true) then
		--either we're not distinguishing between Pure & Human AI, or it is a Human AI order - either way, Human AI settings apply to whether the order should be permitted or not
		print ("[HUMAN AI RULES]");
		if (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOisPlayer == true and Mod.Settings.AttackPlayers == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOplayerID == 0 and Mod.Settings.AttackNeutrals == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == true and boolOrderAttackTOplayerID > 0 and boolOrderAttackTOisPlayer == false and Mod.Settings.AttackAIs == true) then return true;
		elseif (order.proxyType == "GameOrderAttackTransfer" and result.IsAttack == false and Mod.Settings.Transfers == true) then return true;
		elseif (order.proxyType == "GameOrderDeploy" and Mod.Settings.Deployments == true) then return true;
		elseif (order.proxyType == "GameOrderPurchase" and Mod.Settings.BuildCities == true) then return true; -- technically this could be any purchase, but cities are the only purchase that AIs are capable of
		elseif (order.proxyType == "GameOrderPlayCardDiplomacy" and Mod.Settings.Diplomacy == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardBlockade" and Mod.Settings.Blockade == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardAbandon" and Mod.Settings.EmergencyBlockade == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardReinforcement" and Mod.Settings.Reinforcements == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardBomb" and Mod.Settings.Bomb == true) then return true;
		elseif (order.proxyType == "GameOrderPlayCardSanctions" and Mod.Settings.Sanction == true) then return true;
		end
	end
	return boolPermissableAction;
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end