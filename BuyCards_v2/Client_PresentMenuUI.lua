require ("Buy_Cards_dialog");

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	local vert = UI.CreateVerticalLayoutGroup(rootParent);
	setMaxSize(400, 400);
	if (game.Settings.CommerceGame == false) then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("This mod cannot function in this game because it is not a Commerce game");
		return;
	end
	-- if(game.Us == nil) then
	-- 	horz = UI.CreateHorizontalLayoutGroup(vert);
	-- 	UI.CreateLabel(horz).SetText("You are not playing in this game, so menu is disabled");
	-- 	return;
	-- end
	-- if(game.Game.PlayingPlayers[game.Us.ID] == nil)then
	-- 	horz = UI.CreateHorizontalLayoutGroup(vert);
	-- 	UI.CreateLabel(horz).SetText("You have been eliminated, so menu is disabled");
	-- 	return;
	-- end

	UI.CreateLabel (vert).SetText ("[BUY CARDS]\n").SetColor (getColourCode("card play heading"));
	getDefinedCardList (game);
	displayMenu (game, vert, close);
end