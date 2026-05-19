function Client_PresentConfigureUI (rootParent)
	root = rootParent;
	showControls ();
end

function showControls ()
	if (UI.IsDestroyed (UImain) == false) then UI.Destroy (UImain); end
	UImain = UI.CreateVerticalLayoutGroup (root);
	horzDistinguishPureHumanAI = UI.CreateHorizontalLayoutGroup (UImain);
	cbox_DistinguishPureHumanAI = UI.CreateCheckBox (horzDistinguishPureHumanAI).SetText ("Distinguish between Pure AI and Players that have gone AI").SetIsChecked (Mod.Settings.DistinguishPureHumanAI or false).SetOnValueChanged(function() cbox_DistinguishPureHumanAIclicked() end).SetInteractable (true);
	UI.CreateButton (horzDistinguishPureHumanAI).SetText ("[?]").SetColor ('#00FFFF').SetOnClick (function() UI.Alert ("• Pure AI: host configured AI, plays entire game as an AI\n\n• Human AI: starts game as a player but becomes AI due to player surrender or boot") end);

	local horzAIdelayBeforeOrders = UI.CreateHorizontalLayoutGroup(UImain);
    nif_AIdelayBeforeOrders = UI.CreateNumberInputField (horzAIdelayBeforeOrders).SetSliderMinValue (0).SetSliderMaxValue (10).SetWholeNumbers (true).SetValue (Mod.Settings.AIdelayBeforeOrders or 2); --default to 2 turns if not set already
	UI.CreateLabel (horzAIdelayBeforeOrders).SetText ("# turns before a player that has gone AI can enter orders");
	UI.CreateLabel (UImain).SetText ("  (0 = no delay, can attack immediately; 1+ = # of turns that newly turned AIs cannot enter orders)");
	local horzAIdelayActions = UI.CreateHorizontalLayoutGroup (UImain);
	UI.CreateLabel (horzAIdelayActions).SetText ("Suppress ");
	cbox_AIdelay_Attacks = UI.CreateCheckBox (horzAIdelayActions).SetText ("Attacks").SetIsChecked (Mod.Settings.AIdelay_Attacks ~= nil and Mod.Settings.AIdelay_Attacks or Mod.Settings.AIdelay_Attacks == nil and true); --default to true if not set already
	cbox_AIdelay_Deploys = UI.CreateCheckBox (horzAIdelayActions).SetText ("Deploys").SetIsChecked (Mod.Settings.AIdelay_Deploys ~= nil and Mod.Settings.AIdelay_Deploys or Mod.Settings.AIdelay_Deploys == nil and true); --default to true if not set already
	cbox_AIdelay_CardPlays = UI.CreateCheckBox (horzAIdelayActions).SetText ("Card plays").SetIsChecked (Mod.Settings.AIdelay_CardPlays ~= nil and Mod.Settings.AIdelay_CardPlays or Mod.Settings.AIdelay_CardPlays == nil and true); --default to true if not set already

	vertHumanAI = UI.CreateVerticalLayoutGroup (UImain);
	labelHumanAItitle = UI.CreateLabel (vertHumanAI); --leave blank for now
	labelHumanAIPermittedActions = UI.CreateLabel (vertHumanAI).SetText ("\nPermitted actions:").SetColor ("#00FFFF");
	local horzActions = UI.CreateHorizontalLayoutGroup (vertHumanAI);
	cbox_AttackPlayers = UI.CreateCheckBox (horzActions).SetText ("Attack players").SetIsChecked (Mod.Settings.AttackPlayers or false);
	cbox_AttackAIs = UI.CreateCheckBox (horzActions).SetText ("Attack AIs").SetIsChecked (Mod.Settings.AttackAIs or false);
	cbox_AttackNeutrals = UI.CreateCheckBox (horzActions).SetText ("Attack neutrals").SetIsChecked (Mod.Settings.AttackNeutrals or Mod.Settings.AttackNeutrals == nil and true);
	-- print ("read AP ".. tostring (cbox_AttackPlayers.GetIsChecked()), tostring (Mod.Settings.AttackPlayers));
	-- print ("read AAIs ".. tostring (cbox_AttackAIs.GetIsChecked()), tostring (Mod.Settings.AttackAIs));
	local horzActions = UI.CreateHorizontalLayoutGroup (vertHumanAI);
	cbox_Transfers = UI.CreateCheckBox (horzActions).SetText ("Transfers").SetIsChecked (Mod.Settings.Transfers or Mod.Settings.Transfer == nil and true); --default to true
	cbox_Deployments = UI.CreateCheckBox (horzActions).SetText ("Deploys").SetIsChecked (Mod.Settings.Deployments or Mod.Settings.Deployments == nil and true); --default to true
	cbox_Cities = UI.CreateCheckBox (horzActions).SetText ("Build cities").SetIsChecked (Mod.Settings.BuildCities or false);

	UI.CreateLabel (vertHumanAI).SetText ("\nPermitted card plays:").SetColor ("#00FFFF");
	local horzCardPlays = UI.CreateHorizontalLayoutGroup (vertHumanAI);
	cbox_Diplomacy = UI.CreateCheckBox (horzCardPlays).SetText("Diplomacy").SetIsChecked (Mod.Settings.Diplomacy or false);
	cbox_Blockade = UI.CreateCheckBox (horzCardPlays).SetText("Blockade").SetIsChecked (Mod.Settings.Blockade or false);
	cbox_EMB = UI.CreateCheckBox (horzCardPlays).SetText("Emergency Blockade").SetIsChecked (Mod.Settings.EmergencyBlockade or false);
	local horzCardPlays = UI.CreateHorizontalLayoutGroup (vertHumanAI);
	cbox_Reinforcements = UI.CreateCheckBox (horzCardPlays).SetText("Reinforcements").SetIsChecked (Mod.Settings.Reinforcements or false);
	cbox_Bomb = UI.CreateCheckBox (horzCardPlays).SetText("Bomb").SetIsChecked (Mod.Settings.Bomb or false);
	cbox_Sanction = UI.CreateCheckBox (horzCardPlays).SetText("Sanction").SetIsChecked (Mod.Settings.Sanction or false);

	if (cbox_DistinguishPureHumanAI.GetIsChecked () == true) then
		--distinguish between Pure & Human AI is true, so show the list of controls for Pure AI
		-- saveValues ();
		labelHumanAItitle.SetText ("\n[Human AI]").SetColor ("#FFFF00");
		labelHumanAIPermittedActions.SetText ("Permitted actions:").SetColor ("#00FFFF");

		vertPureAI = UI.CreateVerticalLayoutGroup (UImain); --leave empty if Distinguish Pure/Human AI isn't checked, and populate with appropriate controls if checked
		UI.CreateLabel (vertPureAI).SetText ("\n[Pure AI]").SetColor ("#FFFF00");
		UI.CreateLabel (vertPureAI).SetText ("Permitted actions:").SetColor ("#00FFFF");
		local horzActions = UI.CreateHorizontalLayoutGroup (vertPureAI);
		cbox_AttackPlayers_PureAI = UI.CreateCheckBox (horzActions).SetText ("Attack players").SetIsChecked (Mod.Settings.AttackPlayers_PureAI or false);
		cbox_AttackAIs_PureAI = UI.CreateCheckBox (horzActions).SetText ("Attack AIs").SetIsChecked (Mod.Settings.AttackAIs_PureAI or false);
		cbox_AttackNeutrals_PureAI = UI.CreateCheckBox (horzActions).SetText ("Attack neutrals").SetIsChecked (Mod.Settings.AttackNeutrals_PureAI or Mod.Settings.AttackNeutrals_PureAI == nil and true); --default to true
		local horzActions = UI.CreateHorizontalLayoutGroup (vertPureAI);
		cbox_Transfers_PureAI = UI.CreateCheckBox (horzActions).SetText ("Transfers").SetIsChecked (Mod.Settings.Transfers_PureAI or Mod.Settings.Transfers_PureAI == nil and true);
		cbox_Deployments_PureAI = UI.CreateCheckBox (horzActions).SetText ("Deploys").SetIsChecked (Mod.Settings.Deployments_PureAI or Mod.Settings.Deployments_PureAI == nil and true);
		cbox_Cities_PureAI = UI.CreateCheckBox (horzActions).SetText ("Build cities").SetIsChecked (Mod.Settings.BuildCities_PureAI or false);

		UI.CreateLabel (vertPureAI).SetText ("\nPermitted card plays:").SetColor ("#00FFFF");
		local horzCardPlays = UI.CreateHorizontalLayoutGroup (vertPureAI);
		cbox_Diplomacy_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Diplomacy").SetIsChecked (Mod.Settings.Diplomacy_PureAI or false);
		cbox_Blockade_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Blockade").SetIsChecked (Mod.Settings.Blockade_PureAI or false);
		cbox_EMB_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Emergency Blockade").SetIsChecked (Mod.Settings.EmergencyBlockade_PureAI or false);
		local horzCardPlays = UI.CreateHorizontalLayoutGroup (vertPureAI);
		cbox_Reinforcements_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Reinforcements").SetIsChecked (Mod.Settings.Reinforcements_PureAI or false);
		cbox_Bomb_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Bomb").SetIsChecked (Mod.Settings.Bomb_PureAI or false);
		cbox_Sanction_PureAI = UI.CreateCheckBox (horzCardPlays).SetText ("Sanction").SetIsChecked (Mod.Settings.Sanction_PureAI or false);
	end
end

function cbox_DistinguishPureHumanAIclicked ()
	-- print (tostring (cbox_DistinguishPureHumanAI.GetIsChecked ()));
	if (cbox_DistinguishPureHumanAI.GetIsChecked () == true) then
		--if Distinguish Pure/Human AI is checked, show the separate controls for Pure AI and Human AI
		saveValues ();
		labelHumanAItitle.SetText ("\n[Human AI]").SetColor ("#FFFF00");
		labelHumanAIPermittedActions.SetText ("Permitted actions:").SetColor ("#00FFFF");
		showControls (); --re-show controls to update with Pure AI controls
	else
		--if Distinguish Pure/Human AI is unchecked, hide the Pure AI controls and just show 1 set of controls for all AIs
		saveValues ();
		if UI.IsDestroyed (vertPureAI) == false then UI.Destroy (vertPureAI); end
		labelHumanAItitle.SetText ("").SetColor ("#FFFF00");
		labelHumanAIPermittedActions.SetText ("\nPermitted actions:").SetColor ("#00FFFF");
	end
end