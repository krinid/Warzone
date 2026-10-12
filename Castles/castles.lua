--contains common functions used through Behemoth mod to calculate power & power factor for Behemoths

--(global variables) default values if not specified in Mod.Settings
intArmyToCastlePowerRatio = 2; --armies moving into the castle are multiplied by this # to convert into castle Health/Defense Power
intCastleBaseCost = 0; --cost of 1st castle
intCastleCostIncrease = 5; --cumulative cost increase for each additional castle
intCastleMaintenanceCost = 2; --each castle costs this much gpt, gets removed at end of turn so going into next turn, income is reduced appropriately
intCastleScuttleCost = intCastleMaintenanceCost * 2; --scuttle cost is 2x maintenance cost

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

function getColours()
	local colors = {}; -- Stores all the built-in colors (player colors only)
	colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059";
	colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05";
	colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57";
	colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF";
	colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32";
	colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45";
	colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
	colors.WZyellow = "#ABA500"; colors.WZgreen = "#198225"; colors["WZLight Blue"] = "#50B2E3"; colors.WZblue = "#242D9A"; colors.WZred = "#9A2929";
	return colors;
end

function getColourCode (itemName)
	if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
	elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="highlight") then return "#00FFFF"; --cyan
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="ok") then return getColours()["Dark Green"]; --standard green used for "Ok" buttons
	elseif (itemName=="button cyan") then return "#00F4FF"; --cyan
	elseif (itemName=="button green") then return "#008000"; --green
	elseif (itemName=="button magenta") then return "#FF00FF"; --magenta
	elseif (itemName=="button red") then return "#FF0000"; --red
	elseif (itemName=="Card|Reinforcement") then return getColours()["Dark Green"]; --standard green used for "Ok" buttons
	elseif (itemName=="Card|Spy") then return getColours()["Red"]; --
	elseif (itemName=="Card|Emergency Blockade card") then return getColours()["Royal Blue"]; --
	elseif (itemName=="Card|OrderPriority") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|OrderDelay") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Airlift") then return "#777777"; --
	elseif (itemName=="Card|Gift") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Diplomacy") then return getColours()["Light Blue"]; --
	-- elseif (itemName=="Card|") then return getColours()["Medium Blue"]; --
	elseif (itemName=="Card|Sanctions") then return getColours()["Purple"]; --
	elseif (itemName=="Card|Reconnaissance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Surveillance") then return getColours()["Red"]; --
	elseif (itemName=="Card|Blockade") then return getColours()["Blue"]; --
	elseif (itemName=="Card|Bomb") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Bomb+ Card") then return getColours()["Dark Magenta"]; --
	elseif (itemName=="Card|Time Bomb") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Explosive") then return getColours()["Yellow"]; --
	elseif (itemName=="Card|Landmine") then return getColours()["Apple Green"]; --
	elseif (itemName=="Card|Bomb Shelter Card") then return getColours()["Army Green"]; --
	-- elseif (itemName=="Card|") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Nuke") then return getColours()["Tyrian Purple"]; --
	elseif (itemName=="Card|Airstrike") then return getColours()["Ivory"]; --
	elseif (itemName=="Card|Pestilence") then return getColours()["Lime"]; --
	elseif (itemName=="Card|Isolation") then return getColours()["Red"]; --
	elseif (itemName=="Card|Shield") then return getColours()["Aqua"]; --
	elseif (itemName=="Card|Monolith") then return getColours()["Hot Pink"]; --
	elseif (itemName=="Card|Card Block") then return getColours()["Light Blue"]; --
	elseif (itemName=="Card|Card Pieces") then return getColours()["Sea Green"]; --
	elseif (itemName=="Card|Card Hold") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Phantom") then return getColours()["Smoky Black"]; --
	elseif (itemName=="Card|Neutralize") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Deneutralize") then return getColours()["Green"]; --
	elseif (itemName=="Card|Earthquake") then return getColours()["Brown"]; --
	elseif (itemName=="Card|Tornado") then return getColours()["Charcoal"]; --
	elseif (itemName=="Card|Quicksand") then return getColours()["Saddle Brown"]; --
	elseif (itemName=="Card|Forest Fire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Wildfire") then return getColours()["Orange Red"]; --
	elseif (itemName=="Card|Resurrection") then return getColours()["Viridian"];
	elseif (itemName=="Card|Fort Card") then return getColours()["Donkey Brown"]; --
	elseif (itemName=="Card|Beacon") then return getColours()["Yellow"]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	elseif (itemName=="Card|Recon+ Card") then return getColours()["Red"]; --
	elseif (itemName=="Card|Tank Card") then return getColours()["Army Green"]; --
	--Beacon colors.Yellow, BW colors["Dark Gray"], tank card colors["Army Green"], smoke bomb1 & v2 colors["Dark Gray"], recon+, mystery colors["WZLight Blue"] , dms, poison colors.Lime, CP  colors["Sea Green"] colors["Apple Green"] colors["Screamin' Green"] Amazon Viridian Rain Forest
	elseif (itemName=="Card|Smoke Bomb Card") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Mystery Card") then return getColours()["WZLight Blue"]; --
	elseif (itemName=="Card|Barbed Wire Card") then return getColours()["Dark Gray"]; --
	elseif (itemName=="Card|Dead Man's Switch Card") then return getColours()["Artichoke"]; --
	elseif (itemName=="Card|Poison") then return getColours()["Apple Green"]; --
	elseif (itemName=="Card|Card Piece") then return getColours()["Screamin' Green"]; --
	elseif (itemName=="Phase|Purchase") then return "#007700";
	elseif (itemName=="Phase|CardsWearOff") then return "#964B00";
	elseif (itemName=="Phase|Discards") then return "#654321";
	elseif (itemName=="Phase|OrderPriorityCards") then return getColours()["Yellow"];
	elseif (itemName=="Phase|SpyingCards") then return getColours()["Red"];
	elseif (itemName=="Phase|ReinforcementCards") then return getColours()["Dark Green"];
	elseif (itemName=="Phase|Deploys") then return "#00BB00";
	elseif (itemName=="Phase|BombCards") then return getColours()["Dark Magenta"];
	elseif (itemName=="Phase|EmergencyBlockadeCards") then return getColours()["Royal Blue"];
	elseif (itemName=="Phase|Airlift") then return "#777777";
	elseif (itemName=="Phase|Gift") then return getColours()["Aqua"];
	elseif (itemName=="Phase|Attacks") then return "#FF0000";
	elseif (itemName=="Phase|BlockadeCards") then return getColours()["Blue"];
	elseif (itemName=="Phase|DiplomacyCards") then return getColours()["Light Blue"];
	elseif (itemName=="Phase|SanctionCards") then return getColours()["Purple"];
	elseif (itemName=="Phase|ReceiveCards") then return "#005500";
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
	-- elseif (itemName=="Card|") then return getColours()[""]; --
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