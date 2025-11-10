-- This file is part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Having a `getSettings` function is necessary for correct functionality
-- Using the module `settings` is for convenience/error checking
-- Using the module `ui` is for convenience

require('settings');
require('ui');

function getSettings()
	return {
		addCustomCard(
			'MysteryCardID',
			'Mystery Card',
			'Grants a player a full random card (excluding Mystery Cards themselves) when played',
			'MysteryCard.png',
			{
				NumPieces = 'NumPieces',
				Weight = 'Weight',
				MinimumPiecesPerTurn = 'MinimumPiecesPerTurn',
				InitialPieces = 'InitialPieces'
			},
			{
				addSetting('NumPieces', 'Number of pieces to divide the card into', 'int', 7, {
					minValue = 0,
					maxValue = 20,
					absoluteMax = 1000
				}),
				addSetting('Weight', 'Weight', 'float', 1, {
					dp = 10,
					minValue = 0,
					maxValue = 5,
					absoluteMax = 1000,
					help = function(parent)
						Label(parent).SetText('How common the card is');
					end
				}),
				addSetting('MinimumPiecesPerTurn', 'Minimum pieces awarded per turn', 'int', 1, {
					minValue = 0,
					maxValue = 5,
					absoluteMax = 1000
				}),
				addSetting('InitialPieces', 'Pieces given to each player at the start', 'int', 0, {
					minValue = 0,
					maxValue = 5,
					absoluteMax = 1000
				})
			}
		)
	};
end
