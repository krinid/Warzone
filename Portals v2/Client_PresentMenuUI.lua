--tempoarary workaround until Fizzer patches structures not showing up during distribution (start picks opaque green boxes hide all structures)
function Client_PresentMenuUI (rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
    -- Game = game; --global variable to use in other functions in this code 

    setMaxSize(600, 600);
	game.SendGameCustomMessage ("[acquiring portal locations]", {action="getportals"}, function(PortalData) Portals = PortalData[1]; end); --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data; don't need any processing here, so it's an empty (throwaway) anonymous function
	-- Game.SendGameCustomMessage ("[getting shield data]", {action="shielddata"}, function (shieldData) UI.CreateLabel (MenuWindow).SetText ("\nShield data:\n"..shieldData[1]); end);

	-- if (PortalData == nil) then UI.CreateLabel (rootParent).SetFlexibleWidth(1).SetText ("PortalData empty"); end
	if (Portals == nil) then UI.CreateLabel (rootParent).SetFlexibleWidth(1).SetText ("Portal data empty"); return; end
	-- if (PortalData == nil or Portals == nil) then return; end

	local intNumPortals = #Portals/2;

	UI.CreateLabel (rootParent).SetFlexibleWidth(1).SetText ("Portal locations:");

	for i = 1, intNumPortals do
		local line = UI.CreateHorizontalLayoutGroup (rootParent);
		UI.CreateLabel (line).SetPreferredWidth(50).SetText ("[" .. tostring (i).. "] ");
		-- UI.CreateLabel (line).SetFlexibleWidth(1).SetText (Portals[i] .."/".. game.Map.Territories[Portals[i]].Name .. " -> " .. Portals[i+intNumPortals] .."/".. game.Map.Territories[Portals[i+intNumPortals]].Name);
		UI.CreateButton (line).SetPreferredWidth(250).SetText(game.Map.Territories[Portals[i]].Name).SetColor("#198225").SetOnClick(function() game.HighlightTerritories ({Portals[i]}); game.CreateLocatorCircle (game.Map.Territories [Portals[i]].MiddlePointX, game.Map.Territories[Portals[i]].MiddlePointY); end);
		UI.CreateLabel (line).SetPreferredWidth(50).SetText (" <--> ");
		UI.CreateButton (line).SetPreferredWidth(250).SetText(game.Map.Territories[Portals[i+intNumPortals]].Name).SetColor("#0000FF").SetOnClick(function() game.HighlightTerritories ({Portals[i+intNumPortals]}); game.CreateLocatorCircle (game.Map.Territories [Portals[i+intNumPortals]].MiddlePointX, game.Map.Territories[Portals[i+intNumPortals]].MiddlePointY); end);

		-- -- game.Map.Territories[intTerrID].Name
		-- UI.CreateEmpty (line).SetFlexibleWidth(1);
		-- -- UI.CreateLabel (line).SetText("[".. arr.CombatOrder .."]").SetColor(colors.TextColor);
		-- --game.Map.Territories[intTerrID].Name
		-- if (arr.CombatOrder == 0 and #arr.Units == 1) then whereButton.SetInteractable (false); end;

		-- privateGameData.Portals[i] = getRandomTerritory (standing.Territories) --set portal side 1
		-- privateGameData.Portals[i+NumPortals] = getRandomTerritory (standing.Territories) --set portal side 2
		-- print ("Portal created: " ..privateGameData.Portals[i].."/".. game.Map.Territories[privateGameData.Portals[i]].Name .. " -> " .. privateGameData.Portals[i+NumPortals].."/".. game.Map.Territories[privateGameData.Portals[i+NumPortals]].Name);
		-- structure[Portals] = structure[Portals] + 1
		-- standing.Territories[privateGameData.Portals[i]].Structures = structure
		-- standing.Territories[privateGameData.Portals[i+NumPortals]].Structures = structure
	end
end

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create (1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end