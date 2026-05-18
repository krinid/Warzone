require('Utilities')
function Client_PresentSettingsUI(rootParent)

	local name = Mod.Settings.Buildname

	local vert = UI.CreateVerticalLayoutGroup(rootParent)



	local row000 = UI.CreateHorizontalLayoutGroup(vert) -- Human Text
	UI.CreateLabel(row000).SetText("Pure AI")

	local row9 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row9).SetText('Pure AI can attack: ' .. tostring(Mod.Settings.P_attack))

	local row2 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row2).SetText('Pure AI can deploy: ' .. tostring(Mod.Settings.P_deploy))

	local row3 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row3).SetText('Pure AI can build cities: ' .. tostring(Mod.Settings.P_city))

	local row4 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row4).SetText('Pure AI can play Diplomacy card: ' .. tostring(Mod.Settings.P_diplo))

	local row5 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row5).SetText('Pure AI can play blockcade card: ' .. tostring(Mod.Settings.P_block))

	local row6 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row6).SetText('Pure AI can play Emergency blockcade card: ' .. tostring(Mod.Settings.P_emergency))

	local row7 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row7).SetText('Pure AI can use reinforcement card: ' .. tostring(Mod.Settings.P_rein))

if Mod.Settings.P_bomb ~= nil then
	local row8 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(row8).SetText('Pure AI can play bomb card: ' .. tostring(Mod.Settings.P_bomb .. '\n\n')) end
--Human
local row00 = UI.CreateHorizontalLayoutGroup(vert) -- Human Text
UI.CreateLabel(row00).SetText("Human AI")

	local rowH9 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH9).SetText('Human AI can attack: ' .. tostring(Mod.Settings.H_attack))

	local rowH2 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH2).SetText('Human AI can deploy: ' .. tostring(Mod.Settings.H_deploy))

	local rowH3 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH3).SetText('Human AI can build cities: ' .. tostring(Mod.Settings.H_city))

	local rowH4 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH4).SetText('Human AI can play diplomacy card: ' .. tostring(Mod.Settings.H_diplo))

	local rowH5 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH5).SetText('Human AI can play blockcade card: ' .. tostring(Mod.Settings.H_block))

	local rowH6 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH6).SetText('Human AI can play Emergency blockcade card: ' .. tostring(Mod.Settings.H_emergency))

	local rowH7 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH7).SetText('Human AI can play reinforcement card: ' .. tostring(Mod.Settings.H_rein))

	if Mod.Settings.H_bomb ~= nil then
	local rowH8 = UI.CreateHorizontalLayoutGroup(vert) 
	UI.CreateLabel(rowH8).SetText('Human AI can play bomb card: ' .. tostring(Mod.Settings.H_bomb .. '\n\n')) end
end
