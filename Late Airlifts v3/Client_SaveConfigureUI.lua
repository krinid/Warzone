function Client_SaveConfigureUI (alert, addCard)
    Mod.Settings.NumPieces = numPieces.GetValue ();
    Mod.Settings.CardWeight = cardWeight.GetValue ();
    Mod.Settings.MinPieces = minPieces.GetValue ();
    Mod.Settings.InitialPieces = initialPieces.GetValue ();

	local strCardName = "Late Airlift";

    if (Mod.Settings.NumPieces < 1) then
        alert ("[" ..strCardName.. "] Number of pieces cannot be less than 1");
        return;
    end
    if (Mod.Settings.CardWeight < 0) then
        alert ("[" ..strCardName.. "] Card weight cannot be less than 0");
        return;
    end
    if (Mod.Settings.MinPieces < 0) then
        alert ("[" ..strCardName.. "] Minimum pieces cannot be less than 0");
        return;
    end
    if (Mod.Settings.InitialPieces < 0) then
        alert ("[" ..strCardName.. "] Initial pieces cannot be less than 0");
        return;
    end

	local strDescription = "This card airlifts selected armies and Special Units from a source territory to a target territory that you own, but executes it at the end of the turn isntead of at the beginning.";
	local cardID = addCard ("Late Airlift", strDescription, "Late Airlift v3 130x180.png", Mod.Settings.NumPieces, Mod.Settings.MinPieces, Mod.Settings.InitialPieces, Mod.Settings.CardWeight, Mod.Settings.Duration);
end

