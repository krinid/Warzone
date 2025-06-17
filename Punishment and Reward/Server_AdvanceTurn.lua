require ("punishReward");

--[[
TODO:
- implement territory count punishment/rewards
- punished 1PU for not attacking each enemy you border -- ensure to not punish for teammates (in case this is used in team games)
- implement tracking territory count for X turns (default 10) apply rolling increasing pun/rew for increases/decreases in the past 10 turns; decrease = nerf, increase = buff, no change = small nerf
- implement Sanction/Reverse Sanction casting limitations; on self YES/NO, on teammate YES/NO
- anti-card farming --> if own territory @ start of turn, doesn't count as a cap; check if was that player's territory in any of the last 10 turns? maybe this is too punishing? and too compute intensive to check for all captures?
- punishments = 1PU punishment unit = -5% or -10%?
- rewards = 1RU reward unit = +10%
- punishments - each turn w/o attacks = 1 PU, each turn w/o a capture = 1 PU, each turn w/o going up in territories = 1 PU (too punishing?)
- for each additional in the last 10 turns it's another 0.3 PU
- >5PU causes -1 from all territories
- >8PU causes -2 from all territories
- >10PU causes -5 from all territories
- >15PU causes -10 from all territories
- territories won't go from >=1 to neutral, but if already at 0 when the punishment hits, they go will neutral; confirm if using OMS that they will still go to 0 then neutral
- any kill rate impacts?
- city spread - if # of cities on territory == #cities/#terrs (within 10%?) - bonus; if >10% punish?
- reduce (or eliminate) cities when captured?
- allow cities to be sold?
- allow cities to be moved?
- give buff to city growth on territories where bordering territories have <= (not >) city quantity; specifically how? tbd
]]

function Server_AdvanceTurn_Start (game, addOrder)
	--move these to PublicGameData
	print ("[S_AT_S] START");
	disallowReverseSanctionsOnOthers = true;
	disallowNormalSanctionsOnSelf = true;

	--structure used for this turn order, initialize them to {} for each iteration
	Attacks = {};
	Captures = {};
	TerritoryIncrease = {};
	-- local privateGameData = Mod.PrivateGameData;
	-- privateGameData.CardData = game.ServerGame.LatestTurnStanding.Cards;
	-- print ("###"..tostring (#privateGameData.CardData));
	-- Mod.PrivateGameData = privateGameData;
	-- print ("###"..tostring (#Mod.PrivateGameData.CardData));
	-- Cards = game.ServerGame.LatestTurnStanding.Cards; --capture Cards state at start of turn (for testing only -- too soon for anything else b/c cards can be used through the _Order processing)

	-- initialize Cards table to {}, set boolCardsCaptured flag to false; after populating the Cards table, set flag to true so it's only processed/populated once and not multiple times
	Cards = {};
	boolCardsCaptured = false;


	-- Cards = game.ServerGame.LatestTurnStanding.Cards;
	-- for k,v in pairs (Cards) do --for each element table of player,PlayerCards
	-- 	print ("&&"..k,tostring (v),tostring(v.Pieces));
	-- 	for k2,vp in pairs (v.Pieces) do
	-- 		print ("[**PIECES] "..k,k2,vp)
	-- 	end
	-- end

	-- captureCardCounts (game);

	--[[for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards) do --for each element table of player,PlayerCards
		Cards[k] = {};
		Cards[k].Pieces = {};
		Cards[k].WholeCards = {};
		for k2,vp in pairs (v.Pieces) do
			-- print ("[PIECES] "..k,k2,vp);
			Cards[k].Pieces [k2]= vp;
		end
		-- print ("[CARDS] TOTAL "..k,#v.WholeCards)
		for k3,vwc in pairs (v.WholeCards) do
			-- print ("[CARDS] "..k,k3,vwc.CardID);
			if (Cards[k].WholeCards [vwc.CardID] == nil) then Cards[k].WholeCards [vwc.CardID] = 0; end
			Cards[k].WholeCards [vwc.CardID] = Cards[k].WholeCards [vwc.CardID] + 1;
			-- Cards[k].WholeCards [vwc.CardID] = true;
		end
	end
	for k,v in pairs (Cards) do --for each element table of player,PlayerCards
		-- print ("&&"..k,tostring (v),tostring(v.Pieces));
		for k2,vp in pairs (v.Pieces) do
			print ("[**PIECES] "..k,k2,vp);
		end
		for k3,vc in pairs (v.WholeCards) do
			print ("[**CARDS] "..k,k3,vc);
		end
	end ]]

	-- addOrder (WL.GameOrderCustom.Create (1, "Capture card state 1", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 1b", "PunishReward|Capture card state", {}, WL.TurnPhase.ReceiveCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 2", "PunishReward|Capture card state", {}, WL.TurnPhase.SanctionCards));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 3", "PunishReward|Capture card state"));
	-- addOrder (WL.GameOrderCustom.Create (1058239, "Capture card state 4", "PunishReward|Capture card state", nil, WL.TurnPhase.BlockadeCards));

	-- captureCardStateOrder.OccursInPhaseOpt = WL.TurnPhase.ReceiveCards;
	-- addOrder (captureCardStateOrder);
		-- ['SanctionCards'] = WL.TurnPhase.SanctionCards,
		-- ['ReceiveCards'] = WL.TurnPhase.ReceiveCards,
		-- ['ReceiveGold'] = WL.TurnPhase.ReceiveGold

	print ("[S_AT_S] END");
end

function captureCardCounts (game)
	boolCardsCaptured = true;
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards) do --for each element table of player,PlayerCards
		Cards[k] = {};
		Cards[k].Pieces = {};
		Cards[k].WholeCards = {};
		for k2,vp in pairs (v.Pieces) do
			-- print ("[PIECES] "..k,k2,vp);
			Cards[k].Pieces [k2]= vp;
		end
		-- print ("[CARDS] TOTAL "..k,#v.WholeCards)
		for k3,vwc in pairs (v.WholeCards) do
			-- print ("[CARDS] "..k,k3,vwc.CardID);
			if (Cards[k].WholeCards [vwc.CardID] == nil) then Cards[k].WholeCards [vwc.CardID] = 0; end
			Cards[k].WholeCards [vwc.CardID] = Cards[k].WholeCards [vwc.CardID] + 1;
			-- Cards[k].WholeCards [vwc.CardID] = true;
		end
	end
	for k,v in pairs (Cards) do --for each element table of player,PlayerCards
		-- print ("&&"..k,tostring (v),tostring(v.Pieces));
		for k2,vp in pairs (v.Pieces) do
			-- print ("[**PIECES] "..k,k2,vp);
		end
		for k3,vc in pairs (v.WholeCards) do
			-- print ("[**CARDS] "..k,k3,vc);
		end
	end
end

function Server_AdvanceTurn_End(game, addOrder)
	print ("[S_AT_E] START");
--[[ 	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards) do --for each element table of player,PlayerCards
	-- for k,v in pairs (Cards) do --for each element table of player,PlayerCards
		for k2,vp in pairs (v.Pieces) do
			print ("[PIECES] "..k,k2,vp)
		end
		print ("[CARDS] TOTAL "..k,#v.WholeCards)
		for k3,vwc in pairs (v.WholeCards) do
			print ("[CARDS] "..k,vwc.CardID, k3,vwc)
		end
	end]]

	--move these initializations to Server_Create or somewhere else
	--these are used to track the past 10 (make configurable) turns to apply cumulative averages, not just immediate data from the current turn
	if (historicalAttacks==nil) then historicalAttacks = {}; end;
	if (historicalCaptures==nil) then historicalCaptures = {}; end;
	if (historicalTerritoryCount==nil) then historicalTerritoryCount = {}; end;
	local turnNumber = game.Game.TurnNumber;
	local playerList = game.ServerGame.Game.PlayingPlayers;

	--set any nil elements to 0; only elements (playerID) which had attacks/captures have values set; players with no attacks/captures are nil; to them to 0 so can do math with any element
	-- Attacks = cleanElements (Attacks);
	-- Captures = cleanElements (Captures);
	-- Attacks = cleanElements (Attacks, turnNumber, playerList);
	-- Captures = cleanElements (Captures, turnNumber, playerList);

	local publicGameData = Mod.PublicGameData;
	if (publicGameData.PRdataByTurn == nil) then publicGameData.PRdataByTurn = {}; end
	if (publicGameData.PRdataByTurn[turnNumber] == nil) then publicGameData.PRdataByTurn[turnNumber] = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].Attacks == nil) then publicGameData.PRdataByTurn[turnNumber].Attacks = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].Captures == nil) then publicGameData.PRdataByTurn[turnNumber].Captures = {}; end
	if (publicGameData.PRdataByTurn[turnNumber].TerritoryCount == nil) then publicGameData.PRdataByTurn[turnNumber].TerritoryCount = {}; end
	publicGameData.PRdataByTurn[turnNumber].Attacks = Attacks; --store Attacks for this turn; this is easily retrievable by turn#, then by playerID
	publicGameData.PRdataByTurn[turnNumber].Captures = Captures; --store Captures for this turn; this is easily retrievable by turn#, then by playerID

	local intarrTerritoryCount_currentTurn = territoryCountAnalysis (game);

	for ID,player in pairs (game.ServerGame.Game.PlayingPlayers) do
		local intTerritoryCount_lastTurn = 0;
		local intTerritoryCount_currentTurn = intarrTerritoryCount_currentTurn [ID];
		local intPunishment_territoryCount = 0;
		local intReward_territoryCount = 0;
		local intPunishment_attack = 0;
		local intReward_attack = 0;
		local intPunishment_capture = 0;
		local intReward_capture = 0;
		local intPunishmentTotalUnits = 0;
		local intRewardTotalUnits = 0;
		local intPunishmentIncome = 0;
		local intRewardIncome = 0;
		local intPunishmentRewardAdjustedIncome = 0; --net new income inclusive of Punishment & Reward adjustments

		--assign value to intTerritoryCount_lastTurn; if turn ==1 then ignore b/c there is no previous value; if turn >1 then get territory count of previous turn; else leave as default value (0)
		if (turnNumber >1 and publicGameData.PRdataByID ~= nil and publicGameData.PRdataByID[ID] ~= nil and publicGameData.PRdataByID[ID].TerritoryCount ~= nil and publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1] ~= nil) then intTerritoryCount_lastTurn = publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1]; end
		-- if (turnNumber >1 and publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1] ~= nil) then intTerritoryCount_lastTurn = publicGameData.PRdataByID[ID].TerritoryCount[turnNumber-1]; end

		--identify if territory count has gone up, stayed flat or reduced; if flat, use the values of 0 for both Punishment/Reward (these are the defaults, no action required)
		if (intTerritoryCount_currentTurn <= intTerritoryCount_lastTurn) then intPunishment_territoryCount = 1; --territory count reduced, add 1 unit of Punishment
		else intReward_territoryCount = 1; --territory count increase, add 1 unit of Reward
		end

		if (publicGameData.PRdataByID == nil) then publicGameData.PRdataByID = {}; end
		if (publicGameData.PRdataByID[ID] == nil) then publicGameData.PRdataByID[ID] = {}; end
		if (publicGameData.PRdataByID[ID].Attacks == nil) then publicGameData.PRdataByID[ID].Attacks = {}; end
		if (publicGameData.PRdataByID[ID].Captures == nil) then publicGameData.PRdataByID[ID].Captures = {}; end
		if (publicGameData.PRdataByID[ID].TerritoryCount == nil) then publicGameData.PRdataByID[ID].TerritoryCount = {}; end
		publicGameData.PRdataByID[ID].Attacks[turnNumber] = Attacks[ID]; --store Attacks for this turn; this is easily retrievable by playerID, then by turn#
		publicGameData.PRdataByID[ID].Captures[turnNumber] = Captures[ID]; --store Captures for this turn; this is easily retrievable by playerID, then by turn#
		-- print (ID,turnNumber,Attacks[ID],publicGameData.PRdataByID[ID].Attacks[turnNumber]);

		historicalTerritoryCount[ID] = intTerritoryCount_currentTurn;
		publicGameData.PRdataByID[ID].TerritoryCount[turnNumber] = intTerritoryCount_currentTurn; -- store TerritoryCount for this turn; this is easily retrievable by playerID, then by turn#

		intReward_attack = Attacks[ID] or 0; --Attacks[ID]~=nil and 1 or 0; --assign 0 Reward units for no attacks made, assign 1 unit for 1+ attacks made
		intPunishment_attack = 1 - intReward_attack; --assign 0 Punishment units for attacks made, assign 1 unit for no attacks made
		intReward_capture = Captures[ID] or 0; --Captures[ID]==nil and 1 or 0; --assign 0 Reward units for no captures made, assign 1 unit for 1+ captures made
		intPunishment_capture = 1 - intReward_attack; --assign 0 Punishment units for captures made, assign 1 unit for no attacks made

		-- reward = (Attacks[ID]~=nil and 1 or 0)*rewardIncrement + (Captures[ID]~=nil and 1 or 0)*rewardIncrement + intReward_territoryCount*rewardIncrement;
		-- punishment = (Attacks[ID]==nil and 1 or 0)*punishmentIncrement + (Captures[ID]==nil and 1 or 0)*punishmentIncrement + (TerritoryIncrease[ID]==nil and 1 or 0)*punishmentIncrement;
		local intIncome = player.Income (0, game.ServerGame.LatestTurnStanding, false, false).Total; --get player's income w/o respect to reinf cards, and wrt current turn & any applicable army cap + sanctions
-- 		intRewardTotalUnits = intReward_attack + intReward_capture + intReward_territoryCount;
-- 		intPunishmentTotalUnits = intPunishment_attack + intPunishment_capture + intPunishment_territoryCount;
-- 		intRewardIncome = math.floor (intRewardTotalUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
-- 		intPunishmentIncome = math.ceil (intPunishmentTotalUnits * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
-- print ("!"..intReward_attack, intReward_capture, intReward_territoryCount, intTerritoryCount_lastTurn, intTerritoryCount_currentTurn);
-- print ("!"..intPunishmentTotalUnits, punishmentIncrement, intPunishmentIncome, intPunishment_attack, intPunishment_capture, intPunishment_territoryCount);
		-- reward = (intReward_attack + intReward_capture + intReward_territoryCount) * rewardIncrement;
		-- punishment = (intPunishment_attack + intPunishment_capture + intPunishment_territoryCount) * punishmentIncrement;
		--for reference: Income(armiesFromReinforcementCards integer, standing GameStanding, bypassArmyCap boolean, ignoreSanctionCards boolean) returns PlayerIncome: Determine's a player's income (number of armies they receive per turn)

		--calculate Punishments and Rewards
		local incomeAdjustments = assessLongTermPunishment (publicGameData.PRdataByID [ID], game.Game.TurnNumber); --use actual current turn # b/c it just finished and should be included in the calculations
		intRewardIncome = math.floor (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement * intIncome + 0.5); --round up/down appropriately
		intPunishmentIncome = math.ceil ((incomeAdjustments.LongTermPunishmentUnits + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement * intIncome); --NOTE: negative #'s, so just round up (less negative), never round down (more negative) for punishments
		local intNewIncome = intIncome + intRewardIncome + intPunishmentIncome;
		local intNetRU_PU_Change = (incomeAdjustments.CurrTurn.RewardUnits * rewardIncrement) + (incomeAdjustments.LongTermPunishmentUnits + incomeAdjustments.CurrTurn.PunishmentUnits) * punishmentIncrement;
		intPunishmentRewardAdjustedIncome = math.floor (intNetRU_PU_Change * intIncome + 0.5); --round up/down appropriately
		print ("LONG-TERM [ID " ..ID.. "] income punishment " ..incomeAdjustments.LongTermPunishmentUnits.. "PU, army reduction " ..incomeAdjustments.ArmyReduction.. "x, terr reduction " ..incomeAdjustments.TerritoryReduction.. "x, 0armies->neutral " ..tostring (incomeAdjustments.ZeroArmiesGoNeutral).. ", card pieces block " ..tostring (incomeAdjustments.BlockCardPieceReceiving));
		print ("CURR TURN [ID " ..ID.. "] income "..intIncome.." [new " ..intNewIncome.. "], punishment "..intPunishmentIncome.. " [" ..incomeAdjustments.CurrTurn.PunishmentUnits.. "PU], reward " ..intRewardIncome.. " [" ..incomeAdjustments.CurrTurn.RewardUnits.. "RU], isAttack "..tostring (incomeAdjustments.CurrTurn.Attacks)..", isCapture ".. tostring (incomeAdjustments.CurrTurn.Captures)..", terrInc "..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));
		print ("COMBINED PUN/REW [ID " ..ID.. "] income "..intIncome.." [new " ..intNewIncome.. "], punishment "..intPunishmentIncome.. " [" ..incomeAdjustments.CurrTurn.PunishmentUnits.. "PU], reward " ..intRewardIncome.. " [" ..incomeAdjustments.CurrTurn.RewardUnits.. "RU], isAttack "..tostring (incomeAdjustments.CurrTurn.Attacks)..", isCapture ".. tostring (incomeAdjustments.CurrTurn.Captures)..", terrInc "..tostring (incomeAdjustments.CurrTurn.TerritoryCountIncreased));

		--&&& combine these 2 and just make it display Punishment or Reward based on whether it's a net buff or nerf
		local strPunishmentOrReward = "Flat income (punishment = reward)";
		-- print ("[PUNREW] ".. ID, intPunishmentIncome, intRewardIncome, tostring (intPunishmentIncome < intRewardIncome),tostring (intNetRU_PU_Change));
		if (intNetRU_PU_Change > 0) then strPunishmentOrReward = "Reward";
		elseif (intNetRU_PU_Change < 0) then strPunishmentOrReward = "Punishment";
		else strPunishmentOrReward = "Flat income (punishment = reward)";
		end

		local strOrderMsg = strPunishmentOrReward.. " (" ..(intNetRU_PU_Change>0 and "+" or "")..tostring (intNetRU_PU_Change*100).. "%)"

		addOrder (WL.GameOrderEvent.Create (ID, strOrderMsg, {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome + intRewardIncome, strPunishmentOrReward.. " (" ..tostring (intPunishmentIncome + intRewardIncome).. ")")})); --floor = round down for punishment
		-- addOrder (WL.GameOrderEvent.Create (ID, "Punishment!", {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome, "Punishment (" .. intPunishmentIncome..")")})); --floor = round down for punishment
		-- addOrder (WL.GameOrderEvent.Create (ID, "Reward!",     {}, {}, {}, {WL.IncomeMod.Create(ID, intRewardIncome,     "Reward ("     .. intRewardIncome..")")})); --ceiling = round up for reward

		--if flag to block receiving card pieces @ end of turn is set, retract the card pieces that were given (revert card pieces & wholecards to the snapshot state)
		if (incomeAdjustments.BlockCardPieceReceiving == true) then processCardRetractions (game, addOrder, ID); end
	end

	publicGameData.PRdataByTurn[turnNumber].TerritoryCount = historicalTerritoryCount; --store Captures for this turn; this is easily retrievable by turn#, then by playerID
	-- print ("htc count "..#historicalTerritoryCount);
	Mod.PublicGameData = publicGameData;

	--crashNow ();
	print ("[S_AT_E] END");
end

--retract cards given at end of turn to player represented by playerID
function processCardRetractions (game, addOrder, playerID)
	-- local playerCards = WL.PlayerCards.Create(1058239);
	-- addOrder (WL.GameOrderEvent.Create (1058239, "Card retract!", {}, {}, {}, {WL.IncomeMod.Create(ID, intPunishmentIncome, "Punishment (" .. intPunishmentIncome..")")})); --floor = round down for punishment

	if (tablelength (Cards) == 0) then print ("\n\n\n\n[CARDS == {}]"); return; end

	--retract the cards received at end of this turn for playerID; this is done by reverting to the state for # of whole cards and # of card pieces for each card type for this player
	--NOTE: card pieces are given at end of turn, b/c card pieces convert into whole cards when the appropriate # of pieces are collected, it's possible for the # of card pieces for a given card reduces after card pieces are granted (if it makes a new whole card)
	--thus may actually need to add card pieces in order to revert to the previous count; conversely, whole cards can only ever go up by receiving card pieces so it is always a matter of removing them
	--HOWEVER:
		--(1) CARD PIECES - card pieces are removed by AddCardPiecesOpt property of a GameOrderEvent with parameter of a table in a tablet that permits multple player submissions and multiple associations per player to many card types and piece counts,
			--and thus all card pieces for all card types can be removed in a single GameOrderEvent order
		--(2) WHOLE CARDS - whole cards are removed by the RemoveWholeCardsOpt property of a GameOrderEvent with parameter of a flat table that while still permitting multiple player submissions, only permits 1 card type association to each playerID,
			--thus only 1 card type per playerID can be removed per GameOrderEvent, and multiple orders are required to remove multiple cards from a single player
	--THUS the code below identifies how many card pieces need to be added/removed in order to revert to prior state and save that in a single table to be able to remove them all in a single order, but needs to submit a new order for each whole card to be removed;
	--the 1st removal order removes all the card pieces and the 1st whole card, and if there are any additional whole cards to be removed, continues removing those with additional orders but no further card piece removals
	-- for playerID,playerCards in pairs (game.ServerGame.LatestTurnStanding.Cards) do --for each element table of player,PlayerCards
print (tostring (playerID));
	local playerCards = game.ServerGame.LatestTurnStanding.Cards [playerID];

		--identify all card pieces required to be removed/added in order to revert to prior counts
		local cardPiecesToRemove = {};
		for cardPieceCardID,cardPieceCount in pairs (playerCards.Pieces) do
			if (Cards[playerID].Pieces[cardPieceCardID] == nil) then Cards[playerID].Pieces[cardPieceCardID] = 0; end;
			-- print ("@@@@@ "..playerID,tostring (Cards[playerID].Pieces[cardPieceCardID]), tostring (cardPieceCount));
			if (Cards[playerID].Pieces[cardPieceCardID] - cardPieceCount ~= 0) then
				if (cardPiecesToRemove [playerID] == nil) then cardPiecesToRemove [playerID] = {}; end
				if (cardPiecesToRemove [playerID][cardPieceCardID] == nil) then cardPiecesToRemove [playerID][cardPieceCardID] = {}; end
				cardPiecesToRemove [playerID][cardPieceCardID] = Cards[playerID].Pieces[cardPieceCardID] - cardPieceCount;
			end
			-- print ("[^^PIECES] "..playerID,cardPieceCardID,cardPieceCount,Cards[playerID].Pieces[cardPieceCardID]-cardPieceCount, tostring (Cards[playerID].Pieces[cardPieceCardID]-cardPieceCount~=0));
		end

		--identify which whole cards to be removed in order to revert to prior counts
		local numWholeCards = {};
		-- local wholeCardsToRemove = {};
		for _,vc in pairs (playerCards.WholeCards) do
			if (numWholeCards[vc.CardID] == nil) then numWholeCards[vc.CardID] = 0; end
			numWholeCards [vc.CardID] = numWholeCards[vc.CardID] + 1;
			if (Cards[playerID].WholeCards[vc.CardID] == nil) then Cards[playerID].WholeCards[vc.CardID] = 0; end --if there were no wholecards of this card type in the prior state, this element won't exist; create it and set it to 0 so we can do comparisons with it below
			-- if (numWholeCards[vc.CardID] > Cards[playerID].WholeCards[vc.CardID]) then wholeCardsToRemove [playerID] = vc.ID; end
			-- if wholeCardsToRemove[playerID] == nil then wholeCardsToRemove[playerID] = {}; end -- Initialize list for player
			-- table.insert(wholeCardsToRemove[playerID], vc.ID);
			-- wholeCardsToRemove[playerID] = vc.ID;
			-- if (numWholeCards[vc.CardID] > Cards[playerID].WholeCards[vc.CardID]) then
			-- 	if wholeCardsToRemove[playerID] == nil then wholeCardsToRemove[playerID] = {}; end  -- create list for this player
			-- 	table.insert(wholeCardsToRemove[playerID], vc.ID); --add the card ID
			-- end

			-- print ("[^^CARDS] "..playerID,vc.CardID,vc.ID,numWholeCards[vc.CardID],Cards[playerID].WholeCards[vc.CardID],tostring (numWholeCards[vc.CardID]>Cards[playerID].WholeCards[vc.CardID]));

			--if the quantity of whole cards of current card type (vc.CardID) exceeds the count from prior state, remove it
			if (numWholeCards[vc.CardID] > Cards[playerID].WholeCards[vc.CardID]) then
				--submit the order remove card pieces (if any remain at this stage) & the current whole card identified
				-- print ("[^^WHOLECARD TO RETRACT] ",playerID,vc.CardID);
				local cardRetractionOrder = WL.GameOrderEvent.Create (playerID, "Punishment - card pieces retracted", {});

				--if card pieces need to be removed, configure the AddCardPiecesOpt property
				if (tablelength (cardPiecesToRemove) > 0) then cardRetractionOrder.AddCardPiecesOpt = cardPiecesToRemove; end

				--configure the RemoveWholeCardsOpt parameter for the Event order, then add the order to remove card pieces (if any) & the current whole card
				cardRetractionOrder.RemoveWholeCardsOpt = {[playerID] = vc.ID};
				addOrder (cardRetractionOrder, false);
				cardPiecesToRemove = {}; --clear cardPiecesToRemove so it doesn't keep adding/removing them with each iteration through the loop to process whole cards
			end
		end

		--it's possible at this point that there are card pieces to remove still b/c there were no whole cards, and removal orders were submitted; if so, remove them here
		if (tablelength (cardPiecesToRemove) > 0) then
			local cardRetractionOrder = WL.GameOrderEvent.Create (playerID, "Card retract!", {});
			cardRetractionOrder.AddCardPiecesOpt = cardPiecesToRemove;
			addOrder (cardRetractionOrder, false);
			cardPiecesToRemove = {}; --clear cardPiecesToRemove so it doesn't keep adding/removing them with each iteration through the loop to process whole cards
		end
	-- end
end

--remove nil elements, set them to 0
function cleanElements (arrayToClean)
print ("PRE  CLEAN count ".. tablelength (arrayToClean));
	for k,v in pairs (arrayToClean) do
print ("PRE  CLEAN "..k, tostring (arrayToClean[k]));
		if arrayToClean[k]==nil then arrayToClean[k] = 0; end
print ("POST CLEAN "..k, tostring (arrayToClean[k]));
	end
	return arrayToClean;
end

function territoryCountAnalysis (game)
	local territoryCount = {};
	for ID,terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
		if (terr.OwnerPlayerID>0) then
			if (territoryCount [terr.OwnerPlayerID] == nil) then territoryCount [terr.OwnerPlayerID] = 0; end
			territoryCount [terr.OwnerPlayerID] = territoryCount [terr.OwnerPlayerID] + 1;
			-- print ("playerID "..terr.OwnerPlayerID..", terr "..ID.."/"..getTerritoryName (ID, game)..", count "..territoryCount [terr.OwnerPlayerID]);
		end
	end
	return territoryCount;
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	return (game.Map.Territories[intTerrID].Name);
end

function Server_AdvanceTurn_Order(game,order,result,skip,addOrder)
	local playerID = order.PlayerID;
	-- if (order.proxyType~='GameOrderAttackTransfer') then
	-- 	if (order.proxyType ~= 'GameOrderEvent' or order.Message ~= "Mod skipped attack/transfer order") then
	-- 		print ("[ORDER]proxyType=="..order.proxyType.. ", player ".. order.PlayerID); --.. "; ".. tostring (order.Message));
	-- 	-- elseif (order.proxyType ~= 'GameOrderEvent') then
	-- 	-- 	print ("[E]proxyType=="..order.proxyType.. ", player ".. order.PlayerID.. "; ".. tostring (order.Message));
	-- 	end
	-- end

	-- if (order.proxyType=='GameOrderEvent') then skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); return; end

	if (order.proxyType=='GameOrderAttackTransfer') then
		--AttackTeammates boolean:, AttackTransfer AttackTransferEnum (enum):, ByPercent boolean:, From TerritoryID:, NumArmies Armies:, Result GameOrderAttackTransferResult:, To TerritoryID:
		--Result = ActualArmies Armies: The number of armies from the source territory that actually participated in the attack or transfer, AttackingArmiesKilled Armies:, DamageToSpecialUnits Table<Guid,integer>:, DefendingArmiesKilled Armies:, DefenseLuck Nullable<number>:, 
		--         IsAttack boolean: True if this was an attack, false if it was a transfer., IsNullified boolean:, IsSuccessful boolean: If IsAttack is true and IsSuccessful is true, the territory was captured. If IsAttack is true and IsSuccessful was false, the territory was not captured.
		--         OffenseLuck Nullable<number>:

		-- temp only; skip AI orders
		if (order.PlayerID<50) then skip(WL.ModOrderControl.Skip); return; end

		-- print ("[ATTACK/TRANSFER] PRE  from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
		-- ", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");


		--track when a player has made an attack or capture
		if (result.IsAttack) then Attacks[playerID] = 1; end
		if (result.IsAttack and result.IsSuccessful) then Captures[playerID] = 1; end

		--&&& TODO: track damage done, in terms of # armies killed & amount of damage done to SUs (reduced health amount + damage-required-to-kill for killed SUs w/o health)

		-- print ("[ATTACK/TRANSFER] POST from "..order.From.."/"..getTerritoryName(order.From, game).." to "..order.To.."/"..getTerritoryName(order.To,game)..", numArmies "..order.NumArmies.NumArmies ..", actualArmies "..result.ActualArmies.NumArmies.. ", isAttack "..tostring(result.IsAttack)..
		-- ", AttackingArmiesKilled "..result.AttackingArmiesKilled.NumArmies.. ", DefendArmiesKilled "..result.DefendingArmiesKilled.NumArmies..", isSuccessful "..tostring(result.IsSuccessful).."::");

	elseif (order.proxyType == 'GameOrderEvent') then
		-- print ("[EVENT] " ..order.Message);
		-- if (order.Message ~= "Mod skipped attack/transfer order") then print ("[EVENT] " ..order.Message); end
		-- if (order.AddCardPiecesOpt ~= nil) then print ("[-----Event order w/card pieces modification]"); end
		-- if (order.Result.CardInstancesCreated ~= nil) then print ("[-----CardInstancesCreated card pieces]"); end
	elseif (order.proxyType == 'GameOrderPlayCardSanctions') then
		print ("[Sanction card] cast "..order.PlayerID..", target "..order.SanctionedPlayerID..", strength "..game.Settings.Cards[WL.CardID.Sanctions].Percentage);
		--print ("[game.Settings.Cards[WL.CardID.Sanctions] "..WL.CardID.Sanctions);
		--printObjectDetails (game.Settings.Cards[WL.CardID.Sanctions], "WL.CardGameSanctions", "WZ def obj");
		--for k,v in pairs(WL.CardGameSanctions) do print ("**"..k,v); end
		--printObjectDetails (order, "Sanction cards", "played card");
		--printObjectDetails (game.Settings.Cards[WL.CardID.Sanctions], "Sanction config", "Card settings");
		if (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage>=0 and disallowNormalSanctionsOnSelf) then --self-sanction for +ve sanction; skip if disallowed
			print ("[Sanction card] self-sanction for +ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanction self with positive sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		elseif (order.PlayerID == order.SanctionedPlayerID and game.Settings.Cards[WL.CardID.Sanctions].Percentage<0 and disallowReverseSanctionsOnOthers) then --sanction on another for -ve sanction; skip if disallowed
			print ("[Sanction card] sanction on another for -ve sanction SKIP");
			addOrder(WL.GameOrderEvent.Create(order.PlayerID, "Sanctioning others with reverse sanctions is disallowed - Skipping order", {}, {},{}));
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		else
			print ("[Sanction card] permitted sanction type");
		end
	elseif (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, "PunishReward|Capture card state")) then
		--this order gets submitted in Client_GameCommit by each client player; this is necessary b/c only client hooks can apply a Turn Phase to a GameOrderCustom order; when server hooks use addOrder, it's always the immediate next order processed
		--thus must be done in Client hook in order to specify execution in Receive Cards phase to ensure all player orders (which can add/remove cards) are complete and the snapshot of the wholecards & card pieces for before/after comparison can be taken
		--process the first of these orders that is received and skip/suppress the rest
		if (boolCardsCaptured == false) then
			--process the first order received
			captureCardCounts (game); --capture card state at this time (before new cards are received for attacks made this turn)
			--skip/suppress this order? so players don't see this
			--leave it for now at least; to ensure the placement is optimal
		else
			--skip/suppress the order so players don't see this; this isn't the 1st order so the snapshot has already been taken, don't keep retaking it
			-- skip (WL.ModOrderControl.Skip); --skip this order & suppress the order in order history
			skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --skip this order & suppress the order in order history
		end
	else
		--any other proxyTypes to worry about?
	end
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Helper function to convert a table to a string representation
local function tableToString(tbl, indent)
	if type(tbl) ~= "table" then
		return tostring(tbl)  -- Return the value as-is if it's not a table
	end
	indent = indent or ""  -- Indentation for nested tables
	indent = "";
	local result = "{" --"{\n"
	for k, v in pairs(tbl) do
		result = result .. indent .. "  " .. tostring(k) .. " = " .. tableToString(v, indent .. "  ") .. ","; --\n"
	end
	result = result .. indent .. "}"
	return result
end

-- Main function to print object details
function printObjectDetails(object, strObjectName, strLocationHeader)
	strObjectName = strObjectName or ""  -- Default blank value if not provided
	strLocationHeader = strLocationHeader or ""  -- Default blank value if not provided
	print("[" .. strLocationHeader .. "] object=" .. strObjectName .. ", tablelength==".. tablelength (object).."::");
	print("[proactive display attempt] value==" .. tostring(object));

	-- Early return if object is nil or an empty table
	if object == nil then
		print("[invalid/empty object] object==nil")
		return
	elseif type(object) == "table" and next(object) == nil then
		print("[invalid/empty object] object=={}  [empty table]")
		return
	end

	-- Handle tables
	if type(object) == "table" then
		-- Check and display readableKeys
		if object.readableKeys then
			for key, value in pairs(object.readableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [readablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
				else
					print("  [readablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[R]**readableKeys DNE")
		end

		-- Check and display writableKeys
		if object.writableKeys then
			for key, value in pairs(object.writableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [writablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
				else
					print("  [writablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[W]**writableKeys DNE")
		end

		-- Display all base properties of the table
		for key, value in pairs(object) do
			if key ~= "readableKeys" and key ~= "writableKeys" then  -- Skip already processed keys
				if type(value) == "table" then
					print("[base_table] key==" .. tostring(key) .. ":: value==" .. tableToString(value))
				else
					print("[base_value] key==" .. tostring(key) .. ":: value==" .. tostring(value))
				end
			end
		end
	else
		-- Handle non-table objects
		print("[not table] value==" .. tostring(object))
	end
end