require ("behemoth");

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end


function Client_PresentCommercePurchaseUI(rootParent, game, close)
	Close1 = close;
	Game = game;

	if (game.Us.ID == nil) then UI.Alert ("Only active players can buy Behemoths") return; end

	local MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(MainUI).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("A unit whose strength scales with the amount of gold you spend to create it. Using low quantities gold will result in a Behemoth weaker than the # of armies you would receive for the same gold.");
	--CreateLabel(MainUI).SetText("Select which cards to enable:").SetColor(getColourCode ("subheading"));

	horz = UI.CreateHorizontalLayoutGroup(MainUI).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("Gold amount: ");
	UI.CreateButton(MainUI).SetText("Purchase a Behemoth").SetOnClick(PurchaseClicked);

	local intMaxAvailableGold = game.LatestStanding.NumResources(game.Us.ID, WL.ResourceType.Gold); --amount of gold player has available (but some might be spent already)
	local intAvailableGold = game.LatestStanding.NumResources(game.Us.ID, WL.ResourceType.Gold); --max available gold minus any already spent this turn -- once I figured out how to do that; for now just use max available gold
	-- SetValue(100);
	--getArmiesDeployedThisTurnSoFar (Game, terrDetails.ID) + Game.LatestStanding.Territories[terrDetails.ID].NumArmies.NumArmies; --get available gold including subtraction of any gold already spent this turn

	--get values from Mod.Settings, if nil then assign default values
	local intGoldLevel1 = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default;
	local intGoldLevel2 = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default;
	local intGoldLevel3 = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default;
	local boolBehemothInvulnerableToNeutrals = (Mod.Settings.BehemothInvulnerableToNeutrals == nil and boolBehemothInvulnerableToNeutrals_default) or Mod.Settings.BehemothInvulnerableToNeutrals;
	local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;

	UI.CreateLabel (MainUI).SetText ("\nYou decide how much gold to spend, and Behemoth strength increases appropriately."..
	"\n\n• < ".. tostring (intGoldLevel1).. " - inefficient [better to buy armies]"..
	"\n• ≥ ".. tostring (intGoldLevel1).. ", < ".. tostring (intGoldLevel2).. " --> efficient [may make sense to buy a Behemoth]"..
	"\n• ≥ ".. tostring (intGoldLevel2).. ", < ".. tostring (intGoldLevel3).. " --> highly efficient [valuable to buy a Behemoth]"..
	"\n• ≥ ".. tostring (intGoldLevel3).. " --> immensely efficient [incredibly beneficial to buy a Behemoth]");

	BehemothCost_NumberInputField = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(intMaxAvailableGold).SetValue(intAvailableGold).SetPreferredWidth(100);--.SetOnChange(OnGoldAmountChanged);
	BehemothCost_Button = UI.CreateButton(horz).SetText("Details").SetOnClick (
		function ()
			BehemothGoldSpent = BehemothCost_NumberInputField.GetValue();
			--UI.Alert("Behemoth power: "..tostring (BehemothGoldSpent));
			local behemothPower = getBehemothPower(BehemothGoldSpent);
			local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
			Behemoth_details_Label.SetText ("\nBehemoth properties:\nCost "..BehemothGoldSpent..", Health ".. behemothPower..", Power: " .. behemothPower..", Scaling factor: " .. behemothPowerFactor.."\n\n"..
				"POWER Attack ".. behemothPower * (1+behemothPowerFactor)..", Defense ".. behemothPower * behemothPowerFactor.."\n   (Modifier - Attack ".. 0.9+behemothPowerFactor..", Defense ".. 0.6+behemothPowerFactor..")"..
				"\nCombat order: before armies\nDamage absorbed when attacked: ".. behemothPower * behemothPowerFactor..
				"\nInvulnerable to Neutrals: ".. tostring (boolBehemothInvulnerableToNeutrals).."\nStrength against Neutrals: ".. tostring (intStrengthAgainstNeutrals).."x");
		end);
	Behemoth_details_Label = UI.CreateLabel (rootParent);
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

function PurchaseClicked()
	--Check if they're already at max.  Add in how many they have on the map plus how many purchase orders they've already made
	--We check on the client for player convenience. Another check happens on the server, so even if someone hacks their client and removes this check they still won't be able to go over the max.

	local playerID = Game.Us.ID;

 	local numBehemothsAlreadyHave = 0;
	for _,ts in pairs(Game.LatestStanding.Territories) do
		if (ts.OwnerPlayerID == playerID) then
			numBehemothsAlreadyHave = numBehemothsAlreadyHave + countSUinstances (ts.NumArmies, "Behemoth", true);
		end
	end

	for _,order in pairs(Game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, 'Behemoth|Purchase|')) then
			numBehemothsAlreadyHave = numBehemothsAlreadyHave + 1;
		end
	end

	-- limit # of Behemoths to 5 including units already on the map and bought in orders this turn
	if (numBehemothsAlreadyHave >= 5) then
		UI.Alert("Cannot create another Behemoth as you are already at the max of 5 units");
		return;
	end

	BehemothGoldSpent = BehemothCost_NumberInputField.GetValue();
	if (BehemothGoldSpent <= 0) then UI.Alert ("Behemoth cost must be >0"); return; end

	Game.CreateDialog (PresentBehemothDialog);
	Close1();
end


function PresentBehemothDialog (rootParent, setMaxSize, setScrollable, game, close)
	Close2 = close;

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
	UI.CreateLabel(vert).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));

	SelectTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

	buttonBuyBehemoth = UI.CreateButton(vert).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked);

	--UI.Alert("Behemoth power: "..tostring (BehemothGoldSpent));

	local behemothPower = getBehemothPower(BehemothGoldSpent);
	local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	UI.CreateLabel(vert).SetText("\nBehemoth properties:\nCost "..BehemothGoldSpent.."\nPower: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor.."\n\n"..
		"Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 0.9+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
		"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable(false);
	print ("name==Behemoth (power ".. tostring (math.floor (behemothPower*10)/10) ..')');

	SelectTerritoryClicked(); --just start us immediately in selection mode, no reason to require them to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	-- local behemothPower = getBehemothPower(BehemothGoldSpent);
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Behemoth to"); --\nBehemoth power: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor);
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
			TargetTerritoryInstructionLabel.SetText("Select a territory that you own");
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
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

-- function getBehemothPowerFactor (behemothPower)
-- 	return (math.min (behemothPower/100, 0.1) + math.min (behemothPower/1000, 0.1) + math.min (behemothPower/10000, 0.1)); --max factor of 0.3
-- end

-- function getBehemothPower (goldSpent)
-- 	local power = 0;
-- 	if (goldSpent <= 0) then return 0; end
-- 	--if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
-- 	power = power + math.min ((goldSpent/50)*goldSpent, 25);
-- 	if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
-- 	if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
-- 	if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
-- 	if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
-- 	if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
-- 	power = math.floor (math.max (1, power)+0.5);

-- 	power = 0;
-- 	--[[power = power + math.min ((goldSpent/75)*goldSpent, 50);
-- 	power = power + math.min ((goldSpent/150)*goldSpent, 100);
-- 	power = power + math.min ((goldSpent/600)*goldSpent, 500);
-- 	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
-- 	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
-- 	power = power + (goldSpent/10000)*goldSpent;
-- 	power = math.floor (math.max (1, power)+0.5);]]

-- 	local a = 50;  --while goldSpent < a, power < goldSpent
-- 	local b = 100; --while a < goldSpent < b, power >= b and grows slowly/linearly
-- 	local c = 1000; --while b < goldSpent < c, power grows faster/quadratically
-- 	               --while c < goldSpent, power grows even faster/exponentially
-- 	--power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) + math.max(0, math.exp(goldSpent - c) - (c - b)^2);
-- 	--print  (goldSpent ..", "..math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) ..", ".. math.max(0, math.exp(goldSpent - c) - (c - b)^2));

-- 	power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, ((goldSpent - b)) * 1.0)^1 + math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5);
-- 	print  (goldSpent ..", ".. math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, ((goldSpent - b)) * 1.0)^1 ..", ".. math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5));

-- 	return power;
-- end