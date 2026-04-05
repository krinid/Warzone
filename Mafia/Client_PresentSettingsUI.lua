function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("\nStarting turn for eliminations: " ..tostring (Mod.Settings.EliminationStartTurn).. "  (first turn a player will be eliminated)");
	UI.CreateLabel (rootParent).SetText ("Frequency for eliminations: " ..tostring (Mod.Settings.EliminationTurnFrequency).. "  (# of turns before each additional player is eliminated)");
end