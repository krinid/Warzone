require ('Bomb+ common');

function Client_PresentSettingsUI(rootParent)
	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);
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
	if (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == true) then UI.CreateLabel (mainUI).SetText ('  • when Bombed territory is reduced to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	elseif (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == false) then UI.CreateLabel (mainUI).SetText ('  • when Bombed territory is reduced to 0 will turn neutral and you will lose control of any Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	else UI.CreateLabel (mainUI).SetText ('  • territories do not turn neutral when reduced to 0 armies or Special Units');
	end
	-- UI.CreateLabel (mainUI).SetText ('  • when checked, a Bombed territory reduced to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	-- UI.CreateLabel (mainUI).SetText ('  • when unchecked, a Bombed territory reduced to 0 will turn neutral, even if it has Special Units on it');
	-- UI.CreateLabel (mainUI).SetText ('  • unless you have a specific mechanic in mind for your template, leave this checked');

	local horzCitiesDestroyedByBombPlay = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzCitiesDestroyedByBombPlay).SetText ('# cities destroyed by a Bomb+ card play: ');
	NIFnumCitiesDestroyedByBomb = UI.CreateNumberInputField (horzCitiesDestroyedByBombPlay).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByBombPlay).SetInteractable (false);
	if (tonumber (Mod.Settings.NumCitiesDestroyedByBombPlay) == 0) then UI.CreateLabel (mainUI).SetText ("  · Bomb+ plays don't destroy cities");
	else UI.CreateLabel (mainUI).SetText ("  · this quantity of cities are destroyed when a Bomb+ card is played");
	end
	-- UI.CreateLabel (mainUI).SetText ("  · Set to 0 = Bomb+ plays don't destroy cities");
	-- UI.CreateLabel (mainUI).SetText ("  · Set to >=1 = this quantity of cities are destroyed when a Bomb+ card is played");

	local horzBombImplementationPhase = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateEmpty (mainUI);
	UI.CreateLabel (horzBombImplementationPhase).SetText ('Turn phase where bombs are executed');
	BombImplementationPhase = UI.CreateButton (horzBombImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase))).SetInteractable (false).SetColor (getColourCode ("minor heading"));

	local horzExplosivesCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzExplosivesCardPiecesNeeded).SetText ("Number of pieces to divide the card into").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	ExplosivesCardPiecesNeeded = UI.CreateNumberInputField (horzExplosivesCardPiecesNeeded).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.ExplosivesPiecesNeeded or 10).SetWholeNumbers (true).SetInteractable (false);

	local horzExplosivesCardStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzExplosivesCardStartPieces).SetText ("Pieces given to each player at the start").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	ExplosivesCardStartPieces = UI.CreateNumberInputField (horzExplosivesCardStartPieces).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.ExplosivesStartPieces or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzExplosivesCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzExplosivesCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	ExplosivesPiecesPerTurn = UI.CreateNumberInputField (horzExplosivesCardPiecesPerTurn).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.ExplosivesPiecesPerTurn or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzExplosivesCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzExplosivesCardWeight).SetText ("Card weight  (how common the card is)").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	ExplosivesCardWeight = UI.CreateNumberInputField (horzExplosivesCardWeight).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (false).SetValue (Mod.Settings.ExplosivesCardWeight or 1).SetInteractable (false);
end