
function Client_PresentConfigureUI(rootParent)
	-- PURE AI settings
	local p_attack = Mod.Settings.P_attack or true; --pure AI can make attacks
	local p_deploy = Mod.Settings.P_deploy or true; --pure AI can make deployments
	local p_city = Mod.Settings.P_city or true; --pure AI can build cities
	local p_diplo = Mod.Settings.P_diplo or true; --pure AI can play diplo cards
	local p_block = Mod.Settings.P_block or true; --pure AI can play blockade cards
	local p_emergency = Mod.Settings.P_emergency or true; --pure AI can play emergency cards
	--Reinforcement
	local p_rein = Mod.Settings.P_rein or true;
	--Bomb
	local p_bomb = Mod.Settings.P_bomb or true;

-- Human AI --------------------------------------------
	local h_attack = Mod.Settings.H_attack or true; --human AI can make attacks
	-- Deploy
	local h_deploy = Mod.Settings.H_deploy or true; --human AI can make deployments

	local h_city = Mod.Settings.H_city or true; --human AI can build cities
	local h_diplo = Mod.Settings.H_diplo or true; --human AI can play diplo cards
	local h_block = Mod.Settings.H_block or true; --human AI can play blockade cards
	local h_emergency = Mod.Settings.H_emergency or true; --human AI can play emergency cards
	local h_rein = Mod.Settings.H_rein or true; --human AI can play reinforcement cards
	local h_bomb = Mod.Settings.H_bomb or true; --human AI can play bomb cards

	local vert = UI.CreateVerticalLayoutGroup(rootParent)
	local row0 = UI.CreateHorizontalLayoutGroup(vert) -- Pure / Human ai
	UI.CreateLabel(row0).SetText("What is Pure/Human AI").SetColor('#00FFFF')
	UI.CreateButton(row0).SetText("?").SetColor('#0000FF').SetOnClick(function() UI.Alert("• Pure AI: starts the game as an AI\n\n• Human AI: a player that has become AI due to surrender or boot") end)

	local row00 = UI.CreateHorizontalLayoutGroup(vert) -- Pure AI Text
	UI.CreateLabel(row00).SetText("Pure AI").SetColor('#FFFF00');
	UI.CreateLabel(vert).SetText("Check the items below that Pure AI is permitted to execute:");

	local row1 = UI.CreateHorizontalLayoutGroup(vert); -- Pure Attack
	PP_attack = UI.CreateCheckBox(row1).SetText("Attack").SetIsChecked (p_attack);
	PP_deploy = UI.CreateCheckBox(row1).SetText("Deploy").SetIsChecked (p_deploy);
	PP_city = UI.CreateCheckBox(row1).SetText("Build cities").SetIsChecked(p_city);
	PP_rein = UI.CreateCheckBox(row1).SetText("Play Reinforcement cards").SetIsChecked(p_rein)

	local row2 = UI.CreateHorizontalLayoutGroup(vert); -- Pure diplo
	PP_diplo = UI.CreateCheckBox(row2).SetText("Play Diplomacy cards").SetIsChecked(p_diplo)
	PP_block = UI.CreateCheckBox(row2).SetText("Play Blockade cards").SetIsChecked(p_block)
	PP_emger = UI.CreateCheckBox(row2).SetText("Play Emergency cards").SetIsChecked(p_emergency)

	local row3 = UI.CreateHorizontalLayoutGroup(vert) -- Pure bomb
	PP_bomb = UI.CreateCheckBox(row3).SetText("Play Bombs cards").SetIsChecked(p_bomb)

-------------- Human AI


	local row00 = UI.CreateHorizontalLayoutGroup(vert) -- Human Text
	UI.CreateLabel(row00).SetText("Human AI").SetColor('#0000FF')


	local rowH1 = UI.CreateHorizontalLayoutGroup(vert) -- Human Attack
	UI.CreateLabel(rowH1).SetText('Can Human AI attack')
	HH_attack = UI.CreateCheckBox(rowH1).SetText("").SetIsChecked(h_attack)

	local rowH2 = UI.CreateHorizontalLayoutGroup(vert) -- Human deploy
	UI.CreateLabel(rowH2).SetText('Can Human AI Deploy')
	HH_deploy = UI.CreateCheckBox(rowH2).SetText("").SetIsChecked(h_deploy)

	local rowH3 = UI.CreateHorizontalLayoutGroup(vert) -- Human city
	UI.CreateLabel(rowH3).SetText('Can Human AI build cities')
	HH_city = UI.CreateCheckBox(rowH3).SetText("").SetIsChecked(h_city)

	local rowH4 = UI.CreateHorizontalLayoutGroup(vert) -- Human diplo
	UI.CreateLabel(rowH4).SetText('Can Human AI place diplomacy cards')
	HH_diplo = UI.CreateCheckBox(rowH4).SetText("").SetIsChecked(h_diplo)

	local rowH5 = UI.CreateHorizontalLayoutGroup(vert) -- Human block
	UI.CreateLabel(rowH5).SetText('Can Human AI place Blockad cards')
	HH_block = UI.CreateCheckBox(rowH5).SetText("").SetIsChecked(h_block)

	local rowH6 = UI.CreateHorizontalLayoutGroup(vert) -- Human Emergency
	UI.CreateLabel(rowH6).SetText('Can Human AI play Emergency cards')
	HH_emger = UI.CreateCheckBox(rowH6).SetText("").SetIsChecked(h_emergency)

	local rowH7 = UI.CreateHorizontalLayoutGroup(vert) -- Human Reinforcement
	UI.CreateLabel(rowH7).SetText('Can Human AI play Reinforcement cards')
	HH_rein = UI.CreateCheckBox(rowH7).SetText("").SetIsChecked(h_rein)

	local rowH8 = UI.CreateHorizontalLayoutGroup(vert) -- Human bomb
	UI.CreateLabel(rowH8).SetText('Can Human AI play Bomb cards')
	HH_bomb = UI.CreateCheckBox(rowH8).SetText("").SetIsChecked(h_bomb)

end