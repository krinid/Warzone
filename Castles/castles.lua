--contains common functions used through Behemoth mod to calculate power & power factor for Behemoths

--(global variables) default values if not specified in Mod.Settings
intArmyToCastlePowerRatio = 2; --armies moving into the castle are multiplied by this # to convert into castle Health/Defense Power
intCastleBaseCost = 0; --cost of 1st castle
intCastleCostIncrease = 5; --cumulative cost increase for each additional castle
intCastleMaintenanceCost = 2; --each castle costs this much gpt, gets removed at end of turn so going into next turn, income is reduced appropriately

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create(1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="highlight") then return "#00FFFF"; --cyan
	elseif (itemName=="button cyan") then return "#00F4FF"; --cyan
	elseif (itemName=="button green") then return "#008000"; --green
	elseif (itemName=="button magenta") then return "#FF00FF"; --magenta
    else return "#AAAAAA"; --return light grey for everything else
    end
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

--given a parameter 'armies' of type WL.Armies, return the # of a given SU present within it
--2nd parameter indicates pattern match (true) vs exact match (false)
function countSUinstances (armies, strSUname, boolPatternMatch)
	local intNumSUs = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and ((boolPatternMatch and startsWith (su.Name, strSUname)) or (su.Name == strSUname))) then
			intNumSUs = intNumSUs + 1;
		end
	end
	return (intNumSUs);
end

--gets first instance of an SU matching the specified name present on the specified army object
function getSUonTerritory (armies, strSUname, boolPatternMatch)
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and ((boolPatternMatch and startsWith (su.Name, strSUname)) or (su.Name == strSUname))) then
			return (su);
		end
	end
	return (nil);
end

function countSUinstancesOnWholeMapFor1Player (game, playerID, strSUname, boolPatternMatch)
	local intNumSUs = 0;
	for _,terr in pairs (game.LatestStanding.Territories) do
		if (terr.OwnerPlayerID == playerID) then
			intNumSUs = intNumSUs + countSUinstances (terr.NumArmies, strSUname, boolPatternMatch);
		end
	end
	return (intNumSUs);
end

function countSUinstancesOnWholeMapFor1Player_Server (game, playerID, strSUname, boolPatternMatch)
	local intNumSUs = 0;
	for _,terr in pairs (game.ServerGame.LatestTurnStanding.Territories) do
		if (terr.OwnerPlayerID == playerID) then
			intNumSUs = intNumSUs + countSUinstances (terr.NumArmies, strSUname, boolPatternMatch);
		end
	end
	return (intNumSUs);
end

function countSUsPurchasedThisTurn (game, strSUname)
	local numSUs = 0;
	for _,order in pairs(Game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, strSUname.. '|Purchase|')) then
			numSUs = numSUs + 1;
		end
	end
	return (numSUs);
end

function buildingCastleOnTerritoryThisTurn (game, targetTerritoryID)
	for _,order in pairs (game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, 'Castle|Purchase|' ..tostring (targetTerritoryID))) then return (true); end
	end
	return (false);
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	if (game.Map.Territories[intTerrID] == nil) then return nil; end --territory ID does not exist for this game/template/map
	return (game.Map.Territories[intTerrID].Name);
end

function split(inputstr, sep)
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