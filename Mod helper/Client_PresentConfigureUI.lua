function Client_PresentConfigureUI(rootParent)
    local horz = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (horz).SetText ('Starting turn for eliminations\n(first turn a player will be eliminated)').SetPreferredWidth(290);
    EliminationStartTurn = UI.CreateNumberInputField (horz).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.EliminationStartTurn or 5);

    local horz = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (horz).SetText ('Frequency for eliminations\n(# of turns before each additional player is eliminated)').SetPreferredWidth(290);
    EliminationTurnFrequency = UI.CreateNumberInputField (horz).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.EliminationTurnFrequency or 5);
end