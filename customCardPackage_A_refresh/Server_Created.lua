function Server_Created(game, settings)
    --displayAllCardsAndSettings(game, settings);
end

function displayAllCardsAndSettings (game, settings)

    print("All cards in the game:");
    
    for cardID, card in pairs(game.Settings.Cards) do
        if rawget(card, "Name") ~= nil then
            print ("Card Name: " .. card.Name);
            print ("-1-----------------------------------------------------------------------------");
            if rawget(card, "Name") == "Isolation" then
                print ("-2-----------------------------------------------------------------------------");
                print ("Isolation card found - IsStoredInActiveOrders="..tostring(card.IsStoredInActiveOrders));
                print ("Isolation card found - ActiveOrderDuration="..tostring(card.ActiveOrderDuration));
                card.IsStoredInActiveOrders = true;
                card.ActiveOrderDuration = 10;
                print ("Isolation card found - IsStoredInActiveOrders="..tostring(card.IsStoredInActiveOrders));
                print ("Isolation card found - ActiveOrderDuration="..tostring(card.ActiveOrderDuration));
            end
        end

        --this didn't work; the fields aren't writable
        -- --[[
        if (card.ID == 1000002) then
            print ("-3-----------------------------------------------------------------------------");
            print ("Isolation card found - IsStoredInActiveOrders="..tostring(card.IsStoredInActiveOrders));
            print ("Isolation card found - ActiveOrderDuration="..tostring(card.ActiveOrderDuration));
            --printObjectDetails(card.writableKeys, "Card");
            --[[
            --card.IsStoredInActiveOrders = true;
            card.ActiveOrderDuration = 10;
            print ("-4-----------------------------------------------------------------------------");
            print ("Isolation card found - IsStoredInActiveOrders="..tostring(card.IsStoredInActiveOrders));
            print ("Isolation card found - ActiveOrderDuration="..tostring(card.ActiveOrderDuration));
            ]]
        end
        --if card.Name ~= nil then
        --    print ("Card Name: " .. card.Name);
        --end
        -- ]]
        
        printObjectDetails(card, "Card");
        --[[print("Card ID: " .. cardID);
        print("ID: " .. card.ID);
        --print("Card Name: " .. card.Name);
        print("Card Description: " .. card.Description);
        print("Card Friendly Description: " .. card.FriendlyDescription);
        --print("Card Image: " .. card.ImageFilename);
        print("Card Weight: " .. card.Weight);
        print("Card NumPieces: " .. card.NumPieces);
        print("Card IsStoredInActiveOrders: " .. tostring(card.IsStoredInActiveOrders));
        print("Card ActiveOrderDuration: " .. card.ActiveOrderDuration);
        print("Card Initial Pieces: " .. card.InitialPieces);
        print("Card MinimumPiecesPerTurn: " .. card.MinimumPiecesPerTurn);
        ]]
--[[
ActiveCardExpireBehavior ActiveCardExpireBehaviorOptions (enum):
ActiveOrderDuration integer:
CardID CardID:
Description string:
FriendlyDescription string:
ID CardID:
InitialPieces integer:
IsStoredInActiveOrders boolean:
MinimumPiecesPerTurn integer:
NumPieces integer:
Weight number:
]]
end
    
    
    
    --[[
    local overriddenBonuses = {};

    settings.cardSettings = {};
    for _, bonus in pairs(game.Map.Bonuses) do
		--skip negative bonuses unless AllowNegative was checked
		if (bonus.Amount > 0 or Mod.Settings.AllowNegative) then 
			local rndAmount = math.random(-Mod.Settings.RandomizeAmount, Mod.Settings.RandomizeAmount);

			if (rndAmount ~= 0) then --don't do anything if we're not changing the bonus.  We could leave this check off and it would work, but it show up in Settings as an overridden bonus when it's not.

				local newValue = bonus.Amount + rndAmount;

				-- don't take a positive or zero bonus negative unless AllowNegative was checked.
				if (newValue < 0 and not Mod.Settings.AllowNegative) then
					newValue = 0;
				end

				-- -1000 to +1000 is the maximum allowed range for overridden bonuses, never go beyond that
				if (newValue < -1000) then newValue = -1000 end;
				if (newValue > 1000) then newValue = 1000 end;
		
				overriddenBonuses[bonus.ID] = newValue;
			end
		end
    end

    settings.OverriddenBonuses = overriddenBonuses;
]]
end