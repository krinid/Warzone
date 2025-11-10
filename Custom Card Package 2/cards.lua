local function requireCards()
	local cardNames = getCardNames();

	for _, cardName in pairs(cardNames) do
		require(cardName);
	end
end

function getCardNames()
	return {
		'Reconnaissance+',
		'Recycle',
		'Immobilize',
		'Trap',
		'Double Tap',
		'Rushed Blockade'
	};
end

function getCardsThatCanBeActive()
	return {
		['Reconnaissance+'] = true,-- will this be an issue for not being and active card before?
		Immobilize = true,
		Trap = true,
		['Double Tap'] = true
	};
end

requireCards();