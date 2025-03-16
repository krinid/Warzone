function Server_AdvanceTurn_End(game, addNewOrder)
	--uncomment the below line to forcibly halt execution for troubleshooting purposes
	--print ("[FORCIBLY HALTED EXEUCTION @ END OF TURN]"); toriaezu_stop_execution();
	print ("[GRACEFUL END OF TURN EXECUTION]");
end

function Server_AdvanceTurn_Start (game,addNewOrder)
	--delete all AI orders
	for k,v in pairs (game.ServerGame.ActiveTurnOrders) do
		print (k, v.__proxyID, v);--.." "..v.proxyType);--.. "player "..v.PlayerID);
		printObjectDetails (v);

	--for _,playerID in pairs(game.ServerGame.Game.PlayingPlayers) do
      	--[[if (playerID.ID <= 50) then
			for _,order in pairs(game.ServerGame.ActiveTurnOrders[playerID.ID]) do
				--print ("[S_AT_S] ORDER="..order.proxyType.."::");

				if(order.proxyType=='GameOrderPlayCardCustom') then
					--print ("[S_AT_S] ORDER=GameOrderPlayCardCustom::");
					print ("[S_AT_S] ORDER=GameOrderPlayCardCustom::modData="..order.ModData.."::");
					local strArrayModData = split(order.ModData,'|');
					local strCardTypeBeingPlayed = strArrayModData[1];
					print ("[S_AT_S] CUSTOM CARD PLAY, type="..strCardTypeBeingPlayed..":: BUT IGNORE THIS - handle it in TurnAdvance_Order");
				end
			end
		end]]
	--end
	end

	-- game.ServerGame.ActiveTurnOrders[1] = {}; -- doesn't work
	-- neither does this:
	--[[newboy = game.ServerGame.ActiveTurnOrders;
	newboy [1] = {};
	game.ServerGame.ActiveTurnOrders = newboy;]]
end

function Server_AdvanceTurn_Order(game, order, result, skip, addNewOrder)
	print ("proxyType "..order.proxyType, tostring (order), order.__proxyID);
	if (order.proxyType ~= "GameOrderCustom") then return; end --only inspect custom game orders (proxy type GameOrderCustom)
	local strArrayOrderData = split(order.Payload,'|');

	--for reference:
	--local strForcedOrder = "ForceOrder|AttackTransfer|"..targetPlayer.."|"..gameOrder.From.."|"..gameOrder.To.."|"..gameOrder.NumArmies.NumArmies;

	if (strArrayOrderData[1] ~= "ForcedOrders") then return; end --if this isn't an order for ForcedOrders, don't process anything, just exit

	--currently only process AttackTransfers; only handles raw armies, no Special Units, which will be removed from any orders
	if (strArrayOrderData[2] == "AttackTransfer") then
		print ("[FORCE ORDER] prep - "..order.Payload);
		local numArmies = WL.Armies.Create(strArrayOrderData[8], {});
		print ("[FORCE ORDER] start - "..order.Payload);
		local forcedAttackTransfer = WL.GameOrderAttackTransfer.Create(strArrayOrderData[3], strArrayOrderData[4], strArrayOrderData[5], tonumber (strArrayOrderData[6]), toboolean (strArrayOrderData[7]), numArmies, toboolean (strArrayOrderData[9]));
		--reference: replacementOrder = WL.GameOrderAttackTransfer.Create(targetPlayer, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, gameOrder.NumArmies, gameOrder.AttackTeammates);
		print ("[FORCE ORDER] pre - "..order.Payload);
		addNewOrder (forcedAttackTransfer);
		print ("[FORCE ORDER] post - "..order.Payload);
	end
end

function toboolean (value)
    if value == nil or value == false or value == "false" then
        return false
    else
        return true
    end
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
					print("  [readablekeys_table] pointer "..tostring (value)..", key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue))
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
					print("  [writablekeys_table] pointer=="..tostring (value)..", key#==" .. key .. ":: key==" .. tostring(value) .. ":: value==" .. tableToString(propertyValue)) -- *** this is the last line of output that successfully executes
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
					print("[base_table] pointer=="..tostring (value)..", key==" .. tostring(key) .. ":: value==" .. tableToString(value))
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

function tableToString(tbl, indent)
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

--[[function tableToString(tbl)
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

function tablelength(T)
	local count = 0;
	if (T==nil) then return 0; end
	if (type(T) ~= "table") then return 0; end
	for _ in pairs(T) do count = count + 1 end
	return count
end	