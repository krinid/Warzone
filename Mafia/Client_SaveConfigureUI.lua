function Client_SaveConfigureUI (alert)
	if (EliminationStartTurn.GetValue () <= 0) then EliminationStartTurn.SetValue (1); end
	if (EliminationTurnFrequency.GetValue () <= 0) then EliminationTurnFrequency.SetValue (1); end
	Mod.Settings.EliminationStartTurn = EliminationStartTurn.GetValue ();
	Mod.Settings.EliminationTurnFrequency = EliminationTurnFrequency.GetValue ();
end