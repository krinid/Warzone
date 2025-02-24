function Client_GameCommit (clientGame, skipCommit)
    --intCommitButtonPressed_count
    --^^don't make local; keep it global so the count persists during the client session
    if (intTurnNumberOfLastClick==nil) then intTurnNumberOfLastClick=clientGame.Game.TurnNumber; end --capture the turn# of the last click, and if turn# has increased, reset the click count so clicks from prior turns don't count towards warnings for successive turns
    if (intCommitButtonPressed_count==nil or intTurnNumberOfLastClick<clientGame.Game.TurnNumber) then intCommitButtonPressed_count=0; end --nil -> never pressed yet, this is the first time, so let's set it to 0
    --if (Mod.PublicGameData.ResurrectionData[clientGame.Us.ID] ~= clientGame.Game.TurnNumber) then intCommitButtonPressed_count = 0; end --if the turnNumber has already surpassed the turn where the warning is meant to occur, restart the count (actually this won't ever be useful)
    intCommitButtonPressed_count = intCommitButtonPressed_count + 1; --keep track of # of Commit presses
    intTurnNumberOfLastClick = clientGame.Game.TurnNumber;
    print ("[GAME COMMIT] #presses "..intCommitButtonPressed_count.." ["..tostring(intTurnNumberOfLastClick) .."] ::");

    if (clientGame.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires clicking Commit, which they can't do b/c they're not in the game)

    --check if there is a pending Resurrection for the local client player; don't need to check if the player is active (etc), b/c this function only runs when Commit is pressed, which only Active players can do
    if (Mod.PublicGameData.ResurrectionData ~= nil) then
        if ((Mod.PublicGameData.ResurrectionData[clientGame.Us.ID] ~= nil) and (intCommitButtonPressed_count==1)) then
        --if Commit button as been pressed for 1st time and player has a pending Resurrection order, pop up the warning regardless of last time shown & cancel the Commit order
        --if they hit Commit a 2nd time, let it commit, player has been warned sufficiently
            if (popupWarning_toPlayResurrectionCard == nil) then require 'Client_GameRefresh'; end
            skipCommit (); --skip commit, give player a chance to update moves to account for the Resurrection
            popupWarning_toPlayResurrectionCard (clientGame, true); --forcibly popup the Resurrection warning dialog if there is one pending
            print ("[GAME COMMIT] Skip commit");
        else
            print ("[GAME COMMIT] don't Skip commit");
        end
    end
end