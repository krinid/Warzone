require ('Bomb+ common');

function Client_PresentConfigureUI (rootParent)
	Mod.Settings.ArmyDamagePercent = Mod.Settings.ArmyDamagePercent ~= nil and Mod.Settings.ArmyDamagePercent or 25;
	Mod.Settings.ArmyDamageFixed = Mod.Settings.ArmyDamageFixed ~= nil and Mod.Settings.ArmyDamageFixed or 10;
	Mod.Settings.SUdamagePercent = Mod.Settings.SUdamagePercent ~= nil and Mod.Settings.SUdamagePercent or 25;
	Mod.Settings.SUdamageFixed = Mod.Settings.SUdamageFixed ~= nil and Mod.Settings.SUdamageFixed or 10;
	Mod.Settings.SpecialUnitsPreventNeutral = Mod.Settings.SpecialUnitsPreventNeutral == nil and true or Mod.Settings.SpecialUnitsPreventNeutral;
	Mod.Settings.EmptyTerritoriesGoNeutral = Mod.Settings.EmptyTerritoriesGoNeutral == nil and true or Mod.Settings.EmptyTerritoriesGoNeutral;
	Mod.Settings.BombImplementationPhase = Mod.Settings.BombImplementationPhase ~= nil and Mod.Settings.BombImplementationPhase or WL.TurnPhase.BombCards;
	Mod.Settings.NumCitiesDestroyedByLandminePlay = Mod.Settings.NumCitiesDestroyedByLandminePlay ~= nil and Mod.Settings.NumCitiesDestroyedByLandminePlay or 10;
	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);

	-- UI.CreateLabel (mainUI).SetText ("[Army Damage]").SetColor ("#FFFF00");
	-- local horzArmyDamage = UI.CreateHorizontalLayoutGroup (mainUI);
	-- UI.CreateLabel (horzArmyDamage).SetText ('Percent (%): ');
	-- NIFarmyDamagePercent = UI.CreateNumberInputField (horzArmyDamage).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.ArmyDamagePercent);
	-- -- local horzArmyDamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	-- UI.CreateLabel (horzArmyDamage).SetText ('  Fixed: ');
	-- NIFarmyDamageFixed = UI.CreateNumberInputField (horzArmyDamage).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.ArmyDamageFixed);
	-- UI.CreateLabel (mainUI).SetText ('• % damage is applied first, then fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)');

	Mod.Settings.LandmineCastRange = Mod.Settings.LandmineCastRange or 3; --default to 3

	local horzLandmineCastRange = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandmineCastRange).SetText ("Cast range: ").SetPreferredWidth (300);
	NIFcastRange = UI.CreateNumberInputField (horzLandmineCastRange).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.LandmineCastRange);
	UI.CreateLabel (mainUI).SetText("  • how far a Landmine can be placed from a territory you own\n");

	local vertArmyDamage = UI.CreateVerticalLayoutGroup (mainUI);
	local horzArmyDamage1 = UI.CreateHorizontalLayoutGroup (vertArmyDamage).SetFlexibleWidth(1);
	local horzArmyDamage2 = UI.CreateHorizontalLayoutGroup (vertArmyDamage).SetFlexibleWidth(1);
	UI.CreateLabel (horzArmyDamage1).SetText ("[Army Damage]").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel (horzArmyDamage1).SetText ('Percent (%): ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIFarmyDamagePercent = UI.CreateNumberInputField (horzArmyDamage1).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.ArmyDamagePercent).SetPreferredWidth (150);
	-- local horzArmyDamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel (horzArmyDamage2).SetText ("").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel (horzArmyDamage2).SetText ('Fixed: ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIFarmyDamageFixed = UI.CreateNumberInputField (horzArmyDamage2).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.ArmyDamageFixed).SetPreferredWidth (150);
	UI.CreateLabel (mainUI).SetText ('• % damage is applied first, then fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)');

	local vertSUdamage = UI.CreateVerticalLayoutGroup (mainUI);
	local horzSUdamage1 = UI.CreateHorizontalLayoutGroup (vertSUdamage).SetFlexibleWidth(1);
	local horzSUdamage2 = UI.CreateHorizontalLayoutGroup (vertSUdamage).SetFlexibleWidth(1);
	UI.CreateLabel (horzSUdamage1).SetText ("[Special Unit Damage]").SetColor ("#FFFF00").SetPreferredWidth (150);
	UI.CreateLabel(horzSUdamage1).SetText ('Percent (%): ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIF_SUdamagePercent = UI.CreateNumberInputField (horzSUdamage1).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.SUdamagePercent);
	UI.CreateLabel (horzSUdamage2).SetText ("").SetColor ("#FFFF00").SetPreferredWidth (150);
	-- local horzSUdamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel(horzSUdamage2).SetText ('Fixed: ').SetPreferredWidth (100).SetAlignment (WL.TextAlignmentOptions.Right);
	NIF_SUdamageFixed = UI.CreateNumberInputField (horzSUdamage2).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.SUdamageFixed);
	UI.CreateLabel (mainUI).SetText ('• % damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)');

	UI.CreateLabel (mainUI).SetText ("\n");
	UI.CreateEmpty (mainUI);
	cboxEmptyTerritoriesGoNeutral = UI.CreateCheckBox (mainUI).SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral).SetText ("Territories reduced to 0 armies turn Neutral").SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral);
	NIF_SUsPreventNeutral = UI.CreateCheckBox (mainUI).SetIsChecked (Mod.Settings.SpecialUnitsPreventNeutral).SetText ("Special Units prevent territory from turning neutral");
	UI.CreateLabel (mainUI).SetText ('  • when checked, a triggered landmine reducing a territory to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	UI.CreateLabel (mainUI).SetText ('  • when unchecked, a triggered landmine reducing a territory to 0 will turn neutral, even if it has Special Units on it');
	UI.CreateLabel (mainUI).SetText ('  • unless you have a specific mechanic in mind for your template, leave this checked');

	local horzCitiesDestroyedByLandminePlay = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzCitiesDestroyedByLandminePlay).SetText ('# cities destroyed by a triggered landmine: ');
	NIFnumCitiesDestroyedByLandmine = UI.CreateNumberInputField (horzCitiesDestroyedByLandminePlay).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByLandminePlay);
	UI.CreateLabel (mainUI).SetText ("  · Set to 0 = landmines don't destroy cities");
	UI.CreateLabel (mainUI).SetText ("  · Set to >=1 = this quantity of cities are destroyed when a landmine is triggered");

	local horzLandmineImplementationPhase = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateEmpty (mainUI);
	UI.CreateLabel (horzLandmineImplementationPhase).SetText ('Turn phase where landmine plays are executed');
	LandmineImplementationPhase = UI.CreateButton (horzLandmineImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase))).SetOnClick (Bomb_turnPhaseButton_clicked);

	local horzLandmineCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandmineCardPiecesNeeded).SetText ("Number of pieces to divide the card into").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandmineCardPiecesNeeded = UI.CreateNumberInputField (horzLandmineCardPiecesNeeded).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandminePiecesNeeded or 10).SetWholeNumbers (true).SetInteractable (true);

	local horzLandmineCardStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzLandmineCardStartPieces).SetText ("Pieces given to each player at the start").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandmineCardStartPieces = UI.CreateNumberInputField (horzLandmineCardStartPieces).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandmineStartPieces or 1).SetWholeNumbers (true).SetInteractable (true);

	local horzLandmineCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandmineCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandminePiecesPerTurn = UI.CreateNumberInputField (horzLandmineCardPiecesPerTurn).SetSliderMinValue (1).SetSliderMaxValue (10).SetValue (Mod.Settings.LandminePiecesPerTurn or 1).SetWholeNumbers (true).SetInteractable (true);

	local horzLandmineCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzLandmineCardWeight).SetText ("Card weight  (how common the card is)").SetPreferredWidth (290).SetAlignment (WL.TextAlignmentOptions.Left);
	LandmineCardWeight = UI.CreateNumberInputField (horzLandmineCardWeight).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (false).SetValue (Mod.Settings.LandmineCardWeight or 1).SetInteractable (true);
end

function Bomb_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	for k,v in pairs (WLturnPhases()) do
		-- print ("newObj item=="..k,v.."::");
		table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Bomb_turnPhase_selected ({name=k,value=v}); end});
	end

	UI.PromptFromList ("Select turn phase where Landmine cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Bomb_turnPhase_selected (turnPhase)
	-- print ("turnPhase selected=="..tostring(turnPhase));
	-- print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	Mod.Settings.BombImplementationPhase = turnPhase.value;
	LandmineImplementationPhase.SetText (turnPhase.name);
end