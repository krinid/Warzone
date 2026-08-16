function Client_PresentSettingsUI (rootParent)
	if (Mod.Settings.SimpleConfig ~= nil) then
		UI.CreateLabel (rootParent).SetText("Running in Simple Config mode, variant " ..tostring (Mod.Settings.SimpleConfig));
		if (tonumber (Mod.Settings.SimpleConfig) == 10) then
			UI.CreateLabel (rootParent).SetText("\nWhen game starts, each player will receive the following Special Units on a random territory:\n• 1x Super Recruiter\n• 1x Super Worker\n• 1x Super Tank\n• 1x Super Phantom");
		end
	end
end