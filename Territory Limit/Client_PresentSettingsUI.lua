function Client_PresentSettingsUI(rootParent)

local vert = UI.CreateVerticalLayoutGroup(rootParent);
  
UI.CreateLabel(vert).SetText('Territory limit = ' .. Mod.Settings.TerrLimit).SetColor('#FFAF56');

end
