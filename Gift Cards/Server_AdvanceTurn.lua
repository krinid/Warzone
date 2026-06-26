function Server_AdvanceTurn_End (game, addOrder)
	-- print ("[S_AT_E] PRE check :: HostHasAdjustedPricing=="..tostring (Mod.PublicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (Mod.PublicGameData.CardData.CardPricesFinalized).."::");
    -- print ("[S_AT_E] POST check :: HostHasAdjustedPricing=="..tostring (Mod.PublicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (Mod.PublicGameData.CardData.CardPricesFinalized).."::");

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	-- local boolHaltCodeExecutionAtEndofTurn = true;
	if (boolHaltCodeExecutionAtEndofTurn==true) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Start(game, addOrder)
	-- print ("[S_AT_S BEGIN]");
	-- print ("[S_AT_S END]");
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addOrder)
	local publicGameData = Mod.PublicGameData;

	if (order.proxyType == "GameOrderCustom" and startsWith (order.Payload, 'Gift Cards|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		--if order is GameOrderCustom & Payload indicates "Buy Cards", then process the buy card order, else do nothing (it's some other custom order by some other mod)
		print ("payload=="..order.Payload..", message=="..order.Message.."::");

		--ref: order format: "Gift Cards|targetPlayerID|card1name:NumWholeCards,NumCardPieces|card2name:NumWholeCards,NumCardPieces|..."
		--reference: order format is: 'Gift Cards|targetPlayerID|card1name:NumWholeCards,NumCardPieces|card2name:NumWholeCards,NumCardPieces|...'
		--arrayPayload[3] through arrayPayload[n] are the actual cards/pieces to be gifted

		local arrayPayload = split (order.Payload, "|");
		local customOrderType = arrayPayload[1];
		local targetPlayerID = tonumber(arrayPayload[2]);

		print ("[Gift Card] customOrderType=="..tostring(customOrderType)..", targetPlayerID=="..tostring(targetPlayerID).."::");
		local cardPiecesToRemove = {};
		local wholeCardsToRemove = {};
		local cardPiecesToGift = {};
		local cardRetractionOrder = WL.GameOrderEvent.Create (order.PlayerID, "cards/pieces removed", {});
		for i = 3, #arrayPayload do
			local arrGiftCardData = split (arrayPayload[i], ":");
			local cardID = arrGiftCardData[1];
			local arrCardWCPCcounts = split (arrGiftCardData[2], ","); --get WC wholeCard and CP cardPiece counts specified for this card type
			local intNumWholeCardsSpecified = tonumber(arrCardWCPCcounts[1]);
			local intNumCardPiecesSpecified = tonumber(arrCardWCPCcounts[2]);
			local intNumWholeCardsInHand = getWholeCardCount (game, order.PlayerID, cardID);
			local intNumCardPiecesInHand = getCardPieceCount (game, order.PlayerID, cardID);
			local intNumWholeCardsToGift = math.min (intNumWholeCardsSpecified, intNumWholeCardsInHand);
			local intNumCardPiecesToGift = math.min (intNumCardPiecesSpecified, intNumCardPiecesInHand);

			print ("  Card " ..tostring (cardID).. "/" ..getCardName_fromID (cardID, game).. ", WC " .. tostring (intNumWholeCardsSpecified) .. ", Pieces " .. tostring (intNumCardPiecesSpecified) .. ", WC in hand " .. tostring (intNumWholeCardsInHand) .. ", Pieces in hand " .. tostring (intNumCardPiecesInHand).. ", WC to gift " .. tostring (intNumWholeCardsToGift) .. ", Pieces to gift " .. tostring (intNumCardPiecesToGift));

			--if there are card pieces to be removed for the current card, add the removal to the retraction order
			if (intNumCardPiecesToGift > 0) then
				if (cardPiecesToRemove [order.PlayerID] == nil) then cardPiecesToRemove [order.PlayerID] = {}; end
				if (cardPiecesToRemove [order.PlayerID][cardID] == nil) then cardPiecesToRemove [order.PlayerID][cardID] = 0; end
				cardPiecesToRemove [order.PlayerID][cardID] = -intNumCardPiecesToGift;
				cardRetractionOrder.AddCardPiecesOpt = cardPiecesToRemove;

				if (cardPiecesToRemove [targetPlayerID] == nil) then cardPiecesToRemove [targetPlayerID] = {}; end
				if (cardPiecesToRemove [targetPlayerID][cardID] == nil) then cardPiecesToRemove [targetPlayerID][cardID] = 0; end
				cardPiecesToRemove [targetPlayerID][cardID] = cardPiecesToRemove [targetPlayerID][cardID] + intNumCardPiecesToGift;
				cardRetractionOrder.AddCardPiecesOpt = cardPiecesToRemove;

				-- if (cardPiecesToGift [targetPlayerID] == nil) then cardPiecesToGift [targetPlayerID] = {}; end
				-- if (cardPiecesToGift [targetPlayerID][cardID] == nil) then cardPiecesToGift [targetPlayerID][cardID] = 0; end
				-- cardPiecesToGift [targetPlayerID][cardID] = cardPiecesToGift [targetPlayerID][cardID] + intNumCardPiecesToGift;
				-- cardRetractionOrder.AddCardPiecesOpt = cardPiecesToGift;
			end

			--if there are wholecards to be removed for the current card type, add it to the whole card removal table to be processed later
			--&&&change this to a loop to add 1 element per whole card being gifted (multiple entries for each card, since each removal from gifting player must be a separate order)
			if (intNumWholeCardsToGift > 0) then
				for i = 1, intNumWholeCardsToGift do
					--&&& fix this -- this would just get the same instance each time through the loop and never discard the 2nd iteration and beyond
					local wholeCardCardInstanceID = getCardInstance (game, order.PlayerID, cardID);
					table.insert (wholeCardsToRemove, {[order.PlayerID] = wholeCardCardInstanceID});
					--add card pieces here
					-- if (cardPiecesToGift [targetPlayerID] == nil) then cardPiecesToGift [targetPlayerID] = {[cardID] = 0}; end
					cardPiecesToGift[targetPlayerID] = cardPiecesToGift[targetPlayerID] or {};
					cardPiecesToGift[targetPlayerID][cardID] = (cardPiecesToGift[targetPlayerID][cardID] or 0) + intNumCardPiecesToGift;
					-- if (cardPiecesToGift [targetPlayerID] == nil) then cardPiecesToGift [targetPlayerID] = {[cardID] = 0}; end
					cardPiecesToGift [targetPlayerID][cardID] = cardPiecesToGift [targetPlayerID][cardID] + intNumCardPiecesToGift;
					-- cardPiecesToGift [targetPlayerID].cardID = cardPiecesToGift [targetPlayerID].cardID + intNumCardPiecesToGift;
				end
			end
		end

		-- 	local numCardPieces = game.Settings.Cards[cardID].NumPieces;
		-- 	local event = WL.GameOrderEvent.Create (order.PlayerID, order.Message, {});
		-- 	event.AddCardPiecesOpt = {[order.PlayerID] = {[cardID] = numCardPieces}};
		-- 	event.AddResourceOpt = {[order.PlayerID] = {-pricePaid}}; --Table<PlayerID,Table<ResourceType (enum),integer>>

		print ("# wholecards to be removed: " ..#wholeCardsToRemove);
		if (#wholeCardsToRemove == 0) then
			addOrder (cardRetractionOrder, true);
		else
			for k,v in pairs (wholeCardsToRemove) do
				if (cardRetractionOrder == nil) then cardRetractionOrder = WL.GameOrderEvent.Create (order.PlayerID, "whole card removed", {}); end
				-- print ("[ORDER - CARD REMOVAL] playerID=="..k..", cardInstanceID=="..v[k]..", cardName==" ..getCardName_fromInstanceID (game, v[k]).."::");
				-- print ("[ORDER - CARD REMOVAL] playerID=="..k..", cardInstanceID=="..v[k]..", cardName==" ..getCardName_fromInstanceID (game, v[k]).."::");
				cardRetractionOrder.RemoveWholeCardsOpt = v;
				addOrder (cardRetractionOrder, true);
				cardRetractionOrder = nil;
			end
		end

		--local publicGameData = Mod.PublicGameData;
		-- local cardRecord = Mod.PublicGameData.CardData.DefinedCards [cardID];
		-- local cardObject = game.Settings.Cards[cardID];
		-- local strCardName = getCardName_fromObject (cardObject);
		-- local intNumCardPieceIncreases = arrIntNumCardPriceIncreases[cardID] or 0;
		-- local intNumCardsPurchased = arrIntNumCardsPurchased[cardID] or 0;
		-- local intMaxBuyableCards = Mod.Settings.MaxBuyableCards or -1; --# of each card that can be bought; -1 = unlimited; default is -1
		-- local intCostIncreaseRate = Mod.Settings.CostIncreaseRate or 0.0; --the ratio that the price of each card increases after a turn passes where a card was purchased, or within the same turn when 1 player buys >1 of the same type of card
		-- local intActualCardPrice = math.floor (cardRecord.Price * (1 + (intNumCardPieceIncreases * intCostIncreaseRate)) + 0.5);

		-- print ("customOrderType=="..customOrderType..", card=="..cardID.."/"..strCardName ..", base price=="..cardRecord.Price..", actual price=="..intActualCardPrice..", numCardsPurchased=="..intNumCardsPurchased..", maxBuyableCards=="..intMaxBuyableCards);
		-- if (customOrderType == "Buy Cards") then
		-- 	-- print ("________buy card "..cardID.."/");--..game.Settings.Cards[cardID].Name .. "/ price=="..cardRecord.Price..", price paid==");--..order.CostOpt[WL.ResourceType.Gold].."::");
		-- 	-- print ("________buy card "..cardID.."/"..strCardName .. "/ price=="..cardRecord.Price..", price paid=="..pricePaid.."::");

		-- 	---- NOTE :: check PRICE PAID, if not cost to buy card, client tempering was done, SKIP THE ORDER !!
		-- 	if (intMaxBuyableCards ~= -1 and intNumCardsPurchased >= intMaxBuyableCards) then -- -1 indicates unlimited
		-- 		--max # of cards has already been purchased, cancel the purchase
		-- 		--player doesn't have enough gold to afford the card purchase, so cancel it
		-- 		local strCardLimitExceeded = "Card purchase '" ..strCardName.. "' canceled; already at purchase limit (" ..tostring (intMaxBuyableCards).. ")";
		-- 		print (strCardLimitExceeded);
		-- 		addOrder (WL.GameOrderEvent.Create(order.PlayerID, strCardLimitExceeded, {}, {},{}));
		-- 		skipThisOrder(WL.ModOrderControl.Skip);
		-- 		return;
		-- 	elseif (pricePaid < intActualCardPrice) then
		-- 		-- local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering. Skipping order to buy "..strCardName;
		-- 		local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is " ..intActualCardPrice.. " - evidence of client side tampering. Skipping order to buy "..strCardName;
		-- 		print (strClientTampering);
		-- 		addOrder (WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
		-- 		skipThisOrder(WL.ModOrderControl.Skip);
		-- 		return;
		-- 	elseif (pricePaid > intActualCardPrice) then
		-- 		-- local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering but as price paid was too much and not too little, will not skip order to buy "..strCardName;
		-- 		local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..intActualCardPrice.." - evidence of client side tampering but as price paid was too much and not too little, will not skip order to buy "..strCardName;
		-- 		print (strClientTampering);
		-- 		addOrder (WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
		-- 		--skipThisOrder(WL.ModOrderControl.Skip);
		-- 	end

		-- 	local numCardPieces = game.Settings.Cards[cardID].NumPieces;
		-- 	local event = WL.GameOrderEvent.Create (order.PlayerID, order.Message, {});
		-- 	event.AddCardPiecesOpt = {[order.PlayerID] = {[cardID] = numCardPieces}};
		-- 	event.AddResourceOpt = {[order.PlayerID] = {-pricePaid}}; --Table<PlayerID,Table<ResourceType (enum),integer>>

		-- 	--increase counter indicating # of turns this card was purchased on if this is the 1st purchase of this card type this turn
		-- 	--only increase the cost of each card type once per turn;
		-- 	if (arrBoolCardWasPurchasedThisTurn [cardID] == nil) then
		-- 		arrBoolCardWasPurchasedThisTurn [cardID] = true; --flag that this card type was purchased this turn by at least 1 player so the price can be increased at end of turn
		-- 		arrIntNewValues_NumCardPriceIncreases [cardID] = (arrIntNumCardPriceIncreases[cardID] or 0) + 1;
		-- 	end
		-- 	print ("[BUY CARD] " ..cardID,pricePaid,arrIntNewValues_NumCardPriceIncreases [cardID],arrIntNumCardsPurchased [cardID]);
		-- 	arrIntNumCardsPurchased [cardID] = intNumCardsPurchased + 1;
		-- 	print ("[TURNEND CARD CHECK] goes here; count  " ..count (arrIntNumCardPriceIncreases));
		-- 	addOrder(event);
		-- 	skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --already added a custom order that adds card pieces, so don't need this order that is just a text notification (it would just dupe)
		-- end
	end
end

-- function getCardAndPieceCounts (game, playerID, cardID)
-- 	local intWholeCards = 0;
-- 	local intCardPieces = 0;
-- 	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards) do
-- 		if (v.CardID == cardID) then intWholeCards = intWholeCards + 1; end
-- 	end
-- 	for cardPieceCardID,cardPieceCount in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].Pieces) do
-- 		if (cardPieceCardID == cardID) then intCardPieces = cardPieceCount; end
-- 	end
-- 	return intWholeCards, intCardPieces;
-- end

function getCardName_fromObject (cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
	if cardConfig.proxyType == 'CardGameCustom' then
		return cardConfig.Name;
	end

	if cardConfig.proxyType == 'CardGameAbandon' then
		-- Abandon card was the original name of the Emergency Blockade card
		return 'Emergency Blockade card';
	end
	return cardConfig.proxyType:match ("^CardGame(.*)");
end

function getCardName_fromID (cardID, game);
	print ("cardID=="..cardID);
	local cardConfig = game.Settings.Cards [tonumber(cardID)];
	return getCardName_fromObject (cardConfig);
end

function split (inputstr, sep)
	if sep == nil then
			sep = "%s";
	end
	local t={} ; i=1
	for str in string.gmatch (inputstr, "([^"..sep.."]+)") do
			t[i] = str;
			i = i + 1;
	end
	return t;
end

function startsWith (str, sub)
	return string.sub (str, 1, string.len (sub)) == sub;
end

--make a new copy of an array by copying each element; necessary b/c Lua copies arrays by reference not value
function copyArray (orig)
	local newArray = {};
	for k, v in pairs (orig) do
		newArray [k] = v;
	end
	return newArray;
end

function count (t, func)
	local c = 0;
	for _, v in pairs (t) do
		if func ~= nil then
			c = c + func (v);
		else
			c = c + 1;
		end
	end
	return c;
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
			local cardRetractionOrder = WL.GameOrderEvent.Create (playerID, "Punishment: card pieces retracted", {});

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
end

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function getCardInstance (game, playerID, cardID)
	-- print ("player "..playerID);
	if (playerID==0) then --[[ print ("playerID is neutral (has no cards)"); ]] return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then --[[ print ("WHOLE CARDS nil"); ]] return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards) do
		if (v.CardID == cardID) then return k; end
	end
	return nil;
end

function getWholeCardCount (game, playerID, cardID)
	local intNumCards = 0;

	if (game.ServerGame.LatestTurnStanding.Cards [playerID] == nil) then return 0; end

	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards) do
		if (v.CardID == tonumber(cardID)) then intNumCards = intNumCards + 1; end
	end

	-- if (game.ServerGame.LatestTurnStanding.Cards [playerID] ~= nil and game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards ~= nil and game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards [cardID] ~= nil) then
	-- 	return game.ServerGame.LatestTurnStanding.Cards [playerID].WholeCards [cardID];
	-- end
	return (intNumCards);
end

function getCardPieceCount (game, playerID, cardID)
	local intNumPieces = 0;
	if (game.ServerGame.LatestTurnStanding.Cards [playerID] ~= nil and game.ServerGame.LatestTurnStanding.Cards [playerID].Pieces ~= nil and game.ServerGame.LatestTurnStanding.Cards [playerID].Pieces [cardID] ~= nil) then
		intNumPieces = game.ServerGame.LatestTurnStanding.Cards [playerID].Pieces [cardID];
	end
	return (intNumPieces);
end