function Client_PresentSettingsUI (rootParent)
	local UImain = rootParent;
	-- UI.CreateLabel (UImain).SetText("[POISON]").SetColor("#00FFFF");
	UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.PoisonPiecesNeeded);
	UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PoisonStartPieces);
	UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PoisonPiecesPerTurn);
	UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PoisonCardWeight);
	UI.CreateLabel (UImain).SetText("Duration: " .. Mod.Settings.PoisonDuration);
	UI.CreateLabel (UImain).SetText("Damage - Armies - Fixed amount: " .. Mod.Settings.PoisonDamageFixedArmies);
	UI.CreateLabel (UImain).SetText("Damage - Armies - Percentage: " .. Mod.Settings.PoisonDamagePercentArmies);
	UI.CreateLabel (UImain).SetText("Damage - Special Units - Fixed amount: " .. Mod.Settings.PoisonDamageFixedSpecialUnits);
	UI.CreateLabel (UImain).SetText("Damage - Special Units - Percentage: " .. Mod.Settings.PoisonDamagePercentSpecialUnits);
	UI.CreateLabel (UImain).SetText("Range: " .. Mod.Settings.PoisonDamageRange);
	UI.CreateLabel (UImain).SetText("Affects all abilities: " .. tostring (Mod.Settings.PoisonDamageAffectsAllAbilities));
	UI.CreateLabel (UImain).SetText("Poison affects other mods: " .. tostring (Mod.Settings.PoisonAffectsOtherModAbilities));
end