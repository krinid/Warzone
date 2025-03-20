function Client_PresentConfigureUI(rootParent)
	UIcontainer = rootParent;
	--UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("Creates a 'Resurrection' card whereby if you possess a whole card when your Commander dies, you can resurrect your Commander to a territory of your choice at the start of the next turn.");

	if (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies == nil) then Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies = true; end --indicates that Resurrection can't be played until a Commander actually dies; if set to False, then a player can create a Commander even if their existing Commander(s) haven't died, so long as they posses a Resurrection wholecard
	ResurrectionDisableCardPlayUntilCommanderDies = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies).SetInteractable(true).SetText("Only usable when Commander dies");

	if (Mod.Settings.ResurrectionPiecesNeeded == nil) then Mod.Settings.ResurrectionPiecesNeeded = 10; end;
	local horzResurrectionPiecesNeeded = UI.CreateHorizontalLayoutGroup (UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel (horzResurrectionPiecesNeeded).SetText("Number of pieces to divide the card into: ");
	ResurrectionPiecesNeeded = UI.CreateNumberInputField(horzResurrectionPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ResurrectionPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ResurrectionPiecesPerTurn
	if (Mod.Settings.ResurrectionPiecesPerTurn == nil) then Mod.Settings.ResurrectionPiecesPerTurn = 1; end
	local horzResurrectionPiecesPerTurn = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel (horzResurrectionPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
	ResurrectionPiecesPerTurn = UI.CreateNumberInputField(horzResurrectionPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ResurrectionPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ResurrectionStartPieces
	if (Mod.Settings.ResurrectionStartPieces == nil) then Mod.Settings.ResurrectionStartPieces = 1; end
	local horzResurrectionStartPieces = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel(horzResurrectionStartPieces).SetText("Pieces given to each player at the start: ");
	ResurrectionStartPieces = UI.CreateNumberInputField(horzResurrectionStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ResurrectionStartPieces).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ResurrectionCardWeight
	if (Mod.Settings.ResurrectionCardWeight == nil) then Mod.Settings.ResurrectionCardWeight = 1.0; end
	local horzResurrectionCardWeight = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel(horzResurrectionCardWeight).SetText("Card weight (how common the card is): ");
	ResurrectionCardWeight = UI.CreateNumberInputField(horzResurrectionCardWeight).SetWholeNumbers(false).SetSliderMinValue(0.1).SetSliderMaxValue(5.0).SetValue(Mod.Settings.ResurrectionCardWeight).SetInteractable(true);
end