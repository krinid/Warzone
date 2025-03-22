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

	Mod.PublicGameData = publicGameData; --save updated values
    print ("[S_AT_E] POST check :: HostHasAdjustedPricing=="..tostring (Mod.PublicGameData.CardData.HostHasAdjustedPricing)..", CardPricesFinalized=="..tostring (Mod.PublicGameData.CardData.CardPricesFinalized).."::");

	--set to true to cause a "called nil" error to prevent the turn from moving forward and ruining the moves inputted into the game UI
	local boolHaltCodeExecutionAtEndofTurn = false;
	--local boolHaltCodeExecutionAtEndofTurn = true;
	if (boolHaltCodeExecutionAtEndofTurn==true) then endEverythingHereToHelpWithTesting(); ForNow(); end
end

function Server_AdvanceTurn_Start(game,addOrder)
	--if card prices have been finalized, add an order indicating this
	if (Mod.PublicGameData.CardData.CardPricesFinalized == true) then
		--don't declare variable as local, leave it global so this message can be displayed only once
		if (Mod.PublicGameData.PricesFinalizedMessageAlreadyDisplayed == nil) then
			addOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, "Game host has finalized card prices", {}, {},{}));
			local publicGameData = Mod.PublicGameData;
			publicGameData.PricesFinalizedMessageAlreadyDisplayed = true; --flag it so it doesn't redisplay each turn
			Mod.PublicGameData = publicGameData; --save updated values
		end
	end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addOrder)
	print ("[yoho] proxyType=="..order.proxyType);
	--OLD_Server_AdvanceTurn_Order_OLD (game, order, result, skipThisOrder, addNewOrder);
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

		print ("customOrderType=="..customOrderType..", card=="..cardID.."/"..strCardName);
		if (customOrderType == "Buy Cards") then
			print ("________buy card "..cardID.."/");--..game.Settings.Cards[cardID].Name .. "/ price=="..cardRecord.Price..", price paid==");--..order.CostOpt[WL.ResourceType.Gold].."::");
			print ("________buy card "..cardID.."/"..strCardName .. "/ price=="..cardRecord.Price..", price paid=="..pricePaid.."::");

			---- NOTE :: check PRICE PAID, if not cost to buy card, client tempering was done, SKIP THE ORDER !!
			if (pricePaid < cardRecord.Price) then
				local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering. Skipping order to buy "..strCardName;
				print (strClientTampering);
				addOrder(WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
				skipThisOrder(WL.ModOrderControl.Skip);
				return;
			elseif (pricePaid > cardRecord.Price) then
				local strClientTampering = "Price paid at turn input was "..pricePaid..", price of card is "..cardRecord.Price.." - evidence of client side tampering but as price paid was too much and not too little, will not skip order to buy "..strCardName;
				print (strClientTampering);
				addOrder(WL.GameOrderEvent.Create(order.PlayerID, strClientTampering, {}, {},{}));
				--skipThisOrder(WL.ModOrderControl.Skip);
			end 

			local numCardPieces = game.Settings.Cards[cardID].NumPieces;
			local event = WL.GameOrderEvent.Create (order.PlayerID, order.Message, {});
			event.AddCardPiecesOpt = {[order.PlayerID] = {[cardID] = numCardPieces}};
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