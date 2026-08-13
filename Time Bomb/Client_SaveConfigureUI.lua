require ('Bomb+ common');

function Client_SaveConfigureUI (alert, addCard)
	--don't limit any of the damage variables to >0; this permits "healing bombs"
	Mod.Settings.ArmyDamagePercent = NIFarmyDamagePercent.GetValue();
	Mod.Settings.ArmyDamageFixed = NIFarmyDamageFixed.GetValue();
	Mod.Settings.SUdamagePercent = NIF_SUdamagePercent.GetValue();
	Mod.Settings.SUdamageFixed = NIF_SUdamageFixed.GetValue();

	Mod.Settings.SpecialUnitsPreventNeutral = NIF_SUsPreventNeutral.GetIsChecked();
	Mod.Settings.EmptyTerritoriesGoNeutral = cboxEmptyTerritoriesGoNeutral.GetIsChecked();
	Mod.Settings.NumCitiesDestroyedByBombPlay = NIFnumCitiesDestroyedByBomb.GetValue(); --value of <0 means it would create cities
	--don't need this: Mod.Settings.BombImplementationPhase = BombImplementationPhase.GetText();
	--b/c it's handled in Present_Configure; it's done this way to work around the fact that WL.TurnPhase is a numeric value, and we want to display the WL.TurnPhase.ToString () value of that value to the client
	--so it's easier to just set the Mod.Settings.BombImplementationPhase to the numeric value at time of click the desired turn phase

	Mod.Settings.BombPlusPiecesNeeded = BombPlusCardPiecesNeeded.GetValue ();
	Mod.Settings.BombPlusStartPieces = BombPlusCardStartPieces.GetValue ();
	Mod.Settings.BombPlusPiecesPerTurn = BombPlusPiecesPerTurn.GetValue ();
	Mod.Settings.BombPlusCardWeight = BombPlusCardWeight.GetValue ();
	Mod.Settings.NumCitiesDestroyedByBombPlay = NIFnumCitiesDestroyedByBomb.GetValue ();

	local strBombPlusDesc = get_BombPlus_description ();
	Mod.Settings.BombCardPlusID = addCard ("Time Bomb", strBombPlusDesc, "Time bomb 130x180.png", Mod.Settings.BombPlusPiecesNeeded, Mod.Settings.BombPlusPiecesPerTurn, Mod.Settings.BombPlusStartPieces, Mod.Settings.BombPlusCardWeight);
end