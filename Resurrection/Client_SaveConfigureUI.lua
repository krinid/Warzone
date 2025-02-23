function Client_SaveConfigureUI (alert, addCard)
	Mod.Settings.ResurrectionPiecesNeeded = 10;
	Mod.Settings.ResurrectionPiecesPerTurn = 1;
	Mod.Settings.ResurrectionStartPieces = 1;
	Mod.Settings.ResurrectionCardWeight = 1.0;


	Mod.Settings.ResurrectionStartPieces = 10;  --for testing purposes, start with a full card

	Mod.Settings.ResurrectionCardID = addCard ("Resurrection", "Holding this card in hand enables your Commander to resurrect when killed.", "resurrection_130x180.png", Mod.Settings.ResurrectionPiecesNeeded, Mod.Settings.ResurrectionPiecesPerTurn, Mod.Settings.ResurrectionStartPieces, Mod.Settings.ResurrectionCardWeight, Mod.Settings.ResurrectionDuration);
end
