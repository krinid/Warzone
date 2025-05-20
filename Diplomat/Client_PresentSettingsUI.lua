function Client_PresentSettingsUI(rootParent)
	local vert = UI.CreateVerticalLayoutGroup(rootParent);

	UI.CreateLabel(vert).SetText('A Diplomat costs: ' .. Mod.Settings.CostToBuyDiplomat);
	UI.CreateLabel(vert).SetText('Max Diplomats: ' .. Mod.Settings.MaxDiplomats);
	UI.CreateLabel(vert).SetText('When a Diplomat is killed, it will enforce a diplomacy card between both players');

	UI.CreateLabel(vert).SetText('A Diplomat will always have the same power as 1 army!');
end
