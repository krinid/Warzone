
function Client_SaveConfigureUI(alert)
    Mod.Settings.NumPieces = numPieces.GetValue();
    Mod.Settings.CardWeight = cardWeight.GetValue();
    Mod.Settings.MinPieces = minPieces.GetValue();
    Mod.Settings.InitialPieces = initialPieces.GetValue();

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

    local cardID = addCard ("Fort Card", "Play this card to create a fort on any territory you control. Any armies on a territory with a fort cannot be harmed by an incoming attack, but any incoming attack will destroy the fort. Therefore, as an attacker, it's a good idea to attack a fort with 1 army to destroy it with minimal losses. Attacking forces will sustain regular damage from the forces present on the territory with a fort.", "Fort Card.png", Mod.Settings.NumPieces, Mod.Settings.MinPieces, Mod.Settings.InitialPieces, Mod.Settings.CardWeight);
end

