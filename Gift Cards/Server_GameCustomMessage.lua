function Server_GameCustomMessage(game,playerID,payload,setReturn)
	--this mod only uses 1 GameCustomMessage, from Client_PresentMenuUI with parameter of the new PublicGameData table containing updated card prices
	--all that's required is save the incoming payload to PublicGameData
	--local publicGameData = Mod.PublicGameData;
	local publicGameData = payload;
	--publicGameData.CardData.DefinedCards = payload;
	Mod.PublicGameData = publicGameData;
	--Mod.PublicGameData.CardData.DefinedCards = payload;
	for k,v in pairs (Mod.PublicGameData.CardData.DefinedCards) do
		print ("updated card "..k.."/"..v.Name.." to price ".. v.Price.."::");
	end
end