-- copied from https://github.com/DanWaLes/Warzone/tree/main/mods/libs/ui

function Empty(parent)
	return UI.CreateEmpty(parent);
end

function Vert(parent)
	return UI.CreateVerticalLayoutGroup(parent);
end

function Horz(parent)
	return UI.CreateHorizontalLayoutGroup(parent);
end

function Label(parent)
	return UI.CreateLabel(parent);
end

function Btn(parent)
	return UI.CreateButton(parent);
end

function Checkbox(parent)
	return UI.CreateCheckBox(parent);
end

function RadioBtn(parent, group)
	local btn = UI.CreateRadioButton(parent);

	if group then
		btn.SetGroup(group);
	end

	return btn;
end

function RadioBtnGroup(parent)
	return UI.CreateRadioButtonGroup(parent);
end

function TextInput(parent)
	return UI.CreateTextInputField(parent);
end

function NumInput(parent)
	return UI.CreateNumberInputField(parent);
end

function Tabs(parent, dir, tabLabels, tabsClicked)
	local container = parent;

	if dir == Vert then
		container = Horz(parent);
	end

	local tabData = {
		tabsContainer = dir(container),
		tabBtns = {},
		selectedTab = nil,
		tabContents = nil,
	};

	tabData.tabClicked = function(label, main)
		if tabData.selectedTab then
			tabData.tabBtns[tabData.selectedTab].SetInteractable(true);
		end

		tabData.selectedTab = label;
		tabData.tabBtns[label].SetInteractable(false);

		if not UI.IsDestroyed(tabData.tabContents) then
			UI.Destroy(tabData.tabContents);
		end

		tabData.tabContents = Vert(container);

		main(tabData);
	end

	local map = {};
	tabData.clickTab = function(label)
		tabData.tabClicked(label, tabsClicked[map[label]]);
	end

	for i, label in ipairs(tabLabels) do
		map[label] = i;

		local tabBtn = Btn(tabData.tabsContainer).SetText(label);
		tabBtn.SetFlexibleWidth(1);
		tabBtn.SetOnClick(function() 
			tabData.clickTab(label);
		end);

		tabData.tabBtns[label] = tabBtn;
	end

	return tabData;
end

local function HighlightTerrOrBonusBtn(game, id, parent, isBonus)
	local mode = (isBonus and 'Bonuses') or 'Territories';
	local details = game.Map[mode][id];
	local btn = Btn(parent).SetText(details.Name);
	local terrs = (isBonus and details.Territories) or {details.ID};

	btn.SetOnClick(function()
		btn.SetInteractable(false);
		game.HighlightTerritories(terrs);
		btn.SetInteractable(true);
	end);

	return btn;
end

function HighlightTerrBtn(game, terrId, parent)
	return HighlightTerrOrBonusBtn(game, terrId, parent);
end

function HighlightBonusBtn(game, bonusId, parent)
	return HighlightTerrOrBonusBtn(game, bonusId, parent, true);
end

function CustomCardHelpButton(card, btnParent, helpContentParent)
	local horz = Horz(btnParent);

	Label(horz).SetText(card.Name);

	local btn = Btn(horz).SetText('?').SetColor('#23A0FF');
	local vert = Vert(helpContentParent);
	local vert2;

	btn.SetOnClick(
		function()
			if UI.IsDestroyed(vert2) then
				vert2 = Vert(vert);
				Label(vert2).SetText(card.CustomCardDescription);
			else
				UI.Destroy(vert2);
			end
		end
	);

	return btn;
end