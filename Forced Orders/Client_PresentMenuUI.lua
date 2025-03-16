function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
    --global variable 'boolInputMovesForAI'
    if (boolInputMovesForAI==nil or boolInputMovesForAI==false) then
        boolInputMovesForAI = true; --if DNE or is set to false, define to true (default to true or toggle from false to true)
        targetPlayer = 1; --input moves for AI1 instead of local player
    else
        boolInputMovesForAI = false; --toggle from true to false
        targetPlayer = game.Us.ID; --moves are created normally, by local player
    end

    UIcontainer = UI.CreateVerticalLayoutGroup (rootParent);
    UI.CreateLabel (UIcontainer).SetText ("Moves will be inputted for player: "..targetPlayer);
    print ("Moves will be inputted for player: "..targetPlayer);
end