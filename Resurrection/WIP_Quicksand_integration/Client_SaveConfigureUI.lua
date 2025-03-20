function Client_SaveConfigureUI (alert, addCard)
	Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies = ResurrectionDisableCardPlayUntilCommanderDies.GetIsChecked();
    Mod.Settings.ResurrectionPiecesNeeded = ResurrectionPiecesNeeded.GetValue();
	Mod.Settings.ResurrectionPiecesPerTurn = ResurrectionPiecesPerTurn.GetValue();
    Mod.Settings.ResurrectionStartPieces = ResurrectionStartPieces.GetValue();
    Mod.Settings.ResurrectionCardWeight = ResurrectionCardWeight.GetValue();

	local strCommanderDeathRequireMsg = "Possessing this card when your Commander dies enables you to resurrect your Commander to a territory of your choice.\n\nYou don't need to play this card until your Commander dies.";
	if (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies == false) then strCommanderDeathRequireMsg = strCommanderDeathRequireMsg .. "\n\nThis game is configured so that you can play Resurrection without waiting for your Commander to die. You can create multiple Commanders if you have multiple Resurrection cards."; end
	Mod.Settings.ResurrectionCardID = addCard ("Resurrection", strCommanderDeathRequireMsg, "resurrection_130x180.png", Mod.Settings.ResurrectionPiecesNeeded, Mod.Settings.ResurrectionPiecesPerTurn, Mod.Settings.ResurrectionStartPieces, Mod.Settings.ResurrectionCardWeight);
end