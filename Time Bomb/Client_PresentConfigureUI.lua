function Client_PresentConfigureUI (rootParent)
	Mod.Settings.ArmyDamagePercent = Mod.Settings.ArmyDamagePercent ~= nil and Mod.Settings.ArmyDamagePercent or 25;
	Mod.Settings.ArmyDamageFixed = Mod.Settings.ArmyDamageFixed ~= nil and Mod.Settings.ArmyDamageFixed or 10;
	Mod.Settings.SUdamagePercent = Mod.Settings.SUdamagePercent ~= nil and Mod.Settings.SUdamagePercent or 25;
	Mod.Settings.SUdamageFixed = Mod.Settings.SUdamageFixed ~= nil and Mod.Settings.SUdamageFixed or 10;
	Mod.Settings.SpecialUnitsPreventNeutral = Mod.Settings.SpecialUnitsPreventNeutral ~= nil and Mod.Settings.SpecialUnitsPreventNeutral or true;
	Mod.Settings.BombImplementationPhase = Mod.Settings.BombImplementationPhase ~= nil and Mod.Settings.BombImplementationPhase or WL.TurnPhase.BombCards;
	Mod.Settings.EmptyTerritoriesGoNeutral = Mod.Settings.EmptyTerritoriesGoNeutral ~= nil and Mod.Settings.EmptyTerritoriesGoNeutral or true;
	Mod.Settings.NumCitiesDestroyedByBombPlay = Mod.Settings.NumCitiesDestroyedByBombPlay ~= nil and Mod.Settings.NumCitiesDestroyedByBombPlay or 10;
	Mod.Settings.TimeBombCastRange = Mod.Settings.TimeBombCastRange or 3; --default to 3

	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);

	local horzTimeBombCastRange = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombCastRange).SetText ("Cast range: ").SetPreferredWidth (300);
	NIFcastRange = UI.CreateNumberInputField (horzTimeBombCastRange).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.TimeBombCastRange);
	UI.CreateLabel (mainUI).SetText("  • how far a TimeBomb can be placed from a territory you own\n");

	local horzArmyDamage = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzArmyDamage).SetText ("Army Damage - ").SetColor ("#FFFF00");
	UI.CreateLabel (horzArmyDamage).SetText ('Damage (%): ');
	NIFarmyDamagePercent = UI.CreateNumberInputField (horzArmyDamage).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.ArmyDamagePercent);
	-- local horzArmyDamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel (horzArmyDamage).SetText ('  Fixed damage: ');
	NIFarmyDamageFixed = UI.CreateNumberInputField (horzArmyDamage).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.ArmyDamageFixed);
	UI.CreateLabel (mainUI).SetText ('[% damage is applied first, then fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]');

	local horzSUdamage = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel (horzSUdamage).SetText ("SU Damage - ").SetColor ("#FFFF00");
	UI.CreateLabel(horzSUdamage).SetText ('Damage (%): ');
	NIF_SUdamagePercent = UI.CreateNumberInputField (horzSUdamage).SetSliderMinValue (0).SetSliderMaxValue (100).SetValue (Mod.Settings.SUdamagePercent);
	-- local horzSUdamageFixed = UI.CreateHorizontalLayoutGroup(mainUI);
	UI.CreateLabel(horzSUdamage).SetText ('Fixed damage: ');
	NIF_SUdamageFixed = UI.CreateNumberInputField (horzSUdamage).SetSliderMinValue (0).SetSliderMaxValue (25).SetValue (Mod.Settings.SUdamageFixed);
	UI.CreateLabel (mainUI).SetText ('[% damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]');

	UI.CreateLabel (mainUI).SetText ("\n");
	UI.CreateEmpty (mainUI);
	cboxEmptyTerritoriesGoNeutral = UI.CreateCheckBox (UI.CreateHorizontalLayoutGroup (mainUI)).SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral).SetText ("Territories reduced to 0 armies turn Neutral").SetIsChecked (Mod.Settings.EmptyTerritoriesGoNeutral);
	NIF_SUsPreventNeutral = UI.CreateCheckBox (mainUI).SetIsChecked (Mod.Settings.SpecialUnitsPreventNeutral).SetText ("Special Units prevent territory from turning neutral");
	UI.CreateLabel (mainUI).SetText ('  • when checked, a Bombed territory reduced to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	UI.CreateLabel (mainUI).SetText ('  • when unchecked, a Bombed territory reduced to 0 will turn neutral, even if it has Special Units on it');
	UI.CreateLabel (mainUI).SetText ('  • unless you have a specific mechanic in mind for your template, leave this checked');

	local horzCitiesDestroyedByBombPlay = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzCitiesDestroyedByBombPlay).SetText ('# cities destroyed by a Bomb+ card play: ');
	NIFnumCitiesDestroyedByBomb = UI.CreateNumberInputField (horzCitiesDestroyedByBombPlay).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByBombPlay);
	UI.CreateLabel (mainUI).SetText ("  · Set to 0 = Bomb+ plays don't destroy cities");
	UI.CreateLabel (mainUI).SetText ("  · Set to >=1 = this quantity of cities are destroyed when a Bomb+ card is played");

	local horzBombImplementationPhase = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateEmpty (mainUI);
	UI.CreateLabel (horzBombImplementationPhase).SetText ('Turn phase where bombs are executed: ');
	BombImplementationPhase = UI.CreateButton (horzBombImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase))).SetOnClick (Bomb_turnPhaseButton_clicked);

	local horzTimeBombCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombCardPiecesNeeded).SetText("Number of pieces to divide the card into: ");
	TimeBombCardPiecesNeeded = UI.CreateNumberInputField (horzTimeBombCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TimeBombPiecesNeeded or 10).SetWholeNumbers(true).SetInteractable(true);

	local horzTimeBombCardStartPieces = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel(horzTimeBombCardStartPieces).SetText("Pieces given to each player at the start: ");
	TimeBombCardStartPieces = UI.CreateNumberInputField (horzTimeBombCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TimeBombStartPieces or 1).SetWholeNumbers(true).SetInteractable(true);

	local horzTimeBombCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn: ");
	TimeBombPiecesPerTurn = UI.CreateNumberInputField (horzTimeBombCardPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TimeBombPiecesPerTurn or 1).SetWholeNumbers(true).SetInteractable(true);

	local horzTimeBombCardWeight = UI.CreateHorizontalLayoutGroup (mainUI);
	UI.CreateLabel (horzTimeBombCardWeight).SetText("Card weight: ");
	TimeBombCardWeight = UI.CreateNumberInputField(horzTimeBombCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetWholeNumbers(false).SetValue(Mod.Settings.TimeBombCardWeight or 1).SetInteractable(true);
end

function Bomb_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	for k,v in pairs (WLturnPhases()) do
		-- print ("newObj item=="..k,v.."::");
		table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Bomb_turnPhase_selected ({name=k,value=v}); end});
	end

	UI.PromptFromList ("Select turn phase where Bomb cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Bomb_turnPhase_selected (turnPhase)
	-- print ("turnPhase selected=="..tostring(turnPhase));
	-- print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	Mod.Settings.BombImplementationPhase = turnPhase.value;
	BombImplementationPhase.SetText (turnPhase.name);
end