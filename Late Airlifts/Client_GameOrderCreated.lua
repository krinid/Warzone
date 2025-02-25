function Client_GameOrderCreated (game, gameOrder, skip)
	--check if an Airlift was entered, if so popup an alert to let player know it will occur at the end of a turn and not the beginning
	if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then
		UI.Alert ("[LATE AIRLIFTS]\n\nNote that this game uses the Late Airlifts mod which causes airlifts to execute at the end of a turn and not the beginning. If you don't own the territory at that time, the airlift will not occur.");
	end
end