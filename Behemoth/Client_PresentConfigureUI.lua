require ("behemoth");

function Client_PresentConfigureUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("Behemost cost is not fixed. When purchasing, the player decides how much gold to spend, and strength increases with gold spent. "..
	"Gold levels define when it becomes efficient compared to buying armies with the same sum of gold."..
	"\n\n• gold spent < G1 - inefficient [better to buy armies]"..
	"\n• gold spent >= G1, < G2 - efficient [may make sense to buy a Behemoth]"..
	"\n• gold spent >= G2, < G3 - highly efficient [valuable to buy a Behemoth]"..
	"\n• gold spent >= G3 - immensely efficient [incredibly beneficial to buy a Behemoth]"..
	-- "\n\nSet the gold levels relative to the income settings for the template you are creating, and relative to the role you wish Behemoths to play. If you wish Behemoths to be strong in the early game, set a low G1 value. "..
	-- "If you wish Behemoths to be weak in the early game but strong in the late game, set a high G1 value to an amount that won't be achievable until mid game or late mid game, and set G2 and G3 to high values that players won't achieved until late in the game."..
	"\n\nDefault values for Behemoths make them weak in the early game (of an average template), and strong in the late game, doing high damage, buffing attack rates and well suited to rip through blockaded territories");

	local line = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (line).SetText ("Gold level 1 (G1)");
	UI.CreateLabel (line).SetText ("_").SetColor ("#000000");
	goldLevel1NIF = UI.CreateNumberInputField (line).SetValue (100);

	local line = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (line).SetText ("Gold level 2 (G2) ");
	UI.CreateLabel (line).SetText ("_").SetColor ("#000000");
	goldLevel2NIF = UI.CreateNumberInputField (line).SetValue (500);

	local line = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (line).SetText ("Gold level 3 (G3) ");
	UI.CreateLabel (line).SetText ("_").SetColor ("#000000");
	goldLevel3NIF = UI.CreateNumberInputField (line).SetValue (1000);

	UI.CreateLabel (rootParent).SetText ("_").SetColor ("#000000");
	invulnerableToNeutralsCBOX = UI.CreateCheckBox (rootParent).SetText ("Behemoths take no damage when attacking neutral territories").SetIsChecked (true);
	UI.CreateLabel (rootParent).SetText ("When checked, a Behemoth can attack neutral territories of any size without taking damage, cannot die during the attack");

	local line = UI.CreateHorizontalLayoutGroup (rootParent);
	UI.CreateLabel (line).SetText ("Strength against neutrals: ");
	neutralStrengthNIF = UI.CreateNumberInputField (line).SetWholeNumbers(false).SetValue (5.0);
	UI.CreateLabel (rootParent).SetText ("• <1.0 - reduced damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("• =1.0 - normal damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("• >1.0 - increased damage vs neutrals");
	UI.CreateLabel (rootParent).SetText ("•  5.0 - default value, 5x damage vs neutrals");

end