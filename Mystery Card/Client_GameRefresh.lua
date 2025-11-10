require('tblprint');
require('__mod');
require('ui');

local DIALOG;

function Client_GameRefresh(game)
	-- players might be unable to play cards if using old version because of new client hooks added
	-- limiting max notifications per turn could be unreliable if there are multiple mods
	-- because of refreshes happening at unexpected times

	local isVersionOrHigher = WL and WL.IsVersionOrHigher;
	local canUseCustomCards = isVersionOrHigher and isVersionOrHigher(MOD.clientVersion);

	if canUseCustomCards then
		return;
	end

	createDialog(game);
end

function createDialog(game)
	-- dialog preferred over alert because alert cannot be used reliably if other mods use alert
	-- this dialog should only be displayed once at any given time

	if DIALOG then
		DIALOG.close();
	end

	local dialog = {};

	game.CreateDialog(function(rootParent, setMaxSize, setScrollable, clientGame, close)
		setMaxSize(350, 200);
		setScrollable(false, true);

		local vert = Vert(rootParent);

		Label(vert).SetColor('#ff0000').SetText('You must be running app version ' .. MOD.clientVersion .. ' at the minimum to use the mod "' .. MOD.name .. '" or else you may be unable to play Mystery Cards. Check for updates.');

		dialog.close = close;
	end);

	DIALOG = dialog;
end
