function Client_PresentSettingsUI (UIcontainer)
	root = UIcontainer;
	local allow = false;
	UI.CreateLabel (UIcontainer).SetText('- - AI Settings - -').SetColor ("#FFFF00");
	local horzAIoptions = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzAIoptions).SetText('AIs can declare on:');
	cboxAIdeclareOnPlayers = UI.CreateCheckBox (horzAIoptions).SetInteractable (allow).SetText ('Players').SetIsChecked (Mod.Settings.AllowAIDeclaration);
	UI.CreateLabel (horzAIoptions).SetText('  ');
	cboxAIdeclareOnAIs = UI.CreateCheckBox (horzAIoptions).SetInteractable (allow).SetText ('Other AIs').SetIsChecked (Mod.Settings.AIsDeclareAIs);
	if (Mod.Settings.AllowAIDeclaration == true) then UI.CreateLabel (UIcontainer).SetText ("• AIs will declare on Players they have opportunity to attack or target with cards plays");
	else UI.CreateLabel (UIcontainer).SetText ("• AIs won't declare on Players");
	end
	if (Mod.Settings.AIsDeclareAIs == true) then UI.CreateLabel (UIcontainer).SetText ("• AIs will declare on other AIs that they have opportunity to attack or target with cards plays");
	else UI.CreateLabel (UIcontainer).SetText ("• AIs won't declare on other AIs");
	end

	UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	UI.CreateLabel (UIcontainer).SetText ('- - War/Peace Start Settings - -').SetColor ("#FFFF00");
	UI.CreateLabel (UIcontainer).SetText ("When the game starts, players will start:");
	local horzWarStartState = UI.CreateHorizontalLayoutGroup (UIcontainer);
	local grouphorzWarStartState = UI.CreateRadioButtonGroup (horzWarStartState);
	Mod.Settings.WarStateState = Mod.Settings.WarStateState ~= nil and Mod.Settings.WarStateState or Mod.Settings.WarStateState == nil and "ATWAR"; --default to "ATWAR", options are "ATWAR" or "ATPEACE"
	WarStartState_AtWar = UI.CreateRadioButton (horzWarStartState).SetInteractable (allow).SetGroup (grouphorzWarStartState).SetText ("AT WAR with one another").SetIsChecked (Mod.Settings.WarStartState == "ATWAR");
	WarStartState_AtPeace = UI.CreateRadioButton (horzWarStartState).SetInteractable (allow).SetGroup (grouphorzWarStartState).SetText ("AT PEACE with one another").SetIsChecked (Mod.Settings.WarStartState == "ATPEACE");
	if (Mod.Settings.WarStartState == "ATWAR") then UI.CreateLabel (UIcontainer).SetText("• AT WAR - the game started with all players being able to attack each other");
	elseif (Mod.Settings.WarStartState == "ATPEACE") then UI.CreateLabel (UIcontainer).SetText("• AT PEACE - the game started with all players being unable to attack each other");
	end

	UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	UI.CreateLabel (UIcontainer).SetText ('- - Card Settings - -').SetColor ("#FFFF00");
	UI.CreateLabel (UIcontainer).SetText ("Indicates whether cards can be played on:\n(A) Teammates/Allies\n(B) players you're at War with\n(C) players you're at peace with");

	local horzCards = UI.CreateHorizontalLayoutGroup (UIcontainer);
	local vertCardName = UI.CreateVerticalLayoutGroup (horzCards);
	local vertAllies = UI.CreateVerticalLayoutGroup (horzCards);
	local vertWar = UI.CreateVerticalLayoutGroup (horzCards);
	local vertPeace = UI.CreateVerticalLayoutGroup (horzCards);

	UI.CreateLabel (vertCardName).SetText ("CARD").SetColor ("#00AAFF").SetPreferredWidth (100);
	UI.CreateLabel (vertAllies).SetText ("ON ALLIES").SetColor ("#00AAFF").SetPreferredWidth (100);
	UI.CreateLabel (vertWar).SetText ("AT WAR").SetColor ("#00AAFF").SetPreferredWidth (100);
	UI.CreateLabel (vertPeace).SetText ("AT PEACE").SetColor ("#00AAFF").SetPreferredWidth (100);

	UI.CreateLabel (vertCardName).SetText ("Sanction").SetPreferredHeight (30);
	inputSanctionCardRequireAlly = UI.CreateCheckBox (vertAllies).SetInteractable (allow).SetIsChecked (Mod.Settings.SanctionCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	inputSanctionCardRequireWar = UI.CreateCheckBox (vertWar).SetInteractable (allow).SetIsChecked (Mod.Settings.SanctionCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	inputSanctionCardRequirePeace = UI.CreateCheckBox (vertPeace).SetInteractable (allow).SetIsChecked (Mod.Settings.SanctionCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	UI.CreateLabel (vertCardName).SetText ("Bomb").SetPreferredHeight (30);
	inputBombCardRequireAlly = UI.CreateCheckBox (vertAllies).SetInteractable (allow).SetIsChecked (Mod.Settings.BombCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	inputBombCardRequireWar = UI.CreateCheckBox (vertWar).SetInteractable (allow).SetIsChecked (Mod.Settings.BombCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	inputBombCardRequirePeace = UI.CreateCheckBox (vertPeace).SetInteractable (allow).SetIsChecked (Mod.Settings.BombCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	UI.CreateLabel (vertCardName).SetText ("Gift").SetPreferredHeight (30);
	inputGiftCardRequireAlly = UI.CreateCheckBox (vertAllies).SetInteractable (allow).SetIsChecked (Mod.Settings.GiftCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	inputGiftCardRequireWar = UI.CreateCheckBox (vertWar).SetInteractable (allow).SetIsChecked (Mod.Settings.GiftCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	inputGiftCardRequirePeace = UI.CreateCheckBox (vertPeace).SetInteractable (allow).SetIsChecked (Mod.Settings.GiftCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	UI.CreateLabel (vertCardName).SetText ("Spy").SetPreferredHeight (30);
	inputSpyCardRequireAlly = UI.CreateCheckBox (vertAllies).SetInteractable (allow).SetIsChecked (Mod.Settings.SpyCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	inputSpyCardRequireWar = UI.CreateCheckBox (vertWar).SetInteractable (allow).SetIsChecked (Mod.Settings.SpyCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	inputSpyCardRequirePeace = UI.CreateCheckBox (vertPeace).SetInteractable (allow).SetIsChecked (Mod.Settings.SpyCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	-- horzSanction = UI.CreateHorizontalLayoutGroup (rootParent);
	-- lblSanction = UI.CreateLabel (horzSanction);
	-- UI.CreateLabel (rootParent).SetText ("Sanction Card - can be played AT WAR: " ..tostring (Mod.Settings.SanctionCardRequireWar)..", AT PEACE: " ..tostring (Mod.Settings.SanctionCardRequirePeace).. ", ON TEAMMATES/ALLIES: " ..tostring (Mod.Settings.SanctionCardRequireAlly));

	-- if (AlwaysPlayable (Mod.Settings.SanctionCardRequireWar, Mod.Settings.SanctionCardRequirePeace, Mod.Settings.SanctionCardRequireAlly)) then
	-- 	UI.CreateLabel (rootParent).SetText ('Sanction Card - can play on all players').SetColor ('#FF0000');
	-- else
	-- 	if (NeverPlayable (Mod.Settings.SanctionCardRequireWar, Mod.Settings.SanctionCardRequirePeace, Mod.Settings.SanctionCardRequireAlly)) then
	-- 		UI.CreateLabel(rootParent).SetText('Sanction Card - cannot be played at all').SetColor('#FF0000');
	-- 	else
	-- 		CreateLine ('Sanction Cards can be played on players you are in war with: ', Mod.Settings.SanctionCardRequireWar, true, false);
	-- 		CreateLine ('Sanction Cards can be played on players you are in peace with: ', Mod.Settings.SanctionCardRequirePeace, false, false);
	-- 		if (Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false) then
	-- 			CreateLine ('Sanction Cards can be played on players you are allied with: ', Mod.Settings.SanctionCardRequireAlly, false, false);
	-- 		end
	-- 	end
	-- end
	-- UI.CreateLabel(rootParent).SetText('Bomb Card');
	-- if (AlwaysPlayable (Mod.Settings.BombCardRequireWar, Mod.Settings.BombCardRequirePeace, Mod.Settings.BombCardRequireAlly)) then
	-- 	UI.CreateLabel (rootParent).SetText ('You can play a Bomb Card on everybody').SetColor ('#FF0000');
	-- else
	-- 	if (NeverPlayable (Mod.Settings.BombCardRequireWar, Mod.Settings.BombCardRequirePeace, Mod.Settings.BombCardRequireAlly)) then
	-- 		UI.CreateLabel (rootParent).SetText ('Bomb Cards are unplayable').SetColor ('#FF0000');
	-- 	else
	-- 		CreateLine ('Bomb Cards can be played on players you are in war with: ', Mod.Settings.BombCardRequireWar, true, false);
	-- 		CreateLine ('Bomb Cards can be played on players you are in peace with: ', Mod.Settings.BombCardRequirePeace, false, false);
	-- 		if (Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false) then
	-- 			CreateLine ('Bomb Cards can be played on players you are allied with: ', Mod.Settings.BombCardRequireAlly, false, false);
	-- 		end
	-- 	end
	-- end
	-- UI.CreateLabel (rootParent).SetText ('Spy Card');
	-- if (AlwaysPlayable (Mod.Settings.SpyCardRequireWar, Mod.Settings.SpyCardRequirePeace, Mod.Settings.SpyCardRequireAlly)) then
	-- 	UI.CreateLabel (rootParent).SetText ('You can play a Spy Card on everybody').SetColor ('#FF0000');
	-- else
	-- 	if (NeverPlayable (Mod.Settings.SpyCardRequireWar, Mod.Settings.SpyCardRequirePeace, Mod.Settings.SpyCardRequireAlly)) then
	-- 		UI.CreateLabel (rootParent).SetText ('Spy Cards are unplayable').SetColor ('#FF0000');
	-- 	else
	-- 		CreateLine ('Spy Cards can be played on players you are in war with: ', Mod.Settings.SpyCardRequireWar, true, false);
	-- 		CreateLine ('Spy Cards can be played on players you are in peace with: ', Mod.Settings.SpyCardRequirePeace, false, false);
	-- 		if(Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false) then
	-- 			CreateLine ('Spy Cards can be played on players you are allied with: ', Mod.Settings.SpyCardRequireAlly, false, false);
	-- 		end
	-- 	end
	-- end
	-- UI.CreateLabel (rootParent).SetText ('Gift Card');
	-- if (AlwaysPlayable (Mod.Settings.GiftCardRequireWar, Mod.Settings.GiftCardRequirePeace, Mod.Settings.GiftCardRequireAlly)) then
	-- 	UI.CreateLabel (rootParent).SetText ('You can play a Gift Card on everybody').SetColor ('#FF0000');
	-- else
	-- 	if (NeverPlayable (Mod.Settings.GiftCardRequireWar, Mod.Settings.GiftCardRequirePeace, Mod.Settings.GiftCardRequireAlly)) then
	-- 		UI.CreateLabel (rootParent).SetText ('Gift Cards are unplayable').SetColor ('#FF0000');
	-- 	else
	-- 		CreateLine ('Gift Cards can be played on players you are in war with: ', Mod.Settings.GiftCardRequireWar, false, false);
	-- 		CreateLine ('Gift Cards can be played on players you are in peace with: ', Mod.Settings.GiftCardRequirePeace, true, false);
	-- 		if (Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false) then
	-- 			CreateLine ('Gift Cards can be played on players you are allied with: ', Mod.Settings.GiftCardRequireAlly, true, false);
	-- 		end
	-- 	end
	-- end


end

function CreateLine (settingname,variable,default,important, help)
	local horz = UI.CreateHorizontalLayoutGroup(root);
	local lab = UI.CreateLabel(horz);
	if(default == true or default == false)then
		if(help ~= null)then
			lab.SetText(settingname);
			UI.CreateButton(horz).SetText('?').SetColor('#4FC5FF').SetOnClick(function() UI.Alert(help); end);
			lab = UI.CreateLabel(horz);
			lab.SetText(booltostring(variable,default));
		else
			lab.SetText(settingname .. booltostring(variable,default));
		end
	else
		if(variable == nil)then
			if(help ~= null)then
				lab.SetText(settingname);
				UI.CreateButton(horz).SetText('?').SetColor('#4FC5FF').SetOnClick(function() UI.Alert(help); end);
				lab = UI.CreateLabel(horz);
				lab.SetText(default);
			else
				lab.SetText(settingname .. default);
			end
		else
			lab.SetText(settingname .. variable);
		end
	end
	if(variable ~= nil and variable ~= default)then
		if(important == true)then
			lab.SetColor('#FF0000');
		else
			lab.SetColor('#FFFF00');
		end
	end
end
function booltostring(variable,default)
	if(variable == nil)then
		if(default)then
			return "Yes";
		else
			return "No";
		end
	end
	if(variable)then
		return "Yes";
	else
		return "No";
	end
end
function AlwaysPlayable(warsetting,peacesetting,allysetting)
	if(peacesetting == nil and allysetting == nil)then
		if(warsetting == nil)then
			return true;
		else
			if(warsetting)then
				return false;
			else
				return true;
			end
		end
	end
	if(peacesetting and allysetting and warsetting)then
		return true;
	end
	return false;
end
function NeverPlayable(warsetting,peacesetting,allysetting)
	if(peacesetting == nil and allysetting == nil)then
		return false;
	end
	if(Mod.Settings.DisableAllies == nil or Mod.Settings.DisableAllies == false)then
		if(peacesetting == false and allysetting  == false and warsetting == false)then
			return true;
		end
	else
		if(peacesetting == false and warsetting == false)then
			return true;
		end
	end
	return false;
end
