function Client_SaveConfigureUI (alert, addCard)
	local strPoisonDescription = "Throw poison on a territory that last for X turns. Poison causes M fixed/N% damage to armies and O fixed/O% damage to Special Units.\n\nFor Special Units with Health, their Health will be reduced by the appropriate amount. " ..
		"For Special Units of 'Damage to Kill' type (no Health, they must be killed in a single attack), the 'Damage to Kill' value will be reduced. If the Health or Damage to Kill values of a Special Units reaches 0, it will die." ..
		"\n\nArmies or Special Units impacted by poison can leave the territory in order to end the effects.";

	Mod.Settings.PoisonPiecesNeeded = Mod.Settings.PoisonPiecesNeeded or 10; --default to 10 if not set yet
	Mod.Settings.PoisonPiecesPerTurn = Mod.Settings.PoisonPiecesPerTurn or 1; --default to 1 if not set yet
	Mod.Settings.PoisonStartPieces = Mod.Settings.PoisonStartPieces or 1; --default to 1 if not set yet
	Mod.Settings.PoisonCardWeight = Mod.Settings.PoisonCardWeight or 1; --default to 1 if not set yet
	Mod.Settings.PoisonDuration = Mod.Settings.PoisonDuration or 3; --default to 3 if not set yet

	Mod.Settings.PoisonDamageFixedArmies = Mod.Settings.PoisonDamageFixedArmies or 1; --default to 1
	Mod.Settings.PoisonDamagePercentArmies = Mod.Settings.PoisonDamagePercentArmies or 0; --default to 0
	Mod.Settings.PoisonDamageFixedSpecialUnits = Mod.Settings.PoisonDamageFixedSpecialUnits or 5; --default to 0
	Mod.Settings.PoisonDamagePercentSpecialUnits = Mod.Settings.PoisonDamagePercentSpecialUnits or 10; --default to 10%
	Mod.Settings.PoisonDamageRange = Mod.Settings.PoisonDamageRange or 1; --default to 1 (doesn't spread)

	Mod.Settings.PoisonAffectsOtherModAbilities = Mod.Settings.PoisonAffectsOtherModAbilities or true; --default to true; this setting indicates whether Poison should be implemented into other mods, eg: Pestilence, Nuke, Bomb+, etc
	--this is achieved by XYZ (still figuring this out)
	--maybe add additional Poison cards which other mods can check in order to apply poison
	--maybe have them check for the Poison card, then add a 'Poison' custom order (that can be skipped) to trigger this mod to apply the poison

	Mod.Settings.PoisonCardID = addCard ("Poison", strPoisonDescription, "poison_130x180.png", Mod.Settings.PoisonPiecesNeeded, Mod.Settings.PoisonPiecesPerTurn, Mod.Settings.PoisonStartPieces, Mod.Settings.PoisonCardWeight, Mod.Settings.PoisonDuration);
	Mod.Settings.PoisonAffectsOtherModsCardID = addCard ("Poison Affects Other Mods", "Presence of this cards signifies to other mods to apply poison damage to their effects", "poison_130x180.png", 99999, 0, 0, 0, 0); --placeholder card to exchange data between mods, not an actual card to be played
end