function Client_PresentConfigureUI(rootParent)
	rootParentobj = rootParent;
	
	ReinforcementCardCostinit = Mod.Settings.ReinforcementCardCost;
	if(ReinforcementCardCostinit == nil)then
		ReinforcementCardCostinit = 0;
	end
	GiftCardCostinit = Mod.Settings.GiftCardCost;
	if(GiftCardCostinit == nil)then
		GiftCardCostinit = 0;
	end
	SpyCardCostinit = Mod.Settings.SpyCardCost;
	if(SpyCardCostinit == nil)then
		SpyCardCostinit = 0;
	end
	EmergencyBlockadeCardCostinit = Mod.Settings.EmergencyBlockadeCardCost;
	if(EmergencyBlockadeCardCostinit == nil)then
		EmergencyBlockadeCardCostinit = 0;
	end
	BlockadeCardCostinit = Mod.Settings.BlockadeCardCost;
	if(BlockadeCardCostinit == nil)then
		BlockadeCardCostinit = 0;
	end
	OrderPriorityCardCostinit = Mod.Settings.OrderPriorityCardCost;
	if(OrderPriorityCardCostinit == nil)then
		OrderPriorityCardCostinit = 0;
	end
	print (OrderPriorityCardCostinit .. " " .. ReinforcementCardCostinit)
	OrderDelayCardCostinit = Mod.Settings.OrderDelayCardCost;
	if(OrderDelayCardCostinit == nil)then
		OrderDelayCardCostinit = 0;
	end
	AirliftCardCostinit = Mod.Settings.AirliftCardCost;
	if(AirliftCardCostinit == nil)then
		AirliftCardCostinit = 0;
	end
	DiplomacyCardCostinit = Mod.Settings.DiplomacyCardCost;
	if(DiplomacyCardCostinit == nil)then
		DiplomacyCardCostinit = 0;
	end
	SanctionsCardCostinit = Mod.Settings.SanctionsCardCost;
	if(SanctionsCardCostinit == nil)then
		SanctionsCardCostinit = 0;
	end
	ReconnaissanceCardCostinit = Mod.Settings.ReconnaissanceCardCost;
	if(ReconnaissanceCardCostinit == nil)then
		ReconnaissanceCardCostinit = 0;
	end
	SurveillanceCardCostinit = Mod.Settings.SurveillanceCardCost;
	if(SurveillanceCardCostinit == nil)then
		SurveillanceCardCostinit = 0;
	end
	BombCardCostinit = Mod.Settings.BombCardCost;
	if(BombCardCostinit == nil)then
		BombCardCostinit = 0;
	end
	ShowUI();
end
function ShowUI()

local maxvalue = 1000;

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj).SetFlexibleWidth (1);
	UI.CreateLabel(rootParentobj).SetText("- Set cost to 0 to make a card not purchasable\n- Cards must be enabled in the Cards section of the game settings to be usable in game; assigning a purchase price below but not enabling the card will cause the card to not be usable in the game\n");
	UI.CreateLabel(rootParentobj).SetText("- Regular cards (standard cards built into Warzone) can have prices assigned below, and you can finalize the costs once the game starts)");
	UI.CreateLabel(rootParentobj).SetText("- Custom cards must have their prices assigned after game starts via the Game/Mod: Buy Cards v2 menu - only the host can set the prices").SetColor("#FFFF00");
	UI.CreateLabel(rootParentobj).SetText("\nEnter the prices for the Regular Cards below:").SetColor ("#00CCCC");
	
	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Reinforcement Card:');
	ReinforcementCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(ReinforcementCardCostinit);

    horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Gift Card:');
	GiftCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(GiftCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Spy Card:');
	SpyCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(SpyCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Emergency Blockade Card:');
	EmergencyBlockadeCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(EmergencyBlockadeCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Blockade Card:');
	BlockadeCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(BlockadeCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Order Priority Card:');
	OrderPriorityCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(OrderPriorityCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Order Delay Card:');
	OrderDelayCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(OrderDelayCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Airlift Card:');
	AirliftCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(AirliftCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Diplomacy Card:');
	DiplomacyCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(DiplomacyCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Sanctions Card:');
	SanctionsCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(SanctionsCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Reconnaissance Card:');
	ReconnaissanceCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(ReconnaissanceCardCostinit);

	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Surveillance Card:');
	SurveillanceCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(SurveillanceCardCostinit);
	
	horz = UI.CreateHorizontalLayoutGroup(rootParentobj); --.SetPreferredWidth (301);
	UI.CreateLabel(horz).SetPreferredWidth(200).SetText('Bomb Card:');
	BombCardCostinput = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetPreferredWidth(50).SetSliderMaxValue(maxvalue).SetValue(BombCardCostinit);

end
