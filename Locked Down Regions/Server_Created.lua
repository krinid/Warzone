require('tblprint');

function Server_Created(game, settings)
	local publicGD = Mod.PublicGameData;

	publicGD.lockedDownRegions = {};
	publicGD.newLockedDownRegions = {};

	Mod.PublicGameData = publicGD;
end