require('settings');
require('tblprint');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if order.proxyType ~= 'GameOrderPlayCardSurveillance' then
		return;
	end

	local bonus = game.Map.Bonuses[order.TargetBonus];

	if #bonus.Territories > getSetting('MaxTerrs') then
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

		local visibleTo = game.Settings.CardPlayingsFogged and {} or nil;

		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, 'Skipped Surveillance Card from being played on ' .. bonus.Name, visibleTo));
	end
end
