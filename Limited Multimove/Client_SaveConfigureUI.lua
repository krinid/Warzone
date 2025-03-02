
function Client_SaveConfigureUI(alert)
	local defaultValue = 5;
	Mod.Settings.MoveLimit = InputMoveLimit.GetValue();
	if( Mod.Settings.MoveLimit == nil)then
		Mod.Settings.MoveLimit = defaultValue;
	end
	if( Mod.Settings.MoveLimit < -1)then
		alert('[Limited Multimoves] If you have a clever idea for how negative moves might be implemented in a meaningful way in a game, chat me up & I might add it in.');
	end
	if( Mod.Settings.MoveLimit > 1000)then
		alert('[Limited Multimoves] 1000+ is too a high a limit; use -1 for unlimited or enter a reasonable limit.');
	end
	--[[if (game.Settings.MultiAttack == false) then
		alert("[Limited Multimoves] Multi-Attack must be enabled for this mod to function. Please enable Multi-Attack in game settings or unselect this mod.");
	end]] --would be nice to be able to do this but game doesn't exist yet! Can't access Settings of a game that hasn't been started yet

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