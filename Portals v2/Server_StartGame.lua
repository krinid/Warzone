function Server_StartGame (game, standing)
	local privateGameData = Mod.PrivateGameData

	--if manual distribution is used, this ran in Server_StartDistribution so the Portals were shown before picks were made, so don't regen the Portals
	--if auto-distribution is in play, then the Portals weren't created previously and need to be created now
	if (privateGameData.Portals ~= nil) then return; end

	print ("CREATE PORTAL @ Server_StartGame");

	privateGameData.Portals = {};
	territoryArray = {};

	local count = 1
	for _, territory in pairs (game.Map.Territories) do
		territoryArray [count] = territory;
		count = count + 1;
	end
	print ("# terrs " .. count);

	--check that the map has enough territories, else make the max number of portals supportable by current map = floor of # terrs/2
	local intNumPortals = Mod.Settings.NumPortals;
	if (#territoryArray < Mod.Settings.NumPortals * 2) then intNumPortals = math.floor (#territoryArray / 2); end

	--create array privateGameData.Portals where Portal pairs are privateGameData.Portals [i] and privateGameData.Portals [i+intNumPortals] for any portal #i
	for i = 1, intNumPortals do
		local strPortalFilename = "Portal"; --use name "Portal" is only one Portal, otherwise "Portal 1", "Portal 2", etc
		if (intNumPortals > 1) then print (i, math.ceil (i / 2)); strPortalFilename = strPortalFilename .. " " .. tostring (i); end
		local strPortalStructureID = WL.StructureType.Custom (strPortalFilename); --create new custom structure ID for Portal or retrieve the existing ID for it if it has been created already
		privateGameData.Portals [i] = getRandomTerritory (territoryArray); --set portal side 1
		privateGameData.Portals [i+intNumPortals] = getRandomTerritory (territoryArray); --set portal side 2
		local structures1 = standing.Territories [privateGameData.Portals [i]].Structures or {};
		local structures2 = standing.Territories [privateGameData.Portals [i+intNumPortals]].Structures or {};
		if (structures1 [strPortalStructureID] == nil) then structures1 [strPortalStructureID] = 0; end
		if (structures2 [strPortalStructureID] == nil) then structures2 [strPortalStructureID] = 0; end
		structures1 [strPortalStructureID] = structures1 [strPortalStructureID] + 1;
		structures2 [strPortalStructureID] = structures2 [strPortalStructureID] + 1;
		standing.Territories [privateGameData.Portals [i]].Structures = structures1;
		standing.Territories [privateGameData.Portals [i+intNumPortals]].Structures = structures2;
	end

	Mod.PrivateGameData = privateGameData
end

function getRandomTerritory (territoryArray)
	print ("# terrs to choose from randomly: " .. #territoryArray);
	local index = math.random (#territoryArray)
	local territoryID = territoryArray[index].ID
	table.remove (territoryArray, index)

	return territoryID
end