--this is a fixed value right now, needs to be implemented into a host-configurable settings:
local intTaxRate = 0.1; --10% tax on gold carried over beyond 1x income level

function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel (rootParent).SetText ("Commerce tax rate: " ..tostring (intTaxRate*100).."%").SetColor ("#FFFF00");
	UI.CreateLabel (rootParent).SetText ("  (players will lose this amount of their unspent gold at the end of turn)");
end