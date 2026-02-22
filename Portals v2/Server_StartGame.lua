function Server_StartGame (game, standing)
	local privateGameData = Mod.PrivateGameData
	privateGameData.Portals = {}
	territoryArray = {}

	local count = 1
	for _, territory in pairs (game.Map.Territories) do
		territoryArray [count] = territory
		count = count + 1
	end

	-- Check that the map has enough territories, else make the minimum number of portals
	local NumPortals = Mod.Settings.NumPortals
	if (#territoryArray < Mod.Settings.NumPortals * 2) then
		NumPortals = 1
	end


	for i = 1, NumPortals do
		local structure = {};
		local strPortalFilename = "Portal";
		if (NumPortals > 1) then print (i, math.ceil (i / 2)); strPortalFilename = strPortalFilename .. " " .. tostring (i); end
		local Portals = WL.StructureType.Custom (strPortalFilename);
		structure[Portals] = 0
		privateGameData.Portals[i] = getRandomTerritory(territoryArray) --set portal side 1
		privateGameData.Portals[i+NumPortals] = getRandomTerritory(territoryArray) --set portal side 2
		structure[Portals] = structure[Portals] + 1
		standing.Territories[privateGameData.Portals[i]].Structures = structure
		standing.Territories[privateGameData.Portals[i+NumPortals]].Structures = structure
	end

	Mod.PrivateGameData = privateGameData
end

function getRandomTerritory(territoryArray)
	local index = math.random (#territoryArray)
	local territoryID = territoryArray[index].ID
	table.remove (territoryArray, index)

	return territoryID
end
