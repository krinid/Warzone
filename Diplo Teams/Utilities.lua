--Defined value representing that a player is not on a team; anything from 0 or higher is a team assignment
NoTeam = -1;

function map (array, func)
	local new_array = {};
	local i = 1;
	for _,v in pairs (array) do
		new_array [i] = func (v);
		i = i + 1;
	end
	return new_array;
end

function filter (array, func)
	local new_array = {};
	local i = 1;
	for _,v in pairs (array) do
		if (func (v)) then
			new_array [i] = v;
			i = i + 1;
		end
	end
	return new_array;
end

function first (array, func)
	for _,v in pairs (array) do
		if (func == nil or func (v)) then
			return v;
		end
	end
	return nil;
end

function contains (array, value)
	for _,v in pairs (array) do
		if (v == value) then
			return true;
		end
	end
	return false;
end

--Counts the entries in a table.  Works on tables that aren't arrays, where # can't be used.
function count (tbl)
	local ret = 0;
	for _ in pairs (tbl or {}) do
		ret = ret + 1;
	end
	return ret;
end

function sortedCopy(array)
	local ret = {};
	for _,v in pairs (array) do
		table.insert (ret, v);
	end
	table.sort (ret);
	return ret;
end

--Turns a list of strings into "Alice", "Alice and Bob", or "Alice, Bob and Carol"
function joinNames (names)
	local num = #names;
	if (num == 0) then return ''; end;
	if (num == 1) then return names [1]; end;

	local ret = '';
	for i,name in ipairs (names) do
		if (i == num) then
			ret = ret .. ', and ' .. name;
		elseif (i == 1) then
			ret = name;
		else
			ret = ret .. ', ' .. name;
		end
	end
	return ret;
end

function PlayerName (game, playerID)
	local player = game.Game.Players [playerID];
	if (player == nil) then return '[Unknown player]'; end;
	return player.DisplayName (nil, false);
end

--Describes a list of players, such as "Alice, Bob and Carol"
function PlayerNames (game, playerIDs)
	return joinNames (map(sortedCopy(playerIDs), function(pid) return PlayerName (game, pid); end));
end

--The team a player is on right now.  Note that GamePlayer.Team is only the team they started the game on, so we must ask the game with the latest standing since this mod changes teams mid-game.
function TeamOfPlayer (game, playerID, standing)
	return game.Game.PlayerTeam (playerID, standing);
end

--Everyone still playing that shares the given player's team, not counting the player themselves.  Returns an empty list if they're not on a team.
function TeammatesOf (game, playerID, standing)
	local team = TeamOfPlayer (game, playerID, standing);
	if (team == NoTeam) then return {}; end;

	local ret = {};
	for _,gp in pairs (game.Game.PlayingPlayers) do
		if (gp.ID ~= playerID and TeamOfPlayer (game, gp.ID, standing) == team) then
			table.insert (ret, gp.ID);
		end
	end
	return ret;
end

--Whether this game has any cards.  If it does, we warn players that cards belong to the team and don't follow a player who leaves it.
function GameHasCards (settings)
	return count (settings.Cards) > 0;
end

function toname (playerid, game)
	return game.ServerGame.Game.Players [playerid].DisplayName (nil, false);
end

function  tablelength (T)
	local count = 0;
	if(T==nil)then
		return 0;
	end
	for _, elem in pairs (T)do
		count = count + 1;
	end
	return count;
end

function getColours ()
    local colors = {}; -- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
	colors.WZyellow = "#ABA500"; colors.WZgreen = "#198225"; colors["WZLight Blue"] = "#50B2E3"; colors.WZblue = "#242D9A"; colors.WZred = "#9A2929";
    return colors;
end

function getColourCode (itemName)
    if (itemName=="card play heading" or itemName=="main heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
	elseif (itemName=="minor heading") then return "#00FFFF"; --cyan
	elseif (itemName=="ok") then return getColours()["Dark Green"]; --standard green used for "Ok" buttons
	elseif (itemName=="Button|Green") then return getColours()["WZgreen"]; --standard green used for "Ok" buttons
	elseif (itemName=="Button|Red") then return getColours()["WZred"]; --standard green used for "Ok" buttons
	elseif (itemName=="Button|Blue") then return getColours()["WZblue"]; --standard green used for "Ok" buttons
	elseif (itemName=="Button|Light Blue") then return getColours()["WZLight Blue"]; --standard green used for "Ok" buttons
	elseif (itemName=="Button|Yellow") then return getColours()["WZyellow"]; --standard green used for "Ok" buttons
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

function split (inputstr, sep)
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

function InWar (Player1, Player2)
	for _,pID in pairs (Mod.PublicGameData.War [Player1]) do
		-- print ("[WAR LIST] " ..tostring (Player1).." vs " ..tostring (Player2) .. " --> " ..tostring (pID == Player2));
		if (pID == Player2) then
			--both players are at war
			return true;
		end
	end
	return false;
end

--return true if both players are currently on the same team, false if not
function playersAreTeamMates (Player1, Player2, game, standing)
	--check if both players are on a team (not on NoTeam==-1) and if so if it's the same team
	return (TeamOfPlayer (game, Player1, standing) ~= NoTeam and TeamOfPlayer (game, Player2, standing) ~= NoTeam and TeamOfPlayer (game, Player1, standing) == TeamOfPlayer (game, Player2, standing));
end

function stringtochararray (variable)
	chartable = {};
	while (string.len (variable) >0) do
		chartable [tablelength(chartable)] = string.sub (variable, 1 , 1);
		variable = string.sub (variable, 2);
	end
	return chartable;
end

function stringtotable (variable)
	chartable = {};
	while (string.len (variable) >0) do
		chartable [tablelength (chartable)] = string.sub (variable, 1 , 1);
		variable = string.sub (variable, 2);
	end

	local newtable = {};
	local tablepos = 0;
	local executed = false;

	for _, elem in pairs (chartable) do
		if (elem == ",") then
			tablepos = tablepos + 1;
			newtable [tablepos] = "";
			executed = true;
		else
			if (executed == false) then
				tablepos = tablepos + 1;
				newtable [tablepos] = "";
				executed = true;
			end
			if (newtable [tablepos] == nil) then
				newtable [tablepos] = elem;
			else
				newtable [tablepos] = newtable [tablepos] .. elem;
			end
		end
	end
	return newtable;
end

function check (message,variable)
	local match = true;
	local mess = stringtochararray (message);
	local varchararray = stringtochararray (variable);
	local num = 0;
	while (varchararray [num] ~= nil) do
		if (mess [num] ~= varchararray [num]) then
			return false;
		end
		num = num + 1;
	end
	return match;
end