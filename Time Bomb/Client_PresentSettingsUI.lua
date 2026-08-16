require ('Bomb+ common');

function Client_PresentSettingsUI(rootParent)
	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);

	local horzTimeBombDurationForMaxPower = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombDurationForMaxPower).SetText ("Time delay: ").SetPreferredWidth (300);
	NIFdurationForMaxPower = UI.CreateNumberInputField (horzTimeBombDurationForMaxPower).SetInteractable (false).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (tonumber (Mod.Settings.TimeBombDurationForMaxPower or 3));
	UI.CreateLabel (mainUI).SetText("  • how many turns before a Time Bomb explodes\n");

	local horzTimeBombCastRange = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombCastRange).SetText ("Cast range: ").SetPreferredWidth (300);
	NIFcastRange = UI.CreateNumberInputField (horzTimeBombCastRange).SetSliderMinValue (0).SetInteractable (false).SetSliderMaxValue (100).SetValue (Mod.Settings.TimeBombCastRange);
	UI.CreateLabel (mainUI).SetText("  • how far a TimeBomb can be placed from a territory you own\n");

	local vertArmyDamage = UI.CreateVerticalLayoutGroup (mainUI);
	local horzArmyDamage1 = UI.CreateHorizontalLayoutGroup (vertArmyDamage).SetFlexibleWidth(1);
	local horzArmyDamage2 = UI.CreateHorizontalLayoutGroup (vertArmyDamage).SetFlexibleWidth(1);
	UI.CreateLabel (horzArmyDamage1).SetText ("[Army Damage]").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel (horzArmyDamage1).SetText ('Percent (%): ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIFarmyDamagePercent = UI.CreateNumberInputField (horzArmyDamage1).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.ArmyDamagePercent).SetPreferredWidth (150).SetInteractable (false);
	-- local horzArmyDamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel (horzArmyDamage2).SetText ("").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel (horzArmyDamage2).SetText ('Fixed: ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIFarmyDamageFixed = UI.CreateNumberInputField (horzArmyDamage2).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.ArmyDamageFixed).SetPreferredWidth (150).SetInteractable (false);
	-- UI.CreateLabel (mainUI).SetText ('• % damage is applied first, then fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)');

	local vertSUdamage = UI.CreateVerticalLayoutGroup (mainUI);
	local horzSUdamage1 = UI.CreateHorizontalLayoutGroup (vertSUdamage).SetFlexibleWidth(1);
	local horzSUdamage2 = UI.CreateHorizontalLayoutGroup (vertSUdamage).SetFlexibleWidth(1);
	UI.CreateLabel (horzSUdamage1).SetText ("[Special Unit Damage]").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel(horzSUdamage1).SetText ('Percent (%): ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIF_SUdamagePercent = UI.CreateNumberInputField (horzSUdamage1).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.SUdamagePercent).SetInteractable (false);
	UI.CreateLabel (horzSUdamage2).SetText ("").SetColor ("#FFFF00").SetPreferredWidth (150);
	-- local horzSUdamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel(horzSUdamage2).SetText ('Fixed: ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIF_SUdamageFixed = UI.CreateNumberInputField (horzSUdamage2).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.SUdamageFixed).SetInteractable (false);
	UI.CreateLabel (mainUI).SetText ('• % damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)');

	UI.CreateLabel (mainUI).SetText ("\n");
	UI.CreateEmpty (mainUI);
	cboxEmptyTerritoriesGoNeutral = UI.CreateCheckBox (mainUI).SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral).SetText ("Territories reduced to 0 armies turn Neutral").SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral).SetInteractable (false);
	NIF_SUsPreventNeutral = UI.CreateCheckBox (mainUI).SetIsChecked (Mod.Settings.SpecialUnitsPreventNeutral).SetText ("Special Units prevent territory from turning neutral").SetInteractable (false);
	if (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == true) then UI.CreateLabel (mainUI).SetText ('  • a Time Bomb reducing a territory to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	elseif (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == false) then UI.CreateLabel (mainUI).SetText ('  • a Time Bomb reducing a territory to 0 will turn neutral and you will lose control of any Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	else UI.CreateLabel (mainUI).SetText ('  • territories do not turn neutral when reduced to 0 armies or Special Units');
	end

	local horzCitiesDestroyedByTimeBombPlay = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzCitiesDestroyedByTimeBombPlay).SetText ('# cities destroyed by a Time Bomb card play: ');
	NIFnumCitiesDestroyedByTimeBomb = UI.CreateNumberInputField (horzCitiesDestroyedByTimeBombPlay).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByTimeBombPlay).SetInteractable (false);
	if (tonumber (Mod.Settings.NumCitiesDestroyedByTimeBombPlay) == 0) then UI.CreateLabel (mainUI).SetText ("  · Time Bombs don't destroy cities");
	else UI.CreateLabel (mainUI).SetText ("  · this quantity of cities are destroyed when a Time Bomb explodes");
	end

	local horzTimeBombImplementationPhase = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateEmpty (mainUI);
	UI.CreateLabel (horzTimeBombImplementationPhase).SetText ('Turn phase where Time Bomb placements are executed');
	TimeBombImplementationPhase = UI.CreateButton (horzTimeBombImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase))).SetInteractable (false).SetColor (getColourCode ("minor heading"));

	local horzTimeBombPlusCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombPlusCardPiecesNeeded).SetText ("Number of pieces to divide the card into").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	TimeBombPlusCardPiecesNeeded = UI.CreateNumberInputField (horzTimeBombPlusCardPiecesNeeded).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.TimeBombPlusPiecesNeeded or 10).SetWholeNumbers (true).SetInteractable (false);

	local horzTimeBombPlusCardStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzTimeBombPlusCardStartPieces).SetText ("Pieces given to each player at the start").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	TimeBombPlusCardStartPieces = UI.CreateNumberInputField (horzTimeBombPlusCardStartPieces).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.TimeBombPlusStartPieces or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzTimeBombPlusCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombPlusCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	TimeBombPlusPiecesPerTurn = UI.CreateNumberInputField (horzTimeBombPlusCardPiecesPerTurn).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.TimeBombPlusPiecesPerTurn or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzTimeBombPlusCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombPlusCardWeight).SetText ("Card weight  (how common the card is)").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	TimeBombPlusCardWeight = UI.CreateNumberInputField (horzTimeBombPlusCardWeight).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (false).SetValue (Mod.Settings.TimeBombPlusCardWeight or 1).SetInteractable (false);
end