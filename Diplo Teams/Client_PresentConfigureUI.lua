function Client_PresentConfigureUI (rootParent)
	local UIcontainer = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth (1);
	Mod.Settings.AllowAIDeclaration = Mod.Settings.AllowAIDeclaration == nil and true or Mod.Settings.AllowAIDeclaration;
	Mod.Settings.AIsDeclareAIs = Mod.Settings.AIsDeclareAIs == nil and true or Mod.Settings.AIsDeclareAIs;
	Mod.Settings.SanctionCardRequireWar = Mod.Settings.SanctionCardRequireWar == nil and true or Mod.Settings.SanctionCardRequireWar;
	Mod.Settings.SanctionCardRequirePeace = Mod.Settings.SanctionCardRequirePeace == nil and false or Mod.Settings.SanctionCardRequirePeace;
	Mod.Settings.SanctionCardRequireAlly = Mod.Settings.SanctionCardRequireAlly == nil and false or Mod.Settings.SanctionCardRequireAlly;
	Mod.Settings.BombCardRequireWar = Mod.Settings.BombCardRequireWar == nil and true or Mod.Settings.BombCardRequireWar;
	Mod.Settings.BombCardRequirePeace = Mod.Settings.BombCardRequirePeace == nil and false or Mod.Settings.BombCardRequirePeace;
	Mod.Settings.BombCardRequireAlly = Mod.Settings.BombCardRequireAlly == nil and false or Mod.Settings.BombCardRequireAlly;
	Mod.Settings.GiftCardRequireWar = Mod.Settings.GiftCardRequireWar == nil and false or Mod.Settings.GiftCardRequireWar;
	Mod.Settings.GiftCardRequirePeace = Mod.Settings.GiftCardRequirePeace == nil and true or Mod.Settings.GiftCardRequirePeace;
	Mod.Settings.GiftCardRequireAlly = Mod.Settings.GiftCardRequireAlly == nil and true or Mod.Settings.GiftCardRequireAlly;
	Mod.Settings.SpyCardRequireWar = Mod.Settings.SpyCardRequireWar == nil and true or Mod.Settings.SpyCardRequireWar;
	Mod.Settings.SpyCardRequirePeace = Mod.Settings.SpyCardRequirePeace == nil and true or Mod.Settings.SpyCardRequirePeace;
	Mod.Settings.SpyCardRequireAlly = Mod.Settings.SpyCardRequireAlly == nil and true or Mod.Settings.SpyCardRequireAlly;

	local allow = true; --set Interactable to true
	UI.CreateLabel (UIcontainer).SetText('- - AI Settings - -').SetColor ("#FFFF00");
	local horzAIoptions = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzAIoptions).SetText('AIs can declare on:');
	cboxAIdeclareOnPlayers = UI.CreateCheckBox (horzAIoptions).SetInteractable (allow).SetText ('Players').SetIsChecked (Mod.Settings.AllowAIDeclaration);
	UI.CreateLabel (horzAIoptions).SetText('  ');
	cboxAIdeclareOnAIs = UI.CreateCheckBox (horzAIoptions).SetInteractable (allow).SetText ('Other AIs').SetIsChecked (Mod.Settings.AIsDeclareAIs);
	UI.CreateLabel (UIcontainer).SetText ('• AIs declare on Players: permits AIs to declare on players they have opportunity to attack or target with cards plays');
	UI.CreateLabel (UIcontainer).SetText ('• AIs declare on AIs: AIs permits AIs to declare on other AIs that they have opportunity to attack or target with cards plays');

	UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	UI.CreateLabel (UIcontainer).SetText ('- - War/Peace Start Settings - -').SetColor ("#FFFF00");
	UI.CreateLabel (UIcontainer).SetText ("When the game starts, players will start:");
	local horzWarStartState = UI.CreateHorizontalLayoutGroup (UIcontainer);
	local grouphorzWarStartState = UI.CreateRadioButtonGroup (horzWarStartState);
	Mod.Settings.WarStateState = Mod.Settings.WarStateState ~= nil and Mod.Settings.WarStateState or Mod.Settings.WarStateState == nil and "ATWAR"; --default to "ATWAR", options are "ATWAR" or "ATPEACE"
	WarStartState_AtWar = UI.CreateRadioButton (horzWarStartState).SetInteractable (allow).SetGroup (grouphorzWarStartState).SetText ("AT WAR with one another").SetIsChecked (Mod.Settings.WarStartState == "ATWAR");
	WarStartState_AtPeace = UI.CreateRadioButton (horzWarStartState).SetInteractable (allow).SetGroup (grouphorzWarStartState).SetText ("AT PEACE with one another").SetIsChecked (Mod.Settings.WarStartState == "ATPEACE");
	UI.CreateLabel (UIcontainer).SetText("• AT WAR - players can attack each other as soon as the game starts");
	UI.CreateLabel (UIcontainer).SetText("• AT PEACE - players can't attack each other when the game starts, need to declare on players they wish to attack");

	UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
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

	-- UI.CreateLabel (UIcontainer).SetText('- - AI Settings - -').SetColor ("#FFFF00");
	-- local horzAIoptions = UI.CreateHorizontalLayoutGroup (UIcontainer);
	-- UI.CreateLabel (horzAIoptions).SetText('AIs can declare on:');
	-- AIDeclarationcheckbox = UI.CreateCheckBox (horzAIoptions).SetText ('Players').SetIsChecked (Mod.Settings.AllowAIDeclaration);
	-- UI.CreateLabel (horzAIoptions).SetText('  ');
	-- AIsDeclareAIsinitcheckbox = UI.CreateCheckBox (horzAIoptions).SetText ('Other AIs').SetIsChecked (Mod.Settings.AIsDeclareAIs);

	-- UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	-- UI.CreateLabel (UIcontainer).SetText ('- - War/Peace Start Settings - -').SetColor ("#FFFF00");
	-- UI.CreateLabel (UIcontainer).SetText ("When the game starts, players will start:");
	-- local horzWarStartState = UI.CreateHorizontalLayoutGroup (UIcontainer);
	-- local grouphorzWarStartState = UI.CreateRadioButtonGroup (horzWarStartState);
	-- Mod.Settings.WarStateState = Mod.Settings.WarStateState ~= nil and Mod.Settings.WarStateState or Mod.Settings.WarStateState == nil and "ATWAR"; --default to "ATWAR", options are "ATWAR" or "ATPEACE"
	-- WarStartState_AtWar = UI.CreateRadioButton (horzWarStartState).SetGroup (grouphorzWarStartState).SetText ("AT WAR with one another").SetIsChecked (Mod.Settings.WarStartState == "ATWAR");
	-- WarStartState_AtPeace = UI.CreateRadioButton (horzWarStartState).SetGroup (grouphorzWarStartState).SetText ("AT PEACE with one another").SetIsChecked (Mod.Settings.WarStartState == "ATPEACE");
	-- -- PhantomFog_Normal = UI.CreateRadioButton(horzPhantomFogLevel).SetGroup(groupPhantomFogLevel).SetText('Normal Fog').SetIsChecked (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.Fogged);
	-- UI.CreateLabel (UIcontainer).SetText("• AT WAR - players can attack each other as soon as the game starts");
	-- UI.CreateLabel (UIcontainer).SetText("• AT PEACE - players can't attack each other when the game starts, need to declare on players they wish to attack");

	-- UI.CreateLabel (UI.CreateHorizontalLayoutGroup (UIcontainer)).SetText (' ');
	-- UI.CreateLabel (UIcontainer).SetText ('- - Card Settings - -').SetColor ("#FFFF00");
	-- UI.CreateLabel (UIcontainer).SetText ("Indicates whether cards can be played on:\n(A) Teammates/Allies\n(B) players you're at War with\n(C) players you're at peace with");

	-- local horzCards = UI.CreateHorizontalLayoutGroup (UIcontainer);
	-- local vertCardName = UI.CreateVerticalLayoutGroup (horzCards);
	-- local vertAllies = UI.CreateVerticalLayoutGroup (horzCards);
	-- local vertWar = UI.CreateVerticalLayoutGroup (horzCards);
	-- local vertPeace = UI.CreateVerticalLayoutGroup (horzCards);

	-- UI.CreateLabel (vertCardName).SetText ("CARD").SetColor ("#00AAFF").SetPreferredWidth (100);
	-- UI.CreateLabel (vertAllies).SetText ("ON ALLIES").SetColor ("#00AAFF").SetPreferredWidth (100);
	-- UI.CreateLabel (vertWar).SetText ("AT WAR").SetColor ("#00AAFF").SetPreferredWidth (100);
	-- UI.CreateLabel (vertPeace).SetText ("AT PEACE").SetColor ("#00AAFF").SetPreferredWidth (100);

	-- UI.CreateLabel (vertCardName).SetText ("Sanction").SetPreferredHeight (30);
	-- inputSanctionCardRequireAlly = UI.CreateCheckBox (vertAllies).SetIsChecked (Mod.Settings.SanctionCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	-- inputSanctionCardRequireWar = UI.CreateCheckBox (vertWar).SetIsChecked (Mod.Settings.SanctionCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	-- inputSanctionCardRequirePeace = UI.CreateCheckBox (vertPeace).SetIsChecked (Mod.Settings.SanctionCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	-- UI.CreateLabel (vertCardName).SetText ("Bomb").SetPreferredHeight (30);
	-- inputBombCardRequireAlly = UI.CreateCheckBox (vertAllies).SetIsChecked (Mod.Settings.BombCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	-- inputBombCardRequireWar = UI.CreateCheckBox (vertWar).SetIsChecked (Mod.Settings.BombCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	-- inputBombCardRequirePeace = UI.CreateCheckBox (vertPeace).SetIsChecked (Mod.Settings.BombCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	-- UI.CreateLabel (vertCardName).SetText ("Gift").SetPreferredHeight (30);
	-- inputGiftCardRequireAlly = UI.CreateCheckBox (vertAllies).SetIsChecked (Mod.Settings.GiftCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	-- inputGiftCardRequireWar = UI.CreateCheckBox (vertWar).SetIsChecked (Mod.Settings.GiftCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	-- inputGiftCardRequirePeace = UI.CreateCheckBox (vertPeace).SetIsChecked (Mod.Settings.GiftCardRequirePeace or false).SetText ("").SetPreferredHeight (30);

	-- UI.CreateLabel (vertCardName).SetText ("Spy").SetPreferredHeight (30);
	-- inputSpyCardRequireAlly = UI.CreateCheckBox (vertAllies).SetIsChecked (Mod.Settings.SpyCardRequireAlly or false).SetText ("").SetPreferredHeight (30);
	-- inputSpyCardRequireWar = UI.CreateCheckBox (vertWar).SetIsChecked (Mod.Settings.SpyCardRequireWar or false).SetText ("").SetPreferredHeight (30);
	-- inputSpyCardRequirePeace = UI.CreateCheckBox (vertPeace).SetIsChecked (Mod.Settings.SpyCardRequirePeace or false).SetText ("").SetPreferredHeight (30);
end
