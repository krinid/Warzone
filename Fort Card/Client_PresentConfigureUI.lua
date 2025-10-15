function Client_PresentConfigureUI(rootParent)
	if (not WL.IsVersionOrHigher("5.38")) then
		UI.Alert("You must update your app to the latest version to use the Fort Card mod");
		return;
	end

	-- local turnsToGetFort = Mod.Settings.TurnsToGetFort;
	-- if turnsToGetFort == nil then turnsToGetFort = 4; end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    -- local row1 = UI.CreateHorizontalLayoutGroup(vert);
	-- UI.CreateLabel(row1).SetText('Each player can build a fort every X turns');
    -- turnsInputField = UI.CreateNumberInputField(row1)
	-- 	.SetSliderMinValue(1)
	-- 	.SetSliderMaxValue(15)
	-- 	.SetValue(turnsToGetFort);

    -- local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Number of Pieces to divide the card into').SetPreferredWidth(290);
    numPieces = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(1)
        .SetSliderMaxValue(11)
        .SetValue(Mod.Settings.NumPieces or 4);

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
    UI.CreateLabel(horz).SetText('Card weight (how common the card is)').SetPreferredWidth(290);
    cardWeight = UI.CreateNumberInputField(horz)
        .SetWholeNumbers(false)
        .SetSliderMinValue(0)
        .SetSliderMaxValue(5)
        .SetValue(Mod.Settings.Weight or 1.0);

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
    UI.CreateLabel(horz).SetText('Minimum pieces awarded per turn').SetPreferredWidth(290);
    minPieces = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(0)
        .SetSliderMaxValue(5)
        .SetValue(Mod.Settings.MinPieces or 1);

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
    UI.CreateLabel(horz).SetText('Pieces given to each player at the start').SetPreferredWidth(290);
    initialPieces = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(0)
        .SetSliderMaxValue(5)
        .SetValue(Mod.Settings.InitialPieces or 5);

end