function Client_SaveConfigureUI(alert)
	Mod.Settings.NumPortals = numberInputField.GetValue()
	if (Mod.Settings.NumPortals < 1) then
		Mod.Settings.NumPortals = 1
	end

	if (Mod.Settings.NumPortals > 10) then
		Mod.Settings.NumPortals = 10
	end
end
