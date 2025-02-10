
function setPlayerNotifications()
	local t = {};
	t.Messages = {};
	t.LeftPlayers = {};
	t.JoinedPlayers = {};
	t.FactionWarDeclarations = {};
	t.FactionsPeaceOffers = {};
	t.FactionsPeaceConfirmed = {};
	t.FactionsPeaceDeclined = {};
	t.FactionsKicks = {};
	t.FactionsPendingJoins = {};
	t.WarDeclarations = {};
	t.PeaceOffers = {};
	t.PeaceDeclines = {};
	t.PeaceConfirmed = {};
	t.NewFactionLeader = {};
	t.GotKicked = {};
	t.JoinRequestApproved = {};
	t.JoinRequestRejected = {};
	return t;
end

function resetPlayerNotifications(t)
	t.LeftPlayers = {};
	t.JoinedPlayers = {};
	t.FactionWarDeclarations = {};
	t.FactionsPeaceConfirmed = {};
	t.FactionsPeaceDeclined = {};
	t.FactionsKicks = {};
	t.FactionsPendingJoins = {};
	t.WarDeclarations = {};
	t.PeaceConfirmed = {};
	t.PeaceDeclines = {};
	t.NewFactionLeader = {};
	t.GotKicked = {};
	t.JoinRequestApproved = {};
	t.JoinRequestRejected = {};
	t.Messages = {};
	return t;
end

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

function getSlotName(i)
	local c = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};
	local s = "Slot ";
	if i > 25 then
		s = s .. c[math.floor(i / 26)];
		i = i - math.floor(i / 26);
	end
	return s .. c[i % 26 + 1];
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

function getPlayerHashMap(data, p, p2)
	local t = {};
	if data.IsInFaction[p] then
		for _, faction in pairs(data.PlayerInFaction[p]) do
			concatArrays(t, data.Factions[faction].FactionMembers);
		end
	else
		table.insert(t, p);
	end
	if data.IsInFaction[p2] then
		for _, faction in pairs(data.PlayerInFaction[p2]) do
			concatArrays(t, data.Factions[faction].FactionMembers);
		end
	else
		table.insert(t, p2);
	end
	return t;
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

function isFactionLeader(p)
	if Mod.PublicGameData.IsInFaction[p] then
		for _, faction in pairs(Mod.PublicGameData.PlayerInFaction[p]) do
			if type(faction) == type(table) then
				for i, v in pairs(faction) do print(i, v); end
			end
			if Mod.PublicGameData.Factions[faction].FactionLeader == p then
				return true;
			end
		end
	end
	return false;
end

--- END of Dutch's functions

--- START of dabo's functions
function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(myVariable) ~= "table") then return 0; end
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

  --[[function toTerritoryName(territoryid,game)
	game.Map.Territories[targetterritoryid].Name
	for _,playerinfo in pairs(game.Map.Territories)do
		if(playerid == playerinfo.ID)then
			return playerinfo.DisplayName(nil, false);
		end
	end
	return "Error - Player ID not found.";
end]]

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
					print("  [writablekeys_table] key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
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

--[[function printObjectDetails_ (object, strObjectName, strLocationHeader) --2nd & 3rd params are optional
	strObjectName = strObjectName or ""; --assign default blank value if not provided; 
	strLocationHeader = strLocationHeader or ""; --assign default blank value if not provided; 
	print ("["..strLocationHeader.."] object="..strObjectName.."::");
	print("[proactive display attempt] value=="..tostring(object));
	if (object==nil) then
	  print ("[invalid object] object==nil");
	  return;
	elseif (object=={}) then
	  print ("[invalid object] object=={}");
	  return;
	end
	if type(object)=="table" then
		if object.readableKeys then --check if readableKeys exists, if not don't loop on that property (else it will throw an error)
			for key, value in pairs(object.readableKeys) do
				--print("[R]**key=="..key.."::value=="..value.."::tostring(value)=="..tostring(value).."::");

				-- Display object[value], handling cases where it might be a table
				local propertyValue = object[value];
				if type(propertyValue) == "table" then
					print("[readablekeys_table]key#=="..key..":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue));
				else
					print("[readablekeys_value]key#=="..key..":: value==" .. tostring(value) .. ":: value==" .. tostring(propertyValue));
				end				

			end
		else
			print ("[R]**readableKeys DNE");
		end
		if object.writableKeys then --check if writableKeys exists, if not don't loop on that property (else it will throw an error)
			for key, value in pairs(object.writableKeys) do
				print("[W]!!key=="..key.."::value=="..value.."::tostring(value)=="..tostring(value).."::");
				--print("[W++]obj property=="..tostring(value)..":: value=="..obj[value]);

				-- Display object[value], handling cases where it might be a table
				local propertyValue = object[value];
				local propertyValue = object[value];
				if type(propertyValue) == "table" then
					print("[writablekeys_table]key#=="..key..":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue));
				else
					print("[writablekeys_value]key#=="..key..":: value==" .. tostring(value) .. ":: value==" .. tostring(propertyValue));
				end				
				
			end    
		else
		print ("[W]**writableKeys DNE");
		end
	end
	if type (object)=="table" then
		for key, value in pairs(object) do
		print("[base]##key=="..key.."::tostring(value)=="..tostring(value).."::");
		--print("##key=="..key.."::value=="..value.."::tostring(value)=="..tostring(value).."::");
		end
	else
		print("[not table] value=="..tostring(object));
	end
end]]

function tableToString_(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)  -- Return the value as-is if it's not a table
    end
    local result = "{"
    for k, v in pairs(tbl) do
        result = result .. tostring(k) .. "=" .. tostring(v) .. ", "
    end
    result = result:sub(1, -3) .. "}"  -- Remove the trailing comma and space
    return result
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function PrintProxyInfo(obj)
    print('type=' .. obj.proxyType .. ' readOnly=' .. tostring(obj.readonly) .. ' readableKeys=' .. table.concat(obj.readableKeys, ',') .. ' writableKeys=' .. table.concat(obj.writableKeys, ','));
end

function WLturnPhases ()
	--WLturnPhases = {'CardsWearOff', 'Purchase', 'Discards', 'OrderPriorityCards', 'SpyingCards', 'ReinforcementCards', 'Deploys', 'BombCards', 'EmergencyBlockadeCards', 'Airlift', 'Gift', 'Attacks', 'BlockadeCards', 'DiplomacyCards', 'SanctionCards', 'ReceiveCards', 'ReceiveGold'};
	WLturnPhasesTable = {
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

--given input parameter of the text friendly name value of the turn phase, return the WZ internal numeric value that represents that turn phase; this # is what must be assigned to orders to properly associate the turn phase of the order
function WLturnPhases_getNumericValue (strWLturnPhaseName)
	return WLturnPhases()[strNukeImplementationPhase];
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
    print ("[CARDS DEFINED IN THIS GAME]"); 
    local count = 0;
    local cards = {};
	local publicGameData = Mod.PublicGameData;

	if (false) then --(publicGameData.CardData.definedCards ~= nil) then
		print ("[CARDS ALREADY DEFINED] don't regen list, just return existing table");
		return publicGameData.CardData.definedCards; --if the card data is already stored in publicGameData.CardData.definedCards, just return the list that has already been processed, don't regenerate it (it takes ~3.5 secs on standalone app so likely a longer, noticeable delay on web client)
	else
		print ("[CARDS NOT DEFINED] generate the list, store it in publicGameData.CardData.definedCards");
		for cardID, cardConfig in pairs(game.Settings.Cards) do
			local strCardName = getCardName_fromObject(cardConfig);
			--print ("cardID=="..cardID..", cardName=="..strCardName..", #piecesRequired=="..cardConfig.NumPieces.."::");
			cards[cardID] = strCardName;
			count = count +1
		end
		printObjectDetails (cards, "card", count .." defined cards total");
		return cards;
	end
end

--given a card name, return it's cardID
function getCardID (strCardNameToMatch, game)
	--must have run getDefinedCardList first in order to populate Mod.PublicGameData.CardData
	local cards;
	--[[print ("[getCardID] match name=="..strCardNameToMatch.."::");
	print ("Mod.PublicGameData == nil --> "..tostring (Mod.PublicGameData == nil));
	print ("{} == nil --> "..tostring ({} == nil));
	print ("Mod.PublicGameData.CardData == nil --> "..tostring (Mod.PublicGameData.CardData == nil));
	print ("Mod.PublicGameData.CardData.definedCards == nil --> "..tostring (Mod.PublicGameData.CardData.definedCards == nil));
	print ("Mod.PublicGameData.CardData.CardPieceCardID == nil --> "..tostring (Mod.PublicGameData.CardData.CardPieceCardID == nil));]]
	if (Mod.PublicGameData.CardData.definedCards == nil) then
		--print ("run function");
		cards = getDefinedCardList (game);
	else
		--print ("get from pgd");
		cards = Mod.PublicGameData.CardData.definedCards;
	end

	--print ("[getCardID] tablelength=="..tablelength (cards));
	for cardID, strCardName in pairs(cards) do
		--print ("[getCardID] cardID=="..cardID..", cardName=="..strCardName.."::");
		if (strCardName == strCardNameToMatch) then
			print ("[getCardID] matching card cardID=="..cardID.."::");
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
    if cardConfig.proxyType == 'CardGameCustom' then
        return cardConfig.Name;
    end

    if cardConfig.proxyType == 'CardGameAbandon' then
        -- Abandon card was the original name of the Emergency Blockade card
        return 'Emergency Blockade card';
    end
    return cardConfig.proxyType:match("^CardGame(.*)");
end
--- END of krinid's functions