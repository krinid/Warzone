function Client_PresentConfigureUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("[SIMPLE CONFIG]").SetFlexibleWidth (1).SetAlignment (WL.TextAlignmentOptions.Left);

	local horzSimpleConfig = UI.CreateHorizontalLayoutGroup (rootParent);
    NIFsimpleConfig = UI.CreateNumberInputField (horzSimpleConfig).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.SimpleConfig or 1);

	-- local horz = UI.CreateHorizontalLayoutGroup (rootParent);
	-- -- UI.CreateLabel (horz).SetText ("text here").SetPreferredWidth(290);
	-- NeutralizeCanUseOnCommander = UI.CreateCheckBox (horz).SetIsChecked(Mod.Settings.NeutralizeCanUseOnCommander).SetInteractable(true).SetText("Can use on Commander");
    -- EliminationTurnFrequency = UI.CreateNumberInputField (horz).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.EliminationTurnFrequency or 5);

	-- EliminationStartTurn = UI.CreateNumberInputField (horz).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.EliminationStartTurn or 5);

    -- local horz = UI.CreateHorizontalLayoutGroup (rootParent);
	-- UI.CreateLabel (horz).SetText ('Frequency for eliminations\n(# of turns before each additional player is eliminated)').SetPreferredWidth(290);
    -- EliminationTurnFrequency = UI.CreateNumberInputField (horz).SetSliderMinValue (1).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.EliminationTurnFrequency or 5);

	-- horzPhantomFogLevel = UI.CreateHorizontalLayoutGroup (UIcontainer);
	-- groupPhantomFogLevel = UI.CreateRadioButtonGroup(horzPhantomFogLevel);
	-- UI.CreateLabel (horzPhantomFogLevel).SetText("Fog level: ");
	-- PhantomFog_Normal = UI.CreateRadioButton(horzPhantomFogLevel).SetGroup(groupPhantomFogLevel).SetText('Normal Fog').SetIsChecked (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.Fogged);
	-- PhantomFog_Light = UI.CreateRadioButton(horzPhantomFogLevel).SetGroup(groupPhantomFogLevel).SetText('Light Fog').SetIsChecked (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.OwnerOnly);
	-- UI.CreateLabel (UIcontainer).SetText("• Normal Fog - can't see units or owner of Phantom fogged territories\n• Light Fog - can see owner but not units");

	-- --only 2 radio buttons, so if 1st one (Normal fog) isn't checked, it's the 2nd one (Light fog)
	-- --FogMod level options: WL.StandingFogLevel.Visible, WL.StandingFogLevel.OwnerOnly, or WL.StandingFogLevel.Fogged
	-- if (PhantomFog_Normal.GetIsChecked () == true) then Mod.Settings.PhantomFogLevel = WL.StandingFogLevel.Fogged; print ("Fogged");
	-- else Mod.Settings.PhantomFogLevel = WL.StandingFogLevel.OwnerOnly; print ("OwnerOnly");
	-- end
	-- print ("\n\n\nFOG "..tostring (PhantomFog_Normal.GetIsChecked ()), tostring (PhantomFog_Light.GetIsChecked ()),Mod.Settings.PhantomFogLevel,WL.StandingFogLevel.Fogged,WL.StandingFogLevel.OwnerOnly);

end