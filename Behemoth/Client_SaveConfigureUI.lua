function Client_SaveConfigureUI (alert, addCard)

	Mod.Settings.BehemothGoldLevel1 = goldLevel1NIF.GetValue();
	Mod.Settings.BehemothGoldLevel2 = goldLevel2NIF.GetValue();
	Mod.Settings.BehemothGoldLevel3 = goldLevel3NIF.GetValue();
	Mod.Settings.BehemothStrengthAgainstNeutrals = neutralStrengthNIF.GetValue();
	Mod.Settings.BehemothInvulnerableToNeutrals = invulnerableToNeutralsCBOX.GetIsChecked();

	-- if (Mod.Settings.BehemothGoldLevel1 = 
end