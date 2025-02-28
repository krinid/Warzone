
function Client_PresentConfigureUI(rootParent)
	local UIcontainer = rootParent;
	local defaultValue = 5;

	--future use:
	--[[UI.CreateLabel(UIcontainer).SetText("This mod requires multi-attack to be enabled in the game settings to function.\n\nThis mod puts a limit on the number of multi-attack and multi-transfer orders armies can partake in. "..
		"The recommended setting is using 'Multi-move' which sets a common limit for all orders regardless of whether they are attacks or transfers. However, it is possible to set separate limits for multi-attacks and multi-transfers."..
		"\n\nAfter units have made the maximum number of moves, they will remain stationary until the following turn.");]]

	UI.CreateLabel(UIcontainer).SetText("Enables ability for armies and special units to execute continuous attacks and transfers within a single turn. This mod requires 'multi-attack' to be enabled.");
	UI.CreateLabel(UIcontainer).SetText("\nStandard Warzone multi-attack enables limitless attacks (attack or capture of an enemy territory or neutral territory) but doesn't permit multi-transfers. Transferring units to your own territory halts all further movement by those units for that turn.");
	UI.CreateLabel(UIcontainer).SetText("\nLimited Multimoves combines multi-attack and with new multi-transfer functionality, and applies a movement count limitation that can be done by units during a single turn. The limit applies to all attack and transfer orders. Once units have consumed their move allocation, they will remain stationary until the following turn.");
			
	--[[UI.CreateLabel(UIcontainer).SetText("This mod requires multi-attack to be enabled in the game settings to function.\n\nThis mod puts a limit on the number of attack and transfer orders armies can partake in. Notably this allows armies to repeatedly transfer "..
		"within territories you own up to the limit you set.\n\nAfter units have made the maximum number of moves regardless of whether they are attacks or transfers, they will remain stationary until the following turn.");]]

	--always set UseMultimove to true and use MoveLimit only; the AttackLimit and TransferLimit are not used, they are for potential future use only
	if (Mod.Settings.MoveLimit == nil) then Mod.Settings.MoveLimit = defaultValue; end
	if (Mod.Settings.AttackLimit == nil) then Mod.Settings.AttackLimit = defaultValue; end
	if (Mod.Settings.TransferLimit == nil) then Mod.Settings.TransferLimit = defaultValue; end
	if (Mod.Settings.UseMultimove == nil) then Mod.Settings.UseMultimove = true; end --default to multimove; user can unselect to use different values for multi-attack and multi-transfer

	--UI.CreateLabel(UIcontainer).SetText(" ");
	--[[local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	useMultimove = UI.CreateCheckBox(horz).SetText (" ").SetOnValueChanged(toggleMultimove).SetIsChecked(Mod.Settings.UseMultimove);
	UI.CreateLabel(horz).SetText("[Recommended] Use a single limit for multi-moves, regardless if they are attacks or transfers").SetColor (getColourCode("subheading"));
	UI.CreateLabel(UIcontainer).SetText("(if you wish to set different limits for multi-attacks and multi-transfers, uncheck this box and set the values below appropriately");]]

	local horz = UI.CreateHorizontalLayoutGroup(UIcontainer).SetFlexibleWidth (1);
	UI.CreateLabel(horz).SetText('Limit for MULTI-MOVES: ').SetColor (getColourCode("card play heading"));
	InputMoveLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.MoveLimit);
	UI.CreateLabel(UIcontainer).SetText("• use -1 for limitless # of moves (same as standard Multi-Attack setting for attacks but also permits unlimited Multi-Transfers throughout your own territories)").SetFlexibleWidth (1);
	UI.CreateLabel(UIcontainer).SetText("• use 0 to disable transfers altogether [not recommended] - this results in not being able to execute any attacks or transfers, so you will need to rely on cards or some type of mod functionality to make attacks").SetFlexibleWidth (1);
	UI.CreateLabel(UIcontainer).SetText("• use 1 for standard Warzone behaviour)").SetFlexibleWidth (1);
	UI.CreateLabel(UIcontainer).SetText("• use 2 or higher to set the limit for # of moves [RECOMMENDED]").SetFlexibleWidth (1);

	--[[local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateLabel(horz).SetText('Limit for MULTI-ATTACKS: ').SetColor (getColourCode("card play heading"));
	InputAttackLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.AttackLimit).SetInteractable(false);
	UI.CreateLabel(UIcontainer).SetText("(use -1 for no limitations; this would enable limitless multi-attacks)");
	UI.CreateLabel(UIcontainer).SetText("(use 0 to disable attacks altogether [not recommended - no attacks can be done], use 1 for standard Warzone non-multi-attack behaviour)");

	local horz = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateLabel(horz).SetText('Limit for MULTI-TRANSFERS: ').SetColor (getColourCode("card play heading"));
	InputTransferLimit = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.TransferLimit).SetInteractable(false);
	UI.CreateLabel(UIcontainer).SetText("(use -1 for no limitations; this would enable both limitless multi-transfers onlys)");
	UI.CreateLabel(UIcontainer).SetText("(use 0 to disable attacks altogether [not recommended], use 1 for standard Warzone transfer behaviour)");]]
end

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

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end