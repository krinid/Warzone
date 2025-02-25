function Client_GameOrderCreated (game, gameOrder, skip)
	--check if an Airlift was entered, if so popup an alert to let player know it will occur at the end of a turn and not the beginning
	if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then
		UI.Alert ("[LATE AIRLIFTS]\nAirlifts occur at the END OF A TURN (not the beginning) in this game.\n\nIf you no longer own the territory at that time, the airlift will not occur.");
	end
end