function Client_PresentSettingsUI(rootParent)
	local intTaxStartAmount = Mod.Settings.TaxStartAmount or 0.0; --the % of carryover gold that isn't taxed, can be freely carried over to the following turn; default is 0.0 if not defined already
	local intTaxRate = Mod.Settings.TaxRate or 0.1; --the % tax rate for gold carried over; default is 0.1 if not defined already

	--only show the Non-taxable amount section if there is a Non-taxable amount; if ==0, just skip it, no point in confusing players by declaring a 0% non-taxable amount
	if (intTaxStartAmount > 0) then
		UI.CreateLabel (rootParent).SetText ("\nNon-taxable amount: " ..tostring (intTaxStartAmount*100).."%").SetColor ("#FFFF00");
		UI.CreateLabel (rootParent).SetText ("  (up to this amount of a player's income [not gold in hand] can be carried forward without being taxed; if gold in hand exceeds this amount, minimum 1 gold tax applies)");
	end

	UI.CreateLabel (rootParent).SetText ("Commerce tax rate: " ..tostring (intTaxRate*100).."%").SetColor ("#FFFF00");
	UI.CreateLabel (rootParent).SetText ("  (players will lose this amount of their unspent gold at the end of turn)");

	-- UI.CreateLabel (vert).SetText ("\nExamples:\n• Income 20, Gold in hand 30 --> 5 gold tax applied [(30 - (20 * 0.5)) * 0.25]");
	-- UI.CreateLabel (vert).SetText ("• Income 20, Gold in hand 30 --> 15 gold tax applied [(30 * 0.5]");
	-- UI.CreateLabel (vert).SetText ("• Income 20, Gold in hand 60 --> 10 gold tax applied [(60 - (20 * 2.0)) * 0.50]");
end