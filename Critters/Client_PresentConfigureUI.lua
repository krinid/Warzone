require("utilities");

function Client_PresentConfigureUI (rootParent)
	local vertCrittersSettingsHeading = UI.CreateVerticalLayoutGroup (rootParent);
	local vertCrittersSettingsDetails = UI.CreateVerticalLayoutGroup (vertCrittersSettingsHeading);
	local UIcontainer = vertCrittersSettingsDetails;

	Mod.Settings.CrittersPiecesNeeded = Mod.Settings.CrittersPiecesNeeded ~= nil and Mod.Settings.CrittersPiecesNeeded or 10;
	Mod.Settings.CrittersStartPieces = Mod.Settings.CrittersStartPieces ~= nil and Mod.Settings.CrittersStartPieces or 1;
	Mod.Settings.CrittersPiecesPerTurn = Mod.Settings.CrittersPiecesPerTurn ~= nil and Mod.Settings.CrittersPiecesPerTurn or 1;
	Mod.Settings.CrittersCardWeight = Mod.Settings.CrittersCardWeight ~= nil and Mod.Settings.CrittersCardWeight or 1.0;

	Mod.Settings.CrittersRange = Mod.Settings.CrittersRange ~= nil and Mod.Settings.CrittersRange or 2;
	Mod.Settings.CrittersCanAssignToAnotherPlayer = Mod.Settings.CrittersCanAssignToAnotherPlayer ~= nil and Mod.Settings.CrittersCanAssignToAnotherPlayer or true;
	Mod.Settings.CrittersCanAssignToSelf = Mod.Settings.CrittersCanAssignToSelf ~= nil and Mod.Settings.CrittersCanAssignToSelf or false;
	Mod.Settings.CrittersImplementationPhase = Mod.Settings.CrittersImplementationPhase ~= nil and Mod.Settings.CrittersImplementationPhase or WL.TurnPhase.ReceiveCards;

	-- Mod.Settings.CrittersCanUseOnNaturalNeutrals = CrittersCanUseOnNaturalNeutrals.GetIsChecked();
	-- Mod.Settings.CrittersCanUseOnNeutralizedTerritories = CrittersCanUseOnNeutralizedTerritories.GetIsChecked();

	local CrittersDetailslineCardDesc = UI.CreateVerticalLayoutGroup (UIcontainer);
	UI.CreateLabel (CrittersDetailslineCardDesc).SetText("Assign ownership of a neutral territory to a player. Any Special Units on the territory will be assigned to the new owner. Exception: Commanders will remain owned by the original owner. When a territory owned by a player contains a Commander owned by another player, neither player will be able to control the Commander, but death of the Commander still eliminates the player that owns the Commander.\n");

	local horzCrittersRange = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzCrittersRange).SetText("\nRange: ");
	CrittersRange = UI.CreateNumberInputField (horzCrittersRange).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CrittersRange or 2).SetWholeNumbers(true).SetInteractable(true);
	UI.CreateLabel (UIcontainer).SetText("  (Distance [# territories] from any territory you own already where Critters can be used)"); --.SetColor (getColourCode ("subheading"));

	local horzCrittersImplementationPhase = UI.CreateHorizontalLayoutGroup(UIcontainer);
	UI.CreateEmpty (UIcontainer);
	UI.CreateLabel(horzCrittersImplementationPhase).SetText('Turn phase where Critters is executed: ');
	CrittersImplementationPhase = Mod.Settings.CrittersImplementationPhase or 47;
	CrittersImplementationPhaseButton = UI.CreateButton (horzCrittersImplementationPhase).SetInteractable (true).SetText (tostring (WL.TurnPhase.ToString (CrittersImplementationPhase))).SetOnClick (Critters_turnPhaseButton_clicked);

	horzCrittersCanUseOnNaturalNeutrals = UI.CreateHorizontalLayoutGroup (UIcontainer);
	CrittersCanUseOnNaturalNeutrals = UI.CreateCheckBox (horzCrittersCanUseOnNaturalNeutrals).SetIsChecked(Mod.Settings.CrittersCanUseOnNaturalNeutrals).SetInteractable(true).SetText("Can use on natural neutrals (not caused by Neutralize)");

	horzCrittersCanUseOnNeutralizedTerritories = UI.CreateHorizontalLayoutGroup (UIcontainer);
	CrittersCanUseOnNeutralizedTerritories = UI.CreateCheckBox (horzCrittersCanUseOnNeutralizedTerritories).SetIsChecked(Mod.Settings.CrittersCanUseOnNeutralizedTerritories).SetInteractable(true).SetText("Can use on Neutralized territories");

	--set UI controls for Assign to self & Assign to another player to be non-interactive (greyed out) and default values to True & False respectively
	--not implementing these options at this time, so default to assign Critters action to self only
	horzCrittersCanAssignToSelf = UI.CreateHorizontalLayoutGroup (UIcontainer);
	CrittersCanAssignToSelf = UI.CreateCheckBox (horzCrittersCanAssignToSelf).SetIsChecked(Mod.Settings.CrittersCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");
	--CrittersCanAssignToSelf = UI.CreateCheckBox (horzCrittersCanAssignToSelf).SetIsChecked(Mod.Settings.CrittersCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");

	horzCrittersCanAssignToAnotherPlayer = UI.CreateHorizontalLayoutGroup (UIcontainer);
	CrittersCanAssignToAnotherPlayer = UI.CreateCheckBox (horzCrittersCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.CrittersCanAssignToAnotherPlayer).SetInteractable(true).SetText("Can assign to another player");
	--CrittersCanAssignToAnotherPlayer = UI.CreateCheckBox (horzCrittersCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.CrittersCanAssignToAnotherPlayer).SetInteractable(true).SetText("Can assign to another player");

	horzCrittersCardPiecesNeeded = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzCrittersCardPiecesNeeded).SetText("Number of pieces to divide the card into: ")
	CrittersCardPiecesNeeded = UI.CreateNumberInputField (horzCrittersCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CrittersPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

	horzCrittersCardStartPieces = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzCrittersCardStartPieces).SetText("Pieces given to each player at the start: ")
	CrittersCardStartPieces = UI.CreateNumberInputField (horzCrittersCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CrittersStartPieces).SetWholeNumbers(true).SetInteractable(true);

	local horzCrittersPiecesPerTurn = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzCrittersPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
	CrittersPiecesPerTurn = UI.CreateNumberInputField (horzCrittersPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CrittersPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

	local horzCrittersCardWeight = UI.CreateHorizontalLayoutGroup (UIcontainer);
	UI.CreateLabel (horzCrittersCardWeight).SetText("Card weight: ");
	CrittersCardWeight = UI.CreateNumberInputField (horzCrittersCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetWholeNumbers(false).SetValue(Mod.Settings.CrittersCardWeight).SetInteractable(true);
end

function Critters_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	-- for k,v in pairs(WLturnPhases()) do
	for k,v in pairs(WL.TurnPhase) do
		print ("newObj item=="..tostring(k),tostring(v));
		if (tostring (k)) ~= "ToString" then table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Critters_turnPhase_selected({name=k,value=v}); end}); end
	end

	UI.PromptFromList ("Select turn phase where Bomb cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Critters_turnPhase_selected (turnPhase)
	print ("turnPhase selected=="..tostring(turnPhase));
	print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	Mod.Settings.CrittersImplementationPhase = turnPhase.value;
	CrittersImplementationPhase = turnPhase.value;
	CrittersImplementationPhaseButton.SetText (turnPhase.name);
end