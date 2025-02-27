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
		if (playerid<50) then
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

--[[function tableToString_(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)  -- Return the value as-is if it's not a table
    end
    local result = "{"
    for k, v in pairs(tbl) do
        result = result .. tostring(k) .. "=" .. tostring(v) .. ", "
    end
    result = result:sub(1, -3) .. "}"  -- Remove the trailing comma and space
    return result
end]]

local function tableToString_ORIG(tbl, indent)
	if type(tbl) ~= "table" then
		return tostring(tbl)  -- Return the value as-is if it's not a table
	end
	indent = indent or ""  -- Indentation for nested tables
	local result = "{\n"
	for k, v in pairs(tbl) do
		result = result .. indent .. "  " .. tostring(k) .. " = " .. tableToString(v, indent .. "  ") .. ",\n"
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

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end

--adds an "s" for plural items
--if parameter is 1, return "s", else return ""; eg: in order correctly write: 1 turn, 5 turns
function plural (intInputNumber)
	if (intInputNumber==nil or intInputNumber == 1) then return "";
	else
			return "s";
	end
end

--return list of all cards defined in this game; includes custom cards
--generate the list once, then store it in Mod.PublicGame.CardData, and retrieve it from there going forward
function getDefinedCardList (game)
    --print ("[CARDS DEFINED IN THIS GAME]");
    local count = 0;
    local cards = {};
	local publicGameData = Mod.PublicGameData;

	--if CardData structure isn't defined (eg: from an ongoing game before this was done this way), then initialize the variable and populate the list here
	if (publicGameData.CardData==nil) then publicGameData.CardData = {}; publicGameData.CardData.DefinedCards = nil; end

	--if (false) then --publicGameData.CardData.DefinedCards ~= nil) then
	if (publicGameData.CardData.DefinedCards ~= nil) then
		--print ("[CARDS ALREADY DEFINED] don't regen list, just return existing table");
		return publicGameData.CardData.DefinedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
	else
		--print ("[CARDS NOT DEFINED] generate the list, store it in publicGameData.CardData.DefinedCards");
		if (game==nil) then print ("game is nil"); return nil; end
		if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
		if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end
		--[[print ("game==nil --> "..tostring (game==nil).."::");
		print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
		print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
		print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
		print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
		print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
		print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));]]
	
		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			--print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces.."::");
			cards[cardID] = strCardName;
			count = count +1
			--printObjectDetails (cardConfig, "cardConfig");
		end
		--printObjectDetails (cards, "card", count .." defined cards total");
		return cards;
	end
end

--given a card name, return it's cardID
function getCardID (strCardNameToMatch, game)
	--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
	local cards={};
	--[[print ("[getCardID] match name=="..strCardNameToMatch.."::");
	print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
	print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
	print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
	print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));]]
	if (Mod.PublicGameData.CardData.DefinedCards == nil) then
		--print ("run function");
		cards = getDefinedCardList (game);
	else
		--print ("get from pgd");
		cards = Mod.PublicGameData.CardData.DefinedCards;
	end

	--print ("[getCardID] tablelength=="..tablelength (cards));
	for cardID, strCardName in pairs(cards) do
		--print ("[getCardID] cardID=="..cardID..", cardName=="..strCardName.."::");
		if (strCardName == strCardNameToMatch) then
			--print ("[getCardID] matching card cardID=="..cardID.."::");
			return cardID;
		end
	end
	return nil; --cardName not found
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
	print ("@@bonusID==".. bonusID);
	print ("@@bonusName==".. getBonusName (bonusID, game));

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

function getTerritoryName (intTerrID, game)
	if (intTerrID) == nil then return nil; end
	return (game.Map.Territories[intTerrID].Name);
end

function initialize_CardData (game)
    local publicGameData = Mod.PublicGameData;

    publicGameData.CardData = {};
    publicGameData.CardData.DefinedCards = nil;
    publicGameData.CardData.CardPiecesCardID = nil;
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    --[[print ("[init] 0pre");
    print ("game==nil --> "..tostring (game==nil).."::");
    print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
    print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
    print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
    print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
    print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
    print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));]]

    publicGameData.CardData.DefinedCards = getDefinedCardList (game);
    Mod.PublicGameData = publicGameData; --save PublicGameData before calling getDefinedCardList
    publicGameData = Mod.PublicGameData;

    if (game==nil) then print ("game is nil"); return nil; end
    if (game.Settings==nil) then print ("game.Settings is nil"); return nil; end
    if (game.Settings.Cards==nil) then print ("game.Settings.Cards is nil"); return nil; end

    --[[print ("[init] pre");
    print ("game==nil --> "..tostring (game==nil).."::");
    print ("game.Settings==nil --> "..tostring (game.Settings==nil).."::");
    print ("game.Settings.Cards==nil --> "..tostring (game.Settings.Cards==nil).."::");
    print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
    print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
    print ("Mod.PublicGameData.CardData.DefinedCards == nil --> "..tostring (Mod.PublicGameData.CardData.DefinedCards == nil));
    print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));
    print ("[init] post");]]

    --print ("CardPiece=="..tostring(getCardID ("Card Piece")));
    publicGameData.CardData.CardPiecesCardID = tostring(getCardID ("Card Piece"));
    Mod.PublicGameData = publicGameData;

    --printObjectDetails (Mod.PublicGameData.CardData.DefinedCards, "card PGD", "");--count .." defined cards total", game);

    --if Mod.Settings.CardPiecesCardID is set, grab the cardID from this setting
    --standalone app can't grab this yet, need a new version
--[[    if (Mod.Settings.CardPiecesCardID == nil) then
        print ("[CardPiece CardID] get from getCardID function");
        publicGameData.CardData.CardPiecesCardID = getCardID ("Card Piece");
        print ("10----------------------");
    else
        print ("[CardPiece CardID] acquired from Mod.Settings.CardPiecesCardID");
        publicGameData.CardData.CardPiecesCardID = Mod.Settings.CardPiecesCardID;
        print ("11----------------------");
    end]]
    
    --[[print ("[CardPiece CardID] Mod.Settings.CardPiecesCardID=="..tostring (Mod.Settings.CardPiecesCardID));
    print ("[CardPiece CardID] Mod.PublicGameData.CardData.CardPiecesCardID=="..tostring (Mod.PublicGameData.CardData.CardPiecesCardID));
    print ("12----------------------");]]

    --Mod.PublicGameData = publicGameData;
end
--- END of krinid's functions