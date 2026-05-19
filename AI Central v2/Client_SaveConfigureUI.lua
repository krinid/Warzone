function Client_SaveConfigureUI (alert)
	saveValues ();
end

function saveValues ();
	-- Distinguish between Pure AI and Human AI
	Mod.Settings.DistinguishPureHumanAI = cbox_DistinguishPureHumanAI.GetIsChecked() or false;

	-- Delay before AI attacks
	Mod.Settings.AIdelayBeforeOrders = nif_AIdelayBeforeOrders.GetValue() or 2;
	Mod.Settings.AIdelay_Attacks = cbox_AIdelay_Attacks.GetIsChecked() or false;
	Mod.Settings.AIdelay_Deploys = cbox_AIdelay_Deploys.GetIsChecked() or false;
	Mod.Settings.AIdelay_CardPlays = cbox_AIdelay_CardPlays.GetIsChecked() or false;

	-- Permitted actions
	Mod.Settings.AttackPlayers = cbox_AttackPlayers.GetIsChecked() or false;
	Mod.Settings.AttackAIs = cbox_AttackAIs.GetIsChecked() or false;
	Mod.Settings.AttackNeutrals = cbox_AttackNeutrals.GetIsChecked() or false;
	-- print ("save AP ".. tostring (cbox_AttackPlayers.GetIsChecked()), tostring (Mod.Settings.AttackPlayers));
	-- print ("save AAIs ".. tostring (cbox_AttackAIs.GetIsChecked()), tostring (Mod.Settings.AttackAIs));
	Mod.Settings.Transfers = cbox_Transfers.GetIsChecked() or false;
	Mod.Settings.Deployments = cbox_Deployments.GetIsChecked() or false;
	Mod.Settings.BuildCities = cbox_Cities.GetIsChecked() or false;

	-- Permitted card plays
	Mod.Settings.Diplomacy = cbox_Diplomacy.GetIsChecked() or false;
	Mod.Settings.Blockade = cbox_Blockade.GetIsChecked() or false;
	Mod.Settings.EmergencyBlockade = cbox_EMB.GetIsChecked() or false;
	Mod.Settings.Reinforcements = cbox_Reinforcements.GetIsChecked() or false;
	Mod.Settings.Bomb = cbox_Bomb.GetIsChecked() or false;
	Mod.Settings.Sanction = cbox_Sanction.GetIsChecked() or false;

	if UI.IsDestroyed (vertPureAI) == false then
		--if the Pure AI controls are currently being shown, save those values too
		Mod.Settings.AttackPlayers_PureAI = cbox_AttackPlayers_PureAI.GetIsChecked() or false;
		Mod.Settings.AttackAIs_PureAI = cbox_AttackAIs_PureAI.GetIsChecked() or false;
		Mod.Settings.AttackNeutrals_PureAI = cbox_AttackNeutrals_PureAI.GetIsChecked() or false;
		Mod.Settings.Transfers_PureAI = cbox_Transfers_PureAI.GetIsChecked() or false;
		Mod.Settings.Deployments_PureAI = cbox_Deployments_PureAI.GetIsChecked() or false;
		Mod.Settings.BuildCities_PureAI = cbox_Cities_PureAI.GetIsChecked() or false;
		Mod.Settings.Diplomacy_PureAI = cbox_Diplomacy_PureAI.GetIsChecked() or false;
		Mod.Settings.Blockade_PureAI = cbox_Blockade_PureAI.GetIsChecked() or false;
		Mod.Settings.EmergencyBlockade_PureAI = cbox_EMB_PureAI.GetIsChecked() or false;
		Mod.Settings.Reinforcements_PureAI = cbox_Reinforcements_PureAI.GetIsChecked() or false;
		Mod.Settings.Bomb_PureAI = cbox_Bomb_PureAI.GetIsChecked() or false;
		Mod.Settings.Sanction_PureAI = cbox_Sanction_PureAI.GetIsChecked() or false;
	end
end