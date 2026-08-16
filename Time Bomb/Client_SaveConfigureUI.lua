require ('Bomb+ common');

function Client_SaveConfigureUI (alert, addCard)
	--don't limit any of the damage variables to >0; this permits "healing bombs"
	Mod.Settings.ArmyDamagePercent = NIFarmyDamagePercent.GetValue();
	Mod.Settings.ArmyDamageFixed = NIFarmyDamageFixed.GetValue();
	Mod.Settings.SUdamagePercent = NIF_SUdamagePercent.GetValue();
	Mod.Settings.SUdamageFixed = NIF_SUdamageFixed.GetValue();

	Mod.Settings.SpecialUnitsPreventNeutral = NIF_SUsPreventNeutral.GetIsChecked();
	Mod.Settings.EmptyTerritoriesGoNeutral = cboxEmptyTerritoriesGoNeutral.GetIsChecked();
	Mod.Settings.NumCitiesDestroyedByTimeBombPlay = NIFnumCitiesDestroyedByTimeBomb.GetValue(); --value of <0 means it would create cities
	--don't need this: Mod.Settings.BombImplementationPhase = TimeBombImplementationPhase.GetText();
	--b/c it's handled in Present_Configure; it's done this way to work around the fact that WL.TurnPhase is a numeric value, and we want to display the WL.TurnPhase.ToString () value of that value to the client
	--so it's easier to just set the Mod.Settings.BombImplementationPhase to the numeric value at time of click the desired turn phase

	Mod.Settings.TimeBombPiecesNeeded = TimeBombCardPiecesNeeded.GetValue ();
	Mod.Settings.TimeBombStartPieces = TimeBombCardStartPieces.GetValue ();
	Mod.Settings.TimeBombPiecesPerTurn = TimeBombPiecesPerTurn.GetValue ();
	Mod.Settings.TimeBombCardWeight = TimeBombCardWeight.GetValue ();
	Mod.Settings.NumCitiesDestroyedByTimeBombPlay = NIFnumCitiesDestroyedByTimeBomb.GetValue ();

	Mod.Settings.TimeBombCastRange = math.max (NIFcastRange.GetValue (), -1); -- -1 indicates that can be cast anywhere on map w/o limitations; 0 = can only cast time bomb on territories you own yourself
	Mod.Settings.TimeBombDurationForMaxPower = math.max (NIFdurationForMaxPower.GetValue (), 0); --no neg values, min value is 0 (explodes on same turn it's played [which is essentially a regular bomb except it'll explode @ end of turn instead of at time of play during BombCards phase])
	local strTimeBombDesc = get_BombPlus_description ();
	Mod.Settings.TimeBombCardPlusID = addCard ("Time Bomb", strTimeBombDesc, "Time bomb 130x180.png", Mod.Settings.TimeBombPiecesNeeded, Mod.Settings.TimeBombPiecesPerTurn, Mod.Settings.TimeBombStartPieces, Mod.Settings.TimeBombCardWeight);
end