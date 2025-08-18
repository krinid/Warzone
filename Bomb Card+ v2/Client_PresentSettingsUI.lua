function Client_PresentSettingsUI(rootParent)
	-- UI.CreateLabel(rootParent).SetText("BOMB DAMAGE % damage applied: " .. Mod.Settings.killPercentage.."%");
	UI.CreateLabel(rootParent).SetText("% damage applied: " .. Mod.Settings.killPercentage.."%");
	UI.CreateLabel(rootParent).SetText("Fixed damage applied: ".. Mod.Settings.armiesKilled);
	UI.CreateLabel(rootParent).SetText("  [ % damage applies first, then fixed damage applies ]");
	UI.CreateLabel(rootParent).SetText("  [ example: Bombing a territory with 100 armies reduces it to " ..tostring (math.min (math.floor (100*(1-Mod.Settings.killPercentage/100) - Mod.Settings.armiesKilled)).. " (100*" ..tostring (1-Mod.Settings.killPercentage/100)).."-"..Mod.Settings.armiesKilled..") ]");
	UI.CreateLabel(rootParent).SetText("\nTerritories reduced to 0 armies turn Neutral: " .. tostring (Mod.Settings.EmptyTerritoriesGoNeutral));
	UI.CreateLabel(rootParent).SetText("Special Units prevent territories turning Neutral: " .. tostring (Mod.Settings.SpecialUnitsPreventNeutral));
	if (Mod.Settings.delayed == false) then UI.CreateLabel(rootParent).SetText("Bombs are executed at: Start of turn (after deployments, before orders)");
	else UI.CreateLabel(rootParent).SetText("Bombs are executed at: End of turn (after all orders)"); end
end