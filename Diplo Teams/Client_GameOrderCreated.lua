require ("utilities");

function Client_GameOrderCreated (game, order, skip)
	--check if an AttackTransfer on a player that the local player isn't in a Team or At War with (ie: is in NAP with) occurs, and if so flag it so it's not a surprise that it gets skipped when turn advances
	if (order.proxyType == 'GameOrderAttackTransfer') then
		local toowner = game.LatestStanding.Territories [order.To].OwnerPlayerID;

		--allows attacking of neutral territories, and verification if order is not neutral required for compatibility with other mods
		--also permits attacking teammates (leave it to the 'Treat Teammates as Enemies' property - this is intentional and strategically useful in games)
		if (toowner ~= WL.PlayerID.Neutral and order.PlayerID ~= WL.PlayerID.Neutral and playersAreTeamMates (toowner, order.PlayerID, game, game.LatestStanding) == false and InWar (order.PlayerID, toowner) == false) then
			UI.Alert ("You have entered an Attack/Transfer order against a territory whose current owner you are neither in a Team Alliance with nor At War with. The order has not been skipped or blocked at this point, but if the state doesn't change, it will be skipped when the turn advances.\n\nIf you want to attack a player, you must Declare War on them. If you want to transfer units between teammates, you must Propose a Team Alliance");
		end
	end
end