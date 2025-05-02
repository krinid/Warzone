function Client_PresentConfigureUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("This mod can make Special Units invulnerable to neutral territories and also increase their strength against neutrals.");

	UI.CreateLabel (rootParent).SetText ("_").SetColor ("#000000");
	invulnerableToNeutralsCBOX = UI.CreateCheckBox (rootParent).SetText ("Special Units invulnerable vs neutrals").SetIsChecked (boolBehemothInvulnerableToNeutrals);
	UI.CreateLabel (rootParent).SetText ("When checked, all Special Units can attack neutral territories of any size without taking damage or dying");

	local line = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (line).SetText ("Strength against neutrals: ");
	neutralStrengthNIF = UI.CreateNumberInputField (line).SetWholeNumbers(false).SetValue (intStrengthAgainstNeutrals);
	UI.CreateLabel (rootParent).SetText ("• <1.0 - reduced damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("• =1.0 - normal damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("• >1.0 - increased damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("•  "..intStrengthAgainstNeutrals_default.." - default value, ".. intStrengthAgainstNeutrals_default.. "x damage vs neutrals");

end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end