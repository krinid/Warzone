require ("castles");

function Client_PresentSettingsUI(rootParent)
    --be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

	MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(MainUI).SetText("[CASTLES]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("Build a castle to provide additional protection to armies that enter the castle.");
	UI.CreateLabel(MainUI).SetText("• 1st castle: " ..tostring (intCastleBaseCost).. " gold\n• Increases: +" ..tostring (intCastleCostIncrease).. " gold per castle");
	UI.CreateLabel(MainUI).SetText("• Maintenance: " ..tostring (intCastleMaintenanceCost).. " gpt per castle\n• Conversion ratio: " ..tostring (intArmyToCastlePowerRatio).. " [1 army = " ..tostring (intArmyToCastlePowerRatio).. " castle strength]");
end