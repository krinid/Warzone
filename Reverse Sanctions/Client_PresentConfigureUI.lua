function Client_PresentConfigureUI(rootParent)
	UIcontainer = rootParent;
	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetText ("Enables a 'Reverse Sanction Card' that has default behaviour of buffing a player's income. This can be used at the same time as the regular Sanction Card so you can have both positive and negative sanction effects in play in the same game.");

	ReverseSanctionCanPlayReverseSanctionsOnSelf = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
	ReverseSanctionCanPlayReverseSanctionsOnTeammates = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
	ReverseSanctionCanPlayReverseSanctionsOnEnemies = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
	ReverseSanctionCanPlayReverseSanctionsOnSelf = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
	ReverseSanctionCanPlayReverseSanctionsOnTeammates = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
	ReverseSanctionCanPlayReverseSanctionsOnEnemies = UI.CreateCheckBox(UIcontainer).SetFlexibleWidth (1).SetIsChecked(Mod.Settings.ReverseSanctionCanPlayReverseSanctionsOnSelf).SetInteractable(true).SetText("Can play Reverse Sanction card on self");
--allow regular sanction card plays on self, on team, on other
--allow reverse sanction card plays on self, on team, on other

	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetText ("• Positive % is an income buff to a player (opposite of the regular Sanction card) - play this on yourself or teammate");
	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetText ("    • eg: 50% --> increases income by 50% (1.5x) for the target of the card");
	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetText ("• Negative % is an income nerf to a player (opposite of the regular Sanction card) - play this on an enemy");
	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetText ("    • eg: -25% --> decreases income by 25% (0.75x) for the target of the card");

	if (Mod.Settings.ReverseSanctionPiecesNeeded == nil) then Mod.Settings.ReverseSanctionPiecesNeeded = 10; end;
	local horzReverseSanctionPiecesNeeded = UI.CreateHorizontalLayoutGroup (UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel (horzReverseSanctionPiecesNeeded).SetText("Number of pieces to divide the card into: ");
	ReverseSanctionPiecesNeeded = UI.CreateNumberInputField(horzReverseSanctionPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ReverseSanctionPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ReverseSanctionPiecesPerTurn
	if (Mod.Settings.ReverseSanctionPiecesPerTurn == nil) then Mod.Settings.ReverseSanctionPiecesPerTurn = 1; end
	local horzReverseSanctionPiecesPerTurn = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel (horzReverseSanctionPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
	ReverseSanctionPiecesPerTurn = UI.CreateNumberInputField(horzReverseSanctionPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ReverseSanctionPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ReverseSanctionStartPieces
	if (Mod.Settings.ReverseSanctionStartPieces == nil) then Mod.Settings.ReverseSanctionStartPieces = 1; end
	local horzReverseSanctionStartPieces = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel(horzReverseSanctionStartPieces).SetText("Pieces given to each player at the start: ");
	ReverseSanctionStartPieces = UI.CreateNumberInputField(horzReverseSanctionStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ReverseSanctionStartPieces).SetWholeNumbers(true).SetInteractable(true);

	-- Create UI elements for ReverseSanctionCardWeight
	if (Mod.Settings.ReverseSanctionCardWeight == nil) then Mod.Settings.ReverseSanctionCardWeight = 1.0; end
	local horzReverseSanctionCardWeight = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel(horzReverseSanctionCardWeight).SetText("Card weight (how common the card is): ");
	ReverseSanctionCardWeight = UI.CreateNumberInputField(horzReverseSanctionCardWeight).SetWholeNumbers(false).SetSliderMinValue(0.1).SetSliderMaxValue(5.0).SetValue(Mod.Settings.ReverseSanctionCardWeight).SetInteractable(true);
end