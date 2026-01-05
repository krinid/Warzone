function Client_PresentConfigureUI(rootParent)
	local vert = UI.CreateVerticalLayoutGroup(rootParent);

	local intTaxStartAmount = Mod.Settings.TaxStartAmount or 0.0; --the % of carryover gold that isn't taxed, can be freely carried over to the following turn; default is 0.0 if not defined already
	local intTaxRate = Mod.Settings.TaxRate or 0.1; --the % tax rate for gold carried over; default is 0.1 if not defined already

	local rowNonTaxableAmount = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(rowNonTaxableAmount).SetText('Non-taxable amount (%): ').SetPreferredWidth(290).SetColor ("#FFFF00");;
    NonTaxableAmount = UI.CreateNumberInputField(rowNonTaxableAmount).SetSliderMinValue(0).SetSliderMaxValue(100).SetWholeNumbers (false).SetValue(intTaxStartAmount*100).SetPreferredWidth(290);
	UI.CreateLabel (vert).SetText ("  (up to this amount of a player's income [not gold in hand] can be carried forward without being taxed; if gold in hand exceeds this amount, minimum 1 gold tax applies");

	local rowTaxRate = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(rowTaxRate).SetText('Tax rate (%): ').SetPreferredWidth(290).SetColor ("#FFFF00");;
    TaxRate = UI.CreateNumberInputField(rowTaxRate).SetSliderMinValue(0).SetSliderMaxValue(100).SetWholeNumbers (false).SetValue(intTaxRate*100).SetPreferredWidth(290);
	UI.CreateLabel (vert).SetText ("  (players will lose this amount of their unspent gold at the end of turn; if above non-taxable amount, minimum 1 gold tax applies)");

	UI.CreateLabel (vert).SetText ("\nExamples:\n• Non-taxable amount 50%, Tax rate 25%, Income 20, Gold in hand 30 --> 5 gold tax applied [(30 - (20 * 0.5)) * 0.25]");
	UI.CreateLabel (vert).SetText ("• Non-taxable amount 0%, Tax rate 50%, Gold in hand 30 --> 15 gold tax applied [(30 * 0.5]");
	UI.CreateLabel (vert).SetText ("• Non-taxable amount 200%, Tax rate 50%, Income 20, Gold in hand 60 --> 10 gold tax applied [(60 - (20 * 2.0)) * 0.50]");
end