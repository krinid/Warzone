function Client_PresentSettingsUI(rootParent)
    --be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

    UI.CreateLabel(rootParent).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading")).SetFlexibleWidth(1);
	-- UI.CreateLabel(rootParent).SetText("A unit whose strength scales with the amount of gold you spend to create it. Using low quantities gold will result in a Behemoth weaker than the # of armies you would receive for the same gold.");

	--get values from Mod.Settings, if nil then assign default values
	local intGoldLevel1 = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default;
	local intGoldLevel2 = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default;
	local intGoldLevel3 = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default;
	local boolBehemothInvulnerableToNeutrals = (Mod.Settings.BehemothInvulnerableToNeutrals == nil and boolBehemothInvulnerableToNeutrals_default) or Mod.Settings.BehemothInvulnerableToNeutrals;
	local intStrengthAgainstNeutrals = Mod.Settings.BehemothStrengthAgainstNeutrals or intStrengthAgainstNeutrals_default;
	local intMaxBehemothsSimulPerPlayer = Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5;
	local intMaxBehemothsTotalPerPlayer = Mod.Settings.BehemothMaxTotalPerPlayer or -1; --default to -1; this means no limit
	local intMaxBehemothsSimulForAllPlayers = Mod.Settings.BehemothMaxSimultaneousForAllPlayers or -1; --default to -1; this means no limit
	local intMaxBehemothsTotalForAllPlayers = Mod.Settings.BehemothMaxTotalForAllPlayers or -1; --default to -1; this means no limit

    UI.CreateLabel (rootParent).SetText ("Behemost cost is not fixed; strength increases with gold spent. Comparison with buying armies with same amount of gold:"..
	"\n\n• gold spent <" ..tostring (intGoldLevel1).. " --> weaker than armies [linearly]"..
	"\n• gold spent ≥" ..tostring (intGoldLevel1).. ", <" ..tostring (intGoldLevel2).. " --> stronger than armies [linearly]"..
	"\n• gold spent ≥" ..tostring (intGoldLevel2).. ", <" ..tostring (intGoldLevel3).. " --> much stronger than armies [multiplicatively]"..
	"\n• gold spent ≥" ..tostring (intGoldLevel3).. " --> overwhelmingly stronger than armies [exponentially]").SetFlexibleWidth(1);

	-- "\n\n• gold spent <" ..tostring (intGoldLevel1).. " --> inefficient [better to buy armies]"..
	-- "\n• gold spent ≥" ..tostring (intGoldLevel1).. ", <" ..tostring (intGoldLevel2).. " --> efficient [may make sense to buy a Behemoth]"..
	-- "\n• gold spent ≥" ..tostring (intGoldLevel2).. ", <" ..tostring (intGoldLevel3).. " --> highly efficient [valuable to buy a Behemoth]"..
	-- "\n• gold spent ≥" ..tostring (intGoldLevel3).. " --> immensely efficient [incredibly beneficial to buy a Behemoth]").SetFlexibleWidth(1);

	-- UI.CreateLabel (rootParent).SetText ("Behemost cost is not fixed; strength increases with gold spent. "..
	-- "\n\n• gold spent < G1 - inefficient [better to buy armies]"..
	-- "\n• gold spent >= G1, < G2 - efficient [may make sense to buy a Behemoth]"..
	-- "\n• gold spent >= G2, < G3 - highly efficient [valuable to buy a Behemoth]"..
	-- "\n• gold spent >= G3 - immensely efficient [incredibly beneficial to buy a Behemoth]").SetFlexibleWidth(1);
	-- "\n\nSet the gold levels relative to the income settings for the template you are creating, and relative to the role you wish Behemoths to play. If you wish Behemoths to be strong in the early game, set a low G1 value. "..
	-- "If you wish Behemoths to be weak in the early game but strong in the late game, set a high G1 value to an amount that won't be achievable until mid game or late mid game, and set G2 and G3 to high values that players won't achieved until late in the game."..
	-- "\n\nDefault values for Behemoths make them weak in the early game (of an average template), and strong in the late game, doing high damage, buffing attack rates and well suited to rip through blockaded territories");

	UI.CreateLabel (rootParent).SetText ("\n[Max # of Behemoths]").SetColor ("#FFFF00");
	UI.CreateLabel (rootParent).SetText ("Per player simultaneously: " ..tostring (intMaxBehemothsSimulPerPlayer));
	UI.CreateLabel (rootParent).SetText ("        Per player per game: " ..tostring (intMaxBehemothsTotalPerPlayer));
	UI.CreateLabel (rootParent).SetText ("For all players simultaneously: " ..tostring (intMaxBehemothsSimulForAllPlayers));
	UI.CreateLabel (rootParent).SetText ("For all players total per game: " ..tostring (intMaxBehemothsTotalForAllPlayers));
	UI.CreateLabel (rootParent).SetText (" (-1 indicates Unlimited)");

	-- UI.CreateLabel (rootParent).SetText (rootParent).SetText ("\nBehemoths invulnerable vs neutrals: ".. tostring (boolBehemothInvulnerableToNeutrals)).SetFlexibleWidth(1);
	UI.CreateLabel (rootParent).SetText ("\nBehemoths invulnerable vs neutrals: ".. tostring (boolBehemothInvulnerableToNeutrals)).SetFlexibleWidth(1);

    local strStrengthAgainstNeutrals;
    if (intStrengthAgainstNeutrals < 1.0) then strStrengthAgainstNeutrals = "reduced damage vs neutrals";
    elseif (intStrengthAgainstNeutrals == 1.0) then strStrengthAgainstNeutrals = "normal damage vs neutrals";
    elseif (intStrengthAgainstNeutrals > 1.0) then strStrengthAgainstNeutrals = "increased damage vs neutrals";
    end
	UI.CreateLabel (rootParent).SetText ("Strength against neutrals: ".. tostring (intStrengthAgainstNeutrals) .."x damage (" ..strStrengthAgainstNeutrals.. ")").SetFlexibleWidth(1);

    if (boolBehemothInvulnerableToNeutrals == true) then UI.CreateLabel (rootParent).SetText ("     (Behemoths take no damage when attacking neutral territories of any size)").SetFlexibleWidth(1);
    else UI.CreateLabel (rootParent).SetText ("     (Behemoths take normal damage when attacking neutral territories)").SetFlexibleWidth(1);
    end

end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end