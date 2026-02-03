require("UI");
function Client_PresentSettingsUI(rootParent)
	--Encirclement:
	Init(rootParent);
    local root = GetRoot();
    local colors = GetColors();

    CreateLabel(root).SetText("[ENCIRCLEMENT]").SetColor("#FFFF00").SetFlexibleWidth(1);
    CreateLabel(root).SetText("(1+ players surrounding 1 single territory of another player)").SetColor("#00FFFF").SetFlexibleWidth(1);
    local line = CreateHorz(root);
    CreateLabel(line).SetText("Cannot deploy armies to encircled territories: ").SetColor(colors.TextColor);
    if Mod.Settings.DoNotAllowDeployments then
        CreateLabel(line).SetText("Yes").SetColor(colors.Green);
    else
        CreateLabel(line).SetText("No").SetColor(colors.Red);
    end

	line = CreateHorz(root);
    CreateLabel(line).SetText("Reduce armies on encircled territories: ").SetColor(colors.TextColor);
    if Mod.Settings.RemoveArmiesFromEncircledTerrs then
        CreateLabel(line).SetText("Yes").SetColor(colors.Green);

		line = CreateHorz(root);
        CreateLabel(line).SetText("Encircled territories immediately turn neutral: ").SetColor(colors.TextColor);
        if Mod.Settings.TerritoriesTurnNeutral then
            CreateLabel(line).SetText("Yes").SetColor(colors.Green);
        else
            CreateLabel(line).SetText("No").SetColor(colors.Red);

			line = CreateHorz(root);
            CreateLabel(line).SetText("Armies lost when encircled: ").SetColor(colors.TextColor);
            CreateLabel(line).SetText(rounding(Mod.Settings.PercentageLost, 2).."%").SetColor(colors.Cyan);
        end
    else
        CreateLabel(line).SetText("No").SetColor(colors.Red);
    end

	--Weaken Blockades:
    CreateLabel(root).SetText("\n[WEAKEN BLOCKADES]").SetColor("#FFFF00").SetFlexibleWidth(1);
    CreateLabel(root).SetText("(1 single player surrounding neutral territories)").SetColor("#00FFFF").SetFlexibleWidth(1);
	local WB = Mod.Settings.WeakenBlockades
    local vert = UI.CreateVerticalLayoutGroup(rootParent);
    if WB.percentualOrFixed then
        UI.CreateLabel(vert).SetText('• Army reduction: ' ..WB.fixedArmiesRemoved.. " (fixed amount)"); --.SetColor('#4EFFFF');
    else
        UI.CreateLabel(vert).SetText('• Army reduction: ' ..WB.percentualArmiesRemoved.. "%"); --.SetColor('#FF4EFF');
    end

    UI.CreateLabel(vert).SetText("• Effect starts on turn #" ..tostring (WB.delayFromStart +1)); --.SetColor('#FFFF4E');

	if (WB.appliesToMinArmies == 0) then
        UI.CreateLabel(vert).SetText("• Applies to all neutral territories").SetColor('#FFFF4E');
    else
        UI.CreateLabel(vert).SetText("• Only applies to neutral territories with at least " .. WB.appliesToMinArmies .. " armies").SetColor('#FFFF4E');
    end

    if WB.ADVANCEDVERSION then
        UI.CreateLabel(vert).SetText("• Neutral encircle mode: Long Range Encircle\n").SetColor('#FF0000');
        UI.CreateLabel(vert).SetText("   (blocks of neutral territories up to distance of 4 territories can be surrounded and reduced)");
    else
        UI.CreateLabel(vert).SetText("• Neutral encircle mode: Single Surround\n");
        UI.CreateLabel(vert).SetText("   (only 1 single neutral territory can be surrounded and reduced)");
	end
end

function rounding(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
