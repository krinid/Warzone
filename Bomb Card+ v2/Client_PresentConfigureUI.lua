
function Client_PresentConfigureUI(rootParent)
	local killPercentage = Mod.Settings.killPercentage;
	if killPercentage == nil then killPercentage = 50; end

	local delayed = Mod.Settings.delayed;
	if delayed == nil then delayed = false; end

	local armiesKilled = Mod.Settings.armiesKilled;
	if armiesKilled == nil then armiesKilled = 0; end

	local boolSpecialUnitsPreventNeutral = Mod.Settings.SpecialUnitsPreventNeutral;
	if (boolSpecialUnitsPreventNeutral == nil) then boolSpecialUnitsPreventNeutral = false; end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

    local row1 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row1).SetText('Damage (%):');
    killPercentageInput = UI.CreateNumberInputField(row1)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(100)
		.SetValue(killPercentage);

	local row2 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row2).SetText('Fixed damage:');
    armiesKilledInput = UI.CreateNumberInputField(row2)
		.SetSliderMinValue(0)
		.SetSliderMaxValue(15)
		.SetValue(armiesKilled);
	UI.CreateLabel(vert).SetText('[% damage is applied first, the fixed damage is applied; eg: if configured to 25% damage + 10 fixed damage, a target territory with 100 armies would be reduced to 65 (100*0.75-10)]');

	local row3 = UI.CreateHorizontalLayoutGroup(vert);
	-- UI.CreateLabel(row3).SetText('Delayed: off = card happens at the beggining of the turn, on = card happens at the end of the turn.');
	UI.CreateLabel(row3).SetText('\nTurn phase where bombs are executed:');
    delayedInput = UI.CreateCheckBox(row3).SetIsChecked(delayed);
	BombImplementationPhase = CreateButton(row3).SetInteractable(true).SetText(Mod.Settings.BombImplementationPhase).SetOnClick(Bomb_turnPhaseButton_clicked);

	local row4 = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row4).SetText('Special Units prevent territory from turning neutral after bombing');
    specialUnitsInput = UI.CreateCheckBox(row4).SetIsChecked(boolSpecialUnitsPreventNeutral);
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
	printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	BombImplementationPhase.SetText (turnPhase.name);
end