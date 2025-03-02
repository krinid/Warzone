
function Client_PresentSettingsUI(rootParent)
	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	local vert = UI.CreateVerticalLayoutGroup(rootParent);
	local strMessage = "This is the number of Attack or Transfer orders units may partake in. Any Attack or Transfer orders entered beyond this limit will be skipped.";
	if (Mod.Settings.MoveLimit == 0) then strMessage = "No attacks or transfers are allowed. Units will remain stationary until the following turn. You must rely or Cards or other Mod functionality to make attacks.";
	elseif (Mod.Settings.MoveLimit == -1) then strMessage = "Attacks or transfers are unlimited.";
	end
	UI.CreateLabel(vert).SetText("Move limit: "..Mod.Settings.MoveLimit).SetColor('#00B5FF');
	UI.CreateLabel(vert).SetText(strMessage);
	--UI.CreateButton(horz).SetText('?').SetColor('#00B5FF').SetOnClick(function() UI.Alert("This value is the number of move orders units may partake in. They can be either Transfers or Attacks. Any moves entered beyond this limit will be skipped."); end);
end