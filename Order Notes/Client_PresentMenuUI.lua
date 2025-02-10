require('tblprint');
require('ui');
require('placeOrderInCorrectPosition');
require('version');

local WIDTH = 800;
local HEIGHT = 190;

--[[text gets shrunk when inputting, so limit note size so that it doesnt shrink 2024-04-29]]
local CHARLIMIT = 50;

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	if not canRunMod() then
		return;
	end

	setMaxSize(WIDTH, HEIGHT);
	setScrollable(false, true);

	main(rootParent, nil, game);
end

function main(rootParent, vert, game)
	if not UI.IsDestroyed(vert) then
		UI.Destroy(vert);
	end

	vert = Vert(rootParent);

	if game.Game.State ~= WL.GameState.Playing then
		Label(vert).SetText('You can not use this mod because the game is not in-progress');

		return;
	end

	if not game.Us or (game.Us and game.Us.State ~= WL.GamePlayerState.Playing) then
		Label(vert).SetText('You can not use this mod because you are not in this game');

		return;
	end

	local horz = Horz(vert)
		.SetPreferredWidth(WIDTH)
		.SetFlexibleWidth(1);

	Label(horz).SetText('Note');
	Label(horz).SetText(' | ');

	local orderNotesSubmitBtn = Btn(horz);
	local orderNotesTextInput = TextInput(vert);

	orderNotesSubmitBtn
		.SetText('Add note')
		.SetOnClick(function ()
			orderNotesSubmitBtn.SetInteractable(false);
			orderNotesTextInput.SetInteractable(false);

			local txt = orderNotesTextInput.GetText();

			orderNotesTextInput.SetText('');

			if (#txt < #('A')) or (#txt > CHARLIMIT) then
				orderNotesTextInput.SetInteractable(true);
				orderNotesSubmitBtn.SetInteractable(true);

				return;
			end

			local order = WL.GameOrderCustom.Create(game.Us.PlayerID, txt, 'OrderNotes');

			placeOrderInCorrectPosition(game, order);

			orderNotesTextInput.SetInteractable(true);
			orderNotesSubmitBtn.SetInteractable(true);
		end);

	orderNotesTextInput
		.SetPlaceholderText('Enter note here; max ' .. tostring(CHARLIMIT) .. ' characters')
		.SetCharacterLimit(CHARLIMIT)
		.SetPreferredWidth(WIDTH)
		--[[.SetPreferredHeight(HEIGHT)]]
		.SetFlexibleWidth(1)
		--[[.SetFlexibleHeight(1);]]

--[[
	local i = 1;
	local str = '';

	while i < CHARLIMIT + 1 do
		local n = tostring(i);
		n = n:sub(#n, #n);

		str = str .. n;
		i = i + 1;
	end

	orderNotesTextInput.SetText(str);
	Label(mainVert).SetText(str);
]]
end