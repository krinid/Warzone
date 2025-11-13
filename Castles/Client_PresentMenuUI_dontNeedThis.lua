require ("castles");

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
    Game = game; --global variable to use in other functions in this code 

    if game == nil then 		print('ClientGame is nil'); 	end
	if game.LatestStanding == nil then 		print('ClientGame.LatestStanding is nil'); 	end
	if game.LatestStanding.Cards == nil then 		print('ClientGame.LatestStanding.Cards is nil'); 	end
	if game.Us == nil then print('ClientGame.Us is nil'); end
	if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end

	setMaxSize(400, 600);
	MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	enter_exit_Castle_dialog ();
end

function enter_exit_Castle_dialog ()
	SelectTerritoryBtn = UI.CreateButton(MainUI).SetText("Select Territory").SetColor (getColourCode ("button cyan")).SetOnClick(SelectTerritoryClicked_CastleArmyMovements);
	TargetTerritoryInstructionLabel = UI.CreateLabel(MainUI).SetText("");
	UI.CreateLabel(MainUI).SetText(" \n");
	UI.CreateEmpty(MainUI);
	UI.CreateLabel(MainUI).SetText(" \n");
	UI.CreateEmpty(MainUI);

	horz = UI.CreateHorizontalLayoutGroup(MainUI).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to enter the Castle: ").SetColor (getColourCode("highlight"));
	NumArmiesToEnterCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
	UI.CreateLabel(MainUI).SetText("   (armies on territory outside the castle to move inside the castle; Special Units cannot enter castles)").SetColor (getColourCode ("subheading"));

	horz = UI.CreateHorizontalLayoutGroup(MainUI).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to exit the Castle: ").SetColor (getColourCode("highlight"));
	NumArmiesToExitCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
	UI.CreateLabel(MainUI).SetText("   (armies inside the castle to exit the castle to the territory)").SetColor (getColourCode ("subheading"));

	buttonAddOrder = UI.CreateButton(MainUI).SetInteractable(false).SetText("Add Order").SetOnClick(AddOrderButtonClicked).SetColor (getColourCode ("button green"));

	SelectTerritoryBtn.SetInteractable (false);
	SelectTerritoryClicked_CastleArmyMovements(); --start immediately in selection mode, no reason to require player to click the button
end

function SelectTerritoryClicked_CastleArmyMovements()
	UI.InterceptNextTerritoryClick(TerritoryClicked_CastleArmyMovements);
	-- local behemothPower = getBehemothPower(BehemothGoldSpent);
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Castle to").SetColor (getColourCode("error")); --\nBehemoth power: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor);
	--.."\n\n".."Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 1+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
	--	"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked_CastleArmyMovements(terrDetails)
	if (UI.IsDestroyed (SelectTerritoryBtn)) then return; end

	SelectTerritoryBtn.SetInteractable(true);

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

function AddOrderButtonClicked()
	-- local intNumCastlesOwned = countSUinstancesOnWholeMapFor1Player (Game, Game.Us.ID, "Castle", false);
	-- local intNumCastlesPurchaseOrdersThisTurn = countSUsPurchasedThisTurn (Game, "Castle");
	-- local intCastleCost = intCastleBaseCost + intCastleCostIncrease * (intNumCastlesOwned + intNumCastlesPurchaseOrdersThisTurn);

	-- if (countSUinstances (Game.LatestStanding.Territories[SelectedTerritory.ID].NumArmies, "Castle", false) > 0) then
	-- 	UI.Alert("Territory '" ..SelectedTerritory.Name.. "' already has a castle; can only build 1 castle per territory");
	-- 	return;
	-- elseif (buildingCastleOnTerritoryThisTurn (Game, SelectedTerritory.ID) == true) then
	-- 	UI.Alert("Territory '" ..SelectedTerritory.Name.. "' already has an order to build a castle; can only build 1 castle per territory");
	-- 	return;
	-- end

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

	local payload_Enter = 'Castle|Enter|' ..SelectedTerritory.ID.. "|" ..intArmiesToEnterCastle;
	local msg_Enter = intArmiesToEnterCastle.. " armies enter castle";
	local customOrder_Enter = WL.GameOrderCustom.Create (Game.Us.ID, msg_Enter, payload_Enter);
    customOrder_Enter.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
	-- customOrder.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	-- customOrder.OccursInPhaseOpt = WL.TurnPhase.ReceiveCards;
	table.insert(orders, customOrder_Enter);

	local payload_Exit = 'Castle|Exit|' ..SelectedTerritory.ID.. "|" ..intArmiesToExitCastle;
	local msg_Exit = intArmiesToExitCastle.. " armies exit castle";
	local customOrder_Exit = WL.GameOrderCustom.Create (Game.Us.ID, msg_Exit, payload_Exit);
    customOrder_Exit.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
	-- customOrder.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	-- customOrder.OccursInPhaseOpt = WL.TurnPhase.ReceiveCards;
	table.insert(orders, customOrder_Exit);

	Game.Orders = orders;
end