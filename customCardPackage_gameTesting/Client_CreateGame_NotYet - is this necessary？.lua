function Client_CreateGame (settings, alert)
	if (settings.Cards[WL.CardID.Airlift] == nil) then alert ("Airlift cards must be enabled to function properly.\n\nIf you wish to use this mod, enable Airlift cards. Otherwise, disable this mod to proceed."); end
end