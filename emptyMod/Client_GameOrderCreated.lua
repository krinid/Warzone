--do nothing

function Client_GameOrderCreated (game, gameOrder, skip)
	--do nothing
	UI.Alert ("[GOC2] hello "..gameOrder.PlayerID);
	print ("GOC so far so good");
    local publicGameData = Mod.PublicGameData;
end