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

	if (Mod.PublicGameData.PRdataByID == nil or Mod.PublicGameData.PRdataByID [clientPlayerID] == nil) then return; end

	local incomeAdjustments = assessLongTermPunishment (Mod.PublicGameData.PRdataByID [clientPlayerID], game.Game.TurnNumber-1); --use -1 b/c current turn number from the client during order entry is 1 higher than the # of actually finished turns

	MenuWindow = rootParent;
	TopLabel = UI.CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText (""); --future use?
	-- UI.CreateLabel (MenuWindow).SetText ("Punishments: [none]");
	-- UI.CreateLabel (MenuWindow).SetText ("Rewards: [none]");
	UI.CreateLabel (MenuWindow).SetText ("\nCONSECUTIVE TURN PERIOD Punishments:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Block card piece receiving: " ..tostring (incomeAdjustments.BlockCardPieceReceiving)).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Territories with 0 armies go neutral: " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral)).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Income reduction: " ..tostring (incomeAdjustments.LongTermPenalty * 100).. "%").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Army reduction: " ..tostring (incomeAdjustments.ArmyReduction*100).. "%").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Territory reduction: " ..tostring (incomeAdjustments.TerritoryReduction*100).. "%").SetFlexibleWidth (1.0);

	UI.CreateLabel (MenuWindow).SetText ("\n- - - - - - - - -\nDetails:\nEach turn you will get a Punishment of " ..tostring (1*punishmentIncrement*100).. "% to income or a Reward of " ..tostring (1*punishmentIncrement*100).. "% on categories of Attacks, Captures & Increasing your territory count. The quantity of attacks/captures/new territories in a single turn doesn't matter.").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("\nIn addition to the single turn Punishment/Reward, additional Punishments will be given when you have consecutive turns with no territory count increases, as follows:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• 1-3 turns: no additional long term penalty").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• 4-6 turns: " ..tostring (1*punishmentIncrement*100).. "% income penalty, no card pieces").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• 7-9 turns: " ..tostring (2*punishmentIncrement*100).. "% income penalty, no card pieces, -5% armies on all territories & territories with 0 units go neutral & blockade (with added units)").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• 10+ turns: " ..tostring (3*punishmentIncrement*100).. "% income penalty, no card pieces, -10% armies on all territories, territories with 0 units go neutral & blockade (with added units)").SetFlexibleWidth (1.0);

	UI.CreateLabel (MenuWindow).SetText ("\n• #Finished turns: " ..tostring (game.Game.TurnNumber-1).. "   • #Turns evaluated on: " ..tostring (incomeAdjustments.NumTurnsEvaluatedOn)).SetAlignment(WL.TextAlignmentOptions.Left).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("\nTurns where territory count didn't increase:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• #Total: " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. "   • #Consecutive: " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease)).SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("\nTerritory counts:").SetFlexibleWidth (1.0);
	UI.CreateLabel (MenuWindow).SetText ("• Average: " ..tostring (incomeAdjustments.AverageTerritoryCount).. "   • Highest: " ..tostring (incomeAdjustments.HighestTerritoryCount)).SetFlexibleWidth (1.0);

	print ("-----NO_INCREASE #turns evaluated " ..incomeAdjustments.NumTurnsEvaluatedOn.. ", #turns total " ..tostring (incomeAdjustments.NumTurnsWithNoIncrease).. ", consecutive " ..tostring (incomeAdjustments.NumConsecutiveTurnsWithNoIncrease).. ", average " ..tostring (incomeAdjustments.AverageTerritoryCount).. ", highest " ..tostring (incomeAdjustments.HighestTerritoryCount));
	print ("Curr-turn Penalty " ..incomeAdjustments.CurrTurn.PunishmentUnits.. ", Reward " ..incomeAdjustments.CurrTurn.RewardUnits.. ", attacks " ..incomeAdjustments.CurrTurn.Attacks.. ", captures " ..incomeAdjustments.CurrTurn.Captures.. ", #territories " ..incomeAdjustments.CurrTurn.TerritoryCount.. ", terr increased " ..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));
	local strRewardText = "[none]";
	local strPunishmentText = "[none]";
	if (incomeAdjustments.CurrTurn.PunishmentUnits > 0) then strPunishmentText = tostring (incomeAdjustments.CurrTurn.PunishmentUnits * 100 * punishmentIncrement).. "% income"; end
	if (incomeAdjustments.CurrTurn.RewardUnits > 0) then strRewardText = "+" ..tostring (incomeAdjustments.CurrTurn.RewardUnits * 100 * rewardIncrement).. "% income"; end
	TopLabel.SetText ("\nCURRENT TURN:\nPunishments: " ..strPunishmentText.. "\nRewards: " ..strRewardText);

	-- attacks " ..incomeAdjustments.CurrTurn.Attacks.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
	print ("Long-term penalty " ..incomeAdjustments.LongTermPenalty.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));

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
				debugPrint ("Long-term penalty " ..incomeAdjustments.LongTermPenalty.. ", army reduction " ..incomeAdjustments.ArmyReduction.. ", terr reduction " ..incomeAdjustments.TerritoryReduction.. ", 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving), MenuWindow);

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