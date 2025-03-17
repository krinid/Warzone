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

	local MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	CreateLabel(MainUI).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));
	--CreateLabel(MainUI).SetText("Select which cards to enable:").SetColor(getColourCode ("subheading"));

	horz = UI.CreateHorizontalLayoutGroup(vert).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("Gold amount: ");
	BehemothCost_NumberInputField = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10000).SetValue(100).SetPreferredWidth(100).SetOnChange(OnGoldAmountChanged);
	UI.CreateButton(vert).SetText("Purchase a Behemoth").SetOnClick(PurchaseClicked);
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

	Game.CreateDialog (PresentBehemothDialog);
	Close1();
end


function PresentBehemothDialog (rootParent, setMaxSize, setScrollable, game, close)
	Close2 = close;

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel

	SelectTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

	buttonBuyBehemoth = UI.CreateButton(vert).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked);

	SelectTerritoryClicked(); --just start us immediately in selection mode, no reason to require them to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	TargetTerritoryInstructionLabel.SetText("Please click on the territory to spawn the Behemoth to");
	SelectTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
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
	local msg = 'Buy Behemoth, spawn to ' .. SelectedTerritory.Name;
	local payload = 'Behemoth|Purchase|' .. SelectedTerritory.ID.."|"..BehemothCost_NumberInputField.GetValue();
	local orders = Game.Orders;
	table.insert(orders, WL.GameOrderCustom.Create(Game.Us.ID, msg, payload,  { [WL.ResourceType.Gold] = BehemothCost_NumberInputField.GetValue() } ));
	Game.Orders = orders;

	Close2();
end