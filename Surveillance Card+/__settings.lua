-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking

require('settings');

function getSettings()
	return {
		addSetting('MaxTerrs', 'Surveillance Cards can not be played on bonuses with more than this many territories', 'int', 10, {
			minValue = 2,
			maxValue = 50,
			absoluteMax = 4000-- current wz max terrs allowed in map
		})
	};
end
