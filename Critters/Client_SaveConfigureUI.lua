require("utilities");

function Client_SaveConfigureUI (alert, addCard)
	if (Mod.Settings.DeneutralizeRange < 1 or Mod.Settings.DeneutralizeRange > 4000) then UI.Alert ("Range must be between 1-4000"); return; end

	local strDeneutralizeDesc = "Take ownership (or assign to another player) of a neutral territory within " ..tostring (Mod.Settings.DeneutralizeRange) .. " steps from a territory you own already. ";
	if ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == true) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == true)) then
			strDeneutralizeDesc = strDeneutralizeDesc .. "This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).";
	elseif ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == true) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == false)) then
			strDeneutralizeDesc = strDeneutralizeDesc .. "This can only be done on territories that were Neutralized (used a Neutralize card).";
	elseif ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == false) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == true)) then
			strDeneutralizeDesc = strDeneutralizeDesc .. "This can only be done on natural neutral territories (started as neutrals, were blockaded, etc).";
	else
			--this means both settings are false, which doesn't make sense, the card would never be able to be played; spawn error and cancel
			alert('Deneutralize cards must apply to natural neutral territories, Neutralized territories by use of a Neutralize card, or both options.');
	end
	strDeneutralizeDesc = strDeneutralizeDesc .. "\n\nDeneutralize executes in turn phase '" ..WL.TurnPhase.ToString (Mod.Settings.DeneutralizeImplementationPhase).. "'. ";
	Mod.Settings.DeneutralizeCardID = addCard ("Deneutralize", strDeneutralizeDesc, "deneutralize_greenback2_130x180.png", Mod.Settings.DeneutralizePiecesNeeded, Mod.Settings.DeneutralizePiecesPerTurn, Mod.Settings.DeneutralizeStartPieces, Mod.Settings.DeneutralizeCardWeight);
	Mod.Settings.DeneutralizeDescription = strDeneutralizeDesc;
end