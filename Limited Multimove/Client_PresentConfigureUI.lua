
function Client_PresentConfigureUI(rootParent)
	local UIcontainer = rootParent;
	local initialValue = Mod.Settings.MaxAttacks;
	if initialValue == nil then
		initialValue = 5;
	end

	UI.CreateLabel(UIcontainer).SetText("This mod requires multiattack to be enabled in the game settings to function.\n\nThis mod puts a limit on the number of multiattack and multitransfer orders armies can partake it. "..
		"You can set limits for multiattacks and multitransfers separately, or Below you can specify the maximum number of moves that can be made collectively, regardless of whether they are transfers or attacks."..
		"\n\nAfter units have made the maximum number of moves, they will be unable to move any farther and will remain on whatever territory they are on until the following turn.\n\nWhen setting the config values below, "..
		"you can use -1 to indicate no limit, 0 to disable attacks or transfers altogether [not recommended, 1 for standard non-multiattack behaviour, or some number >11 to put a fixed limit restriction om unit movements."..
		"\n\nIf you set a value for 'Limit for moves', units will be able to multi-attack or multi-transfer for the # of moves you specify, regardless as to why they are trans or attacks. If you wish to manually set different "..
		"values for attacks and transfers, uncheck the checkbox below this dialog.");

	if (Mod.Settings.MoveLimit == nil) then Mod.Settings.MoveLimit = initialValue; end
	if (Mod.Settings.AttackLimit == nil) then Mod.Settings.AttackLimit = initialValue; end
	if (Mod.Settings.TransferLimit == nil) then Mod.Settings.TransferLimit = initialValue; end
	if (Mod.Settings.UseMultimove == nil) then Mod.Settings.UseMultimove = true; end --default to multimove; user can unselect to use different values for multi-attack and multi-transfer

	useMultimove = UI.CreateCheckBox(UIcontainer).SetText('Use the same limit for both multi-attacks and multi-transfers; set 1 value here to limit the number of moves units can make, regardless of whether they are attacks or tranfers').SetIsChecked(Mod.Settings.UseMultimove).SetOnValueChanged (toggleMultimove);

	local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateLabel(horz).SetText('Limit for moves: ');
	InputMoveLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.MoveLimit);
	UI.CreateLabel(UIcontainer).SetText("(use -1 for limitless; use 0 to disable transfers altogether [not recommended - if you do this no attacks or transfers can be done, so you will need to rely on some type of mod functionality to make attacks])");
	UI.CreateLabel(UIcontainer).SetText("(use 1 for standard Warzone non-multi-attack behaviour)");

	local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateLabel(horz).SetText('\nLimit for attacks: ');
	InputAttackLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.AttackLimit).SetInteractable(false);
	UI.CreateLabel(UIcontainer).SetText("(use -1 for no limitations; this would enable limitless multi-attacks onlys)");
	UI.CreateLabel(UIcontainer).SetText("(use 0 to disable attacks altogether [not recommended], use 1 for standard Warzone non-multi-attack behaviour)");
	--UI.CreateLabel(UIcontainer).SetText("(use 1 for standard Warzone non-multi-attack behaviour)");

	local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateLabel(horz).SetText('\nLimit for transfers: ');
	InputTransferLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.TransferLimit).SetInteractable(false);
	UI.CreateLabel(UIcontainer).SetText("(use -1 for no limitations; this would enable both limitless multi-transfers onlys)");
	UI.CreateLabel(UIcontainer).SetText("(use 0 to disable attacks altogether [not recommended], use 1 for standard Warzone transfer behaviour)");
	--UI.CreateLabel(UIcontainer).SetText("(use 1 for standard Warzone non-multi-attack behaviour)");
end

--note, currently pull data for # attacks from InputMaxAttacks currently

function toggleMultimove()
	Mod.Settings.UseMultimove = useMultimove.GetIsChecked();
	if (Mod.Settings.UseMultimove) then
		InputMoveLimit.SetInteractable (true);
		InputAttackLimit.SetInteractable (false);
		InputTransferLimit.SetInteractable (false);
	else
		InputMoveLimit.SetInteractable (false);
		InputAttackLimit.SetInteractable (true);
		InputTransferLimit.SetInteractable (true);
	end
end