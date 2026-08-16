require("utilities");

function Client_SaveConfigureUI (alert, addCard)
	if (Mod.Settings.CrittersRange < 1 or Mod.Settings.CrittersRange > 4000) then UI.Alert ("Range must be between 1-4000"); return; end

	local strCrittersDesc = "Take ownership (or assign to another player) of a neutral territory within " ..tostring (Mod.Settings.CrittersRange) .. " steps from a territory you own already. ";
	if ((Mod.Settings.CrittersCanUseOnNeutralizedTerritories == true) and (Mod.Settings.CrittersCanUseOnNaturalNeutrals == true)) then
			strCrittersDesc = strCrittersDesc .. "This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).";
	elseif ((Mod.Settings.CrittersCanUseOnNeutralizedTerritories == true) and (Mod.Settings.CrittersCanUseOnNaturalNeutrals == false)) then
			strCrittersDesc = strCrittersDesc .. "This can only be done on territories that were Neutralized (used a Neutralize card).";
	elseif ((Mod.Settings.CrittersCanUseOnNeutralizedTerritories == false) and (Mod.Settings.CrittersCanUseOnNaturalNeutrals == true)) then
			strCrittersDesc = strCrittersDesc .. "This can only be done on natural neutral territories (started as neutrals, were blockaded, etc).";
	else
			--this means both settings are false, which doesn't make sense, the card would never be able to be played; spawn error and cancel
			alert('Critters cards must apply to natural neutral territories, Neutralized territories by use of a Neutralize card, or both options.');
	end
	strCrittersDesc = strCrittersDesc .. "\n\nCritters executes in turn phase '" ..WL.TurnPhase.ToString (Mod.Settings.CrittersImplementationPhase).. "'. ";
	Mod.Settings.CrittersCardID = addCard ("Critters", strCrittersDesc, "Critters_greenback2_130x180.png", Mod.Settings.CrittersPiecesNeeded, Mod.Settings.CrittersPiecesPerTurn, Mod.Settings.CrittersStartPieces, Mod.Settings.CrittersCardWeight);
	Mod.Settings.CrittersDescription = strCrittersDesc;


	Mod.Settings.CrittersRange = CrittersRange.GetValue ();
	Mod.Settings.CrittersImplementationPhase = CrittersImplementationPhase;
	Mod.Settings.CrittersPiecesNeeded = CrittersCardPiecesNeeded.GetValue();
	Mod.Settings.CrittersStartPieces = CrittersCardStartPieces.GetValue();
	Mod.Settings.CrittersCanUseOnNaturalNeutrals = CrittersCanUseOnNaturalNeutrals.GetIsChecked();
	Mod.Settings.CrittersCanUseOnNeutralizedTerritories = CrittersCanUseOnNeutralizedTerritories.GetIsChecked();
	Mod.Settings.CrittersCanAssignToSelf = CrittersCanAssignToSelf.GetIsChecked();
	Mod.Settings.CrittersCanAssignToAnotherPlayer = CrittersCanAssignToAnotherPlayer.GetIsChecked();
	Mod.Settings.CrittersCardWeight = CrittersCardWeight.GetValue();
	Mod.Settings.CrittersPiecesPerTurn = CrittersPiecesPerTurn.GetValue();
end