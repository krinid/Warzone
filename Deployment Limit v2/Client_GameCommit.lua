function Client_GameCommit (clientGame, skipCommit)
    if (clientGame.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires clicking Commit, which they can't do b/c they're not in the game)

	-- skipCommit (); --while testing, always skip

	--check if deployment orders exceed the deployment limit specified; if so, reduce the deployments to the limit, highlight the impacted territories and raise alert to player
	local intDeploymentLimit = Mod.Settings.MaxDeploy;
	local territoryListToHighlight = {};
	local boolChangesMade = false;
	local newOrders = {};
	local strTerritoryNames = "";
	for _,order in pairs (clientGame.Orders) do
		-- print ("**".. order.proxyType ..",".. order.DeployOn .."/".. tostring (clientGame.Map.Territories[order.DeployOn].Name).. ", ".. order.NumArmies);
		if (order.proxyType == "GameOrderDeploy" and order.NumArmies > intDeploymentLimit) then
			-- order.NumArmies = intDeploymentLimit; --reduce deployments to the limit <--- no writable
			table.insert (territoryListToHighlight, order.DeployOn);
			strTerritoryNames = strTerritoryNames .. (strTerritoryNames == "" and "" or ", ") ..tostring (clientGame.Map.Territories[order.DeployOn].Name);
			table.insert (newOrders, WL.GameOrderDeploy.Create (order.PlayerID, intDeploymentLimit, order.DeployOn, false)); --replace existing order with one that deploys the deployment limit
			-- table.insert (newOrders, order);
			boolChangesMade = true;
		else
			--not a deployment order that exceeds mod set deployment limit, so include the order as-is
			table.insert (newOrders, order);
		end
	end
	if (boolChangesMade == true) then
		-- if (#territoryListToHighlight > 0) then clientGame.HighlightTerritories (territoryListToHighlight); UI.Alert ("要チェックや"); end
		-- print ("__bad " ..tostring (#territoryListToHighlight));
		clientGame.Orders = newOrders;
		clientGame.CreateDialog (deploymentLimitExceededDialog);
		local dialog = deploymentLimitExceededDialogWindow;
		dialog.setMaxSize (500, 400);
		local vert = UI.CreateVerticalLayoutGroup (dialog.rootParent).SetFlexibleWidth(1);
		UI.CreateLabel (vert).SetText ("DEPLOYMENT LIMIT EXCEEDED on " ..tostring (#territoryListToHighlight).. (#territoryListToHighlight >1 and " territories:" or " territory:")).SetColor ("#FFFF00");
		UI.CreateLabel (vert).SetText ("Max deployments per territory per turn: " ..tostring (intDeploymentLimit)).SetColor ("#FF0000");
		-- UI.CreateLabel (vert).SetText ("\nYou have exceeded the limit on the following ");
		-- UI.CreateLabel (vert).SetText ("\nDeployments have been adjusted to the limit:"); --impacted territories have been highlighted on the map)\n");
		UI.CreateLabel (vert).SetText ("\nImpacted territories:\n(highlighted on map, deployments reduced to the limit)");
		-- local horz = UI.CreateHorizontalLayoutGroup (vert).SetFlexibleWidth (1);
		for _,v in pairs (territoryListToHighlight) do
			UI.CreateButton (vert).SetText (tostring (clientGame.Map.Territories[v].Name)).SetColor ("#00FFFF").SetOnClick (function () clientGame.HighlightTerritories ({v}); end);
			-- UI.CreateButton (horz).SetText (tostring (clientGame.Map.Territories[v].Name)).SetColor ("#00FFFF").SetOnClick (function () clientGame.HighlightTerritories ({v}); end);
		end
		-- UI.CreateLabel (vert).SetText (strErrorMessage);
		clientGame.HighlightTerritories (territoryListToHighlight);
		skipCommit ();
	end

	-- print ("---ORDERS---");
	-- for k,order in pairs (clientGame.Orders) do
		-- print (k ..", ".. order.proxyType ..",".. order.DeployOn .."/".. tostring (clientGame.Map.Territories[order.DeployOn].Name).. ", ".. order.NumArmies);
		-- print (k ..", ".. order.proxyType ..",".. tostring (order.proxyType=="GameOrderDeploy"and order.DeployOn)..", ".. tostring (order.proxyType=="GameOrderDeploy"and order.NumArmies));
	-- end
end

function deploymentLimitExceededDialog (rootParent, setMaxSize, setScrollable, game, close)
	deploymentLimitExceededDialogWindow = {rootParent=rootParent, setMaxSize=setMaxSize, setScrollable=setScrollable, game=game, close=close};
	return ({rootParent=rootParent, setMaxSize=setMaxSize, setScrollable=setScrollable, game=game, close=close});
end