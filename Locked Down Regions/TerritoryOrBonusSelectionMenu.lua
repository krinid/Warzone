-- copied from https://github.com/DanWaLes/Warzone/tree/main/mods/libs/TerritoryOrBonusSelectionMenu

local function levenshtein(s, t)
	-- generated from Brave Search using
	-- search query: lua fuzzy match
	-- follow up q: fuzzy module does not exist

	local m, n = #s, #t;
	local d = {};

	for i = 0, m do
		d[i] = {};
	end

	for i = 0, m do
		d[i][0] = i;
	end

	for j = 0, n do
		d[0][j] = j;
	end

	for j = 1, n do
		for i = 1, m do
			if s:sub(i, i) == t:sub(j, j) then
				d[i][j] = d[i-1][j-1];
			else
				d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + 1);
			end
		end
	end

	return d[m][n];
end

local function isVersionOrHigher(version)
	return WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher(version);
end

local function TerritoryOrBonusSelectionMenu(vert, validation, wz, isBonus)
	local tpe = (isBonus and 'bonus') or 'territory';
	local tpePlural = (isBonus and tpe .. 'es') or tpe:gsub('%l$', 'ies');
	local interceptType = tpe:gsub("^%l", string.upper) .. ((isBonus and 'Link') or '');
	local TpePlural = tpePlural:gsub('^%l', string.upper);

	local vert2;
	local vert3;
	local vert4;
	local vert5;
	local vert6;

	if isVersionOrHigher('5.21') then
		local horz = UI.CreateHorizontalLayoutGroup(vert);

		UI.CreateLabel(horz).SetText('You can');
		UI.CreateLabel(horz).SetText('click a ' .. tpe .. ' on the map').SetColor('#4EFFFF');
		UI.CreateLabel(horz).SetText('or');
		UI.CreateLabel(horz).SetText('choose from the list').SetColor('#94652E');

		local horz2 = UI.CreateHorizontalLayoutGroup(vert);

		UI.CreateLabel(horz2).SetText('You can');
		UI.CreateLabel(horz2).SetText('move this window out of the way').SetColor('#00FF05');

		if type(validation.displayTerrOrBonusSelectionWarning) == 'function' then
			validation.displayTerrOrBonusSelectionWarning(wz, UI.CreateVerticalLayoutGroup(vert));
		end

		vert2 = UI.CreateVerticalLayoutGroup(vert);
		vert3 = UI.CreateVerticalLayoutGroup(vert2);
		vert4 = UI.CreateVerticalLayoutGroup(vert);
	end

	local selectedTerrOrBonus = false;

	local resultsPerPage = 20;
	local results;
	local pagers;
	local pagerBtns;
	local searchInput;
	local searchBtn;
	local resultsPageNum = 1;
	local searchResults;

	function interceptNextTerritoryOrBonusClick()
		UI['InterceptNext' .. interceptType .. 'Click'](
			function(details)
				if selectedTerrOrBonus then
					-- print('already selected using option buttons but click intercepted anyway');
					return WL.CancelClickIntercept;
				end

				if UI.IsDestroyed(vert) then
					-- print('could have closed the dialog then clicked on a territory/bonus');
					return WL.CancelClickIntercept;
				end

				if validation.isValidTerrOrBonus(details, wz) then
					validation.onValidTerrOrBonus(details, wz);
				else
					showInvalidSelectionError(details);
				end
			end
		);
	end

	function showInvalidSelectionError(details)
		local errArea = UI.CreateVerticalLayoutGroup(vert3);
		local tryAgainBtn = UI.CreateButton(vert3).SetText('Reactivate map ' .. tpe .. ' selection').SetColor('#00FF21');

		tryAgainBtn.SetOnClick(
			function()
				tryAgainBtn.SetInteractable(false);
				UI.Destroy(vert3);
				vert3 = UI.CreateVerticalLayoutGroup(vert2);
				interceptNextTerritoryOrBonusClick();
			end
		);

		validation.onInvalidTerrOrBonus(details, wz, errArea);
	end

	function isValidSearchedTerrOrBonus(details, wz)
		return validation.isValidTerrOrBonus(details, wz)
	end

	function listTerrOrBonusAsOption(details, wz)
		local horz = UI.CreateHorizontalLayoutGroup(results);
		local optionBtn = UI.CreateButton(horz).SetText(details.Name).SetColor('#00FF05');

		optionBtn.SetOnClick(function()
			optionBtn.SetInteractable(false);
			selectedTerrOrBonus = true;
			validation.onValidTerrOrBonus(details, wz);
		end);

		if not isVersionOrHigher('5.21') then
			return;
		end

		local viewTerrOrBonusBtn = UI.CreateButton(horz).SetText('View');

		viewTerrOrBonusBtn.SetOnClick(function()
			viewTerrOrBonusBtn.SetInteractable(false);
			wz.game.HighlightTerritories((isBonus and details.Territories) or {details.ID});
			viewTerrOrBonusBtn.SetInteractable(true);
		end);
	end

	function search()
		searchBtn.SetInteractable(false);

		if not UI.IsDestroyed(results) then
			UI.Destroy(results);
		end

		if not UI.IsDestroyed(pagers) then
			UI.Destroy(pagers);
		end

		results = UI.CreateVerticalLayoutGroup(vert5);
		pagers = UI.CreateHorizontalLayoutGroup(vert6);
		pagerBtns = {};

		getMatchingSearchResults();

		if #searchResults > 0 then
			displayPageResults(1);

			local i = 1;
			local pg = 1;

			while i < #searchResults do
				displayPager(pg);
				i = i + resultsPerPage;
				pg = pg + 1;
			end
		end

		searchBtn.SetInteractable(true);
	end

	function getMatchingSearchResults()
		searchResults = {};

		local query = (searchInput and searchInput.GetText():lower()) or '';

		for _, details in pairs(wz.game.Map[TpePlural]) do
			if isValidSearchedTerrOrBonus(details, wz) then
				if #query == 0 then
					table.insert(searchResults, {details = details, similarity = 1});
				else
					local text = details.Name:lower();
					local distance = levenshtein(text, query)
					local max_length = math.max(#text, #query);
					local similarity = 1 - (distance / max_length);

					if similarity > 0.05 then
						-- filter out very bad matches
						table.insert(searchResults, {details = details, similarity = similarity});
					end
				end
			end
		end

		table.sort(searchResults, function(a, b)
			if a.similarity == b.similarity then
				if a.details.Name == b.details.Name then
					return a.details.ID < b.details.ID;
				else
					return a.details.Name < b.details.Name;
				end
			else
				return a.similarity > b.similarity;
			end
		end);
	end

	function displayPageResults(pageNum)
		resultsPageNum = pageNum;

		if isVersionOrHigher('5.21') then
			if not UI.IsDestroyed(results) then
				UI.Destroy(results);
			end

			results = UI.CreateVerticalLayoutGroup(vert5);
		end

		local start = ((pageNum - 1) * resultsPerPage) + 1;
		local finish = math.min(start + resultsPerPage, #searchResults + 1);
		local i = start;

		while i < finish do
			local id = searchResults[i].details.ID;
			local details = wz.game.Map[TpePlural][id];

			listTerrOrBonusAsOption(details, wz);
			i = i + 1;
		end

		displayPager(pageNum);
	end

	function displayPager(pageNum)
		if not isVersionOrHigher('5.21') then
			return;
		end

		if #searchResults < resultsPerPage then
			return;
		end

		if UI.IsDestroyed(pagerBtns[pageNum]) then
			pagerBtns[pageNum] = UI.CreateButton(pagers)
				.SetText(tostring(pageNum))
				.SetColor('#0000FF');

			pagerBtns[pageNum].SetOnClick(
				function()
					pagerBtns[pageNum].SetInteractable(false);

					local oldPgNum = resultsPageNum;

					displayPageResults(pageNum);
					displayPager(oldPgNum);
				end
			);
		end

		pagerBtns[pageNum].SetInteractable(pageNum ~= resultsPageNum);
	end

	if not isVersionOrHigher('5.21') then
		getMatchingSearchResults();
		results = vert;
		resultsPerPage = #searchResults;
		displayPageResults(1);

		return;
	end

	local horz = UI.CreateHorizontalLayoutGroup(vert4);

	searchInput = UI.CreateTextInputField(horz).SetText('').SetPlaceholderText('Enter ' .. tpe .. ' name...').SetPreferredWidth(200).SetFlexibleWidth(1);
	searchBtn = UI.CreateButton(horz).SetText('Search').SetColor('#4EFFFF');
	vert5 = UI.CreateVerticalLayoutGroup(vert4);
	vert6 = UI.CreateVerticalLayoutGroup(vert4);

	searchBtn.SetOnClick(search);
	interceptNextTerritoryOrBonusClick();
	search();
end

function TerritorySelectionMenu(vert, terrValidation, wz)
	local validation = {
		displayTerrOrBonusSelectionWarning = terrValidation.displayTerrSelectionWarning,
		isValidTerrOrBonus = terrValidation.isValidTerr,
		onValidTerrOrBonus = terrValidation.onValidTerr,
		onInvalidTerrOrBonus = terrValidation.onInvalidTerr
	};

	return TerritoryOrBonusSelectionMenu(vert, validation, wz);
end

function BonusSelectionMenu(vert, bonusValidation, wz)
	local validation = {
		displayTerrOrBonusSelectionWarning = bonusValidation.displayBonusSelectionWarning,
		isValidTerrOrBonus = bonusValidation.isValidBonus,
		onValidTerrOrBonus = bonusValidation.onValidBonus,
		onInvalidTerrOrBonus = bonusValidation.onInvalidBonus
	};

	return TerritoryOrBonusSelectionMenu(vert, validation, wz, true);
end