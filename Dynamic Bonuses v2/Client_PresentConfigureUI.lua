function Client_PresentConfigureUI(rootParent)
	local minMultiplier = Mod.Settings.MinMultiplier;
	local LevelMultiplierIncrement = Mod.Settings.LevelMultiplierIncrement;
	local MaxMultiplier = Mod.Settings.MaxMultiplier;
	if minMultiplier == nil then minMultiplier = 1; end
	if LevelMultiplierIncrement == nil then LevelMultiplierIncrement = 0.2; end
	if MaxMultiplier == nil then MaxMultiplier = 2.0; end

	vert = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(vert).SetText("• Each territory accumulates a multiplier, which increments each turn it is held by the same player");
	UI.CreateLabel(vert).SetText("• Resulant bonus value = (initial bonus value) * (average of all territory multipliers in the bonus)\n");

	horzMinMultiplier = UI.CreateHorizontalLayoutGroup (vert).SetFlexibleWidth (1.0);
	UI.CreateLabel(horzMinMultiplier).SetText("Initial multiplier (set when a player captures a territory)").SetPreferredWidth (400);
	setMinMultiplier = UI.CreateNumberInputField(horzMinMultiplier).SetSliderMinValue(0).SetSliderMaxValue(1).SetWholeNumbers(false).SetValue(minMultiplier).SetPreferredWidth (100);
	-- UI.CreateLabel(vert).SetText("  (set when a player captures a territory)");

	horzMaxMultiplier = UI.CreateHorizontalLayoutGroup (vert).SetFlexibleWidth (1.0);
	UI.CreateLabel(horzMaxMultiplier).SetText("Maximum multiplier").SetPreferredWidth (400);
	setMaxMultiplier = UI.CreateNumberInputField (horzMaxMultiplier).SetSliderMinValue(1).SetSliderMaxValue(3).SetWholeNumbers(false).SetValue(MaxMultiplier).SetPreferredWidth (100);

	horzIncrement = UI.CreateHorizontalLayoutGroup (vert).SetFlexibleWidth (1.0);
	UI.CreateLabel (horzIncrement).SetText ("Increment (multiplier increases this amount each turn)").SetPreferredWidth (400);
	setLevelMultiplierIncrement = UI.CreateNumberInputField(horzIncrement).SetSliderMinValue(0.1).SetSliderMaxValue(1).SetWholeNumbers(false).SetValue(LevelMultiplierIncrement).SetPreferredWidth (100);
end
