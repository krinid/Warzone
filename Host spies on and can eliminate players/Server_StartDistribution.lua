require('tblprint');
require('version');
require('setup');

function Server_StartDistribution(game, standing)
	print('in Server_StartDistribution');
	print('type(tblprint)', type(tblprint));
	print('type(serverCanRunMod)', type(serverCanRunMod));
	print('type(setup)', type(setup));

	if not serverCanRunMod(game) then
		print('exit Server_StartGame because server cannot run mod');
		return;
	end

	print('about to call setup');
	setup(game);
	print('exit Server_StartDistribution');
end