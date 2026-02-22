require ("punishReward");

--used to display Punishment and Reward stats for the local client player
function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

	setMaxSize (800, 600);
	Game = game; --global variable to use in other functions in this code 

	if game == nil then print('ClientGame is nil'); return; end
	if game.LatestStanding == nil then print('ClientGame.LatestStanding is nil'); end
	if game.LatestStanding.Cards == nil then print('ClientGame.LatestStanding.Cards is nil'); end
	if game.Us == nil then print('ClientGame.Us is nil'); return; end
	-- if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	-- if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end

	local clientPlayerID = game.Us.ID;
	MenuWindow = rootParent;

	local horzButtonLine = UI.CreateHorizontalLayoutGroup (MenuWindow).SetFlexibleWidth(1);
	UI.CreateLabel (horzButtonLine).SetText ("").SetFlexibleWidth(1);
	if (game.Us.ID == 1058239) then UI.CreateButton (horzButtonLine).SetText ("Debug data").SetOnClick (function () game.CreateDialog (showDebugDataForAllPlayers); end).SetColor (getColours()["Dark Gray"]); end
	UI.CreateButton (horzButtonLine).SetText ("All players").SetOnClick (function () game.CreateDialog (showAllPlayerDataButtonClick); end).SetColor ("#0000FF");
	UI.CreateButton (horzButtonLine).SetText ("[?] Mechanics").SetOnClick (function () game.CreateDialog (showMechanics); end).SetColor ("#FFFF00");
	-- UI.CreateButton (horzButtonLine).SetText ("[?] Mechanics").SetOnClick (function () showMechanics (game, clientPlayerID); end).SetColor ("#FFFF00");

	if (Mod.PublicGameData.PRdataByID ~= nil and Mod.PublicGameData.PRdataByID [clientPlayerID] ~= nil) then
		showIncomeAssessment (game, MenuWindow, clientPlayerID, game.Game.TurnNumber-1);
	else
		UI.CreateLabel (MenuWindow).SetText ("No Punishment/Reward data available for you yet").SetColor (getColourCode ("error")).SetAlignment(WL.TextAlignmentOptions.Left);
	end

	--only display if Cities can be built or if Workers are in use (but how to check for workers? see if any are on the map already? that's the only way to know for sure b/c can't check the mods in play)
	-- CreateLabel (MenuWindow).SetText ("\nCITIES: Rewards of 1% of total city income value will be granted for each territory you possess where the # of cities is within 10% of the average cities per territories (#territories/#cities). There are no Punishments for city distribution");
	-- CreateLabel (MenuWindow).SetText ("\n# territories: tbd, # cities: tbd, av cities/territory (ACT): tbd");
	-- CreateLabel (MenuWindow).SetText ("\n# territories with city count within 10% ACT: tbd, Reward: xx% (yy gpt)");


	--[[    Server_GameCustomMessage (Server_GameCustomMessage.lua)
Called whenever your mod calls ClientGame.SendGameCustomMessage. This gives mods a way to communicate between the client and server outside of a turn advancing. Note that if a mod changes Mod.PublicGameData or Mod.PlayerGameData, the clients that can see those changes and have the game open will automatically receive a refresh event with the updated data, so this message can also be used to push data from the server to clients.
Mod security should be applied when working with this Hook
Arguments:
Game: Provides read-only information about the game.
PlayerID: The ID of the player who invoked this call.
payload: The data passed as the payload parameter to SendGameCustomMessage. Must be a lua table.
setReturn: Optionally, a function that sets what data will be returned back to the client. If you wish to return data, pass a table as the sole argument to this function. Not calling this function will result in an empty table being returned.]]

	--this shows all Global Functions! wow
	--[[for i, v in pairs(_G) do
		print(i, v);
	end]]
end

function showMechanics (rootParent, setMaxSize, setScrollable, game, close)
	local MechanicsUI = rootParent;
	setMaxSize (600, 500);
	UI.CreateLabel (MechanicsUI).SetText ("[MECHANICS]").SetFlexibleWidth (1.0).SetColor (getColourCode ("main heading"));
	UI.CreateLabel (MechanicsUI).SetText ("This mod promotes active, aggressive play, while penalizing passive play and card farming. There are 3 components that affect how you will be Rewarded or Punished.").SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText ("\n1) CURRENT TURN REWARDS or PUNISHMENTS:").SetFlexibleWidth (1.0).SetColor (getColourCode ("subheading"));
	UI.CreateLabel (MechanicsUI).SetText ("For each of the following actions you do not complete each turn, you will receive a Punishment of " ..tostring (1*punishmentIncrement*100).. "% or a Reward of +" ..tostring (1*rewardIncrement*100).. "% when you do complete them:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText ("  (A) Attacks [at least 1 attack made]\n  (B) Captures [at least 1 capture made]\n  (C) Increasing your territory count [territory count increased by at least 1]").SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText ("\n2) LONG TERM PUNISHMENTS:").SetFlexibleWidth (1.0).SetColor (getColourCode ("subheading"));
	UI.CreateLabel (MechanicsUI).SetText ("In addition to the most recent turn Punishment/Reward, additional Punishments will be given when you have consecutive turns with no territory count increases, as follows:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL1).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL2).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL3).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL4).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL5).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL6).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL7).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL8).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strLongTermPunishmentL9).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText ("\n3) CITY DISTRIBUTION REWARDS:").SetFlexibleWidth (1.0).SetColor (getColourCode ("subheading"));
	UI.CreateLabel (MechanicsUI).SetText ("Further rewards are available by building cities evenly across all your territories, as follows:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strCityRewards1).SetFlexibleWidth (1.0);
	UI.CreateLabel (MechanicsUI).SetText (strCityRewards2).SetFlexibleWidth (1.0);
end

function showAllPlayerDataButtonClick (rootParent, setMaxSize, setScrollable, game, close)
	setMaxSize (800, 600);

	--if not PR data exists yet, just exit; for example when entering orders for T1, there will be no data yet
	if (Mod.PublicGameData.PRdataByID == nil) then
		UI.CreateLabel (rootParent).SetText ("No Punishment/Reward data available yet").SetColor (getColourCode ("error")).SetAlignment(WL.TextAlignmentOptions.Left);
		return;
	end

	for k,v in pairs (Mod.PublicGameData.PRdataByID) do
		-- only show data for active players, skip eliminated/booted/surrendered/declined players
		if (game.Game.Players [k].State == WL.GamePlayerState.Playing) then
			showIncomeAssessment (game, rootParent, k, game.Game.TurnNumber-1);
			UI.CreateLabel (rootParent).SetText ("\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - \n\n").SetFlexibleWidth (1.0);
		end
	end
end

function showIncomeAssessment (game, windowUI, playerID, turnNumber)
	local labelConsecutivePunishmentDetails;
	local incomeAdjustments;

	incomeAdjustments = assessLongTermPunishment (Mod.PublicGameData.PRdataByID [playerID], turnNumber); --use -1 b/c current turn number from the client during order entry is 1 higher than the # of actually finished turns

	print ("-------------------player "..playerID.. "/" ..getPlayerName (game, playerID) ..", player state: " ..game.Game.Players [playerID].State.."/".. WL.GamePlayerState.ToString (game.Game.Players [playerID].State));
	--skip non-active players (they were eliminated, booted, declined the game, etc)
	if (game.Game.Players [playerID].State ~= WL.GamePlayerState.Playing) then
		return; --do nothing, just return
	end;

	print ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount));
	print ("Curr-turn Penalty " ..tostring (incomeAdjustments.CurrTurn.PunishmentUnits).. ", Reward " ..tostring (incomeAdjustments.CurrTurn.RewardUnits).. ", attacks " ..tostring (incomeAdjustments.CurrTurn.Attacks).. ", captures " ..tostring (incomeAdjustments.CurrTurn.Captures).. ", #territories " ..tostring (incomeAdjustments.CurrTurn.TerritoryCount).. ", terr increased " ..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));
	local strRewardText = "[none]";
	local strPunishmentText = "[none]";
	local strPunishmentText_Details = "";
	local strRewardText_Details = "";

	local intNetRU_PU_Change = (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement) + (incomeAdjustments.LongTermPunishmentUnits + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement;
	local strPunishmentOrReward = "Punishment";
	if (intNetRU_PU_Change > 0) then strPunishmentOrReward = "Reward";
	elseif (intNetRU_PU_Change < 0) then strPunishmentOrReward = "Punishment";
	else strPunishmentOrReward = "No income adjustment (punishment = reward)";
	end

	local strCurrentState = strPunishmentOrReward.. " (" ..(intNetRU_PU_Change>0 and "+" or "")..tostring (intNetRU_PU_Change*100).. "%)"
	local horzCurrentState = UI.CreateHorizontalLayoutGroup (windowUI).SetFlexibleWidth(1);
	UI.CreateLabel (horzCurrentState).SetText ("PLAYER: ").SetColor (getColourCode ("main heading")).SetAlignment (WL.TextAlignmentOptions.Left);
	UI.CreateLabel (horzCurrentState).SetText (getPlayerName (game, playerID)).SetColor ("#FFFFFF").SetAlignment (WL.TextAlignmentOptions.Left);
	UI.CreateLabel (horzCurrentState).SetText ("    CURRENT STATE:    ").SetColor (getColourCode ("main heading")).SetAlignment (WL.TextAlignmentOptions.Left);
	UI.CreateLabel (horzCurrentState).SetText (strCurrentState).SetColor ("#FFFFFF").SetAlignment (WL.TextAlignmentOptions.Left);

	if (incomeAdjustments.CurrTurn.PunishmentUnits > 0) then
		strPunishmentText = tostring (incomeAdjustments.CurrTurn.PunishmentUnits * 100 * punishmentIncrement).. "% income   [";
		if (incomeAdjustments.CurrTurn.Attacks == 0) then strPunishmentText_Details = appendCommaSeparatedComponent (strPunishmentText_Details, "no attack"); end
		if (incomeAdjustments.CurrTurn.Captures == 0) then strPunishmentText_Details = appendCommaSeparatedComponent (strPunishmentText_Details, "no capture"); end
		if (incomeAdjustments.CurrTurn.TerritoryCountIncreased == 0) then strPunishmentText_Details = appendCommaSeparatedComponent (strPunishmentText_Details, "territory count didn't increase"); end
		strPunishmentText = strPunishmentText .. strPunishmentText_Details .. "]";
	end
	if (incomeAdjustments.CurrTurn.RewardUnits > 0) then
		strRewardText = tostring (incomeAdjustments.CurrTurn.RewardUnits * 100 * rewardIncrement).. "% income   [";
		if (incomeAdjustments.CurrTurn.Attacks > 0) then strRewardText_Details = appendCommaSeparatedComponent (strRewardText_Details, "1+ attack"); end
		if (incomeAdjustments.CurrTurn.Captures > 0) then strRewardText_Details = appendCommaSeparatedComponent (strRewardText_Details, "1+ capture"); end
		if (incomeAdjustments.CurrTurn.TerritoryCountIncreased > 0) then strRewardText_Details = appendCommaSeparatedComponent (strRewardText_Details, "territory count increased"); end
		strRewardText = strRewardText .. strRewardText_Details .. "]";
	end
	UI.CreateLabel (windowUI).SetFlexibleWidth(1).SetText ("\nCOMPONENT 1 - MOST RECENT TURN: (Turn " ..tostring (game.Game.TurnNumber-1).. ")").SetColor (getColourCode ("main heading"));
	UI.CreateLabel (windowUI).SetFlexibleWidth(1).SetText ("Punishments: " ..strPunishmentText.. "\nRewards: " ..strRewardText);

	UI.CreateLabel (windowUI).SetText ("\nCOMPONENT 2 - CONSECUTIVE TURN PERIOD Punishments:").SetFlexibleWidth (1.0).SetColor (getColourCode ("main heading"));
	UI.CreateLabel (windowUI).SetText ("• CRITERIA: Consecutive turns with no territory increase: " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease)).SetFlexibleWidth (1.0).SetColor (getColourCode ("subheading"));

	--populate the label above with the details of the Consecutive punishments (for not increasing territory count)
	labelConsecutivePunishmentDetails = UI.CreateLabel (windowUI).SetText ("  • ").SetFlexibleWidth (1.0);
	if (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 3) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL1).SetColor ("#00FF00"); --green
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 6) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL2).SetColor ("#FFFF00"); --yellow
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 9) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL3).SetColor ("#FFA500"); --orange
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 10) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL4).SetColor ("#FF0000"); --red
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 11) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL5).SetColor ("#FF0000"); --red
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 12) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL6).SetColor ("#FF0000"); --red
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 13) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL7).SetColor ("#FF0000"); --red
	elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 14) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL8).SetColor ("#FF0000"); --red
	else labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL9).SetColor ("#FF0000"); --red for 15+
	-- else labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL4).SetColor ("#FF0000"); --red
	end

	--incomeAdjustments.NumConsecutiveTurnsWithNoIncrease
	UI.CreateLabel (windowUI).SetText ("• IMPACT:").SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("    • Nullify receiving card pieces at end of turn: " ..tostring (incomeAdjustments.BlockCardPieceReceiving)).SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("    • Territories with 0 armies go neutral: " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral)).SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("    • Income reduction: " ..tostring (incomeAdjustments.LongTermPunishmentUnits * 100).. "%").SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("    • Army reduction: " ..tostring (incomeAdjustments.ArmyReduction*100).. "%").SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("    • Territory reduction: " ..tostring (incomeAdjustments.TerritoryReduction*100).. "%").SetFlexibleWidth (1.0);

	UI.CreateLabel (windowUI).SetText ("\n• #Finished turns: " ..tostring (game.Game.TurnNumber-1).. "   • #Turns evaluated on: " ..tostring (incomeAdjustments.NumTurnsEvaluatedOn)).SetAlignment(WL.TextAlignmentOptions.Left).SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("\nTurns where territory count didn't increase:").SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("• #Total: " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. "   • #Consecutive: " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease)).SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("\nTerritory counts:").SetFlexibleWidth (1.0);
	UI.CreateLabel (windowUI).SetText ("• Average: " ..tostring (math.floor ((incomeAdjustments.AverageTerritoryCount) * 100 + 0.5)/100).. "   • Highest: " ..tostring (incomeAdjustments.HighestTerritoryCount)).SetFlexibleWidth (1.0);


	--check for presence of Workers -- flag it somewhere in PublicGameData, then display this iff Workers are in play or Can build cities (else it's irrelevant)
	-- if (game.Settings.CommerceGame == false) then alert ("Commerce must be enabled to function properly.\n\nIf you wish to use this mod, enable Commerce. Otherwise, disable this mod to proceed."); end
	if (game.Settings.CommerceCityBaseCost ~= nil or SUisInUse (nil, game.LatestStanding.Territories, "Worker")) then
		local cityRewards = assessCityRewards (game.LatestStanding.Territories, {[playerID] = game.Game.Players [playerID]});
		--use floor for lower bound & ceiling for upper bound so lower bound is always a different integer than upper bound; this is beneficial esp for small ave city #'s where 25% of that value would result in the same lower and upper bound and thus be too restrictive
		local lowerBound = math.floor (cityRewards[playerID].aveCitiesPerTerritory * (1 - cityAverageToleranceLevel));
		local upperBound = math.ceil (cityRewards[playerID].aveCitiesPerTerritory * (1 + cityAverageToleranceLevel));

		UI.CreateLabel (windowUI).SetText ("\nCOMPONENT 3 - CITY REWARDS:").SetFlexibleWidth (1.0).SetColor (getColourCode ("main heading"));
		UI.CreateLabel (windowUI).SetText ("• Commerce: " ..tostring (game.Settings.CommerceGame).. "   • City cost: " ..tostring (game.Settings.CommerceCityBaseCost).. "   • Workers in play: " ..tostring (SUisInUse (nil, game.LatestStanding.Territories, "Worker"))).SetFlexibleWidth (1.0);
		-- UI.CreateLabel (windowUI).SetText ("• # cities: " ..tostring (cityRewards[playerID].numCities).. "   • # terrs: " ..tostring (cityRewards[playerID].numTerritories).. "   • # terrs w/cities: " ..tostring (cityRewards[playerID].numTerritoriesWithCities).. " [+" ..tostring (cityRewards[playerID].rewardForTerritoriesWithCities).. "]   • av# cities/terr " ..tostring (cityRewards[playerID].aveCitiesPerTerritory).. "   • av# cities/terr w/cities " ..tostring (cityRewards[playerID].aveCitiesPerTerritory)).SetFlexibleWidth (1.0);
		UI.CreateLabel (windowUI).SetText ("• # terrs: " ..tostring (cityRewards[playerID].numTerritories).. "   • # cities: " ..tostring (cityRewards[playerID].numCities).. "   • # terrs w/cities: " ..tostring (cityRewards[playerID].numTerritoriesWithCities).. " [+" ..tostring (cityRewards[playerID].rewardForTerritoriesWithCities).. "]   • av# cities/terrs with cities " ..tostring (cityRewards[playerID].aveCitiesPerTerritory)).SetFlexibleWidth (1.0);
		-- UI.CreateLabel (windowUI).SetText ("• Tolerance: " ..tostring (cityAverageToleranceLevel*100).. "%   • #terrs within Tolerance: " ..tostring (cityRewards[playerID].numCitiesWithinTolerance).. " [+"..tostring (cityRewards[playerID].numCities * cityRewardIncrement * cityRewards[playerID].numCitiesWithinTolerance).. "]").SetFlexibleWidth (1.0);
		UI.CreateLabel (windowUI).SetText ("• Tolerance: " ..tostring (cityAverageToleranceLevel*100).. "%   • #terrs within Tolerance: " ..tostring (cityRewards[playerID].numCitiesWithinTolerance).. " [+" ..tostring (cityRewards[playerID].rewardForCityStacksWithinTolerance).. "]   • Lower bound: " ..tostring (lowerBound).. "   • Upper bound: " ..tostring (upperBound)).SetFlexibleWidth (1.0);
		-- UI.CreateLabel (windowUI).SetText ("• City reward: " ..tostring (cityRewards[playerID].numTerritoriesWithCities * cityRewards[playerID].numCitiesWithinTolerance * cityRewardIncrement).. " [+"..tostring (cityRewardIncrement*100).."% * " ..tostring (cityRewards[playerID].numCitiesWithinTolerance).. " * " ..tostring (cityRewards[playerID].numTerritoriesWithCities).. "]").SetFlexibleWidth (1.0);
		UI.CreateLabel (windowUI).SetText ("• City reward: " ..tostring (cityRewards[playerID].rewardTotal).. " [+"..tostring (cityRewardIncrement*100).."% * (" ..tostring (cityRewards[playerID].numCitiesWithinTolerance).. " + " ..tostring (cityRewards[playerID].numTerritoriesWithCities).. ")]").SetFlexibleWidth (1.0);
	end

	-- attacks " ..incomeAdjustments.CurrTurn.Attacks.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
	-- print ("Long-term penalty " ..incomeAdjustments.LongTermPunishmentUnits.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
	local intIncome = game.Us.Income (0, game.LatestStanding, false, false).Total; --get player's income w/o respect to reinf cards, and wrt current turn & any applicable army cap + sanctions
	local intRewardIncome = math.floor (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
	local intPunishmentIncome = math.ceil ((incomeAdjustments.LongTermPunishmentUnits + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
	local intNewIncome = intIncome + intRewardIncome + intPunishmentIncome;

	print ("LONG-TERM [ID " ..playerID.. "] income penalty " ..tostring (incomeAdjustments.LongTermPunishmentUnits).. "PU, army reduction " ..tostring (incomeAdjustments.ArmyReduction).. "x, terr reduction " ..tostring (incomeAdjustments.TerritoryReduction).. "x, 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
	print ("CURR TURN [ID " ..playerID.. "] income "..intIncome.." [new " ..intNewIncome.. "], punishment "..intPunishmentIncome.. " [" ..incomeAdjustments.CurrTurn.PunishmentUnits.. "PU], reward " ..intRewardIncome.. " [" ..incomeAdjustments.CurrTurn.RewardUnits.. "RU], isAttack "..tostring (incomeAdjustments.CurrTurn.Attacks)..", isCapture ".. tostring (incomeAdjustments.CurrTurn.Captures)..", terrInc "..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));
end

function showDebugDataForAllPlayers (rootParent, setMaxSize, setScrollable, game, close)
	setMaxSize (800, 600);
	local DataWindow = rootParent;

	debugPrint ("\n- - - - - - - - -\n[DEBUG DATA]\n", DataWindow);

	if (Mod.PublicGameData.PRdataByID == nil) then debugPrint ("No PR data yet", DataWindow);
	else
		for k,v in pairs (Mod.PublicGameData.PRdataByID) do
			debugPrint ("PLAYER "..k.. " [" ..getPlayerName (game, k).. "]", DataWindow);
			if (v.Attacks == nil or tablelength (v.Attacks) ==0) then debugPrint ("ATTACKS ID "..k.. ", no attacks (all turns)", DataWindow);
			else for k2,v2 in pairs (v.Attacks) do debugPrint ("ATTACKS ID "..k.. ", turn "..k2.. "== "..v2, DataWindow); end
			end

			if (v.Captures == nil or tablelength (v.Captures) ==0) then debugPrint ("CAPTURES ID "..k.. ", no captures (all turns)", DataWindow);
			else for k2,v2 in pairs (v.Captures) do debugPrint ("CAPTURES ID "..k.. ", turn "..k2.. "== "..v2, DataWindow); end
			end

			--this always happens each turn
			for k2,v2 in pairs (v.TerritoryCount) do debugPrint ("TCOUNT ID "..k.. ", turn "..k2.. "== "..v2, DataWindow); end

			local incomeAdjustments = assessLongTermPunishment (v, game.Game.TurnNumber-1); --use -1 b/c current turn number from the client during order entry is 1 higher than the # of actually finished turns
			debugPrint ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount), DataWindow);
			debugPrint ("Long-term penalty " ..incomeAdjustments.LongTermPunishmentUnits.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving), DataWindow);
		end
	end
end

function debugPrint (strText, UIlabel)
	UI.CreateLabel (UIlabel).SetText (strText);
	print (strText);
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<50) then return ("AI "..playerid);
	else
		for _,playerinfo in pairs(game.Game.Players) do
			if(tonumber(playerid) == tonumber(playerinfo.ID))then
				return (playerinfo.DisplayName(nil, false));
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found but playerID >50 was provided
end

function getColours()
    local colors = {};					-- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="Card|Reinforcement") then return getColours()["Dark Green"]; --green
	elseif (itemName=="Card|Spy") then return getColours()["Red"]; --
	elseif (itemName=="Card|Emergency Blockade card") then return getColours()["Blue"]; --
	elseif (itemName=="Card|OrderPriority") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|OrderDelay") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Airlift") then return "#777777"; --
	elseif (itemName=="Card|Gift") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Diplomacy") then return getColours()["Light Blue"]; --
	-- elseif (itemName=="Card|") then return getColours()["Medium Blue"]; --
	elseif (itemName=="Card|Sanctions") then return getColours()["Purple"]; --
	elseif (itemName=="Card|Reconnaissance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Surveillance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Blockade") then return getColours()["Blue"]; --
	elseif (itemName=="Card|Bomb") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Nuke") then return getColours()["Tyrian Purple"]; --
	elseif (itemName=="Card|Airstrike") then return getColours()["Ivory"]; --
	elseif (itemName=="Card|Pestilence") then return getColours()["Lime"]; --
	elseif (itemName=="Card|Isolation") then return getColours()["Red"]; --
	elseif (itemName=="Card|Shield") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Monolith") then return getColours()["Hot Pink"]; --
	elseif (itemName=="Card|Card Block") then return getColours()["Light Blue"]; --
	elseif (itemName=="Card|Card Pieces") then return getColours()["Sea Green"]; --
	elseif (itemName=="Card|Card Hold") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Phantom") then return getColours()["Smoky Black"]; --
	elseif (itemName=="Card|Neutralize") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Deneutralize") then return getColours()["Green"]; --
	elseif (itemName=="Card|Earthquake") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Tornado") then return getColours()["Charcoal"]; --
	elseif (itemName=="Card|Quicksand") then return getColours()["Saddle Brown"]; --
	elseif (itemName=="Card|Forest Fire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Resurrection") then return getColours()["Goldenrod"]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
    else return "#AAAAAA"; --return light grey for everything else
    end
end