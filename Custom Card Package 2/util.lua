function teamIdToTeamName(teamId)
	-- teamId 0 becomes Team A
	-- teamId 3 becomes Team D
	-- teamId 25 becomes Team Z
	-- teamId 26 becomes Team AA
	-- teamId 27 becomes Team AB
	-- based on https://stackoverflow.com/questions/8240637/convert-numbers-to-letters-beyond-the-26-character-alphabet#answer-64456745

	local A = string.byte('A', 1);
	local lettersInAlphabet = 26;
	local teamName = '';

	while teamId >= 0 do
		local c = string.char(A + (teamId % lettersInAlphabet));

		teamName = c .. teamName;
		teamId = math.floor(teamId / lettersInAlphabet) - 1;
	end

	return 'Team ' .. teamName;
end

function teamNameToTeamId(teamName)
	-- print(teamIdToTeamName(52));
	-- print(teamNameToTeamId('Team BA')); -- this does not match up with the above

	if type(teamName) ~= 'string' then
		print('teamName in teamNameToTeamId must be a string');

		return;
	end

	local i, j = string.find(teamName, '^Team ');

	if i and j then
		teamName = string.sub(teamName, j + 1, #teamName);
	else
		print('teamName in teamNameToTeamId must start with "Team "');

		return;
	end

	teamName = string.upper(teamName);

	local A = string.byte('A', 1);
	local lettersInAlphabet = 26;
	local teamId = 0;

	i = 1;

	while i < (#teamName + 1) do
		local c = string.byte(teamName, i);

		teamId = teamId + (c - A) + (lettersInAlphabet * (i - 1));
		i = i + 1;
	end

	return teamId;
end

function profileLinkToPlayerId(str)
	-- print(profileLinkToPlayerId('https://www.warzone.com/Profile?p=9522268564&u=DanWL_1'));

	if type(str) ~= 'string' then
		print('str in profileLinkToPlayerId is not a string');
		return;
	end

	str = string.lower(str);
	str = string.gsub(str, '^https?:%/%/', '');
	str = string.gsub(str, '^www%.', '');

	local i, j = string.find(str, '^warzone%.com');
	local k, l = string.find(str, '^warlight%.net');

	if i and j then
		str = string.sub(str, j + 1, #str);
	elseif k and l then
		str = string.sub(str, l + 1, #str);
	else
		print('invalid profile link domain');

		return;
	end

	i, j = string.find(str, '^%/profile%?p=');

	if i and j then
		str = string.sub(str, j + 1, #str);
	else
		print('invalid profile link profile');

		return;
	end

	str = string.gsub(str, '&u=.+$', '');
	i, j = string.find(str, '^%d+$');

	if not (i and j) then
		print('invalid profile link digitsonly');

		return;
	end

	if #str < 8 then
		print('invalid player');

		return;
	end

	str = string.sub(str, 3, #str - 2);

	return tonumber(str);
end