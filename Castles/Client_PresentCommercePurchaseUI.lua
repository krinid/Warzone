function Client_PresentCommercePurchaseUI(rootParent, game, close)
	Close1 = close;
	Game = game;

	intCastleCost = 10;

	if (game.Us.ID == nil) then UI.Alert ("Only active players can buy Castles") return; end

	-- local MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	MainUI = UI.CreateVerticalLayoutGroup(rootParent);
	UI.CreateLabel(MainUI).SetText("[CASTLE]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(MainUI).SetText("A unit that provides additional protection to armies that enter the castle. The first castle built costs X, and each additional castle built costs Y, castle maintenance costs Z");

	horz = UI.CreateHorizontalLayoutGroup(MainUI).SetFlexibleWidth(1);
	UI.CreateLabel(horz).SetText("# Armies to move inside the Castle: ");
	UI.CreateLabel(MainUI).SetText("  (Castles are created at the end of a turn. The # you enter here will move up to that many armies into the castle when it is created. These armies can be from deployments, airlifts, transfers into the territory or otherwise. Any armies not moved into the caslte will remain outside. Special Units cannot enter the castle)");
	PurchaseCastleButton = UI.CreateButton(MainUI).SetText("Purchase Castle").SetOnClick(PurchaseClicked).SetColor ("#008000");
	NumArmiesToMoveIntoCastle = UI.CreateNumberInputField(horz).SetSliderMinValue(0).SetSliderMaxValue(1000).SetValue(0).SetPreferredWidth(100);
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

--given a parameter 'armies' of type WL.Armies, return the # of a given SU present within it
--2nd parameter indicates pattern match (true) vs exact match (false)
function countSUinstances (armies, strSUname, boolPatternMatch)
	local intNumSUs = 0;
	for _,su in pairs(armies.SpecialUnits) do
		if (su.proxyType == 'CustomSpecialUnit' and ((boolPatternMatch and startsWith (su.Name, strSUname)) or (su.Name == strSUname))) then
			intNumSUs = intNumSUs + 1;
		end
	end
	return (intNumSUs);
end

function PurchaseClicked()
	--Check if they're already at max simultaneous or max total per player per game limits.  Add in how many they have on the map plus how many purchase orders they've already made
	--We check on the client for player convenience. Another check happens on the server, so even if someone hacks their client and removes this check they still won't be able to go over the max.

	local playerID = Game.Us.ID;
	local intCastleMaxSimultaneousPerPlayer = Mod.Settings.CastleMaxSimultaneousPerPlayer or 5; --default to 5 if not set
	local intCastleMaxPerPlayerPerGame = Mod.Settings.CastleMaxTotalPerPlayer or -1; --default to -1 (no limit) if not set by host
	local numCastlesAlreadyHaveTotalPerGame = Mod.PlayerGameData.TotalCastlesCreatedThisGame or 0; --get # of Castles already created this game, if nil then default to 0
	local numCastlesAlreadyHaveSimultaneously = 0;

	--count # of Castles currently on the map (note: if fogged to the owning player by a Smoke Bomb, etc, then they won't be counted and the player could exceed the max while the fog is active)
	for _,ts in pairs(Game.LatestStanding.Territories) do
		if (ts.OwnerPlayerID == playerID) then
			numCastlesAlreadyHaveSimultaneously = numCastlesAlreadyHaveSimultaneously + countSUinstances (ts.NumArmies, "Castle", true);
		end
	end

	for _,order in pairs(Game.Orders) do
		if (order.proxyType == 'GameOrderCustom' and startsWith (order.Payload, 'Castle|Purchase|')) then
			numCastlesAlreadyHaveSimultaneously = numCastlesAlreadyHaveSimultaneously + 1;
			numCastlesAlreadyHaveTotalPerGame = numCastlesAlreadyHaveTotalPerGame + 1;
		end
	end

	-- limit # of Behemoths to value set by host (max 5) including units already on the map and bought in orders this turn
	-- if (intBehemothMaxPerPlayerPerGame > 0 and numBehemothsAlreadyHaveTotalPerGame >= intBehemothMaxPerPlayerPerGame) then
	-- 	UI.Alert("Cannot create another Behemoth\n\nAlready at max of " ..tostring (intBehemothMaxPerPlayerPerGame).. " units per player that can be created for the duration of this game (including ones you have purchased this turn)");
	-- 	return;
	-- elseif (numBehemothsAlreadyHaveSimultaneously >= intBehemothMaxSimultaneousPerPlayer) then
	-- 	UI.Alert("Cannot create another Behemoth\n\nAlready at max of " ..tostring (intBehemothMaxSimultaneousPerPlayer).. " units per player that can simultaneously be on the map (including ones you have purchased this turn)");
	-- 	return;
	-- end

	-- BehemothGoldSpent = BehemothCost_NumberInputField.GetValue();
	-- if (BehemothGoldSpent <= 0) then UI.Alert ("Behemoth cost must be >0"); return; end

	UI.Destroy (PurchaseCastleButton);
	if (SelectTerritoryBtn == nil) then
		SelectTerritoryBtn = UI.CreateButton(MainUI).SetText("Select Territory").SetColor ("#00F4FF").SetOnClick(SelectTerritoryClicked);
		TargetTerritoryInstructionLabel = UI.CreateLabel(MainUI).SetText("");
		buttonBuyCastle = UI.CreateButton(MainUI).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked).SetColor ("#008000");
	end

	local intNumArmiesToMoveInsideCastle = NumArmiesToMoveIntoCastle.GetValue();
	SelectTerritoryBtn.SetInteractable (false);
	SelectTerritoryClicked(); --start immediately in selection mode, no reason to require player to click the button

	-- Close1();
end


function PresentBehemothDialog (rootParent, setMaxSize, setScrollable, game, close)
	Close2 = close;
	setMaxSize(400, 500);

	local vert = UI.CreateVerticalLayoutGroup(rootParent).SetFlexibleWidth(1); --set flexible width so things don't jump around while we change InstructionLabel
	UI.CreateLabel(vert).SetText("[BEHEMOTH]\n\n").SetColor(getColourCode("card play heading"));
	UI.CreateLabel(vert).SetText("• max " ..tostring (Mod.Settings.BehemothMaxSimultaneousPerPlayer or 5).. " units can be on map per player simultaneously");
	UI.CreateLabel(vert).SetText("• " ..tostring (Mod.PlayerGameData.TotalBehemothsCreatedThisGame or 0).. " of max " ..tostring (Mod.Settings.BehemothMaxTotalPerPlayer or -1).. " units created so far\n");

	SelectTerritoryBtn = UI.CreateButton(vert).SetText("Select Territory").SetColor ("#00F4FF").SetOnClick(SelectTerritoryClicked);
	TargetTerritoryInstructionLabel = UI.CreateLabel(vert).SetText("");

	buttonBuyCastle = UI.CreateButton(vert).SetInteractable(false).SetText("Purchase").SetOnClick(CompletePurchaseClicked).SetColor ("#008000");

	local behemothCost = BehemothCost_NumberInputField.GetValue();
	local behemothPower = math.floor (getBehemothPower(BehemothGoldSpent) + 0.5);
	local behemothPowerFactor = 1.0; --always use factor of 1.0, it's too complicated with separate factors, etc
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	UI.CreateLabel(vert).SetText("\nBehemoth properties:\nCost " ..tostring (BehemothGoldSpent).. ", Health ".. behemothPower.. "\nAttack power ".. behemothPower * (1+behemothPowerFactor)..", Defense power ".. (behemothPower * behemothPowerFactor)/4);
	UI.CreateLabel(vert).SetText("Takes damage before Armies");
	-- UI.CreateLabel(vert).SetText("\nBehemoth properties:\nCost "..BehemothGoldSpent.."\nPower: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor.."\n\n"..
	-- 	"Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 0.9+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
	-- 	"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable (false);
	print ("name==Behemoth (power ".. tostring (math.floor (behemothPower*10)/10) ..')');

	SelectTerritoryClicked(); --start immediately in selection mode, no reason to require player to click the button
end

function SelectTerritoryClicked()
	UI.InterceptNextTerritoryClick(TerritoryClicked);
	-- local behemothPower = getBehemothPower(BehemothGoldSpent);
	-- local behemothPowerFactor = getBehemothPowerFactor(behemothPower);
	TargetTerritoryInstructionLabel.SetText("Select a territory to spawn the Castle to").SetColor(getColourCode("error")); --\nBehemoth power: " .. behemothPower.."\nScaling factor: " .. behemothPowerFactor);
	--.."\n\n".."Attack power ".. behemothPower * (1+behemothPowerFactor).."\nDefense power ".. behemothPower * behemothPowerFactor.."\nAttack power modifier factor ".. 1+behemothPowerFactor.."\nDefense power modifier factor ".. 0.6+behemothPowerFactor..
	--	"\nCombat order is before armies\nHealth ".. behemothPower.."\nDamage absorbed when attacked ".. behemothPower * behemothPowerFactor);
	SelectTerritoryBtn.SetInteractable(false);
end

function TerritoryClicked(terrDetails)
	if (UI.IsDestroyed (SelectTerritoryBtn)) then return; end

	SelectTerritoryBtn.SetInteractable(true);

	if (terrDetails == nil) then
		--The click request was cancelled.   Return to our default state.
		TargetTerritoryInstructionLabel.SetText("");
		SelectedTerritory = nil;
		buttonBuyCastle.SetInteractable(false);
	else
		--Territory was clicked, check it
		if (Game.LatestStanding.Territories[terrDetails.ID].OwnerPlayerID ~= Game.Us.ID) then
			TargetTerritoryInstructionLabel.SetText("Select a territory that you own").SetColor(getColourCode("error"));
		else
			TargetTerritoryInstructionLabel.SetText("Selected territory: " .. terrDetails.Name).SetColor(getColourCode("subheading"));
			SelectedTerritory = terrDetails;
			buttonBuyCastle.SetInteractable(true);
		end
	end
end

function CompletePurchaseClicked()
	local msg = 'Buy Castle for '..intCastleCost..' gold, spawn to ' .. SelectedTerritory.Name;
	local payload = 'Castle|Purchase|' ..SelectedTerritory.ID.. "|" ..intCastleCost;
	local orders = Game.Orders;
	local customOrder = WL.GameOrderCustom.Create (Game.Us.ID, msg, payload,  { [WL.ResourceType.Gold] = intCastleCost } );
    customOrder.JumpToActionSpotOpt = createJumpToLocationObject (Game, SelectedTerritory.ID);
	customOrder.TerritoryAnnotationsOpt = {[SelectedTerritory.ID] = WL.TerritoryAnnotation.Create ("Castle", 8, getColourInteger (45, 45, 45))}; --use Dark Grey for Castle
	-- customOrder.OccursInPhaseOpt = WL.TurnPhase.ReceiveCards;
	table.insert(orders, customOrder);
	Game.Orders = orders;
	-- Close1();
end

--given 0-255 RGB integers, return a single 24-bit integer
function getColourInteger (red, green, blue)
	return red*256^2 + green*256 + blue;
end

function createJumpToLocationObject (game, targetTerritoryID)
	if (game.Map.Territories[targetTerritoryID] == nil) then return WL.RectangleVM.Create(1,1,1,1); end --territory ID does not exist for this game/template/map, so just use 1,1,1,1 (should be on every map)
	return (WL.RectangleVM.Create(
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY,
		game.Map.Territories[targetTerritoryID].MiddlePointX,
		game.Map.Territories[targetTerritoryID].MiddlePointY));
end

function getColourCode (itemName)
    if (itemName=="card play heading") then return "#0099FF"; --medium blue
    elseif (itemName=="error")  then return "#FF0000"; --red
	elseif (itemName=="subheading") then return "#FFFF00"; --yellow
    else return "#AAAAAA"; --return light grey for everything else
    end
end