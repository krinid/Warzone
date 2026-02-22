function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel(rootParent).SetText('Deployment limit: ' .. tostring (Mod.Settings.MaxDeploy));
	UI.CreateLabel(rootParent).SetText('  (# of deployments permitted on a single territory)');
end