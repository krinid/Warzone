require('settings');
require('tblprint');

function Client_GameOrderCreated(game, order, skipOrder)
	-- detect if surveillance card played on a bonus it shouldnt be played on

	if order.proxyType ~= 'GameOrderPlayCardSurveillance' then
		return;
	end

	local bonus = game.Map.Bonuses[order.TargetBonus];
	local numTerrs = getSetting('MaxTerrs');

	if #bonus.Territories > numTerrs then
		skipOrder();
		game.CreateDialog(
			function(rootParent, setMaxSize, setScrollable)
				setMaxSize(300, 175);
				UI.CreateLabel(rootParent).SetText('Surveillance Cards cannot be played on bonuses with more than ' .. numTerrs .. ' territories in the bonus');
			end
		);
	end
end