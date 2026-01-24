--TODOs:
-- - include functionality to surround neutrals (which is timely b/c Weaken Blockades has had errors during configuration since the 'accessed a destroyed object' upgrade)
-- - eliminate orders that don't actually have any effect (actually this is for WB not Encircle -- after neutrals have gone to 0, it continues to add orders each turn to reduce them)
-- - add configurable functionality to block gifts, airlifts in/out of surrounded territories 
-- - add 'advanced mode' to encircle (can encircle from a configurable distance)
-- - configurable varying % reductions based on the surround distance, eg:
-- 	- surrounding from 3 doesn't stop reinforcements but causes loss of 1 unit/turn
-- 	- surrounding from 2 doesn't stop reinforcements but causes loss of 10% units/turn + blocks airlifts
-- 	- direct surround (from 1) stops reinforcements and causes loss of 30% units/turn
-- - add support for teams (can't encircle teammates)
-- - configurable if SUs prevent going to neutral or not
-- - weaken blockades: can weaken SUs over time; both Health & DTK goes down X% per turn and die @ 0

require("UI");

function Client_PresentConfigureUI(rootParent)
    --Encirclement:
	Init(rootParent);
    root = GetRoot();
    CreateLabel(root).SetText("[ENCIRCLEMENT]").SetColor("#FFFF00").SetFlexibleWidth(1);
    CreateLabel(root).SetText("(1+ players surrounding 1 single territory of another player)").SetColor("#00FFFF").SetFlexibleWidth(1);
    textColor = GetColors().TextColor;

	mainWin = "mainWindow"
    SetWindow(mainWin);

    disallowDeployments = Mod.Settings.DoNotAllowDeployments or true; --default to true, deployments not allowed when encircled
    removeArmies = Mod.Settings.RemoveArmiesFromEncircledTerrs or true; --default to true, reduce armies when encircled
    turnNeutral = Mod.Settings.TerritoriesTurnNeutral or false; --default to false, don't immediately turn terr neutral when encircled (this is too harsh)
    percentageLost = Mod.Settings.PercentageLost or 34; --default to 34% army reduction

    local line = CreateHorz(root).SetFlexibleWidth(1);
    disallowDeploymentsInput = CreateCheckBox(line).SetText(" ").SetIsChecked(disallowDeployments);
    CreateLabel(line).SetText("Cannot deployment armies on encircled territories").SetColor(textColor);

    line = CreateHorz(root).SetFlexibleWidth(1);
    removeArmiesInput = CreateCheckBox(line).SetText(" ").SetIsChecked(removeArmies).SetOnValueChanged(updateSubWindow);
    CreateLabel(line).SetText("Reduce armies on encircled territories").SetColor(textColor);
	CreateLabel(root).SetText("Note that encircled territories with 1 or 0 armies will always turn neutral").SetColor(textColor);

	local horz = UI.CreateHorizontalLayoutGroup (root).SetFlexibleWidth(1);
	local vert1 = UI.CreateVerticalLayoutGroup (horz).SetFlexibleWidth(0.1); --used for spacing only, has no content; this causes the vert2 panel to shift right and appear indented underneathg the previous label
	local vert2 = UI.CreateVerticalLayoutGroup (horz).SetFlexibleWidth(0.9); --
	local line = CreateHorz(vert2).SetFlexibleWidth(1);
    turnNeutralInput = CreateCheckBox(line).SetText(" ").SetIsChecked(turnNeutral).SetOnValueChanged(updateSubWindow).SetInteractable(removeArmiesInput.GetIsChecked());
    CreateLabel(line).SetText("Territories immediately turn neutral").SetColor(textColor);

	local line = CreateHorz(vert2).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Army reduction amount (%): ").SetColor(textColor);
    percentageLostInput = CreateNumberInputField(line).SetWholeNumbers(false).SetSliderMinValue(10).SetSliderMaxValue(90).SetValue(percentageLost).SetInteractable(removeArmiesInput.GetIsChecked() and not turnNeutralInput.GetIsChecked());

	--Weaken Blockades:
	local mainContainer = CreateVerticalLayoutGroup(rootParent)     --The main container I guess

    CreateLabel(mainContainer).SetText("[WEAKEN BLOCKADES]").SetColor("#FFFF00").SetFlexibleWidth(1);
    CreateLabel(mainContainer).SetText("(1 single player surrounding neutral territories)").SetColor("#00FFFF").SetFlexibleWidth(1);

	if Mod.Settings.WeakenBlockades == nil then
		Mod.Settings.WeakenBlockades = {}
	end

	percentualOrFixed = Mod.Settings.WeakenBlockades.percentualOrFixed or false; --default to false; false == use % amount
	fixedArmiesRemoved = Mod.Settings.WeakenBlockades.fixedArmiesRemoved or 10;
	percentualArmiesRemoved = Mod.Settings.WeakenBlockades.percentualArmiesRemoved or 51;
	delayFromStart = Mod.Settings.WeakenBlockades.delayFromStart or 0;
	appliesToAllNeutrals = Mod.Settings.WeakenBlockades.appliesToAllNeutrals or true;
	appliesToMinArmies = Mod.Settings.WeakenBlockades.appliesToMinArmies or 25;
	ADVANCEDVERSION = Mod.Settings.WeakenBlockades.ADVANCEDVERSION or true;

	CreateLabel (mainContainer).SetText ("Army reduction method: ");
	horzPercentOrFixed = CreateHorz(mainContainer);
	groupPercentOrFixed = UI.CreateRadioButtonGroup(horzPercentOrFixed);
	PercentOrFixed_Fixed = UI.CreateRadioButton(horzPercentOrFixed).SetGroup(groupPercentOrFixed).SetText('Fixed amount').SetIsChecked (percentualOrFixed).SetOnValueChanged (function () typeOfRemovalFnt (); end);
	PercentOrFixed_Percent = UI.CreateRadioButton(horzPercentOrFixed).SetGroup(groupPercentOrFixed).SetText('Percentage').SetIsChecked (not percentualOrFixed).SetOnValueChanged (function () typeOfRemovalFnt (); end);
	CreateLabel (mainContainer).SetText("• Fixed - armies are reduced by a predetermined amount\n• Percentage - armies are reduced by a percentage of the armies present\n");

	local pofCont = CreateVerticalLayoutGroup(mainContainer); -- parent vert for % or fixed; holds the spot in the main window
	local pofSubCont = CreateVerticalLayoutGroup(pofCont); -- subcontainer for % or fixed; this gets destroyed whenever switching between fixed and % options

	function typeOfRemovalFnt()
	-- UI.Alert (tostring (check)..", "..tostring (percentualOrFixed) ..", "..tostring(check == percentualOrFixed));
		percentualOrFixed = PercentOrFixed_Fixed.GetIsChecked ();
		-- UI.Alert ("POF "..tostring (percentualOrFixed)..", farSlider " .. tostring (UI.IsDestroyed (farSlider) == false).. ", parSlider " ..tostring (UI.IsDestroyed (parSlider) == false));
		-- if (check == percentualOrFixed) then return; end

		-- print ("POF "..tostring (percentualOrFixed)..", farSlider " .. tostring (UI.IsDestroyed (farSlider) == false).. ", parSlider " ..tostring (UI.IsDestroyed (parSlider) == false));

		if (UI.IsDestroyed (parSlider) == false and percentualOrFixed == false) then return; end
		if (UI.IsDestroyed (farSlider) == false and percentualOrFixed == true) then return; end

		UI.Destroy (pofSubCont);
		pofSubCont = CreateVerticalLayoutGroup(pofCont) -- subcontainer for % or fixed; this gets destroyed whenever switching between fixed and % options

		-- percentualOrFixed = PercentOrFixed_Fixed.GetIsChecked ();
		-- UI.Alert (percentualOrFixed);
		if (percentualOrFixed == true) then
			farLabel = CreateLabel(pofSubCont).SetText("Army reduction - Fixed amount:");
			farSlider = CreateNumberInputField(pofSubCont).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(fixedArmiesRemoved);
		else
			parLabel = CreateLabel(pofSubCont).SetText("Army reduction - Percentage:");
			parSlider = CreateNumberInputField(pofSubCont).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(percentualArmiesRemoved);
		end
	end

	typeOfRemovalFnt ();

	local dlsCont = CreateHorizontalLayoutGroup(mainContainer)
	dlsLabel = CreateLabel(dlsCont).SetText("Effect begins on turn #: ");
	dlsSlider = CreateNumberInputField(dlsCont).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(delayFromStart);

	local atanCont = CreateVerticalLayoutGroup(mainContainer);

	function appliesToFnt(check)
		appliesToAllNeutrals = check
		if(check)then
			appliesToMinArmies = atmaSlider.GetValue()
			SetWindow(atmaWin)
			DestroyWindow(atmaWin)
			SetWindow(mainWin)
		else
			atmaWin = "appliesToMinArmiesWindow"
			AddSubWindow(mainWin, atmaWin);
			SetWindow(atmaWin)
			atmaCont = CreateHorizontalLayoutGroup(atanCont)															   
			atmaLabel = CreateLabel(atmaCont).SetText("Only applies to neutral territories whose armies are at least: ")				  				-- Label
			atmaSlider = CreateNumberInputField(atmaCont).SetSliderMinValue(10).SetSliderMaxValue(100).SetValue(appliesToMinArmies)
		end
	end

	CreateCheckBox(atanCont).SetIsChecked(appliesToAllNeutrals).SetText("Applies to all neutrals").SetOnValueChanged(function(IsChecked) showedreturnmessage = false; appliesToFnt(IsChecked) end)
	if appliesToAllNeutrals == false then
		appliesToFnt(appliesToAllNeutrals)
	end

	SetWindow(mainWin)
	local ADVVERCont = CreateVerticalLayoutGroup(mainContainer)
	CreateCheckBox(ADVVERCont).SetIsChecked(ADVANCEDVERSION).SetText("Use advanced version").SetOnValueChanged(function(IsChecked) showedreturnmessage = false; setADVVER(IsChecked) end)
	function setADVVER(check)
		ADVANCEDVERSION = check
	end
end

--Encirclement functions:
function updateSubWindow()
    if turnNeutralInput ~= nil then turnNeutral = turnNeutralInput.GetIsChecked(); end
    if percentageLostInput ~= nil then percentageLost = percentageLostInput.GetValue(); end
    -- DestroyWindow("subWindow", false); turnNeutralInput = nil; percentageLostInput = nil;
    -- if removeArmiesInput.GetIsChecked() then
    --     showSubWindow();
    -- end
	turnNeutralInput.SetInteractable(removeArmiesInput.GetIsChecked());
	percentageLostInput.SetInteractable(removeArmiesInput.GetIsChecked() and not turnNeutralInput.GetIsChecked());
end

function showSubWindow()
    local win = "subWindow";
    local cur = GetCurrentWindow();

	AddSubWindow(cur, win);
    SetWindow(win);

	CreateLabel(root).SetText("Note that encircled territories with 1 or 0 armies will always turn neutral").SetColor(textColor);
    local line = CreateHorz(root).SetFlexibleWidth(1);
    turnNeutralInput = CreateCheckBox(line).SetText(" ").SetIsChecked(turnNeutral).SetOnValueChanged(updateSubWindow);
    CreateLabel(line).SetText("Encircled territories immediately turn neutral").SetColor(textColor);

    local line = CreateHorz(root).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Army reduction amount (%): ").SetColor(textColor);
    percentageLostInput = CreateNumberInputField(line).SetWholeNumbers(false).SetSliderMinValue(10).SetSliderMaxValue(90).SetValue(percentageLost).SetInteractable(not turnNeutralInput.GetIsChecked());

    SetWindow(cur);
end