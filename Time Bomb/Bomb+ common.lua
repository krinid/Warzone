function get_BombPlus_description ()
	local strBombPlusDesc = "Target a neighbouring enemy territory to inflict ";
	if (Mod.Settings.ArmyDamagePercent == 0 and Mod.Settings.ArmyDamageFixed == 0) then strBombPlusDesc = strBombPlusDesc .. "no ";
	elseif (Mod.Settings.ArmyDamagePercent ~= 0 and Mod.Settings.ArmyDamageFixed == 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.ArmyDamagePercent).. "% ";
	elseif (Mod.Settings.ArmyDamagePercent == 0 and Mod.Settings.ArmyDamageFixed ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.ArmyDamageFixed).. " ";
	elseif (Mod.Settings.ArmyDamagePercent ~= 0 and Mod.Settings.ArmyDamageFixed ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.ArmyDamagePercent).. "% + " ..tostring (Mod.Settings.ArmyDamageFixed).. " ";
	end

	strBombPlusDesc = strBombPlusDesc .. "damage to armies, and ";

	if (Mod.Settings.SUdamagePercent == 0 and Mod.Settings.SUdamageFixed == 0) then strBombPlusDesc = strBombPlusDesc .. "no ";
	elseif (Mod.Settings.SUdamagePercent ~= 0 and Mod.Settings.SUdamageFixed == 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.SUdamagePercent).. "% ";
	elseif (Mod.Settings.SUdamagePercent == 0 and Mod.Settings.SUdamageFixed ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.SUdamageFixed).. " ";
	elseif (Mod.Settings.SUdamagePercent ~= 0 and Mod.Settings.SUdamageFixed ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.SUdamagePercent).. "% + " ..tostring (Mod.Settings.SUdamageFixed).. " ";
	end

	strBombPlusDesc = strBombPlusDesc .. "damage to Special Units.\n\n";

	if (Mod.Settings.EmptyTerritoriesGoNeutral == true) then
		strBombPlusDesc = strBombPlusDesc .. "If the target territory is reduced to 0 armies";
		if (Mod.Settings.SpecialUnitsPreventNeutral == true) then strBombPlusDesc = strBombPlusDesc .." and 0 Special Units"; end
		strBombPlusDesc = strBombPlusDesc ..", it will turn neutral"
		if (Mod.Settings.SpecialUnitsPreventNeutral == false) then strBombPlusDesc = strBombPlusDesc .." and you will lose control of any Special Units present on the territory at that time.";
		end
	end

	strBombPlusDesc = strBombPlusDesc .. "\n\nThis card will execute during the '" ..WL.TurnPhase.ToString (tonumber (Mod.Settings.BombImplementationPhase)).. "' turn phase.";
	-- strBombPlusDesc = strBombPlusDesc .. "Special Units do not take damage.\n\nThis card will execute during the '" ..(tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase ~= nil and Mod.Settings.BombImplementationPhase) or (Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards))).. "' turn phase.";
	-- UI.Alert ("BombImplementationPhase " ..tostring (Mod.Settings.BombImplementationPhase).. ", " ..tostring (Mod.Settings.delayed) .." --> ".. strBombPlusDesc);
	return (strBombPlusDesc);
end

function WLturnPhases ()
	--WLturnPhases = {'CardsWearOff', 'Purchase', 'Discards', 'OrderPriorityCards', 'SpyingCards', 'ReinforcementCards', 'Deploys', 'BombCards', 'EmergencyBlockadeCards', 'Airlift', 'Gift', 'Attacks', 'BlockadeCards', 'DiplomacyCards', 'SanctionCards', 'ReceiveCards', 'ReceiveGold'};
	local WLturnPhasesTable = {
		['CardsWearOff'] = WL.TurnPhase.CardsWearOff,
		['Purchase'] = WL.TurnPhase.Purchase,
		['Discards'] = WL.TurnPhase.Discards,
		['OrderPriorityCards'] = WL.TurnPhase.OrderPriorityCards,
		['SpyingCards'] = WL.TurnPhase.SpyingCards,
		['ReinforcementCards'] = WL.TurnPhase.ReinforcementCards,
		['Deploys'] = WL.TurnPhase.Deploys,
		['BombCards'] = WL.TurnPhase.BombCards,
		['EmergencyBlockadeCards'] = WL.TurnPhase.EmergencyBlockadeCards,
		['Airlift'] = WL.TurnPhase.Airlift,
		['Gift'] = WL.TurnPhase.Gift,
		['Attacks'] = WL.TurnPhase.Attacks,
		['BlockadeCards'] = WL.TurnPhase.BlockadeCards,
		['DiplomacyCards'] = WL.TurnPhase.DiplomacyCards,
		['SanctionCards'] = WL.TurnPhase.SanctionCards,
		['ReceiveCards'] = WL.TurnPhase.ReceiveCards,
		['ReceiveGold'] = WL.TurnPhase.ReceiveGold
	};
	return WLturnPhasesTable;
end