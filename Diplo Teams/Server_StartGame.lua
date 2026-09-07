function Server_StartGame (game, standing)
	local playerGameData = Mod.PlayerGameData;
	local publicGameData = Mod.PublicGameData;
	publicGameData.War = {}; --contains all ongoing War relationships

	for _, player1 in pairs (game.ServerGame.Game.Players) do
		--default values are no war, no peace offers for all players
		publicGameData.War [player1.ID] = {};
		playerGameData [player1.ID] = {};
		playerGameData [player1.ID].PeaceOffers = {};

		--if starting state is AT WAR, configure all players to be at war with one another
		if (Mod.Settings.WarStartState == "ATWAR") then
			for _,player2 in pairs (game.ServerGame.Game.Players) do
				if (player1.ID ~= player2.ID) then
					publicGameData.War [player1.ID][tablelength (publicGameData.War [player1.ID])+1] = player2.ID;
					playerGameData [player1.ID].HasNewWar = true;
					-- print ("[START GAME] set WAR " ..tostring (player1.ID) .." vs " ..tostring (player2.ID));
				end
			end
		end
	end

	Mod.PlayerGameData = playerGameData;
	Mod.PublicGameData = publicGameData;
end

function  tablelength (T)
	local count = 0;
	if (T==nil) then
		return 0;
	end
	for _, elem in pairs (T) do
		count = count + 1;
	end
	return count;
end