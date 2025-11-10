function decideWastelandSize(base, rand)
	local size = base + math.random(-rand, rand);

	if size < 0 then
		size = 0;
	elseif size > 100000 then
		size = 100000;
	end

	return size;
end

function addWasteland(terrId, size, wastelands, wastelanded)
	local overlapMode = Mod.Settings.OverlapMode;

	if overlapMode == 1 then
		if not wastelands[terrId] then
			wastelands[terrId] = {
				sizes = {},
				numSizes = 0
			};

			wastelanded.length = wastelanded.length + 1;
			wastelanded.list[wastelanded.length] = terrId;
		end

		wastelands[terrId].numSizes = wastelands[terrId].numSizes + 1;
		wastelands[terrId].sizes[wastelands[terrId].numSizes] = size;
	else
		if wastelands[terrId] then
			if overlapMode == 3 then
				wastelands[terrId] = size;
			elseif overlapMode == 4 and size < wastelands[terrId] then
				wastelands[terrId] = size;
			elseif overlapMode == 5 and size > wastelands[terrId] then
				wastelands[terrId] = size;
			end
		else
			wastelands[terrId] = size;

			wastelanded.length = wastelanded.length + 1;
			wastelanded.list[wastelanded.length] = terrId;
		end
	end

	return {wastelands = wastelands, wastelanded = wastelanded};
end

function generateWastelands(notIncluding, gwg)
	local numWastelandGroups = Mod.Settings.extraWasteland + 1;
	local n = 1;

	while n < numWastelandGroups do
		if Mod.Settings['extraWasteland_' .. n] then
			local numWastelands = Mod.Settings['W' .. n .. 'Num'];

			if Mod.Settings['W' .. n .. 'Type'] == notIncluding then
				numWastelands = 0;
			end

			local earlyExit = gwg(numWastelands, Mod.Settings['W' .. n .. 'Size'], Mod.Settings['W' .. n .. 'Rand']);

			if earlyExit then
				break;
			end
		end

		n = n + 1;
	end
end

function generateWastelandGroup(numWastelands, size, rand, placeWasteland, available, wastelands, wastelanded, maxWastelandedTerrs)
	local isRandomOverlapMode = Mod.Settings.OverlapMode == 1;
	local terrCount = Mod.PublicGameData.terrCount or 1;
	local numOverlaps = Mod.PublicGameData.numOverlaps or 0;

	while numWastelands > 0 do
		if available.length == 0 or (maxWastelandedTerrs and terrCount > maxWastelandedTerrs) then
			numOverlaps = numOverlaps + 1;

			if Mod.Settings.EnableOverlaps == false or (Mod.Settings.EnableOverlaps == nil and Mod.Settings.OverlapMode == 2) or (Mod.Settings.MaxOverlaps > 0 and numOverlaps == Mod.Settings.MaxOverlaps) then
				return {earlyExit = true, available = available, wastelands = wastelands, wastelanded = wastelanded};
			end

			terrCount = 0;
			available = clone(wastelanded);
		end

		if available.length < 1 then
			-- no neutrals left
			return {earlyExit = true, available = available, wastelands = wastelands, wastelanded = wastelanded};
		end

		local index = math.random(1, available.length);
		local terrId = available.list[index];
		local wSize = decideWastelandSize(size, rand);

		local ret = addWasteland(terrId, wSize, wastelands, wastelanded);

		wastelands = ret.wastelands;
		wastelanded = ret.wastelanded;

		table.remove(available.list, index);
		available.length = available.length - 1;

		if not isRandomOverlapMode then
			placeWasteland(terrId, wSize);
		end

		terrCount = terrCount + 1;
		numWastelands = numWastelands - 1;
	end

	local pgd = Mod.PublicGameData;

	pgd.terrCount = terrCount;
	pgd.numOverlaps = numOverlaps;
	Mod.PublicGameData = pgd;

	return {earlyExit = false, available = available, wastelands = wastelands, wastelanded = wastelanded};
end

function finish(wastelands, placeWasteland)
	if Mod.Settings.OverlapMode == 1 then
		for terrId, wData in pairs(wastelands) do
			local size = wData.sizes[math.random(1, wData.numSizes)];

			wastelands[terrId] = {
				sizes = {size},
				numSizes = 1
			};

			placeWasteland(terrId, size);
		end
	end

	local pgd = Mod.PublicGameData;

	pgd.wastelands = wastelands;
	pgd.terrCount = 1;
	pgd.numOverlaps = 0;
	Mod.PublicGameData = pgd;
end

function clone(tbl)
	local c = {};

	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			c[k] = clone(v);
		else
			c[k] = v;
		end
	end

	return c;
end