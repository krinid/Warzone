function Client_PresentConfigureUI(rootParent)
	local mainUI = UI.CreateVerticalLayoutGroup(rootParent);
	Mod.Settings.PoisonPiecesNeeded = Mod.Settings.PoisonPiecesNeeded or 10; --default to 10 if not set yet
	Mod.Settings.PoisonPiecesPerTurn = Mod.Settings.PoisonPiecesPerTurn or 1; --default to 1 if not set yet
	Mod.Settings.PoisonStartPieces = Mod.Settings.PoisonStartPieces or 1; --default to 1 if not set yet
	Mod.Settings.PoisonCardWeight = Mod.Settings.PoisonCardWeight or 1; --default to 1 if not set yet
	Mod.Settings.PoisonDuration = Mod.Settings.PoisonDuration or 3; --default to 3 if not set yet

	Mod.Settings.PoisonDamageFixedArmies = Mod.Settings.PoisonDamageFixedArmies or 10; --1; --default to 1
	Mod.Settings.PoisonDamagePercentArmies = Mod.Settings.PoisonDamagePercentArmies or 25; --0; --default to 0
	Mod.Settings.PoisonDamageFixedSpecialUnits = Mod.Settings.PoisonDamageFixedSpecialUnits or 5; --default to 0
	Mod.Settings.PoisonDamagePercentSpecialUnits = Mod.Settings.PoisonDamagePercentSpecialUnits or 10; --default to 10%
	Mod.Settings.PoisonImpactRange = Mod.Settings.PoisonImpactRange or 1; --default to 1 (doesn't spread)
	Mod.Settings.PoisonSpreadRange = Mod.Settings.PoisonSpreadRange or 3; --default to 3
	Mod.Settings.PoisonDamageAffectsAllAbilities = Mod.Settings.PoisonDamageAffectsAllAbilities == nil and true or Mod.Settings.PoisonDamageAffectsAllAbilities --default to true (affects all abilities, eg: Attack+DefensePower, Attack+DefensePower%, DamageAbsorption); false == only affects Health and Damage To Kill
	Mod.Settings.PoisonAffectsOtherModAbilities = Mod.Settings.PoisonAffectsOtherModAbilities == nil and true or Mod.Settings.PoisonAffectsOtherModAbilities; --default to true; this setting indicates whether Poison should be implemented into other mods, eg: Pestilence, Nuke, Bomb+, etc
	Mod.Settings.NumCitiesDestroyedByPoison = Mod.Settings.NumCitiesDestroyedByPoison or 0; --default to 0 (doesn't destroy cities)
	Mod.Settings.CitiesAreDestroyedEachTurn = Mod.Settings.CitiesAreDestroyedEachTurn ~= nil and Mod.Settings.CitiesAreDestroyedEachTurn or false; --default to 0 (destroys cities 1 time at start of Poison attack, not each turn)

	local horzPoisonDuration = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonDuration).SetText ("Poison Duration: ").SetPreferredWidth (300);
    NIFpoisonDuration = UI.CreateNumberInputField (horzPoisonDuration).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.PoisonDuration);

	local horzPoisonDamageFixedArmies = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonDamageFixedArmies).SetText("Damage - Armies - Fixed amount").SetPreferredWidth (300);
    NIFarmiesKilledInput = UI.CreateNumberInputField (horzPoisonDamageFixedArmies).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.PoisonDamageFixedArmies);

	local horzPoisonDamagePercentArmies = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonDamagePercentArmies).SetText ("Damage - Armies - Percentage (%)").SetPreferredWidth (300);
	NIFarmiesKilledPercentInput = UI.CreateNumberInputField (horzPoisonDamagePercentArmies).SetSliderMinValue (0).SetSliderMaxValue (1).SetWholeNumbers (false).SetValue (Mod.Settings.PoisonDamagePercentArmies);
	UI.CreateLabel (mainUI).SetText ("  • % damage is applied first, then fixed damage is applied");
	UI.CreateLabel (mainUI).SetText ("  • eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]");

	local horzPoisonDamageFixedSpecialUnits = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonDamageFixedSpecialUnits).SetText ("Damage - Special Units - Fixed amount").SetPreferredWidth (300);
	NIFspecialUnitsKilledInput = UI.CreateNumberInputField (horzPoisonDamageFixedSpecialUnits).SetSliderMinValue(0).SetSliderMaxValue(25).SetValue (Mod.Settings.PoisonDamageFixedSpecialUnits);

	local horzPoisonDamagePercentSpecialUnits = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonDamagePercentSpecialUnits).SetText ("Damage - Special Units - Percentage (%)").SetPreferredWidth (300);
	NIFspecialUnitsKilledPercentInput = UI.CreateNumberInputField(horzPoisonDamagePercentSpecialUnits).SetSliderMinValue(0).SetSliderMaxValue(1).SetWholeNumbers(false).SetValue (Mod.Settings.PoisonDamagePercentSpecialUnits);
	UI.CreateLabel (mainUI).SetText("  • % damage is applied first, then fixed damage is applied");
	UI.CreateLabel (mainUI).SetText("  • eg: if configured to 25% damage + 10 fixed damage, a targeted Special Unit with 100 Health or DamageToKill would be reduced to 65 (100*0.75-10)]");

	local horzPoisonImpactRange = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonImpactRange).SetText ("Impact range: ").SetPreferredWidth (300);
	NIFimpactRange = UI.CreateNumberInputField (horzPoisonImpactRange).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.PoisonImpactRange);
	UI.CreateLabel (mainUI).SetText("  • how many neighbouring territories the poison will spread to upon impact");

	local horzPoisonSpreadRange = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonSpreadRange).SetText ("Spread range: ").SetPreferredWidth (300);
	NIFspreadRange = UI.CreateNumberInputField (horzPoisonSpreadRange).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.PoisonSpreadRange);
	UI.CreateLabel (mainUI).SetText ("  • how many neighbouring territories the poison can spread to if carried");

	local horzPoisonDamageAffectsAllAbilities = UI.CreateHorizontalLayoutGroup (mainUI);
    cboxPoisonDamageAffectsAllAbilities = UI.CreateCheckBox (horzPoisonDamageAffectsAllAbilities).SetIsChecked (Mod.Settings.PoisonDamageAffectsAllAbilities).SetText ("Affects all Special Unit properties");
	UI.CreateLabel (mainUI).SetText ("  • when checked, SU Attack+DefensePower, Attack+DefensePower%, DamageAbsorption are also reduced by Poison effects");
	UI.CreateLabel (mainUI).SetText ("  • when unchecked, only Health or Damage To Kill properties are reduced by Poison effects");

	UI.CreateLabel (mainUI).SetText ("Poison affects other mods: " .. tostring (Mod.Settings.PoisonAffectsOtherModAbilities));
	local horzPoisonAffectsOtherModAbilities = UI.CreateHorizontalLayoutGroup (mainUI);
    cboxPoisonAffectsOtherModAbilities = UI.CreateCheckBox (horzPoisonAffectsOtherModAbilities).SetIsChecked (Mod.Settings.PoisonAffectsOtherModAbilities).SetText ("Poison affects other mods");
	UI.CreateLabel (mainUI).SetText ("  • when checked, other mods (eg: Pestilence, Nuke, Bomb+, etc) can also cause Poison effects");
	UI.CreateLabel (mainUI).SetText ("  • when unchecked, Poison effects will only impact units directly resulting from playing of Poison cards");

	local horzNumCitiesDestroyedByPoison = UI.CreateHorizontalLayoutGroup (mainUI);
	local radiogroupPoisonCitiesDestroyedEachTurn = UI.CreateRadioButtonGroup (horzNumCitiesDestroyedByPoison);
	UI.CreateLabel (horzNumCitiesDestroyedByPoison).SetText ("# cities destroyed by Poison").SetPreferredWidth (300);
	NIFnumCitiesDestroyedByPoison = UI.CreateNumberInputField (horzNumCitiesDestroyedByPoison).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.NumCitiesDestroyedByPoison);
	UI.CreateLabel (mainUI).SetText ("  • Set to 0, Poison plays don't destroy cities");
	UI.CreateLabel (mainUI).SetText ("  • Set to >=1, this quantity of cities are destroyed when a Poison card is played");
	UI.CreateLabel (mainUI).SetText ("\nCities are destroyed:");
	radioPoisonCitiesDestroyedOnFirstImpactOnly = UI.CreateRadioButton (mainUI).SetGroup (radiogroupPoisonCitiesDestroyedEachTurn).SetText("on first Poison impact turn only").SetIsChecked (not Mod.Settings.CitiesAreDestroyedEachTurn);
	radioPoisonCitiesDestroyedEachTurn = UI.CreateRadioButton (mainUI).SetGroup (radiogroupPoisonCitiesDestroyedEachTurn).SetText ("each turn Poison is active").SetIsChecked (Mod.Settings.CitiesAreDestroyedEachTurn);

	local horzPoisonPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonPiecesNeeded).SetText("Number of pieces to divide the card into").SetPreferredWidth (300);
	NIFpoisonPiecesNeeded = UI.CreateNumberInputField (horzPoisonPiecesNeeded).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.PoisonPiecesNeeded).SetWholeNumbers (true).SetInteractable(true);

	local horzPoisonStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzPoisonStartPieces).SetText("Pieces given to each player at the start").SetPreferredWidth (300);
	NIFpoisonStartPieces = UI.CreateNumberInputField (horzPoisonStartPieces).SetSliderMinValue (1).SetSliderMaxValue(10).SetValue (Mod.Settings.PoisonStartPieces).SetWholeNumbers (true).SetInteractable (true);

	local horzPoisonPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonPiecesPerTurn).SetText ("Minimum pieces awarded per turn").SetPreferredWidth (300);
	NIFpoisonPiecesPerTurn = UI.CreateNumberInputField (horzPoisonPiecesPerTurn).SetSliderMinValue (1).SetSliderMaxValue(10).SetValue (Mod.Settings.PoisonPiecesPerTurn).SetWholeNumbers (true).SetInteractable (true);

	local horzPoisonCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzPoisonCardWeight).SetText ("Card weight").SetPreferredWidth (300);
	NIFpoisonCardWeight = UI.CreateNumberInputField (horzPoisonCardWeight).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (false).SetValue (Mod.Settings.PoisonCardWeight).SetInteractable (true);
end