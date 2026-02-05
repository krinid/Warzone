function Client_PresentSettingsUI(root)
	UI.CreateLabel(root).SetText('Duration for smoke bomb effect: ' ..tostring (Mod.Settings.Duration) .. "      (# of turns the fog remains)");
	-- UI.CreateLabel(root).SetText('Duration for smoke bomb effect: ' ..tostring (Mod.Settings.Duration));
	-- UI.CreateLabel(root).SetText('  (# of turns the fog remains)');
	UI.CreateLabel(root).SetText('Range for smoke bomb effect: ' ..tostring (Mod.Settings.Range));
	-- UI.CreateLabel(root).SetText('Range for smoke bomb effect: ' ..tostring (Mod.Settings.Range).. '      (# of territories the fog spreads; 0=targeted territory only, 1=spreads to directly bordering territories, etc)');
	UI.CreateLabel(root).SetText('  (# of territories the fog spreads; 0=targeted territory only, 1=spreads to directly bordering territories, etc)');
	UI.CreateLabel(root).SetText('\nNumber of Pieces to divide the card into: ' ..tostring (Mod.Settings.NumPieces));
	UI.CreateLabel(root).SetText('Card weight (how common the card is): ' ..tostring (Mod.Settings.CardWeight));
	UI.CreateLabel(root).SetText('Minimum pieces awarded per turn: ' ..tostring (Mod.Settings.MinPieces));
	UI.CreateLabel(root).SetText('Pieces given to each player at the start: ' ..tostring (Mod.Settings.InitialPieces));
end