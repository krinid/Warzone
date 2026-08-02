function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)
	print ("[BOMB+ PMUI START]")
	for k,v in pairs (game.LatestStanding.Territories) do
		--list all structures on each territory, get structure ID, highlight if it's a Fort or not
		local fortID = territoryHasFort (v);
		if v.Structures ~= nil then
			print ("Client_PresentMenuUI - Territory ID: " ..k.. ", Name: " ..game.Map.Territories[k].Name.. ", Owner: " ..v.OwnerPlayerID.. ", # structures: " ..tablelength (v.Structures).. ", fortID: " ..tostring (fortID));
			for key, intQuantity in pairs (v.Structures) do
				local structureData = split (key, "|");
				if (structureData [1] == "c") then
					print ("Structure - Custom -- Name: " ..structureData [3].. ", Count " ..tostring (intQuantity).. ", ID: " ..key.. ", Mod ID " ..structureData [2]);
					-- if (structureData [3] == "Fort") then print ("****confirmed FORT"); end
				else
					print ("Structure - Built-in -- Name: " ..WL.StructureType.ToString (key).. ", Count " ..tostring (intQuantity).. ", ID: " ..key);
				end
			end
		end
	end
end

function territoryHasFort (territory)
	local structures = territory.Structures or {};
	local strFortStructureID = nil;

	for key, _ in pairs (structures) do

		local structureData = split (key, "|");
		if (structureData [1] == "c" and structureData [3] == "Fort") then strFortStructureID = key; end

		-- if (structureData [1] == "c") then
			-- print ("Custom structure - Name: " ..structureData [3].. ", Mod ID " ..structureData [2]..", structure ID: " ..structureID.. " [" ..key.."]");
			-- print ("Custom structure - FORT CHECK: " ..structures ["Fort"]);
		-- 	if (structureData [3] == "Fort") then strFortStructureID = key; print ("****confirmed FORT"); end
		-- else
			-- print ("Built-in structure data: " ..structureID..", structure ID: " ..key);
		-- end
	end

	return strFortStructureID;
end

function split(inputstr, sep)
	if inputstr == nil then return {}; end
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end