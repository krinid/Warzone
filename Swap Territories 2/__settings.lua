-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking
-- Using the module `ui` is for convenience

require('settings');
require('ui');

function getSettings()
	return {
		addSetting('SwapFreq', 'Swap territories once every X turns', 'int', 1, {
			minValue = 1,
			maxValue = 20
		}),
		addSetting('ChanceOfSwapping', 'Chance of territories swapping (%)', 'int', 50, {
			minValue = 1,
			maxValue = 100,
			bkwrds = 100,
			help = function(parent)
				Label(parent).SetText('If a territory should swap is decided per territory, rather than on a turn by turn basis');
			end
		}),
		addSetting('SpecialUnitSwappingEnabled', 'Let territories with special units be swapped', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('Example of special units include Commanders, Bosses (from single player levels) and other custom special units like Tanks');
				Label(parent).SetText('The owner of the special unit is not necessarily who owns the territory');
				Label(parent).SetText('Because of this, special units are only swapped if each player has the same number of a certain special unit type');
			end,
			subsettings = {
				addSetting('SwapCommander', 'Swap Commanders', 'bool', true),
				addSetting('SwapBoss1', 'Swap Boss 1', 'bool', true),
				addSetting('SwapBoss2', 'Swap Boss 2', 'bool', true),
				addSetting('SwapBoss3', 'Swap Boss 3', 'bool', true),
				addSetting('SwapBoss4', 'Swap Boss 4', 'bool', true),
				addSetting('SwapCustomSpecialUnit', 'Swap custom special units', 'bool', true)
			}
		}),
		addSetting('StructureSwappingEnabled', 'Let territories with structures be swapped', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('Examples of structures include Cities and Warzone Idle icons like Army Cache, Smelter and Crafter');
				Label(parent).SetText('If allowed, specify which types of structures can be swapped');
			end,
			subsettings = {
				addSetting('SwapCity', 'Swap Cities', 'bool', true),
				addSetting('SwapArmyCamp', 'Swap Army Camps', 'bool', true),
				addSetting('SwapMine', 'Swap Mines', 'bool', true),
				addSetting('SwapSmelter', 'Swap Smelters', 'bool', true),
				addSetting('SwapCrafter', 'Swap Crafters', 'bool', true),
				addSetting('SwapMarket', 'Swap Markets', 'bool', true),
				addSetting('SwapArmyCache', 'Swap Army Caches', 'bool', true),
				addSetting('SwapMoneyCache', 'Swap Money Caches', 'bool', true),
				addSetting('SwapResourceCache', 'Swap Resource Caches', 'bool', true),
				addSetting('SwapMercenaryCamp', 'Swap Mercenary Camps', 'bool', true),
				addSetting('SwapPower', 'Swap Powers', 'bool', true),
				addSetting('SwapDraft', 'Swap Drafts', 'bool', true),
				addSetting('SwapArena', 'Swap Arenas', 'bool', true),
				addSetting('SwapHospital', 'Swap Hospitals', 'bool', true),
				addSetting('SwapDigSite', 'Swap Dig Sites', 'bool', true),
				addSetting('SwapAttack', 'Swap Attacks', 'bool', true),
				addSetting('SwapMortar', 'Swap Mortars', 'bool', true),
				addSetting('SwapRecipe', 'Swap Recipes', 'bool', true)
			}
		})
	};
end
