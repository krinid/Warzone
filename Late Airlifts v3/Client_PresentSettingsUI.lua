function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("Airlifts occur at the end of a turn rather than the beginning. All attack/transfer orders and other card players occur before airlifts happen.");

	UI.CreateLabel(root).SetText('\nNumber of Pieces to divide the card into: ' ..tostring (Mod.Settings.NumPieces));
	UI.CreateLabel(root).SetText('Card weight (how common the card is): ' ..tostring (Mod.Settings.CardWeight));
	UI.CreateLabel(root).SetText('Minimum pieces awarded per turn: ' ..tostring (Mod.Settings.MinPieces));
	UI.CreateLabel(root).SetText('Pieces given to each player at the start: ' ..tostring (Mod.Settings.InitialPieces));
end