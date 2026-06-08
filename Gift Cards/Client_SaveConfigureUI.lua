
function Client_SaveConfigureUI (alert)
	Mod.Settings.CanGiftWholeCards = cboxCanGiftWholeCards.GetIsChecked ();
	Mod.Settings.CanGiftCardPieces = cboxCanGiftCardPieces.GetIsChecked ();

	if (Mod.Settings.CanGiftCardPieces == false and Mod.Settings.CanGiftWholeCards == false) then
		alert ("[GIFT CARDS] At least one of 'Can gift whole cards' or 'Can gift card pieces' must be enabled, else this mod would do nothing");
		return false;
	end
end