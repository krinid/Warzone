require('tblprint');
require('ui');
require('version');

-- local doingSinglePlayerTesting = false;

function Client_PresentMenuUI(RootParent, setMaxSize, setScrollable, Game, close)
	-- print('init Client_PresentMenuUI');

	rootParent = RootParent;
	game = Game;

	setMaxSize(480, 270);-- 16:9 on 30

	-- let players experiment in single player
	-- if game.Settings.SinglePlayer and not doingSinglePlayerTesting then
		-- Label(rootParent).SetText('This mod is designed to only be used in multiplayer games.');
		-- return;
	-- end

	if not game.Us then
		Label(rootParent).SetText('You must have joined the game to access the menu of this mod.');
		return;
	end

	if game.Game.State ~= WL.GameState.Playing then
		Label(rootParent).SetText('The menu of this mod can only be accessed after distribution and before the game ends.');
		return;
	end

	makeMenu();
end

function playerIsNotTeamed(player)
	if player.Team == -1 then
		return true;
	end

	return Mod.PublicGameData.teams[player.Team] == 1;
end

function makeMenu(stored, vert)
	if not canRunMod() then
		return;
	end

	print('init makeMenu');

	if not stored then
		stored = Mod.PlayerGameData;
	end

	print('stored = ');
	tblprint(stored);

	if not UI.IsDestroyed(vert) then
		UI.Destroy(vert);
	end

	vert = Vert(rootParent);

	local startedBy = game.Settings.StartedBy;
	local weAreHost = game.Us.ID == startedBy;

	if weAreHost and playerIsNotTeamed(game.Us) then
		makeHostMenu(stored, vert);
	elseif weAreHost then
		Label(vert).SetText('You can only use this mod if you are not teamed up with anyone else, otherwise your team would get an unfair advantage by seeing everything.');
	else
		if startedBy then
			local host = game.Game.Players[startedBy];

			if host and playerIsNotTeamed(host) then
				Label(vert).SetText('The host can eliminate any player they like whenever they want. The host also spies on everyone (and neutral depending on Spy Card settings. This is to discourage collusion (making alliances etc.) in games that are meant to be actual FFAs for example.');
				Label(vert).SetText('If the host abuses this mod, you should avoid joining their games in future.');
			else
				Label(vert).SetText('This mod would allow the host to eliminate players whenever they want and spy on everyone if the host joined the game and was not in a team themselves.');
			end
		else
			Label(vert).SetText('Nobody can use this mod because the game was created by the Warzone servers.');
		end
	end
end

function makeHostMenu(stored, vert)
	print('init makeHostMenu');

	local infoBtn = Btn(vert).SetText('Info');
	local vert2 = Vert(vert);
	local vert3 = nil;

	infoBtn.SetOnClick(function()
		infoBtn.SetInteractable(false);

		if not UI.IsDestroyed(vert3) then
			UI.Destroy(vert3);
			infoBtn.SetInteractable(true);
			return;
		end

		vert3 = Vert(vert2);

		Label(vert3).SetText('As you are the host, you can eliminate anyone and spy on all players (and neutral depending on Spy Card settings).');
		Label(vert3).SetText('So that this game remains in your Dashboard, you are immune from elimination (but not from being booted). Any orders that affect your territories will be skipped.');
		Label(vert3).SetText('When it becomes only you and another player left, you should surrender.');

		infoBtn.SetInteractable(true);
	end);

	Label(vert).SetText('Eliminate:');

	for playerId in pairs(game.Game.PlayingPlayers) do
		if playerId ~= game.Us.ID then
			displayPlayer(stored, vert, playerId);
		end
	end
end

function displayPlayer(stored, vert, playerId)
	print('init displayPlayer');
	print('playerId = ' .. playerId);

	local player = game.Game.PlayingPlayers[playerId];
	local horz = Horz(vert);
	local checkbox = Checkbox(horz)
		.SetText('')
		.SetIsChecked(not not stored.eliminating[playerId]);
	checkbox.SetOnValueChanged(function()
		checkbox.SetInteractable(false);
		print('about to call game.SendGameCustomMessage');
		game.SendGameCustomMessage('Updating...', {
			toEliminate = playerId,
			shouldEliminate = checkbox.GetIsChecked()
		}, function(newStorage)
			print('heard back from GameCustomMessage');
			makeMenu(newStorage, vert);
		end);
	end);

	Label(horz)
		.SetText(player.DisplayName(nil, false))
		.SetColor(player.Color.HtmlColor);

	local viewTerrsBtn = Btn(horz).SetText('Territories');

	viewTerrsBtn.SetOnClick(function()
		viewTerrsBtn.SetInteractable(false);
		viewTerritories(playerId);
		viewTerrsBtn.SetInteractable(true);
	end);
end

function viewTerritories(playerId)
	local terrs = {};

	for terrId, terr in pairs(game.LatestStanding.Territories) do
		if terr.OwnerPlayerID == playerId then
			table.insert(terrs, terrId);
		end
	end

	game.HighlightTerritories(terrs);
end
