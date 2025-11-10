-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking
-- Using the module `ui` is for convenience

require('settings');
require('ui');

function getSettings()
	return {
		addSetting('CreatorIsMember', 'I have a Membership', 'bool', true, {
			help = function(parent)
				Label(parent).SetText('Some settings require membership to be used');
				Label(parent).SetText('The game may not be able to be created if member-only features are randomly enabled');
			end
		}),
		addSetting('CreatorHasMegaStrategyPack', 'I have bought the Mega Strategy Pack', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('The Mega Stategy Pack unlocks settings that are normally locked behind levelling up');
				Label(parent).SetText('If you have bought the pack, enable this setting');
			end
		}),
		addSetting('CreatorLevel', 'My Level', 'int', 54, {
			minValue = 0,
			maxValue = 54,
			absoluteMax = 1000,
			help = function(parent)
				Label(parent).SetText('Some settings require leveling up to unlocked');
				Label(parent).SetText('Settings which are not unlocked may be randomly enabled');
				Label(parent).SetText('The game will not be able to be created if locked settings are enabled');
				Label(parent).SetText('If your level is above 54, you have already unlocked all features that can be unlocked by leveling up');
			end
		}),
		addSetting('UseRandomLuckMod', 'Randomize luck modifier', 'bool', false, {
			subsettings = {
				addSetting('LuckStrat', 'Use strategic luck modifier (0 or 16%)', 'bool', true, {
					help = function(parent)
						Label(parent).SetText('If disabled, any luck modifier value will be used');
					end
				})
			}
		}),
		addSetting('UseRandomKillRates', 'Randomize kill rates', 'bool', false),
		addSetting('RandomiseArmiesStandGuard', 'Randomize one army stands guard', 'bool', false),
		addSetting('UseRandomCommerce', 'Randomize commerce settings', 'bool', false),
		addSetting('UseRandomDistMode', 'Randomize distribution mode', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('If enabled distribution mode will be random between full distribution, random warlords and random cities');
			end
		}),
		addSetting('AllowHeavierFogs', 'Allow use of heavier fogs', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('By default, fog is randomly decided to be no fog, light fog or normal fog');
				Label(parent).SetText('Enabling allows dense fog, heavy fog and complete fog to be included');
			end,
			subsettings = {
				addSetting('ForceHeavierFogCards', 'Force inclusion of Reconnaissance, Surveillance and or Spy cards', 'bool', true, {
					help = function(parent)
						Label(parent).SetText('These cards will only be included by force if the fog level is higher than normal fog');
					end
				})
			}
		}),
		addSetting('RandomiseCardsHeldVisibility', 'Randomize cards held and received visibility', 'bool', false),
		addSetting('RandomiseCardsPlayedVisibility', 'Randomize card playing visibility', 'bool', false)
	};
end
