function Client_PresentSettingsUI(rootParent)
    --be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
	-- UI.CreateLabel(MainUI).SetText("[CASTLES]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(rootParent).SetText("When blockading a territory, any Special Units on that territory will remain on the territory after it goes neutral. However, the owner of the Special Units will no longer be able to control them.");
end