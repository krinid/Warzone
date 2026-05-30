require ("Buy_Cards_dialog");

function Client_PresentCommercePurchaseUI(rootParent, game, close)
	--don't show UI if local client player is a spectator
	if (game.Us.ID == nil) then return; end

	CloseWindow = close;
	Game = game;
	MainUI = UI.CreateVerticalLayoutGroup(rootParent);

	-- UI.CreateLabel(MainUI).SetText("[BUY CARDS]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("Use gold to buy cards enabled in this game template. Prices are set by the game host.");

	if(game.Us == nil) then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("You are not playing in this game, so menu is disabled");
		return;
	end
	if(game.Game.PlayingPlayers[game.Us.ID] == nil)then
		horz = UI.CreateHorizontalLayoutGroup(vert);
		UI.CreateLabel(horz).SetText("You have been eliminated, so menu is disabled");
		return;
	end

	buttonBuyCards = UI.CreateButton(MainUI).SetInteractable(true).SetText("Buy Cards").SetOnClick(BuyCardsButtonClicked).SetColor (getColours()["Dark Green"]);
end

function BuyCardsButtonClicked()
	-- buttonBuyCards.SetInteractable (false);
	UI.Destroy (buttonBuyCards);
	getDefinedCardList (Game);
	displayMenu (Game, MainUI, CloseWindow);
end