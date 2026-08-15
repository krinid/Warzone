function Client_SaveConfigureUI (rootParent)
    Mod.Settings.SimpleConfig = NIFsimpleConfig.GetValue ();
	-- UI.Alert (tostring (NIFsimpleConfig.GetValue ()) ..", " .. tostring (Mod.Settings.SimpleConfig));
end