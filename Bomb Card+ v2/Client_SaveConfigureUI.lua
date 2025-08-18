function Client_SaveConfigureUI (alert)
	local killPercentage = killPercentageInput.GetValue();
	-- if killPercentage < 0 or killPercentage > 100 then alert ('The kill percentage must be set between 1 to 100'); end
	-- if killPercentage > 100 then alert ('The kill percentage must be <=100'); end
	Mod.Settings.killPercentage = killPercentage;
	--just use the %; >100% will have no effect; <0% will actually heal

	local delayed = cboxBombPhaseDelayed.GetIsChecked();
	if (delayed == nil) then delayed = false; end
    Mod.Settings.delayed = delayed;

	local armiesKilled = armiesKilledInput.GetValue();

	--don't limit this; allow >1000 and negative bomb values; "healing bombs" in essence
	--if armiesKilled < 0 or armiesKilled > 1000 then alert('Armies killed must be set between 0 to 1000'); end
    Mod.Settings.armiesKilled = armiesKilled;

	Mod.Settings.EmptyTerritoriesGoNeutral = cboxEmptyTerritoriesGoNeutral.GetIsChecked();

	local specialUnits = specialUnitsInput.GetIsChecked();
	Mod.Settings.SpecialUnitsPreventNeutral = specialUnits;
	-- Mod.Settings.BombImplementationPhase = BombImplementationPhase.GetText();
end