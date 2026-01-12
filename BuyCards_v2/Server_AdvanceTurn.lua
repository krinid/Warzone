function Server_AdvanceTurn_End (game, addOrder)
	--publicGameData.CardData.HostHasAdjustedPricing will change to True when host updates card prices
	--set publicGameData.CardData.CardPricesFinalized to True when host updates pricing and the Server_TurnAdvance_Start executes; if not finalized by end of T1, prices will be automatically finalized
	--disallow players including host to buy cards until prices are finalized
	local publicGameData = Mod.PublicGameData;

	print ("[S_AT_E] PRE check :: HostHasAdjustedPricing=="..tostring (Mod.PublicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (Mod.PublicGameData.CardData.CardPricesFinalized).."::");
	if (publicGameData.CardData.CardPricesFinalized == false) then
		if (publicGameData.CardData.HostHasAdjustedPricing == true) then
			publicGameData.CardData.CardPricesFinalized = true;
			if (publicGameData.PricesFinalizedMessageAlreadyDisplayed == nil) then
				addOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Game host has finalized card prices", {}, {},{}));
				publicGameData.PricesFinalizedMessageAlreadyDisplayed = true; --flag it so it doesn't redisplay each turn
			end
		else
			--auto-finalize card prices at their default values
			addOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Finalizing card prices at default values in lieu of host setting custom values", {}, {},{}));
			publicGameData.CardData.CardPricesFinalized = true;
		end
	end

	--if any card types were purchased, copy the new price increase counts back to the main array (to be committed to PublicGameData after the loop)
	--can't just use the values in arrIntNewValues_NumCardPriceIncreases b/c it only contains the entries for cards which were purchased this turn and excludes the values for cards not purchased this turn
	for k,v in pairs (arrIntNewValues_NumCardPriceIncreases) do
		arrIntNumCardPriceIncreases[k] = v;
	end
	publicGameData.NumCardPriceIncreases = arrIntNumCardPriceIncreases;
	print ("[TURNEND CARD CHECK] goes here; count  " ..count (arrIntNumCardPriceIncreases));
	for k,v in pairs (arrIntNumCardPriceIncreases) do
		print ("[TURNEND CARD CHECK] CardID " ..k.. ", #increases " ..v.. ", #purchased " ..tostring (arrIntNumCardsPurchased[k]));
	end

	publicGameData.NumCardPriceIncreases = arrIntNumCardPriceIncreases;
	publicGameData.NumCardsPurchased = arrIntNumCardsPurchased;
	Mod.PublicGameData = publicGameData; --save updated values
    print ("[S_AT_E] POST check :: HostHasAdjustedPricing=="..tostring (Mod.PublicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (Mod.PublicGameData.CardData.CardPricesFinalized).."::");

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	if (boolHaltCodeExecutionAtEndofTurn==true) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Start(game, addOrder)
	print ("[S_AT_S BEGIN]");
	--define these variables here with global scope so they are usable in all functions; grab host configured values if defined
	--each array is non-contiguous, element # is the cardID
	arrIntNumCardPriceIncreases = Mod.PublicGameData.NumCardPriceIncreases or {}; --# of card increases for each card = # of turns where a player has bought that card type; don't update this mid-turn else prices will increase for all users which gets hard to predict, orders may fail, etc
	arrIntNewValues_NumCardPriceIncreases = {}; --track price increases here and update the original record @ end of turn so results are fixed fur the duration of the current turn
	arrIntNumCardsPurchased = Mod.PublicGameData.NumCardsPurchased or {}; --running count of total cards of each type purchased by all players
	arrBoolCardWasPurchasedThisTurn = {}; --flag to indicate if a given card type was purchased this turn by any player

	--if card prices have been finalized, add an order indicating this
	if (Mod.PublicGameData.CardData.CardPricesFinalized == true) then
		--don't declare variable as local, leave it global so this message can be displayed only once
		if (Mod.PublicGameData.PricesFinalizedMessageAlreadyDisplayed == nil) then
			addOrder (WL.GameOrderEvent.Create (WL.PlayerID.Neutral, "Game host has finalized card prices", {}, {},{}));
			local publicGameData = Mod.PublicGameData;
			publicGameData.PricesFinalizedMessageAlreadyDisplayed = true; --flag it so it doesn't redisplay each turn
			Mod.PublicGameData = publicGameData; --save updated values
		end
	end
	print ("[S_AT_S END]");
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addOrder)
	local publicGameData = Mod.PublicGameData;

	if (order.proxyType == "GameOrderCustom" and startsWith(order.Payload, 'Buy Cards|')) then  --look for the order that we inserted in Client_PresentCommercePurchaseUI
		--if order is GameOrderCustom & Payload indicates "Buy Cards", then process the buy card order, else do nothing (it's some other custom order by some other mod)
		print ("payload=="..order.Payload..", message=="..order.Message.."::");

		local arrayPayload = split (order.Payload, "|");
		local customOrderType = arrayPayload[1];
		local cardID = tonumber(arrayPayload[2]);
		local pricePaid = tonumber(arrayPayload[3]);

		print ("customOrderType=="..tostring(customOrderType)..", card=="..tostring(cardID).."::");

		--local publicGameData = Mod.PublicGameData;
		local cardRecord = Mod.PublicGameData.CardData.DefinedCards [cardID];
		local cardObject = game.Settings.Cards[cardID];
		local strCardName = getCardName_fromObject (cardObject);
		local intNumCardPieceIncreases = arrIntNumCardPriceIncreases[cardID] or 0;
		local intNumCardsPurchased = arrIntNumCardsPurchased[cardID] or 0;
		local intMaxBuyableCards = Mod.Settings.MaxBuyableCards or -1; --# of each card that can be bought; -1 = unlimited; default is -1
		local intCostIncreaseRate = Mod.Settings.CostIncreaseRate or 0.1; --the ratio that the price of each card increases after a turn passes where a card was purchased, or within the same turn when 1 player buys >1 of the same type of card
		local intActualCardPrice = math.floor (cardRecord.Price * (1 + (intNumCardPieceIncreases * intCostIncreaseRate)) + 0.5);

		print ("customOrderType=="..customOrderType..", card=="..cardID.."/"..strCardName ..", base price=="..cardRecord.Price..", actual price=="..intActualCardPrice..", numCardsPurchased=="..intNumCardsPurchased..", maxBuyableCards=="..intMaxBuyableCards);
		if (customOrderType == "Buy Cards") then
			-- print ("________buy card "..cardID.."/");--..game.Settings.Cards[cardID].Name .. "/ price=="..cardRecord.Price..", price paid==");--..order.CostOpt[WL.ResourceType.Gold].."::");
			-- print ("________buy card "..cardID.."/"..strCardName .. "/ price=="..cardRecord.Price..", price paid=="..pricePaid.."::");

			---- NOTE :: check PRICE PAID, if not cost to buy card, client tempering was done, SKIP THE ORDER !!
			if (intMaxBuyableCards ~= -1 and intNumCardsPurchased >= intMaxBuyableCards) then -- -1 indicates unlimited
				--max # of cards has already been purchased, cancel the purchase
				--player doesn't have enough gold to afford the card purchase, so cancel it
				local strCardLimitExceeded = "Card purchase '" ..strCardName.. "' canceled; already at purchase limit (" ..tostring (intMaxBuyableCards).. ")";
				print (strCardLimitExceeded);
				addOrder (WL.GameOrderEvent.Create(order.PlayerID, strCardLimitExceeded, {}, {},{}));
				skipThisOrder(WL.ModOrderControl.Skip);
				return;
			elseif (pricePaid < intActualCardPrice) then
				-- local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering. Skipping order to buy "..strCardName;
				local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is " ..intActualCardPrice.. " - evidence of client side tampering. Skipping order to buy "..strCardName;
				print (strClientTampering);
				addOrder (WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
				skipThisOrder(WL.ModOrderControl.Skip);
				return;
			elseif (pricePaid > intActualCardPrice) then
				-- local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering but as price paid was too much and not too little, will not skip order to buy "..strCardName;
				local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..intActualCardPrice.." - evidence of client side tampering but as price paid was too much and not too little, will not skip order to buy "..strCardName;
				print (strClientTampering);
				addOrder (WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
				--skipThisOrder(WL.ModOrderControl.Skip);
			end

			local numCardPieces = game.Settings.Cards[cardID].NumPieces;
			local event = WL.GameOrderEvent.Create (order.PlayerID, order.Message, {});
			event.AddCardPiecesOpt = {[order.PlayerID] = {[cardID] = numCardPieces}};
			event.AddResourceOpt = {[order.PlayerID] = {-pricePaid}}; --Table<PlayerID,Table<ResourceType (enum),integer>>

			--increase counter indicating # of turns this card was purchased on if this is the 1st purchase of this card type this turn
			--only increase the cost of each card type once per turn;
			if (arrBoolCardWasPurchasedThisTurn [cardID] == nil) then
				arrBoolCardWasPurchasedThisTurn [cardID] = true; --flag that this card type was purchased this turn by at least 1 player so the price can be increased at end of turn
				arrIntNewValues_NumCardPriceIncreases [cardID] = (arrIntNumCardPriceIncreases[cardID] or 0) + 1;
			end
			print ("[BUY CARD] " ..cardID,pricePaid,arrIntNewValues_NumCardPriceIncreases [cardID],arrIntNumCardsPurchased [cardID]);
			arrIntNumCardsPurchased [cardID] = intNumCardsPurchased + 1;
			print ("[TURNEND CARD CHECK] goes here; count  " ..count (arrIntNumCardPriceIncreases));
			addOrder(event);
			skipThisOrder (WL.ModOrderControl.SkipAndSupressSkippedMessage); --already added a custom order that adds card pieces, so don't need this order that is just a text notification (it would just dupe)
		end
	end
end

function getCardName_fromObject(cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
	if cardConfig.proxyType == 'CardGameCustom' then
		return cardConfig.Name;
	end

	if cardConfig.proxyType == 'CardGameAbandon' then
		-- Abandon card was the original name of the Emergency Blockade card
		return 'Emergency Blockade card';
	end
	return cardConfig.proxyType:match("^CardGame(.*)");
end

function split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

--make a new copy of an array by copying each element; necessary b/c Lua copies arrays by reference not value
function copyArray (orig)
	local newArray = {};
	for k, v in pairs (orig) do
		newArray [k] = v;
	end
	return newArray;
end

function count(t, func)
	local c = 0;
	for _, v in pairs(t) do
		if func ~= nil then
			c = c + func(v);
		else
			c = c + 1;
		end
	end
	return c;
end