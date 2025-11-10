--[[
,
		'Localized Sanctions'
,
		['Localized Sanctions'] = true
,
		Card('Localized Sanctions', true, function(parent)
			Label(parent).SetText('Like a Sanctions Card but only applies to a bonus');
		end, {
			addDurationSetting('Localized Sanctions'),
			addSetting('Localized SanctionsMultiplier', 'Percent of income to remove', 'float', 50, {
				dp = 2,
				minValue = -100,
				maxValue = 100,
				help = function(parent)
					Label(parent).SetText('Negative values increase income');
				end
			})
		})
]]

-- not compatible with dynamic bonuses, progressive bonuses - could maybe check for mod ids in game settings?
-- confusing with maps with inss bonuses built in

-- card affect = -2, card played = -1. card played does card affect

function playCardLocalizedSancations(game, tabData, cardName, btn, vert, vert2, data)
	if not data.phase then
		data.phase = WL.TurnPhase.SanctionCards - 1;
	end
	-- play bonus selection card
end

function playedCardLocalizedSancations(wz, player, cardName, param)
	-- played bonus selection card
end

function processStartTurnLocalizedSancations(game, addNewOrder, cardName)
	removeExpiredCardInstances(game, addNewOrder, cardName);
	-- if card setting duration is >1, for all active instances make an order saying to do the card affect
	-- no idea if it occurs in correct phase yet
end

local function doLocalizedSancationsCardEffect(wz, cardName)
	
end

function processOrderLocalizedSancations(wz, cardName)
	-- check for do card effect orders then call doLocalizedSancationsCardEffect
end