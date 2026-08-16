require("utilities");

function Client_PresentConfigureUI (rootParent)
	local vertDeneutralizeSettingsHeading = UI.CreateVerticalLayoutGroup (rootParent);
	local vertDeneutralizeSettingsDetails = UI.CreateVerticalLayoutGroup (vertDeneutralizeSettingsHeading);
	local UIcontainer = vertDeneutralizeSettingsDetails;

	local DeneutralizeDetailslineCardDesc = UI.CreateVerticalLayoutGroup (UIcontainer);
	UI.CreateLabel (DeneutralizeDetailslineCardDesc).SetText("Assign ownership of a neutral territory to a player. Any Special Units on the territory will be assigned to the new owner. Exception: Commanders will remain owned by the original owner. When a territory owned by a player contains a Commander owned by another player, neither player will be able to control the Commander, but death of the Commander still eliminates the player that owns the Commander.\n");

	local horzDeneutralizeRange = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzDeneutralizeRange).SetText("\nRange: ");
	DeneutralizeRange = UI.CreateNumberInputField (horzDeneutralizeRange).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizeRange or 2).SetWholeNumbers(true).SetInteractable(true);
	UI.CreateLabel (UIcontainer).SetText("  (Distance [# territories] from any territory you own already where Deneutralize can be used)"); --.SetColor (getColourCode ("subheading"));

	local horzDeneutralizeImplementationPhase = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateEmpty (UIcontainer);
	UI.CreateLabel(horzDeneutralizeImplementationPhase).SetText('Turn phase where Deneutralize is executed: ');
	DeneutralizeImplementationPhase = Mod.Settings.DeneutralizeImplementationPhase or 47;
	DeneutralizeImplementationPhaseButton = UI.CreateButton (horzDeneutralizeImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (DeneutralizeImplementationPhase))).SetOnClick (Deneutralize_turnPhaseButton_clicked);

	horzDeneutralizeCanUseOnNaturalNeutrals = UI.CreateHorizontalLayoutGroup (UIcontainer);
	DeneutralizeCanUseOnNaturalNeutrals = UI.CreateCheckBox (horzDeneutralizeCanUseOnNaturalNeutrals).SetIsChecked(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals).SetInteractable(true).SetText("Can use on natural neutrals (not caused by Neutralize)");

	horzDeneutralizeCanUseOnNeutralizedTerritories = UI.CreateHorizontalLayoutGroup (UIcontainer);
	DeneutralizeCanUseOnNeutralizedTerritories = UI.CreateCheckBox (horzDeneutralizeCanUseOnNeutralizedTerritories).SetIsChecked(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories).SetInteractable(true).SetText("Can use on Neutralized territories");

	--set UI controls for Assign to self & Assign to another player to be non-interactive (greyed out) and default values to True & False respectively
	--not implementing these options at this time, so default to assign Deneutralize action to self only
	horzDeneutralizeCanAssignToSelf = UI.CreateHorizontalLayoutGroup (UIcontainer);
	DeneutralizeCanAssignToSelf = UI.CreateCheckBox (horzDeneutralizeCanAssignToSelf).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");
	--DeneutralizeCanAssignToSelf = UI.CreateCheckBox (horzDeneutralizeCanAssignToSelf).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");

	horzDeneutralizeCanAssignToAnotherPlayer = UI.CreateHorizontalLayoutGroup (UIcontainer);
	DeneutralizeCanAssignToAnotherPlayer = UI.CreateCheckBox (horzDeneutralizeCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer).SetInteractable(true).SetText("Can assign to another player");
	--DeneutralizeCanAssignToAnotherPlayer = UI.CreateCheckBox (horzDeneutralizeCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer).SetInteractable(true).SetText("Can assign to another player");

	horzDeneutralizeCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzDeneutralizeCardPiecesNeeded).SetText("Number of pieces to divide the card into: ")
	DeneutralizeCardPiecesNeeded = UI.CreateNumberInputField (horzDeneutralizeCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

	horzDeneutralizeCardStartPieces = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzDeneutralizeCardStartPieces).SetText("Pieces given to each player at the start: ")
	DeneutralizeCardStartPieces = UI.CreateNumberInputField (horzDeneutralizeCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizeStartPieces).SetWholeNumbers(true).SetInteractable(true);

	local horzDeneutralizePiecesPerTurn = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzDeneutralizePiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
	DeneutralizePiecesPerTurn = UI.CreateNumberInputField (horzDeneutralizePiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizePiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

	local horzDeneutralizeCardWeight = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzDeneutralizeCardWeight).SetText("Card weight: ");
	DeneutralizeCardWeight = UI.CreateNumberInputField (horzDeneutralizeCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetWholeNumbers(false).SetValue(Mod.Settings.DeneutralizeCardWeight).SetInteractable(true);	

	if (Mod.Settings.DeneutralizeEnabled == nil) then
		Mod.Settings.DeneutralizeEnabled = false;
		Mod.Settings.DeneutralizeRange = 2;
		Mod.Settings.DeneutralizeImplementationPhase = WL.TurnPhase.ReceiveCards;
		Mod.Settings.DeneutralizePiecesNeeded = 10;
		Mod.Settings.DeneutralizeStartPieces = 1;
		Mod.Settings.DeneutralizePiecesPerTurn = 1;
		Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories = true;
		Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals = true;
		Mod.Settings.DeneutralizeCanAssignToSelf = true;
		Mod.Settings.DeneutralizeCanAssignToAnotherPlayer = false; --set to False for now; not implementing this option at this point; will only assign territory to self
		Mod.Settings.DeneutralizeCardWeight = 1.0;
	end

	if (not UI.IsDestroyed (vertDeneutralizeSettingsDetails)) then
		Mod.Settings.DeneutralizeRange = DeneutralizeRange.GetValue ();
		-- Mod.Settings.DeneutralizeImplementationPhase = DeneutralizeImplementationPhase.GetValue (); --this is set when the button is clicked; also the control is a Button and doesn't have a .GetValue method
		Mod.Settings.DeneutralizeImplementationPhase = DeneutralizeImplementationPhase;
		Mod.Settings.DeneutralizePiecesNeeded = DeneutralizeCardPiecesNeeded.GetValue();
		Mod.Settings.DeneutralizeStartPieces = DeneutralizeCardStartPieces.GetValue();
		Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals = DeneutralizeCanUseOnNaturalNeutrals.GetIsChecked();
		Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories = DeneutralizeCanUseOnNeutralizedTerritories.GetIsChecked();
		Mod.Settings.DeneutralizeCanAssignToSelf = DeneutralizeCanAssignToSelf.GetIsChecked();
		Mod.Settings.DeneutralizeCanAssignToAnotherPlayer = DeneutralizeCanAssignToAnotherPlayer.GetIsChecked();
		Mod.Settings.DeneutralizeCardWeight = DeneutralizeCardWeight.GetValue();
		Mod.Settings.DeneutralizePiecesPerTurn = DeneutralizePiecesPerTurn.GetValue();
	end
end

function Deneutralize_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	-- for k,v in pairs(WLturnPhases()) do
	for k,v in pairs(WL.TurnPhase) do
		print ("newObj item=="..tostring(k),tostring(v));
		if (tostring (k)) ~= "ToString" then table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Deneutralize_turnPhase_selected({name=k,value=v}); end}); end
	end

	UI.PromptFromList ("Select turn phase where Bomb cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Deneutralize_turnPhase_selected (turnPhase)
	print ("turnPhase selected=="..tostring(turnPhase));
	print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	Mod.Settings.DeneutralizeImplementationPhase = turnPhase.value;
	DeneutralizeImplementationPhase = turnPhase.value;
	DeneutralizeImplementationPhaseButton.SetText (turnPhase.name);
end