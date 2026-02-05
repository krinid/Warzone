

function Client_PresentConfigureUI(rootParent)

    if (not WL.IsVersionOrHigher("5.33")) then
		UI.Alert("You must update your app to the latest version to use the Smoke Bomb Card mod");
		return;
	end

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Duration for smoke bomb effect\n(# of turns the fog remains)').SetPreferredWidth(290);
    duration = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(1)
        .SetSliderMaxValue(10)
        .SetValue(Mod.Settings.Duration or 3);
	-- UI.CreateLabel(rootParent).SetText('(# of turns the fog remains)').SetFlexibleWidth(1);

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Range for smoke bomb effect\n(# of territories the fog spreads; 0=targeted territory only, 1=spreads to directly bordering territories, etc)').SetPreferredWidth(290);
    range = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(1)
        .SetSliderMaxValue(10)
        .SetValue(Mod.Settings.Range or 3);
	-- UI.CreateLabel(rootParent).SetText('(# of territories the fog spreads; 0=targeted territory only, 1=spreads to directly bordering territories, etc)').SetFlexibleWidth(1);

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Number of Pieces to divide the card into').SetPreferredWidth(290);
    numPieces = UI.CreateNumberInputField(horz)
        .SetSliderMinValue(1)
        .SetSliderMaxValue(11)
        .SetValue(Mod.Settings.NumPieces or 8);

    local horz = UI.CreateHorizontalLayoutGroup(rootParent);
    UI.CreateLabel(horz).SetText('Card weight (how common the card is)').SetPreferredWidth(290);
    cardWeight = UI.CreateNumberInputField(horz)
        .SetWholeNumbers(false)
        .SetSliderMinValue(0)
        .SetSliderMaxValue(5)
        .SetValue(Mod.Settings.CardWeight or 1.0);

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