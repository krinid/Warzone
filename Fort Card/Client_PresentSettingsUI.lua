function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel(rootParent).SetText("Forts are built at the end of a turn. They block all incoming damage from 1 attack, then the fort is destroyed. Attackers still takes damage normally from the defender's units.");
	UI.CreateLabel(rootParent).SetText('\n• Number of Pieces to divide the card into: ' .. tostring (Mod.Settings.NumPieces or 4)).SetFlexibleWidth(1);
    UI.CreateLabel(rootParent).SetText('• Card weight (how common the card is): ' ..tostring (Mod.Settings.Weight or 1.0)).SetFlexibleWidth(1);
    UI.CreateLabel(rootParent).SetText('• Minimum pieces awarded per turn: ' ..tostring (Mod.Settings.MinPieces or 1)).SetFlexibleWidth(1);
    UI.CreateLabel(rootParent).SetText('• Pieces given to each player at the start: ' ..tostring (Mod.Settings.InitialPieces or 5)).SetFlexibleWidth(1);
end