function get_BombPlus_description ()
	local strBombPlusDesc = "Target a neighbouring enemy territory to inflict ";
	if (Mod.Settings.killPercentage == 0 and Mod.Settings.armiesKilled == 0) then strBombPlusDesc = strBombPlusDesc .. "0 ";
	elseif (Mod.Settings.killPercentage ~= 0 and Mod.Settings.armiesKilled == 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.killPercentage).. "% ";
	elseif (Mod.Settings.killPercentage == 0 and Mod.Settings.armiesKilled ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.armiesKilled).. " ";
	elseif (Mod.Settings.killPercentage ~= 0 and Mod.Settings.armiesKilled ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.killPercentage).. "% + " ..tostring (Mod.Settings.armiesKilled).. " ";
	end

	strBombPlusDesc = strBombPlusDesc .. "damage.\n\n";

	if (Mod.Settings.EmptyTerritoriesGoNeutral == true) then strBombPlusDesc = strBombPlusDesc .. "If the target territory is reduced to 0 armies, it will turn neutral ";
		if (Mod.Settings.SpecialUnitsPreventNeutral == true) then strBombPlusDesc = strBombPlusDesc .."unless a Special Unit is present. ";
		else strBombPlusDesc = strBombPlusDesc .."and you will lose control of any Special Units present at that time. ";
		end
	end

	strBombPlusDesc = strBombPlusDesc .. "Special Units do not take damage.\n\nThis card will execute at the ";

	if (Mod.Settings.delayed == true) then strBombPlusDesc = strBombPlusDesc .. "end of the turn (after attack/transfer orders are processed).";
	else strBombPlusDesc = strBombPlusDesc .. "start of the turn (after deployments but before attacks).";
	end
	return (strBombPlusDesc);
end