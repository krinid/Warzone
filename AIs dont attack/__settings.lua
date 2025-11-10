-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking

require('settings');

function getSettings()
	return {
		addSetting('EnableTransfers', 'Allow AIs to make transfers', 'bool', true),
		addSetting('EnableAttackOtherAIs', 'Allow AIs to attack other AIs', 'bool', true),
		addSetting('EnableAttackNeutrals', 'Allow AIs to attack neutrals', 'bool', true)
	};
end
