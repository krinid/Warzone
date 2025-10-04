require ('Bomb+ common');

function Client_GameOrderCreated (game, gameOrder, skip)
    print ("[C_GOC] START");
	print ("[C_GOC] gameOrder proxyType=="..gameOrder.proxyType.."::");

	--display message to player if (A) Bomb card was played, (B) the new custom Bomb+ card isn't enabled in the game, which means this bomb play will be treated as a Bomb+ play
	--show the player what the effect will be in terms of damage and timing
	if (gameOrder.proxyType=='GameOrderPlayCardBomb' and Mod.Settings.UseCustomCard == nil) then
		UI.Alert ("The Bomb card you just played has the following properties:\n\n" ..get_BombPlus_description ());
	end
end