function Server_StartDistribution (game, standing)
	print ("CREATE PORTAL @ Server_StartDistribution");
	local privateGameData = Mod.PrivateGameData
	privateGameData.Portals = {}
	territoryArray = {}

	local count = #standing.Territories;
	print ("# terrs " .. count);
	-- local count = 1
	-- for _, territory in pairs (game.Map.Territories) do
	-- 	territoryArray [count] = territory
	-- 	count = count + 1
	-- end

	-- Check that the map has enough territories, else reduce to the max # of portals possible for current map (1/2 of the total terr count)
	local NumPortals = Mod.Settings.NumPortals
	if (count < Mod.Settings.NumPortals * 2) then
		NumPortals = math.min (NumPortals, math.floor (count / 2));
	end


	for i = 1, NumPortals do
		local structure = {};
		local strPortalFilename = "Portal";
		if (NumPortals > 1) then --[[ print (i, math.ceil (i / 2)); ]] strPortalFilename = strPortalFilename .. " " .. tostring (i); end
		local Portals = WL.StructureType.Custom (strPortalFilename);
		structure[Portals] = 0
		privateGameData.Portals[i] = getRandomTerritory (standing.Territories) --set portal side 1
		privateGameData.Portals[i+NumPortals] = getRandomTerritory (standing.Territories) --set portal side 2
		print ("Portal created: " ..privateGameData.Portals[i].."/".. game.Map.Territories[privateGameData.Portals[i]].Name .. " -> " .. privateGameData.Portals[i+NumPortals].."/".. game.Map.Territories[privateGameData.Portals[i+NumPortals]].Name);
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