require ('Bomb+ common');

function Client_PresentSettingsUI(rootParent)
	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);
	if (Mod.Settings.LandmineCastRange ~= nil) then UI.CreateLabel (mainUI).SetText("Cast range: " .. Mod.Settings.LandmineCastRange); UI.CreateLabel (mainUI).SetText("• distance from a territory the caster owns that landmines can be set\n"); end
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
	if (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == true) then UI.CreateLabel (mainUI).SetText ('  • a triggered landmine causing a territory to reduce to 0 armies will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	elseif (Mod.Settings.EmptyTerritoriesGoNeutral == true and Mod.Settings.SpecialUnitsPreventNeutral == false) then UI.CreateLabel (mainUI).SetText ('  • a triggered landmine causing a territory to reduce to 0 armies will turn neutral and you will lose control of any Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	else UI.CreateLabel (mainUI).SetText ('  • territories do not turn neutral when reduced to 0 armies or Special Units');
	end

	local horzCitiesDestroyedByLandminePlay = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzCitiesDestroyedByLandminePlay).SetText ('# cities destroyed by a triggered Landmine: ');
	NIFnumCitiesDestroyedByLandmine = UI.CreateNumberInputField (horzCitiesDestroyedByLandminePlay).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByLandminePlay).SetInteractable (false);
	if (tonumber (Mod.Settings.NumCitiesDestroyedByLandminePlay) == 0) then UI.CreateLabel (mainUI).SetText ("  · Landmines plays don't destroy cities");
	else UI.CreateLabel (mainUI).SetText ("  · this quantity of cities are destroyed when a Landmine is triggered is played");
	end

	local horzLandmineImplementationPhase = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateEmpty (mainUI);
	UI.CreateLabel (horzLandmineImplementationPhase).SetText ('Turn phase where landmines are executed');
	LandmineImplementationPhase = UI.CreateButton (horzLandmineImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.LandmineImplementationPhase))).SetInteractable (false).SetColor (getColourCode ("minor heading"));

	local horzLandminePlusCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandminePlusCardPiecesNeeded).SetText ("Number of pieces to divide the card into").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandminePlusCardPiecesNeeded = UI.CreateNumberInputField (horzLandminePlusCardPiecesNeeded).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandminePlusPiecesNeeded or 10).SetWholeNumbers (true).SetInteractable (false);

	local horzLandminePlusCardStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzLandminePlusCardStartPieces).SetText ("Pieces given to each player at the start").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandminePlusCardStartPieces = UI.CreateNumberInputField (horzLandminePlusCardStartPieces).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandminePlusStartPieces or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzLandminePlusCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandminePlusCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandminePlusPiecesPerTurn = UI.CreateNumberInputField (horzLandminePlusCardPiecesPerTurn).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandminePlusPiecesPerTurn or 1).SetWholeNumbers (true).SetInteractable (false);

	local horzLandminePlusCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandminePlusCardWeight).SetText ("Card weight  (how common the card is)").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandminePlusCardWeight = UI.CreateNumberInputField (horzLandminePlusCardWeight).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (false).SetValue (Mod.Settings.LandminePlusCardWeight or 1).SetInteractable (false);
end