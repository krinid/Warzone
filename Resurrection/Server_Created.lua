function Server_Created(game, settings)
    local publicGameData = Mod.PublicGameData;
    publicGameData.ResurrectionData = {};
    Mod.PublicGameData = publicGameData;
end