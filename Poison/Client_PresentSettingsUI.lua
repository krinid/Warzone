function Client_PresentSettingsUI(rootParent)
        UI.CreateLabel (UImain).SetText("[NUKE]").SetColor("#00FFFF");

		UI.CreateLabel (UImain).SetText("Poison affects other mods: " .. tostring (Mod.Settings.PoisonAffectsOtherModAbilities));
end