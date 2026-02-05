function Client_SaveConfigureUI(alert, addCard)
    Mod.Settings.NumPieces = numPieces.GetValue ();
    Mod.Settings.CardWeight = cardWeight.GetValue ();
    Mod.Settings.MinPieces = minPieces.GetValue ();
    Mod.Settings.InitialPieces = initialPieces.GetValue ();
	Mod.Settings.Duration = duration.GetValue ();
	Mod.Settings.Range = range.GetValue ();

    if (Mod.Settings.Range < 0) then
        alert("Duration cannot be less than 1");
        return;
    end

	if (Mod.Settings.Duration < 1) then
        alert("Duration cannot be less than 1");
        return;
    end

    if (Mod.Settings.NumPieces < 1) then
        alert("Number of pieces cannot be less than 1");
        return;
    end
    if (Mod.Settings.CardWeight < 0) then
        alert("Card weight cannot be less than 0");
        return;
    end
    if (Mod.Settings.MinPieces < 0) then
        alert("Minimum pieces cannot be less than 0");
        return;
    end
    if (Mod.Settings.InitialPieces < 0) then
        alert("Initial pieces cannot be less than 0");
        return;
    end

	local strDescription = "Play this card to cast fog on a given territory" ..(Mod.Settings.Range >= 1 and " and spread to territories within radius of " ..tostring (Mod.Settings.Range)) .. ". The fog lasts " ..tostring (Mod.Settings.Duration).. " turn(s) and affects all players, but players can always see their own territories.";
	local cardID = addCard("Smoke Bomb", strDescription, "SmokeBombCard.png", Mod.Settings.NumPieces, Mod.Settings.MinPieces, Mod.Settings.InitialPieces, Mod.Settings.CardWeight);
end

