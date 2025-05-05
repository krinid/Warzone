function Client_PresentSettingsUI(rootParent)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
    local UIcontainer = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("If you possess a whole card when your Commander dies, you are not eliminated, and you can play this card at the start of the following turn to resurrect your Commander to a territory of your choice. You don't need to play the card until your Commander dies.");

    local strRequiresCommanderDeath = "(can't be played until a Commander actually dies)";
	if (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies == false) then strRequiresCommanderDeath = "(can be played any time, you can create multiple Commanders if you possess multiple Resurrection cards)"; end
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("\nOnly usable when Commander dies: "..tostring (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies));
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText (strRequiresCommanderDeath);

	UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("\nNumber of pieces to divide the card into: "..Mod.Settings.ResurrectionPiecesNeeded);
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("Minimum pieces awarded per turn: "..Mod.Settings.ResurrectionPiecesPerTurn);
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("Pieces given to each player at the start: "..Mod.Settings.ResurrectionStartPieces);
    UI.CreateLabel (UIcontainer).SetFlexibleWidth (1).SetFlexibleWidth (1).SetText ("Card weight (how common the card is): "..Mod.Settings.ResurrectionCardWeight);
end