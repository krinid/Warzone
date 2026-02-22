
function Client_PresentConfigureUI(rootParent)
	local initialValue = Mod.Settings.MaxDeploy or 5; --default to 5 if not set

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Deployment limit: ');
    InputMaxDeploy = UI.CreateNumberInputField(horz).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(initialValue);
	UI.CreateLabel(rootParent).SetText('  (# of deployments permitted on a single territory)');
end