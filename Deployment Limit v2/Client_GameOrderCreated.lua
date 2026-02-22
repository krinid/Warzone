function Client_GameOrderCreated (game, gameOrder, skip)

	print ("**"..gameOrder.proxyType);

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires submitting an order, which they can't do b/c they're not in the game)
	if (gameOrder.proxyType=='GameOrderDeploy' and gameOrder.NumArmies > Mod.Settings.MaxDeploy) then
		print (gameOrder.DeployOn, gameOrder.NumArmies);
		UI.Alert ("bad");
		skip ();
	end

	--need to check is GameCommit b/c Client_GameOrderCreated is only called for the 1st deployment on a given territory; the order is directly edited and never calls Client_GameOrderCreated for deplomyments #2 or after
	--thus must check all orders in GameCommit
	--tbh had to check there anyhow b/c a mod or Auto-Pilot may have directly added deployment records (or some other method)
end