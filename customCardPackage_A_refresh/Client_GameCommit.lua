--require 'Client_GameCommit';

function Client_GameCommit (clientGame, skipCommit)
    --intCommitButtonPressed_count
    --^^don't make local; keep it global so the count persists during the client session
    if (intCommitButtonPressed_count==nil) then intCommitButtonPressed_count=0; end --nil -> never pressed yet, this is the first time, so let's set it to 0
    intCommitButtonPressed_count = intCommitButtonPressed_count + 1; --keep track of # of Commit presses
    print ("[GAME COMMIT] #presses "..intCommitButtonPressed_count.."::");

    --check if there is a pending Pestilence against the local client player; don't need to check if the player is active (etc), b/c this function only runs when Commit is pressed, which only Active players can do
    if ((Mod.PublicGameData.PestilenceData[clientGame.Us.ID] ~= nil) and (intCommitButtonPressed_count==1)) then
	--if Commit button as been pressed for 1st time and player has a pending Pestilence order, pop up the warning regardless of last time shown & cancel the Commit order
    --if they hit Commit a 2nd time, let it commit, player has been warned sufficiently
        if (checkForPendingPestilence == nil) then require 'Client_GameRefresh'; end
        skipCommit (); --skip commit, give player a chance to update moves to account for the Pestilence
        checkForPendingPestilence (clientGame, true); --forcibly popup the Pestilence warning dialog if there is one pending
        print ("[GAME COMMIT] Skip commit");
    else
        print ("[GAME COMMIT] don't Skip commit");
    end
    skipCommit (); --skip commit, give player a chance to update moves to account for the Pestilence
end