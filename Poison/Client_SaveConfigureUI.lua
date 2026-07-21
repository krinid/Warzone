function Client_SaveConfigureUI (alert, addCard)
-- 	Mod.Settings.PoisonPiecesNeeded = Mod.Settings.PoisonPiecesNeeded or 10; --default to 10 if not set yet
-- 	Mod.Settings.PoisonPiecesPerTurn = Mod.Settings.PoisonPiecesPerTurn or 1; --default to 1 if not set yet
-- 	Mod.Settings.PoisonStartPieces = Mod.Settings.PoisonStartPieces or 1; --default to 1 if not set yet
-- 	Mod.Settings.PoisonCardWeight = Mod.Settings.PoisonCardWeight or 1; --default to 1 if not set yet
-- 	Mod.Settings.PoisonDuration = Mod.Settings.PoisonDuration or 3; --default to 3 if not set yet

-- 	Mod.Settings.PoisonDamageFixedArmies = Mod.Settings.PoisonDamageFixedArmies or 10; --1; --default to 1
-- 	Mod.Settings.PoisonDamagePercentArmies = Mod.Settings.PoisonDamagePercentArmies or 0.25; --0; --default to 0
-- 	Mod.Settings.PoisonDamageFixedSpecialUnits = Mod.Settings.PoisonDamageFixedSpecialUnits or 5; --default to 0
-- 	Mod.Settings.PoisonDamagePercentSpecialUnits = Mod.Settings.PoisonDamagePercentSpecialUnits or 10; --default to 10%
-- 	Mod.Settings.PoisonDamageRange = Mod.Settings.PoisonDamageRange or 1; --default to 1 (doesn't spread)
-- 	Mod.Settings.PoisonDamageAffectsAllAbilities = Mod.Settings.PoisonDamageAffectsAllAbilities or true; --default to true (affects all abilities, eg: Attack+DefensePower, Attack+DefensePower%, DamageAbsorption); false == only affects Health and Damage To Kill
-- 	Mod.Settings.PoisonAffectsOtherModAbilities = Mod.Settings.PoisonAffectsOtherModAbilities or true; --default to true; this setting indicates whether Poison should be implemented into other mods, eg: Pestilence, Nuke, Bomb+, etc

	Mod.Settings.PoisonDuration = math.max (NIFpoisonDuration.GetValue (), 1); --cannot be less than 1
	Mod.Settings.PoisonDamageFixedArmies = NIFarmiesKilledInput.GetValue (); --permit <0 to enable 'healing poison'
	Mod.Settings.PoisonDamagePercentArmies = NIFarmiesKilledPercentInput.GetValue (); --permit <0 to enable 'healing poison'
	Mod.Settings.PoisonDamageFixedSpecialUnits = NIFspecialUnitsKilledInput.GetValue (); --permit <0 to enable 'healing poison'
	Mod.Settings.PoisonDamagePercentSpecialUnits = NIFspecialUnitsKilledPercentInput.GetValue (); --permit <0 to enable 'healing poison'
	Mod.Settings.PoisonImpactRange = math.max (NIFimpactRange.GetValue (), 0); --cannot be less than 0
	Mod.Settings.PoisonSpreadRange = math.max (NIFspreadRange.GetValue (), 0); --cannot be less than 0

	Mod.Settings.PoisonDamageAffectsAllAbilities = cboxPoisonDamageAffectsAllAbilities.GetIsChecked ();
	Mod.Settings.PoisonAffectsOtherModAbilities = cboxPoisonAffectsOtherModAbilities.GetIsChecked ();
	--this is achieved by XYZ (still figuring this out)
	--maybe add additional Poison cards which other mods can check in order to apply poison
	--maybe have them check for the Poison card, then add a 'Poison' custom order (that can be skipped) to trigger this mod to apply the poison

	Mod.Settings.PoisonPiecesNeeded = math.max (NIFpoisonPiecesNeeded.GetValue (), 1); --cannot be less than 1
	Mod.Settings.PoisonPiecesPerTurn = math.max (NIFpoisonPiecesPerTurn.GetValue (), 0); --cannot be less than 0
	Mod.Settings.PoisonStartPieces = math.max (NIFpoisonStartPieces.GetValue (), 0); --cannot be less than 0
	Mod.Settings.PoisonCardWeight = math.max (NIFpoisonCardWeight.GetValue (), 0); --cannot be less than 0

	Mod.Settings.NumCitiesDestroyedByPoison = math.max (NIFnumCitiesDestroyedByPoison.GetValue (), 0); --cannot be less than 0
	Mod.Settings.CitiesAreDestroyedEachTurn = radioPoisonCitiesDestroyedEachTurn.GetIsChecked ();

	local strPoisonDescription = "Throw poison on a territory that lasts for " .. tostring (Mod.Settings.PoisonDuration) .. " turn(s). Poison causes " ..tostring (Mod.Settings.PoisonDamageFixedArmies).. " fixed + " ..tostring (Mod.Settings.PoisonDamagePercentArmies) .. "% damage to armies and " ..
		tostring (Mod.Settings.PoisonDamageFixedSpecialUnits) .. " fixed + " ..tostring (Mod.Settings.PoisonDamagePercentSpecialUnits) .. "% damage to Special Units.\n\nFor Special Units with Health, their Health will be reduced by the appropriate amount. " ..
		"For Special Units of 'Damage to Kill' type (no Health, they must be killed in a single attack), the 'Damage to Kill' value will be reduced. If the Health or Damage to Kill values of a Special Units reaches 0, it will die." ..
		"\n\nArmies or Special Units impacted by poison can leave the territory in order to end the effects.";

	--for testing only
	-- Mod.Settings.PoisonPiecesNeeded = 1;
	-- Mod.Settings.PoisonStartPieces = 50;

	Mod.Settings.PoisonCardID = addCard ("Poison", strPoisonDescription, "Poison_card_130x180.png", Mod.Settings.PoisonPiecesNeeded, Mod.Settings.PoisonPiecesPerTurn, Mod.Settings.PoisonStartPieces, Mod.Settings.PoisonCardWeight, Mod.Settings.PoisonDuration);
	Mod.Settings.PoisonAffectsOtherModsCardID = addCard ("Poison Affects Other Mods", "Presence of this cards signifies to other mods to apply poison damage to their effects", "Poison_effect_130x180.png", 99999, 0, 0, 0, 0); --placeholder card to exchange data between mods, not an actual card to be played
end