function Client_PresentSettingsUI(rootParent)
	-- UI.CreateLabel(rootParent).SetText("BOMB DAMAGE % damage applied: " .. Mod.Settings.killPercentage.."%");
	UI.CreateLabel(rootParent).SetText("% damage applied: " .. Mod.Settings.killPercentage.."%");
	UI.CreateLabel(rootParent).SetText("Fixed damage applied: ".. Mod.Settings.armiesKilled);
	UI.CreateLabel(rootParent).SetText("  [ % damage applies first, then fixed damage applies ]");
	UI.CreateLabel(rootParent).SetText("  [ example: Bombing a territory with 100 armies reduces it to " ..tostring (math.min (math.floor (100*(1-Mod.Settings.killPercentage/100) - Mod.Settings.armiesKilled)).. " (100*" ..tostring (1-Mod.Settings.killPercentage/100)).."-"..Mod.Settings.armiesKilled..") ]");
	UI.CreateLabel(rootParent).SetText("\nTerritories reduced to 0 armies turn Neutral: " .. tostring (Mod.Settings.EmptyTerritoriesGoNeutral));
	UI.CreateLabel(rootParent).SetText("Special Units prevent territories turning Neutral: " .. tostring (Mod.Settings.SpecialUnitsPreventNeutral));
	UI.CreateLabel(rootParent).SetText("# of cities that Bomb+ card plays destroy: " ..tostring (Mod.Settings.NumCitiesDestroyedByBombPlay));

	-- UI.CreateLabel(rootParent).SetText("BombImplementationPhase " ..tostring (Mod.Settings.BombImplementationPhase).. ", " ..tostring (Mod.Settings.delayed));

	--if Turn Phase option is set in Mod.Settings, use that; otherwise revert to Mod.Settings.delayed where true==BombCards and false==ReceiveCards turn phases respectively
	UI.CreateLabel(rootParent).SetText("Bomb+ cards are executed in: '" .. (tostring (WL.TurnPhase.ToString (tonumber ((Mod.Settings.BombImplementationPhase ~= nil and Mod.Settings.BombImplementationPhase) or (Mod.Settings.delayed ~= nil and Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards))))).. "' turn phase");

	-- UI.CreateLabel(rootParent).SetText("Bomb+ cards are executed in: '" .. (tostring (WL.TurnPhase.ToString ((tonumber (Mod.Settings.BombImplementationPhase) ~= nil) and Mod.Settings.BombImplementationPhase) or (Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards))).. "' turn phase");
	-- UI.CreateLabel(rootParent).SetText("Bomb+ cards are executed in: '" .. (tostring (WL.TurnPhase.ToString ((tonumber (Mod.Settings.BombImplementationPhase) ~= nil) and Mod.Settings.BombImplementationPhase) or (Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards))).. "' turn phase");
end