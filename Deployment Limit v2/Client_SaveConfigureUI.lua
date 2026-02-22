
function Client_SaveConfigureUI(alert)
    Mod.Settings.MaxDeploy = InputMaxDeploy.GetValue();
	if (Mod.Settings.MaxDeploy == nil)then
		Mod.Settings.MaxDeploy = 5;
	elseif (Mod.Settings.MaxDeploy < 1) then
		-- alert('Limit must be 1 or higher. Setting to less than 1 would make any deployments imposisble.'); --but so what - maybe that's the point, to only allow army accumulation through other means (like recruiters, etc)
		Mod.Settings.MaxDeploy = 0; --ensure value isn't negative as this doesn't have any meaning
	elseif (Mod.Settings.MaxDeploy > 100000)then
		Mod.Settings.MaxDeploy = 100000; --cap at 100,000
	end
end