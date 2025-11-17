function Client_PresentConfigureUI(rootParent)
	local killPercentage = Mod.Settings.killPercentage;
	if killPercentage == nil then killPercentage = 25; end

	local delayed = Mod.Settings.delayed;
	if delayed == nil then delayed = false; end

	local armiesKilled = Mod.Settings.armiesKilled;
	if armiesKilled == nil then armiesKilled = 10; end

	local boolSpecialUnitsPreventNeutral = Mod.Settings.SpecialUnitsPreventNeutral;
	if (boolSpecialUnitsPreventNeutral == nil) then boolSpecialUnitsPreventNeutral = true; end

	if (Mod.Settings.BombImplementationPhase == nil) then Mod.Settings.BombImplementationPhase = WL.TurnPhase.BombCards; end

	local boolEmptyTerritoriesGoNeutral = Mod.Settings.EmptyTerritoriesGoNeutral;
	if (boolEmptyTerritoriesGoNeutral == nil) then boolEmptyTerritoriesGoNeutral = true; end

	if (Mod.Settings.NumCitiesDestroyedByBombPlay == nil) then Mod.Settings.NumCitiesDestroyedByBombPlay = 10; end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local row1 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row1).SetText('Damage (%): ');
    killPercentageInput = UI.CreateNumberInputField(row1).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(killPercentage);

	local row2 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row2).SetText('Fixed damage: ');
    armiesKilledInput = UI.CreateNumberInputField(row2).SetSliderMinValue(0).SetSliderMaxValue(25).SetValue(armiesKilled);

	UI.CreateLabel(vert).SetText('[% damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]');

	UI.CreateLabel (vert).SetText ("\n");
	UI.CreateEmpty (vert);
    cboxEmptyTerritoriesGoNeutral = UI.CreateCheckBox(UI.CreateHorizontalLayoutGroup(vert)).SetIsChecked(boolEmptyTerritoriesGoNeutral).SetText ("Territories reduced to 0 armies turn Neutral").SetIsChecked (boolEmptyTerritoriesGoNeutral);

	local row3 = UI.CreateHorizontalLayoutGroup(vert);
    specialUnitsInput = UI.CreateCheckBox(row3).SetIsChecked(boolSpecialUnitsPreventNeutral).SetText ("Special Units prevent territory from turning neutral");
	UI.CreateLabel(vert).SetText('  - when checked, a Bombed territory reduced to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	UI.CreateLabel(vert).SetText('  - when unchecked, a Bombed territory reduced to 0 will turn neutral, even if it has Special Units on it');

	local row4 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row4).SetText('# cities destroyed by a Bomb+ card play: ');
    NIFnumCitiesDestroyedByBomb = UI.CreateNumberInputField(row4).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue(Mod.Settings.NumCitiesDestroyedByBombPlay);
	UI.CreateLabel(vert).SetText("· Set to 0 = Bomb+ plays don't destroy cities");
	UI.CreateLabel(vert).SetText("· Set to >=1 = this quantity of cities are destroyed when a Bomb+ card is played");

	local row5 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateEmpty (vert);
	UI.CreateLabel(row5).SetText('Turn phase where bombs are executed: ');
	BombImplementationPhase = UI.CreateButton (row5).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase))).SetOnClick (Bomb_turnPhaseButton_clicked);

	local horzBombPlusCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (vert);
	UI.CreateLabel (horzBombPlusCardPiecesNeeded).SetText("Number of pieces to divide the card into: ");
	BombPlusCardPiecesNeeded = UI.CreateNumberInputField (horzBombPlusCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.BombPlusPiecesNeeded or 10).SetWholeNumbers(true).SetInteractable(true);

	local horzBombPlusCardStartPieces = UI.CreateHorizontalLayoutGroup (vert);
	UI.CreateLabel(horzBombPlusCardStartPieces).SetText("Pieces given to each player at the start: ");
	BombPlusCardStartPieces = UI.CreateNumberInputField (horzBombPlusCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.BombPlusStartPieces or 1).SetWholeNumbers(true).SetInteractable(true);

	local horzBombPlusCardPiecesPerTurn = UI.CreateHorizontalLayoutGroup (vert);
	UI.CreateLabel (horzBombPlusCardPiecesPerTurn).SetText ("Minimum pieces awarded per turn: ");
	BombPlusPiecesPerTurn = UI.CreateNumberInputField (horzBombPlusCardPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.BombPlusPiecesPerTurn or 1).SetWholeNumbers(true).SetInteractable(true);

	local horzBombPlusCardWeight = UI.CreateHorizontalLayoutGroup (vert);
	UI.CreateLabel (horzBombPlusCardWeight).SetText("Card weight: ");
	BombPlusCardWeight = UI.CreateNumberInputField(horzBombPlusCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.BombPlusCardWeight or 1).SetWholeNumbers(false).SetInteractable(true);
end

function Bomb_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	for k,v in pairs(WLturnPhases()) do
		print ("newObj item=="..k,v.."::");
		table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Bomb_turnPhase_selected({name=k,value=v}); end});
	end

	UI.PromptFromList ("Select turn phase where Bomb cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Bomb_turnPhase_selected (turnPhase)
	print ("turnPhase selected=="..tostring(turnPhase));
	print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	Mod.Settings.BombImplementationPhase = turnPhase.value;
	BombImplementationPhase.SetText (turnPhase.name);
end