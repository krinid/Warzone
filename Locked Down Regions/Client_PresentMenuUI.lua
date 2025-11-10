require('TerritoryOrBonusSelectionMenu');
require('tblprint');
require('ui');
require('version');

function Client_PresentMenuUI(RootParent, setMaxSize, setScrollable, Game, close)
	rootParent = RootParent;
	game = Game;

	if not canRunMod() then
		return close();
	end

	setMaxSize(500, 300);
	refresh(Mod.PublicGameData);
end

function refresh(storage, vert)
	if not UI.IsDestroyed(vert) then
		UI.Destroy(vert);
	end

	vert = Vert(rootParent);

	if game.Game.State ~= WL.GameState.Finished and game.Us and game.Settings.StartedBy == game.Us.ID then
		makeHostMenu(storage, vert);
	else
		-- other players and spectators can see which regions are locked down
		makeNormalMenu(storage, vert);
	end
end

function makeHostMenu(storage, vert)
	local newStorage = storage;

	function updateStorage()
		game.SendGameCustomMessage('Updating...', newStorage, function(storage)
			refresh(storage, vert);
		end);
	end

	if not storage.bonuses then
		newStorage.bonuses = {};

		for bonusId, bonus in pairs(game.Map.Bonuses) do
			table.insert(newStorage.bonuses, bonusId);
		end

		-- sort bonus names A to Z
		table.sort(newStorage.bonuses, function(a, b)
			return game.Map.Bonuses[a].Name < game.Map.Bonuses[b].Name;
		end);

		return updateStorage();
	end

	local vert1 = Vert(vert);
	local vert2;
	local addLockedDownRegionBtn = Btn(vert1).SetText('Add locked down region');

	addLockedDownRegionBtn.SetOnClick(function()
		addLockedDownRegionBtn.SetInteractable(false);

		if UI.IsDestroyed(vert2) then
			vert2 = Vert(vert1);
		end

		local turnNo = game.Game.TurnNumber;

		if turnNo < 1 then
			turnNo = 1;
		end

		BonusSelectionMenu(
			vert2,
			{
				displayBonusSelectionWarning = function(wz, parent)
					Label(parent).SetColor('#FF7D00').SetText('Regions must not contain territories of current locked down regions');
				end,
				isValidBonus = function(bonusDetails, wz)
					return isValidSelectedBonus(storage, bonusDetails);
				end,
				onValidBonus = function(bonusDetails, wz)
					UI.Destroy(vert2);

					local untilTurnHorz = Horz(vert1);

					HighlightBonusBtn(game, bonusDetails.ID, untilTurnHorz);

					Label(untilTurnHorz).SetText('Locks down until end of turn:');

					local initalValue = newStorage.lastUsedLockdownTurnNo or 0;

					if initalValue < turnNo then
						initalValue = turnNo;
					end

					local turn = NumInput(untilTurnHorz)
						.SetSliderMinValue(turnNo)
						.SetSliderMaxValue(turnNo + 100)
						.SetValue(initalValue);

					Btn(vert1)
						.SetText('Done')
						.SetOnClick(function()	
							local turnValue = turn.GetValue();

							if turnValue < turnNo then
								errorLabel.SetText('"Locks down until end of turn" must be at least ' .. turnNo);
							else
								newStorage.newLockedDownRegions[bonusDetails.ID] = turnValue;
								newStorage.lastUsedLockdownTurnNo = turnValue;

								updateStorage();
							end
						end);
				end,
				onInvalidBonus = function(bonusDetails, wz, parent)
					local horz = Horz(parent);

					HighlightBonusBtn(game, bonusDetails.ID, horz);
					Label(horz).SetColor('#FF0000').SetText('contains territories of current locked down regions!');
				end
			},
			{game = game}
		);
	end);

	Label(vert).SetText('Locked down regions:');

	function displayLockedDownRegions(listName)
		for bonusId, lockedDownUntilTurn in pairs(storage[listName]) do
			if lockedDownUntilTurn + 1 > game.Game.TurnNumber then
				local bonus = game.Map.Bonuses[bonusId];
				local horz = Horz(vert);

				HighlightBonusBtn(game, bonusId, horz)
				Label(horz).SetText('until end of turn ' .. lockedDownUntilTurn);

				Btn(horz).SetText('Remove').SetOnClick(function()
					if newStorage.lockedDownRegions[bonusId] then
						newStorage.lockedDownRegions[bonusId] = -1;
					end

					newStorage.newLockedDownRegions[bonusId] = nil;
					updateStorage();
				end);
			end
		end
	end

	displayLockedDownRegions('newLockedDownRegions');
	displayLockedDownRegions('lockedDownRegions');
end

function makeNormalMenu(storage, vert)
	local label = Label(vert).SetText('Locked down regions:');
	local hasLockedDownRegions = false;

	for bonusId, lockedDownUntilTurn in pairs(storage.lockedDownRegions) do
		if lockedDownUntilTurn + 1 > game.Game.TurnNumber then
			hasLockedDownRegions = true;
			local horz = Horz(vert);

			HighlightBonusBtn(game, bonusId, horz);
			Label(horz).SetText('until end of turn ' .. lockedDownUntilTurn);
		end
	end

	if not hasLockedDownRegions then
		label.SetText(label.GetText() .. ' (none)');
	end
end

function bonusContainsBonus(bonus1, bonus2)
	-- for any common territories

	if bonus1.ID == bonus2.ID then
		return true;
	end

	for _, terr1 in pairs(bonus1.Territories) do
		for _, terr2 in pairs(bonus2.Territories) do
			if terr1 == terr2 then
				return true;
			end
		end
	end

	return false;
end

function isValidSelectedBonus(storage, bonusDetails)
	for bonusId, lockedDownUntilTurn in pairs(storage.lockedDownRegions) do
		if lockedDownUntilTurn + 1 > game.Game.TurnNumber then
			local existingBonus = game.Map.Bonuses[bonusId];

			if bonusContainsBonus(bonusDetails, existingBonus) then
				return false;
			end
		end
	end

	return true;
end
