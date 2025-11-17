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

	strBombPlusDesc = strBombPlusDesc .. "Special Units do not take damage.\n\nThis card will execute during the '" ..(tostring (WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase ~= nil and Mod.Settings.BombImplementationPhase) or (Mod.Settings.delayed == false and WL.TurnPhase.BombCards or WL.TurnPhase.ReceiveCards))).. "' turn phase."
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