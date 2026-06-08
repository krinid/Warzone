function Client_PresentSettingsUI(rootParent)
	UI.CreateCheckBox (rootParent).SetText ("Can gift whole cards").SetIsChecked (Mod.Settings.CanGiftWholeCards).SetInteractable (false);
    UI.CreateCheckBox (rootParent).SetText ("Can gift card pieces").SetIsChecked (Mod.Settings.CanGiftCardPieces).SetInteractable (false);
end