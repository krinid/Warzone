require ("behemoth");

function Client_PresentCommercePurchaseUI(rootParent, game, close)
	Close1 = close;
	Game = game;

	if (game.Us.ID == nil) then UI.Alert ("Only active players can buy Behemoths") return; end --don't believe this can ever occur; Spectators cannot bring up the Commerce menu

	local MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(MainUI).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("A unit whose strength scales with the amount of gold you spend to create it. See Mechanics for details.");
	-- BehemothMechanics_Button = UI.CreateButton(horz).SetText("[?] FAQ - Behemoth mechanics]").SetColor ("#FFFF00").SetOnClick (MechanicsClicked);
	BehemothMechanics_Button = UI.CreateButton(MainUI).SetText("[?] FAQ - Behemoth mechanics").SetColor (getColours()["Orange"]).SetOnClick (function () game.CreateDialog (createMechanicsWindow); end);
	-- UI.CreateLabel(MainUI).SetText("A unit whose strength scales with the amount of gold you spend to create it. Using low quantities gold will result in a Behemoth weaker than the # of armies you would receive for the same gold.");
	--CreateLabel(MainUI).SetText("Select which cards to enable:").SetColor(getColourCode ("subheading"));

	horz = UI.CreateHorizontalLayoutGroup(MainUI).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("Gold amount: ");
	local intMaxAvailableGold = game.LatestStanding.NumResources(game.Us.ID, WL.ResourceType.Gold); --amount of gold player has available (but some might be spent already)
	local intAvailableGold = game.LatestStanding.NumResources(game.Us.ID, WL.ResourceType.Gold); --max available gold minus any already spent this turn -- once I figured out how to do that; for now just use max available gold
	-- SetValue(100);
	--getArmiesDeployedThisTurnSoFar (Game, terrDetails.ID) + Game.LatestStanding.Territories[terrDetails.ID].NumArmies.NumArmies; --get available gold including subtraction of any gold already spent this turn

	--get values from Mod.Settings, if nil then assign default values
	-- local intGoldLevel1 = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default;
	-- local intGoldLevel2 = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default;
	-- local intGoldLevel3 = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default;
	-- local boolBehemothInvulnerableToNeutrals = (Mod.Settings.BehemothInvulnerableToNeutrals == nil and boolBehemothInvulnerableToNeutrals_default) or Mod.Settings.BehemothInvulnerableToNeutrals;
	-- local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;

	BehemothCost_NumberInputField = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(intMaxAvailableGold).SetValue(intAvailableGold).SetPreferredWidth(100);--.SetOnChange(OnGoldAmountChanged);
	BehemothCost_Button = UI.CreateButton(horz).SetText("Details").SetColor ("#00F4FF").SetOnClick (DetailsClicked);
	UI.CreateButton (MainUI).SetText ("Purchase a Behemoth").SetOnClick(PurchaseClicked).SetColor ("#008000");

	Behemoth_details_ErrorMsg_Label = UI.CreateLabel (rootParent);
	Behemoth_details_Properties_Header_Label = UI.CreateLabel (rootParent);
	Behemoth_details_Properties_Content_Label = UI.CreateLabel (rootParent);
	Behemoth_details_Limits_Header_Label = UI.CreateLabel (rootParent);
	Behemoth_details_Limits_Content_Label = UI.CreateLabel (rootParent);
end

--this never gets called b/c NIF has no OnChange event
function OnGoldAmountChanged ()
	print ("clicked");
end

--return the amount of gold already spent this turn
--THIS DOESN'T WORK YET -- it's a bit hairy to get gold spent from GameOrderCustom entries CustomGameOrders
function getGoldSpentThisTurnSoFar (game, terrID)
	for k,existingGameOrder in pairs (game.Orders) do
		--print (k,existingGameOrder.proxyType);
		if (existingGameOrder.proxyType == "GameOrderCustom") then
			print ("[GOLD USAGE] player "..existingGameOrder.PlayerID..", Gold Amount "..existingGameOrder.DeployOn..", Spent on "..existingGameOrder.NumArmies.. ", free "..tostring(existingGameOrder.Free));
			if (existingGameOrder.DeployOn == terrID) then return existingGameOrder.NumArmies; end --this is actual integer # of army deployments, not the usual NumArmies structure containing NumArmies+SpecialUnits
			--reference: need to extract the [WL.ResourceType.Gold] entry from WL.GameOrderCustom.Create(Game.Us.ID, msg, payload,  { [WL.ResourceType.Gold] = Mod.Settings.CostToBuyTank } ));
			--and also GameOrderPurchase entires but they only contain BuildCities Table<TerritoryID,integer>, so territory ID + # of cities and not how much gold was spent to build them, so need to cross reference game settings & recalculate teh amount spent
		end
	end
	return (0); --if no matching deployment orders were found, there were no deployments, so return 0
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

--given a parameter 'armies' of type WL.Armies, return the # of a given SU present within it
--2nd parameter indicates pattern match (true) vs exact match (false)
function countSUinstances (armies, strSUname, boolPatternMatch)
	local intNumSUs = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and ((boolPatternMatch and startsWith (su.Name, strSUname)) or (su.Name == strSUname))) then
			intNumSUs = intNumSUs + 1;
		end
	end
	return (intNumSUs);
end

function createMechanicsWindow (rootParent, setMaxSize, setScrollable, game, close)
    setMaxSize(600, 600);
	local MainUI = rootParent;
	UI.CreateLabel(MainUI).SetText("[BEHEMOTH - FAQ / Mechanics]\n\n").SetColor(getColourCode("card play heading")).SetAlignment (WL.TextAlignmentOptions.Left);
	-- UI.CreateLabel(MainUI).SetText("A unit whose strength scales with the amount of gold you spend to create it.");
	UI.CreateLabel(MainUI).SetText("A unit whose strength scales with the amount of gold you spend to create it. Using low quantities gold will result in a Behemoth weaker than the # of armies you would receive for the same gold.");

	--get values from Mod.Settings, if nil then assign default values
	local intGoldLevel1 = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default;
	local intGoldLevel2 = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default;
	local intGoldLevel3 = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default;
	local boolBehemothInvulnerableToNeutrals = (Mod.Settings.BehemothInvulnerableToNeutrals == nil and boolBehemothInvulnerableToNeutrals_default) or Mod.Settings.BehemothInvulnerableToNeutrals;
	local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;
	local intBehemothMaxSimultaneousPerPlayer = Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intBehemothMaxPerPlayerPerGame = Mod.Settings.BehemothMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host

	-- local MainUI = UI.CreateVerticalLayoutGroup(MechanicsWindow);
	UI.CreateLabel (MainUI).SetText ("\nYou decide how much gold to spend, and Behemoth strength increases appropriately.\n\nIn this specific game/template, for same amount of gold spent, a Behemoth will be:\n(assumes no army multiplier)");

	UI.CreateLabel (MainUI).SetText ("• < ".. tostring (intGoldLevel1).. " --> weaker than armies"..
	"\n• ≥ ".. tostring (intGoldLevel1).. ", < ".. tostring (intGoldLevel2).. " --> stronger than armies [linearly]" ..
	"\n• ≥ ".. tostring (intGoldLevel2).. ", < ".. tostring (intGoldLevel3).. " --> much stronger than armies [multiplicatively]" ..
	"\n• ≥ ".. tostring (intGoldLevel3).. " --> overwhelmingly stronger than armies [exponentially]").SetColor (getColourCode("subheading"));

	UI.CreateLabel (MainUI).SetText ("\nOther properties:").SetColor (getColourCode("minor heading"));
	UI.CreateLabel (MainUI).SetText ("• Behemoths takes damage: before Armies" ..
	"\n• Invulnerable to Neutrals: ".. tostring (boolBehemothInvulnerableToNeutrals)..
	"\n• Strength against Neutrals: ".. tostring (intStrengthAgainstNeutrals).."x"..
	"\n• Max # of Behemoths on map per player simultaneously: " ..tostring (intBehemothMaxSimultaneousPerPlayer)..
	"\n• Max # of Behemoths purchaseable per player per game: " ..tostring (intBehemothMaxPerPlayerPerGame));

	UI.CreateLabel (MainUI).SetText ("\nThe amount of gold you spend generates a value for 'Behemoth Power' using the above formula patterns. " ..
		"This value directly determines Behemoth health and Attack Power, and Defense Power is 25% of this value.");

	-- UI.CreateLabel (MainUI).SetText ("\nYou decide how much gold to spend, and Behemoth strength increases appropriately. For same amount of gold spent:"..
	-- "\n\n• < ".. tostring (intGoldLevel1).. " --> weaker than armies [linearly]"..
	-- "\n• ≥ ".. tostring (intGoldLevel1).. ", < ".. tostring (intGoldLevel2).. " --> stronger than armies [linearly]"..
	-- "\n• ≥ ".. tostring (intGoldLevel2).. ", < ".. tostring (intGoldLevel3).. " --> much stronger than armies [multiplicatively]"..
	-- "\n• ≥ ".. tostring (intGoldLevel3).. " --> overwhelmingly stronger than armies [exponentially]");
end

function DetailsClicked ()
	BehemothGoldSpent = BehemothCost_NumberInputField.GetValue ();
	--UI.Alert("Behemoth power: "..tostring (BehemothGoldSpent));
	-- local behemothPower = math.floor (getBehemothPower(BehemothGoldSpent) + 0.5);
	local behemothPower = getBehemothPower (BehemothGoldSpent);
	local behemothPowerFactor = 1.0; --keep it simple
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	if (behemothPower > 100000) then Behemoth_details_ErrorMsg_Label.SetText ("Behemoth power exceeds max value of 100,000; reduce your gold spending").SetColor ("#FF0000");
	else Behemoth_details_ErrorMsg_Label.SetText ("");
	end

	local boolBehemothInvulnerableToNeutrals = (Mod.Settings.BehemothInvulnerableToNeutrals == nil and boolBehemothInvulnerableToNeutrals_default) or Mod.Settings.BehemothInvulnerableToNeutrals;
	local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;

	Behemoth_details_Properties_Header_Label.SetText ("\nBehemoth properties:").SetColor (getColourCode ("subheading"));
	Behemoth_details_Properties_Content_Label.SetText ("• Cost "..BehemothGoldSpent..", Health ".. behemothPower.."\n• Attack power  " ..behemothPower.. ", Defense power ".. math.floor (behemothPower / 4 + 0.5)..
		"\n• Takes damage before Armies"..
		"\n• Invulnerable to Neutrals: ".. tostring (boolBehemothInvulnerableToNeutrals).."\n• Strength against Neutrals: ".. tostring (intStrengthAgainstNeutrals).."x");

	local intBehemothMaxSimultaneousPerPlayer = Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intBehemothMaxPerPlayerPerGame = Mod.Settings.BehemothMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host
	local intNumBehemothsOnMapForCurrentPlayer, intNumBehemothsCreatedByCurrentPlayer, intNumBehemothsOnMapForCurrentPlayer, intNumBehemothPurchaseOrdersForCurrentPlayer = countBehemothsOnMapAndInOrders (Game);
	--for ref: 	return intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders;

	Behemoth_details_Limits_Header_Label.SetText ("\nBehemoth limits (per player):").SetColor (getColourCode ("subheading"));
	Behemoth_details_Limits_Content_Label.SetText ("• Max # on map simultaneously: " ..tostring (intBehemothMaxSimultaneousPerPlayer) ..
		"\n• Max # purchaseable per game: " ..tostring (intBehemothMaxPerPlayerPerGame) ..
		"\n• # purchased so far: " ..tostring (intNumBehemothsCreatedByCurrentPlayer) .. " (includes current orders)");
		-- "\n   (**count includes current orders)");
end

function PurchaseClicked()
	--Check if they're already at max simultaneous or max total per player per game limits.  Add in how many they have on the map plus how many purchase orders they've already made
	--We check on the client for player convenience. Another check happens on the server, so even if someone hacks their client and removes this check they still won't be able to go over the max.

	DetailsClicked (); --update the details pane
	local behemothPower = math.floor (getBehemothPower(BehemothGoldSpent) + 0.5);
	if (behemothPower > 100000) then UI.Alert ("Behemoth power exceeds max value of 100,000; reduce your gold spending"); return; end

	local playerID = Game.Us.ID;
	local intBehemothMaxSimultaneousPerPlayer = Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intBehemothMaxPerPlayerPerGame = Mod.Settings.BehemothMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host
	-- local intNumBehemothsCurrentlyHaveSimultaneously = Mod.PlayerGameData.TotalBehemothsCreatedThisGame or 0; --get # of Behemoths already created this game, if nil then default to 0
	-- local intNumBehemothsPurchasedTotalPerGame = 0;

	local intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders = countBehemothsOnMapAndInOrders (Game);
	-- ref: return intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders;

	print ("JORK: maxPerGame " ..intBehemothMaxPerPlayerPerGame.. ", current#(map+orders) " ..intNumBehemothsCurrentlyHaveSimultaneously.. ", maxSimul " .. intBehemothMaxSimultaneousPerPlayer.. ", #current(map+orders) " ..tostring (intNumBehemothsPurchasedTotalPerGame).. ", #onMap " ..intNumBehemothsAlreadyOnMap ..", #orders " ..tostring (intNumBehemothNewPurchaseOrders));
	-- ref: return intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders;

	-- limit # of Behemoths to value set by host (max 5) including units already on the map and bought in orders this turn
	if (intBehemothMaxPerPlayerPerGame > 0 and intNumBehemothsCurrentlyHaveSimultaneously >= intBehemothMaxPerPlayerPerGame) then
		UI.Alert("Cannot create another Behemoth\n\nAlready at max of " ..tostring (intBehemothMaxPerPlayerPerGame).. " units per player that can be created for the duration of this game (including ones you have purchased this turn)");
		return;
	elseif (intNumBehemothsPurchasedTotalPerGame >= intBehemothMaxSimultaneousPerPlayer) then
		UI.Alert("Cannot create another Behemoth\n\nAlready at max of " ..tostring (intBehemothMaxSimultaneousPerPlayer).. " units per player that can simultaneously be on the map (including ones you have purchased this turn)");
		return;
	end

	BehemothGoldSpent = BehemothCost_NumberInputField.GetValue();
	if (BehemothGoldSpent <= 0) then UI.Alert ("Behemoth cost must be >0"); return; end

	Game.CreateDialog (PresentBehemothDialog);
	Close1();
end

--count # of Behemoths already on the map and Behemoth purchases entered into orders
--'game' parameter is clientgame (ie: must have game.Orders in it)
function countBehemothsOnMapAndInOrders (game)
	local intNumBehemothsAlreadyOnMap = 0; --# of Behemoths currently on the map
	local intNumBehemothNewPurchaseOrders = 0; --# of Behemoth purchase orders on the current turn (in order entry phase)
	local intNumBehemothsPurchasedTotalPerGame = Mod.PlayerGameData.TotalBehemothsCreatedThisGame or 0; --get # of Behemoths already created this game in previous turns or that have purchase orders during current turn (in order entry phase), if nil then default to 0
	local intNumBehemothsCurrentlyHaveSimultaneously = 0; --# of Behemoths currently on map or there are purchase orders for
	local playerID = game.Us.ID;

	--count # of Behemoths currently on the map (note: if fogged to the owning player by a Smoke Bomb, etc, then they won't be counted and the player could exceed the max while the fog is active)
	for _,terr in pairs(game.LatestStanding.Territories) do
		if (terr.OwnerPlayerID == playerID) then
			intNumBehemothsCurrentlyHaveSimultaneously = intNumBehemothsCurrentlyHaveSimultaneously + countSUinstances (terr.NumArmies, "Behemoth", true);
			intNumBehemothsAlreadyOnMap = intNumBehemothsAlreadyOnMap + 1;
		end
	end

	for _,order in pairs(game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, 'Behemoth|Purchase|')) then
			intNumBehemothsCurrentlyHaveSimultaneously = intNumBehemothsCurrentlyHaveSimultaneously + 1;
			intNumBehemothsPurchasedTotalPerGame = intNumBehemothsPurchasedTotalPerGame + 1;
			intNumBehemothNewPurchaseOrders = intNumBehemothNewPurchaseOrders + 1;
		end
	end

	print ("JARK: TOTAL#(map+orders) " ..intNumBehemothsCurrentlyHaveSimultaneously.. ", SIMUL#(map+orders) " ..tostring (intNumBehemothsPurchasedTotalPerGame).. ", #onMap " ..intNumBehemothsAlreadyOnMap ..", #orders " ..tostring (intNumBehemothNewPurchaseOrders));
	return intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders;
end

function PresentBehemothDialog (rootParent, setMaxSize, setScrollable, game, close)
	Close2 = close;
	setMaxSize(400, 500);

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
	local intBehemothMaxSimultaneousPerPlayer = Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intBehemothMaxPerPlayerPerGame = Mod.Settings.BehemothMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host
	local intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsCreatedByCurrentPlayer, intNumBehemothsOnMapForCurrentPlayer, intNumBehemothPurchaseOrdersForCurrentPlayer = countBehemothsOnMapAndInOrders (game);
	--for ref: 	return intNumBehemothsCurrentlyHaveSimultaneously, intNumBehemothsPurchasedTotalPerGame, intNumBehemothsAlreadyOnMap, intNumBehemothNewPurchaseOrders;

	UI.CreateLabel(vert).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));
	SelectTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetColor ("#00F4FF").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

	buttonBuyBehemoth = UI.CreateButton(vert).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked).SetColor ("#008000");

	UI.CreateLabel(vert).SetText ("\nBehemoth limits (per player):").SetColor (getColourCode ("subheading"));
	UI.CreateLabel(vert).SetText ("• " ..tostring (intNumBehemothsCurrentlyHaveSimultaneously) .." of max " ..tostring (intBehemothMaxSimultaneousPerPlayer).. " currently simultaneously deployed");
	UI.CreateLabel(vert).SetText ("• " ..tostring (intNumBehemothsCreatedByCurrentPlayer).. " of max " ..tostring (intBehemothMaxPerPlayerPerGame).. " per game already purchased");
	UI.CreateLabel(vert).SetText ("   (**counts include current orders)");

	local behemothCost = BehemothCost_NumberInputField.GetValue();
	local behemothPower = math.floor (getBehemothPower(BehemothGoldSpent) + 0.5);
	local behemothPowerFactor = 1.0; --always use factor of 1.0, it's too complicated with separate factors, etc
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	UI.CreateLabel(vert).SetText("\nBehemoth properties:").SetColor (getColourCode ("subheading"));
	UI.CreateLabel(vert).SetText("• Cost " ..tostring (BehemothGoldSpent).. ", Health ".. behemothPower.. "\n• Attack power ".. behemothPower * (1+behemothPowerFactor)..", Defense power ".. (behemothPower * behemothPowerFactor)/4);
	UI.CreateLabel(vert).SetText("• Takes damage before Armies");
	-- UI.CreateLabel(vert).SetText("\nBehemoth properties:\nCost "..BehemothGoldSpent.."\nPower: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor.."\n\n"..
	-- 	"Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 0.9+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
	-- 	"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable (false);
	-- print ("name==Behemoth (power ".. tostring (math.floor (behemothPower*10)/10) ..')');

	SelectTerritoryClicked(); --start immediately in selection mode, no reason to require player to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	-- local behemothPower = getBehemothPower(BehemothGoldSpent);
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Behemoth to").SetColor(getColourCode("minor heading")); --\nBehemoth power: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor);
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
		buttonBuyBehemoth.SetInteractable(false);
	else
		--Territory was clicked, check it
		if (Game.LatestStanding.Territories[terrDetails.ID].OwnerPlayerID ~= Game.Us.ID) then
			TargetTerritoryInstructionLabel.SetText("Select a territory that you own").SetColor(getColourCode("error"));
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name).SetColor(getColourCode("subheading"));
			SelectedTerritory = terrDetails;
			buttonBuyBehemoth.SetInteractable(true);
		end
	end
end

function CompletePurchaseClicked()
	local msg = 'Buy Behemoth for '..BehemothGoldSpent..' gold, spawn to ' .. SelectedTerritory.Name;
	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothGoldSpent;
	local orders = Game.Orders;
	table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, msg, payload,  { [WL.ResourceType.Gold] = BehemothGoldSpent } ));
	Game.Orders = orders;

	Close2();
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="Card|Reinforcement") then return getColours()["Dark Green"]; --green
	elseif (itemName=="Card|Spy") then return getColours()["Red"]; --
	elseif (itemName=="Card|Emergency Blockade card") then return getColours()["Royal Blue"]; --
	elseif (itemName=="Card|OrderPriority") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|OrderDelay") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Airlift") then return "#777777"; --
	elseif (itemName=="Card|Gift") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Diplomacy") then return getColours()["Light Blue"]; --
	-- elseif (itemName=="Card|") then return getColours()["Medium Blue"]; --
	elseif (itemName=="Card|Sanctions") then return getColours()["Purple"]; --
	elseif (itemName=="Card|Reconnaissance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Surveillance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Blockade") then return getColours()["Blue"]; --
	elseif (itemName=="Card|Bomb") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Bomb+ Card") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Nuke") then return getColours()["Tyrian Purple"]; --
	elseif (itemName=="Card|Airstrike") then return getColours()["Ivory"]; --
	elseif (itemName=="Card|Pestilence") then return getColours()["Lime"]; --
	elseif (itemName=="Card|Isolation") then return getColours()["Red"]; --
	elseif (itemName=="Card|Shield") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Monolith") then return getColours()["Hot Pink"]; --
	elseif (itemName=="Card|Card Block") then return getColours()["Light Blue"]; --
	elseif (itemName=="Card|Card Pieces") then return getColours()["Sea Green"]; --
	elseif (itemName=="Card|Card Hold") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Phantom") then return getColours()["Smoky Black"]; --
	elseif (itemName=="Card|Neutralize") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Deneutralize") then return getColours()["Green"]; --
	elseif (itemName=="Card|Earthquake") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Tornado") then return getColours()["Charcoal"]; --
	elseif (itemName=="Card|Quicksand") then return getColours()["Saddle Brown"]; --
	elseif (itemName=="Card|Forest Fire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Resurrection") then return getColours()["Goldenrod"]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
    else return "#AAAAAA"; --return light grey for everything else
    end
end

function getColours()
    local colors = {};					-- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end