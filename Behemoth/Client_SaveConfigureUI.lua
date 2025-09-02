function Client_SaveConfigureUI (alert, addCard)
	Mod.Settings.BehemothGoldLevel1 = math.max (1, goldLevel1NIF.GetValue());
	Mod.Settings.BehemothGoldLevel2 = math.max (1, goldLevel2NIF.GetValue());
	Mod.Settings.BehemothGoldLevel3 = math.max (1, goldLevel3NIF.GetValue());
	Mod.Settings.BehemothStrengthAgainstNeutrals = math.max (0, neutralStrengthNIF.GetValue());
	Mod.Settings.BehemothInvulnerableToNeutrals = invulnerableToNeutralsCBOX.GetIsChecked();
	Mod.Settings.BehemothMaxSimultaneousPerPlayer = math.max (1, math.min (5, maxBehemothsSimulPerPlayer.GetValue()));
	Mod.Settings.BehemothMaxTotalPerPlayer = math.max (-1, maxBehemothsTotalPerPlayer.GetValue());
	Mod.Settings.BehemothMaxSimultaneousForAllPlayers = math.max (-1, math.min (5, maxBehemothsSimulForAllPlayers.GetValue()));
	Mod.Settings.BehemothMaxTotalForAllPlayers = math.max (-1, math.min (5, maxBehemothsTotalForAllPlayers.GetValue()));
end