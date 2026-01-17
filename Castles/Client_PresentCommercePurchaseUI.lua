require ("castles");

function Client_PresentCommercePurchaseUI(rootParent, game, close)
	Game = game;

	MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(MainUI).SetText("[CASTLE]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("Build a castle to provide additional protection to armies that enter the castle. Costs:\n"..
		"• 1st castle: " ..tostring (intCastleBaseCost).. " gold\n• Increases: +" ..tostring (intCastleCostIncrease).. " gold per castle\n• Maintenance: " ..tostring (intCastleMaintenanceCost)..
		" gpt per castle\n• Conversion ratio: " ..tostring (intArmyToCastlePowerRatio).. " [1 army = " ..tostring (intArmyToCastlePowerRatio).. " castle strength]");
	if (game.Us.ID == nil) then UI.CreateLabel(MainUI).SetText("[Spectators can't buy Castles]").SetColor(getColourCode("error")); return; end --can spectators even see this? Can they click the "Build" (buy) button?
	createPurchaseCastleUIcomponents ();
end

function createPurchaseCastleUIcomponents ()
	if (UI.IsDestroyed (vertPurchaseDialog) == false) then UI.Destroy (vertPurchaseDialog); end
	vertPurchaseDialog = UI.CreateVerticalLayoutGroup(MainUI);
	local horz = UI.CreateHorizontalLayoutGroup (vertPurchaseDialog).SetFlexibleWidth (1);
	PurchaseCastleButton = UI.CreateButton(horz).SetText("Purchase Castle").SetOnClick(PurchaseClicked).SetColor (getColourCode("button green"));
	EnterExitCastleButton = UI.CreateButton(horz).SetText("Armies Enter/Exit Castle").SetColor(getColourCode("button magenta")).SetOnClick(enter_exit_Castle_dialog);
	ScuttleCastleButton = UI.CreateButton(horz).SetText("Scuttle Castle").SetColor(getColourCode("button red")).SetOnClick(scuttle_Castle_dialog);
end

function scuttle_Castle_dialog ()
	UI.Destroy (vertPurchaseDialog);
	vertPurchaseDialog = UI.CreateVerticalLayoutGroup(MainUI);
	SelectTerritoryBtn_CastleArmyMovements = UI.CreateButton(vertPurchaseDialog).SetText("Scuttle Castle - Select Territory").SetColor (getColourCode ("button cyan")).SetOnClick(function () SelectTerritoryClicked_CastleArmyMovements ("Select a castle to scuttle"); end);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vertPurchaseDialog).SetText("");
	UI.CreateLabel(vertPurchaseDialog).SetText("**Armies inside castle will exit before scuttled").SetColor (getColourCode ("subheading"));
	UI.CreateLabel(vertPurchaseDialog).SetText(" \n");
	UI.CreateEmpty(vertPurchaseDialog);
	UI.CreateLabel(vertPurchaseDialog).SetText(" \n");
	UI.CreateEmpty(vertPurchaseDialog);

	horz = UI.CreateHorizontalLayoutGroup(vertPurchaseDialog).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("Cost to scuttle castle: " ..tostring (intCastleScuttleCost)).SetColor (getColourCode("highlight"));

	buttonAddOrder = UI.CreateButton(vertPurchaseDialog).SetInteractable(false).SetText("Scuttle Castle").SetOnClick(ScuttleCastleButtonClicked).SetColor (getColourCode ("button green"));
	SelectTerritoryBtn_CastleArmyMovements.SetInteractable (false);
	SelectTerritoryClicked_CastleArmyMovements ("Select a castle to scuttle"); --start immediately in selection mode, no reason to require player to click the button
end

function enter_exit_Castle_dialog ()
	UI.Destroy (vertPurchaseDialog);
	vertPurchaseDialog = UI.CreateVerticalLayoutGroup(MainUI);
	SelectTerritoryBtn_CastleArmyMovements = UI.CreateButton(vertPurchaseDialog).SetText("Armies Enter/Exit - Select Territory").SetColor (getColourCode ("button cyan")).SetOnClick (function () SelectTerritoryClicked_CastleArmyMovements ("Select a castle to allow armies to Enter/Exit"); end);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vertPurchaseDialog).SetText("");
	UI.CreateLabel(vertPurchaseDialog).SetText(" \n");
	UI.CreateEmpty(vertPurchaseDialog);
	UI.CreateLabel(vertPurchaseDialog).SetText(" \n");
	UI.CreateEmpty(vertPurchaseDialog);

	horz = UI.CreateHorizontalLayoutGroup(vertPurchaseDialog).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to enter the Castle: ").SetColor (getColourCode("highlight"));
	NumArmiesToEnterCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
	UI.CreateLabel(vertPurchaseDialog).SetText("   (armies on territory outside the castle to move inside the castle; Special Units cannot enter castles)").SetColor (getColourCode ("subheading"));

	horz = UI.CreateHorizontalLayoutGroup(vertPurchaseDialog).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to exit the Castle: ").SetColor (getColourCode("highlight"));
	NumArmiesToExitCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
	UI.CreateLabel(vertPurchaseDialog).SetText("   (armies inside the castle to exit the castle to the territory)").SetColor (getColourCode ("subheading"));

	buttonAddOrder = UI.CreateButton(vertPurchaseDialog).SetInteractable(false).SetText("Add Order").SetOnClick(AddOrderButtonClicked_ArmiesEnterExit).SetColor (getColourCode ("button green"));

	SelectTerritoryBtn_CastleArmyMovements.SetInteractable (false);
	SelectTerritoryClicked_CastleArmyMovements ("Select a castle to allow armies to Enter/Exit"); --start immediately in selection mode, no reason to require player to click the button
end

function SelectTerritoryClicked_CastleArmyMovements (strDisplayMessage)
	UI.InterceptNextTerritoryClick(TerritoryClicked_CastleArmyMovements);
	TargetTerritoryInstructionLabel.SetText (strDisplayMessage).SetColor (getColourCode("error"));
	SelectTerritoryBtn_CastleArmyMovements.SetInteractable(false);
end

function TerritoryClicked_CastleArmyMovements(terrDetails)
	if (UI.IsDestroyed (SelectTerritoryBtn_CastleArmyMovements)) then return; end

	SelectTerritoryBtn_CastleArmyMovements.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		SelectedTerritory = nil;
		buttonAddOrder.SetInteractable(false);
	else
		--Territory was clicked, check it
		if (Game.LatestStanding.Territories[terrDetails.ID].OwnerPlayerID ~= Game.Us.ID or countSUinstances (Game.LatestStanding.Territories[terrDetails.ID].NumArmies, "Castle", false) < 1) then
			TargetTerritoryInstructionLabel.SetText("Select a territory that you own that has a Castle").SetColor(getColourCode("error"));
			buttonAddOrder.SetInteractable(false);
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name).SetColor(getColourCode("subheading"));
			SelectedTerritory = terrDetails;
			buttonAddOrder.SetInteractable(true);
		end
	end
end

function ScuttleCastleButtonClicked ()
	local orders = Game.Orders;
	local objCastleSU = getSUonTerritory (Game.LatestStanding.Territories[SelectedTerritory.ID].NumArmies, "Castle", false);
	if (objCastleSU == nil) then UI.Alert ("Couldn't find castle on territory"); return; end --this should never occur b/c this function is only called when a valid territory with a castle SU is specified

	local payload_Scuttle = 'Castle|Scuttle|' ..SelectedTerritory.ID;
	local msg_Scuttle = "Castle scuttled on " ..getTerritoryName (SelectedTerritory.ID, Game);
	local customOrder_Scuttle = WL.GameOrderCustom.Create (Game.Us.ID, msg_Scuttle, payload_Scuttle, { [WL.ResourceType.Gold] = intCastleScuttleCost }, WL.TurnPhase.BlockadeCards); --Enter/Exit occurs in EMB phase; Scuttle occurs in GiftCards phase; EMB phase occurs before GiftCards phase, so Enter/Exits occur before Scuttles

	customOrder_Scuttle.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
	customOrder_Scuttle.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Scuttle Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	table.insert(orders, customOrder_Scuttle);

	Game.Orders = orders;
	createPurchaseCastleUIcomponents (); --clear Select Territory / # Armies to move inside / Purchase controls and recreate Purchase Castle button, revert to initial Commerce dialog state (so can buy more Castles, other items, etc)
end

function AddOrderButtonClicked_ArmiesEnterExit()
	local orders = Game.Orders;
	local objCastleSU = getSUonTerritory (Game.LatestStanding.Territories[SelectedTerritory.ID].NumArmies, "Castle", false);
	if (objCastleSU == nil) then UI.Alert ("Couldn't find castle on territory"); return; end --this should never occur b/c this function is only called when a valid territory with a castle SU is specified

	-- local intArmiesToEnterCastle = math.max (0, math.min (NumArmiesToEnterCastle.GetValue(), Game.LatestStanding.Territories[SelectedTerritory.ID].NumArmies.NumArmies));
	-- local intArmiesToExitCastle = math.max (0, math.min (NumArmiesToExitCastle.GetValue(), objCastleSU.Health));
	local intArmiesToEnterCastle = math.max (0, NumArmiesToEnterCastle.GetValue());
	local intArmiesToExitCastle = math.max (0, NumArmiesToExitCastle.GetValue());
	-- local intArmiesTerritoryDelta = math.max (0, intArmiesToExitCastle * intArmyToCastlePowerRatio - intArmiesToExitCastle); --actual army quantity that will change in the order (#exiting*ratio - #entering), should never go below 0 but use max just in case another mod does something funky
	-- local msg = "";
	-- if (intArmiesToEnterCastle > 0) then
	-- 	msg = msg .. intArmiesToEnterCastle.. " armies enter castle";
	-- elseif (intArmiesToExitCastle > 0) then
	-- 	if (msg ~= "") then msg = msg .. "; "; end
	-- 	msg = msg .. intArmiesToEnterCastle.. " armies enter castle";
	-- end

	if (intArmiesToEnterCastle > 0) then
		local payload_Enter = 'Castle|Enter|' ..SelectedTerritory.ID.. "|" ..intArmiesToEnterCastle;
		local msg_Enter = intArmiesToEnterCastle.. " armies enter castle on " ..getTerritoryName (SelectedTerritory.ID, Game);
		local customOrder_Enter = WL.GameOrderCustom.Create (Game.Us.ID, msg_Enter, payload_Enter, {}, WL.TurnPhase.EmergencyBlockadeCards); --Enter/Exit occurs in EMB phase; Scuttle occurs in GiftCards phase; EMB phase occurs before GiftCards phase, so Enter/Exits occur before Scuttles

		customOrder_Enter.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
		customOrder_Enter.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle army enter", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
		table.insert(orders, customOrder_Enter);
	end

	if (intArmiesToExitCastle > 0) then
		local payload_Exit = 'Castle|Exit|' ..SelectedTerritory.ID.. "|" ..intArmiesToExitCastle;
		local msg_Exit = intArmiesToExitCastle.. " armies exit castle on " ..getTerritoryName (SelectedTerritory.ID, Game);
		local customOrder_Exit = WL.GameOrderCustom.Create (Game.Us.ID, msg_Exit, payload_Exit, {}, WL.TurnPhase.BlockadeCards); --Enter/Exit occurs in EMB phase; Scuttle occurs in GiftCards phase; EMB phase occurs before GiftCards phase, so Enter/Exits occur before Scuttles
		customOrder_Exit.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
		customOrder_Exit.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle army exit", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
		table.insert(orders, customOrder_Exit);
	end

	Game.Orders = orders;
	createPurchaseCastleUIcomponents (); --clear Select Territory / # Armies to move inside / Purchase controls and recreate Purchase Castle button, revert to initial Commerce dialog state (so can buy more Castles, other items, etc)
end

function PurchaseClicked()
	--Check if they're already at max simultaneous or max total per player per game limits.  Add in how many they have on the map plus how many purchase orders they've already made
	--We check on the client for player convenience. Another check happens on the server, so even if someone hacks their client and removes this check they still won't be able to go over the max.

	local playerID = Game.Us.ID;
	local intCastleMaxSimultaneousPerPlayer = Mod.Settings.CastleMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intCastleMaxPerPlayerPerGame = Mod.Settings.CastleMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host
	local numCastlesAlreadyHaveTotalPerGame = Mod.PlayerGameData.TotalCastlesCreatedThisGame or 0; --get # of Castles already created this game, if nil then default to 0
	local numCastlesAlreadyHaveSimultaneously = 0;
	intNumCastlesPurchaseOrdersThisTurn = 0;

	--count # of Castles currently on the map (note: if fogged to the owning player by a Smoke Bomb, etc, then they won't be counted and the player could exceed the max while the fog is active)
	for _,terr in pairs (Game.LatestStanding.Territories) do
		if (terr.OwnerPlayerID == playerID) then
			numCastlesAlreadyHaveSimultaneously = numCastlesAlreadyHaveSimultaneously + countSUinstances (terr.NumArmies, "Castle", true);
		end
	end

	for _,order in pairs (Game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, 'Castle|Purchase|')) then
			numCastlesAlreadyHaveSimultaneously = numCastlesAlreadyHaveSimultaneously + 1;
			numCastlesAlreadyHaveTotalPerGame = numCastlesAlreadyHaveTotalPerGame + 1;
			intNumCastlesPurchaseOrdersThisTurn = intNumCastlesPurchaseOrdersThisTurn + 1;
		end
	end

	--block if matches: 'Castle|Purchase|' ..SelectedTerritory.ID

	-- limit # of Castles to value set by host (max 5) including units already on the map and bought in orders this turn
	-- if (intCastleMaxPerPlayerPerGame > 0 and numCastlesAlreadyHaveTotalPerGame >= intCastleMaxPerPlayerPerGame) then
	-- 	UI.Alert("Cannot create another Castle\n\nAlready at max of " ..tostring (intCastleMaxPerPlayerPerGame).. " units per player that can be created for the duration of this game (including ones you have purchased this turn)");
	-- 	return;
	-- elseif (numCastlesAlreadyHaveSimultaneously >= intCastleMaxSimultaneousPerPlayer) then
	-- 	UI.Alert("Cannot create another Castle\n\nAlready at max of " ..tostring (intCastleMaxSimultaneousPerPlayer).. " units per player that can simultaneously be on the map (including ones you have purchased this turn)");
	-- 	return;
	-- end

	UI.Destroy (vertPurchaseDialog);
	vertPurchaseDialog = UI.CreateVerticalLayoutGroup(MainUI);
	SelectTerritoryBtn = UI.CreateButton(vertPurchaseDialog).SetText("Purchase Castle - Select Territory").SetColor ("#00F4FF").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vertPurchaseDialog).SetText("");
	buttonBuyCastle = UI.CreateButton(vertPurchaseDialog).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked).SetColor ("#008000");

	horz = UI.CreateHorizontalLayoutGroup(vertPurchaseDialog).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to move inside the Castle: ").SetColor (getColourCode("highlight"));
	NumArmiesToMoveIntoCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
	UI.CreateLabel(vertPurchaseDialog).SetText("   Castles are created at end of turn. Armies up to the # specified here will move into the castle when it is created. Special Units cannot enter the castle").SetColor ("#FFFF00");

	SelectTerritoryBtn.SetInteractable (false);
	SelectTerritoryClicked(); --start immediately in selection mode, no reason to require player to click the button

	local intNumCastlesOwned = countSUinstancesOnWholeMapFor1Player (Game, Game.Us.ID, "Castle", false);
	local intNumCastlesPurchaseOrdersThisTurn = countSUsPurchasedThisTurn (Game, "Castle");
	local intCastleCost = intCastleBaseCost + intCastleCostIncrease * (intNumCastlesOwned + intNumCastlesPurchaseOrdersThisTurn);
	local intCurrentMaintenanceCost = math.floor (countSUinstancesOnWholeMapFor1Player (Game, Game.Us.ID, "Castle", false) * intCastleMaintenanceCost + 0.5);

	UI.CreateLabel(vertPurchaseDialog).SetText("• Next castle cost: " ..tostring (intCastleCost).. " gold");
	UI.CreateLabel(vertPurchaseDialog).SetText("• # of castles already built: " ..tostring (intNumCastlesOwned));
	UI.CreateLabel(vertPurchaseDialog).SetText("• # of castle purchase orders this turn: " ..tostring (intNumCastlesPurchaseOrdersThisTurn));
	UI.CreateLabel(vertPurchaseDialog).SetText("• Current castle maintenance: " ..tostring (intCurrentMaintenanceCost).. " gpt");
	-- UI.CreateLabel(vertPurchaseDialog).SetText("• Future castle maintenance: X");
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	-- local behemothPower = getBehemothPower(BehemothGoldSpent);
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Castle to").SetColor (getColourCode("error")); --\nBehemoth power: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor);
	--.."\n\n".."Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 1+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
	--	"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	if (UI.IsDestroyed (SelectTerritoryBtn)) then return; end

	SelectTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		SelectedTerritory = nil;
		buttonBuyCastle.SetInteractable(false);
	else
		--Territory was clicked, check it
		if (Game.LatestStanding.Territories[terrDetails.ID].OwnerPlayerID ~= Game.Us.ID) then
			TargetTerritoryInstructionLabel.SetText("Select a territory that you own").SetColor(getColourCode("error"));
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name).SetColor(getColourCode("subheading"));
			SelectedTerritory = terrDetails;
			buttonBuyCastle.SetInteractable(true);
		end
	end
end

function CompletePurchaseClicked()
	local intNumCastlesOwned = countSUinstancesOnWholeMapFor1Player (Game, Game.Us.ID, "Castle", false);
	local intNumCastlesPurchaseOrdersThisTurn = countSUsPurchasedThisTurn (Game, "Castle");
	local intCastleCost = intCastleBaseCost + intCastleCostIncrease * (intNumCastlesOwned + intNumCastlesPurchaseOrdersThisTurn);

	if (countSUinstances (Game.LatestStanding.Territories[SelectedTerritory.ID].NumArmies, "Castle", false) > 0) then
		UI.Alert("Territory '" ..SelectedTerritory.Name.. "' already has a castle; can only build 1 castle per territory");
		return;
	elseif (buildingCastleOnTerritoryThisTurn (Game, SelectedTerritory.ID) == true) then
		UI.Alert("Territory '" ..SelectedTerritory.Name.. "' already has an order to build a castle; can only build 1 castle per territory");
		return;
	end

	local msg = 'Buy Castle for '..intCastleCost..' gold, spawn to ' .. SelectedTerritory.Name ..", " ..tostring (math.max (0, NumArmiesToMoveIntoCastle.GetValue())).. " armies move inside";
	local payload = 'Castle|Purchase|' ..SelectedTerritory.ID.. "|" ..math.max (0, NumArmiesToMoveIntoCastle.GetValue()).. "|" ..intCastleCost;
	local orders = Game.Orders;
	local customOrder = WL.GameOrderCustom.Create (Game.Us.ID, msg, payload,  { [WL.ResourceType.Gold] = intCastleCost }, WL.TurnPhase.ReceiveCards);
	customOrder.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
	customOrder.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	-- customOrder.OccursInPhaseOpt = WL.TurnPhase.ReceiveCards;
	table.insert(orders, customOrder);
	Game.Orders = orders;
	createPurchaseCastleUIcomponents (); --clear Select Territory / # Armies to move inside / Purchase controls and recreate Purchase Castle button, revert to initial Commerce dialog state (so can buy more Castles, other items, etc)
end