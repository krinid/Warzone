
function Client_SaveConfigureUI(alert)
	local defaultValue = 5;
	Mod.Settings.MoveLimit = InputMoveLimit.GetValue();
	if( Mod.Settings.MoveLimit == nil)then
		Mod.Settings.MoveLimit = defaultValue;
	end
	if( Mod.Settings.MoveLimit < -1)then
		alert('If you have a good idea for what negative moves could mean in a game, chat me up & I might add it in.');
	end
	if( Mod.Settings.MoveLimit > 1000)then
		alert('1000+ is too high; use -1 for unlimited or enter a reasonable limit.');
	end

	-- for potential future use only:
	--[[Mod.Settings.AttackLimit = InputAttackLimit.GetValue();
	if( Mod.Settings.AttackLimit == nil)then
		Mod.Settings.AttackLimit = defaultValue;
	end
	if( Mod.Settings.AttackLimit < -1)then
		alert('If you have a good idea for what negative moves could mean in a game, chat me up & I might add it in.');
	end
	if( Mod.Settings.AttackLimit > 100000)then
		alert('The number is too big. Use -1 for unlimited multi-attacks.');
	end

	Mod.Settings.TransferLimit = InputTransferLimit.GetValue();
	if( Mod.Settings.TransferLimit == nil)then
		Mod.Settings.TransferLimit = defaultValue;
	end
	if( Mod.Settings.TransferLimit < -1)then
		alert('If you have a good idea for what negative moves could mean in a game, chat me up & I might add it in.');
	end
	if( Mod.Settings.TransferLimit > 100000)then
		alert('The number is too big. Use -1 for unlimited multi-transfers.');
	end]]
end