
function Client_SaveConfigureUI(alert)
   	Mod.Settings.MaxAttacks = InputMaxAttacks.GetValue();
	if( Mod.Settings.MaxAttacks == nil)then
		Mod.Settings.MaxAttacks = 5;
	end
	if( Mod.Settings.MaxAttacks < 0)then
		alert('If you can explain me what you understand under negative transfers, I will add it.');
	end
	if( Mod.Settings.MaxAttacks > 100000)then
		alert('The number is too big.');
	end
end