function Client_GameOrderCreated (game, gameOrder, skip)
	--check if an Airlift was entered, if so popup an alert to let player know it will occur at the end of a turn and not the beginning
	if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then
		UI.Alert ("[LATE AIRLIFTS]\n\nAirlifts occur at the END OF A TURN and not the beginning in this game. If you don't own the territory at that time, the airlift will not occur.");
	end
end