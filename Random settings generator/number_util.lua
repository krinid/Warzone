-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/lua_util

function round(n, dp)
	-- http://lua-users.org/wiki/SimpleRound
	local multi = 10 ^ (dp or 0);

	return math.floor((n * multi + 0.5)) / multi;
end