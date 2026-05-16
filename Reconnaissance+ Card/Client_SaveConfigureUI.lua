function Client_SaveConfigureUI(alert, addCard)
    Mod.Settings.NumPieces = numPieces.GetValue ();
    Mod.Settings.CardWeight = cardWeight.GetValue ();
    Mod.Settings.MinPieces = minPieces.GetValue ();
    Mod.Settings.InitialPieces = initialPieces.GetValue ();
	Mod.Settings.Duration = duration.GetValue ();
	Mod.Settings.Range = range.GetValue ();

	local strCardName = "Recon+";

	if (Mod.Settings.Range < 0) then
        alert("[" ..strCardName.. "] Range cannot be less than 1");
        return;
    end

	if (Mod.Settings.Duration < 1) then
        alert("[" ..strCardName.. "] Duration cannot be less than 1");
        return;
    end

    if (Mod.Settings.NumPieces < 1) then
        alert("[" ..strCardName.. "] Number of pieces cannot be less than 1");
        return;
    end
    if (Mod.Settings.CardWeight < 0) then
        alert("[" ..strCardName.. "] Card weight cannot be less than 0");
        return;
    end
    if (Mod.Settings.MinPieces < 0) then
        alert("[" ..strCardName.. "] Minimum pieces cannot be less than 0");
        return;
    end
    if (Mod.Settings.InitialPieces < 0) then
        alert("[" ..strCardName.. "] Initial pieces cannot be less than 0");
        return;
    end

	local strDescription = "Play this card to create a beacon that dispels fog emanating from a given territory" ..(Mod.Settings.Range >= 1 and " and spread to territories within radius of " ..tostring (Mod.Settings.Range) or "") .. ". The reveal lasts " ..tostring (Mod.Settings.Duration).. " turn(s) and lets all players see the revealed territories.";
	local cardID = addCard("Recon+", strDescription, "Recon+ card_130x180.png", Mod.Settings.NumPieces, Mod.Settings.MinPieces, Mod.Settings.InitialPieces, Mod.Settings.CardWeight);
end

