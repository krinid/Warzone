function Client_SaveConfigureUI(alert)
    
    local limit = limitInputField.GetValue();
     if limit < 1 then alert("You can only have a limit of 1 territory or above!"); end
    Mod.Settings.TerrLimit = limit;
    
end
