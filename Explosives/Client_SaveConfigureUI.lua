require ('Bomb+ common');

function Client_SaveConfigureUI (alert, addCard)
	--don't limit any of the damage variables to >0; this permits "healing bombs"
	Mod.Settings.ArmyDamagePercent = NIFarmyDamagePercent.GetValue();
	Mod.Settings.ArmyDamageFixed = NIFarmyDamageFixed.GetValue();
	Mod.Settings.SUdamagePercent = NIF_SUdamagePercent.GetValue();
	Mod.Settings.SUdamageFixed = NIF_SUdamageFixed.GetValue();

	--these settings don't apply and there are no future plans at this time, but leave them in for potential future use just in case, but set them to inert settings
	Mod.Settings.SpecialUnitsPreventNeutral = false; --NIF_SUsPreventNeutral.GetIsChecked();
	Mod.Settings.EmptyTerritoriesGoNeutral = false; --cboxEmptyTerritoriesGoNeutral.GetIsChecked();
	Mod.Settings.NumCitiesDestroyedByBombPlay = false; --NIFnumCitiesDestroyedByBomb.GetValue(); --value of <0 means it would create cities
	--don't need this: Mod.Settings.BombImplementationPhase = BombImplementationPhase.GetText();
	--b/c it's handled in Present_Configure; it's done this way to work around the fact that WL.TurnPhase is a numeric value, and we want to display the WL.TurnPhase.ToString () value of that value to the client
	--so it's easier to just set the Mod.Settings.BombImplementationPhase to the numeric value at time of click the desired turn phase

	Mod.Settings.ExplosivesPiecesNeeded = ExplosivesCardPiecesNeeded.GetValue ();
	Mod.Settings.ExplosivesStartPieces = ExplosivesCardStartPieces.GetValue ();
	Mod.Settings.ExplosivesPiecesPerTurn = ExplosivesPiecesPerTurn.GetValue ();
	Mod.Settings.ExplosivesCardWeight = ExplosivesCardWeight.GetValue ();
	-- Mod.Settings.NumCitiesDestroyedByBombPlay = NIFnumCitiesDestroyedByBomb.GetValue ();

	local strExplosivesDesc = get_BombPlus_description ();
	Mod.Settings.BombCardPlusID = addCard ("Explosive", strExplosivesDesc, "explosive orig v3b_130x180.png", Mod.Settings.ExplosivesPiecesNeeded, Mod.Settings.ExplosivesPiecesPerTurn, Mod.Settings.ExplosivesStartPieces, Mod.Settings.ExplosivesCardWeight);
end