--- START of Dutch's functions
function count(t, func)
	local c = 0;
	for _, v in pairs(t) do
		if func ~= nil then
			c = c + func(v);
		else
			c = c + 1;
		end
	end
	return c;
end

function concatArrays(t1, t2)
	for _, v in pairs(t2) do
		table.insert(t1, v);
	end
	return t1;
end

function filterDeadPlayers(game, array)
	if array == nil then return nil; end
	local toBeRemoved = {};
	for i = 1, #array do
		if game.ServerGame.Game.PlayingPlayers[array[i]] == nil then
			table.insert(toBeRemoved, i);
		end
	end
	for _, index in pairs(toBeRemoved) do
		table.remove(array, index);
	end
	return array;
end

function valueInTable(t, v)
	for _, v2 in pairs(t) do
		if v == v2 then return true; end
	end
	return false;
end

function getKeyFromValue(t, v)
	for i, v2 in pairs(t) do
		if v == v2 then return i; end
	end
end

function getArrayOfAllPlayers(game)
	local t = {};
	for p, _ in pairs(game.ServerGame.Game.PlayingPlayers) do
		table.insert(t, p);
	end
	return t;
end

function createEvent(m, p, h);
	local t = {Message=m, PlayerID=p};
	if not Mod.Settings.GlobalSettings.VisibleHistory then
		t.VisibleTo = h;
	end
	return t;
end

function dateIsEarlier(date1, date2)
	local list = getDateIndexList();
	for _, v in pairs(list) do
		if v == "MiliSeconds" then return false; end
		if date1[v] ~= date2[v] then
			if date1[v] < date2[v] then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end

function getDateIndexList() return {"Year", "Month", "Day", "Hours", "Minutes", "Seconds", "MiliSeconds"}; end

function getDateRestraints() return {99999999, 12, 30, 24, 60, 60, 1000} end;

function dateToTable(s)
	local list = getDateIndexList();
	local r = {};
	local i = 1;
	local buffer = "";
	local index = 1;
	while i <= string.len(s) do
		local c = string.sub(s, i, i);
		if c == "-" or c == " " or c == ":" then
			r[list[index]] = tonumber(buffer);
			buffer = "";
			index = index + 1;
		else
			buffer = buffer .. c;
		end
		i = i + 1;
	end
	r[list[index]] = tonumber(buffer);
	return r;
end

function tableToDate(t)
	return t.Year .. "-" .. addZeros("Month", t.Month) .. "-" .. addZeros("Day", t.Day) .. " " .. addZeros("Hours", t.Hours) .. ":" .. addZeros("Minutes", t.Minutes) .. ":" .. addZeros("Seconds", t.Seconds) .. ":" .. addZeros("MiliSeconds", t.MiliSeconds);
end

function addTime(t, field, i)
	local dateIndex = getDateIndexList();
	local restraint = getDateRestraints()[getTableKey(dateIndex, field)];
	t[field] = t[field] + i;
	if t[field] > restraint then
		t[field] = t[field] - restraint;
		addTime(t, dateIndex[getTableKey(dateIndex, field) - 1], 1);
	end
	return t;
end

function getTableKey(t, value)
	for i, v in pairs(t) do
		if value == v then return i; end
	end
end

function addZeros(field, i)
	if field == "MiliSeconds" then
		if i < 10 then
			return "00" .. i;
		elseif i < 100 then
			return "0" .. i;
		end
	else
		if i < 10 then
			return "0" .. i;
		end
	end
	return i;
end
--- END of Dutch's functions

--- START of dabo's functions
function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
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

function toPlayerName(playerid, game)
	if (playerid ~= nil) then
		if (playerid==WL.PlayerID.Neutral) then
			return ("Neutral");
		elseif (playerid<50) then
				return ("AI"..playerid);
		else
			for _,playerinfo in pairs(game.Game.Players) do
				if(playerid == playerinfo.ID)then
					return (playerinfo.DisplayName(nil, false));
				end
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found
end
--- END of dabo's functions

--- START of Fizzer's functions
function map(array, func)
	local new_array = {}
	local i = 1;
	for _,v in pairs(array) do
		new_array[i] = func(v);
		i = i + 1;
	end
	return new_array
end

function filter(array, func)
	local new_array = {}
	local i = 1;
	for _,v in pairs(array) do
		if (func(v)) then
			new_array[i] = v;
			i = i + 1;
		end
	end
	return new_array
end
--- END of Fizzer's functions

--- START of DanWL's functions
--heavily modified version of DanWL's eliminate function; reduced to only eliminate a single specified playerID
--change all territories for the specified player to neutral to eliminate the player
--remove all Special Units owned by that player even if they are on territories not owned by that player
function eliminatePlayer (playerID, territories, removeSpecialUnits, isSinglePlayer)
	local modifiedTerritories = {};
	local canRemoveSpecialUnits = removeSpecialUnits and ((not isSinglePlayer) or (isSinglePlayer and WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher('5.22')));
	if (playerID == nil or playerID <= 0) then return nil; end

	for _, territory in pairs(territories) do
		local specialUnitsToRemove = {};
		local terrMod = nil;

		--if territory is owned by specified player, make it neutral
		if (territory.OwnerPlayerID == playerID) then
			terrMod = WL.TerritoryModification.Create (territory.ID);
			terrMod.SetOwnerOpt = WL.PlayerID.Neutral;
		end

		--if territory has SUs owned by specified player, remove them, even if the territory is owned by another player
		if (canRemoveSpecialUnits) then
			for _, SU in pairs(territory.NumArmies.SpecialUnits) do
				if (SU.OwnerID == playerID) then
					if (terrMod == nil) then terrMod = WL.TerritoryModification.Create (territory.ID); end
					table.insert(specialUnitsToRemove, SU.ID);
				end
			end
		end

		--if any changes were made (territory owner set to neutral and/or any SUs removed)
		if (terrMod ~= nil) then
			if (#specialUnitsToRemove > 0) then terrMod.RemoveSpecialUnitsOpt = specialUnitsToRemove; end
			table.insert(modifiedTerritories, terrMod);
		end
	end

	return (modifiedTerritories);
end
--- END of DanWL's functions

--- START of Derfellios's functions
function NotTableEmpty(List)
	for a,b in pairs(List) do
		return true
	end
	return false
end

function NotinTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then 
			return false 
		end
    end
    return true
end
--- END of Derfellios's functions

--- START of krinid's functions
-- Helper function to convert a table to a string representation
local function tableToString(tbl, indent)
	if type(tbl) ~= "table" then
		return tostring(tbl)  -- Return the value as-is if it's not a table
	end
	indent = indent or ""  -- Indentation for nested tables
	indent = "";
	local result = "{" --"{\n"
	for k, v in pairs(tbl) do
		result = result .. indent .. "  " .. tostring(k) .. " = " .. tableToString(v, indent .. "  ") .. ","; --\n"
	end
	result = result .. indent .. "}"
	return result
end

-- Main function to print object details
function printObjectDetails(object, strObjectName, strLocationHeader)
	strObjectName = strObjectName or ""  -- Default blank value if not provided
	strLocationHeader = strLocationHeader or ""  -- Default blank value if not provided
	print("[" .. strLocationHeader .. "] object=" .. strObjectName .. ", tablelength==".. tablelength (object).."::");
	print("[proactive display attempt] value==" .. tostring(object));

	-- Early return if object is nil or an empty table
	if object == nil then
		print("[invalid/empty object] object==nil")
		return
	elseif type(object) == "table" and next(object) == nil then
		print("[invalid/empty object] object=={}  [empty table]")
		return
	end

	-- Handle tables
	if type(object) == "table" then
		-- Check and display readableKeys
		if object.readableKeys then
			for key, value in pairs(object.readableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [readablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
				else
					print("  [readablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[R]**readableKeys DNE")
		end

		-- Check and display writableKeys
		if object.writableKeys then
			for key, value in pairs(object.writableKeys) do
				local propertyValue = object[value]
				if type(propertyValue) == "table" then
					print("  [writablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue)) -- *** this is the last line of output that successfully executes
				else
					print("  [writablekeys_value] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tostring(propertyValue))
				end
			end
		else
			print("[W]**writableKeys DNE")
		end

		-- Display all base properties of the table
		for key, value in pairs(object) do
			if key ~= "readableKeys" and key ~= "writableKeys" then  -- Skip already processed keys
				if type(value) == "table" then
					print("[base_table] key==" .. tostring(key) .. ":: value==" .. tableToString(value))
				else
					print("[base_value] key==" .. tostring(key) .. ":: value==" .. tostring(value))
				end
			end
		end
	else
		-- Handle non-table objects
		print("[not table] value==" .. tostring(object))
	end
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function PrintProxyInfo(obj)
    print('type=' .. obj.proxyType .. ' readOnly=' .. tostring(obj.readonly) .. ' readableKeys=' .. table.concat(obj.readableKeys, ',') .. ' writableKeys=' .. table.concat(obj.writableKeys, ','));
end

function WLturnPhases ()
	--WLturnPhases = {'CardsWearOff', 'Purchase', 'Discards', 'OrderPriorityCards', 'SpyingCards', 'ReinforcementCards', 'Deploys', 'BombCards', 'EmergencyBlockadeCards', 'Airlift', 'Gift', 'Attacks', 'BlockadeCards', 'DiplomacyCards', 'SanctionCards', 'ReceiveCards', 'ReceiveGold'};
	local WLturnPhasesTable = {
		['CardsWearOff'] = WL.TurnPhase.CardsWearOff,
		['Purchase'] = WL.TurnPhase.Purchase,
		['Discards'] = WL.TurnPhase.Discards,
		['OrderPriorityCards'] = WL.TurnPhase.OrderPriorityCards,
		['SpyingCards'] = WL.TurnPhase.SpyingCards,
		['ReinforcementCards'] = WL.TurnPhase.ReinforcementCards,
		['Deploys'] = WL.TurnPhase.Deploys,
		['BombCards'] = WL.TurnPhase.BombCards,
		['EmergencyBlockadeCards'] = WL.TurnPhase.EmergencyBlockadeCards,
		['Airlift'] = WL.TurnPhase.Airlift,
		['Gift'] = WL.TurnPhase.Gift,
		['Attacks'] = WL.TurnPhase.Attacks,
		['BlockadeCards'] = WL.TurnPhase.BlockadeCards,
		['DiplomacyCards'] = WL.TurnPhase.DiplomacyCards,
		['SanctionCards'] = WL.TurnPhase.SanctionCards,
		['ReceiveCards'] = WL.TurnPhase.ReceiveCards,
		['ReceiveGold'] = WL.TurnPhase.ReceiveGold
	};
	return WLturnPhasesTable;
end

function WLplayerStates ()
	local WLplayerStatesTable = {
		[WL.GamePlayerState.Invited] = 'Invited',
		[WL.GamePlayerState.Playing] = 'Playing',
		[WL.GamePlayerState.Eliminated] = 'Eliminated',
		[WL.GamePlayerState.Won] = 'Won',
		[WL.GamePlayerState.Declined] = 'Declined',
		[WL.GamePlayerState.RemovedByHost] = 'RemovedByHost',
		[WL.GamePlayerState.SurrenderAccepted] = 'SurrenderAccepted',
		[WL.GamePlayerState.Booted] = 'Booted',
		[WL.GamePlayerState.EndedByVote] = 'EndedByVote'
	};
	return WLplayerStatesTable;
end

--given input parameter of the text friendly name value of the turn phase, return the WZ internal numeric value that represents that turn phase; this # is what must be assigned to orders to properly associate the turn phase of the order
function WLturnPhases_getNumericValue (strWLturnPhaseName)
	return WLturnPhases()[strWLturnPhaseName];
end

--create a few Horz objects to add a bit of invisible spacing (indenting)
function addHorizontalBufferSpacing (parent)
	--return CreateHorz(CreateHorz(CreateHorz(CreateHorz(CreateHorz(parent)))));
	return CreateHorz(CreateHorz(CreateHorz(parent)));
end

--accept player object, return result true is player active in game; false is player is eliminated, booted, surrendered, etc
function isPlayerActive (playerID, game)
	--if (playerid<=50) then

	local player = game.Game.Players[playerID];

	--if VTE, player was removed by host or decline the game, then player is not Active
	if player.State ~= WL.GamePlayerState.EndedByVote and player.State ~= WL.GamePlayerState.RemovedByHost and player.State ~= WL.GamePlayerState.Declined then
		return (false);
	--if eliminated or booted (and not AI), then player is not active
	elseif ((player.State == WL.GamePlayerState.Eliminated) or (player.State == WL.GamePlayerState.Booted and not game.Settings.BootedPlayersTurnIntoAIs) or (player.State == WL.GamePlayerState.SurrenderAccepted and not game.Settings.SurrenderedPlayersTurnIntoAIs)) then
	--elseif ((player.State == WL.GamePlayerState.Eliminated) or (player.State == WL.GamePlayerState.Booted and not game.Settings.BootedPlayersTurnIntoAIs) or (player.State == WL.GamePlayerState.SurrenderAccepted and not game.Settings.SurrenderedPlayersTurnIntoAIs)) then
		return (false);
	else
		-- all other cases, user is active
		return (true);
	end
end

function createJumpToLocationObject (game, targetTerritoryID)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

function createJumpToLocationObject_Bonus (game, bonusID)
	--get XY coordinates of the bonus; note this is estimated since it's based on the midpoints of the territories in the bonus (that's all WZ provides)
	local XYbonusCoords = getXYcoordsForBonus (bonusID, game);
	--# of map units to add as buffer to min/max X values to zoom/pan on the bonus; do this to increase chance of territories being on screen, since the X/Y calcs WZ provides are midpoints of the territories (and thus the bonuses), not the actual left/right/top/bottom coordiantes
	local X_buffer = 25;
	local Y_buffer = 25;

	--add/subtract buffer (25) on each side of bonus b/c it's calc'd from the midpoints of each territory, not the actual edges, so some territories can still get cut off when using their midpoints to zoom to
	return (WL.RectangleVM.Create (XYbonusCoords.min_X-X_buffer, XYbonusCoords.min_Y-Y_buffer, XYbonusCoords.max_X+X_buffer, XYbonusCoords.max_Y+Y_buffer));
end

--return table with keys X=xvalue, Y=yvalue for a bonus which is the average of its territories' X,Y coords as a best estimate for where the bonus resides on the map
function getXYcoordsForBonus (bonusID, game)
	local average_X = 0;
	local average_Y = 0;
	local min_X = 0;
	local max_X = 0;
	local min_Y = 0;
	local max_Y = 0;
	local sum_X = 0;
	local sum_Y = 0;
	local count = 0;

	if (game==nil) then print ("@@game is nil"); end
	if (game.Map==nil) then print ("@@game.Map is nil"); end
	if (game.Map.Bonuses==nil) then print ("@@game.Map.Bonuses is nil"); end
	--print ("@@bonusID==".. bonusID);
	--print ("@@bonusName==".. getBonusName (bonusID, game));

	for _,terrID in pairs (game.Map.Bonuses[bonusID].Territories) do
		count = count + 1;
		sum_X = sum_X + game.Map.Territories[terrID].MiddlePointX;
		sum_Y = sum_Y + game.Map.Territories[terrID].MiddlePointY;
		if (game.Map.Territories[terrID].MiddlePointX < min_X) then min_X = game.Map.Territories[terrID].MiddlePointX; end
		if (game.Map.Territories[terrID].MiddlePointX > max_X) then max_X = game.Map.Territories[terrID].MiddlePointX; end
		if (game.Map.Territories[terrID].MiddlePointY < min_Y) then min_Y = game.Map.Territories[terrID].MiddlePointY; end
		if (game.Map.Territories[terrID].MiddlePointY > max_Y) then max_Y = game.Map.Territories[terrID].MiddlePointY; end
	end
	--take average of all the X/Y coords
	average_X = sum_X / count;
	average_Y = sum_Y / count;

	return ({average_X=average_X, average_Y=average_Y, min_X=min_X, max_X=max_X, min_Y=min_Y, max_Y=max_Y});
end

function getColours()
    local colors = {};					-- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
    else return "#AAAAAA"; --return light grey for everything else
    end
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

--adds an "s" for plural items
--if parameter is 1, return "s", else return ""; eg: in order correctly write: 1 turn, 5 turns
function plural (intInputNumber)
	if (intInputNumber==nil or intInputNumber == 1) then return "";
	else return "s"; end
end

--keep numDecimalsToKeep quantity of decimal points for 'number', truncate the remainder
function truncateDecimals (number, numDecimalsToKeep)
    local multiplier = 10 ^ numDecimalsToKeep;
    return (math.floor (number * multiplier) / multiplier);
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
function getDefinedCardList (game)
    local count = 0;
    local cards = {};
	local publicGameData = Mod.PublicGameData;

	--if CardData structure isn't defined (eg: from an ongoing game before this was done this way), then initialize the variable and populate the list here
	if (publicGameData.CardData==nil) then publicGameData.CardData = {}; publicGameData.CardData.DefinedCards = nil; end

	--if (false) then --publicGameData.CardData.DefinedCards ~= nil) then
	if (publicGameData.CardData.DefinedCards ~= nil) then
		return publicGameData.CardData.DefinedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
	else
		if (game==nil) then print ("game is nil"); return nil; end
		if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
		if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			cards[cardID] = strCardName;
			count = count +1
		end
		return cards;
	end
end

--given a card name, return it's cardID (not card instance ID), ie: represents the card type, not the instance of the card
function getCardID (strCardNameToMatch, game)
	--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
	local cards={};
	if (Mod.PublicGameData.CardData == nil or Mod.PublicGameData.CardData.DefinedCards == nil) then
		print ("run function");
		cards = getDefinedCardList (game);
	else
		cards = Mod.PublicGameData.CardData.DefinedCards;
	end

	for cardID, strCardName in pairs(cards) do
		if (strCardName == strCardNameToMatch) then
			return cardID;
		end
	end
	return nil; --cardName not found
end

--return cardInstace if playerID possesses card of type cardID, otherwise return nil
function playerHasCard (playerID, cardID, game)
	if (playerID<=0) then print ("playerID is neutral (has no cards)"); return nil; end
	if (cardID==nil) then print ("cardID is nil"); return nil; end
	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards) do
		if (v.CardID == tonumber(cardID)) then print (k); return k; end
	end
	return nil;
end

--return card instance for a given card type by name that belongs to a given player
function getCardInstanceID_fromName (playerID, strCardNameToMatch, game)
	print ("[GCII_fn] player "..playerID..", cardName "..strCardNameToMatch);
	local cardID = tonumber (getCardID (strCardNameToMatch, game));
	print ("[GCII_fn] player "..playerID..", cardName "..strCardNameToMatch..", cardID "..tostring(cardID));
	if (cardID==nil) then print ("cardID is nil"); return nil; end
	return getCardInstanceID (playerID, cardID, game);
end

--return card instance if playerID possesses card of type cardID, otherwise return nil; note this is not the same as getCardID, which returns the cardID of the card type
function getCardInstanceID (playerID, cardID, game)
	print ("[GCII] player "..playerID..", cardID "..cardID);
	if (playerID==0) then print ("playerID is neutral (has no cards)"); return nil; end

	if (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards==nil) then print ("WHOLE CARDS nil"); return nil; end
	for k,v in pairs (game.ServerGame.LatestTurnStanding.Cards[playerID].WholeCards) do
		if (v.CardID == cardID) then return k; end
	end
	return nil;
end

function getCardName_fromID(cardID, game);
    print ("cardID=="..cardID);
    local cardConfig = game.Settings.Cards[tonumber(cardID)];
    return getCardName_fromObject (cardConfig);
end

function getCardName_fromObject(cardConfig)
	if (cardConfig==nil) then print ("cardConfig==nil"); return nil; end
    if cardConfig.proxyType == 'CardGameCustom' then
        return cardConfig.Name;
    end

    if cardConfig.proxyType == 'CardGameAbandon' then
        -- Abandon card was the original name of the Emergency Blockade card
        return 'Emergency Blockade card';
    end
    return cardConfig.proxyType:match("^CardGame(.*)");
end

function getBonusName (intBonusID, game)
	if (intBonusID) == nil then return nil; end
	if (game==nil) then print ("##game is nil"); end
	if (game.Map==nil) then print ("##game.Map is nil"); end
	if (game.Map.Bonuses==nil) then print ("##game.Map.Bonuses is nil"); end
	return (game.Map.Bonuses[intBonusID].Name);
end

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	return (game.Map.Territories[intTerrID].Name);
end

function getPlayerName(game, playerid)
	if (playerid == nil) then return "Player DNE (nil)";
	elseif (tonumber(playerid)==WL.PlayerID.Neutral) then return ("Neutral");
	elseif (tonumber(playerid)<50) then return ("AI "..playerid);
	else
		for _,playerinfo in pairs(game.Game.Players) do
			if(tonumber(playerid) == tonumber(playerinfo.ID))then
				return (playerinfo.DisplayName(nil, false));
			end
		end
	end
	return "[Error - Player ID not found,playerid==]"..tostring(playerid); --only reaches here if no player name was found but playerID >50 was provided
end

--return the # of armies deployed to territory terrID so far this turn
function getArmiesDeployedThisTurnSoFar (game, terrID)
	for k,existingGameOrder in pairs (game.Orders) do
		--print (k,existingGameOrder.proxyType);
		if (existingGameOrder.proxyType == "GameOrderDeploy") then
			print ("[DEPLOY] player "..existingGameOrder.PlayerID..", DeployOn "..existingGameOrder.DeployOn..", NumArmies "..existingGameOrder.NumArmies.. ", free "..tostring(existingGameOrder.Free));
			if (existingGameOrder.DeployOn == terrID) then return existingGameOrder.NumArmies; end --this is actual integer # of army deployments, not the usual NumArmies structure containing NumArmies+SpecialUnits
		end
	end
	return (0); --if no matching deployment orders were found, there were no deployments, so return 0
end

function initialize_CardData (game)
    local publicGameData = Mod.PublicGameData;

    publicGameData.CardData = {};
    publicGameData.CardData.DefinedCards = nil;
    publicGameData.CardData.CardPiecesCardID = nil;
	publicGameData.CardData.ResurrectionCardID = nil;
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    publicGameData.CardData.DefinedCards = getDefinedCardList (game);
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    if (game==nil) then print ("game is nil"); return nil; end
    if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
    if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

    publicGameData.CardData.CardPiecesCardID = tostring(getCardID ("Card Piece"));
	publicGameData.CardData.ResurrectionCardID = tostring(getCardID ("Resurrection"));
    Mod.PublicGameData = publicGameData;
end

--initialize the Mod.PublicGameData.Debug structure and all member properties
function initialize_debug_data ()
	local publicGameData = Mod.PublicGameData;
	publicGameData.Debug = {};
	publicGameData.Debug.DebugMode = false;
	publicGameData.Debug.DebugUser = 1058239; --only output data for this user, to prevent other users from displaying & erasing the data so it's not available for me & disable abuse of this coding/debugging feature
	publicGameData.Debug.TrimData = true; --indicates whether to trim data (erase) it after viewing it or leave it in PublicGameData.Debug.OutputData for future perusal
    publicGameData.Debug.OutputData = {};
    publicGameData.Debug.OutputDataCounter = 0;  --the highest key# created so far
    publicGameData.Debug.OutputDataLastRead = 0; --the highest key# retrieved by client side
    Mod.PublicGameData = publicGameData;
end

--call from server hooks to write data to be retrieved by client hooks later
function printDebug (strOutputText)
	print (strOutputText); --in addition to storing for retrieval from client hook (see below), also output to Mod Log window (this will display normally when playing SP on standalone client)

	local publicGameData = Mod.PublicGameData;
	if (publicGameData.Debug == nil) then publicGameData.Debug = {}; end
	if (publicGameData.Debug.DebugMode == nil) then publicGameData.Debug.DebugMode = false; end
	if (publicGameData.Debug.TrimData == nil) then publicGameData.Debug.TrimData = true; end --if not configured, default to trim data (so it doesn't get unnecessarily/unknowingly huge)

	-- local debugMode = true;
	if (publicGameData.Debug.DebugMode == true) then
		if (publicGameData.Debug.OutputData == nil) then publicGameData.Debug.OutputData = {}; end
		if (publicGameData.Debug.OutputDataCounter == nil) then publicGameData.Debug.OutputDataCounter = 0; end
		if (publicGameData.Debug.OutputDataLastRead == nil) then publicGameData.Debug.OutputDataLastRead = 0; end
		publicGameData.Debug.OutputDataCounter = publicGameData.Debug.OutputDataCounter + 1;
		publicGameData.Debug.OutputData [publicGameData.Debug.OutputDataCounter] = "[S]"..strOutputText;
		Mod.PublicGameData = publicGameData;
	end
end

--given an SU 'unit', return true/false indicating whether it is an Immovable Special Unit (ie: should be excluded from any Attack/Transfer/Airlift operations)
function isSpecialUnitAnImmovableUnit (unit)
	if (unit.proxyType ~= "CustomSpecialUnit") then return false; end --non-custom special units (Commanders & Bosses) are not Immovables

	--identify all of the following SU types as Immovables; some of these like Nuke, Pestilence
	if (unit.Name == "Monolith") or (unit.Name == "Shield") or (unit.Name == "Neutralized territory") or (unit.Name == "Quicksand impacted territory") or (unit.Name == "Isolated territory") or (unit.Name == "Tornado") or (unit.Name == "Earthquake") or (unit.Name == "Nuke") or (unit.Name == "Pestilence") or (unit.Name == "Forest Fire") then
		return true;
	end
end

--called from Server_GameCustomMessage which is in turn called by client hooks, in order to clear data elements retrieved by the client hook (so they aren't continually redisplayed on client side)
function trimDebug (intLastReadKey)
	local publicGameData = Mod.PublicGameData;
	if (publicGameData.Debug == nil) then return; end --debug data is empty, nothing to trim
	if (publicGameData.Debug.OutputData == nil) then return; end --debug data is empty, nothing to trim

	if (publicGameData.Debug.OutputDataLastRead == nil) then publicGameData.Debug.OutputDataLastRead = 0; end
	if (intLastReadKey <= publicGameData.Debug.OutputDataLastRead) then return; end --new intLastReadKey is lower than the already stored previous debugOutputDataLastRead, which makes no sense, so just do nothing

	for k=publicGameData.Debug.OutputDataLastRead+1, intLastReadKey do
		publicGameData.Debug.OutputData [k] = nil;
	end
	publicGameData.Debug.OutputDataLastRead = intLastReadKey;
	Mod.PublicGameData = publicGameData;
end

--called from client hooks to display data stored by server hooks
function displayDebugInfoFromServer (game)
	local publicGameData = Mod.PublicGameData;
	if (publicGameData.Debug == nil) then return; end --debug data is empty, nothing to display
	if (publicGameData.Debug.OutputData == nil) then return; end --debug data is empty, nothing to display

	if (publicGameData.Debug.OutputDataCounter == nil) then publicGameData.Debug.OutputDataCounter = 0; end
	if (publicGameData.Debug.OutputDataLastRead == nil) then publicGameData.Debug.OutputDataLastRead = 0; end

	--check if there are any undisplayed debug messages; if LastRead > Counter then there is an error, that should never happen; when LastRead == Counter, all messages have been displayed already
	if (publicGameData.Debug.OutputDataLastRead >= publicGameData.Debug.OutputDataCounter) then print ("[No new server debug output]"); end
	for k=publicGameData.Debug.OutputDataLastRead+1, publicGameData.Debug.OutputDataCounter do
		print (publicGameData.Debug.OutputData [k]); --output stored debug statement to local client Mod Log console
	end
	--trim (clear) the statements that were just displayed so they aren't reoutputted next time & we free up space in PublicGameData
	game.SendGameCustomMessage ("[getting debug info from server]", {action="trimdebugdata", lastReadKey=publicGameData.Debug.OutputDataCounter}, function() end); --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data; don't need any processing here, so it's an empty (throwaway) anonymous function
	--for reference: function Server_GameCustomMessage(game,playerID,payload,setReturn)
end

--concatenate elements of 2 arrays, return resulting array; elements do not need to be consecutive or numeric; if both arrays use the same keys, array2 will overwrite the values of array1 where the keys overlap
function concatenateArrays (array1, array2)
	local result = array1; --start with the first array, then add the elements of the 2nd array to it
	for k,v in pairs (array2) do
		result[k] = array2[i];
	end
	return result
end
--- END of krinid's functions