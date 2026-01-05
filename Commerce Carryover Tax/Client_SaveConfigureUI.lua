function Client_SaveConfigureUI (alert, addCard)
	Mod.Settings.TaxStartAmount = math.max (0, NonTaxableAmount.GetValue()/100); --ensure value is >= 0
	Mod.Settings.TaxRate = math.max (0, TaxRate.GetValue()/100); --ensure value is >= 0
end