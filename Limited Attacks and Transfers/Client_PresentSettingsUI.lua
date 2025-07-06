function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel(rootParent).SetText('Max # of attacks  : ' .. tostring (Mod.Settings.AttackLimit));
	UI.CreateLabel(rootParent).SetText('Max # of transfers: ' .. tostring (Mod.Settings.TransferLimit));
end

