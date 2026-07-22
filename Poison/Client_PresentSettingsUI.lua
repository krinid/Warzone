function Client_PresentSettingsUI (rootParent)
	local UImain = rootParent;
	-- UI.CreateLabel (UImain).SetText("[POISON]").SetColor("#00FFFF");
	UI.CreateLabel (UImain).SetText("Duration: " .. Mod.Settings.PoisonDuration);
	UI.CreateLabel (UImain).SetText("Damage - Armies - Fixed amount: " .. Mod.Settings.PoisonDamageFixedArmies);
	UI.CreateLabel (UImain).SetText("Damage - Armies - Percentage: " .. Mod.Settings.PoisonDamagePercentArmies .."%");
	UI.CreateLabel (UImain).SetText("Damage - Special Units - Fixed amount: " .. Mod.Settings.PoisonDamageFixedSpecialUnits);
	UI.CreateLabel (UImain).SetText("Damage - Special Units - Percentage: " .. Mod.Settings.PoisonDamagePercentSpecialUnits .."%");
	if (Mod.Settings.PoisonDamageRange ~= nil) then UI.CreateLabel (UImain).SetText("\nImpact range: " .. Mod.Settings.PoisonDamageRange); end --old variable name, not used anymore, after existing games using it end, can remove this
	if (Mod.Settings.PoisonImpactRange ~= nil) then UI.CreateLabel (UImain).SetText("\nImpact range: " .. Mod.Settings.PoisonImpactRange); end
	UI.CreateLabel (UImain).SetText("  • how many neighbouring territories the poison will spread to upon impact");
	if (Mod.Settings.PoisonSpreadRange ~= nil) then UI.CreateLabel (UImain).SetText("Spread range: " .. Mod.Settings.PoisonSpreadRange); UI.CreateLabel (UImain).SetText ("  • how many neighbouring territories the poison can spread to if carried"); end

	UI.CreateEmpty (UImain);
	UI.CreateLabel (UImain).SetText ("_").SetColor ("#000000");
	UI.CreateCheckBox (UImain).SetIsChecked (Mod.Settings.PoisonDamageAffectsAllAbilities).SetText ("Affects all Special Unit properties").SetInteractable (false);
	-- UI.CreateLabel (UImain).SetText("Affects all Special Unit properties: " .. tostring (Mod.Settings.PoisonDamageAffectsAllAbilities or false));
	if (Mod.Settings.PoisonDamageAffectsAllAbilities == true) then UI.CreateLabel (UImain).SetText ("  • when checked, SU Attack+DefensePower, Attack+DefensePower%, DamageAbsorption are also reduced by Poison effects");
	else UI.CreateLabel (UImain).SetText ("  • when unchecked, only Health or Damage To Kill properties are reduced by Poison effects");
	end

	-- UI.CreateLabel (UImain).SetText("Poison affects other mods: " .. tostring (Mod.Settings.PoisonAffectsOtherModAbilities or false));
    UI.CreateCheckBox (UImain).SetIsChecked (Mod.Settings.PoisonAffectsOtherModAbilities).SetText ("Poison affects other mods").SetInteractable (false);
	if (Mod.Settings.PoisonAffectsOtherModAbilities == true) then UI.CreateLabel (UImain).SetText ("  • other mods (eg: Pestilence, Nuke, Bomb+, etc) can also cause Poison effects");
	else UI.CreateLabel (UImain).SetText ("  • Poison effects will only impact units directly resulting from playing of Poison cards");
	end

	UI.CreateLabel (UImain).SetText ("\n# cities destroyed by Poison: ".. tostring (Mod.Settings.NumCitiesDestroyedByPoison ~= nil and Mod.Settings.NumCitiesDestroyedByPoison or 0));
	if (Mod.Settings.NumCitiesDestroyedByPoison ~= nil) then UI.CreateLabel (UImain).SetText ("Cities are destroyed: " .. tostring (Mod.Settings.CitiesAreDestroyedEachTurn and "Each turn Poison is active" or "On first Poison impact turn only")); end

	UI.CreateLabel (UImain).SetText("\nNumber of pieces to divide the card into: " .. Mod.Settings.PoisonPiecesNeeded);
	UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PoisonStartPieces);
	UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PoisonPiecesPerTurn);
	UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PoisonCardWeight);
end