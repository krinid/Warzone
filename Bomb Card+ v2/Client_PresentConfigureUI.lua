
function Client_PresentConfigureUI(rootParent)
	local killPercentage = Mod.Settings.killPercentage;
	if killPercentage == nil then killPercentage = 25; end

	local delayed = Mod.Settings.delayed;
	if delayed == nil then delayed = false; end

	local armiesKilled = Mod.Settings.armiesKilled;
	if armiesKilled == nil then armiesKilled = 10; end

	local boolSpecialUnitsPreventNeutral = Mod.Settings.SpecialUnitsPreventNeutral;
	if (boolSpecialUnitsPreventNeutral == nil) then boolSpecialUnitsPreventNeutral = true; end

	local intBombImplementationPhase = Mod.Settings.BombImplementationPhase;
	if (intBombImplementationPhase == nil) then intBombImplementationPhase = false; end

	local boolEmptyTerritoriesGoNeutral = Mod.Settings.EmptyTerritoriesGoNeutral;
	if (boolEmptyTerritoriesGoNeutral == nil) then boolEmptyTerritoriesGoNeutral = true; end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local row1 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row1).SetText('Damage (%): ');
    killPercentageInput = UI.CreateNumberInputField(row1)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(100)
		.SetValue(killPercentage);

	local row2 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row2).SetText('Fixed damage: ');
    armiesKilledInput = UI.CreateNumberInputField(row2)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(25)
		.SetValue(armiesKilled);

	UI.CreateLabel(vert).SetText('[% damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]');

	UI.CreateLabel (vert).SetText ("\n");
	UI.CreateEmpty (vert);
    cboxEmptyTerritoriesGoNeutral = UI.CreateCheckBox(UI.CreateHorizontalLayoutGroup(vert)).SetIsChecked(boolEmptyTerritoriesGoNeutral).SetText ("Territories reduced to 0 armies turn Neutral").SetIsChecked (boolEmptyTerritoriesGoNeutral);

	local row3 = UI.CreateHorizontalLayoutGroup(vert);
	-- UI.CreateLabel(row4).SetText('Special Units prevent territory from turning neutral after bombing: ');
    specialUnitsInput = UI.CreateCheckBox(row3).SetIsChecked(boolSpecialUnitsPreventNeutral).SetText ("Special Units prevent territory from turning neutral");
	UI.CreateLabel(vert).SetText('  - when checked, a Bombed territory reduced to 0 will not turn neutral if it has 1 or more Special Units on it, eg: Commanders, Behemoths, Dragons, Recruiters, Workers, etc');
	UI.CreateLabel(vert).SetText('  - when unchecked, a Bombed territory reduced to 0 will turn neutral, even if it has Special Units on it');

	local row4a = UI.CreateHorizontalLayoutGroup(vert);
	local row4b = UI.CreateHorizontalLayoutGroup(vert);
	-- UI.CreateLabel(row3).SetText('Delayed: off = card happens at the beggining of the turn, on = card happens at the end of the turn.');
	local labelBombImplentationPhase = UI.CreateLabel(row4a);
	cboxBombPhaseDelayed = UI.CreateCheckBox(row4b).SetIsChecked(delayed).SetText ("Check to move Bomb impacts to end of turn").SetOnValueChanged (function () displayBombPhaseText (labelBombImplentationPhase, cboxBombPhaseDelayed.GetIsChecked()); end);
	displayBombPhaseText (labelBombImplentationPhase, delayed);
	UI.CreateLabel(vert).SetText("  - unchecked - normal Bomb functionality @ start of turn after deployments, before orders\n  - checked - Bombs are executed at the end of the turn, after all orders have been processed");
	-- if (Mod.Settings.BombImplementationPhase == nil) then Mod.Settings.BombImplementationPhase = WL.TurnPhase.BombCards; end
	-- BombImplementationPhase = UI.CreateButton (row4a).SetInteractable(true).SetText(Mod.Settings.BombImplementationPhase).SetOnClick(Bomb_turnPhaseButton_clicked);

end

function displayBombPhaseText (labelObject, boolDelayed)
	local strBombImplementationPhase = "Start of turn";
	if (boolDelayed == true) then strBombImplementationPhase = "End of turn"; end
	labelObject.SetText('\nTurn phase where bombs are executed: ' .. strBombImplementationPhase);
	-- UI.Alert ('\nTurn phase where bombs are executed: ' .. strBombImplementationPhase);
end

function Bomb_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	for k,v in pairs(WLturnPhases()) do
		print ("newObj item=="..k,v.."::");
		table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Bomb_turnPhase_selected({name=k,value=v}); end});
	end

	UI.PromptFromList ("Select turn phase where Bomb cards will occur.\n\nThe default is BombCards, where bombs usually occur in core Warzone, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Bomb_turnPhase_selected (turnPhase)
	print ("turnPhase selected=="..tostring(turnPhase));
	print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	-- printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	BombImplementationPhase.SetText (turnPhase.name);
end