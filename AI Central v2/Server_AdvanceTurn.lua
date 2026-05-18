require('Utilities')


-- if player.IsAI ) then 
-- if player.HumanTurnedIntoAI 


function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)

  --pure AI

  if not (order.PlayerID == 0) then
    if game.Game.Players [order.PlayerID].IsAI then
      local Sett = Mod.Settings

      if (not Sett.P_attack) and order.proxyType == "GameOrderAttackTransfer" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_deploy) and order.proxyType == "GameOrderDeploy" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_city) and order.proxyType == "GameOrderPurchase" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_rein) and order.proxyType == "GameOrderPlayCardReinforcement" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_emergency) and order.proxyType == "GameOrderPlayCardAbandon" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_diplo) and order.proxyType == "GameOrderPlayCardDiplomacy" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.P_block) and order.proxyType == "GameOrderPlayCardBlockade" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
        end

    --Human AI
    elseif game.Game.Players [order.PlayerID].HumanTurnedIntoAI then
      local Sett = Mod.Settings

      if (not Sett.H_attack) and order.proxyType == "GameOrderAttackTransfer" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_deploy) and order.proxyType == "GameOrderDeploy" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_city) and order.proxyType == "GameOrderPurchase" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_rein) and order.proxyType == "GameOrderPlayCardReinforcement" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_emergency) and order.proxyType == "GameOrderPlayCardAbandon" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_diplo) and order.proxyType == "GameOrderPlayCardDiplomacy" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
      elseif (not Sett.H_block) and order.proxyType == "GameOrderPlayCardBlockade" then
        skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage)
        end
    end
    
  end
  
end
