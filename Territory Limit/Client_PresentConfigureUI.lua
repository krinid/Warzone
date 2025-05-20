function Client_PresentConfigureUI(rootParent, rootParent2, rootParent3)
   
        local limit = Mod.Settings.TerrLimit;
	
        if limit == nil then 
                limit = 20; 
        end
        
        local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local row1 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row1).SetText('Limit the amount of territories that a player can own').SetColor('#AD7E7E');
    limitInputField = UI.CreateNumberInputField(row1)
		.SetSliderMinValue(1)
		.SetSliderMaxValue(50)
		.SetValue(limit);
        
end
