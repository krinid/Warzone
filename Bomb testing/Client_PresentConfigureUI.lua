
function Client_PresentConfigureUI(rootParent)
	local killPercentage = Mod.Settings.killPercentage;
	if killPercentage == nil then killPercentage = 50; end
    local delayed = Mod.Settings.delayed;
	if delayed == nil then delayed = false; end
	local armiesKilled = Mod.Settings.armiesKilled;
	if armiesKilled == nil then armiesKilled = 0; end
	
	
	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local row1 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row1).SetText('Amount of troops killed (in percentage)');
    killPercentageInput = UI.CreateNumberInputField(row1)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(100)
		.SetValue(killPercentage);
	local row2 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row2).SetText('Number of armies killed (absolute number, happens after percentage kill).');
    armiesKilledInput = UI.CreateNumberInputField(row2)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(15)
		.SetValue(armiesKilled);
	local row3 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row3).SetText('Delayed: off = card happens at the beggining of the turn, on = card happens at the end of the turn.');
    delayedInput = UI.CreateCheckBox(row3)
		.SetIsChecked(delayed);
	local row4 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row4).SetText('Do special units prevent territory from turning neutral after bombing?');
    specialUnitsInput = UI.CreateCheckBox(row4)
		.SetIsChecked(SpecialUnits);
end

	