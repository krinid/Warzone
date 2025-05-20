Alerted = false;

function Client_GameRefresh(game)
	if(game.Us == nil)then
		return;
	end
	
  	if (not Alerted and not WL.IsVersionOrHigher or not WL.IsVersionOrHigher("5.22")) then
		UI.Alert("You must update your app to the latest version to use this mod!");
        Alerted = true;
	end
end
