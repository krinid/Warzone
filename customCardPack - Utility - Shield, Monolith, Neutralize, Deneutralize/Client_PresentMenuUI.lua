require("UI_Events");
require("utilities");
require("DataConverter");

--used only for testing purposes, this menu has no in-game functional purpose at this point in time
function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function
    Game = game; --global variable to use in other functions in this code 

    if game == nil then 		print('ClientGame is nil'); 	end
	if game.LatestStanding == nil then 		print('ClientGame.LatestStanding is nil'); 	end
	if game.LatestStanding.Cards == nil then 		print('ClientGame.LatestStanding.Cards is nil'); 	end
	if game.Us == nil then 		print('ClientGame.Us is nil'); 	end
	if game.Settings == nil then 		print('ClientGame.Settings is nil'); 	end
	if game.Settings.Cards == nil then 		print('ClientGame.Settings.Cards is nil'); 	end

	if (Mod.PublicGameData.Debug == nil) then 	game.SendGameCustomMessage ("[initializing debug info on server]", {action="initializedebug"}, function() end); end --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data; don't need any processing here, so it's an empty (throwaway) anonymous function
	--game.SendGameCustomMessage ("[initializing debug info on server]", {action="initializedebug"}, function() end); --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data; don't need any processing here, so it's an empty (throwaway) anonymous function	

	displayDebugInfoFromServer (game); --display (in Mod Log output window) debug info stored by server hooks

	MenuWindow = rootParent;
	local debugPanel = UI.CreateVerticalLayoutGroup (MenuWindow);
	TopLabel = CreateLabel (MenuWindow).SetFlexibleWidth(1).SetText ("[Testing/Debug information only]\n\n");

	--debug info for debug authorized user only
	if (Mod.PublicGameData.Debug ~= nil and Mod.PublicGameData.Debug.DebugUser ~= nil and game.Us.ID == Mod.PublicGameData.Debug.DebugUser) then
		--put debug panel here
		debugButton = UI.CreateButton (debugPanel).SetText ("Debug mode active: "..tostring (Mod.PublicGameData.Debug.DebugMode)).SetOnClick (debugModeButtonClick);
	end

	create_UnitInspectorMenu ();

    TopLabel.SetText (TopLabel.GetText() .. ("Active Modules: "));
    local moduleCount = 0;
    if (Mod.Settings.ActiveModules ~= nil) then
        for k,v in pairs (Mod.Settings.ActiveModules) do
            moduleCount = moduleCount + 1;
            if (moduleCount > 1) then TopLabel.SetText (TopLabel.GetText() ..", "); end
            TopLabel.SetText (TopLabel.GetText() ..k);
        end
    else
        TopLabel.SetText (TopLabel.GetText() .."[old template - ActiveModules not present]");
    end

    print ("LOCAL CLIENT ORDERS SO FAR:");
    for k,gameOrder in pairs (game.Orders) do
        print (k..", "..gameOrder.proxyType);
        if (gameOrder.proxyType == "GameOrderAttackTransfer") then
            print ("player "..gameOrder.PlayerID..", FROM "..gameOrder.From..", TO "..gameOrder.To..", AttackTransfer "..tostring (gameOrder.AttackTransfer)..", ByPercent "..tostring(gameOrder.ByPercent).. ", #armies"..gameOrder.NumArmies.NumArmies..", #SUs "..#gameOrder.NumArmies.SpecialUnits..", AttackTeammates "..tostring (gameOrder.AttackTeammates));
        end
    end

    --debugging test criteria; for games where Mod.Settings.ActiveModules is properly defined, this should print JUMBO, then PUCHI, then JUMBO, and none cause an error/halt execution
   	-- if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Pestilence == true) then print ("jumbo"); else print ("puchi"); end --if Pestilence isn't active for this mod, do nothing, just return
    -- if (Mod.Settings.ERROROUT ~= nil and Mod.Settings.ERROROUT.ERROROUT2 == true) then print ("jumbo"); else print ("puchi"); end --if Pestilence isn't active for this mod, do nothing, just return
    -- if (Mod.Settings.ERROROUT == nil or Mod.Settings.ERROROUT.ERROROUT2 == true) then print ("jumbo"); else print ("puchi"); end --if Pestilence isn't active for this mod, do nothing, just return

    TopLabel.SetText (TopLabel.GetText() .. ("\n\nServer time: "..game.Game.ServerTime));
	if (game.Us~=nil) then --a player in the game
		TopLabel.SetText (TopLabel.GetText() .. "\n\nClient player "..game.Us.ID .."/"..toPlayerName (game.Us.ID, game)..", State: "..tostring(game.Game.Players[game.Us.ID].State).."/"..tostring(WLplayerStates ()[game.Game.Players[game.Us.ID].State]).. ", IsActive: "..tostring(game.Game.Players[game.Us.ID].State == WL.GamePlayerState.Playing).. ", IsHost: "..tostring(game.Us.ID == game.Settings.StartedBy));
	else
		--client local player is a Spectator, don't reference game.Us which ==nil
		TopLabel.SetText (TopLabel.GetText() .. "\n\nClient player is Spectator");
	end

	TopLabel.SetText (TopLabel.GetText() .. ("\n\nGame host: "..game.Settings.StartedBy.."/".. toPlayerName(game.Settings.StartedBy, game)));

	TopLabel.SetText (TopLabel.GetText() .. ("\n\nPlayers in the game:"));
	for k,v in pairs (game.Game.Players) do
		local strPlayerIsHost = "";
		if (k == game.Settings.StartedBy) then strPlayerIsHost = " [HOST]"; end
		TopLabel.SetText (TopLabel.GetText() .. "\nPlayer "..k .."/"..toPlayerName (k, game)..", State: "..tostring(v.State).."/"..tostring(WLplayerStates ()[v.State]).. ", IsActive: "..tostring(game.Game.Players[k].State == WL.GamePlayerState.Playing) .. strPlayerIsHost);
	end

	--this shows all Global Functions! wow
	--[[for i, v in pairs(_G) do
		print(i, v);
	end]]

    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardBlock == true) then showCardBlockData (); end
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Isolation == true) then showIsolationData (); end
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Quicksand == true) then showQuicksandData (); end
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Earthquake == true) then showEarthquakeData (); end
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.Pestilence == true) then showPestilenceData (); end
	--showNeutralizeData (); --can't do this b/c NeutralizeData is in PrivateGameData --> can't view in Client hook

	showDefinedCards (game);
end

--send message to Server hook to toggle debug mode and save result in Mod.PublicGameData
function debugModeButtonClick ()
	Game.SendGameCustomMessage ("[toggling debug mode]", {action="debugmodetoggle"}, debugModeButtonClick_callback); --last param is callback function which gets called by Server_GameCustomMessage and sends it a table of data
end

--return value is a 1 element table of value true/false indicating whether debugMode is active
function debugModeButtonClick_callback (tableData)
	debugButton.SetText ("Debug mode active: "..tostring (tableData[1]));
	-- debugButton.SetText ("Debug mode active: "..tostring (Mod.PublicGameData.Debug.DebugMode));
end

--not actually used; but keep it around as an example of how to use/return data using clientGame.SendGameCustomMessage
function PresentMenuUI_callBack (table)
    for k,v in pairs (table) do
        print ("[C_PMUI] "..k,v);
        CreateLabel (MenuWindow).SetText ("[C_PMUI] "..k.."/"..v);
    end
end

function showNeutralizeData ()
    CreateLabel (MenuWindow).SetText ("\nNeutralize data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PrivateGameData.NeutralizeData));
    for k,v in pairs (Mod.PrivateGameData.NeutralizeData) do
        printObjectDetails (v,"record", "NeutralizeData");
        CreateLabel (MenuWindow).SetText (tostring(k)..", " ..tostring(v.territory)..", " ..tostring(v.castingPlayer)..", "..tostring(v.impactedTerritoryOwnerID)..", " .. tostring(v.turnNumber_NeutralizationExpires).. ", ".. tostring(v.specialUnitID));
    end
	--for reference: local neutralizeDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberToRevert=turnNumber_NeutralizationExpires, specialUnitID=specialUnit_Neutralize.ID};
end

function showEarthquakeData ()
    CreateLabel (MenuWindow).SetText ("\nEarthquake data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PublicGameData.EarthquakeData));
    for k,v in pairs (Mod.PublicGameData.EarthquakeData) do
        printObjectDetails (v,"record", "EarthquakeData");
        CreateLabel (MenuWindow).SetText (tostring(k)..", " ..tostring(v.targetBonus)..", " ..tostring(v.castingPlayer)..", "..tostring(v.turnNumberEarthquakeEnds));
    end
    --for reference: publicGameData.EarthquakeData[targetBonusID] = {targetBonus = targetBonusID, castingPlayer = gameOrder.PlayerID, turnNumberEarthquakeEnds = turnNumber_EarthquakeExpires};
end

function showCardBlockData ()
    CreateLabel (MenuWindow).SetText ("\nCard Block data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PublicGameData.CardBlockData));
    for k,v in pairs (Mod.PublicGameData.CardBlockData) do
        printObjectDetails (v,"record", "CardBlockData");
        CreateLabel (MenuWindow).SetText (k..", " ..v.castingPlayer..", "..v.turnNumberBlockEnds);
        --for reference: local record = {targetPlayer = targetPlayerID, castingPlayer = gameOrder.PlayerID, turnNumberBlockEnds = turnNumber_CardBlockExpires}; --create record to save data on impacted player, casting player & end turn of Card Block impact
    end
end

function showQuicksandData ()
    CreateLabel (MenuWindow).SetText ("\nQuicksand data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PublicGameData.QuicksandData));
    CreateLabel (MenuWindow).SetText ("AttackerDamageTakenModifier: "..Mod.Settings.QuicksandAttackerDamageTakenModifier);
    CreateLabel (MenuWindow).SetText ("DefenderDamageTakenModifier: "..Mod.Settings.QuicksandDefenderDamageTakenModifier);

	if (tablelength (Mod.PublicGameData.QuicksandData)) == 0 then CreateLabel (MenuWindow).SetText ("QuicksandData is empty"); return; end

    for k,v in pairs (Mod.PublicGameData.QuicksandData) do
        printObjectDetails (v,"record", "QuicksandData");
        CreateLabel (MenuWindow).SetText (k..", " ..tostring (v.territory).."/"..getTerritoryName (v.territory, Game) ..", "..tostring (v.castingPlayer).. ", "..tostring (v.territoryOwner).. ", ".. tostring (v.turnNumberQuicksandEnds) .. ", "..tostring (v.specialUnitID));
        --CreateLabel (MenuWindow).SetText (k..", " ..v.territory.."/"..getTerritoryName (v.territory, game)..", "..v.castingPlayer.. ", "..v.territoryOwner.. ", ".. v.turnNumberQuicksandEnds);
        --for reference: local QuicksandDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberQuicksandEnds=turnNumber_QuicksandExpires, specialUnitID=specialUnit_Quicksand.ID};---&&&
    end
end

function showPestilenceData ()
    CreateLabel (MenuWindow).SetText ("\nPestilence data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PublicGameData.PestilenceData));

	if (tablelength (Mod.PublicGameData.PestilenceData)) == 0 then CreateLabel (MenuWindow).SetText ("PestilenceData is empty"); return; end

    for k,v in pairs (Mod.PublicGameData.PestilenceData) do
        --printObjectDetails (v,"record", "PestilenceData");
        CreateLabel (MenuWindow).SetText ("["..k.."] target " ..v.targetPlayer.."/"..toPlayerName (v.targetPlayer, Game)..", caster "..v.castingPlayer.."/"..toPlayerName (v.castingPlayer, Game)..", warning T"..v.PestilenceWarningTurn..", Start T"..v.PestilenceStartTurn..", End T"..v.PestilenceEndTurn);
		--for reference: publicGameData.PestilenceData [pestilenceTarget_playerID] = {targetPlayer=pestilenceTarget_playerID, castingPlayer=gameOrder.PlayerID, PestilenceWarningTurn=PestilenceWarningTurn, PestilenceStartTurn=PestilenceStartTurn, PestilenceEndTurn=PestilenceEndTurn};

    end
end

function showIsolationData ()
    CreateLabel (MenuWindow).SetText ("\nIsolation data:");
    CreateLabel (MenuWindow).SetText ("# records==".. tablelength (Mod.PublicGameData.IsolationData));

	CreateLabel (MenuWindow).SetText ("Isolated territories:");
    if (tablelength (Mod.PublicGameData.IsolationData)) == 0 then CreateLabel (MenuWindow).SetText ("IsolationData is empty"); return; end

    for k,v in pairs (Mod.PublicGameData.IsolationData) do
        printObjectDetails (v,"record", "IsolationData");
        --CreateLabel (MenuWindow).SetText (k..", " ..v.territory.."/".."?"..", "..v.castingPlayer.. ", "..v.territoryOwner.. ", ".. v.turnNumberIsolationEnds);
        CreateLabel (MenuWindow).SetText (k..", " ..v.territory.."/"..getTerritoryName (v.territory, Game)..", "..v.castingPlayer.. ", "..v.territoryOwner.. ", ".. v.turnNumberIsolationEnds);
        --for reference: local IsolationDataRecord = {territory=targetTerritoryID, castingPlayer=castingPlayerID, territoryOwner=impactedTerritoryOwnerID, turnNumberIsolationEnds=turnNumber_IsolationExpires, specialUnitID=specialUnit_Isolation.ID};---&&&
    end
end

function showDefinedCards (game)
    --print ("[PresentMenuUI] CARD OVERVIEW");
    --game.SendGameCustomMessage ("[waiting for server response]", {action="initialize_CardData"}, PresentMenuUI_callBack);

    local cards = getDefinedCardList (game);
    local CardPiecesCardID = Mod.PublicGameData.CardData.CardPiecesCardID;

    local strText = "";
    for k,v in pairs (cards) do
        strText = strText .. "\n"..v.." / ["..k.."]";
    end

    strText = TopLabel.GetText() .. "\n\nDEFINED CARDS:"..strText;
    if (Mod.Settings.ActiveModules ~= nil and Mod.Settings.ActiveModules.CardPieces == true) then strText = strText .. "\n\nCardPieceCardID=="..CardPiecesCardID; end
    TopLabel.SetText (strText.."\n");
end

function create_UnitInspectorMenu ()
	Game.CreateDialog (populateUnitInspectorMenu); --user friendly Unit Inspector
	Game.CreateDialog (unitInspectorMenu);         --comprehensive Unit Inspector
end

function createDialogWindow ()
	return (Game.CreateDialog (createDialogWindow_interface));
end

function createDialogWindow_interface (rootParent, setMaxSize, setScrollable, game, close)
	return (rootParent);
end

function tableIsEmpty(t)
	for _, _ in pairs(t) do
		return false;
	end
	return true;
end

function unitInspectorMenu (rootParent, setMaxSize, setScrollable, game, close)
    setMaxSize(800, 600);
    --setScrollable(true);

	local UIdisplay = UI.CreateVerticalLayoutGroup (rootParent);
	UI.CreateLabel(UIdisplay).SetText("[UNIT INSPECTOR]").SetColor(getColourCode("main heading"));

	for _,terr in pairs (game.LatestStanding.Territories) do
		--print ("terr.ID=="..terr.ID..", #specials==".. (#terr.NumArmies.SpecialUnits));
		local boolCurrentTerritoryHeaderDisplayed = false;
		local numSpecialsOnTerritory = 0;
		if (#terr.NumArmies.SpecialUnits >= 1) then
			for _,specialUnit in pairs (terr.NumArmies.SpecialUnits) do
				numSpecialsOnTerritory = numSpecialsOnTerritory + 1;
				if (boolCurrentTerritoryHeaderDisplayed == false) then
					UI.CreateLabel (UIdisplay).SetText ("\n["..terr.ID.. "/"..	game.Map.Territories[terr.ID].Name.."] Attack Power "..game.LatestStanding.Territories[terr.ID].NumArmies.AttackPower..", Defense Power "..game.LatestStanding.Territories[terr.ID].NumArmies.DefensePower..
						", #Armies ".. game.LatestStanding.Territories[terr.ID].NumArmies.NumArmies ..", #Special Units ".. #game.LatestStanding.Territories[terr.ID].NumArmies.SpecialUnits).SetColor(getColourCode("subheading")); 
					boolCurrentTerritoryHeaderDisplayed = true;
				end
				if (numSpecialsOnTerritory>1) then UI.CreateLabel (UIdisplay).SetText (" "); end --spacer between SUs, but don't leave space between territory heading and 1st SU
				UI.CreateLabel (UIdisplay).SetText ("<"..numSpecialsOnTerritory.."> "..specialUnit.proxyType..", owner "..specialUnit.OwnerID.."/"..getPlayerName (game, specialUnit.OwnerID)..", ID="..specialUnit.ID).SetColor (getColourCode("minor heading"));

				if (specialUnit.proxyType == "Commander") then
					--reference: displaySpecialUnitProperties (UIcontrol, name, attackPower, attackPowerPercentage, defensePower, defensePowerPercentage, damageToKill, damageAbsorbedWhenAttacked, health, combatOrder, canBeGifted, canBeTransferredToTeammate, canBeAirliftedToTeammate, isVisibleToAllPlayers, modData)
					displaySpecialUnitProperties (UIdisplay, "Commander", 7, nil, 7, nil, 7, 0, nil, 10000, false, false, false, true, false, nil);
				elseif (specialUnit.proxyType == "Boss3") then
					displaySpecialUnitProperties (UIdisplay, "Boss3", specialUnit.Power, nil, specialUnit.Power, nil, specialUnit.Power, 0, nil, 10000, false, false, false, true, false, "Stage "..specialUnit.Stage.." of 3");
				elseif (specialUnit.proxyType == "CustomSpecialUnit") then
					displaySpecialUnitProperties (UIdisplay, specialUnit.Name, specialUnit.AttackPower, specialUnit.AttackPowerPercentage, specialUnit.DefensePower, specialUnit.DefensePowerPercentage, specialUnit.DamageToKill, specialUnit.DamageAbsorbedWhenAttacked, specialUnit.Health, specialUnit.CombatOrder, specialUnit.CanBeGiftedWithGiftCard, specialUnit.CanBeTransferredToTeammate, specialUnit.CanBeAirliftedToTeammate, specialUnit.CanBeAirliftedToSelf, specialUnit.IsVisibleToAllPlayers, getUnitDescription (specialUnit));
				else
					CreateLabel(UIdisplay).SetText("unknown unit type").SetColor(colors["Orange Red"]);
				end
			end
		end
	end
end

function displaySpecialUnitProperties (UIcontrol, name, attackPower, attackPowerPercentage, defensePower, defensePowerPercentage, damageToKill, damageAbsorbedWhenAttacked, health, combatOrder, canBeGifted, canBeTransferredToTeammate, canBeAirliftedToTeammate, canBeAirliftedToSelf, isVisibleToAllPlayers, modData)
	UI.CreateLabel (UIcontrol).SetText ("    Name: "..tostring(name)).SetColor ("#FFFFFF");
	UI.CreateLabel (UIcontrol).SetText ("    Attack -- Power: "..tostring(attackPower)..", modifier factor: "..tostring(attackPowerPercentage));
	UI.CreateLabel (UIcontrol).SetText ("    Defense -- Power: "..tostring(defensePower)..", modifier factor: "..tostring(defensePowerPercentage));
	UI.CreateLabel (UIcontrol).SetText ("    Damage to kill: "..tostring(damageToKill)..", Health: "..tostring(health));
	UI.CreateLabel (UIcontrol).SetText ("    Damage absorbed when attacked: "..tostring (damageAbsorbedWhenAttacked)..", Combat order: "..tostring(combatOrder));
	UI.CreateLabel (UIcontrol).SetText ("    Can be gifted: "..tostring(canBeGifted)..", can be airlifted to self: "..tostring(canBeAirliftedToSelf));
	UI.CreateLabel (UIcontrol).SetText ("    Teammate actions -- can be transferred: "..tostring(canBeTransferredToTeammate)..", can be airlifted: "..tostring(canBeAirliftedToTeammate));
	UI.CreateLabel (UIcontrol).SetText ("    Visible to all players: "..tostring(isVisibleToAllPlayers));
	UI.CreateLabel (UIcontrol).SetText ("    Mod data: "..tostring(modData));
end

function populateUnitInspectorMenu (rootParent, setMaxSize, setScrollable, game, close)
    setMaxSize(600, 600);
    --setScrollable(true);
	UnitInspectorRoot = rootParent;
	inspectToolInUse = true;

	--UnitInspector_selectorRoot = nil;
	vertTerritoryInfoAndUnitInspectorList = nil;
	UnitInspector_UnitInfoRoot = nil;
	UnitInspector_CombatOrderRoot = nil;
	CurrentDisplayRoot = UnitInspectorRoot;
	colors = GetColors();

    local vert = UI.CreateVerticalLayoutGroup(UnitInspectorRoot).SetFlexibleWidth(1).SetCenter(false);
	UI.CreateLabel(vert).SetText("[UNIT INSPECTOR]\n\n").SetColor(getColourCode("card play heading"));

	--CreateLabel(vert).SetText("\n\nClick a territory to inspect it").SetColor(colors.TextColor);

	inspectToolInUse = true;
	--if (UI.IsDestroyed (UnitInspector_TerritorySelectButton)==true) then strButtonText = "Select another Territory"; end
	--UnitInspector_TerritorySelectButton = CreateButton(vert).SetText("Select another Territory").SetColor(colors.Cyan).SetFlexibleWidth(1).SetOnClick(function () Game.CreateDialog (populateUnitInspectorMenu); end);
	UnitInspector_TerritorySelectButton = CreateButton(vert).SetText("Click on a territory to inspect it").SetColor(colors.Cyan).SetFlexibleWidth(1).SetOnClick(function () Game.CreateDialog (populateUnitInspectorMenu); end);
	CreateButton(vert).SetText("Show combat order of visible Special Units").SetColor(colors.Orange).SetFlexibleWidth(1).SetOnClick(function() showCombatOrder(nil, nil, nil); end);
	UI.InterceptNextTerritoryClick(UnitInspector_clickedTerr);
end

function UnitInspector_clickedTerr(terrDetails)
	if terrDetails == nil or not inspectToolInUse or UI.IsDestroyed(UnitInspectorRoot) then return WL.CancelClickIntercept; end
	if (not UI.IsDestroyed(vertTerritoryInfoAndUnitInspectorList)) then UI.Destroy (vertTerritoryInfoAndUnitInspectorList); end
	vertTerritoryInfoAndUnitInspectorList = UI.CreateVerticalLayoutGroup(UnitInspectorRoot).SetFlexibleWidth(1);
	CurrentDisplayRoot = vertTerritoryInfoAndUnitInspectorList;
	UI.CreateLabel(vertTerritoryInfoAndUnitInspectorList).SetText(" "); --vertical spacer
	local line = UI.CreateHorizontalLayoutGroup (vertTerritoryInfoAndUnitInspectorList);
	UI.CreateLabel(line).SetText("INSPECTING Territory: ");
	UI.CreateLabel(line).SetText(terrDetails.ID .. "/" .. terrDetails.Name).SetColor ("#00FF00");
	UI.CreateLabel(vertTerritoryInfoAndUnitInspectorList).SetText("    Attack Power: ".. Game.LatestStanding.Territories[terrDetails.ID].NumArmies.AttackPower .. ", Defense Power: " .. Game.LatestStanding.Territories[terrDetails.ID].NumArmies.DefensePower..
		"\n    Units present -- Armies: ".. Game.LatestStanding.Territories[terrDetails.ID].NumArmies.NumArmies..", Special Units: "..#Game.LatestStanding.Territories[terrDetails.ID].NumArmies.SpecialUnits).SetColor(colors.TextColor);
	local sps = Game.LatestStanding.Territories[terrDetails.ID].NumArmies.SpecialUnits;
	if not tableIsEmpty(sps) then
		UnitInspector_TerritorySelectButton.SetText ("Click to select a different Territory to inspect");
		pickUnitOfList(sps);
		if (#sps == 1) then inspectUnit(sps[1], nil); end
	else
		--DestroyWindow();
		--SetWindow("NoUnitFound");

		--CreateButton(UnitInspectorRoot).SetText("Return").SetColor(colors.Orange).SetOnClick(function() inspectToolInUse = false; showMainMenu(); end);
		CreateLabel(UnitInspectorRoot).SetText("\n[There are no Special Units on this territory]").SetColor(colors.TextColor);
	end
end

function pickUnitOfList(list)
	--DestroyWindow();
	--UnitInspector_selectorRoot = createDialogWindow();
	--CurrentDisplayRoot = UnitInspector_selectorRoot;
	CurrentDisplayRoot = UnitInspectorRoot;
	UI.CreateLabel (CurrentDisplayRoot).SetText("\nSelect one of the Special Units to inspect:").SetFlexibleWidth(1).SetColor(colors.TextColor);

	--CreateButton(CurrentDisplayRoot).SetText("Return").SetColor(colors.Orange).SetOnClick(populateUnitInspectorMenu);
	CreateEmpty(CurrentDisplayRoot).SetPreferredHeight(5);
	for _, sp in pairs(list) do
		CreateButton(CurrentDisplayRoot).SetText(getUnitName(sp)).SetFlexibleWidth(1).SetColor(getOwnerColor(sp)).SetOnClick(function() inspectUnit(sp, function() pickUnitOfList(list); end); end)
	end
end

function inspectUnit_Window (rootParent, setMaxSize, setScrollable, game, close)
	UnitInspector_UnitInfoRoot = rootParent;
	setMaxSize(600, 600);
	CurrentDisplayRoot = UnitInspector_UnitInfoRoot;
end

function inspectUnit(sp, callback)
	--DestroyWindow();
	--local inspectUnitsOnTerritoryRoot = createDialogWindow();
	Game.CreateDialog (inspectUnit_Window);

	local line = CreateHorz(CurrentDisplayRoot).SetFlexibleWidth(1);
	CreateEmpty(line).SetFlexibleWidth(0.33);
	--CreateButton(line).SetText("Return").SetColor(colors.Orange).SetOnClick(callback);
	CreateEmpty(line).SetFlexibleWidth(0.33);
	CreateButton(line).SetText("Combat Order").SetColor(colors.Orange).SetOnClick(function() showCombatOrder(function() inspectUnit(sp, callback--[[, UnitInspectorRoot]]); end, sp); end);
	CreateEmpty(line).SetFlexibleWidth(0.33);
	CreateEmpty(CurrentDisplayRoot).SetPreferredHeight(5);

	line = CreateHorz(CurrentDisplayRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Unit type: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(getReadableString(sp.proxyType)).SetColor(colors.Tan);
	line = CreateHorz(CurrentDisplayRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Owner: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(getPlayerName(Game, sp.OwnerID)).SetColor(colors.Tan);
	if sp.proxyType == "CustomSpecialUnit" then
		inspectCustomUnit(sp, CurrentDisplayRoot);
	else
		inspectNormalUnit(sp, CurrentDisplayRoot);
	end
end

function inspectCustomUnit(sp, UnitInspectorRoot)

	local line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Name: ").SetColor(colors.TextColor);
	if sp.Name ~= nil then
		CreateLabel(line).SetText(sp.Name).SetColor(colors.Tan);
	else
		CreateLabel(line).SetText("None").SetColor(colors.Tan);
	end

	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Uses health: ").SetColor(colors.TextColor);
	if sp.Health ~= nil then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Health remaining: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.Health).SetColor(colors.Cyan);

		
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Damage needed to kill: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.DamageToKill).SetColor(colors.Cyan);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Damage absorbed when damage is sustained: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.DamageAbsorbedWhenAttacked).SetColor(colors.Cyan);
		
	end
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Attack Power: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(truncateDecimals (sp.AttackPower, 2)).SetColor(colors.Cyan);

	--line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("   Defense Power: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(truncateDecimals (sp.DefensePower, 2)).SetColor(colors.Cyan);
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Attack power modifier: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(truncateDecimals (math.floor((sp.AttackPowerPercentage * 10000) + 0.5) / 100 - 100, 2) .. "%").SetColor(colors.Cyan);

	--line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("   Defense power modifier: ").SetColor(colors.TextColor);
	CreateLabel(line).SetText(truncateDecimals (math.floor((sp.DefensePowerPercentage * 10000) + 0.5) / 100 - 100, 2) .. "%").SetColor(colors.Cyan);
	CreateLabel(UnitInspectorRoot).SetText("(modifies the kill ratios used for battles this Special Unit participates in)");
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Permanently visible to all players: ").SetColor(colors.TextColor);
	if sp.IsVisibleToAllPlayers then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
	end
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Can be airlifted -- to self: ").SetColor(colors.TextColor);
	-- createLabel_TrueFalse_YesNo_GreenRed (line, sp.CanBeAirliftedToSelf);
	if sp.CanBeAirliftedToSelf then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
	end
	
	--line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("   -- to teammates: ").SetColor(colors.TextColor);
	createLabel_TrueFalse_YesNo_GreenRed (line, sp.CanBeAirliftedToTeammate);
	if sp.CanBeAirliftedToTeammate then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
	end
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Giftable using gift card: ").SetColor(colors.TextColor);
	if sp.CanBeGiftedWithGiftCard then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
	end
	
	--line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("    Transferrable to teammates: ").SetColor(colors.TextColor);
	if sp.CanBeTransferredToTeammate then
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else
		CreateLabel(line).SetText("No").SetColor(colors.Red);
	end
	
	line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
	CreateLabel(line).SetText("Description: ").SetColor(colors.TextColor);
	CreateLabel(UnitInspectorRoot).SetText(getUnitDescription(sp)).SetColor(colors.Tan);

end

--given 'result' (true/false) create label on container 'line' with text Yes in green or No in red respectively
function createLabel_TrueFalse_YesNo_GreenRed (line, result)
	if (result) then CreateLabel(line).SetText("Yes").SetColor(colors.Green);
	else CreateLabel(line).SetText("No").SetColor(colors.Red); end
end

function inspectNormalUnit(sp, UnitInspectorRoot)
	if sp.proxyType == "Commander" then
		local line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Attack damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("7").SetColor(colors.Cyan);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Defense damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("7").SetColor(colors.Cyan);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Takes damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be airlifted: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be airlifted to teammates: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be transferred to teammates: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be gifted: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Is visible to all players: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Special features: ").SetColor(colors.TextColor);
		CreateLabel(UnitInspectorRoot).SetText("When this unit dies, " .. getPlayerName(Game, sp.OwnerID) .. " is eliminated immediately").SetColor(colors.Tan);
	
	elseif sp.proxyType == "Boss3" then
		
		local line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Stage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.Stage .. " / 3").SetColor(colors.Cyan);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Attack damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.Power).SetColor(colors.Cyan);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("defense damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText(sp.Power).SetColor(colors.Cyan);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Takes damage: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be airlifted: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("Yes").SetColor(colors.Green);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be airlifted to teammates: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be transferred to teammates: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Can be gifted: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);
		
		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Is visible to all players: ").SetColor(colors.TextColor);
		CreateLabel(line).SetText("No").SetColor(colors.Red);

		line = CreateHorz(UnitInspectorRoot).SetFlexibleWidth(1);
		CreateLabel(line).SetText("Special features: ").SetColor(colors.TextColor);
		if sp.Stage == 3 then
			CreateLabel(UnitInspectorRoot).SetText("When this unit is killed in an attack, it will NOT split into 4 smaller bosses. This unit is in it's last stage").SetColor(colors.Tan);
		else
			CreateLabel(UnitInspectorRoot).SetText("When this unit is killed in an attack, it will split into 4 bosses with " .. sp.Power - 10 .. " health. These 4 bosses are randomly spawned at nearby territories, no matter who controls it. Only territories with a commander immune for this").SetColor(colors.Tan);
		end
	else
		CreateLabel(UnitInspectorRoot).SetText("This unit has not been implemented yet. Please contact me and tell me the unit type so I can implement it").SetColor(colors["Orange Red"]);
	end
end

function showCombatOrder_Window (rootParent, setMaxSize, setScrollable, game, close)
	UnitInspector_CombatOrderRoot = rootParent;
	setMaxSize (600, 600);
	CurrentDisplayRoot = UnitInspector_CombatOrderRoot;
end

function showCombatOrder(callback, sp, UnitInspectorRoot)
	--DestroyWindow();
	--SetWindow("CombatOrder");
	Game.CreateDialog (showCombatOrder_Window);
	--CreateButton(UnitInspectorRoot).SetText("Return").SetColor(colors.Orange).SetOnClick(callback);

	local order = {[0] = {Units = {"Normal army"}, Positions = {}}};
	for _, terr in pairs(Game.LatestStanding.Territories) do
		if not tableIsEmpty(terr.NumArmies.SpecialUnits) then
			for _, unit in pairs(terr.NumArmies.SpecialUnits) do
				if order[unit.CombatOrder] == nil then order[unit.CombatOrder] = {}; order[unit.CombatOrder].Units = {}; order[unit.CombatOrder].Positions = {}; end
				table.insert(order[unit.CombatOrder].Units, unit);
				if not valueInTable(order[unit.CombatOrder], terr.ID) then
					table.insert(order[unit.CombatOrder].Positions, terr.ID);
				end
			end
		end
	end

	local cos = {};
	local t = {};
	for co, arr in pairs(order) do
		local i = 1;
		for i2, v in pairs(cos) do
			if v > co then
				break;
			end
			i = i + 1;
		end
		table.insert(cos, i, co);
		arr.CombatOrder = co;
		table.insert(t, i, arr);
	end
	order = t;

	CreateEmpty(CurrentDisplayRoot).SetPreferredHeight(10);
	CreateLabel(CurrentDisplayRoot).SetText("This is the order in which units take damage. Note that the units listed below are only the ones visible to you, there might be units hidden by the fog").SetColor(colors.TextColor);

	local c = 1;
	for _, arr in pairs(order) do
		local line = CreateHorz(CurrentDisplayRoot).SetFlexibleWidth(1);
		if sp ~= nil and arr.CombatOrder == sp.CombatOrder then
			CreateLabel(line).SetText(c .. ". ").SetColor(colors.Green);
		else
			CreateLabel(line).SetText(c .. ". ").SetColor(colors.TextColor);
		end
		
		local t = {};
		for _, unit in pairs(arr.Units) do
			if not valueInTable(t, getUnitName(unit)) then
				table.insert(t, getUnitName(unit));
			end
		end
		local label = CreateLabel(line).SetText(table.concat(t, ", "));
		if sp ~= nil and arr.CombatOrder == sp.CombatOrder then
			label.SetColor(colors.Green);
		else
			label.SetColor("#EEEEEE");
		end
		CreateEmpty(line).SetFlexibleWidth(1);
		CreateButton(line).SetText("Where?").SetColor(colors.Blue).SetOnClick(function() Game.HighlightTerritories(arr.Positions) for _, terrID in pairs(arr.Positions) do Game.CreateLocatorCircle(Game.Map.Territories[terrID].MiddlePointX, Game.Map.Territories[terrID].MiddlePointY); end; end);
		
		c = c + 1;
	end
end

function getUnitName(sp)
	if type(sp) == type("") then return sp; end
	if sp.proxyType == "CustomSpecialUnit" then
		if (sp.Health==nil) then return sp.Name or "[No name]";
		else return (sp.Name .. " [health "..sp.Health.."]" or "[No name]"); end
	else
		return getReadableString(sp.proxyType);
	end
end

function getReadableString(s)
	local ret = string.upper(string.sub(s, 1, 1));
	for i = 2, #s do
		local c = string.sub(s, i, i);
		if c ~= string.lower(c) or tonumber(c) ~= nil then
			ret = ret .. " " .. string.lower(c);
		else
			ret = ret .. c;
		end
	end
	return ret;
end

function getOwnerColor(sp)
	if sp.OwnerID ~= WL.PlayerID.Neutral then
		return Game.Game.Players[sp.OwnerID].Color.HtmlColor;
	else
		return colors.TextColor;
	end
end

---Returns a table with all available colors for buttons
---@return table<string, string>
---```
--- --Stores the table in a global variable to allow access to it everywhere
--- colors = GetColors();
--- print(colors.Blue);     -- Prints "#0000FF"
---```
function GetColors()
    local colors = {};					-- Stores all the built-in colors (player colors only)
    colors.Blue = "#0000FF"; colors.Purple = "#59009D"; colors.Orange = "#FF7D00"; colors["Dark Gray"] = "#606060"; colors["Hot Pink"] = "#FF697A"; colors["Sea Green"] = "#00FF8C"; colors.Teal = "#009B9D"; colors["Dark Magenta"] = "#AC0059"; colors.Yellow = "#FFFF00"; colors.Ivory = "#FEFF9B"; colors["Electric Purple"] = "#B70AFF"; colors["Deep Pink"] = "#FF00B1"; colors.Aqua = "#4EFFFF"; colors["Dark Green"] = "#008000"; colors.Red = "#FF0000"; colors.Green = "#00FF05"; colors["Saddle Brown"] = "#94652E"; colors["Orange Red"] = "#FF4700"; colors["Light Blue"] = "#23A0FF"; colors.Orchid = "#FF87FF"; colors.Brown = "#943E3E"; colors["Copper Rose"] = "#AD7E7E"; colors.Tan = "#FFAF56"; colors.Lime = "#8EBE57"; colors["Tyrian Purple"] = "#990024"; colors["Mardi Gras"] = "#880085"; colors["Royal Blue"] = "#4169E1"; colors["Wild Strawberry"] = "#FF43A4"; colors["Smoky Black"] = "#100C08"; colors.Goldenrod = "#DAA520"; colors.Cyan = "#00FFFF"; colors.Artichoke = "#8F9779"; colors["Rain Forest"] = "#00755E"; colors.Peach = "#FFE5B4"; colors["Apple Green"] = "#8DB600"; colors.Viridian = "#40826D"; colors.Mahogany = "#C04000"; colors["Pink Lace"] = "#FFDDF4"; colors.Bronze = "#CD7F32"; colors["Wood Brown"] = "#C19A6B"; colors.Tuscany = "#C09999"; colors["Acid Green"] = "#B0BF1A"; colors.Amazon = "#3B7A57"; colors["Army Green"] = "#4B5320"; colors["Donkey Brown"] = "#664C28"; colors.Cordovan = "#893F45"; colors.Cinnamon = "#D2691E"; colors.Charcoal = "#36454F"; colors.Fuchsia = "#FF00FF"; colors["Screamin' Green"] = "#76FF7A"; colors.TextColor = "#DDDDDD";
    return colors;
end

function getPlayerName_Dutch_useUtilitiesVersionInstead(playerID)
	if playerID ~= WL.PlayerID.Neutral then
		return Game.Game.Players[playerID].DisplayName(nil, true);
	else
		return "Neutral";
	end
end

function getUnitDescription_causesCrashWithDragons (sp) --(why? happens even with native Essentials mod itself)
	if sp.ModData ~= nil then
		-- print("Has mod data");
		-- print (sp.ModData);
		local data = DataConverter.StringToData(sp.ModData);
		if data.Essentials ~= nil and data.Essentials.UnitDescription ~= nil then
			return subtitudeData(sp, data, tostring(data.Essentials.UnitDescription));
		elseif data.UnitDescription ~= nil then		-- Old version (V0)
			return subtitudeData(sp, data, tostring(data.UnitDescription));
		else
			return "This unit does not have a unit description.";
		end
		print("Has no unit description");
	end
	return "This unit does not have a description. Please read the mod description of the mod that created this unit to get to know more about it";
end

function getUnitDescription(sp)
	if sp.ModData ~= nil then
		--print("Has mod data");
		-- local data = DataConverter.StringToData(sp.ModData);
		-- if data.Essentials ~= nil and data.Essentials.UnitDescription ~= nil then
		-- 	return subtitudeData(sp, data, tostring(data.Essentials.UnitDescription));
		-- elseif data.UnitDescription ~= nil then		-- Old version (V0)
		-- 	return subtitudeData(sp, data, tostring(data.UnitDescription));
		-- else
		-- 	return sp.ModData;
		-- 	--return "This unit does not have a unit description.";
		-- end
		-- print("Has no unit description");
		return sp.ModData;
	end
	return "This unit does not have a description. Please read the mod description of the mod that created this unit to get to know more about it";
end

function subtitudeData(sp, data, text)
	local commandMap = {
		Health = function(n) return tostring(sp.Health); end,
		Player = function(n) 
						if sp.OwnerID == WL.PlayerID.Neutral then return "Neutral"; end
						for pID, p in pairs(Game.Game.Players) do
							if pID == sp.OwnerID then
								return p.DisplayName(nil, false);
							end
						end
						return "Player"
					end,
		DefensePower = function(n) return tostring(sp.DefensePower); end,
		AttackPower = function(n) return tostring(sp.AttackPower); end,
		DamageToKill = function(n) return tostring(sp.DamageToKill); end,
		DamageAbsorbedWhenAttacked = function(n) return tostring(sp.DamageAbsorbedWhenAttacked); end,
		DefensePowerPercentage = function(n) return tostring(round(sp.DefensePowerPercentage, 2)); end,
		AttackPowerPercentage = function(n) return tostring(round(sp.AttackPowerPercentage, 2)); end,
		CombatOrder = function(n) return tostring(sp.CombatOrder); end,
		Name = function(n) return tostring(sp.Name); end,
		TextOverHeadOpt = function(n) return tostring(sp.TextOverHeadOpt); end
	};

	for name, f in pairs(commandMap) do
		-- print("{{" .. name .. "}}");
		text = string.gsub(text, "{{" .. name .. "}}", f);
	end

	local limit = 100;
	while string.find(text, "{{[%w/]+}}") do
		local start, ending = string.find(text, "{{[%w/]+}}");
		if start ~= nil or ending ~= nil then 
			local path = string.sub(text, start + 2, ending - 2);
			if path ~= nil then 
				local pathComponents = split(path, "/");
				if pathComponents ~= nil then 
					local v = data;
					for _, component in ipairs(pathComponents) do
						if v[component] == nil then break; end
						v = v[component];
					end
					if v ~= nil and v ~= data then 
						text = string.gsub(text, "{{" .. path .."}}", tostring(v));
					end
				end
			end
		end
		if string.find(text, "{{[%w/]+}}") == start then
			text = string.gsub(text, "{{[%w/]+}}", "[nil]", 1);
		end
		limit = limit - 1;
		if limit == 0 then break; end
	end

	return text;
end

--[[
card data:
846: 18 cards total
846: [PresentMenuUI] CARD OVERVIEW
846: [PresentMenuUI] CARD OVERVIEW
846: 1
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDA9
846:   [readablekeys_value] key#==1:: key==FriendlyDescription:: value==Play this card to gain an extra 5 armies
846:   [readablekeys_value] key#==2:: key==CardID:: value==1
846:   [readablekeys_value] key#==3:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==4:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==5:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==6:: key==Description:: value==In 3 pieces for 5 armies (minimum 1 piece per turn, starts with 8 pieces)
846:   [readablekeys_value] key#==7:: key==Mode:: value==0
846:   [readablekeys_value] key#==8:: key==FixedArmies:: value==5
846:   [readablekeys_value] key#==9:: key==ProgressivePercentage:: value==0
846:   [readablekeys_value] key#==10:: key==ID:: value==1
846:   [readablekeys_value] key#==11:: key==NumPieces:: value==3
846:   [readablekeys_value] key#==12:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==13:: key==InitialPieces:: value==8
846:   [readablekeys_value] key#==14:: key==Weight:: value==1
846:   [readablekeys_value] key#==15:: key==proxyType:: value==CardGameReinforcement
846:   [readablekeys_value] key#==16:: key==readonly:: value==true
846:   [readablekeys_table] key#==17:: key==readableKeys:: value=={  1 = FriendlyDescription,  2 = CardID,  3 = IsStoredInActiveOrders,  4 = ActiveOrderDuration,  5 = ActiveCardExpireBehavior,  6 = Description,  7 = Mode,  8 = FixedArmies,  9 = ProgressivePercentage,  10 = ID,  11 = NumPieces,  12 = MinimumPiecesPerTurn,  13 = InitialPieces,  14 = Weight,  15 = proxyType,  16 = readonly,  17 = readableKeys,  18 = writableKeys,}
846:   [readablekeys_table] key#==18:: key==writableKeys:: value=={  1 = Mode,  2 = FixedArmies,  3 = ProgressivePercentage,  4 = NumPieces,  5 = MinimumPiecesPerTurn,  6 = InitialPieces,  7 = Weight,}
846:   [writablekeys_value] key#==1:: key==Mode:: value==0
846:   [writablekeys_value] key#==2:: key==FixedArmies:: value==5
846:   [writablekeys_value] key#==3:: key==ProgressivePercentage:: value==0
846:   [writablekeys_value] key#==4:: key==NumPieces:: value==3
846:   [writablekeys_value] key#==5:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==6:: key==InitialPieces:: value==8
846:   [writablekeys_value] key#==7:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221749
846: 1000013	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDB9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Start a forest fire that spreads each turn
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==10
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000013
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 20 pieces Start a forest fire that spreads each turn (minimum 1 piece per turn, starts with 111 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Forest Fire
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Start a forest fire that spreads each turn
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==forest fire_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==10
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000013
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==20
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==111
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Forest Fire
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Start a forest fire that spreads each turn
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==forest fire_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==10
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==20
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==111
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221750
846: 1000012	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDC9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Launch an attack on a territory that you don't need to border
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000012
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 19 pieces Launch an attack on a territory that you don't need to border (minimum 1 piece per turn, starts with 110 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Airstrike
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Launch an attack on a territory that you don't need to border
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==airstrike_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==-1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000012
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==19
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==110
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Airstrike
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Launch an attack on a territory that you don't need to border
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==airstrike_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==-1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==19
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==110
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221751
846: 1000011	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDD9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Take ownership of a neutral territory. This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000011
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 14 pieces Take ownership of a neutral territory. This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card). (minimum 1 piece per turn, starts with 105 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Deneutralize
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Take ownership of a neutral territory. This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==deneutralize_greenback2_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==-1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000011
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==14
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==105
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Deneutralize
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Take ownership of a neutral territory. This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==deneutralize_greenback2_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==-1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==14
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==105
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221752
846: 1000010	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDE9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Turn a territory owned by a player to neutral for 3 turns. If it is still neutral at that time, it will revert ownership to the prior owner.

Territories with commanders or other special units can be targeted.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==3
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000010
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 13 pieces Turn a territory owned by a player to neutral for 3 turns. If it is still neutral at that time, it will revert ownership to the prior owner.

Territories with commanders or other special units can be targeted. (minimum 1 piece per turn, starts with 114 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Neutralize
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Turn a territory owned by a player to neutral for 3 turns. If it is still neutral at that time, it will revert ownership to the prior owner.

Territories with commanders or other special units can be targeted.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==neutralize_greyback2_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==3
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000010
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==13
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==114
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Neutralize
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Turn a territory owned by a player to neutral for 3 turns. If it is still neutral at that time, it will revert ownership to the prior owner.

Territories with commanders or other special units can be targeted.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==neutralize_greyback2_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==3
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==13
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==114
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221753
846: 6
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFDF9
846:   [readablekeys_value] key#==1:: key==FriendlyDescription:: value==Play this card to do a one-time transfer between any two of your territories.
846:   [readablekeys_value] key#==2:: key==CardID:: value==6
846:   [readablekeys_value] key#==3:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==4:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==5:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==6:: key==Description:: value==In 5 pieces (minimum 1 piece per turn, starts with 8 pieces)
846:   [readablekeys_value] key#==7:: key==ID:: value==6
846:   [readablekeys_value] key#==8:: key==NumPieces:: value==5
846:   [readablekeys_value] key#==9:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==10:: key==InitialPieces:: value==8
846:   [readablekeys_value] key#==11:: key==Weight:: value==1
846:   [readablekeys_value] key#==12:: key==proxyType:: value==CardGameAirlift
846:   [readablekeys_value] key#==13:: key==readonly:: value==true
846:   [readablekeys_table] key#==14:: key==readableKeys:: value=={  1 = FriendlyDescription,  2 = CardID,  3 = IsStoredInActiveOrders,  4 = ActiveOrderDuration,  5 = ActiveCardExpireBehavior,  6 = Description,  7 = ID,  8 = NumPieces,  9 = MinimumPiecesPerTurn,  10 = InitialPieces,  11 = Weight,  12 = proxyType,  13 = readonly,  14 = readableKeys,  15 = writableKeys,}
846:   [readablekeys_table] key#==15:: key==writableKeys:: value=={  1 = NumPieces,  2 = MinimumPiecesPerTurn,  3 = InitialPieces,  4 = Weight,}
846:   [writablekeys_value] key#==1:: key==NumPieces:: value==5
846:   [writablekeys_value] key#==2:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==3:: key==InitialPieces:: value==8
846:   [writablekeys_value] key#==4:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221754
846: 1000009	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE09
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Receive whole cards and/or card pieces of a card of your choice.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000009
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Receive whole cards and/or card pieces of a card of your choice. (minimum 1 piece per turn, starts with 202 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Card Piece
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Receive whole cards and/or card pieces of a card of your choice.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==Card Pieces_greenback_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==-1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000009
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==202
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Card Piece
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Receive whole cards and/or card pieces of a card of your choice.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==Card Pieces_greenback_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==-1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==202
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221755
846: 7
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE19
846:   [readablekeys_value] key#==1:: key==FriendlyDescription:: value==Play this card to give one of your territories and all armies on it to another player.  Most useful with teams.
846:   [readablekeys_value] key#==2:: key==CardID:: value==7
846:   [readablekeys_value] key#==3:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==4:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==5:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==6:: key==Description:: value==In 9 pieces (minimum 1 piece per turn, starts with 90 pieces)
846:   [readablekeys_value] key#==7:: key==ID:: value==7
846:   [readablekeys_value] key#==8:: key==NumPieces:: value==9
846:   [readablekeys_value] key#==9:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==10:: key==InitialPieces:: value==90
846:   [readablekeys_value] key#==11:: key==Weight:: value==1
846:   [readablekeys_value] key#==12:: key==proxyType:: value==CardGameGift
846:   [readablekeys_value] key#==13:: key==readonly:: value==true
846:   [readablekeys_table] key#==14:: key==readableKeys:: value=={  1 = FriendlyDescription,  2 = CardID,  3 = IsStoredInActiveOrders,  4 = ActiveOrderDuration,  5 = ActiveCardExpireBehavior,  6 = Description,  7 = ID,  8 = NumPieces,  9 = MinimumPiecesPerTurn,  10 = InitialPieces,  11 = Weight,  12 = proxyType,  13 = readonly,  14 = readableKeys,  15 = writableKeys,}
846:   [readablekeys_table] key#==15:: key==writableKeys:: value=={  1 = NumPieces,  2 = MinimumPiecesPerTurn,  3 = InitialPieces,  4 = Weight,}
846:   [writablekeys_value] key#==1:: key==NumPieces:: value==9
846:   [writablekeys_value] key#==2:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==3:: key==InitialPieces:: value==90
846:   [writablekeys_value] key#==4:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221756
846: 1000008	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE29
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Create a special unit that does no damage but cannot be killed. Monoliths last 3 turns before expiring.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==3
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000008
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Create a special unit that does no damage but cannot be killed. Monoliths last 3 turns before expiring. (minimum 1 piece per turn, weight is 12, starts with 135 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Monolith
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Create a special unit that does no damage but cannot be killed. Monoliths last 3 turns before expiring.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==monolith v2 130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==3
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000008
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==135
846:   [readablekeys_value] key#==17:: key==Weight:: value==12
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Monolith
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Create a special unit that does no damage but cannot be killed. Monoliths last 3 turns before expiring.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==monolith v2 130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==3
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==135
846:   [writablekeys_value] key#==9:: key==Weight:: value==12
846: [base_value] key==__proxyID:: value==221757
846: 1000007	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE39
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Transform a territory into quicksand for 9 turns.

Attacks and transfers into the territory can still occur, but none can be executed from the territory while quicksand remains active. Units caught in quicksand also do 0.100000001490116% less damage to attackers, and sustain 0.100000001490116% more damage when attacked.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==9
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000007
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 18 pieces Transform a territory into quicksand for 9 turns.

Attacks and transfers into the territory can still occur, but none can be executed from the territory while quicksand remains active. Units caught in quicksand also do 0.100000001490116% less damage to attackers, and sustain 0.100000001490116% more damage when attacked. (minimum 1 piece per turn, starts with 109 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Quicksand
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Transform a territory into quicksand for 9 turns.

Attacks and transfers into the territory can still occur, but none can be executed from the territory while quicksand remains active. Units caught in quicksand also do 0.100000001490116% less damage to attackers, and sustain 0.100000001490116% more damage when attacked.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==quicksand_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==9
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000007
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==18
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==109
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Quicksand
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Transform a territory into quicksand for 9 turns.

Attacks and transfers into the territory can still occur, but none can be executed from the territory while quicksand remains active. Units caught in quicksand also do 0.100000001490116% less damage to attackers, and sustain 0.100000001490116% more damage when attacked.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==quicksand_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==9
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==18
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==109
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221758
846: 1000006	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE49
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Cause a tornado to develop on a territory, causing 10 damage for 3 turns.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==3
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000006
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Cause a tornado to develop on a territory, causing 10 damage for 3 turns. (minimum 1 piece per turn, starts with 203 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Tornado
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Cause a tornado to develop on a territory, causing 10 damage for 3 turns.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==tornado_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==3
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000006
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==203
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Tornado
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Cause a tornado to develop on a territory, causing 10 damage for 3 turns.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==tornado_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==3
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==203
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221759
846: 1000005	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE59
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Cause an earthquake that ravages all territories owned by a target player for 3 turns. 
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==3
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000005
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Cause an earthquake that ravages all territories owned by a target player for 3 turns.  (minimum 1 piece per turn, starts with 201 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Earthquake
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Cause an earthquake that ravages all territories owned by a target player for 3 turns. 
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==earthquake_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==3
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000005
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==201
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Earthquake
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Cause an earthquake that ravages all territories owned by a target player for 3 turns. 
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==earthquake_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==3
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==201
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221760
846: 1000004	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE69
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Block an opponent from playing cards for 5 turns.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==5
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000004
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 15 pieces Block an opponent from playing cards for 5 turns. (minimum 1 piece per turn, starts with 106 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Card Block
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Block an opponent from playing cards for 5 turns.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==Card Block_blueback_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==5
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000004
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==15
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==106
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Card Block
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Block an opponent from playing cards for 5 turns.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==Card Block_blueback_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==5
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==15
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==106
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221761
846: 12
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE79
846:   [readablekeys_value] key#==1:: key==MultiplyPercentage:: value==400%
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Play this card to change one of your territories to a neutral and multiply its armies by 400% at the end of your turn.
846:   [readablekeys_value] key#==3:: key==CardID:: value==12
846:   [readablekeys_value] key#==4:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==5:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 8 pieces to multiply armies by 400% (minimum 1 piece per turn, starts with 80 pieces)
846:   [readablekeys_value] key#==8:: key==MultiplyAmount:: value==4
846:   [readablekeys_value] key#==9:: key==ID:: value==12
846:   [readablekeys_value] key#==10:: key==NumPieces:: value==8
846:   [readablekeys_value] key#==11:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==12:: key==InitialPieces:: value==80
846:   [readablekeys_value] key#==13:: key==Weight:: value==1
846:   [readablekeys_value] key#==14:: key==proxyType:: value==CardGameBlockade
846:   [readablekeys_value] key#==15:: key==readonly:: value==true
846:   [readablekeys_table] key#==16:: key==readableKeys:: value=={  1 = MultiplyPercentage,  2 = FriendlyDescription,  3 = CardID,  4 = IsStoredInActiveOrders,  5 = ActiveOrderDuration,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = MultiplyAmount,  9 = ID,  10 = NumPieces,  11 = MinimumPiecesPerTurn,  12 = InitialPieces,  13 = Weight,  14 = proxyType,  15 = readonly,  16 = readableKeys,  17 = writableKeys,}
846:   [readablekeys_table] key#==17:: key==writableKeys:: value=={  1 = MultiplyAmount,  2 = NumPieces,  3 = MinimumPiecesPerTurn,  4 = InitialPieces,  5 = Weight,}
846:   [writablekeys_value] key#==1:: key==MultiplyAmount:: value==4
846:   [writablekeys_value] key#==2:: key==NumPieces:: value==8
846:   [writablekeys_value] key#==3:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==4:: key==InitialPieces:: value==80
846:   [writablekeys_value] key#==5:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221762
846: 1000003	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE89
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Create a special unit that does no damage but has low combat order, preventing capture temporarily. Shields last 1 turn before expiring.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000003
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Create a special unit that does no damage but has low combat order, preventing capture temporarily. Shields last 1 turn before expiring. (minimum 1 piece per turn, starts with 137 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Shield
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Create a special unit that does no damage but has low combat order, preventing capture temporarily. Shields last 1 turn before expiring.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==shield_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000003
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==137
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Shield
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Create a special unit that does no damage but has low combat order, preventing capture temporarily. Shields last 1 turn before expiring.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==shield_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==137
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221763
846: 1000002	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFE99
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Isolate a territory for 7 turns.

No units can attack or transfer to or from the territory during this duration.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==7
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000002
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 12 pieces Isolate a territory for 7 turns.

No units can attack or transfer to or from the territory during this duration. (minimum 1 piece per turn, starts with 103 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Isolation
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Isolate a territory for 7 turns.

No units can attack or transfer to or from the territory during this duration.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==isolation_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==7
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000002
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==12
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==103
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Isolation
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Isolate a territory for 7 turns.

No units can attack or transfer to or from the territory during this duration.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==isolation_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==7
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==12
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==103
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221764
846: 1000001	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFEA9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Invoke pestilence on another player, reducing each of their territories by 5 units for 1 turn.

If a territory is reduced to 0 armies, it will turn neutral.

Special units are not affected by Pestilence, and will prevent a territory from turning to neutral.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000001
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==true
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 11 pieces Invoke pestilence on another player, reducing each of their territories by 5 units for 1 turn.

If a territory is reduced to 0 armies, it will turn neutral.

Special units are not affected by Pestilence, and will prevent a territory from turning to neutral. (minimum 1 piece per turn, starts with 102 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Pestilence
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Invoke pestilence on another player, reducing each of their territories by 5 units for 1 turn.

If a territory is reduced to 0 armies, it will turn neutral.

Special units are not affected by Pestilence, and will prevent a territory from turning to neutral.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==pestilence_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000001
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==11
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==102
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Pestilence
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Invoke pestilence on another player, reducing each of their territories by 5 units for 1 turn.

If a territory is reduced to 0 armies, it will turn neutral.

Special units are not affected by Pestilence, and will prevent a territory from turning to neutral.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==pestilence_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==11
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==102
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221765
846: 1000000	custom card
846: [cards] object=card def, tablelength==1::
846: [proactive display attempt] value==table: 001AFEB9
846:   [readablekeys_value] key#==1:: key==ModID:: value==846
846:   [readablekeys_value] key#==2:: key==FriendlyDescription:: value==Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.

The epicenter (targeted territory) will sustain 100% + 3 fixed damage.

Directly bordering territories will sustain 50% + 3 fixed damage, and the effect will continue outward for an additional 2 territories, reducing in amount by 25% each time.

Friendly Fire is enabled, so you will damage yourself if you own one of the impacted territories.

Damage from a nuke occurs during the BombCards phase of a turn.
846:   [readablekeys_value] key#==3:: key==ActiveOrderDuration:: value==-1
846:   [readablekeys_value] key#==4:: key==CardID:: value==1000000
846:   [readablekeys_value] key#==5:: key==IsStoredInActiveOrders:: value==false
846:   [readablekeys_value] key#==6:: key==ActiveCardExpireBehavior:: value==0
846:   [readablekeys_value] key#==7:: key==Description:: value==In 10 pieces Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.

The epicenter (targeted territory) will sustain 100% + 3 fixed damage.

Directly bordering territories will sustain 50% + 3 fixed damage, and the effect will continue outward for an additional 2 territories, reducing in amount by 25% each time.

Friendly Fire is enabled, so you will damage yourself if you own one of the impacted territories.

Damage from a nuke occurs during the BombCards phase of a turn. (minimum 1 piece per turn, starts with 101 pieces)
846:   [readablekeys_value] key#==8:: key==Name:: value==Nuke
846:   [readablekeys_value] key#==9:: key==CustomCardDescription:: value==Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.

The epicenter (targeted territory) will sustain 100% + 3 fixed damage.

Directly bordering territories will sustain 50% + 3 fixed damage, and the effect will continue outward for an additional 2 territories, reducing in amount by 25% each time.

Friendly Fire is enabled, so you will damage yourself if you own one of the impacted territories.

Damage from a nuke occurs during the BombCards phase of a turn.
846:   [readablekeys_value] key#==10:: key==ImageFilename:: value==nuke_card_image_130x180.png
846:   [readablekeys_value] key#==11:: key==ActiveDuration:: value==-1
846:   [readablekeys_value] key#==12:: key==ExpireBehavior:: value==1
846:   [readablekeys_value] key#==13:: key==ID:: value==1000000
846:   [readablekeys_value] key#==14:: key==NumPieces:: value==10
846:   [readablekeys_value] key#==15:: key==MinimumPiecesPerTurn:: value==1
846:   [readablekeys_value] key#==16:: key==InitialPieces:: value==101
846:   [readablekeys_value] key#==17:: key==Weight:: value==1
846:   [readablekeys_value] key#==18:: key==proxyType:: value==CardGameCustom
846:   [readablekeys_value] key#==19:: key==readonly:: value==true
846:   [readablekeys_table] key#==20:: key==readableKeys:: value=={  1 = ModID,  2 = FriendlyDescription,  3 = ActiveOrderDuration,  4 = CardID,  5 = IsStoredInActiveOrders,  6 = ActiveCardExpireBehavior,  7 = Description,  8 = Name,  9 = CustomCardDescription,  10 = ImageFilename,  11 = ActiveDuration,  12 = ExpireBehavior,  13 = ID,  14 = NumPieces,  15 = MinimumPiecesPerTurn,  16 = InitialPieces,  17 = Weight,  18 = proxyType,  19 = readonly,  20 = readableKeys,  21 = writableKeys,}
846:   [readablekeys_table] key#==21:: key==writableKeys:: value=={  1 = Name,  2 = CustomCardDescription,  3 = ImageFilename,  4 = ActiveDuration,  5 = ExpireBehavior,  6 = NumPieces,  7 = MinimumPiecesPerTurn,  8 = InitialPieces,  9 = Weight,}
846:   [writablekeys_value] key#==1:: key==Name:: value==Nuke
846:   [writablekeys_value] key#==2:: key==CustomCardDescription:: value==Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.

The epicenter (targeted territory) will sustain 100% + 3 fixed damage.

Directly bordering territories will sustain 50% + 3 fixed damage, and the effect will continue outward for an additional 2 territories, reducing in amount by 25% each time.

Friendly Fire is enabled, so you will damage yourself if you own one of the impacted territories.

Damage from a nuke occurs during the BombCards phase of a turn.
846:   [writablekeys_value] key#==3:: key==ImageFilename:: value==nuke_card_image_130x180.png
846:   [writablekeys_value] key#==4:: key==ActiveDuration:: value==-1
846:   [writablekeys_value] key#==5:: key==ExpireBehavior:: value==1
846:   [writablekeys_value] key#==6:: key==NumPieces:: value==10
846:   [writablekeys_value] key#==7:: key==MinimumPiecesPerTurn:: value==1
846:   [writablekeys_value] key#==8:: key==InitialPieces:: value==101
846:   [writablekeys_value] key#==9:: key==Weight:: value==1
846: [base_value] key==__proxyID:: value==221766
846: 18 cards total
846: [all cards] object=game.Settings.Cards, tablelength==18::
846: [proactive display attempt] value==table: 001AFECE
846: [invalid/empty object] object=={}  [empty table]
]]