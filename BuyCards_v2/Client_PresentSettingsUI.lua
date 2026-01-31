function Client_PresentSettingsUI(rootParent)
	local publicGameData = Mod.PublicGameData;
	UI.CreateLabel (rootParent).SetText ("Enables use of gold to purchase cards. Host configures which cards can be purchased among the standard and custom cards, and their respective prices.");
	UI.CreateLabel (rootParent).SetText ("• Max # of buyable cards: " ..tostring (Mod.Settings.MaxBuyableCards > 0 and Mod.Settings.MaxBuyableCards or "No limit"));
	UI.CreateLabel (rootParent).SetText ("    (limit applies to all players collectively, each player purchase reduces the remaining cards available to all players)");
	UI.CreateLabel (rootParent).SetText ("• Cost increase when purchased: " ..tostring ((Mod.Settings.CostIncreaseRate or 0.1) *100).. "%");
	UI.CreateLabel (rootParent).SetText ("    (when 1 or more cards of a given type are purchased, the price for that card goes up by this rate relative to the card's base cost on the following turn)");
	UI.CreateLabel (rootParent).SetText ("• See Buy Cards panel in Commerce menu for current card prices");
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd: " ..tostring (publicGameData));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD: " ..tostring (publicGameData.CardData));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.DC: " ..tostring (publicGameData.CardData.DefinedCards));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.CPF: " ..tostring (publicGameData.CardData.CardPricesFinalized));
	-- UI.CreateLabel (rootParent).SetText ("Data check pgd.CD.HHAP: " ..tostring (publicGameData.CardData.HostHasAdjustedPricing));

	-- for cardID, cardRecord in pairs (publicGameData.CardData.DefinedCards) do
	-- 	print (cardRecord.ID .."/" .. cardRecord.Name..", " ..cardRecord.Price);
	-- 	--for reference: publicGameData.CardData.DefinedCards [cardRecord.ID] = {Name=cardRecord.Name, Price=sliderCardPrices [cardCount].GetValue (), ID=cardID};
	-- end

	-- Mod.Settings.MaxBuyableCards = math.max (-1, MaxBuyableCards.GetValue()); --ensure value is -1 or >= 0; -1 = unlimited
	-- Mod.Settings.CostIncreaseRate = CostIncreaseRate.GetValue()/100; --value can be negative (gets cheaper), 0, or positive (gets more expensive)
end