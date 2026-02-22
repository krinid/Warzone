function Client_PresentConfigureUI(rootParent)
	local initialValue = Mod.Settings.NumPortals or 5; --default to 5 if value hasn't been set yet
	local mainContainer = UI.CreateVerticalLayoutGroup(rootParent)

	local sliderNumPortals = UI.CreateHorizontalLayoutGroup(mainContainer)
	UI.CreateLabel (sliderNumPortals).SetText("Number of Portals: ")
	numberInputField = UI.CreateNumberInputField(sliderNumPortals).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(initialValue);
	UI.CreateLabel (mainContainer).SetText ("(# portals to be randomly created on the map at the start of the game)");
	
end
