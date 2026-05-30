function Client_PresentConfigureUI (rootParent)
	rootParentobj = rootParent;
	local mainUI = UI.CreateVerticalLayoutGroup (rootParent);

	-- UI.CreateLabel(rootParentobj).SetText("Card prices are set by the host once the game starts\n");
	local boolCanGiftWholeCards = Mod.Settings.CanGiftWholeCards ~= nil and Mod.Settings.CanGiftWholeCards or Mod.Settings.CanGiftWholeCards == nil and true; --default to true if not set
	local boolCanGiftCardPieces = Mod.Settings.CanGiftCardPieces ~= nil and Mod.Settings.CanGiftCardPieces or Mod.Settings.CanGiftCardPieces == nil and true; --default to true if not set

	-- local rowMaxBuyableCards = UI.CreateHorizontalLayoutGroup(vert);
    disallowDeploymentsInput = CreateCheckBox (mainUI).SetText ("Can gift whole cards").SetIsChecked (boolCanGiftWholeCards);
    disallowDeploymentsInput = CreateCheckBox (mainUI).SetText ("Can gift card pieces").SetIsChecked (boolCanGiftCardPieces);
end