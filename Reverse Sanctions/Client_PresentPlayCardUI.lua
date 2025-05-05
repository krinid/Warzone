--Called when the player attempts to play your card.  You can call playCard directly if no UI is needed, or you can call game.CreateDialog to present the player with options.
function Client_PresentPlayCardUI (game, cardInstance, playCard)
    --when dealing with multiple cards in a single mod, observe game.Settings.Cards[cardInstance.CardID].Name to identify which one was played
    Game = game; --make client game object available globally

	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires playing a Card, which they can't do b/c they're not in the game)

    strPlayerName_cardPlayer = game.Us.DisplayName(nil, false);
    intPlayerID_cardPlayer = game.Us.PlayerID;
    strCardBeingPlayed = game.Settings.Cards[cardInstance.CardID].Name;
    print ("PLAY CARD="..strCardBeingPlayed.."::");

    if (strCardBeingPlayed=="Resurrection") then
        --UI.Alert ("Resurrection does not need to played. It is automatically activated by possessing it. If your Commander dies, this card will be consumed.");
        activate_Resurrection (game, cardInstance, playCard);
    else
        --a custom card not defined here has been played; do nothing; another mod will handle it
    end
end

function TargetCardClicked (strText, cards)
	UI.PromptFromList(strText, cards);
end

function activate_Resurrection (game, cardInstance, playCard)
    print("[RESURRECTION CARD PLAY] card play clicked, played by=" .. strPlayerName_cardPlayer .. "::");

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400, 300);
        local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1);
        UI.CreateLabel(vert).SetText("[RESURRECTION]\n\n").SetColor(getColourCode("card play heading"));

        if (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies == true and Mod.PublicGameData.ResurrectionData[game.Us.ID] == nil) then
            UI.CreateLabel(vert).SetText("Commander has died: ".. tostring (Mod.PublicGameData.ResurrectionData[game.Us.ID] ~= nil));
            UI.CreateLabel(vert).SetText("Commander must die to use card: ".. tostring (Mod.Settings.ResurrectionDisableCardPlayUntilCommanderDies));
            UI.CreateLabel(vert).SetText("\nYour Commander has not died, you cannot use this card at this time.");
            return;
        end

        TargetTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetOnClick(TargetTerritoryClicked);
        TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");
        TargetTerritoryClicked("Select the territory to resurrect your Commander to.");

        UI.CreateButton(vert).SetText("Play Card").SetOnClick(
        function()
            if (TargetTerritoryID == nil) then
                UI.Alert("No territory selected. Please select a territory.");
                return;
            end
            if (game.LatestStanding.Territories[TargetTerritoryID].OwnerPlayerID ~= game.Us.ID) then
                UI.Alert("You must select a territory you own.");
                return;
            end
            print ("[RESURRECTION CARD PLAY ACTIVATE] order input::terr=" .. TargetTerritoryName .. "::Resurrection|" .. TargetTerritoryID .. "::");

            playCard (strPlayerName_cardPlayer .. " resurrects a Commander on " .. TargetTerritoryName, 'Resurrection|' .. tostring (game.Us.ID) .. "|" .. TargetTerritoryID, WL.TurnPhase.CardsWearOff);
            close();
        end);
    end);
end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end

function play_cardPiece_card (game, cardInstance, playCard)
    local publicGameData = Mod.PublicGameData;
    local cards = nil;
    CardPieceCardID = cardInstance.CardID; --ensure player doesn't redeem Card Piece cards/pieces; esp if redeem amount is >1 whole card, this results in receiving infinite turn-over-turn card/piece quantities

    print ("[PLAY CARD - CARD PIECE] "..CardPieceCardID.."::"); --/".. cards[CardPieceCardID] .. "//");

    cards = getDefinedCardList (game);

    print ("(cards==nil) --> "..tostring (cards==nil));
    print ("tablelength (cards) --> ".. tablelength (cards));

    --[[for k,v in pairs(cards) do
        print (k,v);
    end]]

    print ("[PLAY CARD - CARD PIECE] "..CardPieceCardID.."/".. cards[CardPieceCardID] .. "//".. game.Settings.Cards[CardPieceCardID].NumPieces);


    local strPrompt = "Select a card type to receive cards/pieces of:"

    game.CreateDialog(
    function(rootParent, setMaxSize, setScrollable, game, close)
        setMaxSize(400,300);
        local vert = CreateVert(rootParent).SetFlexibleWidth(1);
        CreateLabel(vert).SetText("[CARD PIECES]\n\n"..strPrompt).SetColor(getColourCode("card play heading"));
        TargetCardButton = CreateButton (vert).SetText("Select card...").SetOnClick(function() CardPiece_CardSelection_clicked (strPrompt, cards, playCard, close) end);
    end);
end

function TargetPlayerClicked_Fizz(strText)
	local options = map(filter(Game.Game.Players, IsPotentialTarget), PlayerButton);
	UI.PromptFromList(strText, options);
end

--Determines if the player is one we can propose an alliance to.
function IsPotentialTarget(player)
	if (Game.Us.ID == player.ID) then return false end; -- can't select self

	if (player.State ~= WL.GamePlayerState.Playing) then return false end; --skip players not alive anymore, or that declined the game

	--if (Game.Settings.SinglePlayer) then return true end; --in single player, allow proposing with everyone
    --return not player.IsAI; --In multi-player, never allow proposing with an AI.
    return (player.State == WL.GamePlayerState.Playing); --return true if they are still playing, false otherwise
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function() 
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end

function TargetTerritoryClicked(strLabelText) --TargetTerritoryInstructionLabel, TargetTerritoryBtn)
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	if strLabelText ~= nil then TargetTerritoryInstructionLabel.SetText(strLabelText); end --strLabelText==nil indicates that the label wasn't specified, reason is b/c was already applied in a previous operation, that this is a re-select of a territory, so no need to reapply the label as it's already there
	TargetTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	if (UI.IsDestroyed (TargetTerritoryBtn)) then return; end --if the button was destroyed, don't try to set it interactable, do nothing, just return
    TargetTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		TargetTerritoryID = nil;
        TargetTerritoryName = nil;
	else
		--Territory was clicked, remember its ID
		TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name);
		TargetTerritoryID = terrDetails.ID;
        TargetTerritoryName = terrDetails.Name;
	end
end

function TargetPlayerClicked(strTextLabel)
	local players = filter(Game.Game.Players, function (p) return p.ID ~= Game.Us.ID end);
	local options = map(players, PlayerButton);
	UI.PromptFromList(strTextLabel, options);
end

function PlayerButton(player)
	local name = player.DisplayName(nil, false);
	local ret = {};
	ret["text"] = name;
	ret["selected"] = function()
		TargetPlayerBtn.SetText(name);
		TargetPlayerID = player.ID;
	end
	return ret;
end