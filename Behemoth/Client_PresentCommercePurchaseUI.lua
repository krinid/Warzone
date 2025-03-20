--require('Utilities')

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
	BehemothCost_NumberInputField = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(game.LatestStanding.NumResources(game.Us.ID, WL.ResourceType.Gold)).SetValue(100).SetPreferredWidth(100);--.SetOnChange(OnGoldAmountChanged);
	UI.CreateButton(MainUI).SetText("Purchase a Behemoth").SetOnClick(PurchaseClicked);
end

function OnGoldAmountChanged ()
	print ("clicked");
end

function NumTanksIn(armies)
	local ret = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and su.Name == 'Tank') then
			ret = ret + 1;
		end
	end
	return ret;
end

function PurchaseClicked()
	--Check if they're already at max.  Add in how many they have on the map plus how many purchase orders they've already made
	--We check on the client for player convenience. Another check happens on the server, so even if someone hacks their client and removes this check they still won't be able to go over the max.

	local playerID = Game.Us.ID;

	--[[local numTanksAlreadyHave = 0;
	for _,ts in pairs(Game.LatestStanding.Territories) do
		if (ts.OwnerPlayerID == playerID) then
			numTanksAlreadyHave = numTanksAlreadyHave + NumTanksIn(ts.NumArmies);
		end
	end

	for _,order in pairs(Game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith(order.Payload, 'BuyTank_')) then
			numTanksAlreadyHave = numTanksAlreadyHave + 1;
		end
	end

	if (numTanksAlreadyHave >= Mod.Settings.MaxTanks) then
		UI.Alert("You already have " .. numTanksAlreadyHave .. " tanks, and you can only have " ..  Mod.Settings.MaxTanks);
		return;
	end]]

	BehemothGoldSpent = BehemothCost_NumberInputField.GetValue();
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

	SelectTerritoryClicked(); --just start us immediately in selection mode, no reason to require them to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Behemoth to\nBehemoth power: " .. getBehemothPower (BehemothGoldSpent).."\nScaling factor: " .. getBehemothPowerFactor (getBehemothPower(BehemothGoldSpent)));
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

function getBehemothPowerFactor (behemothPower)
	return (math.min (behemothPower/100, 0.1) + math.min (behemothPower/1000, 0.1) + math.min (behemothPower/10000, 0.1)); --max factor of 0.3
end

function getBehemothPower (goldSpent)
	local power = 0;
	if (goldSpent <= 0) then return 0; end
	--if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
	power = power + math.min ((goldSpent/50)*goldSpent, 25);
	if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
	if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
	if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
	if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
	if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
	power = math.floor (math.max (1, power)+0.5);

	power = 0;
	power = power + math.min ((goldSpent/75)*goldSpent, 50);
	power = power + math.min ((goldSpent/150)*goldSpent, 100);
	power = power + math.min ((goldSpent/600)*goldSpent, 500);
	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
	power = power + (goldSpent/10000)*goldSpent;
	power = math.floor (math.max (1, power)+0.5);
	return power;
end