require ("Buy_Cards_dialog");

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	gameRefresh_Game = game;
	gameRefresh_Mod = Mod;
	print ("PMUI gameRefresh_Game==nil " ..tostring (gameRefresh_Game==nil));

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

	--debug data for error in game https://www.warzone.com/MultiPlayer?GameID=42876634
	if (game.Us ~= nil and game.Us.ID == 1058239) then
		game.CreateDialog (showDebugWindow); --show Debug Window to output debug data to
	end
end

function showDebugWindow (rootParent, setMaxSize, setScrollable, game, close)
    setMaxSize(600, 600);
    --setScrollable(true);
	UIdebugWindow = rootParent;
	UI.CreateLabel (UIdebugWindow).SetText ("[DEBUG DATA]").SetColor (getColourCode("card play heading"));
	UI.CreateLabel (UIdebugWindow).SetText ("Nothing to populate yet");
end
