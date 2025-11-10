-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking
-- Using the module `ui` is for convenience

require('settings');
require('ui');

local function Card(customCard, settings)
	local card = addSetting('Enable' .. customCard.name, 'Enable ' .. customCard.name .. ' cards', 'bool', false, {
		subsettings = {
			addSetting(customCard.name .. 'PiecesInCard', 'Number of pieces to divide the card into', 'int', 5, {
				minValue = 1,
				maxValue = 10,
				absoluteMax = 100
			}),
			addSetting(customCard.name .. 'WonByChance', 'Award pieces based on random chance', 'bool', false, {
				help = function(parent)
					Label(parent).SetText('If enabled, all pieces from "Minimum pieces awarded per turn" are given first then chance applies to the upper limit of number of card pieces to award on piece by piece basis');
				end,
				subsettings = {
					addSetting(customCard.name .. 'PiecesPerTurnMaxLimit', 'Maximum pieces awarded per turn', 'int', 1, {
						minValue = 1,
						maxValue = 10,
						absoluteMax = 100,
						help = function(parent)
							Label(parent).SetText('If "Minimum pieces awarded per turn" is higher than this setting, then the value for that setting is used for this setting');
						end
					}),
					addSetting(customCard.name .. 'WonByChancePercent', 'Chance of a piece being awarded (%)', 'int', 10, {
						minValue = 0,
						maxValue = 100
					}),
				}
			}),
			addSetting(customCard.name .. 'PiecesPerTurn', 'Minimum pieces awarded per turn', 'int', 1, {
				minValue = 0,
				maxValue = 10,
				absoluteMax = 100
			}),
			addSetting(customCard.name .. 'StartPieces', 'Pieces given to each player at the start', 'int', 0, {
				minValue = 0,
				maxValue = 10,
				absoluteMax = 100
			}),
			addSetting(customCard.name .. 'IsBuyable', 'Can be bought', 'bool', false, {
				help = function(parent)
					Label(parent).SetText('Must be a Commerce game to be bought');
				end,
				subsettings = {
					addSetting(customCard.name .. 'Cost', 'Cost (gold)', 'int', 5, {
						minValue = 1,
						maxValue = 20,
						absoluteMax = 10000
					})
				}
			}),
			addSetting(customCard.name .. 'NeedsSuccessfulAttackToEarnPiece', 'Needs successful attack to award pieces', 'bool', true)
		}
	});

	card.help = function(parent)
		Label(parent).SetText(customCard.desc);
	end;

	card.bkwards = false;

	for _, subsetting in ipairs(settings) do
		table.insert(card.subsettings, subsetting);
	end

	return card;
end

local function addDurationSetting(cardName, defaultValue)
	return addSetting(cardName .. 'Duration', 'Duration (turns)', 'int', defaultValue, {
		bkwrds = 1,
		minValue = 1,
		maxValue = 10,
		absoluteMax = 100000
	});
end

function getSettings()
	return {
		Card(
			{
				name = 'Reconnaissance+',
				desc = 'Like normal Reconnaissance Cards but with a range and lasts for 1 turn.\r\nReconnaissance Cards must be included for the card to work'
			},
			{
				addDurationSetting('Reconnaissance+', 1),
				addSetting('Reconnaissance+Range', 'Range', 'int', 2, {
					minValue = 1,
					maxValue = 5
				}),
				addSetting('Reconnaissance+RandomAutoplay', 'Automatically randomly play this card', 'bool', false, {
					help = function(parent)
						Label(parent).SetText('If enabled, players will not be able to play this card through the menu')
						Label(parent).SetText('Instead the card will automatically be played anywhere');
					end
				})
			}
		),
		Card(
			{
				name = 'Recycle',
				desc = 'Sets the number armies on a territory to be the amount that was on it on the first turn and changes the owner to neutral\r\nThe armies that used to be on the territory get added to your income\r\nCan only be played on one of your own territories'
			},
			{
				addSetting('RecycleEliminateIfCommander', 'Recycling Commander causes elimination', 'bool', false, {
					help = function(parent)
						Label(parent).SetText('If a Recycle Card was played on a territory with a Commander, should the player be eliminated?');
					end
				})
			}
		),
		Card(
			{
				name = 'Immobilize',
				desc = 'Prevents all army movement (including airlifts) to and from a territory that is next to or is one of yours'
			},
			{
				addDurationSetting('Immobilize', 2)
			}
		),
		Card(
			{
				name = 'Trap',
				desc = 'Similar to Blockade Cards except they are triggered by the enemy capturing where the card was played\r\nTraps must be played on one of your own territories'
			},
			{
				addSetting('TrapMultiplier', 'Multiplier', 'float', 4, {
					help = function(parent)
						Label(parent).SetText('Armies attacking become neutral and are multiplied by this much');
					end,
					dp = 2,
					minValue = 0,
					maxValue = 8
				}),
				addSetting('TrapEliminateIfCommander', 'Trapping Commander causes elimination', 'bool', true, {
					help = function(parent)
						Label(parent).SetText('If one of the armies taking over the territory (where a Trap Card was played) was a Commander, should the player be eliminated?');
					end
				})
			}
		),
		Card({
			name = 'Double Tap',
			desc = 'Allows you to make a second attack/transfer from a territory that you already issued an attack/transfer from\r\nIf one of your attacks fails but you played a Double Tap Card, a new order will be created using all armies and any special units that are on the territory at the time the card is played\r\nIf using multi-attack and the double tap attack is successful, the multi-attack chain will only continue if it was played before the next attack of the chain'
		}, {}),
		Card(
			{
				name = 'Rushed Blockade',
				desc = 'Like normal Blockade Cards but happen during the attacks phase - attack one territory then blockade it during the same turn\r\nYou must own the territory at the time of the card being played'
			},
			{
				addSetting('Rushed BlockadeMultiplier', 'Multiplier', 'float', 3, {
					dp = 2,
					minValue = 0,
					maxValue = 8
				})
			}
		),
		addSetting('LimitMaxCards', 'Limit maximum cards each player or team can hold', 'bool', true, {
			subsettings = {
				addSetting('MaxCardsLimit', 'Limit', 'int', 3, {
					minValue = 0,
					maxValue = 15,
					absoluteMax = 600
				})
			}
		})
	};
end
