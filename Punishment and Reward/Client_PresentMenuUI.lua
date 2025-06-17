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
	local playerData = {};
	MenuWindow = rootParent;
	TopLabel = UI.CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText (""); --use below to show Punishment/Reward values after some calculations are done, but define it here so it shows at the top of the form
	-- UI.CreateLabel (MenuWindow).SetText ("Punishments: [none]");
	-- UI.CreateLabel (MenuWindow).SetText ("Rewards: [none]");

	local labelConsecutivePunishmentDetails;
	local incomeAdjustments;

	local strLongTermPunishmentL1 = "• 0-3 turns: no additional long term penalty";
	local strLongTermPunishmentL2 = "• 4-6 turns: " ..tostring (1*punishmentIncrement*100).. "% income penalty, no card pieces";
	local strLongTermPunishmentL3 = "• 7-9 turns: " ..tostring (2*punishmentIncrement*100).. "% income penalty, no card pieces, [future: -5% armies on all territories & territories with 0 units go neutral & blockade (with added units)]";
	local strLongTermPunishmentL4 = "• 10+ turns: " ..tostring (3*punishmentIncrement*100).. "% income penalty, no card pieces, [future: -10% armies on all territories, territories with 0 units go neutral & blockade (with added units)]";

	if (Mod.PublicGameData.PRdataByID ~= nil and Mod.PublicGameData.PRdataByID [clientPlayerID] ~= nil) then

		incomeAdjustments = assessLongTermPunishment (Mod.PublicGameData.PRdataByID [clientPlayerID], game.Game.TurnNumber-1); --use -1 b/c current turn number from the client during order entry is 1 higher than the # of actually finished turns

		print ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount));
		print ("Curr-turn Penalty " ..incomeAdjustments.CurrTurn.PunishmentUnits.. ", Reward " ..incomeAdjustments.CurrTurn.RewardUnits.. ", attacks " ..incomeAdjustments.CurrTurn.Attacks.. ", captures " ..incomeAdjustments.CurrTurn.Captures.. ", #territories " ..incomeAdjustments.CurrTurn.TerritoryCount.. ", terr increased " ..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));
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
		local horzCurrentState = UI.CreateHorizontalLayoutGroup (MenuWindow).SetFlexibleWidth(1);
		UI.CreateLabel (horzCurrentState).SetText ("CURRENT STATE:    ").SetColor (getColourCode ("main heading")).SetAlignment (WL.TextAlignmentOptions.Left);
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
		UI.CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText ("\nCOMPONENT 1 - MOST RECENT TURN: (Turn " ..tostring (game.Game.TurnNumber-1).. ")").SetColor (getColourCode ("main heading"));
		UI.CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText ("Punishments: " ..strPunishmentText.. "\nRewards: " ..strRewardText);
		-- TopLabel.SetText ("\nMOST RECENT TURN:\nPunishments: " ..strPunishmentText.. "\nRewards: " ..strRewardText);

		UI.CreateLabel (MenuWindow).SetText ("\nCOMPONENT 2 - CONSECUTIVE TURN PERIOD Punishments:").SetFlexibleWidth (1.0).SetColor (getColourCode ("main heading"));
		UI.CreateLabel (MenuWindow).SetText ("• CRITERIA: Consecutive turns with no territory increase: " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease)).SetFlexibleWidth (1.0).SetColor (getColourCode ("subheading"));

		--populate the label above with the details of the Consecutive punishments (for not increasing territory count)
		labelConsecutivePunishmentDetails = UI.CreateLabel (MenuWindow).SetText ("  • ").SetFlexibleWidth (1.0);
		if (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 3) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL1).SetColor ("#00FF00"); --green
		elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 6) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL2).SetColor ("#FFFF00"); --yellow
		elseif (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease <= 9) then labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL3).SetColor ("#FFA500"); --orange
		else labelConsecutivePunishmentDetails.SetText ("    " ..strLongTermPunishmentL4).SetColor ("#FF0000"); --red
		end

		--incomeAdjustments.NumConsecutiveTurnsWithNoIncrease
		UI.CreateLabel (MenuWindow).SetText ("• IMPACT:").SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("    • Nullify receiving card pieces at end of turn: " ..tostring (incomeAdjustments.BlockCardPieceReceiving)).SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("    • Territories with 0 armies go neutral: " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral)).SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("    • Income reduction: " ..tostring (incomeAdjustments.LongTermPunishmentUnits * 100).. "%").SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("    • Army reduction: " ..tostring (incomeAdjustments.ArmyReduction*100).. "%").SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("    • Territory reduction: " ..tostring (incomeAdjustments.TerritoryReduction*100).. "%").SetFlexibleWidth (1.0);

		UI.CreateLabel (MenuWindow).SetText ("\n• #Finished turns: " ..tostring (game.Game.TurnNumber-1).. "   • #Turns evaluated on: " ..tostring (incomeAdjustments.NumTurnsEvaluatedOn)).SetAlignment(WL.TextAlignmentOptions.Left).SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("\nTurns where territory count didn't increase:").SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("• #Total: " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. "   • #Consecutive: " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease)).SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("\nTerritory counts:").SetFlexibleWidth (1.0);
		UI.CreateLabel (MenuWindow).SetText ("• Average: " ..tostring (math.floor ((incomeAdjustments.AverageTerritoryCount) * 100 + 0.5)/100).. "   • Highest: " ..tostring (incomeAdjustments.HighestTerritoryCount)).SetFlexibleWidth (1.0);

		--check for presence of Workers -- flag it somewhere in PublicGameData, then display this iff Workers are in play or Can build cities (else it's irrelevant)
		-- if (game.Settings.CommerceGame == false) then alert ("Commerce must be enabled to function properly.\n\nIf you wish to use this mod, enable Commerce. Otherwise, disable this mod to proceed."); end
		if (game.Settings.CommerceCityBaseCost ~= nil or SUisInUse (nil, game.LatestStanding.Territories, "Worker")) then
			local cityRewards = assessCityRewards (game.LatestStanding.Territories, {[game.Us.ID] = game.Game.Players [game.Us.ID]});
			UI.CreateLabel (MenuWindow).SetText ("\n[FUTURE] CITY REWARDS:\n• Commerce: " ..tostring (game.Settings.CommerceGame).. "   • City cost: " ..tostring (game.Settings.CommerceCityBaseCost).. "   • Workers in play: " ..tostring (SUisInUse (nil, game.LatestStanding.Territories, "Worker"))).SetFlexibleWidth (1.0);
			-- UI.CreateLabel (MenuWindow).SetText ("• # cities: " ..tostring (cityRewards[game.Us.ID].numCities).. "   • # terrs: " ..tostring (cityRewards[game.Us.ID].numTerritories).. "   • # terrs w/cities: " ..tostring (cityRewards[game.Us.ID].numTerritoriesWithCities).. " [+" ..tostring (cityRewards[game.Us.ID].rewardForTerritoriesWithCities).. "]   • av# cities/terr " ..tostring (cityRewards[game.Us.ID].aveCitiesPerTerritory).. "   • av# cities/terr w/cities " ..tostring (cityRewards[game.Us.ID].aveCitiesPerTerritory)).SetFlexibleWidth (1.0);
			UI.CreateLabel (MenuWindow).SetText ("• # cities: " ..tostring (cityRewards[game.Us.ID].numCities).. "   • # terrs w/cities: " ..tostring (cityRewards[game.Us.ID].numTerritoriesWithCities).. " [+" ..tostring (cityRewards[game.Us.ID].rewardForTerritoriesWithCities).. "]   • av# cities/terr w/cities " ..tostring (cityRewards[game.Us.ID].aveCitiesPerTerritory)).SetFlexibleWidth (1.0);
			-- UI.CreateLabel (MenuWindow).SetText ("• Tolerance: " ..tostring (cityAverageToleranceLevel*100).. "%   • #terrs within Tolerance: " ..tostring (cityRewards[game.Us.ID].numCitiesWithinTolerance).. " [+"..tostring (cityRewards[game.Us.ID].numCities * cityRewardIncrement * cityRewards[game.Us.ID].numCitiesWithinTolerance).. "]").SetFlexibleWidth (1.0);
			UI.CreateLabel (MenuWindow).SetText ("• Tolerance: " ..tostring (cityAverageToleranceLevel*100).. "%   • #terrs within Tolerance: " ..tostring (cityRewards[game.Us.ID].numCitiesWithinTolerance).. " [+" ..tostring (cityRewards[game.Us.ID].rewardForCityStacksWithinTolerance).. "]").SetFlexibleWidth (1.0);
			-- UI.CreateLabel (MenuWindow).SetText ("• City reward: " ..tostring (cityRewards[game.Us.ID].numTerritoriesWithCities * cityRewards[game.Us.ID].numCitiesWithinTolerance * cityRewardIncrement).. " [+"..tostring (cityRewardIncrement*100).."% * " ..tostring (cityRewards[game.Us.ID].numCitiesWithinTolerance).. " * " ..tostring (cityRewards[game.Us.ID].numTerritoriesWithCities).. "]").SetFlexibleWidth (1.0);
			UI.CreateLabel (MenuWindow).SetText ("• City reward: " ..tostring (cityRewards[game.Us.ID].rewardTotal)).SetFlexibleWidth (1.0);--.. " [+"..tostring (cityRewardIncrement*100).."% * " ..tostring (cityRewards[game.Us.ID].numCitiesWithinTolerance).. " * " ..tostring (cityRewards[game.Us.ID].numTerritoriesWithCities).. "]").SetFlexibleWidth (1.0);
		end

		-- attacks " ..incomeAdjustments.CurrTurn.Attacks.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
		-- print ("Long-term penalty " ..incomeAdjustments.LongTermPunishmentUnits.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
		local intIncome = game.Us.Income (0, game.LatestStanding, false, false).Total; --get player's income w/o respect to reinf cards, and wrt current turn & any applicable army cap + sanctions
		local intRewardIncome = math.floor (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
		local intPunishmentIncome = math.ceil ((incomeAdjustments.LongTermPunishmentUnits + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
		local intNewIncome = intIncome + intRewardIncome + intPunishmentIncome;

		print ("LONG-TERM [ID " ..clientPlayerID.. "] income penalty " ..tostring (incomeAdjustments.LongTermPunishmentUnits).. "PU, army reduction " ..tostring (incomeAdjustments.ArmyReduction).. "x, terr reduction " ..tostring (incomeAdjustments.TerritoryReduction).. "x, 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
		print ("CURR TURN [ID " ..clientPlayerID.. "] income "..intIncome.." [new " ..intNewIncome.. "], punishment "..intPunishmentIncome.. " [" ..incomeAdjustments.CurrTurn.PunishmentUnits.. "PU], reward " ..intRewardIncome.. " [" ..incomeAdjustments.CurrTurn.RewardUnits.. "RU], isAttack "..tostring (incomeAdjustments.CurrTurn.Attacks)..", isCapture ".. tostring (incomeAdjustments.CurrTurn.Captures)..", terrInc "..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));

	end

	UI.CreateLabel (MenuWindow).SetText ("\n- - - - - - - - -\nMechanics:\nEach turn you will get a Punishment of " ..tostring (1*punishmentIncrement*100).. "% to income or a Reward of +" ..tostring (1*rewardIncrement*100).. "% on each category of:\n(A) Attacks [at least 1 attack made]\n(B) Captures [at least 1 capture made]\n(C) Increasing your territory count [territory count increased by at least 1]").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("\nIn addition to the single turn Punishment/Reward, additional Punishments will be given when you have consecutive turns with no territory count increases, as follows:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText (strLongTermPunishmentL1).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText (strLongTermPunishmentL2).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText (strLongTermPunishmentL3).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText (strLongTermPunishmentL4).SetFlexibleWidth (1.0);

	--only display if Cities can be built or if Workers are in use (but how to check for workers? see if any are on the map already? that's the only way to know for sure b/c can't check the mods in play)
	-- CreateLabel (MenuWindow).SetText ("\nCITIES: Rewards of 1% of total city income value will be granted for each territory you possess where the # of cities is within 10% of the average cities per territories (#territories/#cities). There are no Punishments for city distribution");
	-- CreateLabel (MenuWindow).SetText ("\n# territories: tbd, # cities: tbd, av cities/territory (ACT): tbd");
	-- CreateLabel (MenuWindow).SetText ("\n# territories with city count within 10% ACT: tbd, Reward: xx% (yy gpt)");

	if (game.Us.ID == 1058239) then
	-- if (Mod.PublicGameData.Debug ~= nil and (game.Us.ID == Mod.PublicGameData.Debug.DebugUser or game.Us.ID == 1058239)) then
		debugPrint ("\n- - - - - - - - -\n[DEBUG DATA]\n", MenuWindow);

		if (Mod.PublicGameData.PRdataByID == nil) then debugPrint ("No PR data yet", MenuWindow);
		else
			for k,v in pairs (Mod.PublicGameData.PRdataByID) do
				debugPrint ("PLAYER "..k.. " [" ..getPlayerName (game, k).. "]", MenuWindow);
				if (v.Attacks == nil or tablelength (v.Attacks) ==0) then debugPrint ("ATTACKS ID "..k.. ", no attacks (all turns)", MenuWindow);
				else for k2,v2 in pairs (v.Attacks) do debugPrint ("ATTACKS ID "..k.. ", turn "..k2.. "== "..v2, MenuWindow); end
				end

				if (v.Captures == nil or tablelength (v.Captures) ==0) then debugPrint ("CAPTURES ID "..k.. ", no captures (all turns)", MenuWindow);
				else for k2,v2 in pairs (v.Captures) do debugPrint ("CAPTURES ID "..k.. ", turn "..k2.. "== "..v2, MenuWindow); end
				end

				--this always happens each turn
				for k2,v2 in pairs (v.TerritoryCount) do debugPrint ("TCOUNT ID "..k.. ", turn "..k2.. "== "..v2, MenuWindow); end

				local incomeAdjustments = assessLongTermPunishment (v, game.Game.TurnNumber-1); --use -1 b/c current turn number from the client during order entry is 1 higher than the # of actually finished turns
				debugPrint ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount), MenuWindow);
				debugPrint ("Long-term penalty " ..incomeAdjustments.LongTermPunishmentUnits.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving), MenuWindow);

			end

			-- for k,v in pairs (Mod.PublicGameData.PRdataByTurn) do
			-- 	if (v.Attacks == nil or tablelength (v.Attacks) ==0) then debugPrint ("ATTACKS TURN "..k.. ", no attacks (all players)", MenuWindow);
			-- 	else for k2,v2 in pairs (v.Attacks) do debugPrint ("ATTACKS turn "..k.. ", ID "..k2.. "== "..v2, MenuWindow); end
			-- 	end

			-- 	if (v.Captures == nil or tablelength (v.Captures) ==0) then debugPrint ("CAPTURES TURN "..k.. ", no captures (all players)", MenuWindow);
			-- 	else for k2,v2 in pairs (v.Captures) do debugPrint ("CAPTURES turn "..k.. ", ID "..k2.. "== "..v2, MenuWindow); end
			-- 	end

			-- 	--this always happens each turn
			-- 	for k2,v2 in pairs (v.TerritoryCount) do debugPrint ("TCOUNT turn "..k.. ", ID "..k2.. "== "..v2, MenuWindow); end
			-- end
		end
	end

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