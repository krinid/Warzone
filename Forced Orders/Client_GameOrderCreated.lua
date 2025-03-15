function Client_GameOrderCreated (game, gameOrder, skip)
    print ("[C_GOC] START");
	print ("[C_GOC] gameOrder proxyType=="..gameOrder.proxyType.."::");
	if (game.Us == nil) then return; end --technically not required b/c spectators could never initiative this function (requires submitting an order, which they can't do b/c they're not in the game)

	if (boolInputMovesForAI == true) then
		--recreate move for AI1 & delete all other AI moves
		if (gameOrder.proxyType=='GameOrderAttackTransfer') then
			--this doesn't work -- obviously it'd be an easy hack for players to cheat
			--replacementOrder = WL.GameOrderAttackTransfer.Create(targetPlayer, gameOrder.From, gameOrder.To, gameOrder.AttackTransfer, gameOrder.ByPercent, gameOrder.NumArmies, gameOrder.AttackTeammates); end
			--if (gameOrder.proxyType=='GameOrderPlayCardAirlift') then replacementOrder = WL.GameOrderPlayCardAirlift.Create(gameOrder.CardInstanceID, gameOrder.PlayerID, gameOrder.FromTerritoryID, gameOrder.ToTerritoryID, numArmies); end

			--create a custom game order & handle it in Server_TurnAdvance_Order
			local orders = game.Orders;
			local strForcedOrder = "ForceOrder|AttackTransfer|"..targetPlayer.."|"..gameOrder.From.."|"..gameOrder.To.."|"..tostring (gameOrder.AttackTransfer) .."|"..tostring (gameOrder.ByPercent) .."|"..gameOrder.NumArmies.NumArmies.."|".. tostring (gameOrder.AttackTeammates);
			table.insert(orders, WL.GameOrderCustom.Create(game.Us.ID, "Create AI move: " .. strForcedOrder, strForcedOrder));
			print ("Create AI move: " .. strForcedOrder);
			game.Orders = orders;
			skip (WL.ModOrderControl.Skip, false); --skip the original order, replaced with a move for AI1

			--skip (WL.ModOrderControl.SkipAndSupressSkippedMessage); --suppress the meaningless/detailless 'Mod skipped order' message, since the order is being replaced with a proper order (minus the Immovable Specials)
		end
	end
    print ("[C_GOC] END");
end