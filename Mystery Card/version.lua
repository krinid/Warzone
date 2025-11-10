-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/version

require('__mod');

local function isVersionOrHigher(version)
	return WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher(version);
end

local function err(msg)
	local alert = (UI and UI.Alert) or error;

	if type(alert) == 'function' then
		alert(msg);
	end
end

function canRunMod()
	-- for use on client hooks
	-- not needed in Client_PresentSettingsUI in AutoSettingsFiles due to checking for 5.21
	-- if is under 5.21 then UI.Destroy and UI.IsDestroyed are never called

	if isVersionOrHigher(MOD.clientVersion) then
		return true;
	end

	err('You must be running app version ' .. MOD.clientVersion .. ' at the minimum to use the mod "' .. MOD.name .. '". Check for updates.');

	return false;
end

function serverCanRunMod(game)
	-- for use on server hooks

	if game.Settings.SinglePlayer and not isVersionOrHigher(MOD.serverVersion) then
		-- in single player games the server is the client. client version of mod api framework might not be up to date
		err('You must be running app version ' .. MOD.serverVersion .. ' at the minimum to use the mod "' .. MOD.name .. '" in single player. Check for updates.');

		return false;
	end

	-- server always runs most up to date version of mod api framework
	return true;
end
