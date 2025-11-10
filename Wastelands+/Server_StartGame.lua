require 'distributionWastelands'

function Server_StartGame(game, standing)
	local createAfterPicks = Mod.Settings.CreateDistributionWastelandsAfterPicks;
	local autoDist = game.Settings.AutomaticTerritoryDistribution;

	if autoDist or (not autoDist and createAfterPicks) then
		makeDistributionWastelands(game, standing);
	end
end