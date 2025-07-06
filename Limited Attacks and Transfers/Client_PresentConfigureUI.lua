function Client_PresentConfigureUI(rootParent)
	local intAttackLimit = Mod.Settings.AttackLimit;
	local intTransferLimit = Mod.Settings.TransferLimit;
	if (intAttackLimit == nil) then intAttackLimit = 3; end
	if (intTransferLimit == nil) then intTransferLimit = 3; end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local horz = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(horz).SetText('Attack limit');
    nifAttackLimit = UI.CreateNumberInputField(horz)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(15)
		.SetValue(intAttackLimit);

    local horz = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(horz).SetText('Transfer limit');
    nifTransferLimit = UI.CreateNumberInputField(horz)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(15)
		.SetValue(intTransferLimit);

end