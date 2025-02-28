
function Client_SaveConfigureUI(alert)
	Mod.Settings.MoveLimit = InputMoveLimit.GetValue();
	if( Mod.Settings.MoveLimit == nil)then
		Mod.Settings.MoveLimit = 5;
	end
	if( Mod.Settings.MoveLimit < 0)then
		alert('If you can explain me what you understand under negative moves, I will add it.');
	end
	if( Mod.Settings.MoveLimit > 100000)then
		alert('The number is too big.');
	end

	Mod.Settings.AttackLimit = InputAttackLimit.GetValue();
	if( Mod.Settings.AttackLimit == nil)then
		Mod.Settings.AttackLimit = 5;
	end
	if( Mod.Settings.AttackLimit < 0)then
		alert('If you can explain me what you understand under negative transfers, I will add it.');
	end
	if( Mod.Settings.AttackLimit > 100000)then
		alert('The number is too big.');
	end

	Mod.Settings.TransferLimit = InputTransferLimit.GetValue();
	if( Mod.Settings.TransferLimit == nil)then
		Mod.Settings.TransferLimit = 5;
	end
	if( Mod.Settings.TransferLimit < 0)then
		alert('If you can explain me what you understand under negative transfers, I will add it.');
	end
	if( Mod.Settings.TransferLimit > 100000)then
		alert('The number is too big.');
	end
end