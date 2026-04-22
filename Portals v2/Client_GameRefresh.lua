function Client_GameRefresh (clientGame)
	print ("[CLIENT REFRESH]");
	-- if (clientGame == nil) then print ("[CLIENTGAME is nil]"); return; end
    -- if (clientGame.Us == nil) then print ("[CLIENTGAME.Us is nil]"); return; end --player is probably a spectator, do nothing, just return

	gameRefresh_Mod = Mod;
	gameRefresh_Game = clientGame;

	if (Portals == nil) then
		clientGame.SendGameCustomMessage ("[acquiring portal locations]", {action="getportals"}, function(PortalData) Portals = PortalData[1]; end); --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data; don't need any processing here, so it's an empty (throwaway) anonymous function
	end
end

function createBuyCardsWindow (rootParent, setMaxSize, setScrollable, game, close)
    setMaxSize(600, 600);
	local vert = UI.CreateVerticalLayoutGroup(rootParent);
	displayMenu (game, vert, close);
end