
function Client_SaveConfigureUI(alert)
	--[[if (game.Settings.CommerceGame == false) then
		alert("The 'Buy Cards v2' mod requires Commerce in order to function. Please enable Commerce game in game settings or unselect this mod.");
	end]] --would be nice to be able to do this but game doesn't exist yet! Can't access Settings of a game that hasn't been started yet

	Mod.Settings.MaxBuyableCards = math.max (-1, MaxBuyableCards.GetValue()); --ensure value is -1 or >= 0; -1 = unlimited
	Mod.Settings.CostIncreaseRate = CostIncreaseRate.GetValue()/100; --value can be negative (gets cheaper), 0, or positive (gets more expensive)

	--[[ Mod.Settings.ReinforcementCardCost = ReinforcementCardCostinput.GetValue();
	if(Mod.Settings.ReinforcementCardCost > 100000 or Mod.Settings.ReinforcementCardCost < 0)then
		alert("Reinforcement card cost is invalid");
	end
	Mod.Settings.GiftCardCost = GiftCardCostinput.GetValue();
	if(Mod.Settings.GiftCardCost > 100000 or Mod.Settings.GiftCardCost < 0)then
		alert("gift card cost is invalid");
	end
	Mod.Settings.SpyCardCost = SpyCardCostinput.GetValue();
	if(Mod.Settings.SpyCardCost > 100000 or Mod.Settings.SpyCardCost < 0)then
		alert("spy card cost is invalid");
	end
	Mod.Settings.EmergencyBlockadeCardCost = EmergencyBlockadeCardCostinput.GetValue();
	if(Mod.Settings.EmergencyBlockadeCardCost > 100000 or Mod.Settings.EmergencyBlockadeCardCost < 0)then
		alert("emergency blockard card cost is invalid");
	end
	Mod.Settings.BlockadeCardCost = BlockadeCardCostinput.GetValue();
	if(Mod.Settings.BlockadeCardCost > 100000 or Mod.Settings.BlockadeCardCost < 0)then
		alert("blockard card cost is invalid");
	end
	Mod.Settings.OrderPriorityCardCost = OrderPriorityCardCostinput.GetValue();
	if(Mod.Settings.OrderPriorityCardCost > 100000 or Mod.Settings.OrderPriorityCardCost < 0)then
		alert("order priority card cost is invalid");
	end
	Mod.Settings.OrderDelayCardCost = OrderDelayCardCostinput.GetValue();
	if(Mod.Settings.OrderDelayCardCost > 100000 or Mod.Settings.OrderDelayCardCost < 0)then
		alert("order delay card cost is invalid");
	end
	Mod.Settings.AirliftCardCost = AirliftCardCostinput.GetValue();
	if(Mod.Settings.AirliftCardCost > 100000 or Mod.Settings.AirliftCardCost < 0)then
		alert("airlift card cost is invalid");
	end
	Mod.Settings.DiplomacyCardCost = DiplomacyCardCostinput.GetValue();
	if(Mod.Settings.DiplomacyCardCost > 100000 or Mod.Settings.DiplomacyCardCost < 0)then
		alert("diplomacy card cost invalid");
	end
	Mod.Settings.SanctionsCardCost = SanctionsCardCostinput.GetValue();
	if(Mod.Settings.SanctionsCardCost > 100000 or Mod.Settings.SanctionsCardCost < 0)then
		alert("sanctions card cost invalid");
	end
	Mod.Settings.SurveillanceCardCost = SurveillanceCardCostinput.GetValue();
	if(Mod.Settings.SurveillanceCardCost > 100000 or Mod.Settings.SurveillanceCardCost < 0)then
		alert("surveillance card cost invalid");
	end
	Mod.Settings.ReconnaissanceCardCost = ReconnaissanceCardCostinput.GetValue();
	if(Mod.Settings.ReconnaissanceCardCost > 100000 or Mod.Settings.ReconnaissanceCardCost < 0)then
		alert("reconnaissance card cost invalid");
	end
	Mod.Settings.BombCardCost = BombCardCostinput.GetValue();
	if(Mod.Settings.BombCardCost > 100000 or Mod.Settings.BombCardCost < 0)then
		alert("bomb card cost invalid");
	end ]]
end